extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var db : float = max(
		AudioServer.get_bus_peak_volume_left_db(0, 0),
		AudioServer.get_bus_peak_volume_right_db(0, 0)
	)

	print ("DB: %.1f" % db)
	
