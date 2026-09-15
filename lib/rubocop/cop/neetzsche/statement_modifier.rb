# frozen_string_literal: true

module RuboCop
  module Cop
    module NEETzsche
      class StatementModifier < Base
        include RangeHelp
        extend AutoCorrector

        MSG = "Write a one-statement `%<keyword>s` as a modifier."

        CHAIN_TYPES = %i[if while until while_post until_post for case case_match rescue kwbegin].freeze
        CALLS = %i[send csend super yield].freeze

        def self.autocorrect_incompatible_with
          [Style::Next, Style::SoleNestedConditional]
        end

        def on_if(node)
          return if node.modifier_form? || node.ternary? || node.elsif? || node.else?

          check_conditional(node)
        end

        def on_while(node)
          return if node.modifier_form?

          check_conditional(node)
        end
        alias on_until on_while

        def on_rescue(node)
          resbody = node.resbody_branches.first
          return unless bare_rescue?(node, resbody)

          target = node.parent&.kwbegin_type? ? node.parent : node
          return unless one_liner?(target, [node.body, resbody.body])

          add_offense(resbody.loc.keyword, message: format(MSG, keyword: "rescue")) do |corrector|
            rewrite(corrector, target, rescue_statement(node, resbody), Precedence.parenthesize_rescue?(target))
          end
        end

        private

        def check_conditional(node)
          return unless eligible_conditional?(node)

          add_offense(node.loc.keyword, message: format(MSG, keyword: node.keyword)) do |corrector|
            rewrite(corrector, node, conditional_statement(node), Precedence.parenthesize_conditional?(node))
          end
        end

        def eligible_conditional?(node)
          node.condition.single_line? && one_liner?(node, [node.body]) &&
            !Precedence.endless_def?(node.body) && !ParseOrder.hazard?(node)
        end

        def conditional_statement(node)
          "#{statement_source(node.body)} #{node.keyword} #{node.condition.source}"
        end

        def rescue_statement(node, resbody)
          "#{statement_source(node.body)} rescue #{statement_source(resbody.body)}"
        end

        def rewrite(corrector, node, statement, parenthesize)
          statement = "(#{statement})" if parenthesize
          corrector.replace(node, [statement, first_line_comment(node)&.source].compact.join(" "))
        end

        def bare_rescue?(node, resbody)
          !rescue_modifier?(resbody) && node.resbody_branches.one? && !node.else? &&
            resbody.exception_variable.nil? && standard_error_only?(resbody.exceptions)
        end

        def rescue_modifier?(resbody)
          processed_source.tokens.any? { |token| token.rescue_modifier? && token.pos == resbody.loc.keyword }
        end

        def standard_error_only?(exceptions)
          return true if exceptions.empty?
          return false unless exceptions.one? && exceptions.first.const_type?

          namespace, name = *exceptions.first
          name == :StandardError && (namespace.nil? || namespace.cbase_type?)
        end

        def one_liner?(node, statements)
          statements.all? { |statement| single_statement?(statement) } &&
            !modifier_body?(node) && !heredoc?(node) && comments_movable?(node)
        end

        def single_statement?(statement)
          return false if statement.nil? || statement.begin_type? || CHAIN_TYPES.include?(statement.type)
          return false if statement.source.end_with?(":") && !CALLS.include?(statement.type)

          statement.single_line?
        end

        def modifier_body?(node)
          parent = node.parent
          return false unless parent && (parent.if_type? || parent.while_type? || parent.until_type?)

          parent.modifier_form? && parent.body.equal?(node)
        end

        def heredoc?(node)
          node.each_descendant(:str, :dstr, :xstr).any?(&:heredoc?)
        end

        def comments_movable?(node)
          return false if processed_source.each_comment_in_lines((node.first_line + 1)..node.last_line).any?

          first_line_comment(node).nil? || code_after(node).nil?
        end

        def first_line_comment(node)
          processed_source.comment_at_line(node.first_line)
        end

        def code_after(node)
          line_end = first_line_comment(node)&.source_range&.begin_pos if node.single_line?
          line_end ||= processed_source.buffer.line_range(node.last_line).end_pos
          code = range_between(node.source_range.end_pos, line_end).source.strip
          code unless code.empty?
        end

        def statement_source(statement)
          return statement.source unless statement.source.end_with?(":")

          head = range_between(statement.source_range.begin_pos, statement.first_argument.source_range.begin_pos)
          "#{head.source.rstrip}(#{statement.arguments.map(&:source).join(", ")})"
        end

        module ParseOrder
          CAPTURING_CONDITIONS = %i[lvasgn match_with_lvasgn match_pattern match_pattern_p].freeze

          module_function

          def hazard?(node)
            condition = node.condition
            return true if condition.each_node(*CAPTURING_CONDITIONS).any?

            assigned = node.body.each_node(:lvasgn).map { |assignment| assignment.children.first }
            return false if assigned.empty?

            condition.each_node(:send).any? { |call| bare_identifier?(call) && assigned.include?(call.method_name) }
          end

          def bare_identifier?(call)
            call.receiver.nil? && call.arguments.empty? && !call.parenthesized? && call.block_node.nil?
          end
        end

        module Precedence
          STATEMENT_PARENTS = %i[begin kwbegin def defs block numblock itblock class module sclass
                                 ensure rescue resbody preexe postexe].freeze
          ASSIGNMENTS = %i[lvasgn ivasgn cvasgn gvasgn casgn masgn op_asgn or_asgn and_asgn indexasgn].freeze

          module_function

          def parenthesize_conditional?(node)
            !statement_position?(node)
          end

          def parenthesize_rescue?(node)
            !statement_position?(node) && !assignment_value?(node)
          end

          def endless_def?(body)
            %i[def defs].include?(body.type) && body.endless?
          end

          def statement_position?(node)
            parent = node.parent
            return true if parent.nil? || STATEMENT_PARENTS.include?(parent.type)

            case parent.type
            when :if, :while, :until, :case, :case_match then !parent.children.first.equal?(node)
            when :for, :when, :in_pattern then parent.body.equal?(node)
            else false
            end
          end

          def assignment_value?(node)
            parent = node.parent
            return false unless parent.children.last.equal?(node)

            ASSIGNMENTS.include?(parent.type) || (parent.send_type? && parent.assignment_method?)
          end
        end
      end
    end
  end
end
