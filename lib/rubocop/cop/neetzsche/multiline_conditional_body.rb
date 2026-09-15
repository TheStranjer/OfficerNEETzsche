# frozen_string_literal: true

module RuboCop
  module Cop
    module NEETzsche
      class MultilineConditionalBody < Base
        MSG = "Move a multi-line `%<keyword>s` body into its own method."

        HEREDOC_TYPES = %i[str dstr xstr].freeze

        def on_if(node)
          return if node.ternary?

          check(node.if_branch, node.loc.keyword, node.keyword)
          check(node.else_branch, node.loc.else, "else") if node.else? && !node.elsif_conditional?
        end

        def on_while(node)
          check(node.body, node.loc.keyword, node.keyword)
        end
        alias on_until on_while

        private

        def check(body, keyword, name)
          return if body.nil? || one_liner?(body)

          add_offense(keyword, message: format(MSG, keyword: name))
        end

        def one_liner?(body)
          !multiple_statements?(body) && body.first_line == last_line(body)
        end

        def multiple_statements?(body)
          (body.begin_type? || body.kwbegin_type?) && body.children.size > 1
        end

        def last_line(body)
          heredocs = body.each_node(*HEREDOC_TYPES).select(&:heredoc?)
          [body.last_line, *heredocs.map { |heredoc| heredoc.loc.heredoc_end.line }].max
        end
      end
    end
  end
end
