extends Node2D
@onready var hand_reference: Node2D = $hand
@onready var discard_reference: Node2D = $discard
@onready var discard_top_card_reference: Node2D = $discard.get_node("top_card")
@onready var deck_reference: Node2D = $deck
@onready var end_turn_reference: Button = $end_turn

#@export var card_scene : PackedScene
@export var starting_deck : Array[CardData] = []

var deck : Array[CardData] = []
var hand : Array[Card] = []
var discard : Array[CardData] = []

const HAND_SIZE := 5
const CARD_DEFAULT_SCALE := Vector2(.33, .33)
	
# end turn
func _on_button_pressed() -> void:
	# disable the button
	end_turn_reference.disabled = true
	
	# resolve any actions
	
	# discard hand
	await discard_hand()
		
	# enemy turn
	
	# remove a turn from any x turn effects
	
	# draw a new hand
	for i in range(HAND_SIZE):
		await draw_card()
	
	# reset state variables
	
	# re-enable end turn button
	end_turn_reference.disabled = false

func _ready() -> void:
	# hacky way to prevent issues with the fiest card dealt
	await get_tree().create_timer(.15).timeout
	
	# TODO: build and assign starting deck instead of placeholder
	var Strike : CardData = load("res://cards/Strike.tres")
	var Defend : CardData = load("res://cards/Defend.tres")
	for i in range(13):
		if i % 2 == 0:
			starting_deck.append(Strike)
		else:
			starting_deck.append(Defend)
	
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
		
	var card_data : CardData = deck.pop_back()
	var start_pos : Vector2 = deck_reference.global_position
	var card_scene = instantiate_card(card_data)
	card_scene.index_in_hand = hand.size()
	hand_reference.add_child(card_scene)
	card_scene.global_position = start_pos
	card_scene.scale = CARD_DEFAULT_SCALE
	hand.append(card_scene)
	deal_to_hand(card_scene) # don't have to await this as stagger will be set per card anyways
	if deck.size() == 0:
		deck_reference.get_node("card_back").visible = false
		
func instantiate_card(card_data : CardData) -> Card:
	var card_scene: Card = load("res://prefabs/card.tscn").instantiate()
	card_scene.data = card_data
	return card_scene
		
func discard_card(card : Card) -> void:
	discard.append(card.data)
	var final_pos : Vector2 = discard_reference.global_position
	var tween : Tween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(card, "global_position", final_pos, .1)
	tween.parallel().tween_property(card, "rotation", 0, .1)
	await tween.finished
	hand.remove_at(card.index_in_hand)
	discard_top_card_reference.visible = true
	discard_top_card_reference.setup(card.data)
	card.queue_free()
		
func discard_hand() -> void:
	while not hand.is_empty():
		var card : Card = hand.pop_back()
		await discard_card(card)
	hand.clear()
	
func shuffle_discard_into_deck() -> void:
	for card in discard:
		await move_to_deck(card)
	deck.shuffle()
	deck_reference.get_node("card_back").visible = true
	discard_top_card_reference.visible = false
	discard.clear()

## Moves a card from the hand or discard to the top of the deck.[br]
## Pass a Card if in hand, or CardData if in discard.[br]
## NOTE: if we add additional piles (i.e. exhaust), this may need to be extended
func move_to_deck(card : Variant) -> void:
	assert(card is Card or card is CardData, "tried to move a non Card/CardData to deck")
	# TODO: this is untested. create a card that moves something from hand to top of deck
	if card is Card: # hand, already instantiated
		deck.insert(0, card.data)
		var final_pos : Vector2 = deck_reference.global_position
		var tween : Tween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.parallel().tween_property(card, "global_position", final_pos, .2)
		tween.parallel().tween_property(card, "rotation", 0, .2)
		tween.parallel().tween_callback(card.get_node("animation").play.bind("reverse_flip_card"))
		await tween.finished
		hand.remove_at(card.index_in_hand)
		card.queue_free()
	else: # discard, need to instantiate and then free
		var card_ref = instantiate_card(card)
		discard_reference.add_child(card_ref)
		card_ref.global_position = discard_reference.global_position
		deck.insert(0, card)
		var final_pos : Vector2 = deck_reference.global_position
		var tween : Tween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.parallel().tween_property(card_ref, "global_position", final_pos, .2)
		tween.parallel().tween_callback(card_ref.get_node("animation").play.bind("reverse_flip_card"))
		await tween.finished
		card_ref.queue_free()
		# if deck is empty, display the card back
		deck_reference.get_node("card_back").visible = true
	
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
			final_pos = hand_reference.to_global(Vector2(hand_ratio * offset, 0))
			final_rot = lerp_angle(-0.2, 0.2, float(i.index_in_hand)/float(hand.size() - 1))
		else:
			final_rot = 0
			final_pos = hand_reference.to_global(Vector2(max_offset / 2.0, 0))
		
		i.in_hand_pos = final_pos
		i.in_hand_rot = final_rot
		
		# calculate the delay
		var card_delay : float = i.index_in_hand * stagger_delay
		
		# apply delay to the tweens
		var tween : Tween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		# play the flip card animation only if this is a new card
		if i == new_card:
			tween.parallel().tween_callback(i.get_node("animation").play.bind("flip_card")).set_delay(card_delay)
		tween.parallel().tween_property(i, "global_position", final_pos, 0.25).set_delay(card_delay)
		tween.parallel().tween_property(i, "rotation", final_rot, 0.35).set_delay(card_delay)
		final_tween = tween
		
	await final_tween.finished

			
