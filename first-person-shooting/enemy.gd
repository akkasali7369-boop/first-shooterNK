extends CharacterBody3D

const SPEED = 2.0
const MAX_HEALTH = 100
const ATTACK_RANGE = 1.6
const ATTACK_DAMAGE = 10
const ATTACK_COOLDOWN = 1.0
const AMMO_DROP_CHANCE = 0.4

var health = MAX_HEALTH
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var player: Node3D
var attack_timer = 0.0
var is_dead = false

var ammo_pickup_scene = preload("res://ammo_pickup.tscn")

@onready var model = $characterMedium
@onready var anim = $characterMedium/AnimationPlayer
@onready var hit_sound = $HitSound
@onready var death_sound = $DeathSound


func _ready():
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")
	anim.play("idle/Root|Idle")


func _physics_process(delta):
	if is_dead or get_tree().paused:
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	if player:
		var to_player = player.global_position - global_position
		to_player.y = 0
		var dist = to_player.length()

		if dist > ATTACK_RANGE:
			var direction = to_player.normalized()
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED

			if anim.current_animation != "run/Root|Run":
				anim.play("run/Root|Run")

			model.rotation.y = atan2(direction.x, direction.z)
		else:
			velocity.x = 0
			velocity.z = 0

			if anim.current_animation != "idle/Root|Idle":
				anim.play("idle/Root|Idle")

			attack_timer -= delta
			if attack_timer <= 0.0:
				attack_timer = ATTACK_COOLDOWN
				if player.has_method("take_damage"):
					player.take_damage(ATTACK_DAMAGE)

	move_and_slide()


func take_damage(amount):
	if is_dead:
		return
	health -= amount
	hit_sound.play()
	play_hit_flash()
	if health <= 0:
		die()


func play_hit_flash():
	var tween = create_tween()
	tween.tween_property(model, "scale", Vector3(1.25, 0.8, 1.25) * 0.48, 0.06)
	tween.tween_property(model, "scale", Vector3.ONE * 0.48, 0.12)


func die():
	is_dead = true
	anim.play("idle/Root|Idle")
	death_sound.play()

	if player and player.has_method("add_score"):
		player.add_score(10)

	if randf() < AMMO_DROP_CHANCE:
		var pickup = ammo_pickup_scene.instantiate()
		get_tree().current_scene.add_child(pickup)
		pickup.global_position = global_position + Vector3(0, 0.5, 0)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(model, "position:y", model.position.y - 1.2, 0.4).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(model, "scale", Vector3(0.7, 0.1, 0.7) * 0.48, 0.4)
	tween.tween_property(self, "rotation:y", rotation.y + 1.2, 0.4)
	await tween.finished
	queue_free()
