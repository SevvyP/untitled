extends Node2D

@onready var current_scene_placeholder : Node2D = $current_scene
@onready var current_health : Label = $current_health
@onready var max_health: Label = $max_health
@onready var battle_scene : PackedScene = preload("res://scenes/battle.tscn")
@onready var reward_screen : PackedScene = preload("res://prefabs/reward_screen.tscn")
@onready var run_lost_screen : PackedScene = preload("res://prefabs/run_lost_screen.tscn")

## The initial state of the character at the start of the run. For now should just be the base stats,
## but in theory could be modified before passing in
@export var character_data : CharacterData

## The initial deck of cards at the start of the run
@export var starting_deck : Array[CardData]

## The global state of the deck during the run. Saves modifications to cards such as upgrades
## and enchantments
var deck : Array[CardInstance]

## The global state of the character during the run. Maintains state between battles, such as 
## current health and max health
var character_instance : CharacterInstance

## Setup the basic gameplay loop
func _ready() -> void:
	# TODO: replace with random enemies and the selected character
	var enemy : EnemyData = load("res://enemies/winorlose.tres")
	var character_data : CharacterData= load("res://characters/untitled.tres")
	character_instance = CharacterInstance.new(character_data)
	
	# TODO: build and assign starting deck instead of placeholder
	var Strike: CardData = load("res://cards/srike.tres")
	var Defend: CardData = load("res://cards/defend.tres")
	var Draw: CardData = load("res://cards/draw.tres")
	var Vulnerable: CardData = load("res://cards/vulnerable.tres")
	for i in range(10):
		if i % 4 == 0:
			starting_deck.append(Vulnerable)
		elif i % 3 == 0:
			starting_deck.append(Strike)
		elif i % 2 == 0:
			starting_deck.append(Draw)
		else:
			starting_deck.append(Defend)
	for i in range(starting_deck.size()):
		deck.append(CardInstance.new(starting_deck[i]))
	
	var battle = load_battle(deck, character_instance, [enemy])
	
## updates run trackers like current and max health	
func _process(_delta: float) -> void:
	current_health.text = str(character_instance.current_health)
	max_health.text = str(character_instance.max_health)


## Loads the battle and adds it to the current scene
func load_battle(deck : Array[CardInstance], character : CharacterInstance, enemies : Array[EnemyData]) -> Battle:
	var battle : Battle = battle_scene.instantiate()
	current_scene_placeholder.add_child(battle)
	battle.setup(deck, character, enemies[0])
	battle.card_reward_chosen.connect(_on_card_reward_chosen.bind())
	battle.combat_won_next.connect(_on_combat_won_next.bind())
	return battle
	
	
## Handles adding a card reward to the deck	
func _on_card_reward_chosen(card : CardInstance):
	deck.append(card)


## Handles the next button press to move on from a combat
func _on_combat_won_next():
	for child in current_scene_placeholder.get_children():
		child.queue_free()
	await get_tree().create_timer(0.15).timeout
	#TODO: randomly generate next combat
	var enemy : EnemyData = load("res://enemies/winorlose.tres")
	load_battle(deck, character_instance, [enemy])


## Handles displaying the deck when the icon is pressed in the top bar
func _on_deck_pressed() -> void:
	for card in deck:
		print(card.data.card_name)
		
