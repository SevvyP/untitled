extends Node2D

const COLLISION_MASK_CARD: int = 1

var dragged_card: Card = null


## Handles mouse presses and releases for dragging cards.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if dragged_card:
				return

			var top_card: Card = get_top_card_at_position(get_global_mouse_position())

			if not top_card or top_card.is_animating:
				return

			dragged_card = top_card
			dragged_card.start_dragging()
		else:
			if not dragged_card:
				return

			dragged_card.stop_dragging()
			dragged_card = null


## Returns the topmost interactive card at the given global position.[br]
## Uses physics queries because the card's parent is a Node2D pivot.
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

	var highest_card: Card = null
	var highest_index: int = -1

	# Evaluate every card under the mouse cursor
	for result in results:
		var area: Area2D = result["collider"] as Area2D

		if not area:
			continue

		var card: Card = area.get_parent() as Card

		if not card or card.is_animating:
			continue

		# get_index() returns its position in the Scene Tree
		var current_index: int = card.get_index()

		# The higher the index, the later it was added, meaning it draws on top
		if current_index > highest_index:
			highest_index = current_index
			highest_card = card

	return highest_card
