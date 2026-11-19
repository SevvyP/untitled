## The instantiated logical instance of a card
class_name CardInstance
extends RefCounted

static var next_id: int = 0

var id: int
var data: CardData

## True if the card has been upgraded
@export var upgraded: bool = false

## Creates a unique instance of a card using its shared CardData resource.
func _init(card_data: CardData) -> void:
	id = next_id
	next_id += 1
	data = card_data
