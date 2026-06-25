# GameState.gd
extends Node

var current_mission := {
	"name": "Hack the Gibson",
	"target_kpm": 400.0,
	"target_gap": 20.0,
	"time_limit": 60.0,
	"pong_speed": 170.0,
	"progress_mult": 5.0,
	"trace_enabled": false,
	"enable_speech": false,
	"enable_interrupt": false,
	"webcam": "sodamachine.jpg"
}
