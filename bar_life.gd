extends TextureProgressBar

func _ready():
	self.max_value = 5 #Vida maxima
	self.value = 5 #Valor de la vida por defecto
	
	if not texture_progress or not texture_under: #Verifico si hay texturas asignadas
		print("No hay texturas cargadas ERR...")
