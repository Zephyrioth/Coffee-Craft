extends Area2D

@export var offset: Vector2 = Vector2(125, 15)

@onready var boton = get_node_or_null("Boton/TextureButton")
@onready var audio = get_node_or_null("Boton/AudioStreamPlayer2D")

@onready var particles =  get_node_or_null("Salida Cafe")
@onready var grind_area = get_node_or_null("Area Enganche")
@onready var grind_button = $Boton/TextureButton
@onready var growth_timer = $GrowthTimer 
var coffee_instance: RigidBody2D = null 

var is_grinding := false
var portafilter_attached := false


var soltando_cafe := false


func _ready():
	growth_timer.timeout.connect(_on_growth_timeout)  # Conecta la señal
	$Boton/TextureButton.pressed.connect(_on_grind_button_pressed)
	# Configurar partículas
	if particles.process_material == null:
		particles.process_material = ParticleProcessMaterial.new()
	
	var mat = particles.process_material
	mat.gravity = Vector3(0, 30, 0)
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 30.0
	mat.set("initial_velocity_min", 15.0)  # Rango de velocidad
	
	particles.amount = 50
	particles.lifetime = 0.8
	particles.emitting = false
	growth_timer.wait_time = 0.1  # Cada 0.1 segundos crece
	growth_timer.one_shot = false  # Que se repita
	

func _on_grind_button_pressed():
	is_grinding = !is_grinding
	
	if is_grinding and portafilter_attached:
		if coffee_instance == null:
			spawn_coffee()
		coffee_instance.start_growing()  # Nueva función
		$GrowthTimer.start()
	else:
		if coffee_instance:
			coffee_instance.stop_growing()
		$GrowthTimer.stop()

func spawn_coffee():
	coffee_instance = preload("res://coffee_granular.tscn").instantiate()
	# Posición relativa al portafiltro si está enganchado
	if portafilter_attached:
		coffee_instance.position = $PortafilterAnchor.global_position  # Nuevo Marker2D
		coffee_instance.gravity_scale = 0  # Sin gravedad
	else:
		coffee_instance.position = $CoffeeSpawnPoint.global_position
		coffee_instance.gravity_scale = 1  # Gravedad normal
	get_parent().add_child(coffee_instance)
	

func _on_AreaEnganche_body_entered(body: Node2D) -> void:
	if body.name == "Portafiltro":
		body.can_snap = true
		body.snap_candidate_position = global_position + offset
		portafilter_attached = true  # ¡Actualiza esta variable!
		print("📥 Portafiltro enganchado | portafilter_attached = true")

func _on_AreaEnganche_body_exited(body: Node2D) -> void:
	if body.name == "Portafiltro":
		body.can_snap = false
		portafilter_attached = false  # ¡Actualiza esta variable!
		print("📤 Portafiltro desenganchado | portafilter_attached = false")

func _on_growth_timeout():
	if is_grinding and coffee_instance and is_instance_valid(coffee_instance):
		coffee_instance.grow_coffee()


	
