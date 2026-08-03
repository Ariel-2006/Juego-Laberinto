class_name Enemy3  # Le doy un nombre a esta clase para poder usarla como nodo personalizado en Godot
extends CharacterBody2D

@export var enemy_type: String = "type3"  # Exporto el tipo del enemigo para configurarlo desde el editor

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D  # Referencia al nodo de animación del enemigo
@onready var attack_timer: Timer = $AttackTimer  # Referencia al temporizador que controla los ataques

# Busco la barra de vida del enemigo si existe dentro del nodo "EnemyLifeBar"
@onready var barra_vida: TextureProgressBar = get_node_or_null("EnemyLifeBar/TextureProgressBar_Enemys")

@export var salud_maxima := 3  # Defino cuánta vida máxima tiene este enemigo
var salud := salud_maxima  # Inicializo la salud actual con la máxima al comienzo

var config: Dictionary  # Diccionario para guardar la configuración personalizada del enemigo
var current_direction: Vector2  # Dirección hacia donde se mueve el enemigo
var is_attacking: bool = false  # Variable para saber si el enemigo está atacando actualmente

func _ready():
	randomize()  # Inicializo el generador aleatorio para elegir tiempos de ataque aleatorios

	# Cargo los valores de configuración del enemigo según su tipo
	config = get_enemy_config(enemy_type)

	# Establezco la dirección inicial del movimiento del enemigo
	current_direction = Vector2.RIGHT if config.get("start_facing_right", false) else Vector2.LEFT
	update_sprite_direction()  # Actualizo hacia qué lado está volteado el sprite
	apply_skin_color()  # Aplico el color que tenga asignado en la configuración
	play_animation(config["walk_animation"])  # Reproduzco la animación de caminar

	set_random_attack_timer()  # Defino el tiempo aleatorio del primer ataque
	attack_timer.timeout.connect(_on_attack_timer_timeout)  # Conecto el temporizador al evento de ataque

	# Configuro la barra de vida si existe
	if barra_vida:
		barra_vida.max_value = salud_maxima
		barra_vida.value = salud
		print("[Enemy3] Barra de vida encontrada y configurada")
	else:
		printerr("[Enemy3] No se encontró la barra de vida")

func _physics_process(delta):
	# Si el enemigo está atacando, no se mueve
	if is_attacking:
		velocity = Vector2.ZERO
	else:
		# Si no está atacando, se mueve en su dirección
		velocity = current_direction * config["move_speed"]

	# Aplico el movimiento y detecto si hay colisión
	var collision = move_and_collide(velocity * delta)
	if collision:
		handle_collision(collision)

func update_sprite_direction():
	# Giro horizontalmente el sprite si se mueve hacia la izquierda
	animated_sprite.flip_h = current_direction.x < 0

func handle_collision(collision: KinematicCollision2D):
	var collider = collision.get_collider()

	# Si colisiona con el jugador
	if collider.is_in_group("player"):
		if not is_attacking:
			is_attacking = true
			play_animation(config["attack_animation"], true)  # Reproduzco la animación de ataque
			attack_timer.start(0.1)  # Inicio temporizador de ataque

			# Si el jugador tiene la función para recibir impacto, la llamo
			if "reaccionar_impacto" in collider:
				var direccion = collider.global_position - global_position
				collider.reaccionar_impacto(direccion)
	else:
		# Si choca con otra cosa, cambia de dirección
		current_direction *= -1
		update_sprite_direction()
		play_animation(config["walk_animation"], true)

func play_animation(anim_name: String, force: bool = false):
	# Reproduzco una animación si es diferente a la actual o si se fuerza su reproducción
	if force or animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)

func _on_attack_timer_timeout():
	# Cuando termina el tiempo de ataque
	if is_attacking:
		await animated_sprite.animation_finished  # Espero que termine la animación
		is_attacking = false
		play_animation(config["walk_animation"], true)  # Reanudo caminata
		set_random_attack_timer()  # Reinicio temporizador de ataque

func set_random_attack_timer():
	# Asigno un tiempo aleatorio entre 1 y 5 segundos para el siguiente ataque
	attack_timer.wait_time = randf_range(1.0, 5.0)
	attack_timer.start()

func apply_skin_color():
	# Si se configuró un color, lo aplico al sprite del enemigo
	if config.has("modulate_color"):
		animated_sprite.modulate = config["modulate_color"]

func get_enemy_config(type_name: String) -> Dictionary:
	# Diccionario con la configuración específica del enemigo de tipo "type3"
	var configs = {
		"type3": {
			"move_speed": 100.0,
			"start_facing_right": false,
			"walk_animation": "enemi_animation3",
			"attack_animation": "atack_enemi3",
			"modulate_color": Color(0.8, 0.5, 1.0),
			"dead_animation": "dead_enemi3"
		}
	}
	# Retorno la configuración específica o por defecto
	return configs.get(type_name, configs["type3"])

func recibir_dano(cantidad: int) -> void:
	# Resto salud por el daño recibido
	salud -= cantidad
	salud = max(salud, 0)  # Me aseguro que la salud no baje de 0
	print("[Enemy3] Salud actual: ", salud)

	# Si hay barra de vida, la actualizo
	if barra_vida:
		barra_vida.value = salud
	else:
		printerr("[Enemy3] No se encontró la barra de vida al recibir daño")

	# Si la salud llega a cero, muere
	if salud <= 0:
		morir()

func morir():
	# Detengo movimiento y ataques
	set_physics_process(false)
	attack_timer.stop()
	is_attacking = false

	# Sumo uno al contador global de enemigos eliminados
	if GlobalsEstadisticas:
		GlobalsEstadisticas.estadisticas_jugador["enemigos_eliminados"] += 1
		print("Enemigo eliminado. Total:", GlobalsEstadisticas.estadisticas_jugador["enemigos_eliminados"])

	# Reproduzco animación de muerte si está definida
	if config.has("dead_animation"):
		play_animation(config["dead_animation"], true)
	else:
		print("[Enemy3] No se encontró animación de muerte")

	await animated_sprite.animation_finished  # Espero que termine la animación
	await get_tree().create_timer(0.7).timeout  # Espero un poco antes de desaparecer

	queue_free()  # Elimino al enemigo de la escena
