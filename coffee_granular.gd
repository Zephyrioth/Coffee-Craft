extends RigidBody2D

@export var growth_rate: float = 0.02
@export var peak_sharpness: float = 2.5
@export var size_scale: float = 5.0
@export var growth_curve: Curve

@onready var sprite := $Sprite2D
@onready var shader := sprite.material as ShaderMaterial

var is_growing: bool = false
var is_grabbed: bool = false
var current_surface: String = ""

func _ready():
	# Configuración inicial del shader
	shader.set_shader_parameter("fill", 0.0)
	shader.set_shader_parameter("flatten", 0.0)
	shader.set_shader_parameter("mode", 1)
	shader.set_shader_parameter("peak_sharpness", peak_sharpness)
	shader.set_shader_parameter("size_scale", size_scale)
	
	# Escala visual
	sprite.scale = Vector2.ONE * 3.0  # Escala base adicional
	
	# Configurar curva de crecimiento por defecto
	if growth_curve == null:
		growth_curve = Curve.new()
		growth_curve.add_point(Vector2(0.0, 0.1))
		growth_curve.add_point(Vector2(0.4, 0.6))
		growth_curve.add_point(Vector2(0.8, 0.9))
		growth_curve.add_point(Vector2(1.0, 1.0))
	
	# Física
	set_deferred("gravity_scale", 0 if is_in_group("inside_portafilter") else 1)
	update_collision_shape(0.1)

func grow_coffee():
	if not is_growing:
		return
	
	# Crecimiento controlado por curva
	var current_fill = shader.get_shader_parameter("fill")
	var normalized_fill = current_fill / 1.5
	var growth_factor = growth_curve.sample_baked(normalized_fill)
	
	var growth = growth_rate * growth_factor * (1.0 + normalized_fill * 0.3)
	var next_fill = clamp(current_fill + growth, 0.0, 1.8)
	
	shader.set_shader_parameter("fill", next_fill)
	update_collision_shape(next_fill)
	
	# Aplanamiento controlado
	if next_fill > 1.0:
		var overfill = (next_fill - 1.0) / 0.8
		shader.set_shader_parameter("flatten", min(overfill, 1.0))

func update_collision_shape(fill_amount: float):
	var target_radius = 25.0 * fill_amount  # Colisión grande
	if $CollisionShape2D.shape is CircleShape2D:
		$CollisionShape2D.shape.radius = target_radius

func start_growing():
	is_growing = true
	shader.set_shader_parameter("fill", 0.0)
	shader.set_shader_parameter("flatten", 0.0)
	update_collision_shape(0.1)

func stop_growing():
	is_growing = false

func apply_visual_form():
	match current_surface:
		"portafilter":
			shader.set_shader_parameter("mode", 1)
		"table":
			shader.set_shader_parameter("mode", 0)

func _on_surface_detected(body: Node):
	current_surface = "portafilter"
	apply_visual_form()

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		is_grabbed = event.pressed
		call_deferred("_update_shape")

func _update_shape():
	call_deferred("_update_collision", is_grabbed)

func _update_collision(is_grabbed_state: bool):
	# Efecto visual de debug (opcional)
	shader.set_shader_parameter("debug_color", Color(1, 0, 0)) # rojo
	await get_tree().create_timer(0.5).timeout
	shader.set_shader_parameter("debug_color", Color(0, 1, 0)) # verde
	await get_tree().create_timer(0.5).timeout
	shader.set_shader_parameter("debug_color", Color(0, 0, 1)) # azul
	
	# Actualizar forma de colisión
	var circle_shape = CircleShape2D.new()
	var fill_val: float = shader.get_shader_parameter("fill")    
	circle_shape.radius = 8.0 * fill_val
	$CollisionShape2D.shape = circle_shape
	
	print("fill:", fill_val, " | flatten:", shader.get_shader_parameter("flatten"))

func freeze_inside_portafilter():
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	freeze = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0

func unfreeze():
	freeze = false
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
