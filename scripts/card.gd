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
var appearance_tween : Tween

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


## Releases the card at its current position.
func stop_dragging() -> void:
	if appearance_tween and appearance_tween.is_valid():
		appearance_tween.kill()
	is_dragging = false
	z_index = 0
	scale = CARD_DEFAULT_SCALE
	
## Returns a released card to its hand position.
func return_to_hand() -> void:
	is_animating = true

	var tween: Tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(self, "global_position", in_hand_pos, 0.15)
	tween.tween_property(self, "rotation", in_hand_rot, 0.15)
	tween.tween_property(self, "scale", CARD_DEFAULT_SCALE, 0.15)

	await tween.finished
	is_animating = false


## Plays the card hover or return animation.[br]
## Type 0 enlarges the card; type 1 restores its default scale.
func tween_anim(type: int) -> void:
	if appearance_tween and appearance_tween.is_valid():
		appearance_tween.kill()
	var tween: Tween = create_tween()
	appearance_tween = tween

	match type:
		0: # picked up animation
			tween.tween_property(self, "scale", Vector2(0.4, 0.4), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		1: # dropped
			tween.tween_property(self, "scale", CARD_DEFAULT_SCALE, 0.55).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	await tween.finished
