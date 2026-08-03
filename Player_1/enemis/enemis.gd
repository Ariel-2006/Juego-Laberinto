class_name Enemy  # Declaro la clase Enemy para poder reutilizarla fácilmente en otras escenas
extends CharacterBody2D  

@export var enemy_type: String = "default"  # Exporto el tipo de enemigo para configurar distintos comportamientos desde el editor

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2d  # Obtengo la referencia al sprite animado del enemigo
@onready var attack_timer: Timer = $AttackTimer  # Referencia al temporizador que controla la duración del ataque

# Obtengo la barra de vida del enemigo si existe dentro del nodo EnemyLifeBar
@onready var barra_vida: TextureProgressBar = get_node_or_null("EnemyLifeBar/TextureProgressBar_Enemys")

@export var salud_maxima := 3  # Salud máxima del enemigo
var salud := salud_maxima  # Inicializo la salud actual con el valor máximo

var config: Dictionary  # Diccionario de configuración que se llena según el tipo de enemigo
var current_direction: Vector2  # Dirección actual de movimiento del enemigo
var is_attacking: bool = false  # Indica si el enemigo está en estado de ataque

func _ready():
	randomize()  # Llamo a randomize() para que las funciones aleatorias funcionen bien

	config = get_enemy_config(enemy_type)  # Obtengo la configuración según el tipo de enemigo

	# Establezco dirección inicial según configuración (derecha o izquierda)
	current_direction = Vector2.RIGHT if config.get("start_facing_right", false) else Vector2.LEFT
	update_sprite_direction()  # Ajusto orientación del sprite según dirección
	apply_skin_color()  # Aplico el color configurado al sprite

	play_animation(config["walk_animation"])  # Inicio la animación de caminar
	set_random_attack_timer()  # Establezco el primer tiempo aleatorio para atacar

	attack_timer.timeout.connect(_on_attack_timer_timeout)  # Conecto la señal timeout del temporizador al método que maneja fin del ataque

	# Configuro la barra de vida si fue encontrada
	if barra_vida:
		barra_vida.max_value = salud_maxima
		barra_vida.value = salud
		print("Barra de vida del enemigo encontrada y configurada")
	else:
		printerr("ERROR: No se encontró la barra de vida del enemigo")

func _physics_process(delta):
	if is_attacking:
		velocity = Vector2.ZERO  # Si está atacando, no se mueve
	else:
		velocity = current_direction * config["move_speed"]  # Si no está atacando, se mueve en la dirección actual

	var collision = move_and_collide(velocity * delta)  # Muevo al enemigo y verifico si colisiona con algo
	if collision:
		handle_collision(collision)  # Si hay colisión, la manejo

func update_sprite_direction():
	# Giro el sprite horizontalmente si se está moviendo a la izquierda
	animated_sprite.flip_h = current_direction.x < 0

func handle_collision(collision: KinematicCollision2D):
	var collider = collision.get_collider()  # Obtengo el objeto con el que colisionó

	if collider.is_in_group("player"):  # Si colisionó con el jugador
		if not is_attacking:
			is_attacking = true
			play_animation(config["attack_animation"], true)  # Reproduzco animación de ataque forzada
			attack_timer.start(0.1)  # Empiezo un pequeño temporizador para simular tiempo de ataque

			# Si el jugador tiene método de reacción, lo llamo
			if "reaccionar_impacto" in collider:
				var direccion = collider.global_position - global_position
				collider.reaccionar_impacto(direccion)
	else:
		# Si choca con otra cosa, invierto dirección y actualizo animación
		current_direction *= -1
		update_sprite_direction()
		play_animation(config["walk_animation"], true)

func play_animation(anim_name: String, force: bool = false):
	# Reproduzco una animación solo si no se está ya reproduciendo, o si se fuerza
	if force or animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)

func _on_attack_timer_timeout():
	# Este método se llama cuando termina el temporizador de ataque
	if is_attacking:
		await animated_sprite.animation_finished  # Espero que termine la animación de ataque
		is_attacking = false  # Termina el estado de ataque
		play_animation(config["walk_animation"], true)  # Reanudo animación de caminar
		set_random_attack_timer()  # Reinicio el temporizador de ataque

func set_random_attack_timer():
	# Establezco un tiempo aleatorio entre 1 y 5 segundos para el próximo ataque
	attack_timer.wait_time = randf_range(1.0, 5.0)
	attack_timer.start()

func apply_skin_color():
	# Si el diccionario tiene color personalizado, lo aplico al sprite del enemigo
	if config.has("modulate_color"):
		animated_sprite.modulate = config["modulate_color"]

func get_enemy_config(type_name: String) -> Dictionary:
	# Devuelvo un diccionario con la configuración del enemigo según su tipo
	var configs = {
		"default": {
			"move_speed": 100.0,
			"start_facing_right": false,
			"walk_animation": "enemi_animation",
			"attack_animation": "atack_enemi",
			"modulate_color": Color(1, 1, 1)
		},
	}
	return configs.get(type_name, configs["default"])  # Si no existe el tipo, uso la configuración por defecto

func recibir_dano(cantidad: int) -> void:
	salud -= cantidad  # Resto la cantidad de daño recibido
	salud = max(salud, 0)  # Me aseguro que no baje de cero
	print("Salud del enemigo actual: ", salud)

	if barra_vida:
		barra_vida.value = salud  # Actualizo la barra visualmente
	else:
		printerr("La barra de vida del enemigo no fue encontrada al recibir daño")

	if salud <= 0:
		morir()  # Si ya no tiene salud, ejecuto la función de muerte

func morir():
	set_physics_process(false)  # Detengo el procesamiento de físicas para que no se mueva más
	attack_timer.stop()  # Detengo cualquier ataque pendiente
	is_attacking = false  # Me aseguro de salir del estado de ataque

	# Aumento el conteo global de enemigos eliminados
	if GlobalsEstadisticas:
		GlobalsEstadisticas.estadisticas_jugador["enemigos_eliminados"] += 1
		print("Enemigos eliminados:", GlobalsEstadisticas.estadisticas_jugador["enemigos_eliminados"])

	play_animation("dead_animation", true)  # Reproduzco la animación de muerte

	await animated_sprite.animation_finished  # Espero que la animación de muerte termine

	await get_tree().create_timer(0.7).timeout  # Espero 0.7 segundos adicionales

	queue_free()  # Finalmente elimino al enemigo de la escena
