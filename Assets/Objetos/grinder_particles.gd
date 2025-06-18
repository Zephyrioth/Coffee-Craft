extends GPUParticles2D

@export var grind_sound: AudioStreamPlayer2D  # Arrastra el nodo de sonido aquí

func _ready():
	emitting = false  # Desactivar al inicio

func start_grinding():
	emitting = true
	if grind_sound:
		grind_sound.play()

func stop_grinding():
	emitting = false
	if grind_sound:
		grind_sound.stop()
