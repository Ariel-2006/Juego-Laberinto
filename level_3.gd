extends Node2D

@export var new_scene_path: String  # La ruta del siguiente nivel se asigna desde el inspector.

# Nota: aquí había una función change_scene() que nadie llamaba y que además
# usaba GlobalsEstadisticas.tiempo_acumulado, una variable que NO existe en el
# autoload: si alguien la hubiera llamado, el juego se caía. El cambio de nivel
# lo hace el Area2D "Punto_nivel" con area_2d.gd.
