extends Node2D

@export var new_scene_path: String  # exportamos esa escena o niivel como un path para el cambio entre niveles desde el inspector

func change_scene():
	#Guardar el tiempo acumulado antes de cambiar de escena o nivel
	GlobalsEstadisticas.tiempo_acumulado = GlobalsEstadisticas.estadisticas_jugador["tiempo_juego"]
	get_tree().change_scene_to_file("res://stats.tscn")
