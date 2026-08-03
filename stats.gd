extends CanvasLayer
# Esta escena es el menú de estadísticas de jugadores (stats.tscn)

# Referencias a los Labels donde se mostrará el top 3 de jugadores
@onready var label_top1 = $LabelTop1
@onready var label_top2 = $LabelTop2
@onready var label_top3 = $LabelTop3

# Referencias a los Sprite2D donde se mostrará la textura del personaje de cada jugador del top 3
@onready var sprite_top1 = $LabelTop1/Sprite2D
@onready var sprite_top2 = $LabelTop2/Sprite2D
@onready var sprite_top3 = $LabelTop3/Sprite2D

func _ready():
	# Se llama al iniciar la escena
	# Guarda los datos del jugador actual antes de mostrar el top
	GlobalsEstadisticas.guardar_datos_jugador()
	mostrar_top_3()

func mostrar_top_3():
	# Verifica si existe el archivo de estadísticas
	if not FileAccess.file_exists(GlobalsEstadisticas.archivo_jugadores):
		label_top1.text = "No hay estadísticas guardadas."
		label_top2.text = ""
		label_top3.text = ""
		return

	# Abre el archivo de estadísticas para leer
	var archivo = FileAccess.open(GlobalsEstadisticas.archivo_jugadores, FileAccess.READ)
	var contenido = archivo.get_as_text()
	archivo.close()

	# Si el archivo está vacío, avisa al jugador
	if contenido.strip_edges() == "":
		label_top1.text = "El archivo de estadísticas está vacío."
		label_top2.text = ""
		label_top3.text = ""
		return

	# Convierte el texto del archivo en un diccionario usando JSON.parse_string
	var jugadores = JSON.parse_string(contenido)
	var lista = [] # Lista de jugadores para ordenar

	# Procesa cada jugador guardado en el archivo
	for nombre in jugadores.keys():
		var datos = jugadores[nombre]
		datos["nombre"] = datos.get("nombre", nombre) # Usa el nombre del jugador, o el key si no existe
		datos["selected_character"] = int(datos.get("selected_character", -1)) # Índice del personaje usado
		lista.append(datos)

	# Ordena la lista por mayor cantidad de enemigos eliminados
	lista.sort_custom(func(a, b): return a["enemigos_eliminados"] > b["enemigos_eliminados"])

	# Lista de labels y sprites en orden para mostrar el top 3
	var labels = [label_top1, label_top2, label_top3]
	var sprites = [sprite_top1, sprite_top2, sprite_top3]

	# Para cada jugador en el top 3 (o menos si hay menos de 3)
	for i in range(min(lista.size(), 3)):
		var jugador = lista[i]
		# Actualiza el label con las estadísticas del jugador
		labels[i].text = "%d) %s\nKills: %d\nTiempo: %.2f s\nPuntaje: %d" % [
			i + 1,
			jugador["nombre"],
			jugador["enemigos_eliminados"],
			jugador["tiempo_juego"],
			jugador.get("puntaje_niveles_tot", 0)
		]

		# Obtiene el índice del personaje seleccionado
		var personaje_index = int(jugador.get("selected_character", -1))
		if personaje_index >= 0 and personaje_index < GlobalsEstadisticas.characters_dead.size():
			# Si es válido, asigna la textura correspondiente del array characters_stats
			sprites[i].texture = GlobalsEstadisticas.characters_stats[personaje_index]
			sprites[i].visible = true # Lo hace visible
		else:
			sprites[i].visible = false # Oculta el sprite si no hay textura

	# Si hay menos de 3 jugadores, oculta los sprites sobrantes
	for j in range(lista.size(), 3):
		sprites[j].visible = false

func _on_back_pressed():
	# Vuelve al menú principal al presionar el botón "Atrás"
	get_tree().change_scene_to_file("res://start_menu.tscn")
