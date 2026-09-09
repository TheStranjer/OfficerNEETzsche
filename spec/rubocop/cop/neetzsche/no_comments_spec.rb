# frozen_string_literal: true

RSpec.describe RuboCop::Cop::NEETzsche::NoComments, :config do
  it "registers an offense for a comment on its own line and removes the whole line" do
    expect_offense(<<~RUBY)
      # explains the obvious
      ^^^^^^^^^^^^^^^^^^^^^^ Avoid comments; let the code speak for itself.
      foo
    RUBY

    expect_correction(<<~RUBY)
      foo
    RUBY
  end

  it "removes an indented comment line along with its indentation" do
    expect_offense(<<~RUBY)
      def foo
        # explains foo
        ^^^^^^^^^^^^^^ Avoid comments; let the code speak for itself.
        bar
      end
    RUBY

    expect_correction(<<~RUBY)
      def foo
        bar
      end
    RUBY
  end

  it "registers an offense for a trailing comment and removes it with the space before it" do
    expect_offense(<<~RUBY)
      foo # explains foo
          ^^^^^^^^^^^^^^ Avoid comments; let the code speak for itself.
    RUBY

    expect_correction(<<~RUBY)
      foo
    RUBY
  end

  it "removes all of the whitespace between code and a trailing comment" do
    expect_offense(<<~RUBY)
      foo    # aligned
             ^^^^^^^^^ Avoid comments; let the code speak for itself.
    RUBY

    expect_correction(<<~RUBY)
      foo
    RUBY
  end

  it "registers an offense for a comment without a space after the hash" do
    expect_offense(<<~RUBY)
      #terse
      ^^^^^^ Avoid comments; let the code speak for itself.
      foo
    RUBY

    expect_correction(<<~RUBY)
      foo
    RUBY
  end

  it "registers an offense for every comment in the file" do
    expect_offense(<<~RUBY)
      # first
      ^^^^^^^ Avoid comments; let the code speak for itself.
      foo # second
          ^^^^^^^^ Avoid comments; let the code speak for itself.
      # third
      ^^^^^^^ Avoid comments; let the code speak for itself.
      bar
    RUBY

    expect_correction(<<~RUBY)
      foo
      bar
    RUBY
  end

  it "registers an offense for an =begin/=end block and removes the block" do
    expect_offense(<<~RUBY)
      =begin
      ^^^^^^ Avoid comments; let the code speak for itself.
      a block comment
      =end
      foo
    RUBY

    expect_correction(<<~RUBY)
      foo
    RUBY
  end

  it "allows magic comments" do
    expect_no_offenses(<<~RUBY)
      # frozen_string_literal: true
      #frozen_string_literal: true
      # encoding: utf-8
      # coding: utf-8
      # -*- coding: utf-8 -*-
      # warn_indent: true
      # shareable_constant_value: literal
      foo
    RUBY
  end

  it "allows a shebang" do
    expect_no_offenses(<<~RUBY)
      #!/usr/bin/env ruby
      foo
    RUBY
  end

  it "allows rubocop directives in every mode" do
    expect_no_offenses(<<~RUBY)
      # rubocop:disable Layout/LineLength
      foo # rubocop:disable Style/Semicolon
      # rubocop:enable Layout/LineLength
      # rubocop:todo Metrics/AbcSize
      # rubocop:disable-next Style/StringLiterals
      # rubocop:todo-next Style/StringLiterals
      # rubocop:push -Metrics/AbcSize
      # rubocop:pop
      #rubocop:disable all
      bar
    RUBY
  end

  it "ignores a hash sign inside a string" do
    expect_no_offenses(<<~'RUBY')
      puts "# not a comment"
      puts '#{also_not}'
    RUBY
  end

  it "ignores code without comments" do
    expect_no_offenses(<<~RUBY)
      def foo
        bar
      end
    RUBY
  end
end
