# global.gd Autoload
extends Node  # Extiendo Node para que este script pueda ser un singleton global

const characters_paths = [
	{
		"Idle": "res://Player_1/Idle/",
		"Run": "res://Player_1/Run/",
		"Ataque": "res://Player_1/Attacking/",
		"Dead": "res://Player_1/Dead/",
		"Idle_bling": "res://Player_1/Idle Blink/"
	},
	{
		"Idle": "res://Player_2/Idle/",
		"Run": "res://Player_2/Casting Spells/",  # corregido
		"Ataque": "res://Player_2/Attacking/",
		"Dead": "res://Player_2/Dead/",
		"Idle_bling": "res://Player_2/Idle_bling/"
	},
	{
		"Idle": "res://Player_3/Idle/",
		"Run": "res://Player_3/Casting Spells/",  # corregido
		"Ataque": "res://Player_3/Attacking/",
		"Dead": "res://Player_3/Dead/",
		"Idle_bling": "res://Player_3/Idle_bling/"
	}
]
	

# Declaro un diccionario llamado estadisticas_jugador para almacenar información clave del jugador
@export var estadisticas_jugador := {
	"nombre": $LineEdit,  # Nombre del jugador por defecto
	"puntaje_niveles_tot": 0,  # Puntaje total acumulado en todos los niveles
	"niveles_superados_tot": 0,  # Total de niveles que el jugador ha superado
	"tiempo_juego": 0.0,  # Tiempo total jugado en segundos
	"intentos_totales": 0,  # Número total de intentos realizados
	"enemigos_eliminados": 0  # Conteo de enemigos eliminados
}

# Variables para controlar el tiempo del cronómetro
var tiempo_inicio_global: float = 0.0  # Marca el inicio del cronómetro en milisegundos
var tiempo_pausado_acumulado: float = 0.0  # Acumula el tiempo que el juego ha estado pausado
var ultimo_tiempo_pausa: float = 0.0  # Guarda el tiempo exacto en que se pausó por última vez
var cronometro_activo: bool = false  # Indica si el cronómetro está activo o pausado

# Variables para stats
var player_name = ""
var kills = 0
var tiempo_juego = 0.0
var vida_restante = 0

# Función para iniciar el cronómetro solo si no está activo
func iniciar_cronometro():
	if not cronometro_activo:
		# Obtengo el tiempo actual en ms y resto el tiempo pausado para continuar contando desde donde quedó
		tiempo_inicio_global = Time.get_ticks_msec() - tiempo_pausado_acumulado
		cronometro_activo = true  # Marco el cronómetro como activo

# Función para pausar el cronómetro solo si está activo
func pausar_cronometro():
	if cronometro_activo:
		# Registro el tiempo en que se pausó para calcular luego la pausa acumulada
		ultimo_tiempo_pausa = Time.get_ticks_msec()
		cronometro_activo = false  # Marco el cronómetro como pausado

# Función para reanudar el cronómetro si está pausado
func reanudar_cronometro():
	if not cronometro_activo:
		# Aumento el tiempo pausado acumulado con el tiempo transcurrido desde la última pausa
		tiempo_pausado_acumulado += Time.get_ticks_msec() - ultimo_tiempo_pausa
		cronometro_activo = true  # Marco el cronómetro como activo otra vez

# Función para obtener el tiempo actual jugado en segundos
func obtener_tiempo_actual() -> float:
	if cronometro_activo:
		# Actualizo el tiempo de juego calculando la diferencia entre el tiempo actual, inicio y pausas
		estadisticas_jugador["tiempo_juego"] = (Time.get_ticks_msec() - tiempo_inicio_global - tiempo_pausado_acumulado) / 1000.0
	return estadisticas_jugador["tiempo_juego"]  # Retorno el tiempo en segundos

# Función para actualizar el puntaje total sumando puntos pasados por parámetro
func actualizar_puntaje_nivel(puntos: int):
	estadisticas_jugador["puntaje_niveles_tot"] += puntos  # Incremento el puntaje total

# Funciones para manejo de puntajes y niveles (complementarias)

# Sumo una cantidad al puntaje total y al puntaje del nivel actual
func sumar_puntaje(cantidad: int):
	estadisticas_jugador["puntaje_total"] += cantidad  # Sumo a puntaje total (¡Ojo! no está en el diccionario inicial, se debería agregar)
	estadisticas_jugador["puntaje_nivel_actual"] += cantidad  # Sumo al puntaje del nivel actual (igual, debe estar definido en diccionario)

# Reinicio el puntaje del nivel actual a cero
func reiniciar_puntaje_nivel():
	estadisticas_jugador["puntaje_nivel_actual"] = 0

