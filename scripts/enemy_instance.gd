## The base class logical instantiation of an enemy
class_name EnemyInstance
extends CharacterInstance

static var current_ability = 0

## An enemy cyles through its list of abilities, executing one per turn and circling back to the 
## beginning of the ability order when needed. It will choose a target from the list provided,
## applying a set of rules on each choice depending on effect type
func execute_next_turn(targets : Array[CharacterInstance]) -> void:
	assert(data is EnemyData, "enemy data is not an enemy")
	assert(not data.abilities.is_empty(), "enemy has no turn data")
	
	var enemy_data : EnemyData = data
	
	var ability_actions : Array[Action] = enemy_data.abilities[current_ability].actions
	for action in ability_actions:
		# TODO: build targeting rules
		# for example: attack player character with least block
		#				heal most damaged enemy
		#				always inflict strength on self
		assert(targets and targets.size() > 0, "didn't pass any targets to enemy turn")
		action.execute(targets[0])
		
	# move forward in ability list, circling back if needed	
	current_ability += 1
	if current_ability == data.abilities.size():
		current_ability = 0
	
