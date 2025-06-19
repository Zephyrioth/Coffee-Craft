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

var is_snapped := false
var snap_position := Vector2.ZERO
var pending_unsnap := false
const gravity = 980

var snap_candidate_position: Vector2 = Vector2.ZERO
var can_snap: bool = false

const SLIDE_FRICTION := 0.85
const WALL_DETECTION_OFFSET := 20.0

@onready var area_pickable := $MouseArea
@onready var audio = get_node_or_null("AudioStreamPlayer2D")

func _physics_process(delta):
	# 1. Manejo del estado enganchado
	if is_snapped:
		if pending_unsnap and Input.is_action_pressed("left_click") and _is_mouse_over():
			unsnap()
			dragging = true
			grab_offset = get_global_mouse_position() - global_position
			previous_position = global_position
			pending_unsnap = false
			return
			
		global_position = snap_position
		rotation = 0.0
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0
		return
	
	# 2. Lógica de arrastre
	if Input.is_action_pressed("left_click"):
		if not dragging and _is_mouse_over():
			# Iniciar arrastre
			dragging = true
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
		set("mode", RIGID)
		sleeping = false
		# Reactivar gravedad
		gravity_scale = 1.0
		
		# ELIMINADO: calculated_velocity.y = 0  // Esto quitaba el movimiento vertical
		
		# Aplicar velocidad limitada
		if calculated_velocity.length() > MAX_RELEASE_SPEED:
			calculated_velocity = calculated_velocity.normalized() * MAX_RELEASE_SPEED
		
		linear_velocity = calculated_velocity * 1.2
		angular_velocity = calculated_velocity.x * 0.005
		
		# Auto-enganche
		if can_snap:
			snap(snap_candidate_position)
			can_snap = false
	
	# 4. Gravedad
	if not dragging and not is_snapped:
		linear_velocity.y += gravity * delta

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_snapped:
			pending_unsnap = _is_mouse_over()

func snap(target_position: Vector2):
	freeze = true
	sleeping = true
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "global_position", target_position, 0.15)
	tween.tween_property(self, "rotation", 0.0, 0.1)
	
	tween.tween_callback(func():
		is_snapped = true
		snap_position = target_position
		set("mode", KINEMATIC)
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0
	)
	
	if audio:
		audio.play()

func unsnap():
	is_snapped = false
	set("mode", RIGID)
	freeze = false
	sleeping = false
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
	
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	
	apply_central_impulse(Vector2(0, 10))
	
	grab_offset = get_global_mouse_position() - global_position
	previous_position = global_position
	
	PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_SLEEPING, false)

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
	
func _on_CoffeeDetectionArea_body_entered(body: Node2D) -> void:
	print("Entra")
	if body.name == "CoffeeGranular" or body.is_in_group("coffee"):
		body.current_surface = "portafilter"
		body.call_deferred("freeze_inside_portafilter")
		body.linear_velocity = Vector2.ZERO
		body.call_deferred("_update_collision", false)
		body.call_deferred("apply_visual_form")
		print("☕ Café ha entrado al portafiltro visualmente")
