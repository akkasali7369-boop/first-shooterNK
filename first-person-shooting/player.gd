extends CharacterBody3D

const SPEED = 6.0
const JUMP_VELOCITY = 6.0
const MOUSE_SENSITIVITY = 0.003
const TOUCH_SENSITIVITY = 0.006
const MAGAZINE_SIZE = 8
const DAMAGE = 25
const MAX_HEALTH = 100
const FOOTSTEP_INTERVAL = 0.4

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * 2.0
var bullet_hole_scene = preload("res://bullet_hole.tscn")

var health = MAX_HEALTH
var ammo_in_mag = MAGAZINE_SIZE
var reserve_ammo = 32
var score = 0
var is_dead = false
var weapon_base_pos: Vector3
var footstep_timer = 0.0

var footstep_sounds = [
	preload("res://assets/Audio/footstep_grass_000.ogg"),
	preload("res://assets/Audio/footstep_grass_001.ogg"),
	preload("res://assets/Audio/footstep_grass_002.ogg"),
]

@onready var head = $Head
@onready var ray = $Head/Camera3D/RayCast3D
@onready var weapon = $Head/Camera3D/Weapon
@onready var health_label = $"../CanvasLayer/HUD/HealthLabel"
@onready var ammo_label = $"../CanvasLayer/HUD/AmmoLabel"
@onready var score_label = $"../CanvasLayer/HUD/ScoreLabel"
@onready var game_over_label = $"../CanvasLayer/GameOverLabel"
@onready var shoot_sound = $ShootSound
@onready var reload_sound = $ReloadSound
@onready var footstep_sound = $FootstepSound
@onready var hurt_sound = $HurtSound
@onready var pickup_sound = $PickupSound

@onready var pause_menu = $"../CanvasLayer/PauseMenu"
@onready var resume_button = $"../CanvasLayer/PauseMenu/CenterContainer/VBoxContainer/ResumeButton"
@onready var menu_button = $"../CanvasLayer/PauseMenu/CenterContainer/VBoxContainer/MenuButton"

@onready var joystick = $"../CanvasLayer/TouchControls/Joystick"
@onready var shoot_button = $"../CanvasLayer/TouchControls/ShootButton"
@onready var jump_button = $"../CanvasLayer/TouchControls/JumpButton"
@onready var reload_button = $"../CanvasLayer/TouchControls/ReloadButton"


func _ready():
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	weapon_base_pos = weapon.position
	game_over_label.visible = false
	pause_menu.visible = false
	update_hud()

	if resume_button:
		resume_button.pressed.connect(_on_resume_button_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_button_pressed)

	if shoot_button:
		shoot_button.pressed.connect(_on_shoot_button_pressed)
	if jump_button:
		jump_button.pressed.connect(_on_jump_button_pressed)
	if reload_button:
		reload_button.pressed.connect(_on_reload_button_pressed)


func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	if is_dead:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
			get_tree().reload_current_scene()
		return

	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		return

	if get_tree().paused:
		return

	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

	if event is InputEventScreenDrag:
		var vp_size = get_viewport().get_visible_rect().size
		if event.position.x > vp_size.x * 0.35 and event.position.y < vp_size.y * 0.75:
			rotate_y(-event.relative.x * TOUCH_SENSITIVITY)
			head.rotate_x(-event.relative.y * TOUCH_SENSITIVITY)
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		shoot()

	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		reload()


func _on_shoot_button_pressed():
	if is_dead or get_tree().paused:
		return
	shoot()


func _on_jump_button_pressed():
	if is_dead or get_tree().paused:
		return
	if is_on_floor():
		velocity.y = JUMP_VELOCITY


func _on_reload_button_pressed():
	if is_dead or get_tree().paused:
		return
	reload()


func toggle_pause():
	var new_pause_state = not get_tree().paused
	get_tree().paused = new_pause_state
	pause_menu.visible = new_pause_state

	if new_pause_state:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_resume_button_pressed():
	get_tree().paused = false
	pause_menu.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_menu_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")


func _physics_process(delta):
	if is_dead or get_tree().paused:
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		input_dir.y -= 1
	if Input.is_key_pressed(KEY_S):
		input_dir.y += 1
	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1

	if joystick:
		input_dir += joystick.output

	input_dir = input_dir.limit_length(1.0)

	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED

	move_and_slide()

	handle_footsteps(delta, input_dir)


func handle_footsteps(delta, input_dir):
	if is_on_floor() and input_dir.length() > 0.1:
		footstep_timer -= delta
		if footstep_timer <= 0.0:
			footstep_timer = FOOTSTEP_INTERVAL
			footstep_sound.stream = footstep_sounds[randi() % footstep_sounds.size()]
			footstep_sound.play()
	else:
		footstep_timer = 0.0


func shoot():
	if ammo_in_mag <= 0:
		return

	ammo_in_mag -= 1
	update_hud()
	shoot_sound.play()

	ray.force_raycast_update()
	if ray.is_colliding():
		var point = ray.get_collision_point()
		var normal = ray.get_collision_normal()
		var collider = ray.get_collider()

		if collider.is_in_group("enemies"):
			collider.take_damage(DAMAGE)
		else:
			spawn_bullet_hole(point, normal)

	play_recoil()


func reload():
	if ammo_in_mag == MAGAZINE_SIZE or reserve_ammo <= 0:
		return

	var needed = MAGAZINE_SIZE - ammo_in_mag
	var take = min(needed, reserve_ammo)
	ammo_in_mag += take
	reserve_ammo -= take
	update_hud()
	reload_sound.play()


func add_ammo(amount):
	reserve_ammo += amount
	update_hud()
	pickup_sound.play()


func add_score(amount):
	score += amount
	update_hud()


func take_damage(amount):
	if is_dead:
		return
	health -= amount
	if health < 0:
		health = 0
	update_hud()
	hurt_sound.play()
	if health <= 0:
		die()


func die():
	is_dead = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game_over_label.visible = true


func update_hud():
	health_label.text = "Health: %d" % health
	ammo_label.text = "%d / %d" % [ammo_in_mag, reserve_ammo]
	score_label.text = "Score: %d" % score


func spawn_bullet_hole(point, normal):
	var hole = bullet_hole_scene.instantiate()
	get_tree().current_scene.add_child(hole)
	hole.global_position = point + normal * 0.01

	var up = Vector3.UP
	if abs(normal.dot(Vector3.UP)) > 0.99:
		up = Vector3.RIGHT
	hole.look_at(point + normal, up)


func play_recoil():
	var tween = create_tween()
	tween.tween_property(weapon, "position:z", weapon_base_pos.z + 0.1, 0.05)
	tween.tween_property(weapon, "position:z", weapon_base_pos.z, 0.15)
