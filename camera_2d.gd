extends Camera2D

@export var target: Node2D  # Exporto esta variable para poder asignar fácilmente el nodo objetivo (ej. el jugador) desde el editor
@export var target_offset: Vector2 = Vector2.ZERO  # Offset opcional que me permite mover la cámara respecto al jugador (por ejemplo, que no esté centrada)
@export var smooth_speed: float = 5.0  # Esta velocidad controla qué tan rápido la cámara sigue al objetivo (mayor valor = más rápida)

func _ready() -> void:
	# Sin esto la cámara arranca donde la dejó el editor (en el nivel 1, a 332
	# píxeles del jugador) y se desliza hasta él durante el primer segundo.
	# Ese deslizamiento es el "gesto" raro que se ve al empezar: no se mueve el
	# personaje, se mueve el encuadre.
	if target:
		global_position = target.global_position + target_offset
		force_update_scroll()


func _process(delta: float):
	if !target:
		return  # Si no hay objetivo asignado, simplemente no hago nada

	# Calculo la posición objetivo sumando el offset al objetivo (jugador)
	var target_position = target.global_position + target_offset  # global_position: funciona aunque el jugador no cuelgue de la raíz del nivel

	# Uso interpolación lineal (lerp) para mover suavemente la cámara hacia la posición objetivo
	# Cuanto mayor es smooth_speed, más rápido se alcanza el objetivo
	global_position = global_position.lerp(target_position, smooth_speed * delta)

	# Fuerzo que el scroll del viewport se actualice inmediatamente con la nueva posición de la cámara
	force_update_scroll()
