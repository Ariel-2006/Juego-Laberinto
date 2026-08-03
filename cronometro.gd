extends Node

@onready var timer_label: Label = $Label  # Obtengo referencia directa al nodo Label que va a mostrar el tiempo en pantalla

func _ready():
	# Cuando se inicia esta escena (por ejemplo, un HUD o menú), inicio el cronómetro global llamando al singleton
	GlobalsEstadisticas.iniciar_cronometro()

func _process(delta):
	# Esta función se ejecuta cada frame; aquí actualizo los datos y la interfaz constantemente
	actualizar_tiempo()  # Llamo a una función que actualiza el tiempo transcurrido en el cronómetro global
	actualizar_ui()  # Luego actualizo la UI (el Label) para reflejar el nuevo tiempo

func actualizar_tiempo():
	# Esta función solo llama a la función del singleton que calcula el tiempo jugado actual
	# El resultado de esa función actualiza automáticamente el valor en el diccionario `estadisticas_jugador`
	GlobalsEstadisticas.obtener_tiempo_actual()

func actualizar_ui():
	# Obtengo el tiempo total jugado (en segundos) directamente del diccionario global
	var tiempo_total = GlobalsEstadisticas.estadisticas_jugador["tiempo_juego"]

	# Convierto ese valor en horas, minutos y segundos
	var horas = int(tiempo_total) / 3600  # Calculo cuántas horas completas hay
	var minutos = (int(tiempo_total) % 3600) / 60  # Calculo los minutos restantes después de quitar las horas
	var segundos = int(tiempo_total) % 60  # Calculo los segundos restantes después de quitar minutos y horas

	# Formateo el resultado en un string tipo 00:00:00 y lo asigno al texto del Label
	timer_label.text = "%02d:%02d:%02d" % [horas, minutos, segundos]

func pausar_cronometro():
	# Esta función permite pausar el cronómetro desde cualquier parte, por ejemplo si el jugador pausa el juego
	GlobalsEstadisticas.pausar_cronometro()

func reanudar_cronometro():
	# Esta función permite reanudar el cronómetro después de una pausa
	GlobalsEstadisticas.reanudar_cronometro()
