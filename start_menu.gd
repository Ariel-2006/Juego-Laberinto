extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# En el navegador no se puede cerrar la pestaña, así que escondo "Salir"
	if OS.has_feature("web"):
		$salir.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass#


func _on_salir_pressed() -> void:
	if OS.has_feature("web"):
		return  # en web quit() no hace nada y deja el juego congelado
	get_tree().quit()


func _on_stats_pressed() -> void:
	get_tree().change_scene_to_file("res://stats.tscn")


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://selector.tscn")
