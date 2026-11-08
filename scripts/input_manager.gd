extends Node2D

const COLLISION_MASK_CARD : int = 1
		
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var top_card : Card = get_top_card_at_position(event.global_position)
		if !top_card: return
		if event.pressed:
			top_card.start_dragging()
		else:
			top_card.stop_dragging()

# this is a little fucked because the parent of card is a Node2D
# however, we need to use a Node2D as a pivot point
func get_top_card_at_position(global_click_pos: Vector2) -> Card:
	var space_state := get_world_2d().direct_space_state
	
	# Set up a physics point query at the mouse position
	var query := PhysicsPointQueryParameters2D.new()
	query.position = global_click_pos
	query.collision_mask = COLLISION_MASK_CARD
	query.collide_with_areas = true
	query.collide_with_bodies = false # Ignore player/walls, only look for card Areas
	
	# Intersect point returns an array of dictionaries representing all overlapping areas
	var results := space_state.intersect_point(query)
	
	if results.is_empty():
		return null
		
	var highest_card: Area2D = null
	var highest_index: int = -1
	
	# Evaluate every card under the mouse cursor
	for result in results:
		var area = result["collider"] as Area2D
		
		# Ensure it's a card (or check if it has the start_dragging method)
		if area and area.get_parent() and area.get_parent().has_method("start_dragging"):
			# get_index() returns its position in the Scene Tree
			var current_index := area.get_parent().get_index() 
			
			# The higher the index, the later it was added, meaning it draws on top
			if current_index > highest_index:
				highest_index = current_index
				highest_card = area
				
	return highest_card.get_parent()
