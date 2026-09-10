# frozen_string_literal: true

RSpec.describe RuboCop::Cop::NEETzsche::GeneratedMigrationTimestamp, :config do
  def migration(basename)
    "db/migrate/#{basename}.rb"
  end

  def expect_generated(timestamp)
    expect_no_offenses(<<~RUBY, migration("#{timestamp}_create_users"))
      class CreateUsers < ActiveRecord::Migration[8.0]
      end
    RUBY
  end

  def expect_made_up(timestamp, tell)
    expect_offense(<<~RUBY, migration("#{timestamp}_create_users"))
      class CreateUsers < ActiveRecord::Migration[8.0]
      ^ Migration timestamp `#{timestamp}` looks made up; #{tell}. Let `bin/rails generate migration` name the file.
      end
    RUBY
  end

  def expect_no_timestamp(basename)
    expect_offense(<<~RUBY, migration(basename))
      class CreateUsers < ActiveRecord::Migration[8.0]
      ^ Migration filename `#{basename}.rb` does not start with a 14-digit `YYYYMMDDHHMMSS_` timestamp. Let `bin/rails generate migration` name the file.
      end
    RUBY
  end

  describe "generated timestamps" do
    it "accepts what bin/rails generate migration produces" do
      expect_generated("20260409074855")
    end

    it "accepts an engine migration with a scope suffix" do
      expect_no_offenses(<<~RUBY, migration("20260409074855_create_users.blorgh"))
        class CreateUsers < ActiveRecord::Migration[8.0]
        end
      RUBY
    end

    it "accepts a real time of day on the first of January" do
      expect_generated("20240101143052")
    end

    it "accepts a time that merely ends in :00" do
      expect_generated("20230614141700")
    end

    it "accepts the first second and minute past the counter range" do
      expect_generated("20230614120010")
      expect_generated("20230614121100")
    end

    it "accepts a real time of day in the midnight hour" do
      expect_generated("20230614001742")
    end
  end

  describe "round clock times" do
    it "flags midnight, the default that gets typed" do
      expect_made_up("20240101000000", "`00:00:00` is a round clock time")
    end

    it "flags noon" do
      expect_made_up("20240115120000", "`12:00:00` is a round clock time")
    end

    it "flags the top of any hour" do
      expect_made_up("20260409070000", "`07:00:00` is a round clock time")
    end

    it "flags quarter hours" do
      expect_made_up("20240315091500", "`09:15:00` is a round clock time")
      expect_made_up("20240315143000", "`14:30:00` is a round clock time")
      expect_made_up("20240315164500", "`16:45:00` is a round clock time")
    end

    it "flags five-minute marks" do
      expect_made_up("20240315142500", "`14:25:00` is a round clock time")
      expect_made_up("20240315101000", "`10:10:00` is a round clock time")
    end
  end

  describe "counters" do
    it "flags a batch numbered in the seconds after midnight" do
      expect_made_up("20240101000001", "`00:00:01` is a round hour plus a counter")
      expect_made_up("20240101000002", "`00:00:02` is a round hour plus a counter")
      expect_made_up("20240101000023", "`00:00:23` is a round hour plus a counter")
    end

    it "flags a batch numbered in the minutes after midnight" do
      expect_made_up("20240101000100", "`00:01:00` is a round hour plus a counter")
      expect_made_up("20240101003700", "`00:37:00` is a round hour plus a counter")
    end

    it "flags a batch numbered in the seconds after another hour" do
      expect_made_up("20240601120001", "`12:00:01` is a round hour plus a counter")
      expect_made_up("20240601120009", "`12:00:09` is a round hour plus a counter")
    end

    it "flags a batch numbered in the minutes after another hour" do
      expect_made_up("20240601120100", "`12:01:00` is a round hour plus a counter")
      expect_made_up("20240601120900", "`12:09:00` is a round hour plus a counter")
    end
  end

  describe "keyboard patterns" do
    it "flags one number repeated" do
      expect_made_up("20240101111111", "`11:11:11` repeats one number")
      expect_made_up("20240101121212", "`12:12:12` repeats one number")
    end

    it "flags consecutive numbers" do
      expect_made_up("20240101010203", "`01:02:03` is three consecutive numbers")
      expect_made_up("20240101101112", "`10:11:12` is three consecutive numbers")
    end

    it "flags placeholder times" do
      expect_made_up("20240101123456", "`12:34:56` is a placeholder time")
      expect_made_up("20240101012345", "`01:23:45` is a placeholder time")
      expect_made_up("20240101102030", "`10:20:30` is a placeholder time")
      expect_made_up("20240101112233", "`11:22:33` is a placeholder time")
      expect_made_up("20240315153045", "`15:30:45` is a placeholder time")
      expect_made_up("20231231235959", "`23:59:59` is a placeholder time")
    end
  end

  describe "impossible timestamps" do
    it "flags a date that does not exist" do
      expect_made_up("20230229143052", "`2023-02-29` is not a real date")
      expect_made_up("20240431143052", "`2024-04-31` is not a real date")
      expect_made_up("20241301143052", "`2024-13-01` is not a real date")
      expect_made_up("20240100143052", "`2024-01-00` is not a real date")
    end

    it "flags a time that does not exist" do
      expect_made_up("20240101240000", "`24:00:00` is not a real time")
      expect_made_up("20240101126000", "`12:60:00` is not a real time")
      expect_made_up("20240101120060", "`12:00:60` is not a real time")
    end

    it "flags a date that has not happened yet" do
      expect_made_up("99991231133742", "`9999-12-31` is in the future")
    end
  end

  describe "filenames without a timestamp" do
    it "flags a sequential version" do
      expect_no_timestamp("001_create_users")
    end

    it "flags a date with no time" do
      expect_no_timestamp("20240101_create_users")
    end

    it "flags a timestamp missing a digit" do
      expect_no_timestamp("2024010112000_create_users")
    end

    it "flags a timestamp with a digit too many" do
      expect_no_timestamp("202401011200000_create_users")
    end

    it "flags a file with no version at all" do
      expect_no_timestamp("create_users")
    end
  end

  it "can be silenced from the first line" do
    expect_no_offenses(<<~RUBY, migration("20240101000000_create_users"))
      # rubocop:disable NEETzsche/GeneratedMigrationTimestamp
      class CreateUsers < ActiveRecord::Migration[8.0]
      end
    RUBY
  end
end
