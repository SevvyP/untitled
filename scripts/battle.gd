class_name Battle
extends Node2D

signal card_reward_chosen(card : CardInstance)
signal combat_won_next()

@onready var game_view: GameView = $game_view
@onready var end_turn_reference: Button = $end_turn
@onready var input_manager = $input_manager
@onready var enemy_reference : Enemy = $enemy
@onready var character_reference : Character = $character
@onready var reward_screen = preload("res://prefabs/reward_screen.tscn")
@onready var round_lost_screen = preload("res://prefabs/round_lost_screen.tscn")

## Reference to the character being played this run. This is a global reference, so changes made
## during this combat will persist during the run. For example, taking damage should persist into
## the next battle
var character_instance : CharacterInstance

## Instantated logical state of the enemy being fought
var enemy_instance : EnemyInstance

## State of the current battle. Contains deck, hand, discard, plus modifiers like modifiers on number
## of cards to be drawn each turn
var game_state: GameState

const HAND_SIZE := 5

## true when the game state is updating and player interactions should be paused
var is_game_state_updating: bool = false

## true when the round is over and actions should stop resolving
var is_round_over : bool = false

##
func setup(deck : Array[CardInstance], character : CharacterInstance, enemy : EnemyData):
	game_state = GameState.new()
	assert(deck and character and enemy, "missing needed data to setup battle")
	character_instance = character
	enemy_instance = EnemyInstance.new(enemy)
	
	enemy_reference.setup(enemy_instance)
	character_reference.setup(character_instance)
	
	enemy_instance.died.connect(_on_enemy_died.bind(enemy_instance))
	character_instance.died.connect(_on_player_died.bind(character_instance))
	
	input_manager.card_play_requested.connect(_on_card_play_requested)

	# hacky way to prevent issues with the first card dealt
	await get_tree().create_timer(0.15).timeout

	# TODO: randomize() seed the global RNG for shuffle()
	game_state.build_deck(deck)

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
	# TODO: pass in any targets if more than just player
	await enemy_instance.execute_next_turn([character_instance])
	if is_round_over:
		return

	# resolve start of next player turn
	character_instance.vulnerable -= 1
	if character_instance.vulnerable < 0:
		character_instance.vulnerable = 0
	character_instance.block = 0

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
	# TODO: player pick a target
	for action in card_instance.data.ability.actions:
		match action.get_effect_type(action.effect):
			Action.EffectTargetType.CHOSEN_ENEMY:
				action.execute(enemy_instance)
			Action.EffectTargetType.CHOSEN_ALLY:
				action.execute(character_instance)
			Action.EffectTargetType.NONE:
				if not action.action_requests_change_to_game_state.is_connected(_apply_game_state_effect):
					action.action_requests_change_to_game_state.connect(_apply_game_state_effect)
				action.execute()

## helper function for actions which effect the game state (ex: draw, gain mana)
func _apply_game_state_effect(action : Action) -> void:
	match action.effect:
		Action.Effect.DRAW:
			for i in range(action.modifier):
				await draw_card()

		#Action.Effect.GAIN_MANA:
			#game_state.mana += amount

		#Action.Effect.GAIN_GOLD:
			#game_state.gold += amount

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
	

func _on_enemy_died(dead_enemy: EnemyInstance) -> void:
	is_round_over = true
	await enemy_reference.animate_death()
	combat_won()

func _on_player_died(dead_player: CharacterInstance) -> void:
	is_round_over = true
	await character_reference.animate_death()
	combat_lost()
	
func combat_won() -> void:
	var rewards = reward_screen.instantiate()
	rewards.reward_chosen.connect(_on_reward_chosen.bind())
	rewards.next_pressed.connect(_on_rewards_next_pressed.bind())
	game_view.queue_free()
	end_turn_reference.queue_free()
	self.add_child(rewards)
	
func combat_lost() -> void:
	var round_lost = round_lost_screen.instantiate()
	for child in get_children():
		child.queue_free()
	get_tree().current_scene.add_child(round_lost)

## roundabout way to bus rewards back to main
func _on_reward_chosen(card : CardInstance):
	card_reward_chosen.emit(card)
	
func _on_rewards_next_pressed():
	get_tree().paused = false
	combat_won_next.emit()