# Avanzo el nivel, incremento el nivel actual y niveles completados, y reinicio puntaje de nivel
func avanzar_nivel():
	estadisticas_jugador["nivel_actual"] += 1  # Incremento nivel actual (debe estar definido en diccionario)
	estadisticas_jugador["niveles_completados"] += 1  # Incremento niveles completados (idem)
	reiniciar_puntaje_nivel()  # Reseteo puntaje para el nuevo nivel

# Función para imprimir las estadísticas del jugador en formato JSON y mostrar tiempo en hh:mm:ss
func imprimir_estadisticas_json():
	var stats = estadisticas_jugador.duplicate()  # Duplico el diccionario para no modificar el original
	var tiempo = obtener_tiempo_actual()  # Obtengo el tiempo jugado actual en segundos

	# Calculo horas, minutos y segundos para formatear el tiempo
	var horas = int(tiempo) / 3600
	var minutos = int(tiempo) % 3600 / 60
	var segundos = int(tiempo) % 60
	stats["tiempo_juego"] = "%02d:%02d:%02d" % [horas, minutos, segundos]  # Asigno tiempo formateado a stats

	var json_string = JSON.stringify(stats, "  ")  # Convierto el diccionario a string JSON con indentación
	print("ESTADÍSTICAS ACTUALIZADAS:\n", json_string)  # Imprimo en consola

	guardar_datos_jugador()  # Llamo a la función para guardar los datos en archivo JSON

# Variables para manejo de ruta y archivo en el sistema operativo

var ruta_escritorio := OS.get_environment("USERPROFILE") + "/Desktop"  
# Obtengo la ruta del escritorio del usuario en Windows mediante variable de entorno USERPROFILE

var carpeta_datos := ruta_escritorio + "/datos"  
# Defino la ruta de la carpeta "datos" que estará dentro del escritorio

var archivo_jugadores := carpeta_datos + "/jugadores.json"  
# Defino la ruta final donde guardaré el archivo JSON con datos de jugadores

# Función para guardar datos del jugador en un archivo JSON en la carpeta "datos" del escritorio
func guardar_datos_jugador():
	var nombre_actual = estadisticas_jugador["nombre"]  # Obtengo el nombre del jugador actual
	var jugadores = {}  # Inicializo un diccionario para almacenar los datos de todos los jugadores

	# Compruebo si la carpeta "datos" existe; si no, la creo
	if not DirAccess.dir_exists_absolute(carpeta_datos):
		var dir = DirAccess.open(ruta_escritorio)  # Abro la ruta del escritorio
		if dir:
			dir.make_dir("datos")  # Creo la carpeta "datos"
			print("Carpeta con nombre 'datos' creada en el Escritorio")

	# Si el archivo JSON ya existe, lo abro y leo su contenido
	if FileAccess.file_exists(archivo_jugadores):
		var archivo_lectura = FileAccess.open(archivo_jugadores, FileAccess.READ)  # Abro en modo lectura
		var contenido = archivo_lectura.get_as_text()  # Leo el contenido como texto
		archivo_lectura.close()  # Cierro el archivo

		if contenido.strip_edges() != "":
			# Si el archivo no está vacío, convierto el JSON en diccionario y asigno a jugadores
			jugadores = JSON.parse_string(contenido)

	# Actualizo o agrego la información del jugador actual al diccionario jugadores
	jugadores[nombre_actual] = estadisticas_jugador.duplicate()

	# Abro el archivo en modo escritura para guardar el JSON actualizado
	var archivo_escritura = FileAccess.open(archivo_jugadores, FileAccess.WRITE)
	archivo_escritura.store_string(JSON.stringify(jugadores, "  "))  # Guardo el JSON con indentación
	archivo_escritura.close()  # Cierro el archivo

	print("Datos guardados en:", archivo_jugadores)  # Confirmo en consola que los datos se guardaron

var selected_character = 0
const characters = [
	preload("res://Los diablos mejeje/Wraith_01_Idle_000.png"),
	preload("res://Los diablos mejeje/Wraith_02_Idle_000.png"),
	preload("res://Los diablos mejeje/Wraith_03_Idle_000.png"),
]


const characters_dead = [
	preload("res://Player_1/Dead/Wraith_01_Dying_014.png"),
	preload("res://Player_2/Dead/Wraith_02_Dying_014.png"),
	preload("res://Player_3/Dead/Wraith_03_Dying_014.png"),
]

const characters_stats = [
	preload("res://Los diablos mejeje/Wraith_01_Idle_000.png"),
	preload("res://Los diablos mejeje/Wraith_02_Idle_000.png"),
	preload("res://Los diablos mejeje/Wraith_03_Idle_000.png"),
]
