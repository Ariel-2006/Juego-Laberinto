class_name EnemigoBase
extends CharacterBody2D
#
# Lógica compartida por TODOS los enemigos del juego.
#
# Antes esta lógica estaba copiada tres veces (enemis.gd, enemis_2.gd y
# enemis_3.gd, ~145 líneas cada uno). Cualquier arreglo había que hacerlo
# tres veces. Ahora vive aquí y cada enemigo concreto solo declara su
# configuración: sus animaciones, su color y su velocidad si es distinta.
#
# No hace falta tocar ninguna escena: los tres scripts siguen existiendo
# con el mismo nombre y el mismo class_name, solo que ahora heredan de aquí.

# --- Ajustes globales de todos los enemigos ------------------------------
# Cambiar estos dos números afecta a los tres tipos de enemigo a la vez.
const VELOCIDAD_POR_DEFECTO := 60.0   # antes 100.0: eran demasiado rápidos
const ESCALA := 0.75                  # los reduce al 75% de su tamaño original

@export var enemy_type: String = ""   # si se deja vacío usa el primer tipo de la tabla
@export var salud_maxima := 3

var animated_sprite: AnimatedSprite2D
var attack_timer: Timer
var barra_vida: TextureProgressBar

var salud := 0
var config: Dictionary
var current_direction: Vector2
var is_attacking := false


# Cada enemigo concreto sobreescribe esta función con sus propios tipos.
func tabla_de_tipos() -> Dictionary:
	return {}


func _ready() -> void:
	randomize()
	salud = salud_maxima

	# Busco el sprite animado sin depender del nombre exacto del nodo:
	# en una escena se llama "AnimatedSprite2d" y en las otras "AnimatedSprite2D".
	animated_sprite = _buscar_sprite()
	attack_timer = get_node_or_null("AttackTimer")
	barra_vida = get_node_or_null("EnemyLifeBar/TextureProgressBar_Enemys")

	if animated_sprite == null:
		printerr("[", name, "] No se encontró el AnimatedSprite2D del enemigo.")
		return
	if attack_timer == null:
		printerr("[", name, "] No se encontró el nodo AttackTimer.")
		return

	config = get_enemy_config(enemy_type)

	# Reduzco el tamaño respetando la escala que cada nivel le puso a mano
	scale *= ESCALA

	current_direction = Vector2.RIGHT if config.get("start_facing_right", false) else Vector2.LEFT
	update_sprite_direction()
	apply_skin_color()

	play_animation(config["walk_animation"])
	set_random_attack_timer()
	attack_timer.timeout.connect(_on_attack_timer_timeout)

	if barra_vida:
		barra_vida.max_value = salud_maxima
		barra_vida.value = salud


func _buscar_sprite() -> AnimatedSprite2D:
	for hijo in get_children():
		if hijo is AnimatedSprite2D:
			return hijo
	return null


func get_enemy_config(type_name: String) -> Dictionary:
	var tabla := tabla_de_tipos()
	if tabla.is_empty():
		printerr("[", name, "] Este enemigo no declaró ningún tipo.")
		return {"walk_animation": "", "attack_animation": ""}

	var elegido: Dictionary = tabla.get(type_name, tabla.values()[0])

	# Si el tipo no define velocidad, uso la general. Así la velocidad de
	# todos los enemigos se cambia en un solo sitio (VELOCIDAD_POR_DEFECTO).
	if not elegido.has("move_speed"):
		elegido["move_speed"] = VELOCIDAD_POR_DEFECTO
	return elegido


func _physics_process(delta: float) -> void:
	if is_attacking:
		velocity = Vector2.ZERO   # mientras ataca se queda quieto
	else:
		velocity = current_direction * config["move_speed"]

	var collision := move_and_collide(velocity * delta)
	if collision:
		handle_collision(collision)


func update_sprite_direction() -> void:
	animated_sprite.flip_h = current_direction.x < 0


func handle_collision(collision: KinematicCollision2D) -> void:
	var collider = collision.get_collider()
	if collider == null:
		return

	if collider.is_in_group("player"):
		if not is_attacking:
			is_attacking = true
			play_animation(config["attack_animation"], true)
			attack_timer.start(0.1)

			if collider.has_method("reaccionar_impacto"):
				var direccion: Vector2 = collider.global_position - global_position
				collider.reaccionar_impacto(direccion)
	else:
		# Chocó con una pared: se da la vuelta
		current_direction *= -1
		update_sprite_direction()
		play_animation(config["walk_animation"], true)


func play_animation(anim_name: String, force: bool = false) -> void:
	if anim_name == "":
		return
	if force or animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)


func _on_attack_timer_timeout() -> void:
	if is_attacking:
		await animated_sprite.animation_finished
		is_attacking = false
		play_animation(config["walk_animation"], true)
		set_random_attack_timer()


func set_random_attack_timer() -> void:
	attack_timer.wait_time = randf_range(1.0, 5.0)
	attack_timer.start()


func apply_skin_color() -> void:
	if config.has("modulate_color"):
		animated_sprite.modulate = config["modulate_color"]


func recibir_dano(cantidad: int) -> void:
	salud = max(salud - cantidad, 0)

	if barra_vida:
		barra_vida.value = salud

	if salud <= 0:
		morir()


func morir() -> void:
	set_physics_process(false)
	if attack_timer:
		attack_timer.stop()
	is_attacking = false

	GlobalsEstadisticas.estadisticas_jugador["enemigos_eliminados"] += 1

	if config.has("dead_animation"):
		play_animation(config["dead_animation"], true)
		await animated_sprite.animation_finished

	await get_tree().create_timer(0.7).timeout
	queue_free()
