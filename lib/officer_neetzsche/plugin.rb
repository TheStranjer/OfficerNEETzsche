# frozen_string_literal: true

require "lint_roller"
require "pathname"

module OfficerNEETzsche
  class Plugin < LintRoller::Plugin
    def about
      LintRoller::About.new(
        name: "officer_neetzsche",
        version: VERSION,
        homepage: "https://github.com/TheStranjer/OfficerNEETzsche",
        description: "RuboCop cops that enforce NEETzsche-isms."
      )
    end

    def supported?(context)
      context.engine == :rubocop
    end

    def rules(_context)
      LintRoller::Rules.new(
        type: :path,
        config_format: :rubocop,
        value: Pathname.new(__dir__).join("../../config/default.yml")
      )
    end
  end
end
