extends CharacterBody2D

@onready var urm_2d: URM2D = $URM2D
@onready var animaciones = $Animaciones

var input_direction: Vector2
var last_direction := "front"  # Dirección por defecto

func set_input_direction():
	input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

func input_axis_direction():
	input_direction.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	input_direction.y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))

func _physics_process(_delta: float) -> void:
	move()
	#move_2()
	pass

func move():
	set_input_direction()
	urm_2d.direction_2d = input_direction
	urm_2d.get_velocity()
	urm_2d.move()
	move_and_slide()
	decide_animation()

func move_2():
	set_input_direction()
	urm_2d.direction_2d = input_direction
	velocity = urm_2d.get_velocity()
	move_and_slide()
	decide_animation()

func decide_animation():
	if velocity.length() == 0:
		match last_direction:
			"front":
				animaciones.play("idle_front")
			"back":
				animaciones.play("idle_back")
			"left":
				animaciones.play("idle_left")
			"right":
				animaciones.play("idle_right")
		return

	# Si hay movimiento, decidimos animación y actualizamos la dirección
	if abs(velocity.x) > abs(velocity.y):
		if velocity.x > 0:
			animaciones.play("walk_right")
			last_direction = "right"
		else:
			animaciones.play("walk_left")
			last_direction = "left"
	else:
		if velocity.y > 0:
			animaciones.play("walk_front")
			last_direction = "front"
		else:
			animaciones.play("walk_back")
			last_direction = "back"
