# frozen_string_literal: true

RSpec.describe RuboCop::Cop::NEETzsche::StatementModifier, :config do
  describe "if and unless" do
    it "rewrites a one-statement if as a modifier" do
      expect_offense(<<~RUBY)
        if condition?
        ^^ Write a one-statement `if` as a modifier.
          do_thing
        end
      RUBY

      expect_correction(<<~RUBY)
        do_thing if condition?
      RUBY
    end

    it "rewrites a one-statement unless as a modifier" do
      expect_offense(<<~RUBY)
        unless condition?
        ^^^^^^ Write a one-statement `unless` as a modifier.
          do_thing
        end
      RUBY

      expect_correction(<<~RUBY)
        do_thing unless condition?
      RUBY
    end

    it "keeps the indentation of the block" do
      expect_offense(<<~RUBY)
        def call
          if condition?
          ^^ Write a one-statement `if` as a modifier.
            do_thing(with, arguments)
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        def call
          do_thing(with, arguments) if condition?
        end
      RUBY
    end

    it "rewrites a single-line then form" do
      expect_offense(<<~RUBY)
        if condition? then do_thing end
        ^^ Write a one-statement `if` as a modifier.
      RUBY

      expect_correction(<<~RUBY)
        do_thing if condition?
      RUBY
    end

    it "rewrites a body separated by semicolons" do
      expect_offense(<<~RUBY)
        if condition?; do_thing; end
        ^^ Write a one-statement `if` as a modifier.
      RUBY

      expect_correction(<<~RUBY)
        do_thing if condition?
      RUBY
    end

    it "does not care how long the modifier line becomes" do
      expect_offense(<<~'RUBY')
        if some_object.some_predicate_with_a_long_name?(first_argument, second_argument, third_argument)
        ^^ Write a one-statement `if` as a modifier.
          return log_warning("category ##{category_id} no longer exists; skipping inactive site notification")
        end
      RUBY

      expect_correction(<<~'RUBY')
        return log_warning("category ##{category_id} no longer exists; skipping inactive site notification") if some_object.some_predicate_with_a_long_name?(first_argument, second_argument, third_argument)
      RUBY
    end

    it "ignores blank lines inside the block" do
      expect_offense(<<~RUBY)
        if condition?
        ^^ Write a one-statement `if` as a modifier.

          do_thing

        end
      RUBY

      expect_correction(<<~RUBY)
        do_thing if condition?
      RUBY
    end

    it "rewrites a body that is a block" do
      expect_offense(<<~RUBY)
        if condition?
        ^^ Write a one-statement `if` as a modifier.
          items.each { |item| item.touch }
        end
      RUBY

      expect_correction(<<~RUBY)
        items.each { |item| item.touch } if condition?
      RUBY
    end

    it "accepts a modifier" do
      expect_no_offenses(<<~RUBY)
        do_thing if condition?
        do_thing unless condition?
      RUBY
    end

    it "accepts a body of more than one statement" do
      expect_no_offenses(<<~RUBY)
        if condition?
          do_this
          do_that
        end
      RUBY
    end

    it "accepts a body that spans more than one line" do
      expect_no_offenses(<<~RUBY)
        if condition?
          do_thing(
            argument
          )
        end
      RUBY
    end

    it "accepts a condition that spans more than one line" do
      expect_no_offenses(<<~RUBY)
        if first_condition? &&
           second_condition?
          do_thing
        end
      RUBY
    end

    it "accepts an empty body" do
      expect_no_offenses(<<~RUBY)
        if condition?
        end
      RUBY
    end

    it "accepts else, elsif, and ternaries" do
      expect_no_offenses(<<~RUBY)
        if condition?
          do_this
        else
          do_that
        end

        if condition?
          do_this
        elsif other?
          do_that
        end

        unless condition?
          do_this
        else
          do_that
        end

        condition? ? do_this : do_that
      RUBY
    end
  end

  describe "while and until" do
    it "rewrites a one-statement while as a modifier" do
      expect_offense(<<~RUBY)
        while queue.any?
        ^^^^^ Write a one-statement `while` as a modifier.
          queue.pop.call
        end
      RUBY

      expect_correction(<<~RUBY)
        queue.pop.call while queue.any?
      RUBY
    end

    it "rewrites a one-statement until as a modifier" do
      expect_offense(<<~RUBY)
        until queue.empty?
        ^^^^^ Write a one-statement `until` as a modifier.
          queue.pop.call
        end
      RUBY

      expect_correction(<<~RUBY)
        queue.pop.call until queue.empty?
      RUBY
    end

    it "rewrites a single-line do form" do
      expect_offense(<<~RUBY)
        while queue.any? do queue.pop.call end
        ^^^^^ Write a one-statement `while` as a modifier.
      RUBY

      expect_correction(<<~RUBY)
        queue.pop.call while queue.any?
      RUBY
    end

    it "keeps a body that only reassigns a local variable" do
      expect_offense(<<~RUBY)
        count = 0
        while count < 10
        ^^^^^ Write a one-statement `while` as a modifier.
          count += 1
        end
      RUBY

      expect_correction(<<~RUBY)
        count = 0
        count += 1 while count < 10
      RUBY
    end

    it "accepts modifiers and post-condition loops" do
      expect_no_offenses(<<~RUBY)
        queue.pop.call while queue.any?
        queue.pop.call until queue.empty?
        begin
          queue.pop.call
        end while queue.any?
      RUBY
    end

    it "accepts a body of more than one statement" do
      expect_no_offenses(<<~RUBY)
        while queue.any?
          item = queue.pop
          item.call
        end
      RUBY
    end
  end

  describe "rescue" do
    it "rewrites a one-statement begin/rescue as a modifier" do
      expect_offense(<<~RUBY)
        begin
          do_thing
        rescue
        ^^^^^^ Write a one-statement `rescue` as a modifier.
          handle
        end
      RUBY

      expect_correction(<<~RUBY)
        do_thing rescue handle
      RUBY
    end

    it "rewrites a rescue of StandardError, which is what the modifier rescues" do
      expect_offense(<<~RUBY)
        begin
          do_thing
        rescue StandardError
        ^^^^^^ Write a one-statement `rescue` as a modifier.
          handle
        end

        begin
          do_thing
        rescue ::StandardError
        ^^^^^^ Write a one-statement `rescue` as a modifier.
          handle
        end
      RUBY

      expect_correction(<<~RUBY)
        do_thing rescue handle

        do_thing rescue handle
      RUBY
    end

    it "rewrites a single-line begin/rescue" do
      expect_offense(<<~RUBY)
        begin; do_thing; rescue; handle; end
                         ^^^^^^ Write a one-statement `rescue` as a modifier.
      RUBY

      expect_correction(<<~RUBY)
        do_thing rescue handle
      RUBY
    end

    it "rewrites a rescue clause of a method" do
      expect_offense(<<~RUBY)
        def call
          do_thing
        rescue
        ^^^^^^ Write a one-statement `rescue` as a modifier.
          handle
        end
      RUBY

      expect_correction(<<~RUBY)
        def call
          do_thing rescue handle
        end
      RUBY
    end

    it "rewrites a rescue clause of a block" do
      expect_offense(<<~RUBY)
        items.each do |item|
          item.call
        rescue
        ^^^^^^ Write a one-statement `rescue` as a modifier.
          nil
        end
      RUBY

      expect_correction(<<~RUBY)
        items.each do |item|
          item.call rescue nil
        end
      RUBY
    end

    it "rewrites the rescue and leaves an ensure clause alone" do
      expect_offense(<<~RUBY)
        begin
          do_thing
        rescue
        ^^^^^^ Write a one-statement `rescue` as a modifier.
          handle
        ensure
          cleanup
        end
      RUBY

      expect_correction(<<~RUBY)
        begin
          do_thing rescue handle
        ensure
          cleanup
        end
      RUBY
    end

    it "rewrites a handler that returns or raises" do
      expect_offense(<<~RUBY)
        def call
          do_thing
        rescue
        ^^^^^^ Write a one-statement `rescue` as a modifier.
          raise Error, "failed"
        end

        def other
          do_thing
        rescue
        ^^^^^^ Write a one-statement `rescue` as a modifier.
          return nil
        end
      RUBY

      expect_correction(<<~RUBY)
        def call
          do_thing rescue raise Error, "failed"
        end

        def other
          do_thing rescue return nil
        end
      RUBY
    end

    it "accepts a modifier" do
      expect_no_offenses(<<~RUBY)
        do_thing rescue handle
      RUBY
    end

    it "accepts a body or handler of more than one statement" do
      expect_no_offenses(<<~RUBY)
        begin
          do_this
          do_that
        rescue
          handle
        end

        begin
          do_thing
        rescue
          log
          handle
        end
      RUBY
    end

    it "accepts an empty body or handler" do
      expect_no_offenses(<<~RUBY)
        begin
        rescue
          handle
        end

        begin
          do_thing
        rescue
        end
      RUBY
    end

    it "accepts a rescue that names a class, binds a variable, or has more than one clause" do
      expect_no_offenses(<<~RUBY)
        begin
          do_thing
        rescue ArgumentError
          handle
        end

        begin
          do_thing
        rescue StandardError, ArgumentError
          handle
        end

        begin
          do_thing
        rescue => e
          handle(e)
        end

        begin
          do_thing
        rescue ArgumentError
          handle
        rescue
          handle_other
        end
      RUBY
    end

    it "accepts a rescue with an else clause" do
      expect_no_offenses(<<~RUBY)
        begin
          do_thing
        rescue
          handle
        else
          celebrate
        end
      RUBY
    end
  end

  describe "precedence" do
    it "parenthesizes an if whose value is used" do
      expect_offense(<<~RUBY)
        value = if condition?
                ^^ Write a one-statement `if` as a modifier.
          compute
        end
        values = [if condition? then compute end, other]
                  ^^ Write a one-statement `if` as a modifier.
        options = { value: if condition? then compute end }
                           ^^ Write a one-statement `if` as a modifier.
        call(if condition? then compute end)
             ^^ Write a one-statement `if` as a modifier.
        both = first? && if condition? then compute end
                         ^^ Write a one-statement `if` as a modifier.
        text = if condition? then compute end.to_s
               ^^ Write a one-statement `if` as a modifier.
      RUBY

      expect_correction(<<~RUBY)
        value = (compute if condition?)
        values = [(compute if condition?), other]
        options = { value: (compute if condition?) }
        call((compute if condition?))
        both = first? && (compute if condition?)
        text = (compute if condition?).to_s
      RUBY
    end

    it "parenthesizes a rescue whose value is used, except as an assigned value" do
      expect_offense(<<~RUBY)
        value = begin; compute; rescue; fallback; end
                                ^^^^^^ Write a one-statement `rescue` as a modifier.
        record.value = begin; compute; rescue; fallback; end
                                       ^^^^^^ Write a one-statement `rescue` as a modifier.
        cache[:value] ||= begin; compute; rescue; fallback; end
                                          ^^^^^^ Write a one-statement `rescue` as a modifier.
        values = [begin; compute; rescue; fallback; end, other]
                                  ^^^^^^ Write a one-statement `rescue` as a modifier.
        call(begin; compute; rescue; fallback; end)
                             ^^^^^^ Write a one-statement `rescue` as a modifier.
        text = begin; compute; rescue; fallback; end.to_s
                               ^^^^^^ Write a one-statement `rescue` as a modifier.
        return begin; compute; rescue; fallback; end
                               ^^^^^^ Write a one-statement `rescue` as a modifier.
      RUBY

      expect_correction(<<~RUBY)
        value = compute rescue fallback
        record.value = compute rescue fallback
        cache[:value] ||= compute rescue fallback
        values = [(compute rescue fallback), other]
        call((compute rescue fallback))
        text = (compute rescue fallback).to_s
        return (compute rescue fallback)
      RUBY
    end

    it "does not parenthesize a statement inside a method, block, or interpolation" do
      expect_offense(<<~'RUBY')
        def call
          if condition? then compute end
          ^^ Write a one-statement `if` as a modifier.
        end
        items.each { |item| if item.ready? then item.call end }
                            ^^ Write a one-statement `if` as a modifier.
        "#{if condition? then compute end}"
           ^^ Write a one-statement `if` as a modifier.
      RUBY

      expect_correction(<<~'RUBY')
        def call
          compute if condition?
        end
        items.each { |item| item.call if item.ready? }
        "#{compute if condition?}"
      RUBY
    end

    it "parenthesizes a call whose last keyword argument omits its value", :ruby31 do
      expect_offense(<<~RUBY)
        if condition?
        ^^ Write a one-statement `if` as a modifier.
          render locals:, layout: false, status:
        end
        begin
          compute
        rescue
        ^^^^^^ Write a one-statement `rescue` as a modifier.
          fallback status:
        end
      RUBY

      expect_correction(<<~RUBY)
        render(locals:, layout: false, status:) if condition?
        compute rescue fallback(status:)
      RUBY
    end
  end

  describe "chained modifiers" do
    it "accepts a body that is already a modifier" do
      expect_no_offenses(<<~RUBY)
        if outer?
          do_thing if inner?
        end

        while outer?
          do_thing unless inner?
        end

        if condition?
          do_thing rescue nil
        end

        begin
          do_thing rescue nil
        rescue
          handle
        end

        if outer?
          case value when 1 then do_thing end
        end
      RUBY
    end

    it "rewrites an inner one-liner and leaves the block around it alone" do
      expect_offense(<<~RUBY)
        if outer?
          if inner? then do_thing end
          ^^ Write a one-statement `if` as a modifier.
        end

        if condition?
          begin; do_thing; rescue; nil; end
                           ^^^^^^ Write a one-statement `rescue` as a modifier.
        end

        begin
          begin; do_thing; rescue; nil; end
                           ^^^^^^ Write a one-statement `rescue` as a modifier.
        rescue
          handle
        end
      RUBY

      expect_correction(<<~RUBY)
        if outer?
          do_thing if inner?
        end

        if condition?
          do_thing rescue nil
        end

        begin
          do_thing rescue nil
        rescue
          handle
        end
      RUBY
    end

    it "accepts a rescue body or handler that is a conditional" do
      expect_no_offenses(<<~RUBY)
        begin
          do_thing if condition?
        rescue
          handle
        end

        begin
          do_thing
        rescue
          handle if condition?
        end
      RUBY
    end

    it "accepts a begin/rescue that is already the body of a modifier" do
      expect_no_offenses(<<~RUBY)
        begin; do_thing; rescue; handle; end if condition?
      RUBY
    end
  end

  describe "parse order" do
    it "accepts a condition that assigns a local variable" do
      expect_no_offenses(<<~RUBY)
        if (match = pattern.match(text))
          use(match)
        end

        while (line = input.gets)
          process(line)
        end

        if match = pattern.match(text)
          use(match)
        end
      RUBY
    end

    it "accepts a condition that pattern matches or captures", :ruby30 do
      expect_no_offenses(<<~RUBY)
        if value in [first]
          use(first)
        end

        if /(?<year>\\d+)/ =~ text
          use(year)
        end
      RUBY
    end

    it "accepts a body that assigns a name the condition calls as a method" do
      expect_no_offenses(<<~RUBY)
        def with_predicate
          if name.nil?
            name = default_name
          end
        end

        def with_defined
          unless defined?(name)
            name = default_name
          end
        end

        def with_loop
          while count < limit
            count += 1
          end
        end
      RUBY
    end

    it "rewrites a body that assigns a name the condition does not call" do
      expect_offense(<<~RUBY)
        if name.nil?
        ^^ Write a one-statement `if` as a modifier.
          other = default_name
        end
      RUBY

      expect_correction(<<~RUBY)
        other = default_name if name.nil?
      RUBY
    end

    it "accepts a body that is an endless method definition", :ruby30 do
      expect_no_offenses(<<~RUBY)
        if condition?
          def call = compute
        end
      RUBY
    end
  end

  describe "comments and heredocs" do
    it "moves a comment on the keyword line to the end of the modifier line" do
      expect_offense(<<~RUBY)
        if condition? # why
        ^^ Write a one-statement `if` as a modifier.
          do_thing
        end
        begin # why
          do_thing
        rescue
        ^^^^^^ Write a one-statement `rescue` as a modifier.
          handle
        end
      RUBY

      expect_correction(<<~RUBY)
        do_thing if condition? # why
        do_thing rescue handle # why
      RUBY
    end

    it "accepts a comment on any other line of the block" do
      expect_no_offenses(<<~RUBY)
        if condition?
          # why
          do_thing
        end

        if condition?
          do_thing # why
        end

        if condition?
          do_thing
        end # why

        begin
          do_thing
        rescue # why
          handle
        end
      RUBY
    end

    it "accepts a keyword-line comment when code follows the end keyword" do
      expect_no_offenses(<<~RUBY)
        value = if condition? # why
          compute
        end.to_s
      RUBY
    end

    it "accepts a heredoc" do
      expect_no_offenses(<<~RUBY)
        if condition?
          query(<<~SQL)
            SELECT 1
          SQL
        end

        begin
          query(<<~SQL)
            SELECT 1
          SQL
        rescue
          handle
        end
      RUBY
    end
  end
end
