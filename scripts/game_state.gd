## The logical layer of the game
class_name GameState
extends RefCounted

var deck: Array[CardInstance] = []
var hand: Array[CardInstance] = []
var discard: Array[CardInstance] = []

@export var player_health : int = 0
@export var player_mana : int = 0
@export var player_gold : int = 0

## Builds and shuffles the starting deck from CardData resources.
func build_deck(starting_cards: Array[CardData]) -> void:
	deck.clear()
	hand.clear()
	discard.clear()

	for card_data in starting_cards:
		deck.append(CardInstance.new(card_data))

	deck.shuffle()


## Draws the top card from the deck into the hand.[br]
## Returns null if the deck is empty.
func draw_card() -> CardInstance:
	if deck.is_empty():
		return null

	var card: CardInstance = deck.pop_back()
	hand.append(card)

	return card


## Moves a card from the hand into the discard pile.
func discard_card(card: CardInstance) -> void:
	assert(card in hand, "discard called on card not in hand")

	hand.erase(card)
	discard.append(card)


## Moves all discarded cards into the deck and shuffles it.
func shuffle_discard_into_deck() -> void:
	deck.append_array(discard)
	discard.clear()
	deck.shuffle()


## Moves a card from the hand or discard pile to the top of the deck.[br]
## Returns false if the card is not in either pile.
func move_to_deck(card: CardInstance) -> bool:
	if card in hand:
		hand.erase(card)
	elif card in discard:
		discard.erase(card)
	else:
		return false

	deck.insert(0, card)
	return true
