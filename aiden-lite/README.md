# Godot puzzle game: scripts & structure

Written for **Godot 4.3+** (GDScript). I could not run Godot while writing this, so treat it as a solid first pass: if the console shows an error on first run, it will point at the exact line.

## 1. Setup (5 minutes)

1. Copy all the folders into your project (`res://`).
2. **Project > Project Settings > Globals (Autoload)**, add these four **in this order**:

   | Name | Path |
   |---|---|
   | GameData | `res://autoload/game_data.gd` |
   | Settings | `res://autoload/settings.gd` |
   | GameState | `res://autoload/game_state.gd` |
   | Journal | `res://autoload/journal.gd` |

3. **Application > Run > Main Scene** = `res://ui/main_menu.tscn`
4. Optional: **Layer Names > 3D Physics**: 1 World, 2 Player, 3 Pickable, 4 Rock, 5 Interact. (Layers/masks are set from code, so this is only for readability.)
5. **The input map is created by code** (`Settings`): WASD, Space, E (interact), J (journal), and it supports rebinding in Options. Nothing to set up.
6. Press **F6** on `levels/level_template.tscn` to test straight away: a floor, two boxes (stack them!), a rock (push/pull) and the player.

## 2. Folder structure

```
autoload/   game_data.gd    levels, collectibles, credits text, scene paths  (EDIT THIS)
            game_state.gd   meter, progress, save/load, scene fades, level flow
            settings.gd     options, input map, audio buses
            journal.gd      collectibles menu (J), builds itself in code
player/     player.gd / player.tscn
objects/    pickable.gd  pushable_rock.gd  puzzle_socket.gd  puzzle_controller.gd
            collectible.gd  kill_zone.gd  checkpoint.gd  level_goal.gd  cinematic_spot.gd
levels/     level_base.gd (root script for every level), level_1/2.tscn (copies of the template)
cinematics/ cinematic_scene.gd, cinematic_1/2/3.tscn (empty placeholders)
ui/         main_menu, world_map, credits, options_menu, hud
```

## 3. Game flow (edit in `game_data.gd`)

New Game -> `cinematic_1` -> 2D map -> Level 1 -> `cinematic_2` -> map (level 2 unlocked) -> Level 2 -> `cinematic_3` (ending) -> credits -> main menu.

To add a level: add a dictionary to `GameData.LEVELS` (scene, map position, cinematic after). The last level's `cinematic_after` is the ending cinematic. Continue = open the map with everything unlocked so far. Progress and collectibles save to `user://save.json`.

## 4. Building a level

1. Duplicate `level_template.tscn`. Root has `level_base.gd`. Keep the **Player** instance.
2. Level geometry: `StaticBody3D` on physics layer 1 (default).
3. Boxes / pieces: `RigidBody3D` + `CollisionShape3D` (box shape, origin at center) + `pickable.gd`. Set `piece_id` for puzzle pieces (leave empty for plain boxes).
4. Rocks: `CharacterBody3D` + `CollisionShape3D` + `pushable_rock.gd`.
5. Puzzle: `Area3D` + shape + `puzzle_socket.gd` (`required_piece_id`). Add a `Node` with `puzzle_controller.gd`, drag the sockets in, and pick an AnimationPlayer + animation to play when solved (door opens...).
6. `Area3D` scenes with a `CollisionShape3D`:
   - `kill_zone.gd`: big box under the map (fall: damage + respawn; boxes/rocks return to start)
   - `checkpoint.gd`: place on the floor
   - `level_goal.gd`: end of level (optional `required_puzzle`)
   - `collectible.gd`: set `collectible_id` (+ your model as a child)
   - `cinematic_spot.gd`: set AnimationPlayer + animation (+ optional Camera3D); the meter regenerates during it

## 5. Controls & behaviour

- **WASD** move (camera-relative), **Space** jump, mouse orbits camera, **E** interact, **J** journal.
- **E** near a box/piece: pick up. **E** again: drop (it snaps on top of a box below it, so stacking is clean). **E** next to a socket while holding a piece: insert.
- **E** facing a rock: grab it. **W** pushes, **S** pulls, **E** releases. Movement is locked to the axis you grabbed from, and the rock stops when blocked, so it can't overlap anything.
- Meter: wrong piece = `damage_on_wrong` (default 10), falling = `fall_damage` (default 20). At 0: KO animation, meter back to 50%, respawn at last checkpoint. The meter refills to full at the start of each level (change in `level_base.gd`).
- For your own puzzles (levers, sequences): call `GameState.puzzle_failed(10)` on a mistake.

## 6. Where YOU plug in art and narrative

- **Character**: put your model inside `Player/Model`, delete `Placeholder` and `Nose`, assign its AnimationPlayer to `animation_player`. Names used if they exist: `idle, walk, jump, fall, carry_idle, carry_walk, push_idle, push, pull, ko`. Adjust `HoldPoint` so carried objects sit in the hands.
- **Cinematics** (`cinematics/*.tscn`): add cameras, models, subtitles UI, an AnimationPlayer (Call Method tracks work well for dialogue), assign it in the root's `animation_player`. Esc skips. Video works via `video_player`.
- **Journal text/icons**: `GameData.COLLECTIBLES` (BBCode allowed).
- **Menus**: built in code so they work immediately. Restyle with a `Theme` on the root Control, or add background nodes in the `.tscn` files. Set the map `background` in `world_map.tscn`'s inspector.
- Music: `music` / `level_music` exports on menus, map, credits, levels and cinematics (they play on the "Music" bus).

## 7. Known simplifications

- Carried objects can clip through thin walls while held.
- Rocks slide only along world X or Z (fits grid-style puzzles).
- No pause menu yet (Esc does nothing in levels); easy to add later with `get_tree().paused`.
