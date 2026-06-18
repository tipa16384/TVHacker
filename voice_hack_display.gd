extends Control

var voice_history: Array[Vector2] = []

func set_voice_history(history: Array[Vector2]) -> void:
	voice_history = history
	queue_redraw()

func _draw() -> void:
	if voice_history.is_empty():
		return

	var count := voice_history.size()
	var slot_w := size.x / float(count)
	var h := size.y

	for i in range(count):
		var sample := voice_history[i]

		var x := i * slot_w + 2.0
		var bar_w : float = max(1.0, slot_w - 4.0)

		var top_y := h * (1.0 - sample.x) / 4.0 + h * 0.2
		var bottom_y := h * (1.0 + sample.y) / 4.0 + h * 0.2

		var rect := Rect2(
			Vector2(x, top_y),
			Vector2(bar_w, bottom_y - top_y)
		)

		draw_rect(rect, Color.GREEN)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
