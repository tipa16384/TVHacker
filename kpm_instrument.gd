extends Control

var current_kpm := 0.0
var target_kpm := 120.0
var target_low := 110.0
var target_high := 130.0

var min_kpm := 0.0
var max_kpm := 240.0

var crt_dark := Color("#001000")
var crt_dim := Color("#006622")
var crt_green := Color("#00ff55")
var crt_white := Color("#e8ffe8")
var crt_red := Color("#ff2020")

func set_values(kpm: float, low: float, high: float) -> void:
	current_kpm = kpm
	target_low = low
	target_high = high
	target_kpm = (low + high) / 2.0

	# Keep the display scale useful as difficulty rises.
	max_kpm = max(240.0, target_high * 1.5)

	queue_redraw()

func kpm_to_x(kpm: float, track_x: float, track_w: float) -> float:
	var t := inverse_lerp(min_kpm, max_kpm, kpm)
	return track_x + clamp(t, 0.0, 1.0) * track_w
	
func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)

	# Panel background.
	draw_rect(rect, crt_dark)
	draw_rect(rect, crt_green, false, 2.0)

	var padding := 24.0
	var track_y := size.y * 0.55
	var track_h := 24.0
	var track_x := padding
	var track_w := size.x - padding * 2.0

	var track_rect := Rect2(track_x, track_y - track_h / 2.0, track_w, track_h)

	# Base track.
	draw_rect(track_rect, Color("#003300"))
	draw_rect(track_rect, crt_dim, false, 1.0)

	# Target green zone.
	var low_x := kpm_to_x(target_low, track_x, track_w)
	var high_x := kpm_to_x(target_high, track_x, track_w)
	var zone_rect := Rect2(
		low_x,
		track_y - track_h / 2.0,
		max(1.0, high_x - low_x),
		track_h
	)
	draw_rect(zone_rect, crt_green)

	# Current indicator.
	var cur_x := kpm_to_x(current_kpm, track_x, track_w)
	var locked := current_kpm >= target_low and current_kpm <= target_high
	var indicator_color := crt_white if locked else crt_red

	draw_line(
		Vector2(cur_x, track_y - 36.0),
		Vector2(cur_x, track_y + 36.0),
		indicator_color,
		3.0
	)

	var tri := PackedVector2Array([
		Vector2(cur_x, track_y - 42.0),
		Vector2(cur_x - 8.0, track_y - 56.0),
		Vector2(cur_x + 8.0, track_y - 56.0),
	])
	draw_colored_polygon(tri, indicator_color)

	# Tick marks.
	for kpm in range(int(min_kpm), int(max_kpm) + 1, 20):
		var x : float = kpm_to_x(float(kpm), track_x, track_w)
		var tick_h := 10.0
		if kpm % 60 == 0:
			tick_h = 18.0

		draw_line(
			Vector2(x, track_y + track_h / 2.0),
			Vector2(x, track_y + track_h / 2.0 + tick_h),
			crt_dim,
			1.0
		)

	# Text.
	var status := "LOCKED"
	if current_kpm < target_low:
		status = "LOW"
	elif current_kpm > target_high:
		status = "HIGH"

	var title := "KEYBOARD OSCILLATOR"
	var value := "%03.0f KPM" % current_kpm
	var target := "TARGET %.0f-%.0f" % [target_low, target_high]

	var font := get_theme_default_font()
	var font_size := get_theme_default_font_size()

	draw_string(font, Vector2(padding, 28), title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, crt_green)
	draw_string(font, Vector2(size.x * 0.45, 28), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 8, crt_white)
	draw_string(font, Vector2(size.x - 180, 28), status, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, indicator_color)
	draw_string(font, Vector2(padding, size.y - 12), target, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, crt_dim)
	
