## The visual layer of a character
class_name Character
extends Node2D

@onready var health = $health
@onready var mana = $mana
# the logical state of the character
var character: CharacterInstance

func _process(_delta: float) -> void:
	health.text = str(character.health)
	
func setup(character_instance : CharacterInstance) -> void:
	if not character_instance:
		return
		
	character = character_instance
	
