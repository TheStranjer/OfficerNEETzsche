# OfficerNEETzsche

[![Gem Version](https://badge.fury.io/rb/officer_neetzsche.svg)](https://rubygems.org/gems/officer_neetzsche)

RuboCop cops that enforce NEETzsche-isms. Every cop ships enabled: register the plugin and the rules apply.

## Cops

| Cop | Enforces | Autocorrect |
| --- | --- | --- |
| `NEETzsche/GeneratedMigrationTimestamp` | Migration timestamps come from `bin/rails generate migration`, not a keyboard. | No |
| `NEETzsche/NoComments` | No comments. The code explains itself. | Yes |

## Requirements

- Ruby 2.7 or newer.
- RuboCop 1.72 or newer, which introduced `plugins:`.

## Installation

Add the gem to your `Gemfile`:

```ruby
group :development, :test do
  gem "officer_neetzsche", require: false
end
```

Then run `bundle install`. Or install it directly:

```sh
gem install officer_neetzsche
```

The gem is published at [rubygems.org/gems/officer_neetzsche](https://rubygems.org/gems/officer_neetzsche).

## Usage

Register the plugin in `.rubocop.yml`:

```yaml
plugins:
  - officer_neetzsche
```

That is the whole setup. Every cop in the `NEETzsche` department is enabled by default, so `bundle exec rubocop` enforces them alongside your other cops. `AllCops: NewCops` does not apply: cops added in later releases are on the moment you upgrade.

Listing the gem under `require:` also works. RuboCop loads it as a plugin and prints a warning asking you to move it under `plugins:`.

Run only these cops:

```sh
bundle exec rubocop --only NEETzsche
```

Autocorrect what they flag:

```sh
bundle exec rubocop --autocorrect --only NEETzsche
```

## NEETzsche/GeneratedMigrationTimestamp

Flags a migration file whose 14-digit timestamp prefix looks typed rather than generated. `bin/rails generate migration` stamps the file with the current UTC second, and that second is almost never round. A person, or an LLM writing the file without running the generator, reaches for round numbers and patterns instead.

```
# bad
db/migrate/20240101000000_create_users.rb
db/migrate/20240101000001_create_posts.rb
db/migrate/20240115120000_add_email_to_users.rb
db/migrate/20240315143000_create_comments.rb
db/migrate/20240601123456_add_index_to_comments.rb

# good
db/migrate/20260409074855_create_users.rb
```

The offense sits on the first line of the file and names the tell:

- **No 14-digit timestamp.** `001_create_users.rb`, `20240101_create_users.rb`, `create_users.rb`.
- **Not a real date or time.** `2023-02-29`, month `13`, hour `24`, minute or second `60`.
- **In the future.** A date later than today in UTC.
- **A round clock time.** Seconds `00` on a five-minute mark: `00:00:00`, `12:00:00`, `14:30:00`, `09:15:00`.
- **A round hour plus a counter.** Up to nine seconds or nine minutes past any hour (`12:00:01`, `12:01:00`), or any whole minute or second past midnight (`00:00:23`, `00:37:00`). Incrementing the last digits of a copied timestamp produces these.
- **One number repeated.** `11:11:11`, `12:12:12`.
- **Consecutive numbers.** `01:02:03`, `10:11:12`.
- **A placeholder time.** `12:34:56`, `01:23:45`, `10:20:30`, `11:22:33`, `15:30:45`, `23:59:59`.

A time that only ends in `:00`, such as `14:17:00`, passes. The date is not judged beyond existing and having happened, so a migration generated on New Year's Day passes too.

The cop runs on `db/migrate/**/*.rb` and on the `db/*_migrate/**/*.rb` directories that multiple-database setups use. About one generated timestamp in a hundred lands on a clock-time tell, so an established project may see a few legitimate migrations flagged. Never rename a migration that has run anywhere, since its version is recorded in `schema_migrations`. Exclude the file instead:

```yaml
NEETzsche/GeneratedMigrationTimestamp:
  Exclude:
    - "db/migrate/20230614140700_add_index_to_users.rb"
```

Or silence it from the first line with a directive, which `NEETzsche/NoComments` allows:

```ruby
# rubocop:disable NEETzsche/GeneratedMigrationTimestamp
class AddIndexToUsers < ActiveRecord::Migration[8.0]
```

Projects that set `config.active_record.timestamped_migrations = false` number their migrations `001`, `002`, and so on. Every one of those trips the cop, so disable it there.

There is no autocorrect. The fix is to delete the file and run `bin/rails generate migration` again.

## NEETzsche/NoComments

Flags every comment. On autocorrect, a comment on its own line is deleted along with the line, and a trailing comment is deleted along with the whitespace before it.

```ruby
# bad
# Returns the user's full name.
def full_name
  "#{first_name} #{last_name}" # join with a space
end

# good
def full_name
  "#{first_name} #{last_name}"
end
```

Comments that change how Ruby or RuboCop behaves are allowed:

- Magic comments: `frozen_string_literal`, `encoding`, `coding`, `warn_indent`, `shareable_constant_value`, and Emacs `-*- ... -*-` lines.
- Shebangs, such as `#!/usr/bin/env ruby`.
- RuboCop directives: anything starting with `# rubocop:`, so `disable`, `enable`, `todo`, `disable-next`, `todo-next`, `push`, and `pop`.

`Style/Documentation` demands the class and module comments this cop forbids, so the plugin disables it. Re-enable it in your own `.rubocop.yml` if you want the two to fight.

## Configuration

Disable one cop:

```yaml
NEETzsche/NoComments:
  Enabled: false
```

Disable the whole department:

```yaml
NEETzsche:
  Enabled: false
```

Exclude paths from one cop:

```yaml
NEETzsche/NoComments:
  Exclude:
    - "db/schema.rb"
```

Directive comments are always allowed, so a comment can be kept by disabling the cop around it:

```ruby
# rubocop:disable NEETzsche/NoComments
# This comment survives.
# rubocop:enable NEETzsche/NoComments
```

## Development

```sh
bundle install
bundle exec rake
```

The default Rake task runs the specs and then RuboCop against this repository, with this gem's own cops loaded.

### Adding a cop

1. Create `lib/rubocop/cop/neetzsche/<cop_name>.rb` with a class under `RuboCop::Cop::NEETzsche`, and `require_relative` it from `lib/rubocop/cop/neetzsche_cops.rb`.
2. Add `NEETzsche/<CopName>` to `config/default.yml` with `Description`, `Enabled: true`, and `VersionAdded`.
3. Add `spec/rubocop/cop/neetzsche/<cop_name>_spec.rb` using `expect_offense`, `expect_correction`, and `expect_no_offenses`.
4. Add the cop to the table above and to `CHANGELOG.md`.

The suite fails if a registered `NEETzsche` cop is missing from `config/default.yml` or is not `Enabled: true`.

### Releasing

`bundle exec rake build` writes the gem to `pkg/`. `bundle exec rake release` tags the version, pushes the tag, and pushes the gem to RubyGems.
