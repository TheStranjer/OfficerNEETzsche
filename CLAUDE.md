# OfficerNEETzsche

RuboCop plugin gem. Every cop is enabled by default; `AllCops: NewCops` does not apply.

## Always do SemVer

Version lives in `lib/officer_neetzsche/version.rb` and is read by the gemspec. Every published change bumps it, and the bump kind is decided by the user-facing effect on a codebase that runs `rubocop` with this plugin, not by how big the diff is.

### What counts as what

- **MAJOR** (`X.0.0`): a currently passing codebase can start failing without the user opting in, or the user must change `.rubocop.yml` to keep the old behavior. Examples: an existing cop starts flagging code it used to allow; a cop is renamed or removed; a cop's config key is renamed or removed or its default changes; a cop's autocorrect output changes meaning; `required_ruby_version` or the minimum `rubocop` version is raised; the plugin stops disabling `Style/Documentation`.
- **MINOR** (`x.Y.0`): new capability with no forced change for existing users. Examples: a new cop in the `NEETzsche` department; a new optional config key with a default that preserves old behavior; adding autocorrect to a cop that had none; a cop starts ignoring something it used to flag (it only gets more permissive). Note that because every cop is on by default, a new cop can still produce new offenses on upgrade. That is accepted and documented in the README, so a new cop is MINOR, not MAJOR. The cop's `VersionAdded` in `config/default.yml` is the release it ships in.
- **PATCH** (`x.y.Z`): bug fixes and internals. Examples: a false positive or false negative fixed within the cop's documented intent; a crash fixed; a wrong offense message or location fixed; autocorrect producing invalid Ruby fixed; docs, specs, gemspec metadata, dev dependencies.

Judgment call for "false positive fix" vs "cop got stricter": if the change makes the cop flag code it previously allowed, and that code was passing on purpose for anyone, it is MAJOR. If it was clearly a bug against the cop's stated description, it is PATCH.

### Pre-1.0

While the version is `0.y.z`, the standard convention applies: MINOR (`0.Y.0`) carries anything MAJOR or MINOR above, PATCH carries fixes. Still name breaking changes explicitly in the changelog. Go to `1.0.0` when the cop set and config surface are stable enough that breaking changes should be rare.

### Mechanics of a release

1. Bump `VERSION` in `lib/officer_neetzsche/version.rb`.
2. Convert the `(unreleased)` heading in `CHANGELOG.md` to the version and date, grouped as Added / Changed / Fixed / Removed, with breaking changes called out.
3. Set `VersionAdded` on any new cop and `VersionChanged` on any cop whose behavior or config changed, in `config/default.yml`.
4. `bundle exec rake` must pass.
5. Tag `vX.Y.Z`, then `gem build` and `gem push`. Do not commit built `.gem` files.

Never reuse or overwrite a published version. If a release is wrong, ship the next PATCH.
