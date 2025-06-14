extends RigidBody2D

const SPEED:int = 50
const RIGID := 0
const STATIC := 1
const KINEMATIC := 2

const MAX_RELEASE_SPEED := 800.0
const SLIDE_SPEED := 5.0
const ROTATION_SMOOTH_SPEED := 14.0

const SNAP_FORCE_THRESHOLD := 100.0
const UNSNAP_UPWARD_THRESHOLD := 100.0


var dragging:bool = false
var has_mouse:bool = false

var previous_position:Vector2
var calculated_velocity:Vector2 = Vector2.ZERO
var grab_offset:Vector2 = Vector2.ZERO

# Variables para enganche
var is_snapped: bool = false
var snap_position: Vector2 = Vector2.ZERO
var pending_unsnap := false

func _on_area_2d_mouse_entered():
	has_mouse = true
	print("✅ _on_area_2d_mouse_entered")

func _on_area_2d_mouse_exited():
	if not dragging:
		has_mouse = false
		print("✅ _on_area_2d_mouse_exited")

func _physics_process(delta):

	# 🔒 Mantener posición fija si está enganchado y no se está intentando arrastrar
	if is_snapped and not Input.is_action_pressed("left_click"):
		var move_vector := global_position - snap_position

		#TODO quitar y sustituir por posicion fija
		if move_vector.length() < SNAP_FORCE_THRESHOLD and move_vector.y < UNSNAP_UPWARD_THRESHOLD:
			global_position = snap_position
			rotation = 0.0
			linear_velocity = Vector2.ZERO
			angular_velocity = 0.0
			sleeping = true
			return

	# 🖱 Arrastrar
	if Input.is_action_pressed("left_click") and has_mouse:
		print("Pressed")
		if not dragging:
			if pending_unsnap:
				unsnap()
				pending_unsnap = false
			else:
				var mouse_pos = get_global_mouse_position()
				grab_offset = mouse_pos - global_position

			dragging = true
			set("mode", KINEMATIC)
			sleeping = true
			previous_position = global_position
		
		# ⛔ Cancelar acumulación de velocidad física
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0

		var mouse_pos = get_global_mouse_position()
		var target_pos = mouse_pos - grab_offset
		var offset = (target_pos - previous_position) / delta
		calculated_velocity = offset

		var space_state = get_world_2d().direct_space_state
		var ray_params := PhysicsRayQueryParameters2D.create(global_position, target_pos)
		ray_params.exclude = [self]
		var collision = space_state.intersect_ray(ray_params)

		if collision.is_empty():
			global_position = target_pos
		else:
			var limited_target := Vector2(target_pos.x, global_position.y)
			global_position = global_position.lerp(limited_target, SLIDE_SPEED * delta)

		previous_position = global_position
		rotation = lerp_angle(rotation, 0.0, ROTATION_SMOOTH_SPEED * delta)

	elif Input.is_action_just_released("left_click") and dragging:
		dragging = false
		set("mode", RIGID)
		sleeping = false

		if calculated_velocity.length() > MAX_RELEASE_SPEED:
			calculated_velocity = calculated_velocity.normalized() * MAX_RELEASE_SPEED

		linear_velocity = calculated_velocity

func _ready():
	print("✅ Portafiltro cargado correctamente")

func snap(target_position: Vector2) -> void:

	if not dragging:
		print("🙅‍♂️ No se está arrastrando, no se engancha")
		return

	is_snapped = true
	snap_position = target_position
	set("mode", KINEMATIC)
	sleeping = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	print("🔒 Snapping")

func unsnap():
	is_snapped = false
	set("mode", RIGID)
	sleeping = false

	# 🛠️ Registrar el nuevo offset al desenganchar para que el arrastre sea natural
	grab_offset = get_global_mouse_position() - global_position
	previous_position = global_position

	print("✅ Unsnapping")

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and has_mouse:
		if is_snapped:
			grab_offset = get_global_mouse_position() - global_position
			pending_unsnap = true
