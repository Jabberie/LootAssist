# LootAssist

LootAssist is a lightweight World of Warcraft addon focused on fast, reliable looting.

Originally built with multiboxing in mind, LootAssist works equally well on a single character and supports Retail and Classic variants of World of Warcraft.

## Features

- Suppresses the normal loot window while LootAssist is active.
- Immediately attempts to loot every available slot.
- Automatically retries when WoW reports that a loot object is busy.
- Reports items that were left behind when the loot window closes.
- Supports an account-wide default with per-character overrides.
- Automatically falls back to Blizzard's normal loot window when master loot is active.
- No external libraries or dependencies.

## Commands

| Command | Action |
| --- | --- |
| `/lootassist on` | Enable LootAssist on this character. |
| `/lootassist off` | Disable LootAssist on this character. |
| `/lootassist default` | Make this character follow the account default. |
| `/lootassist defaulton` | Enable the account default. |
| `/lootassist defaultoff` | Disable the account default. |
| `/lootassist check` | Show the current settings. |

The original shortcuts remain supported:

`/lasson`, `/lassoff`, `/lassdefaulton`, `/lassdefaultoff`, `/lasscheck`

## Installation

Copy the `LootAssist` folder into the appropriate World of Warcraft `Interface/AddOns/` directory.

## Links

- GitHub: Jabberie/LootAssist
- CurseForge project ID: 255491

## License

LootAssist is licensed under the MIT License.