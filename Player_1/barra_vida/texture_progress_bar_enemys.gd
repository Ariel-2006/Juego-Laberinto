extends TextureProgressBar
func _ready():
	# Configuración básica (sin colores, pues ya los tienes en el inspector)
	self.max_value = 3
	self.value = 3
	
	# Opcional: Verificar que las texturas están asignadas
	if not texture_progress or not texture_under:
		print("Advertencia: Asigna texturas en el inspector para mejor visualización")
