# frozen_string_literal: true

RSpec.describe RuboCop::Cop::NEETzsche::MultilineConditionalBody, :config do
  describe "if and unless" do
    it "flags a body of more than one statement" do
      expect_offense(<<~RUBY)
        if condition?
        ^^ Move a multi-line `if` body into its own method.
          do_this
          do_that
        end

        unless condition?
        ^^^^^^ Move a multi-line `unless` body into its own method.
          do_this
          do_that
        end
      RUBY
    end

    it "flags a body of one statement that spans lines" do
      expect_offense(<<~RUBY)
        if condition?
        ^^ Move a multi-line `if` body into its own method.
          do_thing(
            argument
          )
        end

        if condition?
        ^^ Move a multi-line `if` body into its own method.
          items.each do |item|
            item.call
          end
        end

        if condition?
        ^^ Move a multi-line `if` body into its own method.
          options = {
            key: value
          }
        end
      RUBY
    end

    it "flags a body that is a multi-line conditional" do
      expect_offense(<<~RUBY)
        if outer?
        ^^ Move a multi-line `if` body into its own method.
          if inner?
            do_thing
          end
        end

        if outer?
        ^^ Move a multi-line `if` body into its own method.
          case value
          when 1 then do_this
          when 2 then do_that
          end
        end
      RUBY
    end

    it "flags every level of nesting whose body spans lines" do
      expect_offense(<<~RUBY)
        if outer?
        ^^ Move a multi-line `if` body into its own method.
          if inner?
          ^^ Move a multi-line `if` body into its own method.
            do_this
            do_that
          end
        end
      RUBY
    end

    it "flags a body of more than one statement on one line" do
      expect_offense(<<~RUBY)
        if condition?; do_this; do_that; end
        ^^ Move a multi-line `if` body into its own method.
        if condition? then do_this; do_that end
        ^^ Move a multi-line `if` body into its own method.
      RUBY
    end

    it "flags a body whose value is used" do
      expect_offense(<<~RUBY)
        value = if condition?
                ^^ Move a multi-line `if` body into its own method.
          do_this
          do_that
        end
      RUBY
    end

    it "accepts a body of one statement on one line" do
      expect_no_offenses(<<~RUBY)
        if condition?
          do_thing
        end

        unless condition?
          do_thing(with, arguments)
        end

        if condition? then do_thing end

        if condition?
          items.each { |item| item.call }
        end

        if outer?
          do_thing if inner?
        end
      RUBY
    end

    it "accepts a modifier with a one-line body" do
      expect_no_offenses(<<~RUBY)
        do_thing if condition?
        do_thing unless condition?
      RUBY
    end

    it "accepts an empty body" do
      expect_no_offenses(<<~RUBY)
        if condition?
        end
      RUBY
    end

    it "accepts a ternary" do
      expect_no_offenses(<<~RUBY)
        condition? ? do_this : do_that
      RUBY
    end

    it "accepts a comment inside the body" do
      expect_no_offenses(<<~RUBY)
        if condition?
          # why
          do_thing
        end
      RUBY
    end

    it "accepts a condition that spans lines" do
      expect_no_offenses(<<~RUBY)
        if first_condition? &&
           second_condition?
          do_thing
        end
      RUBY
    end
  end

  describe "else and elsif" do
    it "flags each branch on its own" do
      expect_offense(<<~RUBY)
        if condition?
        ^^ Move a multi-line `if` body into its own method.
          do_this
          do_that
        else
        ^^^^ Move a multi-line `else` body into its own method.
          do_other
          do_another
        end
      RUBY
    end

    it "flags an elsif body and the else after it" do
      expect_offense(<<~RUBY)
        if first?
          do_first
        elsif second?
        ^^^^^ Move a multi-line `elsif` body into its own method.
          do_this
          do_that
        else
        ^^^^ Move a multi-line `else` body into its own method.
          do_other
          do_another
        end
      RUBY
    end

    it "flags the else of an unless" do
      expect_offense(<<~RUBY)
        unless condition?
          do_thing
        else
        ^^^^ Move a multi-line `else` body into its own method.
          do_other
          do_another
        end
      RUBY
    end

    it "accepts branches of one statement each" do
      expect_no_offenses(<<~RUBY)
        if first?
          do_first
        elsif second?
          do_second
        else
          do_other
        end

        if condition? then do_this else do_that end
      RUBY
    end

    it "accepts an empty else" do
      expect_no_offenses(<<~RUBY)
        if condition?
          do_thing
        else
        end
      RUBY
    end
  end

  describe "while and until" do
    it "flags a body of more than one statement" do
      expect_offense(<<~RUBY)
        while queue.any?
        ^^^^^ Move a multi-line `while` body into its own method.
          item = queue.pop
          item.call
        end

        until queue.empty?
        ^^^^^ Move a multi-line `until` body into its own method.
          item = queue.pop
          item.call
        end
      RUBY
    end

    it "flags a body of one statement that spans lines" do
      expect_offense(<<~RUBY)
        while queue.any?
        ^^^^^ Move a multi-line `while` body into its own method.
          queue.pop.call(
            argument
          )
        end
      RUBY
    end

    it "accepts a body of one statement on one line" do
      expect_no_offenses(<<~RUBY)
        while queue.any?
          queue.pop.call
        end

        until queue.empty? do queue.pop.call end
      RUBY
    end

    it "accepts a modifier and a post-condition loop" do
      expect_no_offenses(<<~RUBY)
        queue.pop.call while queue.any?

        begin
          item = queue.pop
          item.call
        end while queue.any?

        begin
          item = queue.pop
          item.call
        end until queue.empty?
      RUBY
    end
  end

  describe "modifier form" do
    it "flags a modifier whose body spans lines" do
      expect_offense(<<~RUBY)
        begin
          do_this
          do_that
        end if condition?
            ^^ Move a multi-line `if` body into its own method.

        do_thing(
          argument
        ) unless condition?
          ^^^^^^ Move a multi-line `unless` body into its own method.

        do_thing(
          argument
        ) while condition?
          ^^^^^ Move a multi-line `while` body into its own method.
      RUBY
    end
  end

  describe "heredocs" do
    it "flags a body whose heredoc spans lines" do
      expect_offense(<<~RUBY)
        if condition?
        ^^ Move a multi-line `if` body into its own method.
          query(<<~SQL)
            SELECT 1
          SQL
        end
      RUBY
    end
  end
end
