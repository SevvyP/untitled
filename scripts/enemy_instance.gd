## The base class logical instantiation of an enemy
class_name EnemyInstance
extends CharacterInstance

static var current_turn = 0

func execute_next_turn() -> void:
	assert(data is EnemyData, "enemy data is not an enemy")
	assert(not data.turns.is_empty(), "enemy has no turn data")
	
	var turn_actions : Array[Action] = data.turns[current_turn]
	for action in turn_actions:
		# TODO: choose target
		action.execute(null)
	
