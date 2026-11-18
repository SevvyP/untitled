class_name GameView
extends Node2D

@onready var hand_reference: Node2D = $hand
@onready var discard_reference: Node2D = $discard
@onready var discard_top_card_reference: Card = $discard/top_card
@onready var deck_reference: Node2D = $deck

const HAND_SIZE := 5
const CARD_DEFAULT_SCALE := Vector2(0.33, 0.33)
const ANIMATION_Z_INDEX := 100

var card_views: Dictionary[int, Card] = {}

## Initializes the pile visuals and disables interaction with the discard top card.
func _ready() -> void:
	discard_top_card_reference.visible = false
	discard_top_card_reference.get_node("Area2D/CollisionShape2D").disabled = true


## Instantiates a visual card and associates it with its logical CardInstance.[br]
## The caller is responsible for adding the card to the scene tree.
func instantiate_card(card_instance: CardInstance) -> Card:
	var card_scene: Card = load("res://prefabs/card.tscn").instantiate()
	card_scene.setup_instance(card_instance)
	return card_scene


## Creates a visual hand card at the deck's global position.
func create_hand_card(card_instance: CardInstance) -> Card:
	var card_scene: Card = instantiate_card(card_instance)
	hand_reference.add_child(card_scene)
	card_scene.global_position = deck_reference.global_position
	card_scene.scale = CARD_DEFAULT_SCALE
	card_scene.is_animating = true
	card_views[card_instance.id] = card_scene
	return card_scene

func animate_hand_layout(
	hand_cards: Array[CardInstance],
	new_card: CardInstance = null
) -> void:
	var layout_cards: Array[CardInstance] = hand_cards.duplicate()

	if layout_cards.is_empty():
		return

	var max_offset: float = 450.0
	var offset: float = (
		max_offset
		* float(layout_cards.size() - 1)
		/ float(HAND_SIZE - 1)
	)

	var animated_views: Array[Card] = []

	var tween: Tween = create_tween().set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

	for index in range(layout_cards.size()):
		var card_instance: CardInstance = layout_cards[index]

		assert(
			card_views.has(card_instance.id),
			"Hand contains card %d, but its visual is missing"
			% card_instance.id
		)

		var card_view: Card = card_views[card_instance.id]
		var final_pos: Vector2
		var final_rot: float

		if layout_cards.size() > 1:
			var hand_ratio: float = (
				float(index) / float(layout_cards.size() - 1)
			)
			final_pos = hand_reference.to_global(
				Vector2(hand_ratio * offset, 0)
			)
			final_rot = lerp_angle(-0.2, 0.2, hand_ratio)
		else:
			final_pos = hand_reference.to_global(
				Vector2(max_offset / 2.0, 0)
			)
			final_rot = 0.0

		card_view.in_hand_pos = final_pos
		card_view.in_hand_rot = final_rot
		card_view.is_animating = true
		animated_views.append(card_view)

		if card_instance == new_card:
			tween.tween_callback(
				card_view.get_node("animation").play.bind("flip_card")
			)

		tween.tween_property(
			card_view, "global_position", final_pos, 0.15
		)
		tween.tween_property(
			card_view, "rotation", final_rot, 0.15
		)

	await tween.finished

	for card_view in animated_views:
		if is_instance_valid(card_view):
			card_view.is_animating = false


## Creates and animates a new card entering the hand.
func animate_draw(card_instance: CardInstance, hand_cards: Array[CardInstance]) -> void:
	create_hand_card(card_instance)
	await animate_hand_layout(hand_cards, card_instance)


## Animates a card from the hand into the discard pile.[br]
## Removes its visual node after the animation completes.
func animate_discard(card_instance: CardInstance) -> void:
	assert(card_views.has(card_instance.id), "discard animation called on missing card view")

	var card_view: Card = card_views[card_instance.id]
	var final_pos: Vector2 = discard_reference.global_position

	card_view.is_animating = true
	card_view.is_dragging = false

	var tween: Tween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(card_view, "global_position", final_pos, 0.1)
	tween.parallel().tween_property(card_view, "rotation", 0, 0.1)
	# if card is not default size
	tween.parallel().tween_property(card_view, "scale", CARD_DEFAULT_SCALE, 0.1)

	await tween.finished

	discard_top_card_reference.setup(card_instance.data)
	discard_top_card_reference.visible = true

	card_views.erase(card_instance.id)
	card_view.queue_free()


## Animates the entire hand into the discard pile in at most 0.5 seconds.
func animate_discard_hand(cards: Array[CardInstance]) -> void:
	if cards.is_empty():
		return

	const MOVE_DURATION := 0.2
	const TOTAL_DURATION := 0.5

	var stagger: float = 0.0
	if cards.size() > 1:
		stagger = (TOTAL_DURATION - MOVE_DURATION) / float(cards.size() - 1)

	var tween: Tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	for index in range(cards.size()):
		var card_instance: CardInstance = cards[index]
		var card_view: Card = card_views[card_instance.id]
		var delay: float = index * stagger

		card_view.is_animating = true
		card_view.is_dragging = false

		tween.tween_property(
			card_view,
			"global_position",
			discard_reference.global_position,
			MOVE_DURATION
		).set_delay(delay)

		tween.tween_property(
			card_view, "rotation", 0.0, MOVE_DURATION
		).set_delay(delay)

		tween.tween_callback(
			_finish_hand_discard.bind(card_instance, card_view)
		).set_delay(delay + MOVE_DURATION)

	await tween.finished


