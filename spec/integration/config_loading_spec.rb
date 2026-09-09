# frozen_string_literal: true

RSpec.describe "Loading officer_neetzsche from .rubocop.yml", :isolated_environment, :restore_configuration do
  let(:config) { RuboCop::ConfigLoader.configuration_from_file(".rubocop.yml") }

  before { File.write(".rubocop.yml", rubocop_yml) }

  context "when listed under plugins" do
    let(:rubocop_yml) { "plugins:\n  - officer_neetzsche\n" }

    it "enables NEETzsche/NoComments" do
      expect(config.for_cop("NEETzsche/NoComments")["Enabled"]).to be(true)
    end

    it "disables Style/Documentation" do
      expect(config.for_cop("Style/Documentation")["Enabled"]).to be(false)
    end
  end

  context "when the project disables one cop" do
    let(:rubocop_yml) { "plugins:\n  - officer_neetzsche\n\nNEETzsche/NoComments:\n  Enabled: false\n" }

    it "disables that cop" do
      expect(config.for_cop("NEETzsche/NoComments")["Enabled"]).to be(false)
    end
  end

  context "when the project disables the department" do
    let(:rubocop_yml) { "plugins:\n  - officer_neetzsche\n\nNEETzsche:\n  Enabled: false\n" }

    it "disables every NEETzsche cop" do
      expect(config.for_cop("NEETzsche/NoComments")["Enabled"]).to be(false)
    end
  end

  context "when listed under require" do
    let(:rubocop_yml) { "require:\n  - officer_neetzsche\n" }

    it "loads the plugin anyway and asks for plugins: instead" do
      expect { config }.to output(/plugins: officer_neetzsche/).to_stderr
      expect(config.for_cop("NEETzsche/NoComments")["Enabled"]).to be(true)
    end
  end
end
