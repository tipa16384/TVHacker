extends TextureRect

@onready var web_cam : TextureRect = self

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var xtexture := load("res://images/" + GameState.current_mission.webcam)
	if xtexture:
		print ("Image found")
	web_cam.visible = not GameState.current_mission.enable_interrupt
	web_cam.set_texture(xtexture)
