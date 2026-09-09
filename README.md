# OfficerNEETzsche

RuboCop cops that enforce NEETzsche-isms. Every cop ships enabled: register the plugin and the rules apply.

## Cops

| Cop | Enforces | Autocorrect |
| --- | --- | --- |
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

Until the gem is published to RubyGems, point Bundler at the repository instead:

```ruby
group :development, :test do
  gem "officer_neetzsche", github: "TheStranjer/OfficerNEETzsche", require: false
end
```

Then run `bundle install`.

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
