## The base class logical instantiation of a character
class_name CharacterInstance
extends RefCounted

static var next_id: int = 0

var id: int
var data: CharacterData

# list of attributes all characters have
## The current health of the character. If current health falls to 0 or below, emit a death signal
@export var current_health : int:
	set(value):
		var was_alive := current_health > 0
		current_health = maxi(value, 0)

		if was_alive and current_health == 0:
			died.emit()
## the maximum health a character can have
@export var max_health : int	

# list of conditions all characters can have
@export var vulnerable: int
@export var strength: int
@export var block : int

signal died

## Creates a unique instance of a card using its shared CardData resource.
func _init(character: CharacterData) -> void:
	id = next_id
	next_id += 1
	data = character
	current_health = data.health
	max_health = data.health
