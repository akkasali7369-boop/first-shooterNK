extends Control

const RADIUS = 60.0

var output := Vector2.ZERO
var _active_index = -1
var _center = Vector2.ZERO

@onready var base = $Base
@onready var knob = $Knob


func _ready():
	_center = base.position + base.size / 2.0
	_reset_knob()


func _gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed and _active_index == -1:
			_active_index = event.index
			_update_knob(event.position)
		elif not event.pressed and event.index == _active_index:
			_active_index = -1
			_reset_knob()

	elif event is InputEventScreenDrag:
		if event.index == _active_index:
			_update_knob(event.position)

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_active_index = 999
			_update_knob(event.position)
		elif _active_index == 999:
			_active_index = -1
			_reset_knob()

	elif event is InputEventMouseMotion and _active_index == 999:
		_update_knob(event.position)


func _update_knob(pos: Vector2):
	var delta = pos - _center
	var dist = min(delta.length(), RADIUS)
	var dir = Vector2.ZERO
	if delta.length() > 0.01:
		dir = delta.normalized()
	knob.position = _center + dir * dist - knob.size / 2.0
	output = dir * (dist / RADIUS)


func _reset_knob():
	knob.position = _center - knob.size / 2.0
	output = Vector2.ZERO
