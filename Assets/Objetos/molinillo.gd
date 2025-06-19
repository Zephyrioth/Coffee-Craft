extends Node2D

@onready var particles =  get_node_or_null("Salida Cafe")
@onready var grind_sound = get_node_or_null("SonidoGrind")
@onready var grind_area = get_node_or_null("Area Enganche")
@onready var grind_button = $Boton/TextureButton

var is_grinding := false
var portafilter_attached := false

func _ready():
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


func spawn_coffee():
	var coffee = preload("res://coffee_granular.tscn").instantiate()
	coffee.position = $CoffeeSpawnPoint.global_position
	coffee.apply_central_impulse(Vector2(0, 50))
	get_parent().add_child(coffee)  # Añade al nivel, no al molinillo
