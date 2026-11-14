class_name Card
extends Node2D
@onready var art : Sprite2D = $Area2D/card_art

@export var data : CardData
@export var index_in_hand : int # since we're keeping all nodes out

var is_dragging : bool = false 
var in_hand_pos : Vector2
var in_hand_rot: float
		
func _process(_delta: float) -> void:
	if is_dragging:
		global_position = get_global_mouse_position()
		
	if is_dragging:
		rotation = 0			

func _on_area_2d_mouse_entered() -> void:
	if is_dragging: return
	z_index = 10
	await tween_anim(0)

func _on_area_2d_mouse_exited() -> void:
	z_index = 0
	await tween_anim(1)
	
func _ready() -> void:
	if data:
		setup(data)
	
func setup(card_data : CardData) -> void:
	data = card_data
	if data.art:
		if !art:
			print("wtf")
		art.texture = data.art

func start_dragging():
	is_dragging = true
	
func stop_dragging():
	is_dragging = false
	position = in_hand_pos
	rotation = in_hand_rot
	
func tween_anim(type: int):
	var t: Tween = create_tween()
	match type:
		0: # picked up animation
			t.tween_property(self, "scale", Vector2(.4, .4), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		1: # dropped
			t.tween_property(self, "scale", Vector2(.33, .33), 0.55).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await t.finished
