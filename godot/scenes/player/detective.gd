extends CharacterBody2D

## Player-controlled detective. WASD to move (polled directly, so no UI element can swallow
## the input the way it did with click-to-move); E to interact. Camera follows.

const SPEED := 200.0

@onready var _camera: Camera2D = $Camera2D
@onready var _interactor: Interactor = $Interactor
@onready var _sprite: AnimatedSprite2D = $Sprite

var control_enabled := true


func _physics_process(_delta: float) -> void:
	if not control_enabled:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	# Reuse the WASD actions (camera_pan_* = W/A/S/D). The observer camera only pans in
	# OBSERVER mode, and the detective only reads these in PLAY mode, so there's no conflict.
	var dir := Vector2.ZERO
	if Input.is_action_pressed("camera_pan_up"):
		dir.y -= 1.0
	if Input.is_action_pressed("camera_pan_down"):
		dir.y += 1.0
	if Input.is_action_pressed("camera_pan_left"):
		dir.x -= 1.0
	if Input.is_action_pressed("camera_pan_right"):
		dir.x += 1.0
	velocity = dir.normalized() * SPEED
	move_and_slide()
	_update_facing(dir)

	if Input.is_action_just_pressed("interact"):
		_interactor.try_examine()
	if Input.is_action_just_pressed("talk"):
		_interactor.try_talk()


func _update_facing(dir: Vector2) -> void:
	if not _sprite.sprite_frames:
		return
	var anim: String
	if dir == Vector2.ZERO:
		anim = "idle_down"
	elif absf(dir.x) > absf(dir.y):
		anim = "walk_right" if dir.x > 0.0 else "walk_left"
	else:
		anim = "walk_down" if dir.y > 0.0 else "walk_up"
	if _sprite.animation != anim:
		_sprite.play(anim)


func set_control_enabled(enabled: bool) -> void:
	control_enabled = enabled
	_camera.enabled = enabled
	if enabled:
		# Make this the active camera so it follows the detective.
		_camera.make_current()
