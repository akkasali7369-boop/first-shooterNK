extends Node3D

const ENEMIES_PER_WAVE_BASE = 3
const SPAWN_INTERVAL = 2.0
const AMMO_SPAWN_INTERVAL = 12.0
const AMMO_MAX_ACTIVE = 3

var enemy_scene = preload("res://enemy.tscn")
var ammo_pickup_scene = preload("res://ammo_pickup.tscn")

var enemy_spawn_points: Array = []
var ammo_spawn_points: Array = []

var wave = 0
var enemies_to_spawn = 0
var spawn_timer = 0.0
var ammo_timer = AMMO_SPAWN_INTERVAL

@onready var wave_label = get_node("../CanvasLayer/HUD/WaveLabel")


func _ready():
	for child in get_children():
		if child is Marker3D:
			if child.name.begins_with("SpawnPoint"):
				enemy_spawn_points.append(child)
			elif child.name.begins_with("AmmoPoint"):
				ammo_spawn_points.append(child)
	start_next_wave()


func _process(delta):
	if get_tree().paused:
		return

	if enemies_to_spawn > 0:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			spawn_timer = SPAWN_INTERVAL
			spawn_enemy()
			enemies_to_spawn -= 1
	elif get_tree().get_nodes_in_group("enemies").size() == 0:
		start_next_wave()

	handle_ammo_spawning(delta)


func handle_ammo_spawning(delta):
	if ammo_spawn_points.is_empty():
		return

	ammo_timer -= delta
	if ammo_timer <= 0.0:
		ammo_timer = AMMO_SPAWN_INTERVAL
		if get_tree().get_nodes_in_group("ammo_pickups").size() < AMMO_MAX_ACTIVE:
			spawn_ammo_at_random_point()


func spawn_ammo_at_random_point():
	var point = ammo_spawn_points[randi() % ammo_spawn_points.size()]
	var pickup = ammo_pickup_scene.instantiate()
	get_tree().current_scene.add_child(pickup)
	pickup.global_position = point.global_position


func start_next_wave():
	wave += 1
	enemies_to_spawn = ENEMIES_PER_WAVE_BASE + wave - 1
	spawn_timer = 0.0
	update_wave_label()


func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	var point = enemy_spawn_points[randi() % enemy_spawn_points.size()]
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = point.global_position


func update_wave_label():
	wave_label.text = "Wave: %d" % wave
