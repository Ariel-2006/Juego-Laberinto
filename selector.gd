extends CanvasLayer

# Varía según demos clic al botón izquierda o derecha
var index_selection = 0
var char_portrait

func _ready() -> void:
	# Opcional: Limpiar aviso al iniciar
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

	GlobalsEstadisticas.player_name = nombre
	GlobalsEstadisticas.kills = 0
	GlobalsEstadisticas.tiempo_juego = 0.0
	GlobalsEstadisticas.estadisticas_jugador["vida_restante"] = 5
	GlobalsEstadisticas.estadisticas_jugador["nombre"] = nombre
	GlobalsEstadisticas.estadisticas_jugador["selected_character"] = index_selection
	GlobalsEstadisticas.selected_character = index_selection

	if $LabelAviso:
		$LabelAviso.text = ""

	get_tree().change_scene_to_file("res:///level_1.tscn")

func _on_left_pressed() -> void:
	if (index_selection > 0):
		index_selection -= 1
		update_portrait(index_selection)

func _on_rigth_pressed() -> void:
	if (index_selection < GlobalsEstadisticas.characters.size()-1):
		index_selection += 1
		update_portrait(index_selection)
