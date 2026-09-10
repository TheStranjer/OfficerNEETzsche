# Changelog

## 0.2.0 (unreleased)

### Added

- `NEETzsche/GeneratedMigrationTimestamp`: flags a migration file whose timestamp prefix is missing, impossible, in the future, or a round or patterned clock time that a hand or an LLM typed instead of `bin/rails generate migration`. Runs on `db/migrate/**/*.rb` and `db/*_migrate/**/*.rb`.

## 0.1.0 (2026-09-09)

- Add `NEETzsche/NoComments`, ported from hyperborea-news.
- Disable `Style/Documentation` whenever the plugin is loaded, since it demands the comments `NEETzsche/NoComments` forbids.
