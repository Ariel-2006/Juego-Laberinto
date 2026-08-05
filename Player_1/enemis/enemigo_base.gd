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
const AUMENTO_POR_NIVEL := 0.08       # +8% de velocidad por cada nivel superado
const ESPERA_ENTRE_GIROS := 0.25      # segundos mínimos entre un giro y el siguiente

@export var enemy_type: String = ""   # si se deja vacío usa el primer tipo de la tabla
@export var salud_maxima := 3
@export var multiplicador_velocidad := 1.0   # 1.0 = normal; se sube por enemigo desde la escena del nivel

var animated_sprite: AnimatedSprite2D
var attack_timer: Timer
var barra_vida: TextureProgressBar

var salud := 0
var config: Dictionary
var current_direction: Vector2
var is_attacking := false
var espera_giro := 0.0                        # cuenta atrás para no girar varias veces por segundo
var direccion_tras_ataque := Vector2.ZERO     # hacia dónde se irá cuando termine de atacar


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

	# Reduzco el tamaño SIN mover al enemigo de su sitio.
	#
	# Los hijos de esta escena están a ~140 px del origen del nodo, así que al
	# escalar todo se encoge HACIA el origen y el diablo se desplazaba unos
	# 35 px a la izquierda y 27 hacia arriba, saliéndose de su pasillo.
	# Guardo dónde se ve antes de escalar y lo devuelvo ahí después.
	var donde_se_ve := animated_sprite.global_position
	scale *= ESCALA
	global_position += donde_se_ve - animated_sprite.global_position

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

	# Los enemigos van un poco más rápido en cada nivel: 60, 65, 70, 76.
	elegido["move_speed"] *= 1.0 + AUMENTO_POR_NIVEL * nivel_actual()
	elegido["move_speed"] *= multiplicador_velocidad
	return elegido


# Nivel en el que estamos, contando desde 0. Se deduce de cuántos niveles
# lleva superados el jugador en esta partida.
func nivel_actual() -> int:
	if GlobalsEstadisticas == null:
		return 0
	return int(GlobalsEstadisticas.estadisticas_jugador.get("niveles_superados_tot", 0))


func _physics_process(delta: float) -> void:
	if espera_giro > 0.0:
		espera_giro -= delta

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

			# El ataque termina por TIEMPO, no esperando animation_finished.
			# Antes se hacía "await animated_sprite.animation_finished", y si
			# algo cambiaba de animación en medio (por ejemplo al girar), esa
			# señal no llegaba nunca: is_attacking se quedaba en true para
			# siempre y el diablo quedaba congelado sin caminar ni atacar.
			attack_timer.start(duracion_animacion(config["attack_animation"]))

			if collider.has_method("reaccionar_impacto"):
				# Uso la posición del SPRITE, no la del nodo: el origen está a
				# ~140 px del cuerpo visible, así que antes el empujón se
				# calculaba desde un punto equivocado y a veces lanzaba al
				# jugador justo hacia el diablo en vez de alejarlo.
				var direccion: Vector2 = collider.global_position - animated_sprite.global_position
				collider.reaccionar_impacto(direccion)

				# Al terminar el golpe se irá en sentido contrario al jugador,
				# para no quedarse encima impidiéndole escapar.
				if abs(direccion.x) > 0.1:
					direccion_tras_ataque = Vector2(-signf(direccion.x), 0)
	else:
		# Chocó con una pared
		girar_alejandose(collision.get_normal())


# Cambia de sentido usando la normal de la colisión, que apunta hacia el lado
# libre. Antes se hacía "current_direction *= -1" a ciegas: si el diablo
# quedaba encajado chocaba cada frame, se invertía cada frame y se quedaba
# oscilando en el sitio. Y como la animación se reiniciaba también cada frame,
# se veía siempre el cuadro 0: ese era el titileo.
func girar_alejandose(normal: Vector2) -> void:
	if is_attacking or espera_giro > 0.0:
		return

	var nueva := current_direction
	if abs(normal.x) > 0.1:
		nueva = Vector2(signf(normal.x), 0)   # me alejo de la pared
	else:
		nueva = -current_direction            # choque vertical: doy media vuelta

	if nueva != current_direction:
		current_direction = nueva
		update_sprite_direction()

	espera_giro = ESPERA_ENTRE_GIROS
	play_animation(config["walk_animation"])   # sin forzar: no reinicia el ciclo


func play_animation(anim_name: String, force: bool = false) -> void:
	if anim_name == "":
		return
	if force or animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)


func _on_attack_timer_timeout() -> void:
	if not is_attacking:
		return

	is_attacking = false

	if direccion_tras_ataque != Vector2.ZERO:
		current_direction = direccion_tras_ataque
		direccion_tras_ataque = Vector2.ZERO
		update_sprite_direction()

	play_animation(config["walk_animation"], true)
	set_random_attack_timer()


# Cuánto dura una animación en segundos, leída del propio SpriteFrames.
func duracion_animacion(nombre: String) -> float:
	var sf := animated_sprite.sprite_frames
	if sf == null or not sf.has_animation(nombre):
		return 0.7
	var fps := sf.get_animation_speed(nombre)
	if fps <= 0.0:
		return 0.7
	return sf.get_frame_count(nombre) / fps


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
