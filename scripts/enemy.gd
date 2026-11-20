## The visual layer of an enemy
class_name Enemy
extends Node2D

@onready var health : Label = $health
@onready var vulnerable : Label = $vulnerable
@onready var block : Label = $block
@onready var sprite : Sprite2D = $Bigbad1

var enemy : EnemyInstance

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	health.text = str(enemy.health)
	vulnerable.text = str(enemy.vulnerable)
	block.text = str(enemy.block)
	
func setup(enemy_instance : EnemyInstance) -> void:
	if not enemy_instance:
		return
	
	enemy = enemy_instance
	
func animate_death() -> void:
	var death_material := material as ShaderMaterial
	if death_material == null:
		return

	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.025

	var noise_texture := NoiseTexture2D.new()
	noise_texture.width = 512
	noise_texture.height = 512
	noise_texture.noise = noise

	death_material.set_shader_parameter("position", Vector2(0.0, 1.0))
	death_material.set_shader_parameter("radius", 0.0)
	death_material.set_shader_parameter("burnColor", Color("ff1e00ff"))
	death_material.set_shader_parameter("borderWidth", 0.02)
	death_material.set_shader_parameter("burnMult", 0.14)
	death_material.set_shader_parameter("noiseTexture", noise_texture)
	

	var tween := create_tween()
	tween.tween_method(update_radius, 0.0, 2.0, 1.5)
	await tween.finished

func update_radius(value: float):
	if material:
		material.set_shader_parameter("radius", value)
	
