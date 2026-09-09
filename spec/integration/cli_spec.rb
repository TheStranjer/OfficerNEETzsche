# frozen_string_literal: true

RSpec.describe "rubocop with officer_neetzsche", :isolated_environment, :restore_configuration do
  include_context "mock console output"

  let(:cli) { RuboCop::CLI.new }

  before do
    File.write(".rubocop.yml", <<~YAML)
      plugins:
        - officer_neetzsche

      AllCops:
        SuggestExtensions: false
    YAML
    File.write("example.rb", <<~RUBY)
      # frozen_string_literal: true

      # explains foo
      def foo; end
    RUBY
  end

  it "shows NEETzsche/NoComments as enabled" do
    expect(cli.run(%w[--show-cops NEETzsche/NoComments])).to eq(0)
    expect($stdout.string).to include("NEETzsche/NoComments:").and include("Enabled: true")
  end

  it "reports NEETzsche/NoComments offenses" do
    expect(cli.run(%w[--format simple --only NEETzsche/NoComments example.rb])).to eq(1)
    expect($stdout.string).to include("NEETzsche/NoComments: Avoid comments; let the code speak for itself.")
  end

  it "autocorrects them" do
    expect(cli.run(%w[--format simple --only NEETzsche/NoComments --autocorrect example.rb])).to eq(0)
    expect(File.read("example.rb")).to eq("# frozen_string_literal: true\n\ndef foo; end\n")
  end
end
