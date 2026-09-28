extends Node
## AUTOLOAD "GameData"
## All content-like data lives here: edit this file to add levels, collectibles and credits.

# --- 3D physics layers (also name them in Project Settings > Layer Names > 3D Physics) ---
const LAYER_WORLD := 1      # layer 1: static level geometry
const LAYER_PLAYER := 2     # layer 2
const LAYER_PICKABLE := 4   # layer 3: boxes / puzzle pieces
const LAYER_ROCK := 8       # layer 4: pushable rocks
const LAYER_INTERACT := 16  # layer 5: sockets, collectibles, triggers

# --- Scene paths ---
const MENU_SCENE := "res://ui/main_menu.tscn"
const MAP_SCENE := "res://ui/world_map.tscn"
const CREDITS_SCENE := "res://ui/credits.tscn"
const INTRO_CINEMATIC := "res://cinematics/cinematic_1.tscn"

# --- Progression ---
# Flow: New Game -> INTRO_CINEMATIC -> map -> level 1 -> its "cinematic_after" -> map -> level 2 -> ...
# The cinematic_after of the LAST level is the ending cinematic, followed by the credits.
# "map_pos" is the position of the level button on the 2D map (in pixels).
const LEVELS := [
	{
		"id": "level_1",
		"name": "Level 1",
		"scene": "res://levels/level_1.tscn",
		"map_pos": Vector2(220, 480),
		"cinematic_after": "res://cinematics/cinematic_2.tscn",
	},
	{
		"id": "level_2",
		"name": "Level 2",
		"scene": "res://levels/level_2.tscn",
		"map_pos": Vector2(560, 300),
		"cinematic_after": "res://cinematics/cinematic_3.tscn",
	},
]

# --- Collectibles (journal entries). "text" supports BBCode. "icon" is an optional texture path. ---
const COLLECTIBLES := [
	{ "id": "note_1", "title": "A torn letter", "text": "Write the entry text here.\n\nSupports [b]BBCode[/b].", "icon": "" },
	{ "id": "note_2", "title": "The old key", "text": "Second entry text.", "icon": "" },
	{ "id": "note_3", "title": "Faded photograph", "text": "Third entry text.", "icon": "" },
]

# Lines starting with "# " are headers.
const CREDITS := [
	"# MY GAME",
	"",
	"# Design & Story",
	"Your name",
	"",
	"# Programming",
	"Your name",
	"",
	"# Music",
	"Composer name",
	"",
	"Thanks for playing!",
]
