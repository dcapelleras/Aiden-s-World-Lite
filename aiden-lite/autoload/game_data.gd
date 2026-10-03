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
		"id": "hub",
		"name": "Hub",
		"scene": "res://levels/level_1.tscn",
		"map_pos": Vector2(220, 480),
		"cinematic_after": "res://cinematics/cinematic_2.tscn",
	},
	{
		"id": "mansion",
		"name": "Mansion",
		"scene": "res://levels/level_2.tscn",
		"map_pos": Vector2(560, 300),
		"cinematic_after": "res://cinematics/cinematic_3.tscn",
	},
]

# --- Collectibles (journal entries). "text" supports BBCode. "icon" is an optional texture path. ---
const COLLECTIBLES := [
	{ "id": "note_1", "title": "Coleccionable1", "text": "La primera història de l'Aiden.", "icon": "res://Assets/UI/Collectible Medals/Medal_1.png" },
	{ "id": "note_2", "title": "Coleccionable2", "text": "La segona història de l'Aiden.", "icon": "res://Assets/UI/Collectible Medals/Medal_2.png" },
	{ "id": "note_3", "title": "Coleccionable3", "text": "La tercera història de l'Aiden.", "icon": "res://Assets/UI/Collectible Medals/Medal_3.png" },
	{ "id": "note_4", "title": "Coleccionable4", "text": "La quarta història de l'Aiden.", "icon": "res://Assets/UI/Collectible Medals/Medal_4.png" },
	{ "id": "note_5", "title": "Coleccionable5", "text": "La cinquena història de l'Aiden.", "icon": "res://Assets/UI/Collectible Medals/Medal_5.png" },
	{ "id": "note_6", "title": "Coleccionable6", "text": "La sisena història de l'Aiden.", "icon": "res://Assets/UI/Collectible Medals/Medal_6.png" },
	{ "id": "note_7", "title": "Coleccionable7", "text": "La setena història de l'Aiden.", "icon": "res://Assets/UI/Collectible Medals/Medal_7.png" },
	{ "id": "note_8", "title": "Coleccionable8", "text": "La vuitena història de l'Aiden.", "icon": "res://Assets/UI/Collectible Medals/Medal_8.png" },
	{ "id": "note_9", "title": "Coleccionable9", "text": "La novena història de l'Aiden.", "icon": "res://Assets/UI/Collectible Medals/Medal_9.png" },
	{ "id": "note_10", "title": "Coleccionable10", "text": "La desena història de l'Aiden.", "icon": "res://Assets/UI/Collectible Medals/Medal_10.png" },
]

# Lines starting with "# " are headers.
const CREDITS := [
	"# AIDEN'S WORLD",
	"",
	"# Direcció del projecte",
	"Noms varis",
	"",
	"# Leads",
	"Noms varis",
	"",
	"# Disseny",
	"Noms varis",
	"",
	"# Narrativa",
	"Noms varis",
	"",
	"# Art",
	"Noms varis",
	"",
	"# Programació",
	"Noms varis",
	"",
	"# Música",
	"Noms varis",
	"",
	"Gràcies per jugar!",
]
