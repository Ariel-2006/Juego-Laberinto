class_name Enemy3
extends EnemigoBase
# Enemigo tipo 3. La lógica está en enemigo_base.gd.

func tabla_de_tipos() -> Dictionary:
	return {
		"type3": {
			"start_facing_right": false,
			"walk_animation": "enemi_animation3",
			"attack_animation": "atack_enemi3",
			"dead_animation": "dead_enemi3",
			"modulate_color": Color(0.8, 0.5, 1.0),
		},
	}