## Updates the discard artwork and removes the arriving hand card.
func _finish_hand_discard(
	card_instance: CardInstance,
	card_view: Card
) -> void:
	discard_top_card_reference.setup(card_instance.data)
	discard_top_card_reference.visible = true

	card_views.erase(card_instance.id)
	card_view.queue_free()


## Animates every discarded card returning to the deck.[br]
func animate_shuffle(cards: Array[CardInstance]) -> void:
	if cards.is_empty():
		return

	# the animation length for each indivual card
	const MOVE_DURATION := 0.2
	# the length of the total shuffle animation
	const TOTAL_DURATION := 0.5
	# cards are staggered so that the total animation will be the set length
	var stagger: float = 0.0
	if cards.size() > 1:
		stagger = (TOTAL_DURATION - MOVE_DURATION) / float(cards.size() - 1)

	var tween: Tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	var deck_back: CanvasItem = deck_reference.get_node("card_back")

	var temporary_cards: Array[Card] = []
	for index in range(cards.size()):
		var card_view: Card = instantiate_card(cards[index])
		temporary_cards.append(card_view)
		discard_reference.add_child(card_view)
		card_view.global_position = discard_reference.global_position
		card_view.is_animating = true
		
		# render on top of everything else on the board
		card_view.z_as_relative = false
		card_view.z_index = ANIMATION_Z_INDEX

		# Show each temporary card when it departs.
		card_view.visible = false
		var delay: float = index * stagger

		var animation: AnimationPlayer = card_view.get_node("animation")
		var flip_speed: float = (
			animation.get_animation("reverse_flip_card").length / MOVE_DURATION
		)

		tween.tween_callback(card_view.show).set_delay(delay)
		tween.tween_callback(
			animation.play.bind("reverse_flip_card", 0.0, flip_speed)
		).set_delay(delay)

		var start_pos: Vector2 = card_view.global_position
		var end_pos: Vector2 = deck_reference.global_position

		# How far above the straight path the card rises at its midpoint.
		var arc_height: float = 180
		var control_pos: Vector2 = (
			(start_pos + end_pos) * 0.5
			+ Vector2.UP * arc_height * 2.0
		)

		tween.tween_method(
			func(progress: float) -> void:
				var first: Vector2 = start_pos.lerp(control_pos, progress)
				var second: Vector2 = control_pos.lerp(end_pos, progress)
				card_view.global_position = first.lerp(second, progress),
			0.0,
			1.0,
			MOVE_DURATION
		).set_delay(delay)

		tween.tween_callback(deck_back.show).set_delay(delay + MOVE_DURATION)

	# Keep the discard visible until its last card departs.
	tween.tween_callback(discard_top_card_reference.hide).set_delay(
		(cards.size() - 1) * stagger
	)

	await tween.finished
	for card_view in temporary_cards:
		card_view.queue_free()


## Animates a temporary card from the discard pile to the deck.[br]
## Temporary shuffle cards are not registered in card_views.
func animate_card_from_discard_to_deck(card_instance: CardInstance) -> void:
	var card_view: Card = instantiate_card(card_instance)

	discard_reference.add_child(card_view)
	card_view.global_position = discard_reference.global_position
	card_view.is_animating = true

	var final_pos: Vector2 = deck_reference.global_position

	var tween: Tween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.parallel().tween_property(card_view, "global_position", final_pos, 0.1)
	tween.parallel().tween_callback(card_view.get_node("animation").play.bind("reverse_flip_card", -1, 2))

	await tween.finished

	card_view.queue_free()


## Animates an existing hand card returning to the deck.[br]
## Removes its visual representation after the animation completes.
func animate_hand_card_to_deck(card_instance: CardInstance) -> void:
	assert(card_views.has(card_instance.id), "deck animation called on missing card view")

	var card_view: Card = card_views[card_instance.id]
	var final_pos: Vector2 = deck_reference.global_position
	var animation: AnimationPlayer = card_view.get_node("animation")
	var flip_speed: float = animation.get_animation("flip_card").length

	card_view.is_animating = true
	card_view.is_dragging = false

	var tween: Tween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	tween.parallel().tween_property(card_view, "global_position", final_pos, flip_speed)
	tween.parallel().tween_property(card_view, "rotation", 0, flip_speed)
	tween.parallel().tween_callback(animation.play.bind("reverse_flip_card"))

	await tween.finished

	card_views.erase(card_instance.id)
	card_view.queue_free()


## Updates deck visibility based on the logical number of cards.
func update_deck_visual(deck_count: int) -> void:
	deck_reference.get_node("card_back").visible = deck_count > 0


## Updates discard visibility and its top card artwork.[br]
## The last element in the discard array is the top card.
func update_discard_visual(discard_cards: Array[CardInstance]) -> void:
	if discard_cards.is_empty():
		discard_top_card_reference.visible = false
		return

	var top_card: CardInstance = discard_cards.back()

	discard_top_card_reference.setup(top_card.data)
	discard_top_card_reference.visible = true
	
	
func animate_card_play(card : Card) -> void:
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(card, "scale", Vector2(0.5, 0.5), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
