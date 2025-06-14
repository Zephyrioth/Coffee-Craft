extends Area2D

@export var offset: Vector2 = Vector2(125, 15)

var soltando_cafe := false
var portafiltro: Node2D = null

func _ready():
	var boton = $TextureButton
	boton.pressed.connect(_on_boton_pressed)

func _on_boton_pressed():
	soltando_cafe = !soltando_cafe
	var audio = $AudioStreamPlayer

	if soltando_cafe:
		print("☕ Empezando a soltar café")
		if not audio.playing:
			audio.play()
	else:
		print("🛑 Parando café")
		if audio.playing:
			audio.stop()

func _on_Area2D_body_entered(body: Node2D) -> void:
	if body is RigidBody2D and body.has_method("snap") and body.dragging and not body.is_snapped:
		body.snap(global_position + offset)
		portafiltro = body

func _on_Area2D_body_exited(body: Node2D) -> void:
	if body == portafiltro and body.has_method("unsnap"):
		body.unsnap()
		portafiltro = null

func _physics_process(delta):
	if soltando_cafe and portafiltro and portafiltro.is_snapped:
		# Aquí puedes generar café o incrementar una variable en el portafiltro
		# por ejemplo:
		if portafiltro.has_method("agregar_cafe"):
			portafiltro.agregar_cafe(delta)
