extends Node2D

@onready var game_view: GameView = $game_view
@onready var end_turn_reference: Button = $end_turn
@onready var input_manager = $input_manager
@onready var enemy_health_reference : Label = $enemy_health
@onready var enemy_vulnerable_reference: Label = $enemy_vulnerable

@export var enemy_health : int = 30
@export var enemy_vulnerable : int = 0
@export var starting_deck: Array[CardData] = []

var game_state: GameState

const HAND_SIZE := 5

## true when the game state is updating and player interactions should be paused
var is_game_state_updating: bool = false

# Update display numbers from game state
func _process(delta: float) -> void:
	enemy_health_reference.text = str(enemy_health)
	enemy_vulnerable_reference.text = str(enemy_vulnerable)

## Initializes the game state, builds the starting deck, and draws the first hand
func _ready() -> void:
	game_state = GameState.new()
	
	input_manager.card_play_requested.connect(_on_card_play_requested)

	# hacky way to prevent issues with the fiest card dealt
	await get_tree().create_timer(0.15).timeout

	# TODO: build and assign starting deck instead of placeholder
	var Strike: CardData = load("res://cards/srike.tres")
	var Defend: CardData = load("res://cards/defend.tres")
	var Draw: CardData = load("res://cards/draw.tres")
	var Vulnerable: CardData = load("res://cards/vulnerable.tres")
	for i in range(10):
		if i % 4 == 0:
			starting_deck.append(Vulnerable)
		if i % 3 == 0:
			starting_deck.append(Strike)
		elif i % 2 == 0:
			starting_deck.append(Draw)
		else:
			starting_deck.append(Defend)

	# TODO: randomize() seed the global RNG for shuffle()
	game_state.build_deck(starting_deck)

	# update the starting states for deck and discard
	game_view.update_deck_visual(game_state.deck.size())
	game_view.update_discard_visual(game_state.discard)

	is_game_state_updating = true
	end_turn_reference.disabled = true

	for i in range(HAND_SIZE):
		await draw_card()

	is_game_state_updating = false
	end_turn_reference.disabled = false


## Resolves the end of the player's turn, triggers enemy turns, resolves the start 
## of the player's next turn, then draws a new hand
func _on_button_pressed() -> void:
	if is_game_state_updating:
		return

	is_game_state_updating = true

	# disable the button
	end_turn_reference.disabled = true

	# resolve any actions

	# discard hand
	await discard_hand()

	# trigger enemy turns
	if enemy_vulnerable > 0:
		enemy_vulnerable -= 1

	# resolve start of next player turn

	# draw a new hand
	for i in range(HAND_SIZE):
		await draw_card()

	# start new turn
	is_game_state_updating = false
	end_turn_reference.disabled = false

## Signal recieved from input manager to attempt to play a card
func _on_card_play_requested(card: Card) -> void:
	var card_instance: CardInstance = card.card_instance
	if is_game_state_updating or card_instance == null or not game_state.hand.has(card_instance):
		await card.return_to_hand()
		return
		
	is_game_state_updating = true
	
	card.z_index = GameView.ANIMATION_Z_INDEX

	await game_view.animate_card_play(card)

	await discard_card(card.card_instance)
	
	await resolve_card_effects(card_instance)
	
	await game_view.animate_hand_layout(game_state.hand)
	
	is_game_state_updating = false


## Resolve the effects of a card
func resolve_card_effects(card_instance: CardInstance) -> void:
	for action in card_instance.data.card_effects:
		var base_modifier: int = card_instance.data.card_effects[action]
		var amount: int = base_modifier + get_effect_bonus(action)

		match action:
			CardData.Effect.ATTACK:
				enemy_health -= amount
				if enemy_health <= 0:
					enemy_health = 0
					print("game over!")

			CardData.Effect.DEFEND:
				# Replace with adding block to the player.
				print("Gain %d block" % amount)

			CardData.Effect.DRAW:
				for i in range(maxi(amount, 0)):
					await draw_card()

			CardData.Effect.INFLICT_VULNERABLE:
				enemy_vulnerable += amount


## TODO: get bonus mondifiers to apply
func get_effect_bonus(action: CardData.Effect) -> int:
	# Look up relevant player buffs, relics, etc. here.
	if action == CardData.Effect.ATTACK:
		return enemy_vulnerable
	return 0


## Draws one logical card and animates it entering the hand.[br]
## Shuffles the discard pile into the deck when necessary.
func draw_card() -> void:
	if game_state.deck.is_empty() and game_state.discard.is_empty():
		# nothing to draw
		# TODO: show some sort of visual queue that there's no more cards 
		return

	# shuffle the discard into the deck
	if game_state.deck.is_empty():
		await shuffle_discard_into_deck()
		# small pause before drawing the next card
		await get_tree().create_timer(0.15).timeout

	var card_instance: CardInstance = game_state.draw_card()
	assert(card_instance, "draw card did not result in a card being drawn")

	await game_view.animate_draw(card_instance, game_state.hand)
	game_view.update_deck_visual(game_state.deck.size())


## Moves a card from from the hand to the discard pile
func discard_card(card_instance: CardInstance) -> void:
	assert(game_state.hand.has(card_instance), "attempted to discard a card that isn't in hand")
	game_state.discard_card(card_instance)
	await game_view.animate_discard(card_instance)
	game_view.update_discard_visual(game_state.discard)


## Discards every card currently in the hand.[br]
func discard_hand() -> void:
	var cards: Array[CardInstance] = game_state.hand.duplicate()
	cards.reverse()

	for card_instance in cards:
		game_state.discard_card(card_instance)

	await game_view.animate_discard_hand(cards)
	game_view.update_discard_visual(game_state.discard)
	
	# add a small pause before the next action
	await get_tree().create_timer(0.15).timeout

## Shuffles discarded cards into the deck and animates the shuffle.
func shuffle_discard_into_deck() -> void:
	if game_state.discard.is_empty():
		return

	var cards_to_shuffle: Array[CardInstance] = game_state.discard.duplicate()
	game_state.shuffle_discard_into_deck()
	await game_view.animate_shuffle(cards_to_shuffle)
	game_view.update_deck_visual(game_state.deck.size())
	game_view.update_discard_visual(game_state.discard)


## Moves a card from the hand or discard pile to the top of the deck.[br]
## Animates the transition based on the card's original pile.[br]
## NOTE: if we add additional piles (i.e. exhaust), this may need to be extended.[br]
## TODO: test this
func move_to_deck(card_instance: CardInstance) -> void:
	var was_in_hand: bool = game_state.hand.has(card_instance)
	var was_in_discard: bool = game_state.discard.has(card_instance)
	assert(was_in_hand or was_in_discard, "trying to move a nonexistant card to the deck")

	game_state.move_to_deck(card_instance)

	if was_in_hand:
		await game_view.animate_hand_card_to_deck(card_instance)
		await game_view.animate_hand_layout(game_state.hand)
	else:
		await game_view.animate_card_from_discard_to_deck(card_instance)

	game_view.update_deck_visual(game_state.deck.size())
	game_view.update_discard_visual(game_state.discard)
