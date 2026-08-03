extends Node

class_name URM2D

@export var speed:float = 150
@export var direction_2d:Vector2 = Vector2.ZERO
@export var normalized:bool = true
@export var character:CharacterBody2D

func _ready() -> void:
	pass

func get_velocity() -> Vector2:
	if normalized:
		direction_2d = direction_2d.normalized()
	print(direction_2d)
	return direction_2d * speed

func move():
	character.velocity = get_velocity()
	character.move_and_slide()
	
