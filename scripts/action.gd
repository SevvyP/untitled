## All character actions are defined by an effect and a modifier. For example:[br]
## - ATTACK: 6 = attack target for 6 damage[br]
class_name Action
extends Resource

signal action_requests_change_to_game_state

enum Effect { 
	ATTACK, 
	DEFEND, 
	DRAW, 
	GAIN_MANA, 
	GAIN_GOLD, 
	INFLICT_VULNERABLE, 
	INFLICT_STRENGTH 
	}

@export var effect : Effect = Effect.ATTACK
@export var modifier: int = 1

## Execute an action on a target. Some actions like DRAW can be executed without a target
## TODO: split each action into a separate script extending Action
func execute(target : CharacterInstance = null) -> void:
	if effect == Effect.ATTACK:
		assert(target, "no target for an attack action")
		target.health -= modifier + target.vulnerable
	if effect == Effect.DEFEND:
		print("Block " + str(modifier) + " damage")
	if effect == Effect.DRAW:
		action_requests_change_to_game_state.emit()
	if effect == Effect.GAIN_MANA:
		action_requests_change_to_game_state.emit(effect)
	if effect == Effect.GAIN_GOLD:
		action_requests_change_to_game_state.emit(effect)
	if effect == Effect.INFLICT_VULNERABLE:
		assert(target, "no target for an inflict vulnerable action")
		target.vulnerable += modifier
		if target.vulnerable < 0 : target.vulnerable = 0
	if effect == Effect.INFLICT_STRENGTH:
		assert(target, "no target for an inflict strength action")
		target.strength += modifier
		if target.strength < 0 : target.vulnerable = 0
