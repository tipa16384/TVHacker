extends Control

signal missed_ball

@onready var pong_player : AudioStreamPlayer = $PongPlayer

var ping_sound = preload("res://audio/ping.wav")
var pong_sound = preload("res://audio/pong.wav")

var crt_dark := Color("#001000")
var crt_dim := Color("#006622")
var crt_green := Color("#00ff55")
var crt_white := Color("#e8ffe8")
var crt_red := Color("#ff2020")

var ball_pos := Vector2.ZERO
var ball_vel := Vector2.ZERO
var ball_radius := 5.0
var ball_speed : float = GameState.current_mission.pong_speed

var paddle_x := 0.0
var paddle_w := 70.0
var paddle_h := 10.0
var paddle_speed := 260.0
var paddle_margin_bottom := 28.0

var max_horizontal_speed := 220.0

var active := false

func play_sfx(stream: AudioStream) -> void:
	pong_player.stream = stream
	pong_player.play()
	
func set_active(value: bool) -> void:
	active = value
	queue_redraw()

func update_paddle(delta: float) -> void:
	if Input.is_key_pressed(KEY_LEFT):
		paddle_x -= paddle_speed * delta

	if Input.is_key_pressed(KEY_RIGHT):
		paddle_x += paddle_speed * delta

	var half_w := paddle_w * 0.5
	paddle_x = clamp(paddle_x, half_w + 8.0, size.x - half_w - 8.0)

func reset_ball() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	ball_pos = Vector2(size.x * 0.5, size.y * 0.72)

	# Pick left or right, but not too shallow.
	var x_dir := -1.0 if randf() < 0.5 else 1.0
	var direction := Vector2(0.55 * x_dir, -1.0).normalized()

	ball_vel = direction * ball_speed

func check_paddle_collision() -> void:
	var paddle_y := size.y - paddle_margin_bottom
	var paddle_rect := Rect2(
		Vector2(paddle_x - paddle_w * 0.5, paddle_y - paddle_h * 0.5),
		Vector2(paddle_w, paddle_h)
	)

	var ball_rect := Rect2(
		Vector2(ball_pos.x - ball_radius, ball_pos.y - ball_radius),
		Vector2(ball_radius * 2.0, ball_radius * 2.0)
	)

	if not paddle_rect.intersects(ball_rect):
		return

	# Only bounce if the ball is moving downward.
	if ball_vel.y <= 0.0:
		return

	play_sfx(ping_sound)

	ball_pos.y = paddle_rect.position.y - ball_radius

	# -1.0 at left edge, 0.0 center, +1.0 right edge.
	var hit_offset := (ball_pos.x - paddle_x) / (paddle_w * 0.5)
	hit_offset = clamp(hit_offset, -1.0, 1.0)

	ball_vel.y = -abs(ball_vel.y)

	# Add horizontal influence based on hit location.
	ball_vel.x += hit_offset * 120.0
	ball_vel.x = clamp(ball_vel.x, -max_horizontal_speed, max_horizontal_speed)

	# Normalize back toward intended speed so it doesn't crawl or explode.
	ball_vel = ball_vel.normalized() * ball_speed
	
func update_ball(delta: float) -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
   
	ball_pos += ball_vel * delta
	
	var bounced := false

	# Left wall.
	if ball_pos.x - ball_radius <= 0.0:
		ball_pos.x = ball_radius
		ball_vel.x = abs(ball_vel.x)
		bounced = true

	# Right wall.
	if ball_pos.x + ball_radius >= size.x:
		ball_pos.x = size.x - ball_radius
		ball_vel.x = -abs(ball_vel.x)
		bounced = true

	# Top wall.
	if ball_pos.y - ball_radius <= 0.0:
		ball_pos.y = ball_radius
		ball_vel.y = abs(ball_vel.y)
		bounced = true
	
	if bounced:
		play_sfx(pong_sound)

	# Paddle.
	check_paddle_collision()

	# Bottom miss.
	if ball_pos.y - ball_radius > size.y:
		emit_signal("missed_ball")
		reset_ball()
		
func _ready() -> void:
	set_process(true)
	reset_ball()
	paddle_x = size.x * 0.5
	self.visible = GameState.current_mission.enable_interrupt

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if ball_pos == Vector2.ZERO:
			reset_ball()
			paddle_x = size.x * 0.5
			
func _process(delta: float) -> void:
	if not GameState.current_mission.enable_interrupt:
		return
		
	if active:
		update_paddle(delta)
		update_ball(delta)
		
	queue_redraw()

func _draw() -> void:
	if not GameState.current_mission.enable_interrupt:
		return
		
	var rect := Rect2(Vector2.ZERO, size)

	draw_rect(rect, crt_dark)
	# draw_rect(rect, crt_green, false, 2.0)

	var font := get_theme_default_font()
	var font_size := get_theme_default_font_size()

	draw_string(
		font,
		Vector2(12, 24),
		"HOSTILE PROCESS",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		crt_green
	)

	draw_string(
		font,
		Vector2(12, 44),
		"DEFLECT TRACE",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		crt_dim
	)

	# Decorative center line / scan lines.
	for y in range(64, int(size.y), 32):
		draw_line(Vector2(8, y), Vector2(size.x - 8, y), Color("#003300"), 1.0)

	# Ball.
	draw_circle(ball_pos, ball_radius, crt_red)

	# Paddle.
	var paddle_y := size.y - paddle_margin_bottom
	var paddle_rect := Rect2(
		Vector2(paddle_x - paddle_w * 0.5, paddle_y - paddle_h * 0.5),
		Vector2(paddle_w, paddle_h)
	)

	draw_rect(paddle_rect, crt_green)

	# Bottom danger line.
	draw_line(
		Vector2(0, size.y - 8),
		Vector2(size.x, size.y - 8),
		crt_red,
		2.0
	)
