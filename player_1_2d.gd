extends CharacterBody2D
class_name Player

@export var speed := 300
@export var vertical_speed := 300
@export var gravity := 600
@export var bling_interval := 15.0
@export var max_salud := 5

var salud := max_salud:
	set(value):
		salud = clamp(value, 0, max_salud)
		actualizar_barra_vida()

var inmune := false
var forzando_retroceso := false
var barra_life: TextureProgressBar

@onready var animated_sprite_p1: AnimatedSprite2D = $Animated_sprit_p1
@onready var animated_sprite_p2: AnimatedSprite2D = $Animated_sprit_p2
@onready var animated_sprite_p3: AnimatedSprite2D = $Animated_sprit_p3
@onready var attack_area: Area2D = $AttackArea

var animated_sprite: AnimatedSprite2D
var muerto := false

var movement := {
	"speed": speed,
	"vertical_speed": vertical_speed,
	"gravity": gravity,
	"gravity_enabled": true
}

var animation := {
	"idle_time": 0.0,
	"bling_interval": bling_interval,
	"is_attacking": false,
	"attack_cooldown": 0.5,
	"can_attack": true
}

func cargar_personaje():
	var selected_index = GlobalsEstadisticas.selected_character
	var anim_paths = GlobalsEstadisticas.characters_paths[selected_index]

	# Asignar el sprite según personaje seleccionado
	if selected_index == 0:
		animated_sprite = animated_sprite_p1
		animated_sprite_p1.visible = true
		animated_sprite_p2.visible = false
		animated_sprite_p3.visible = false
	elif selected_index == 1:
		animated_sprite = animated_sprite_p2
		animated_sprite_p1.visible = false
		animated_sprite_p2.visible = true
		animated_sprite_p3.visible = false
	elif selected_index == 2:
		animated_sprite = animated_sprite_p3
		animated_sprite_p1.visible = false
		animated_sprite_p2.visible = false
		animated_sprite_p3.visible = true

	# Preparar animaciones dinámicamente
	var new_sprite_frames = SpriteFrames.new()

	for anim_name in anim_paths.keys():
		var path = anim_paths[anim_name]
		var files = listar_imagenes(path)

		if files.is_empty():
			printerr("Sin imágenes para la animación '", anim_name, "' en ", path)
			continue

		new_sprite_frames.add_animation(anim_name)
		for file in files:
			var texture = load(path.path_join(file))
			if texture:
				new_sprite_frames.add_frame(anim_name, texture)

	animated_sprite.frames = new_sprite_frames


# Devuelve los nombres de imagen de una carpeta, funcionando IGUAL dentro del
# editor y dentro del .exe/.web ya exportado.
#
# Por qué hace falta: al exportar, Godot NO empaqueta los .png originales.
# Solo guarda el archivo .png.import y la textura ya convertida. Entonces un
# listado que busque ".png" encuentra 0 archivos y el personaje sale invisible.
# La solución es quitarle el sufijo .import (o .remap) a lo que se lista.
func listar_imagenes(ruta: String) -> Array:
	var vistos := {}
	var dir = DirAccess.open(ruta)
	if dir == null:
		printerr("No se pudo abrir el directorio: ", ruta)
		return []

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		var limpio = file_name
		if limpio.ends_with(".import") or limpio.ends_with(".remap"):
			limpio = limpio.get_basename()
		var ext = limpio.get_extension().to_lower()
		if ext == "png" or ext == "jpg" or ext == "jpeg":
			vistos[limpio] = true   # el diccionario evita duplicados
		file_name = dir.get_next()
	dir.list_dir_end()

	var lista = vistos.keys()
	lista.sort()
	return lista

func _ready():
	cargar_personaje()

	attack_area.monitoring = false
	movement.gravity_enabled = true
	velocity = Vector2.ZERO
	animated_sprite.connect("animation_finished", _on_animation_finished)
	attack_area.body_entered.connect(_on_attack_area_body_entered)

	barra_life = get_tree().current_scene.find_child("TextureProgressBar", true, false)
	if barra_life:
		barra_life.max_value = max_salud
		barra_life.value = salud
	else:
		printerr("No se encontró la barra de vida.")

