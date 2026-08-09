# Music credits

Tracks under `game/audio/music/`. Most are CC0 from [OpenGameArt.org](https://opengameart.org); a few require attribution (see below).

## Core location / mood beds

| File | Source | License |
|---|---|---|
| `asianoriental1.ogg` | [Asianoriental1](https://opengameart.org/content/asianoriental1) | CC0 |
| `asianoriental2.ogg` | [Asianoriental2](https://opengameart.org/content/asianoriental2) | CC0 |
| `port_town.ogg` | [Port Town Loop](https://opengameart.org/content/port-town-loop) | Credit optional |
| `market_zone.ogg` | [Tyhosi Asian Sparrow 4](https://opengameart.org/content/tyhosi-asian-sparrow-4-kimono-market-zone) | CC0 |
| `home_garden.ogg` | [Tyhosi Sparrow](https://opengameart.org/content/tyhosi-sparrow) | CC0 |
| `garden3.ogg` | [Tyhosi Garden 3](https://opengameart.org/content/tyhosi-garden-3) | CC0 |
| `mysterious_lake.ogg` | [Mysterious Sparrow Lake](https://opengameart.org/content/mysterious-sparrow-lake) | CC0 |
| `fools_philosophy.ogg` | [Fool's Philosophy](https://opengameart.org/content/fools-philosophy) | CC0 |
| `city_pulse.ogg` / `four_sequence.ogg` | [Four Sequence](https://opengameart.org/content/four-sequence) | CC0 |
| `orient_high_strings.ogg` | [Oriental High Strings Short](https://opengameart.org/content/oriental-high-strings-short) | CC0 |
| `orientalsomber.ogg` | [Oriental Somber](https://opengameart.org/content/oriental-somber) | CC0 |
| `samurai_nights.ogg` | [Samurai Nights](https://opengameart.org/content/samurai-nights) (Majadroid) | CC-BY 3.0 / OGA-BY 3.0 |
| `dark_theme.ogg` | [Dark Theme](https://opengameart.org/content/dark-theme) | CC0 |
| `town_theme_0.ogg` | [Town Theme](https://opengameart.org/content/town-theme-0) | See OGA page |
| `alone.ogg` | [Alone](https://opengameart.org/content/alone) | CC0 |
| `defeat.ogg` | [Defeat](https://opengameart.org/content/defeat) | See OGA page |
| `determination.ogg` | [Determination](https://opengameart.org/content/determination) | CC0 |
| `menu_theme.ogg` | [Menu Theme](https://opengameart.org/content/menu-theme) | CC0 |
| `title_theme.ogg` | [Title Theme](https://opengameart.org/content/title-theme) | CC0 |

Additional oriental / town beds in the same folder (`koto_booth`, `rpg_orient_17`, `stereotypical_asian_town`, `orien`, `ch_ay_na`, `liyan`, `honor_lowrund_village_theme`, `melody_vollen`, …) are also pulled from OGA for pool rotation.

## Playback model

`SfxPlayer` keeps **per-location × mood pools** (calm / unease / tense / climax). Tracks:

1. change on enter/exit location
2. rotate when a track finishes (no infinite single-loop)
3. rotate again when day/period advances
4. avoid the last few recently heard tracks when the pool is wide enough
