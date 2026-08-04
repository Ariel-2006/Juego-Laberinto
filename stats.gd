extends CanvasLayer
# Pantalla de estadísticas (stats.tscn)
#
# Muestra el ranking de todos los jugadores que han jugado, con un gráfico de
# barras del puntaje, y el desglose de puntos del ganador.
#
# Toda la interfaz se construye por código, así que NO hace falta abrir el
# editor de Godot para tocar la escena.

# --- Fórmula de puntaje -------------------------------------------------
# puntaje = enemigos*100 + niveles*500 + vida*50 - segundos
const PUNTOS_POR_ENEMIGO := 100
const PUNTOS_POR_NIVEL := 500
const PUNTOS_POR_VIDA := 50

# --- Colores ------------------------------------------------------------
const COLOR_ORO := Color("ffd24a")
const COLOR_PLATA := Color("cfd6e2")
const COLOR_BRONCE := Color("d68c5a")
const COLOR_RESTO := Color("7f8ba3")
const COLOR_TEXTO := Color("f2f4f8")
const COLOR_TENUE := Color("aeb6c6")
const COLOR_NEGATIVO := Color("e07a6a")


func _ready() -> void:
	# Guarda la partida del jugador actual antes de mostrar el ranking
	GlobalsEstadisticas.guardar_datos_jugador()

	# Oculto los marcos y labels viejos de la escena; ahora dibujo todo yo
	for nombre_nodo in ["Panel", "Panel2", "Panel3", "LabelTop1", "LabelTop2", "LabelTop3"]:
		var nodo = get_node_or_null(nombre_nodo)
		if nodo:
			nodo.visible = false

	construir_pantalla(leer_jugadores())


# ---------------------------------------------------------------- datos --

func leer_jugadores() -> Array:
	var lista := []

	if not FileAccess.file_exists(GlobalsEstadisticas.archivo_jugadores):
		return lista

	var archivo = FileAccess.open(GlobalsEstadisticas.archivo_jugadores, FileAccess.READ)
	if archivo == null:
		return lista
	var contenido = archivo.get_as_text()
	archivo.close()

	var datos = JSON.parse_string(contenido)
	if not (datos is Dictionary):
		return lista   # archivo vacío o dañado

	for nombre in datos.keys():
		var d = datos[nombre]
		if not (d is Dictionary):
			continue

		var enemigos := int(d.get("enemigos_eliminados", 0))
		var niveles := int(d.get("niveles_superados_tot", 0))
		var vida := int(d.get("vida_restante", 0))
		var tiempo := float(d.get("tiempo_juego", 0.0))

		var puntaje := enemigos * PUNTOS_POR_ENEMIGO \
			+ niveles * PUNTOS_POR_NIVEL \
			+ vida * PUNTOS_POR_VIDA \
			- int(tiempo)

		lista.append({
			"nombre": str(d.get("nombre", nombre)),
			"personaje": int(d.get("selected_character", -1)),
			"enemigos": enemigos,
			"niveles": niveles,
			"vida": vida,
			"tiempo": tiempo,
			"puntaje": puntaje,
		})

	lista.sort_custom(func(a, b): return a["puntaje"] > b["puntaje"])
	return lista


# ------------------------------------------------------------ interfaz --

