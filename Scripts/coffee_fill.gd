extends Node2D

@onready var sprite := $AnimatedSprite2D
@onready var timer := $FillTimer
@onready var particles := $GPUParticles2D

var current_frame := 0
var is_filling := false

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
	else:
		timer.stop()
		is_filling = false
		particles.emitting = false
