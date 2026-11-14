class_name GameView
extends Node2D

@onready var hand_reference: Node2D = $hand
@onready var discard_reference: Node2D = $discard
@onready var discard_top_card_reference: Card = $discard/top_card
@onready var deck_reference: Node2D = $deck

const HAND_SIZE := 5
const CARD_DEFAULT_SCALE := Vector2(0.33, 0.33)

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


## Animates all cards into their correct hand positions.[br]
## Existing cards reposition simultaneously with the newly drawn card.
func animate_hand_layout(hand_cards: Array[CardInstance], new_card: CardInstance = null) -> void:
	if hand_cards.is_empty():
		return

	var max_offset: float = 450.0
	var offset: float = max_offset * (float(hand_cards.size() - 1) / float(HAND_SIZE - 1))
	var tweens: Array[Tween] = []

	for index in range(hand_cards.size()):
		var card_instance: CardInstance = hand_cards[index]
		var card_view: Card = card_views[card_instance.id]

		var final_pos: Vector2
		var final_rot: float

		if hand_cards.size() > 1:
			var hand_ratio: float = float(index) / float(hand_cards.size() - 1)

			final_pos = hand_reference.to_global(Vector2(hand_ratio * offset, 0))
			final_rot = lerp_angle(-0.2, 0.2, hand_ratio)
		else:
			final_pos = hand_reference.to_global(Vector2(max_offset / 2.0, 0))
			final_rot = 0.0

		card_view.in_hand_pos = final_pos
		card_view.in_hand_rot = final_rot
		card_view.is_animating = true

		# apply delay to the tweens
		var tween: Tween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

		# play the flip card animation only if this is a new card
		if card_instance == new_card:
			tween.parallel().tween_callback(card_view.get_node("animation").play.bind("flip_card"))

		tween.parallel().tween_property(card_view, "global_position", final_pos, 0.15)
		tween.parallel().tween_property(card_view, "rotation", final_rot, 0.15)

		tweens.append(tween)

	for tween in tweens:
		await tween.finished

	for card_instance in hand_cards:
		var card_view: Card = card_views[card_instance.id]
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

	await tween.finished

	discard_top_card_reference.setup(card_instance.data)
	discard_top_card_reference.visible = true

	card_views.erase(card_instance.id)
	card_view.queue_free()


## Animates every discarded card returning to the deck.[br]
## The logical discard array is managed separately by GameState.
func animate_shuffle(cards: Array[CardInstance]) -> void:
	for card_instance in cards:
		await animate_card_from_discard_to_deck(card_instance)
		deck_reference.get_node("card_back").visible = true

	discard_top_card_reference.visible = false


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

	card_view.is_animating = true
	card_view.is_dragging = false

	var tween: Tween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	tween.parallel().tween_property(card_view, "global_position", final_pos, 0.2)
	tween.parallel().tween_property(card_view, "rotation", 0, 0.2)
	tween.parallel().tween_callback(card_view.get_node("animation").play.bind("reverse_flip_card"))

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