func _physics_process(delta):
	if muerto:
		return

	var input_dir = Input.get_vector("izquierda", "derecha", "subir", "bajar")

	if Input.is_action_just_pressed("ataque") and not animation.is_attacking and animation.can_attack:
		start_attack()

	handle_movement(delta, input_dir)
	update_animation(animated_sprite)
	move_and_slide()

func handle_movement(delta: float, input_dir: Vector2) -> void:
	if not forzando_retroceso:
		velocity.x = input_dir.x * movement.speed

	if movement.gravity_enabled:
		velocity.y += movement.gravity * delta
		if is_on_floor():
			movement.gravity_enabled = false
			velocity.y = 0
	else:
		velocity.y = input_dir.y * movement.vertical_speed

func start_attack():
	if muerto:
		return

	animation.is_attacking = true
	animation.can_attack = false
	attack_area.monitoring = true
	animated_sprite.play("Ataque")

	await get_tree().create_timer(0.2).timeout
	attack_area.monitoring = false

	await get_tree().create_timer(animation.attack_cooldown).timeout
	animation.can_attack = true
	animation.is_attacking = false

func _on_attack_area_body_entered(body):
	if animation.is_attacking and body.is_in_group("enemigo"):
		if body.has_method("recibir_dano"):
			body.recibir_dano(1)

func update_animation(sprite: AnimatedSprite2D) -> void:
	if muerto:
		# Si ya está en Dead, no volver a reproducir
		if sprite.animation != "Dead":
			sprite.play("Dead")
		return

	if animation.is_attacking:
		if sprite.animation != "Ataque":
			sprite.play("Ataque")
		return

	if velocity.x != 0:
		sprite.play("Run")
		sprite.flip_h = velocity.x < 0
	else:
		if sprite.animation == "Idle":
			animation.idle_time += get_process_delta_time()
			if animation.idle_time >= animation.bling_interval:
				sprite.play("Idle_bling")
				animation.idle_time = 0.0
		elif sprite.animation != "Idle_bling":
			sprite.play("Idle")



func reaccionar_impacto(from_direction: Vector2):
	if inmune or muerto:
		return

	salud -= 1
	inmune = true
	animated_sprite.modulate = Color(1, 0, 0)

	# Si el golpe venía justo de arriba o de abajo, sign(x) daba 0: el empuje
	# quedaba en cero Y ADEMAS se bloqueaba el control. El jugador quedaba
	# clavado contra el diablo sin poder escapar. Ahora siempre hay dirección.
	var direccion_horizontal = sign(from_direction.x)
	if direccion_horizontal == 0:
		direccion_horizontal = -1.0 if animated_sprite.flip_h else 1.0
	var retroceso = Vector2(direccion_horizontal * 260, -80)
	velocity = retroceso
	forzando_retroceso = true

	if salud <= 0:
		animacion_muerte()
		return

	# Antes: 0.5 s sin control + 0.7 s de inmunidad. Como el diablo volvía a
	# golpear apenas terminaba la inmunidad, perdías el control casi la mitad
	# del tiempo y era imposible huir. Ahora el bloqueo dura lo justo para que
	# se note el golpe, y la inmunidad es más larga para poder escapar.
	await get_tree().create_timer(0.25).timeout
	forzando_retroceso = false
	await get_tree().create_timer(0.95).timeout
	inmune = false
	animated_sprite.modulate = Color(1, 1, 1)

func actualizar_barra_vida():
	if barra_life:
		barra_life.value = salud

func cambiar_a_game_over():
	get_tree().paused = false  
	get_tree().change_scene_to_file("res://game_over.tscn")

func _on_animation_finished(anim_name):
	print("Animación terminada:", anim_name)

	if muerto:
		# Forzar minúsculas para asegurar coincidencia sin importar cómo se imprima
		if anim_name.to_lower() == "dead":
			print("Cambiando a game over ahora")
			cambiar_a_game_over()


func animacion_muerte():
	if muerto:
		return

	muerto = true
	animated_sprite.modulate = Color(1, 1, 1)
	animated_sprite.play("Dead")
	await get_tree().create_timer(1.5).timeout
	if muerto:
		print("Forzando cambio a game over tras timeout de seguridad")
		cambiar_a_game_over()
