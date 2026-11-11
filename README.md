<div align="center">

<img src="icon.svg" alt="Save the Sheep" width="128" />

# 🐑 Save the Sheep

**An arcade action game where you keep the sheep alive to finish every level.**

<a href="https://dupot-org.itch.io/save-the-sheep"><img src="export/promo/save_the_sheep.gif" alt="Save the Sheep gameplay: Gordon jumps over a gate to open it for the sheep, blasts a T-Rex with his water gun and rides his motorbike in the bonus level, then two players open a gate together and race two motorbikes" width="720" /></a>

*Run, jump, blast dinosaurs with your water gun and get the sheep home safe, alone or with a friend.*

**👥 New: 2 players co-op on the same screen!**

**[▶ Play it now in your browser](https://dupot-org.itch.io/save-the-sheep)** · **[Get it on Flathub](https://flathub.org/apps/org.dupot.savethesheep)**

Free · 1–2 players · Age 3+ · Linux x86_64 & aarch64 · Web · Made with Godot 4.7

[![Flathub](https://img.shields.io/flathub/v/org.dupot.savethesheep?logo=flathub&logoColor=white&label=Flathub&color=4a90d9)](https://flathub.org/apps/org.dupot.savethesheep)
[![Snap Store](https://img.shields.io/badge/Snap%20Store-dupot--save--the--sheep-82BEA0?logo=snapcraft&logoColor=white)](https://snapcraft.io/dupot-save-the-sheep)
[![itch.io](https://img.shields.io/badge/itch.io-Play%20in%20browser-FA5C5C?logo=itchdotio&logoColor=white)](https://dupot-org.itch.io/save-the-sheep)
[![Godot 4.7](https://img.shields.io/badge/Godot-4.7-478CBF?logo=godotengine&logoColor=white)](https://godotengine.org)
[![License: LGPL-2.1](https://img.shields.io/badge/License-LGPL--2.1-blue.svg)](LICENSE)

<a href="https://flathub.org/apps/org.dupot.savethesheep"><img width="200" alt="Get it on Flathub" src="https://flathub.org/api/badge?locale=en"/></a>
<a href="https://snapcraft.io/dupot-save-the-sheep"><img width="200" alt="Get it from the Snap Store" src="https://snapcraft.io/static/images/badges/en/snap-store-black.svg"/></a>

</div>

---

## 📖 About

Gordon has one job: **protect the sheep**. The sheep walks on its own, and Gordon has to clear the way so it can reach the end of each level in one piece.

- 🌃 **A city at night**: run and jump across rooftops, streets and building sites under a starry sky
- 💦 **Water gun**: blast the enemies (dinosaurs included!) before they reach the sheep
- 🚪 **Action handle**: open gates to let the sheep through
- 🛗 **Elevators**: turn them on to carry the sheep over obstacles
- 🏍️ **Bonus level**: ride the motorbike, jump the rocks and grab water and desserts before time runs out
- 👥 **2 players co-op**: play together on the same screen, each player with his own life bar; gates and elevators only move once both players pull the handle, a player down is back at the next level, and the bonus level gets two motorbikes on two roads (the sheep rides with player 1)

If the sheep doesn't make it, neither do you.

## 📸 Screenshots

<div align="center">

| Level start | Jump the gate, then open it | Watch out for the T-Rex! |
|:---:|:---:|:---:|
| ![Level 01 start](export/Linux/screenshots/level_01_start.png) | ![Gordon jumps over a gate](export/Linux/screenshots/level_01_gate.png) | ![Gordon fights a T-Rex](export/Linux/screenshots/level_01_trex.png) |

| 2 players: controls and test | Both pull the handle | Two motorbikes, two roads |
|:---:|:---:|:---:|
| ![Keys of the two players](export/Linux/screenshots/menu_two_players.png) | ![Two players open a gate together](export/Linux/screenshots/level_01_two_players.png) | ![Two motorbikes in the bonus level](export/Linux/screenshots/bonus_level_two_players.png) |

| Main menu | Bonus level |
|:---:|:---:|
| ![Main menu](export/Linux/screenshots/menu.png) | ![Motorbike bonus level](export/Linux/screenshots/bonus_level.png) |

</div>

## 🎮 Controls

| Action | 1 player | 2 players: player 1 | 2 players: player 2 |
|---|---|---|---|
| Move | ← → arrow keys | `Q` `D` (`A` `D` on QWERTY) | ← → arrow keys |
| Jump | `Space` or `Z` | `Z` (`W` on QWERTY) | ↑ |
| Shoot | `Enter` or `A` | `F` | `L` |
| Action (gates, elevators) | `Tab` or `E` | `G` | `K` |
| Pause | `Esc` | `Esc` | `Esc` |
| Sound on/off | `M` | `M` | `M` |

After **1 PLAYER** or **2 PLAYERS** in the menu, the controls screen lets each player pick **keyboard or gamepad**, change his keys / buttons (saved for the next time), and try them with his Gordon in the test area (**TEST**) before **START**. 🎮 With a gamepad, moving stays on the d-pad and the left stick; Android gets on-screen touch controls.

## 📦 Install

### Flathub (Linux, recommended)

Available for **x86_64** and **aarch64** (around 35 MiB to download).

```bash
flatpak install flathub org.dupot.savethesheep
flatpak run org.dupot.savethesheep
```

You can also install it from GNOME Software, KDE Discover or any app store that uses Flathub. The Flatpak manifest lives in [flathub/org.dupot.savethesheep](https://github.com/flathub/org.dupot.savethesheep).

### Snap Store (Linux)

```bash
sudo snap install dupot-save-the-sheep
```

### itch.io (browser)

Play it in your browser, no install needed: **[dupot-org.itch.io/save-the-sheep](https://dupot-org.itch.io/save-the-sheep)**

## 🛠️ Build from source

1. Install [Godot 4.7](https://godotengine.org/download).
2. Clone the repository:
   ```bash
   git clone https://github.com/imikado/dupotSaveTheSheep.git
   ```
3. Open `project.godot` in Godot and press **F5** to play.

Export presets for **Linux** and **HTML5** are included in `export_presets.cfg`.

Helper scripts (set `GODOT` if Godot isn't in your `PATH`):

| Script | What it does |
|---|---|
| `./export_html5.sh` | Exports the web build and zips it for itch.io |
| `./generate_itchio.sh` | Builds the itch.io banner, embed background and `export/itchio/ITCHIO.md` from the screenshots (needs `python3-pil`) |
| `./export_flathub.sh` | Exports the `.pck` and builds `export/Linux/bundle.tar.gz` for the Flathub manifest |
| `tools/capture/capture.sh` | Plays an automated run (solo, then 2 players) and regenerates the screenshots and the promo GIF (needs `ffmpeg`) |
| `tools/capture/promo_video.sh` | Records the automated run (solo, then 2 players) in 1080p60 with sound and edits the YouTube trailer `export/promo/save_the_sheep.mp4` (needs `ffmpeg`) |

## 🕹️ More from dupot.org

Also on Flathub from the same developer:

- **Little Adventure**
- **Beat And Match To Pass**
- **Easyflatpak**

See them all on [dupot.org](https://www.dupot.org/games.html).

## 🐛 Feedback

Found a bug or have an idea? [Open an issue](https://github.com/imikado/dupotSaveTheSheep/issues).

## 📜 License

This game is released under the [GNU LGPL v2.1](LICENSE).

---

<div align="center">

Made with ❤️ and [Godot Engine](https://godotengine.org) by [Michael Bertocchi](https://www.dupot.org/games.html) · [dupot.org](https://www.dupot.org)

</div>
