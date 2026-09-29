extends Area3D

const AMMO_AMOUNT = 16

@onready var model = $Model


func _ready():
	add_to_group("ammo_pickups")
	body_entered.connect(_on_body_entered)


func _process(delta):
	rotate_y(delta * 2.0)
	model.position.y = 0.1 + sin(Time.get_ticks_msec() / 300.0) * 0.05


func _on_body_entered(body):
	if body.is_in_group("player") and body.has_method("add_ammo"):
		body.add_ammo(AMMO_AMOUNT)
		queue_free()
