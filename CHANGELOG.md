# Changelog

## 0.3.0 (unreleased)

### Added

- `NEETzsche/StatementModifier`: rewrites an `if`, `unless`, `while`, `until`, or `rescue` whose body is one statement on one line as a statement modifier, whatever the resulting line length. Method-level and block-level `rescue` clauses count. Bodies that are themselves conditionals or rescues, comments inside the block, heredocs, and conditions or bodies whose meaning would change when the body is parsed first are left alone. Autocorrects, adding parentheses where the value is used.

### Changed

- **Breaking:** the plugin now disables `Style/IfUnlessModifier` and `Style/WhileUntilModifier`, which `NEETzsche/StatementModifier` subsumes, and `Style/RescueModifier`, which forbids what it demands. Re-enable them in your own `.rubocop.yml` if you want them back; `Style/IfUnlessModifier` will then fight over modifier lines that exceed `Layout/LineLength`.

## 0.2.0 (2026-09-09)

### Added

- `NEETzsche/GeneratedMigrationTimestamp`: flags a migration file whose timestamp prefix is missing, impossible, in the future, or a round or patterned clock time that a hand or an LLM typed instead of `bin/rails generate migration`. Runs on `db/migrate/**/*.rb` and `db/*_migrate/**/*.rb`.

## 0.1.0 (2026-09-09)

- Add `NEETzsche/NoComments`, ported from hyperborea-news.
- Disable `Style/Documentation` whenever the plugin is loaded, since it demands the comments `NEETzsche/NoComments` forbids.
