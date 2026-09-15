# OfficerNEETzsche

[![Gem Version](https://badge.fury.io/rb/officer_neetzsche.svg)](https://rubygems.org/gems/officer_neetzsche)

RuboCop cops that enforce NEETzsche-isms. Every cop ships enabled: register the plugin and the rules apply.

## Cops

| Cop | Enforces | Autocorrect |
| --- | --- | --- |
| `NEETzsche/GeneratedMigrationTimestamp` | Migration timestamps come from `bin/rails generate migration`, not a keyboard. | No |
| `NEETzsche/MultilineConditionalBody` | An `if`, `unless`, `while`, or `until` body of more than one statement, or more than one line, is a method of its own. | No |
| `NEETzsche/NoComments` | No comments. The code explains itself. | Yes |
| `NEETzsche/StatementModifier` | An `if`, `unless`, `while`, `until`, or `rescue` around one statement is a modifier. | Yes |

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

## NEETzsche/MultilineConditionalBody

Flags an `if`, `unless`, `elsif`, `else`, `while`, or `until` whose body is more than one statement, or one statement that spans lines. The fix is to name what the body does and move it into a method of its own, after which `NEETzsche/StatementModifier` rewrites the call site as a modifier. Between them, the two cops leave a conditional two shapes: a modifier, or a block whose branches are one statement each.

```ruby
# bad
if condition?
  do_this
  do_that
end

while queue.any?
  item = queue.pop
  item.call
end

if condition?
  items.each do |item|
    item.call
  end
end

# good
do_stuff if condition?
work_one_item while queue.any?
call_items if condition?

def do_stuff
  do_this
  do_that
end

def work_one_item
  item = queue.pop
  item.call
end

def call_items
  items.each { |item| item.call }
end

# good, because each branch is one statement
if condition?
  do_this
else
  do_that
end
```

The offense sits on the keyword of the branch: `if`, `unless`, `elsif`, `else`, `while`, or `until`. Each branch is judged on its own, so an `if` with a two-statement body and a one-statement `else` gets one offense, on the `if`. A heredoc counts as the lines it spans. A modifier whose body spans lines, such as `begin ... end if condition?`, is flagged too. A conditional nested inside another is flagged at every level whose body spans lines, and fixing the innermost usually clears the rest.

Left alone:

- A body of one statement on one line, which is `NEETzsche/StatementModifier`'s to rewrite.
- Ternaries, empty bodies, and `begin ... end while` loops.
- A condition that spans lines. Only the body is measured.

There is no autocorrect. The method needs a name that says what the body does, and that is a decision for a person. Moving the body by hand also means deciding what it reads and writes: a local variable the body uses becomes a parameter, one it assigns for later use becomes the return value, and a `return`, `break`, or `next` inside it means something else once it sits in another method. Once the body is one call, `NEETzsche/StatementModifier` turns the block into a modifier under `rubocop --autocorrect`.

`Style/GuardClause` and `Style/Next` may flag the same block with a different fix. Either fix satisfies this cop too, since a guard clause or a `next` leaves no block behind. Under `rubocop --autocorrect`, `Layout/LineLength` may wrap the arguments of a long modifier line and `Style/MultilineIfModifier` then restore the block form, which this cop flags. The way out is a method.

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

## NEETzsche/StatementModifier

Flags an `if`, `unless`, `while`, `until`, or `rescue` whose body is one statement on one line, and rewrites it as a statement modifier. How long the modifier line ends up does not matter.

```ruby
# bad
if condition?
  do_thing
end

until queue.empty?
  queue.pop.call
end

begin
  fetch
rescue
  fallback
end

def call
  fetch
rescue StandardError
  fallback
end

# good
do_thing if condition?
queue.pop.call until queue.empty?
fetch rescue fallback

def call
  fetch rescue fallback
end

# left to NEETzsche/MultilineConditionalBody, because the body is more than one statement
if condition?
  do_this
  do_that
end
```

The offense sits on the keyword. A `rescue` counts when it is the only clause, rescues `StandardError` (bare, or named, since that is what the modifier rescues), binds no variable, and has no `else`; the `begin`/`end` around it goes away, while a `def`, a block, or an `ensure` around it stays. Parentheses are added where the value is used, so `value = if condition? then compute end` becomes `value = (compute if condition?)` and `call(begin; fetch; rescue; fallback; end)` becomes `call((fetch rescue fallback))`. An assigned `rescue` needs none: `value = fetch rescue fallback` already binds that way.

Left alone, because the block form is the only correct one:

- A body of more than one statement, a statement that spans lines, or a condition that spans lines. The first two are for `NEETzsche/MultilineConditionalBody`.
- `else`, `elsif`, ternaries, and `begin ... end while` loops.
- A body that is itself an `if`, `unless`, `while`, `until`, `case`, or `rescue`, in either form. No chained modifiers.
- A `rescue` that names another class, lists several, binds a variable, has several clauses, an `else`, or an empty body or handler.
- A comment on any line of the block other than the first. A comment on the keyword line moves to the end of the modifier line.
- A heredoc anywhere inside.
- Anything whose meaning changes when the body is parsed before the condition, which is what the modifier form does: a condition that assigns a local variable, matches a pattern, or captures a named group; a body that assigns a name the condition calls as a method, as in `if name.nil?` followed by `name = default`; and an endless method definition, which would swallow the modifier.

The plugin disables `Style/IfUnlessModifier` and `Style/WhileUntilModifier`, which this cop subsumes, and `Style/RescueModifier`, which forbids what this cop demands. Re-enable them in your own `.rubocop.yml` if you want them back; `Style/IfUnlessModifier` will then fight over any modifier line longer than `Layout/LineLength` allows. `Layout/LineLength` itself is not consulted. If a modifier line is too long for it, shorten the statement or the condition, or exclude the file. Under `rubocop --autocorrect`, `Layout/LineLength` may instead wrap the arguments of a call on that line, after which `Style/MultilineIfModifier` restores the block form around the now multi-line body, and this cop leaves it there. `Style/GuardClause` and `Style/SoleNestedConditional` may flag the same block with a different fix; whichever corrects first wins, and the result satisfies both.

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
