# The data layer of a card
class_name CardData
extends Resource

@export var card_name: String = "Strike"
@export var cost: int = 1
@export_multiline var description: String = "Deal 6 damage."
@export var art: Texture2D

## The list of effects that a card can perform
enum Effect { ATTACK, DEFEND, DRAW, INFLICT_VULNERABLE }

## Card behaviour is a list of action + modifier.
## Each action has a defined set of rules, i.e.:[br]
## 	ATTACK = apply modifier as damage on the target[br]
##  INFLICT_<STATUS> = apply modifier as stacks of status on the target[br]
## In this way, every possible card ability behaviour can be expressed as an ordered list of 
## actions and modifiers. Set the base modifiers for the actions, addtional modifiers will be applied
## by the game manager
@export var card_effects : Dictionary[Effect, int] = {
	Effect.ATTACK: 1,
}
