# frozen_string_literal: true

RSpec.describe OfficerNEETzsche::Plugin do
  subject(:plugin) { described_class.new }

  let(:rubocop_context) { LintRoller::Context.new(engine: :rubocop) }

  describe "#about" do
    it "reports the gem name and version" do
      expect(plugin.about).to have_attributes(name: "officer_neetzsche", version: OfficerNEETzsche::VERSION)
    end
  end

  describe "#supported?" do
    it "supports RuboCop" do
      expect(plugin.supported?(rubocop_context)).to be(true)
    end

    it "does not support other engines" do
      expect(plugin.supported?(LintRoller::Context.new(engine: :rufo))).to be(false)
    end
  end

  describe "#rules" do
    subject(:rules) { plugin.rules(rubocop_context) }

    it "points RuboCop at the bundled default configuration" do
      expect(rules).to have_attributes(type: :path, config_format: :rubocop)
      expect(rules.value).to be_file
    end
  end

  it "is the plugin class RuboCop discovers through the gemspec" do
    gemspec = Gem::Specification.load(File.expand_path("../../officer_neetzsche.gemspec", __dir__))

    expect(gemspec.metadata["default_lint_roller_plugin"]).to eq(described_class.name)
  end
end
