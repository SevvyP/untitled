extends Node2D
@onready var hand_reference: Node2D = $hand
@onready var discard_reference: Node2D = $discard.get_node("cards")
@onready var deck_reference: Node2D = $deck

#@export var card_scene : PackedScene
@export var starting_deck : Array[CardData] = []

var deck : Array[CardData] = []
var hand : Array[Card] = []
var discard : Array[CardData] = []

const HAND_SIZE := 5
	
# end turn
func _on_button_pressed() -> void:
	# resolve any actions
	
	# discard hand
	await discard_hand()
		
	# enemy turn
	
	# remove a turn from any x turn effects
	
	# draw a new hand
	for i in range(HAND_SIZE):
		await draw_card()
	
	# reset state variables

func _ready() -> void:
	# hacky way to prevent issues with the fiest card dealt
	await get_tree().create_timer(.15).timeout
	
	# TODO: build and assign starting deck instead of placeholder
	var Strike : CardData = load("res://cards/Strike.tres")
	for i in range(13):
		starting_deck.append(Strike)
	
	#randomize() seed the global RNG for shuffle()
	build_deck()

	for i in range(HAND_SIZE):
		await draw_card()
	
func build_deck() -> void:
	deck.clear()
	for card_data in starting_deck:
		deck.append(card_data)
	deck.shuffle()

func draw_card() -> void:
	if deck.size() == 0:
		# small pause before playing shuffle animation
		await get_tree().create_timer(.5).timeout
		await shuffle_discard_into_deck()
		# small pause before next draw animation
		await get_tree().create_timer(.15).timeout
		
	var card_scene: Card = load("res://prefabs/card.tscn").instantiate()
	var card_data : CardData = deck.pop_back()
	card_scene.scale = Vector2(.33, .33)
	var start_pos : Vector2 = Vector2(deck_reference.position.x - hand_reference.position.x, 0) # deck offset from the hand position
	card_scene.position = start_pos
	card_scene.data = card_data
	card_scene.index_in_hand = hand.size()
	hand_reference.add_child(card_scene)
	hand.append(card_scene)
	deal_to_hand(card_scene) # don't have to await this as stagger will be set per card anyways
	if deck.size() == 0:
		deck_reference.get_node("card_back").visible = false
		
#func discard_card(card : Card) -> void:
	#discard.append(card.data)
	#var final_pos : Vector2 = Vector2($discard.position.x - hand_reference.position.x, 0) # discard offset from the hand position
	#var tween : Tween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	#tween.tween_property(card, "position", final_pos, .25)
	#await tween.finished
	#card.animations_disabled = true
	#hand.remove_at(card.index_in_hand)
		
func discard_hand() -> void:
	var stagger_delay: float = 0.15
	var cards_to_discard: Array[Card] = hand.duplicate()

	var max_delay: float = 0.0
	var last_tween : Tween
	for card in cards_to_discard:
		var card_delay: float = card.index_in_hand * stagger_delay
		max_delay = max(max_delay, card_delay)

		var final_pos: Vector2 = discard_reference.position

		var tween := get_tree().create_tween()
		tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.parallel().tween_property(card, "position", final_pos, 0.25).set_delay(card_delay)
		tween.parallel().tween_property(card, "rotation", 0, 0.35).set_delay(card_delay)
		last_tween = tween
		discard.append(card.data)
		card.reparent(discard_reference)

	await last_tween.finished
	for card in discard_reference.get_children():
		card.animations_disabled = true
	hand.clear()
	
func shuffle_discard_into_deck() -> void:
	# This dictates how long to wait between each card's movement (in seconds)
	var stagger_delay: float = 0.1 
	
	# first, animate the shuffle
	var final_tween : Tween
	var discard_cards = discard_reference.get_children()

	for index in range(discard_cards.size()):
		var card: Card = discard_cards[index]
		var card_delay: float = index * stagger_delay
		var final_pos: Vector2 = discard_reference.to_local(deck_reference.global_position)
		
		var tween: Tween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.parallel().tween_callback(card.get_node("animation").play.bind("reverse_flip_card")).set_delay(card_delay)
		tween.parallel().tween_property(card, "position", final_pos, 0.2).set_delay(card_delay)
		final_tween = tween
		
	# wait for animation to finish
	await final_tween.finished
		
	# update deck and discard references
	for i in discard:
		deck.append(i)
	deck.shuffle()
	deck_reference.get_node("card_back").visible = true
	
	for child in discard_reference.get_children():
		child.queue_free()
	discard.clear()
	
func deal_to_hand(new_card : Card = null) -> void:
	var max_offset: float = 450.0
	var offset: float = max_offset * (float(hand.size() - 1) / (HAND_SIZE - 1))
	var final_pos: Vector2
	var final_rot: float
	
	# This dictates how long to wait between each card's movement (in seconds)
	var stagger_delay: float = 0.15 
	
	var final_tween : Tween
	for i in hand:
		var hand_ratio: float = 0.5
		if hand.size() > 1:
			hand_ratio = float(i.index_in_hand) / (float(hand.size()) - 1.0)
			final_pos = Vector2(hand_ratio * offset, 0)
			final_rot = lerp_angle(-0.2, 0.2, float(i.index_in_hand)/float(hand.size() - 1))
		else:
			final_rot = 0
			final_pos = Vector2(max_offset / 2.0, 0)
		
		i.in_hand_pos = final_pos
		i.in_hand_rot = final_rot
		
		# calculate the delay
		var card_delay : float = i.index_in_hand * stagger_delay
		
		# apply delay to the tweens
		var tween : Tween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		# play the flip card animation only if this is a new card
		if i == new_card:
			tween.parallel().tween_callback(i.get_node("animation").play.bind("flip_card")).set_delay(card_delay)
		tween.parallel().tween_property(i, "position", final_pos, 0.25).set_delay(card_delay)
		tween.parallel().tween_property(i, "rotation", final_rot, 0.35).set_delay(card_delay)
		final_tween = tween
		
	await final_tween.finished

			
