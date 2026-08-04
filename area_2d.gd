extends Area2D
# Punto de meta de cada nivel. Cuando el jugador lo toca:
#   1. cuenta el nivel como superado
#   2. guarda la vida con la que terminó y el tiempo
#   3. graba la partida en el archivo de estadísticas
#   4. carga el siguiente nivel

@export var new_scene_path: String  # Se asigna en el editor: ruta del siguiente nivel


func _on_body_entered(body: Node2D):
	if body.name != "Player":
		return

	var g = GlobalsEstadisticas

	g.estadisticas_jugador["niveles_superados_tot"] += 1

	# Guardo la vida con la que el jugador terminó el nivel (sirve para el puntaje)
	if body is Player:
		g.estadisticas_jugador["vida_restante"] = body.salud

	g.obtener_tiempo_actual()      # refresca "tiempo_juego"
	g.guardar_datos_jugador()      # graba la partida en user://jugadores.json

	print("Nivel superado. Niveles: ", g.estadisticas_jugador["niveles_superados_tot"],
		" | Enemigos: ", g.estadisticas_jugador["enemigos_eliminados"],
		" | Vida: ", g.estadisticas_jugador["vida_restante"])

	change_scene()


func change_scene():
	if new_scene_path == "":
		printerr("Este Punto_nivel no tiene asignada la escena siguiente.")
		return
	get_tree().change_scene_to_file(new_scene_path)
