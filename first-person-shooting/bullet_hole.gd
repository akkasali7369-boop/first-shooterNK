extends Node3D

const SPARK_COUNT = 10
const SPARK_LIFETIME = 0.35
const SPARK_SPREAD_DEG = 45.0
const SPARK_MIN_DIST = 0.15
const SPARK_MAX_DIST = 0.45

@onready var mark = $Mark


func _ready():
	var mark_material = mark.get_active_material(0).duplicate()
	mark.set_surface_override_material(0, mark_material)

	spawn_sparks()

	await get_tree().create_timer(4.0).timeout
	var tween = create_tween()
	mark_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tween.tween_property(mark_material, "albedo_color:a", 0.0, 1.0)
	await tween.finished
	queue_free()


func spawn_sparks():
	var spark_material = StandardMaterial3D.new()
	spark_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_material.albedo_color = Color(1.0, 0.75, 0.2)
	spark_material.emission_enabled = true
	spark_material.emission = Color(1.0, 0.6, 0.1)
	spark_material.emission_energy_multiplier = 4.0

	for i in range(SPARK_COUNT):
		var spark = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.03, 0.03, randf_range(0.08, 0.2))
		spark.mesh = box
		spark.material_override = spark_material
		add_child(spark)

		var angle = deg_to_rad(randf_range(0, SPARK_SPREAD_DEG))
		var rot = randf_range(0, TAU)
		var dir = Vector3(sin(angle) * cos(rot), sin(angle) * sin(rot), -cos(angle))

		spark.look_at(global_position + (global_transform.basis * dir), Vector3.UP)

		var dist = randf_range(SPARK_MIN_DIST, SPARK_MAX_DIST)
		var target_pos = dir * dist
		target_pos.y -= 0.06

		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(spark, "position", target_pos, SPARK_LIFETIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(spark, "scale", Vector3.ZERO, SPARK_LIFETIME * 0.6).set_delay(SPARK_LIFETIME * 0.4)
		tween.chain().tween_callback(spark.queue_free)
