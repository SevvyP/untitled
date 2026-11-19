## The visual layer of an enemy
class_name Enemy
extends Node2D

@onready var health : Label = $health
@onready var vulnerable : Label = $vulnerable
@onready var block : Label = $block

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
	
