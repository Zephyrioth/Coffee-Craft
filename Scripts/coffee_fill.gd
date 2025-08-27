extends Node2D

@onready var sprite := $AnimatedSprite2D
@onready var timer := $FillTimer
@onready var particles := $GPUParticles2D

var current_frame := 0
var is_filling := false
var coffee_amount := 0.0  # 0.0 a 1.0 (normalizado)

var squash := 0.0  # De 0.0 (sin presionar) a 1.0 (máximo comprimido)
var max_squash := 1.0  # Cambiará según la cantidad de café

func apply_press(velocity: Vector2, angle: float):
	var force = clamp(velocity.y / 1000.0, 0.0, 1.0)
	max_squash = coffee_amount  # Solo puede comprimirse hasta el café acumulado
	squash = min(squash + force * 0.2, max_squash)
	_update_sprite_scale(force, angle)

func _update_sprite_scale(force: float, angle: float):
	var base_scale = Vector2(1, 1)
	var squash_factor = lerp(1.0, 0.6, squash)  # Aplasta hacia abajo

	# Para squash inclinado (ej: tamper golpeando en ángulo)
	var incline = clamp(angle / PI, -1.0, 1.0)  # Normalizado
	sprite.scale = Vector2(1.0 + incline * 0.2, squash_factor)

func _ready():
	sprite.play("Fill")
	sprite.frame = 0
	sprite.pause()
	timer.wait_time = 0.1
	timer.timeout.connect(_on_fill_step)
	particles.emitting = false

func start_filling():
	if not is_filling:
		is_filling = true
		timer.start()
		particles.emitting = true

func stop_filling():
	is_filling = false
	timer.stop()
	particles.emitting = false

func _on_fill_step():
	var max_frames = sprite.sprite_frames.get_frame_count("Fill")
	if current_frame < max_frames - 1:
		current_frame += 1
		sprite.frame = current_frame
		coffee_amount = float(current_frame) / float(max_frames - 1)
	else:
		timer.stop()
		is_filling = false
		particles.emitting = false
