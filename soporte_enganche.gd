extends Area2D

@export var offset: Vector2 = Vector2(70, 0)

@onready var boton = get_node_or_null("../Boton/TextureButton")
@onready var audio = get_node_or_null("../Boton/AudioStreamPlayer2D")

var soltando_cafe := false

func _on_AreaEnganche_body_entered(body: Node2D) -> void:
	if body.name == "Portafiltro":
		body.can_snap = true
		body.snap_candidate_position = global_position + offset
		print("📥 Portafiltro dentro del área de enganche")

func _on_AreaEnganche_body_exited(body: Node2D) -> void:
	if body.name == "Portafiltro":
		body.can_snap = false
		print("📤 Portafiltro salió del área de enganche")
