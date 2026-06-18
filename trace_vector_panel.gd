extends Control

signal trace_cleared

var crt_dark := Color("#001000")
var crt_dim := Color("#006622")
var crt_green := Color("#00ff55")
var crt_white := Color("#e8ffe8")
var crt_red := Color("#ff2020")

var nodes := [
	{"label": "SEA"},
	{"label": "SFO"},
	{"label": "DEN"},
	{"label": "DFW"},
	{"label": "ORD"},
	{"label": "HFD"},
	{"label": "NYC"},
	{"label": "DC"},
	{"label": "ATL"}
]

var links := [
	[0, 2],
	[1, 2],
	[2, 4],
	[3, 4],
	[4, 5],
	[5, 6],
	[6, 7],
	[7, 8],
	[3, 8]
]

var selected_index := 0
var trace_index := -1
var trace_active := false
var pulse_time := 0.0

func _ready() -> void:
	set_process(true)
	set_process_input(true)

func activate_trace() -> void:
	trace_active = true
	trace_index = randi_range(0, nodes.size() - 1)
	selected_index = 0
	if trace_index == 0:
		selected_index = 1
	pulse_time = 0.0
	queue_redraw()

func clear_trace() -> void:
	trace_active = false
	trace_index = -1
	emit_signal("trace_cleared")
	queue_redraw()

func get_node_positions() -> Array[Vector2]:
	var result: Array[Vector2] = []

	var top := 58.0
	var bottom := size.y - 42.0
	var usable_h := bottom - top
	var step : float = usable_h / max(1.0, float(nodes.size() - 1))

	# Slight x variation so it feels like topology, not just a menu.
	var x_values := [
		0.26, # SEA
		0.20, # SFO
		0.43, # DEN
		0.32, # DFW
		0.58, # ORD
		0.68, # HFD
		0.76, # NYC
		0.70, # DC
		0.50  # ATL
	]

	for i in range(nodes.size()):
		var x_ratio : float = x_values[i] if i < x_values.size() else 0.5
		var x : float = size.x * x_ratio
		var y : float = top + step * i
		result.append(Vector2(x, y))

	return result

func draw_selector(pos: Vector2) -> void:
	var left := pos.x - 16.0
	var right := pos.x + 16.0
	var top := pos.y - 13.0
	var bottom := pos.y + 13.0

	draw_line(Vector2(left, top), Vector2(left, bottom), crt_white, 2.0)
	draw_line(Vector2(left, top), Vector2(left + 8, top), crt_white, 2.0)
	draw_line(Vector2(left, bottom), Vector2(left + 8, bottom), crt_white, 2.0)

	draw_line(Vector2(right, top), Vector2(right, bottom), crt_white, 2.0)
	draw_line(Vector2(right, top), Vector2(right - 8, top), crt_white, 2.0)
	draw_line(Vector2(right, bottom), Vector2(right - 8, bottom), crt_white, 2.0)
	
func _input(event: InputEvent) -> void:
	if not trace_active:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_UP:
			selected_index = max(0, selected_index - 1)
			queue_redraw()

		elif event.keycode == KEY_DOWN:
			selected_index = min(nodes.size() - 1, selected_index + 1)
			queue_redraw()

		if selected_index == trace_index:
			clear_trace()

func _process(delta: float) -> void:
	pulse_time += delta
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)

	draw_rect(rect, crt_dark)
	# draw_rect(rect, crt_green, false, 2.0)

	var font := get_theme_default_font()
	var font_size := get_theme_default_font_size()

	draw_string(
		font,
		Vector2(16, 26),
		"TRACE VECTOR",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		crt_green
	)

	var positions := get_node_positions()

	# Draw decorative links behind nodes.
	for link in links:
		var a: int = link[0]
		var b: int = link[1]

		if a < positions.size() and b < positions.size():
			draw_line(
				positions[a],
				positions[b],
				crt_dim,
				1.0
			)

	# Draw nodes and labels.
	for i in range(nodes.size()):
		var pos := positions[i]
		var label: String = nodes[i]["label"]

		var node_color := crt_green
		var radius := 5.0

		if trace_active and i == trace_index:
			var pulse := 0.5 + 0.5 * sin(pulse_time * 10.0)
			node_color = crt_red.lerp(crt_white, pulse * 0.35)
			radius = 6.0 + pulse * 3.0

		if trace_active and i == selected_index:
			draw_selector(pos)

		draw_circle(pos, radius, node_color)

		draw_string(
			font,
			pos + Vector2(18, 5),
			label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size,
			crt_white if i == selected_index else crt_green
		)

	# Status line.
	var status := "ROUTE STABLE"
	var status_color := crt_dim

	if trace_active:
		status = "TRACE DETECTED"
		status_color = crt_red

	draw_string(
		font,
		Vector2(16, size.y - 18),
		status,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		status_color
	)
	
