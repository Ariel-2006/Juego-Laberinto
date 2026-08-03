extends CanvasLayer

@onready var sprite_dead = $SpriteDead

func _ready():
	# Mostrar sprite muerto según el personaje seleccionado
	var selected_index = GlobalsEstadisticas.selected_character
	sprite_dead.texture = GlobalsEstadisticas.characters_dead[selected_index]

func _on_stat_s_pressed() -> void:
	get_tree().change_scene_to_file("res://stats.tscn")

func _on_bac_k_pressed() -> void:
	get_tree().quit()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://start_menu.tscn")
