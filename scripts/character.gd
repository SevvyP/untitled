## The visual layer of a character
class_name Character
extends Node2D

@onready var health : Label = $health
@onready var vulnerable : Label = $vulnerable
@onready var block : Label = $block

# the logical state of the character
var character: CharacterInstance

func _process(_delta: float) -> void:
	health.text = str(character.health)
	vulnerable.text = str(character.vulnerable)
	block.text = str(character.block)
	
func setup(character_instance : CharacterInstance) -> void:
	if not character_instance:
		return
		
	character = character_instance
	
