class_name Enemy2  # Defino esta clase como Enemy2 para poder usarla desde otras escenas fácilmente
extends CharacterBody2D  

@export var enemy_type: String = "type2"  # Exporto el tipo de enemigo para configurar sus parámetros desde el editor

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D  # Obtengo el sprite animado del enemigo
@onready var attack_timer: Timer = $AttackTimer  # Obtengo el temporizador para controlar ataques

# Referencia a la barra de vida del enemigo si existe en el nodo "EnemyLifeBar"
@onready var barra_vida: TextureProgressBar = get_node_or_null("EnemyLifeBar/TextureProgressBar_Enemys")

@export var salud_maxima := 3  # Defino la salud máxima del enemigo
var salud := salud_maxima  # Inicializo la salud actual igual a la máxima

var config: Dictionary  # Diccionario que contendrá la configuración del enemigo según su tipo
var current_direction: Vector2  # Dirección actual del movimiento del enemigo
var is_attacking: bool = false  # Variable para saber si el enemigo está atacando

func _ready():
	randomize()  # Inicializo el generador aleatorio para obtener tiempos aleatorios

	config = get_enemy_config(enemy_type)  # Lleno el diccionario con los parámetros del tipo de enemigo

	# Asigno dirección inicial según configuración
	current_direction = Vector2.RIGHT if config.get("start_facing_right", false) else Vector2.LEFT
	update_sprite_direction()  # Ajusto orientación del sprite
	apply_skin_color()  # Aplico color al sprite si está configurado
	play_animation(config["walk_animation"])  # Inicio la animación de caminar

	set_random_attack_timer()  # Configuro el tiempo del primer ataque
	attack_timer.timeout.connect(_on_attack_timer_timeout)  # Conecto el temporizador al método que maneja ataques

	# Inicializo la barra de vida si existe
	if barra_vida:
		barra_vida.max_value = salud_maxima
		barra_vida.value = salud
		print("[Enemy2] Barra de vida encontrada y configurada")
	else:
		printerr("[Enemy2] No se encontró la barra de vida")

func _physics_process(delta):
	# Si está atacando no se mueve, sino avanza en su dirección
	if is_attacking:
		velocity = Vector2.ZERO
	else:
		velocity = current_direction * config["move_speed"]

	# Muevo al enemigo y detecto si colisiona
	var collision = move_and_collide(velocity * delta)
	if collision:
		handle_collision(collision)

func update_sprite_direction():
	# Giro el sprite si se mueve hacia la izquierda
	animated_sprite.flip_h = current_direction.x < 0

func handle_collision(collision: KinematicCollision2D):
	var collider = collision.get_collider()

	if collider.is_in_group("player"):  # Si colisiona con el jugador
		if not is_attacking:
			is_attacking = true
			play_animation(config["attack_animation"], true)  # Reproduzco animación de ataque
			attack_timer.start(0.1)  # Inicio temporizador corto para ataque

			# Si el jugador tiene función de reacción, la llamo
			if "reaccionar_impacto" in collider:
				var direccion = collider.global_position - global_position
				collider.reaccionar_impacto(direccion)
	else:
		# Si choca con algo más, cambio de dirección
		current_direction *= -1
		update_sprite_direction()
		play_animation(config["walk_animation"], true)

func play_animation(anim_name: String, force: bool = false):
	# Reproduzco animación si no es la actual o si se fuerza
	if force or animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)

func _on_attack_timer_timeout():
	# Cuando el ataque termina, vuelvo al estado normal
	if is_attacking:
		await animated_sprite.animation_finished
		is_attacking = false
		play_animation(config["walk_animation"], true)  # Reanudo animación de caminar
		set_random_attack_timer()  # Reinicio temporizador de ataque

func set_random_attack_timer():
	# Genero un tiempo aleatorio para el siguiente ataque entre 1 y 5 segundos
	attack_timer.wait_time = randf_range(1.0, 5.0)
	attack_timer.start()

func apply_skin_color():
	# Si en la configuración hay color, lo aplico al sprite
	if config.has("modulate_color"):
		animated_sprite.modulate = config["modulate_color"]

func get_enemy_config(type_name: String) -> Dictionary:
	# Diccionario de configuraciones por tipo de enemigo
	var configs = {
		"type2": {
			"move_speed": 100.0,
			"start_facing_right": false,
			"walk_animation": "enemi_animation2",
			"attack_animation": "atack_enemi2",
			"modulate_color": Color(0.8, 0.5, 1.0),  # Color violeta claro
			"dead_animation": "dead_enemi2"  # Animación de muerte
		}
	}
	# Retorno la configuración solicitada o la del type2 por defecto
	return configs.get(type_name, configs["type2"])

func recibir_dano(cantidad: int) -> void:
	# Resto salud según el daño recibido
	salud -= cantidad
	salud = max(salud, 0)  # Me aseguro que no baje de 0
	print("[Enemy2] Salud actual: ", salud)

	# Actualizo barra de vida si está presente
	if barra_vida:
		barra_vida.value = salud
	else:
		printerr("[Enemy2] La barra de vida no fue encontrada al recibir daño")

	# Si la salud llega a 0, el enemigo muere
	if salud <= 0:
		morir()

func morir():
	# Detengo todo movimiento y ataques
	set_physics_process(false)
	attack_timer.stop()
	is_attacking = false

	# Aumento el contador de enemigos eliminados en las estadísticas globales
	if GlobalsEstadisticas:
		GlobalsEstadisticas.estadisticas_jugador["enemigos_eliminados"] += 1
		print("Enemigo eliminado. Total:", GlobalsEstadisticas.estadisticas_jugador["enemigos_eliminados"])

	# Reproduzco animación de muerte si está definida
	if config.has("dead_animation"):
		play_animation(config["dead_animation"], false)
	else:
		print("[Enemy2] No se encontró animación de muerte")

	# Espero que termine la animación de muerte
	await animated_sprite.animation_finished
	await get_tree().create_timer(0.7).timeout  # Pausa breve antes de eliminar

	# Elimino al enemigo de la escena
	queue_free()