func construir_pantalla(lista: Array) -> void:
	var raiz := MarginContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.add_theme_constant_override("margin_left", 60)
	raiz.add_theme_constant_override("margin_right", 60)
	raiz.add_theme_constant_override("margin_top", 30)
	raiz.add_theme_constant_override("margin_bottom", 90)
	add_child(raiz)

	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 8)
	raiz.add_child(columna)

	columna.add_child(titulo("RANKING DE JUGADORES", 34, COLOR_TEXTO))

	if lista.is_empty():
		columna.add_child(titulo("Todavía no hay partidas guardadas.", 20, COLOR_TENUE))
		columna.add_child(titulo("Juega una partida y vuelve aquí.", 16, COLOR_TENUE))
		return

	# El ganador
	var campeon = lista[0]
	columna.add_child(titulo("Ganador: %s  -  %d puntos" % [campeon["nombre"], campeon["puntaje"]], 22, COLOR_ORO))
	columna.add_child(separador(10))

	# Gráfico de barras del puntaje de cada jugador
	var maximo := maxi(1, int(campeon["puntaje"]))
	for i in range(mini(lista.size(), 8)):
		columna.add_child(fila_barra(
			"%d. %s" % [i + 1, lista[i]["nombre"]],
			lista[i]["puntaje"],
			maximo,
			color_puesto(i),
			str(lista[i]["puntaje"])
		))

	columna.add_child(separador(18))

	# Desglose de los puntos del ganador
	columna.add_child(titulo("De dónde salieron los puntos de " + campeon["nombre"], 18, COLOR_TEXTO))

	var partes := [
		["Enemigos (%d x %d)" % [campeon["enemigos"], PUNTOS_POR_ENEMIGO], campeon["enemigos"] * PUNTOS_POR_ENEMIGO],
		["Niveles (%d x %d)" % [campeon["niveles"], PUNTOS_POR_NIVEL], campeon["niveles"] * PUNTOS_POR_NIVEL],
		["Vida restante (%d x %d)" % [campeon["vida"], PUNTOS_POR_VIDA], campeon["vida"] * PUNTOS_POR_VIDA],
		["Tiempo (%s)" % formatear_tiempo(campeon["tiempo"]), -int(campeon["tiempo"])],
	]

	var mayor_parte := 1
	for p in partes:
		mayor_parte = maxi(mayor_parte, abs(int(p[1])))

	for p in partes:
		var valor := int(p[1])
		var col := COLOR_RESTO if valor >= 0 else COLOR_NEGATIVO
		var etiqueta := ("+%d" % valor) if valor >= 0 else str(valor)
		columna.add_child(fila_barra(str(p[0]), abs(valor), mayor_parte, col, etiqueta))


func fila_barra(texto: String, valor: int, maximo: int, color: Color, etiqueta: String) -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)

	var nombre := Label.new()
	nombre.text = texto
	nombre.custom_minimum_size = Vector2(280, 0)
	nombre.add_theme_font_size_override("font_size", 16)
	nombre.add_theme_color_override("font_color", COLOR_TEXTO)
	nombre.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	nombre.add_theme_constant_override("outline_size", 5)
	nombre.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fila.add_child(nombre)

	# Fondo de la barra (siempre del mismo ancho)
	var fondo := ColorRect.new()
	fondo.color = Color(1, 1, 1, 0.10)
	fondo.custom_minimum_size = Vector2(0, 28)
	fondo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fondo.clip_contents = true
	fila.add_child(fondo)

	# Relleno proporcional al valor
	var fraccion := clampf(float(valor) / float(maxi(maximo, 1)), 0.0, 1.0)
	var relleno := ColorRect.new()
	relleno.color = color
	relleno.anchor_left = 0.0
	relleno.anchor_top = 0.0
	relleno.anchor_right = fraccion
	relleno.anchor_bottom = 1.0
	relleno.offset_left = 0
	relleno.offset_top = 0
	relleno.offset_right = 0
	relleno.offset_bottom = 0
	relleno.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fondo.add_child(relleno)

	var cifra := Label.new()
	cifra.text = etiqueta
	cifra.custom_minimum_size = Vector2(95, 0)
	cifra.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cifra.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cifra.add_theme_font_size_override("font_size", 16)
	cifra.add_theme_color_override("font_color", COLOR_TEXTO)
	cifra.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	cifra.add_theme_constant_override("outline_size", 5)
	fila.add_child(cifra)

	return fila


func titulo(texto: String, tamano: int, color: Color) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	etiqueta.add_theme_constant_override("outline_size", 6)
	return etiqueta


func separador(alto: int) -> Control:
	var espacio := Control.new()
	espacio.custom_minimum_size = Vector2(0, alto)
	return espacio


func color_puesto(i: int) -> Color:
	match i:
		0: return COLOR_ORO
		1: return COLOR_PLATA
		2: return COLOR_BRONCE
		_: return COLOR_RESTO


func formatear_tiempo(segundos: float) -> String:
	var t := int(segundos)
	return "%02d:%02d" % [t / 60, t % 60]


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://start_menu.tscn")
