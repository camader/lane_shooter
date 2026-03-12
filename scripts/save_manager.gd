extends Node

const SAVE_PATH: String = "user://highscore.json"

var high_score: int = 0
var high_minions: int = 0
var high_bosses: int = 0
var last_score: int = 0
var last_minions: int = 0
var last_bosses: int = 0


func _ready() -> void:
	load_data()


func save_run(minions: int, bosses: int, total: int) -> void:
	last_score = total
	last_minions = minions
	last_bosses = bosses
	if total > high_score:
		high_score = total
		high_minions = minions
		high_bosses = bosses
	save_data()


func save_data() -> void:
	var data := {
		"high_score": high_score,
		"high_minions": high_minions,
		"high_bosses": high_bosses,
		"last_score": last_score,
		"last_minions": last_minions,
		"last_bosses": last_bosses,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))


func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK:
		var data: Dictionary = json.data
		high_score = int(data.get("high_score", 0))
		high_minions = int(data.get("high_minions", 0))
		high_bosses = int(data.get("high_bosses", 0))
		last_score = int(data.get("last_score", 0))
		last_minions = int(data.get("last_minions", 0))
		last_bosses = int(data.get("last_bosses", 0))
