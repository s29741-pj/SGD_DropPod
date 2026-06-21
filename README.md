# DROPPOD

A 2D action platformer set in the Warhammer 40,000 universe, built in Godot 4.

## Description

The player takes on the role of a Space Marine deployed via combat drop pod onto a planet overrun by Ork hordes. The mission is to fight through successive enemy sectors, eliminate hostile forces, and extract via Stormbird at the end of each level.

## Controls

| Key | Action |
|---|---|
| A / D or Arrow Keys | Move left / right |
| W | Jump |
| Space | Jetpack (boost jump) |
| S | Crouch |
| Left Mouse Button | Shoot / Attack |
| Right Mouse Button | Switch Bolter fire mode (burst / auto) |
| Q | Switch weapon |
| R | Reload Bolter |
| Escape | Pause |

## Mechanics

- **Bolter** — primary weapon, 30-round magazine, 150 reserve ammo, burst (3-round) or auto fire mode, animated reload.
- **Gatling** — pickup weapon found on levels, continuous fire with an overheating mechanic.
- **Knife** — 3-hit combo system, the only weapon available on level 4.
- **Jetpack** — boost jump consuming fuel, which regenerates while grounded.
- **Upgrade system** — between levels the player picks 1 of 3 random upgrades using earned points (damage, fire rate, HP, ammo capacity).
- **Checkpoints** — automatic save at the start of each level; the player respawns at the checkpoint on death without reloading the scene.

## Levels

1. **City Ruins** — introduction, controls tutorial, Gatling pickup.
2. **Bunker** — boss fight (twin-barreled Ork gunner).
3. **Defense Zone** — wave-based enemy survival.
4. **Finale** — knife-only combat mode, mission ending.

## Technical Requirements

- Engine: Godot 4
- Platform: Windows (PC)
- Resolution: 640×360 (pixel art)

## Installation and Running

1. Download and extract the `build.zip` build of the game can be found i `/build` folder.
2. Run `droppod.exe`.
3. The `droppod.pck` file must be in the same folder as the `.exe`.

## Art and Audio Credits

### Graphics
- Free Swamp Game Tileset — [CraftPix](https://craftpix.net)
- Free Animated Explosion Sprite Pack — [CraftPix](https://craftpix.net)
- Power Station Free Tileset — [CraftPix](https://craftpix.net)
- Free Industrial Zone Tileset — [CraftPix](https://craftpix.net)
- Free Exclusion Zone Tileset — [CraftPix](https://craftpix.net)

### Audio
- Gustav Holst — *The Planets: Mars* (public domain, [Internet Archive](https://archive.org))
- Free Cyberpunk Audio Pack 4 — [CraftPix](https://craftpix.net)
- Transformers Fusion Cannon SFX — [MyInstants](https://myinstants.com)

### Engine
- [Godot Engine 4](https://godotengine.org) — MIT License

## License

Coursework project. Bundled assets remain under the licenses of their original authors (see Credits section above).
