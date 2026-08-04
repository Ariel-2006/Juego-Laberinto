class_name Enemy2
extends EnemigoBase
# Enemigo tipo 2. La lógica está en enemigo_base.gd.

func tabla_de_tipos() -> Dictionary:
	return {
		"type2": {
			"start_facing_right": false,
			"walk_animation": "enemi_animation2",
			"attack_animation": "atack_enemi2",
			"dead_animation": "dead_enemi2",
			"modulate_color": Color(0.8, 0.5, 1.0),
		},
	}
