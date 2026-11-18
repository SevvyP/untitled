## The base class logical instantiation of a character
class_name CharacterInstance
extends RefCounted

static var next_id: int = 0

var id: int
var data: CharacterData

# list of conditions all characters can have
@export var vulnerable: int
@export var strength: int

## Creates a unique instance of a card using its shared CardData resource.
func _init(character: CharacterData) -> void:
	id = next_id
	next_id += 1
	data = character
