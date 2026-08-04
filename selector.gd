extends CanvasLayer

# Varía según demos clic al botón izquierda o derecha
var index_selection = 0
var char_portrait


func _ready() -> void:
	if $LabelAviso:
		$LabelAviso.text = ""

	char_portrait = $Sprite2D
	update_portrait(index_selection)


func update_portrait(index):
	char_portrait.texture = GlobalsEstadisticas.characters[index]


func _on_continuar_pressed() -> void:
	var nombre = $LineEdit.text.strip_edges()

	if nombre == "":
		if $LabelAviso:
			$LabelAviso.text = "¡Ingresa un nombre antes de continuar!"
		return

	var g = GlobalsEstadisticas

	# --- Partida nueva: dejo TODO en cero para este jugador ---
	# Antes el cronómetro seguía corriendo del jugador anterior, así que el
	# segundo y el tercero arrancaban con un tiempo enorme en contra.
	g.cronometro_activo = false
	g.tiempo_inicio_global = 0.0
	g.tiempo_pausado_acumulado = 0.0
	g.ultimo_tiempo_pausa = 0.0

	g.estadisticas_jugador["tiempo_juego"] = 0.0
	g.estadisticas_jugador["enemigos_eliminados"] = 0
	g.estadisticas_jugador["niveles_superados_tot"] = 0
	g.estadisticas_jugador["puntaje_niveles_tot"] = 0
	g.estadisticas_jugador["vida_restante"] = 5
	g.estadisticas_jugador["nombre"] = nombre
	g.estadisticas_jugador["selected_character"] = index_selection

	g.player_name = nombre
	g.kills = 0
	g.tiempo_juego = 0.0
	g.selected_character = index_selection

	if $LabelAviso:
		$LabelAviso.text = ""

	get_tree().change_scene_to_file("res://level_1.tscn")


func _on_left_pressed() -> void:
	if index_selection > 0:
		index_selection -= 1
		update_portrait(index_selection)


func _on_rigth_pressed() -> void:
	if index_selection < GlobalsEstadisticas.characters.size() - 1:
		index_selection += 1
		update_portrait(index_selection)
