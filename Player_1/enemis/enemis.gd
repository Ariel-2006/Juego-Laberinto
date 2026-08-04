class_name Enemy
extends EnemigoBase
# Enemigo tipo 1. Toda la lógica está en enemigo_base.gd; aquí solo declaro
# qué animaciones y qué color usa este enemigo.

func tabla_de_tipos() -> Dictionary:
	return {
		"default": {
			"start_facing_right": false,
			"walk_animation": "enemi_animation",
			"attack_animation": "atack_enemi",
			"dead_animation": "dead_animation",
			"modulate_color": Color(1, 1, 1),
		},
	}
