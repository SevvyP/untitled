## All character actions are defined by an effect and a modifier. For example:[br]
## - ATTACK: 6 = attack target for 6 damage[br]
class_name Action
extends Resource

signal action_requests_change_to_game_state(action : Action)

## The list of possible effects which are mapped to specific execution behaviours
enum Effect { 
	ATTACK, 
	DEFEND, 
	DRAW, 
	GAIN_MANA, 
	GAIN_GOLD, 
	INFLICT_VULNERABLE, 
	INFLICT_STRENGTH 
	}
	
## The effect target type, which determines what targets can be chosen
enum EffectTargetType { SELF, CHOSEN_ALLY, CHOSEN_ENEMY, NONE }

## Returns the effect type for a given effect
func get_effect_type(effect: Effect) -> EffectTargetType:
	match effect:
		Effect.ATTACK:
			return EffectTargetType.CHOSEN_ENEMY

		Effect.DEFEND:
			return EffectTargetType.CHOSEN_ALLY

		Effect.DRAW, Effect.GAIN_MANA, Effect.GAIN_GOLD:
			return EffectTargetType.NONE

		Effect.INFLICT_VULNERABLE:
			return EffectTargetType.CHOSEN_ENEMY

		Effect.INFLICT_STRENGTH:
			return EffectTargetType.CHOSEN_ALLY
		
	# need to return something
	return EffectTargetType.NONE
	

@export var effect : Effect = Effect.ATTACK
@export var modifier: int = 1

## Execute an action on a target. Some actions like DRAW can be executed without a target
## TODO: split each action into a separate script extending Action
func execute(target : CharacterInstance = null) -> void:
	match effect:
		Effect.ATTACK:
			assert(target, "no target for an attack action")
			var damage = modifier + target.vulnerable
			if damage > target.block:
				target.current_health -= damage - target.block
				target.block = 0
			else:
				target.block -= damage
				
			if target.current_health < 0:
				target.current_health = 0

		Effect.DEFEND:
			target.block += modifier

		Effect.DRAW, Effect.GAIN_MANA, Effect.GAIN_GOLD:
			action_requests_change_to_game_state.emit(self)

		Effect.INFLICT_VULNERABLE:
			assert(target, "no target for an inflict vulnerable action")
			target.vulnerable = maxi(0, target.vulnerable + modifier)

		Effect.INFLICT_STRENGTH:
			assert(target, "no target for an inflict strength action")
			target.strength = maxi(0, target.strength + modifier)
