extends Control

var progress := 50.0
var blink_time := 0.0

func set_progress(value: float) -> void:
	progress = clamp(value, 0.0, 100.0)
	queue_redraw()

func _process(delta: float) -> void:
	if progress >= 100.0:
		blink_time += delta
		queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var fill_w := size.x * (progress / 100.0)

	var bg_color := Color(0.02, 0.08, 0.02)
	var fill_color := Color(0.4, 1.0, 0.4)
	var border_color := Color(0.8, 1.0, 0.8)

	draw_rect(rect, bg_color)
	draw_rect(Rect2(Vector2.ZERO, Vector2(fill_w, size.y)), fill_color)
	draw_rect(rect, border_color, false, 2.0)

	var text := "%.1f%%" % progress
	if progress >= 100.0:
		text = "100% HACKED!"

	var font := get_theme_default_font()
	var font_size := get_theme_default_font_size()
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)

	var pos := Vector2(
		(size.x - text_size.x) / 2.0,
		(size.y + text_size.y) / 2.0 - 4.0
	)

	# Blinking hacked text
	if progress >= 100.0:
		var visible := int(blink_time * 4.0) % 2 == 0
		if not visible:
			return

	# Draw inverse-ish shadow/contrast layers
	draw_string(font, pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.BLACK)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
