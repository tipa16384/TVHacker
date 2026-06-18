extends Control

var time_left := 60.0
var max_time := 60.0
var critical_time := 5.0

var bg_color := Color(0.0, 0.08, 0.0)
var green := Color(0.35, 1.0, 0.35)
var red := Color(1.0, 0.05, 0.02)
var border := Color(0.65, 1.0, 0.65)

func _draw_filled_arc(
	center: Vector2,
	radius: float,
	start_angle: float,
	end_angle: float,
	color: Color
) -> void:
	var points := PackedVector2Array()
	points.append(center)

	var steps := 96
	var angle_span := end_angle - start_angle
	var used_steps : int = max(2, int(steps * abs(angle_span) / TAU))

	for i in range(used_steps + 1):
		var t := float(i) / float(used_steps)
		var angle : float = lerp(start_angle, end_angle, t)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)

	draw_colored_polygon(points, color)
	
func set_time(value: float, maximum: float, critical: float = 5.0) -> void:
	time_left = clamp(value, 0.0, maximum)
	max_time = max(maximum, 0.001)
	critical_time = critical
	queue_redraw()

func _zdraw() -> void:
	var center := size / 2.0
	var radius : float = min(size.x, size.y) * 0.45

	# Background circle.
	draw_circle(center, radius, bg_color)

	var remaining_ratio : float = clamp(time_left / max_time, 0.0, 1.0)

	# Full timer arc starts at 12 o'clock and drains clockwise.
	var start_angle := -PI / 2.0
	var end_angle := start_angle + TAU * remaining_ratio

	var fill_color := green
	if time_left <= critical_time:
		fill_color = red

	if remaining_ratio > 0.0:
		_draw_filled_arc(center, radius, start_angle, end_angle, fill_color)

	# Optional critical zone outline/marker.
	var critical_ratio : float = clamp(critical_time / max_time, 0.0, 1.0)
	var critical_angle := start_angle + TAU * critical_ratio
	var marker_pos := center + Vector2(cos(critical_angle), sin(critical_angle)) * radius
	draw_line(center, marker_pos, red, 2.0)

	# Border.
	draw_arc(center, radius, 0.0, TAU, 96, border, 2.0)

func _draw() -> void:
	var center := size / 2.0
	var radius : float = min(size.x, size.y) * 0.45
	var inner_radius := radius * 0.58

	draw_circle(center, radius, bg_color)

	var remaining_ratio : float = clamp(time_left / max_time, 0.0, 1.0)
	var start_angle := -PI / 2.0
	var end_angle := start_angle + TAU * remaining_ratio
	var fill_color := red if time_left <= critical_time else green

	if remaining_ratio > 0.0:
		_draw_filled_arc(center, radius, start_angle, end_angle, fill_color)

	# Punch out the middle so the label always has a dark background.
	draw_circle(center, inner_radius, bg_color)

	draw_arc(center, radius, 0.0, TAU, 96, border, 2.0)
	draw_arc(center, inner_radius, 0.0, TAU, 96, border, 1.0)
	
