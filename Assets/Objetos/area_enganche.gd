extends Area2D

@export var offset: Vector2 = Vector2(125, 15)

@onready var grind_button = $Boton/TextureButton
@onready var audio = $Boton/AudioStreamPlayer2D
@onready var particles = $"Salida Cafe"
@onready var coffee_spawn = $CoffeeSpawnPoint
@onready var portafilter_anchor = $PortafilterAnchor

var coffee_instance: Node2D = null
var is_grinding := false
var portafilter_attached := false

func _ready():
	grind_button.pressed.connect(_on_grind_button_pressed)


func _on_grind_button_pressed():
	is_grinding = !is_grinding
	particles.emitting = is_grinding

	if is_grinding and portafilter_attached:
		print("grinding")
		audio.play()
		await get_tree().create_timer(1.0).timeout  # Espera 0.3 segundos
		if coffee_instance == null:
			spawn_coffee()
			print("1")
		
		coffee_instance.start_filling()
	else:
		print("stop filling")
		if coffee_instance:
			print("2")
			coffee_instance.stop_filling()
		audio.stop()

func spawn_coffee():
	coffee_instance = preload("res://coffee_fill.tscn").instantiate()
	var marker = $CoffeeSpawnPoint  # o $CoffeeFillOrigin si creas uno nuevo
	coffee_instance.global_position = marker.global_position
	
	var portafiltro = get_node_or_null("/root/Node2D/Portafiltro")  # Ajusta ruta si es distinta
	if portafiltro:
		portafiltro.add_child(coffee_instance)
		coffee_instance.position = portafiltro.to_local(marker.global_position)

func _on_AreaEnganche_body_entered(body: Node2D) -> void:
	if body.name == "Portafiltro":
		body.can_snap = true
		body.snap_candidate_position = global_position + offset
		portafilter_attached = true
		print("📥 Portafiltro enganchado | portafilter_attached = true")

func _on_AreaEnganche_body_exited(body: Node2D) -> void:
	if body.name == "Portafiltro":
		body.can_snap = false
		portafilter_attached = false
		print("📤 Portafiltro desenganchado | portafilter_attached = false")
