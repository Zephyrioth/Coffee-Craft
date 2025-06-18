extends Area2D

@export var offset: Vector2 = Vector2(125, 15)

@onready var boton = get_node_or_null("../Boton/TextureButton")
@onready var audio = get_node_or_null("../Boton/AudioStreamPlayer2D")

var soltando_cafe := false

func _ready():
	if boton:
		boton.pressed.connect(_on_boton_pressed)

func _on_boton_pressed():
	soltando_cafe = !soltando_cafe

	if audio:
		if soltando_cafe:
			print("☕ Empezando a soltar café")
			audio.play()
		else:
			print("🛑 Parando café")
			audio.stop()

func _on_AreaEnganche_body_entered(body: Node2D) -> void:
	if body.name == "Portafiltro":
		body.can_snap = true
		body.snap_candidate_position = global_position + offset
		print("📥 Portafiltro dentro del área de enganche")

func _on_AreaEnganche_body_exited(body: Node2D) -> void:
	if body.name == "Portafiltro":
		body.can_snap = false
		print("📤 Portafiltro salió del área de enganche")
