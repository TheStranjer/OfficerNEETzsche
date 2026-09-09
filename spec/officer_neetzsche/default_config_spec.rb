# frozen_string_literal: true

require "yaml"

RSpec.describe "config/default.yml" do
  let(:defaults) { YAML.safe_load(File.read(File.expand_path("../../config/default.yml", __dir__))) }
  let(:cops) { RuboCop::Cop::Registry.global.cops.select { |cop| cop.department == :NEETzsche } }
  let(:configured_cop_names) { defaults.keys.grep(%r{\ANEETzsche/}) }

  it "registers at least one NEETzsche cop" do
    expect(cops).not_to be_empty
  end

  it "enables the NEETzsche department" do
    expect(defaults.dig("NEETzsche", "Enabled")).to be(true)
  end

  it "enables every NEETzsche cop" do
    cops.each do |cop|
      expect(defaults.dig(cop.cop_name, "Enabled"))
        .to be(true), "#{cop.cop_name} must be `Enabled: true` in config/default.yml"
    end
  end

  it "configures exactly the cops that exist" do
    expect(configured_cop_names).to match_array(cops.map(&:cop_name))
  end

  it "documents every cop" do
    configured_cop_names.each do |name|
      expect(defaults[name]).to include("Description", "VersionAdded")
    end
  end
end
