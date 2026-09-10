# frozen_string_literal: true

require "fileutils"

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

  context "with migrations" do
    before do
      write_migration("db/migrate/20260409070000_create_users.rb", "CreateUsers")
      write_migration("db/migrate/20260409074855_create_posts.rb", "CreatePosts")
      write_migration("db/animals_migrate/20260409000001_create_dogs.rb", "CreateDogs")
      write_migration("lib/20260409070000_not_a_migration.rb", "NotAMigration")
    end

    def write_migration(path, class_name)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, "class #{class_name} < ActiveRecord::Migration[8.0]\nend\n")
    end

    it "shows NEETzsche/GeneratedMigrationTimestamp as enabled for migration directories" do
      expect(cli.run(%w[--show-cops NEETzsche/GeneratedMigrationTimestamp])).to eq(0)
      expect($stdout.string).to include("Enabled: true").and include("db/migrate/**/*.rb")
    end

    it "reports made-up timestamps in every migration directory and nowhere else" do
      expect(cli.run(%w[--format simple --only NEETzsche/GeneratedMigrationTimestamp])).to eq(1)
      expect($stdout.string).to include("== db/migrate/20260409070000_create_users.rb ==")
        .and include("07:00:00 is a round clock time")
        .and include("== db/animals_migrate/20260409000001_create_dogs.rb ==")
        .and include("00:00:01 is a round hour plus a counter")
        .and include("5 files inspected, 2 offenses detected")
      expect($stdout.string).not_to include("create_posts")
      expect($stdout.string).not_to include("not_a_migration")
    end
  end
end
