# The data layer of a card
class_name CardData
extends Resource

@export var card_name: String = "Strike"
@export var cost: int = 1
@export_multiline var description: String = "Deal 6 damage."
@export var art: Texture2D

@export var ability : Ability
