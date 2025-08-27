extends RigidBody2D

const RIGID := 0
const KINEMATIC := 2

const MAX_RELEASE_SPEED := 800.0
const SLIDE_SPEED := 5.0
const ROTATION_SMOOTH_SPEED := 24.0

const SNAP_FORCE_THRESHOLD := 100.0
const UNSNAP_UPWARD_THRESHOLD := 100.0

var dragging := false
var calculated_velocity := Vector2.ZERO
var grab_offset := Vector2.ZERO
var previous_position := Vector2.ZERO

const gravity = 1200

const SLIDE_FRICTION := 0.85
const WALL_DETECTION_OFFSET := 20.0

@onready var area_pickable := $MouseArea
@onready var audio = get_node_or_null("AudioStreamPlayer2D")
@onready var collision_area := $PressArea 


func _ready():
	print("✅ Tamper listo")
	if collision_area:
		collision_area.body_entered.connect(_on_TamperCollision_body_entered)
		print("🔗 Señal body_entered conectada")
	else:
		print("⚠️ TamperCollision no encontrado")

func _physics_process(delta):
	
	# 2. Lógica de arrastre
	if Input.is_action_pressed("left_click"):
		if not dragging and _is_mouse_over() and not GrabManager.is_dragging():
			# Iniciar arrastre
			dragging = true
			GrabManager.current_dragged_object = self
			set("mode", KINEMATIC)
			sleeping = true
			grab_offset = get_global_mouse_position() - global_position
			previous_position = global_position
			calculated_velocity = Vector2.ZERO
			linear_velocity = Vector2.ZERO
			angular_velocity = 0.0
			gravity_scale = 0.0
		
		if dragging:
			var mouse_pos = get_global_mouse_position()
			var target_pos = mouse_pos - grab_offset
			
			# Detección de colisiones
			var space_state = get_world_2d().direct_space_state
			var ray_params = PhysicsRayQueryParameters2D.create(
				global_position, 
				target_pos,
				collision_mask,
				[self]
			)
			
			var collision = space_state.intersect_ray(ray_params)
			
			if collision:
				# Movimiento con colisión
				var collision_normal = collision.normal
				var slide_vector = (target_pos - global_position).slide(collision_normal)
				var limited_target = global_position + slide_vector * SLIDE_FRICTION
				
				if global_position.distance_to(collision.position) > WALL_DETECTION_OFFSET:
					global_position = global_position.lerp(limited_target, SLIDE_SPEED * delta)
			else:
				# Movimiento libre
				global_position = target_pos
			
			calculated_velocity = (global_position - previous_position) / delta
			previous_position = global_position
			rotation = lerp_angle(rotation, 0.0, ROTATION_SMOOTH_SPEED * delta)
	
	# 3. Al soltar el objeto
	elif Input.is_action_just_released("left_click") and dragging:
		dragging = false
		GrabManager.current_dragged_object = null
		set("mode", RIGID)
		sleeping = false
		# Reactivar gravedad
		gravity_scale = 2.0
		

		# Aplicar velocidad limitada
		if calculated_velocity.length() > MAX_RELEASE_SPEED:
			calculated_velocity = calculated_velocity.normalized() * MAX_RELEASE_SPEED
		
		linear_velocity = calculated_velocity * 1.2
		angular_velocity = calculated_velocity.x * 0.005
		linear_velocity.y += gravity * delta


func _is_mouse_over() -> bool:
	var mouse_pos = get_global_mouse_position()
	var query := PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.exclude = []
	var result = get_world_2d().direct_space_state.intersect_point(query)
	
	for item in result:
		if item["collider"] == area_pickable:
			return true
	return false

func _on_TamperCollision_body_entered(body):
	if body.is_in_group("coffee") and calculated_velocity.y > 300:
		body.apply_press(calculated_velocity, rotation)
	
