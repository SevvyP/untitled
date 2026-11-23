extends CanvasLayer

signal reward_chosen(data: CardInstance)
signal next_pressed()

const DEFAULT_CARD_SCALE = Vector2(.33, .33)
const CARD_SCENE: PackedScene = preload("res://prefabs/card.tscn")

@onready var cards_box: HBoxContainer = $reward_panel/cards
@onready var dimmer: ColorRect = $dimmer
@onready var reward_panel: Control = $reward_panel

## Card rewards to offer the player
@export var card_rewards : Array[Card]

var reward_group := ButtonGroup.new()
var selected_reward: CardInstance

func _ready() -> void:
	# Pause the background game scene
	get_tree().paused = true
	
	# Prepare starting states for the animation
	dimmer.modulate.a = 0.0
	reward_panel.scale = Vector2(0.9, 0.9)
	reward_panel.modulate.a = 0.0
	
	# Animate the fade and pop-in
	var tween = create_tween().set_parallel(true)
	tween.tween_property(dimmer, "modulate:a", 1.0, 0.25)
	tween.tween_property(reward_panel, "modulate:a", 1.0, 0.25)
	tween.tween_property(reward_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# add rewards to the screen
	# TODO: pass in randomized card rewards
	for path in [
		"res://cards/rare.tres",
		"res://cards/rare.tres",
		"res://cards/rare.tres",
		"res://cards/rare.tres",
	]:
		add_reward_card(CardInstance.new(load(path)))
		
	
## Add a card to the offered rewards cards	
func add_reward_card(data: CardInstance) -> void:
	var slot := Button.new()
	slot.flat = true
	slot.toggle_mode = true
	slot.button_group = reward_group
	slot.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot.pressed.connect(_on_reward_pressed.bind(data))
	cards_box.add_child(slot)

	var card := CARD_SCENE.instantiate() as Card
	slot.add_child(card)
	card.setup(data.data)
	card.scale = Card.CARD_DEFAULT_SCALE
	card_rewards.append(card)

	# Reserve the resting card's footprint in the HBox.
	var card_size := card.art.get_rect().size * card.art.scale.abs() * card.scale
	slot.custom_minimum_size = card_size
	var center_card := func() -> void:
		card.position = slot.size * 0.5

	slot.resized.connect(center_card)
	center_card.call()

	# Let the slot own hover across the entire card, including its text.
	var area := card.get_node("Area2D") as Area2D
	area.input_pickable = false
	for child in card.find_children("*", "Control", true, false):
		(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

	slot.mouse_entered.connect(card._on_area_2d_mouse_entered)
	slot.mouse_exited.connect(card._on_area_2d_mouse_exited)

	
## Handles the selection of a reward and emits the chosen reward to be handled up the tree
func _on_reward_pressed(data: CardInstance) -> void:
	selected_reward = data
	reward_chosen.emit(selected_reward)
	for child in cards_box.get_children():
		child.queue_free()

## Handles the next button being pressed and emits a signal to be handled up the tree
func _on_next_pressed() -> void:
	next_pressed.emit()
	
