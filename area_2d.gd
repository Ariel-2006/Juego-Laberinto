extends Area2D 

@export var new_scene_path: String  # Exporto una variable tipo string para poder asignar en el editor la ruta de la nueva escena a cargar

func _process(delta):
	pass  # No necesito usar _process en este caso, pero lo dejo definido por si más adelante quiero añadir lógica por frame

func _on_body_entered(body: Node2D):
	print("Algo entró:", body.name)  # Confirmar quién entra al área

	if body.name == "Player":
		print("¡Jugador entró en el Punto_nivel!")
		print("Escena destino:", new_scene_path)

		GlobalsEstadisticas.actualizar_puntaje_nivel(10)
		GlobalsEstadisticas.estadisticas_jugador["niveles_superados_tot"] += 1

		GlobalsEstadisticas.imprimir_estadisticas_json()

		change_scene()

func change_scene():
	# Esta función cambia la escena actual a la que está indicada en la variable `new_scene_path`
	get_tree().change_scene_to_file(new_scene_path)
