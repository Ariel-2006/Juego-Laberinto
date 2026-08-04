extends CanvasLayer

@onready var sprite_dead = $SpriteDead


func _ready():
	var g = GlobalsEstadisticas

	# Mostrar sprite muerto según el personaje seleccionado
	var selected_index = g.selected_character
	if selected_index >= 0 and selected_index < g.characters_dead.size():
		sprite_dead.texture = g.characters_dead[selected_index]

	# El jugador murió: cierro su partida y la guardo
	g.obtener_tiempo_actual()
	g.pausar_cronometro()
	g.estadisticas_jugador["vida_restante"] = 0
	g.guardar_datos_jugador()

	# En el navegador no se puede cerrar la pestaña, escondo el botón
	if OS.has_feature("web"):
		var salir = get_node_or_null("bac_k")
		if salir:
			salir.visible = false


func _on_stat_s_pressed() -> void:
	get_tree().change_scene_to_file("res://stats.tscn")


func _on_bac_k_pressed() -> void:
	if OS.has_feature("web"):
		return  # en web quit() no hace nada y deja el juego congelado
	get_tree().quit()


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://start_menu.tscn")
