# Changelog

All notable changes to LootAssist will be documented here.

## 12.002

### Fixed
- Fixed Blizzard's loot window remaining visible while LootAssist is enabled.
- LootAssist now suppresses both `LOOT_OPENED` and `LOOT_READY` on Blizzard's LootFrame and restores Blizzard's original event registrations when needed.

## 12.001

### Added
- Support for Retail and Classic World of Warcraft variants.
- Added `/lootassist` and `/lass` command interfaces.
- Added per-character override support for the account-wide default.

### Changed
- Modernized LootAssist for World of Warcraft 12.1.
- Removed the Ace3 dependency.
- Reworked loot tracking to use loot events instead of chat-message parsing.
- Improved handling of busy loot objects.
- Improved master loot compatibility.
- Updated project packaging and GitHub release workflow.
- Changed project license to MIT.

### Fixed
- Character-specific `off` now persists correctly when the account default is enabled.
- Removed use of obsolete currency APIs.
- Corrected master-loot detection for the current `C_PartyInfo.GetLootMethod()` API.
