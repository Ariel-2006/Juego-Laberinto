extends CharacterBody2D

const VELOCIDAD = 100

func _physics_process(delta):
	var direccion = Vector2.ZERO

	if Input.is_action_pressed("derecha"):
		direccion.x += 1
	if Input.is_action_pressed("izquierda"):
		direccion.x -= 1
	if Input.is_action_pressed("abajo"):
		direccion.y += 1
	if Input.is_action_pressed("arriba"):
		direccion.y -= 1

	direccion = direccion.normalized()
	velocity = direccion * VELOCIDAD
	move_and_slide()
