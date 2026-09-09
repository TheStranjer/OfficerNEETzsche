# frozen_string_literal: true

require_relative "lib/officer_neetzsche/version"

Gem::Specification.new do |spec|
  spec.name = "officer_neetzsche"
  spec.version = OfficerNEETzsche::VERSION
  spec.authors = ["TheStranjer"]
  spec.email = ["thestranjer@protonmail.com"]

  spec.summary = "RuboCop cops that enforce NEETzsche-isms."
  spec.description = "A RuboCop plugin whose cops each enforce one NEETzsche-ism. Every cop is enabled by default."
  spec.homepage = "https://github.com/TheStranjer/OfficerNEETzsche"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata = {
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "default_lint_roller_plugin" => "OfficerNEETzsche::Plugin",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir["lib/**/*.rb", "config/**/*.yml", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "lint_roller", "~> 1.1"
  spec.add_dependency "rubocop", ">= 1.72.0"
end
