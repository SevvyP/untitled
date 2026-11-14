class_name Card
extends Node2D

@onready var art: Sprite2D = $Area2D/card_art

@export var data: CardData

# the logical state of the card
var card_instance: CardInstance

var is_dragging: bool = false
var is_animating: bool = false
var in_hand_pos: Vector2
var in_hand_rot: float

const CARD_DEFAULT_SCALE := Vector2(0.33, 0.33)


## Initializes the card artwork when the node enters the scene tree.
func _ready() -> void:
	if card_instance:
		setup(card_instance.data)
	elif data:
		setup(data)


## Updates the card position and rotation while dragging.
func _process(_delta: float) -> void:
	if is_dragging:
		global_position = get_global_mouse_position()
		rotation = 0


## Plays the hover animation when the mouse enters the card.
func _on_area_2d_mouse_entered() -> void:
	if is_dragging or is_animating:
		return

	z_index = 10
	await tween_anim(0)


## Restores the card scale when the mouse leaves.
func _on_area_2d_mouse_exited() -> void:
	if is_dragging or is_animating:
		return

	z_index = 0
	await tween_anim(1)


## Assigns the card definition and updates its artwork.
func setup(card_data: CardData) -> void:
	data = card_data

	if not is_node_ready():
		return

	if data and data.art:
		art.texture = data.art


## Associates the visual card with its logical CardInstance.
func setup_instance(instance: CardInstance) -> void:
	card_instance = instance
	setup(instance.data)


## Starts dragging the card if it is not currently animating.
func start_dragging() -> void:
	if is_animating:
		return

	is_dragging = true
	z_index = 10


## Stops dragging and restores the card's hand position.
func stop_dragging() -> void:
	if not is_dragging:
		return

	is_dragging = false
	global_position = in_hand_pos
	rotation = in_hand_rot
	z_index = 0

	await tween_anim(1)


## Plays the card hover or return animation.[br]
## Type 0 enlarges the card; type 1 restores its default scale.
func tween_anim(type: int) -> void:
	var tween: Tween = create_tween()

	match type:
		0: # picked up animation
			tween.tween_property(self, "scale", Vector2(0.4, 0.4), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		1: # dropped
			tween.tween_property(self, "scale", CARD_DEFAULT_SCALE, 0.55).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	await tween.finished
