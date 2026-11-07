extends Node2D
@onready var hand: Node2D = $hand

		
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var top_card = get_top_card_at_position(event.global_position)
		if !top_card: return
		if event.pressed:
			top_card.start_dragging()
		else:
			top_card.stop_dragging()

func _ready() -> void:
	draw_card(5, null)


func draw_card(amount: int, card_data):
	for i in range(amount):
		var card_scene: Node2D = load("res://prefabs/card.tscn").instantiate()
		card_scene.scale = Vector2(.33, .33)
		var start_pos : Vector2 = Vector2(-450, 0)
		card_scene.position = start_pos
		hand.add_child(card_scene)
	arrange_hand()

func move_card(card: Node2D, start_position: Vector2, target_position: Vector2, dur: float):
	var tween: Tween = create_tween()
	tween.tween_property(card, "position", target_position, dur).set_trans(Tween.TRANS_CUBIC).from(start_position)
	await tween.finished
	
func arrange_hand():
	var offset: int = 450
	var final_pos: Vector2
	var final_rot: float
	
	# This dictates how long to wait between each card's movement (in seconds)
	var stagger_delay: float = 0.15 
	
	for i in hand.get_children():
		var hand_ratio: float = 0.5
		if hand.get_child_count() > 1:
			hand_ratio = float(i.get_index()) / (float(hand.get_child_count()) - 1.0)
			final_pos = Vector2(hand_ratio * offset, 0)
			final_rot = lerp_angle(-0.2, 0.2, float(i.get_index())/float(hand.get_child_count() - 1))
		else:
			final_rot = 0
			final_pos = Vector2(200, 0)
		
		i.in_hand_pos = final_pos
		i.in_hand_rot = final_rot
		
		# calculate the delay
		var card_delay : float = i.get_index() * stagger_delay
		
		# apply delay to the tweens
		var tween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.parallel().tween_callback(i.get_node("animation").play.bind("flip_card")).set_delay(card_delay)
		tween.parallel().tween_property(i, "position", final_pos, 0.25).set_delay(card_delay)
		tween.parallel().tween_property(i, "rotation", final_rot, 0.35).set_delay(card_delay)
		

func get_top_card_at_position(global_click_pos: Vector2) -> Node2D:
	var space_state := get_world_2d().direct_space_state
	
	# Set up a physics point query at the mouse position
	var query := PhysicsPointQueryParameters2D.new()
	query.position = global_click_pos
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
			var current_index = area.get_parent().get_index() 
			
			# The higher the index, the later it was added, meaning it draws on top
			if current_index > highest_index:
				highest_index = current_index
				highest_card = area
				
	return highest_card.get_parent()
		
