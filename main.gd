extends Control

@onready var phrase_label = $MainMargin/RootVBox/MiddleRow/VoicePanelRoot/VoiceVBox/PhraseLabel
@onready var voice_hack_display = $MainMargin/RootVBox/MiddleRow/VoicePanelRoot/VoiceVBox/VoiceHackDisplay
@onready var hack_bar: ProgressBar = $MainMargin/RootVBox/TopRow/HackProgressRoot/HackProgressBar
@onready var hack_label: Label = $MainMargin/RootVBox/TopRow/HackProgressRoot/HackProgressLabel
@onready var timer_dial = $MainMargin/RootVBox/TopRow/TimerDialRoot/TimerDial
@onready var timer_label = $MainMargin/RootVBox/TopRow/TimerDialRoot/TimerLabel
@onready var voice_label = $MainMargin/RootVBox/MiddleRow/VoicePanelRoot/VoiceVBox/VoicePanelTitleLabel
@onready var kpm_instrument = $MainMargin/RootVBox/KPMInstrument
@onready var mission_overlay: ColorRect = $MissionResultOverlay
@onready var result_label: Label = $MissionResultOverlay/CenterContainer/VBoxContainer/ResultLabel
@onready var continue_label: Label = $MissionResultOverlay/CenterContainer/VBoxContainer/ContinueLabel
@onready var trace_panel = $MainMargin/RootVBox/MiddleRow/TraceVectorPanel
@onready var interrupt_panel = $MainMargin/RootVBox/MiddleRow/InterruptPanel
@onready var music_player : AudioStreamPlayer = $GameMusic

var mission_failed = preload("res://audio/mission_failed.wav")
var mission_success = preload("res://audio/mission_success.wav")
var tick_sound = preload("res://audio/tick.wav")
var modem_sound = preload("res://audio/modem.mp3")

var mission_finished := false
var success := false
var result_overlay_active := false
var result_accept_input := false
var result_delay := 5.0
var result_elapsed := 0.0
var non_speech_phrase_length := 10

var trace_clear := true

var old_hack_progress := 0.0
var hack_progress := 0.0
var hacked_blink_time := 0.0

var capture: AudioEffectCapture
var key_count := 0
var mic_bus_idx := 2
var phrase : Array = []
var voice_history: Array[Vector2] = []

var voice_threshold := 0.75
var filter_threshold := 0.3
var was_speaking := false
var pulse_count := 0
var pulse_cooldown := 0.0
var last_update := 0.0
var cur_update := 0.0

var key_times: Array[float] = []
var kpm_window := 30.0
var current_kpm := 0.0

var target_kpm := 200.0
var target_gap := 20.0
var score := 0.0
var target_score := 50.0

var time_left := 60.0
var max_time := 60.0

var ignored_keys := [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]
var start_time := 0.0
var tick_time : int = 0
var modem_sound_played := false

var verbs: Array = [
	["isolate", "i-so-late", 3],
	["rectify", "rect-i-fy", 3],
	["prime", "prime", 1],
	["recurse", "re-curse", 2],
	["overflow", "o-ver-flow", 3],
	["cancel", "can-cel", 2],
	["refactor", "re-fac-tor", 3],
	["initialize", "in-i-tial-ize", 4],
	["interrupt", "in-ter-rupt", 3],
	["hack", "hack", 1],
	["simulate", "sim-ul-ate", 3]
]

var nouns: Array = [
	["buffer", "buf-fer", 2],
	["procedure", "pro-ce-dure", 3],
	["stack", "stack", 1],
	["database", "da-ta-base", 3],
	["capacitor", "ca-pa-ci-tor", 4],
	["mainframe", "main-frame", 2],
	["switchboard", "switch-board", 2],
	["CPU", "C-P-U", 3],
	["cache", "cache", 1]
]

var adjectives: Array = [
	["output", "out-put", 2],
	["graphics", "graph-ics", 2],
	["input", "in-put", 2],
	["dedicated", "ded-i-ca-ted", 4],
	["dead", "dead", 1],
	["binary", "bi-nar-y", 3],
	["syntax", "syn-tax", 2]
]

func speech() -> bool:
	return GameState.current_mission.enable_speech

func play_sfx(stream: AudioStream) -> void:
	music_player.stream = stream
	music_player.play()

func finish_mission(was_successful: bool) -> void:
	mission_finished = true
	success = was_successful
	
	play_sfx(mission_success if success else mission_failed)

	result_overlay_active = true
	result_accept_input = false
	result_elapsed = 0.0

	mission_overlay.visible = true
	continue_label.visible = false

	interrupt_panel.set_active(false)

	DisplayServer.tts_stop()
	
	if success:
		result_label.text = "HACKED!"
		result_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		result_label.text = "MISSION FAILED!"
		result_label.add_theme_color_override("font_color", Color.RED)

	result_label.add_theme_font_size_override("font_size", 104)
	continue_label.add_theme_font_size_override("font_size", 28)
	continue_label.add_theme_color_override("font_color", Color.WHITE)

func update_result_overlay(delta: float) -> void:
	result_elapsed += delta

	if result_elapsed >= result_delay:
		result_accept_input = true
		continue_label.visible = true
		
func set_hack_progress(value: float) -> void:
	hack_progress = clamp(value, 0.0, 100.0)
	hack_bar.value = hack_progress

	if hack_progress >= 100.0:
		hack_label.text = "100% HACKED!"
	else:
		hack_label.text = "%.1f%% HACKED" % hack_progress
	
	if trace_clear \
		and GameState.current_mission.trace_enabled \
		and ((old_hack_progress < 25.0 and hack_progress >= 25.0) \
			or (old_hack_progress < 50.0 and hack_progress >= 50.0) \
			or (old_hack_progress < 75.0 and hack_progress >= 75.0)):
		trace_panel.activate_trace()
		trace_clear = false
	
	old_hack_progress = hack_progress
	
func _add_phrase_candidate(
	candidates: Array,
	verb: Array,
	adjective,
	noun: Array,
	min_syllables: int,
	max_syllables: int
) -> void:
	var the_syllables := 1

	var total: int = verb[2] + the_syllables + noun[2]
	if adjective != null:
		total += adjective[2]

	if total < min_syllables or total > max_syllables:
		return

	var words: Array[String] = [verb[0], "the"]
	var syllable_words: Array[String] = [verb[1], "the"]

	if adjective != null:
		words.append(adjective[0])
		syllable_words.append(adjective[1])

	words.append(noun[0])
	syllable_words.append(noun[1])

	var full_phrase := " ".join(words).to_upper()
	var phrase_as_syllables := "-".join(syllable_words)

	candidates.append([full_phrase, phrase_as_syllables, total])

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if mission_finished and result_accept_input and event.keycode == KEY_X:
			reset()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("screenshot"):
		# Capture the viewport and save to the user folder
		var img : Image = get_viewport().get_texture().get_image()
		img.save_png("user://TVHacker.png")      

	if mission_finished:
		return
	
	var special_key : bool = event.keycode in ignored_keys
	
	if event is InputEventKey and event.pressed and not event.echo and not special_key:
		key_times.append(Time.get_ticks_msec() / 1000.0)
		while key_times.size() > kpm_window:
			key_times.pop_front()

func update_kpm() -> void:
	var now := Time.get_ticks_msec() / 1000.0

	if key_times.size() > 1:
		var last_interval := key_times[-1] - key_times[-2]
		var current_interval := now - key_times[-1]
		if current_interval > 2.0 * max(last_interval, 0.35):
			current_kpm = 0.0
			key_times = []
		else:
			var sum := 0.0
			for i in range(0, key_times.size() - 1):
				sum += key_times[i+1] - key_times[i]
			var avg := sum / key_times.size()
			current_kpm = 60.0 / avg

	var low := target_kpm - target_gap / 2.0
	var high := target_kpm + target_gap / 2.0

	kpm_instrument.set_values(current_kpm, low, high)

func make_phrase(min_syllables: int, max_syllables: int) -> Array:
	var candidates: Array = []

	for verb in verbs:
		for noun in nouns:
			# No adjective
			_add_phrase_candidate(candidates, verb, null, noun, min_syllables, max_syllables)

			# One adjective
			for adjective in adjectives:
				_add_phrase_candidate(candidates, verb, adjective, noun, min_syllables, max_syllables)

	if candidates.is_empty():
		push_warning("No phrase found for syllable range %d-%d" % [min_syllables, max_syllables])
		return ["ERROR THE MAINFRAME", "er-ror-the-main-frame", 5]

	return candidates.pick_random()
	
func update_voice(delta: float, normalized: float) -> void:
	cur_update += delta
	
	if speech() and not phrase.is_empty() and (cur_update - last_update > 2) and (pulse_count > 0):
		pulse_count = 1000
		
	pulse_cooldown = max(0.0, pulse_cooldown - delta)

	var speaking := normalized > voice_threshold

	if speech() and speaking and not was_speaking and pulse_cooldown <= 0.0:
		pulse_count += 1
		pulse_cooldown = 0.2
		last_update = cur_update

	was_speaking = speaking
	var phrase_len : int = phrase[2] if speech() and not phrase.is_empty() \
									else non_speech_phrase_length
	
	if (not speech() and pulse_count >= phrase_len) or (not phrase.is_empty() and pulse_count >= phrase_len):
		var target_low := target_kpm - target_gap/2.0
		var target_high := target_kpm + target_gap/2.0
		var divider := 3.0
		
		if current_kpm >= target_low and current_kpm <= target_high:
			divider = 1.0
		
		if trace_clear:
			score += GameState.current_mission.progress_mult \
				* phrase_len * (1.0 - abs(target_kpm - current_kpm) / target_kpm) / divider
			phrase = []
			pulse_count = 0
			
		set_hack_progress(clamp(100.0 * score / target_score, 0.0, 100.0))

func add_voice_sample(left: float, right: float) -> void:
	voice_history.append(Vector2(left, right))

	if voice_history.size() > 60:
		voice_history.pop_front()
	
	voice_hack_display.set_voice_history(voice_history)

func reset() -> void:
	for i in range(60):
		voice_history.append(Vector2.ZERO)
	mission_finished = false
	success = false
	time_left = max_time
	hack_progress = 0
	phrase = []
	old_hack_progress = 0
	trace_clear = true
	result_overlay_active = false
	result_accept_input = false
	result_elapsed = 0.0
	key_count = 0
	was_speaking = false
	pulse_count = 0
	pulse_cooldown = 0.0
	last_update = 0.0
	cur_update = 0.0
	current_kpm = 0.0
	score = 0.0
	mission_overlay.visible = false
	continue_label.visible = false
	set_hack_progress(0.0)
	key_times = []
	interrupt_panel.set_active(GameState.current_mission.enable_interrupt)
	start_time = Time.get_ticks_msec() + 2000.0
	timer_dial.stop_all_sounds()
	music_player.stop()
	tick_time = 0
	modem_sound_played = false
	target_kpm = GameState.current_mission.target_kpm
	target_gap = GameState.current_mission.target_gap
	time_left = GameState.current_mission.time_limit
	max_time = time_left

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print ("Base engine FPS ", Engine.max_fps)
	Engine.max_fps = 60
	print ("Base engine FPS is now ", Engine.max_fps)
	interrupt_panel.missed_ball.connect(_on_missed_ball)
	mic_bus_idx = AudioServer.get_bus_index("Mic")
	print("Mic bus index: ", mic_bus_idx)
	print("Audio input enabled: ", ProjectSettings.get_setting("audio/driver/enable_input"))
	
	# trace_panel.visible = GameState.current_mission.trace_enabled
	voice_label.text = GameState.current_mission.name
	
	reset()

func _on_missed_ball() -> void:
	if not mission_finished:
		old_hack_progress = 0.0
		score /= 2.0
		set_hack_progress(hack_progress / 2.0)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if result_overlay_active:
		update_result_overlay(delta)
		return

	update_kpm()
	
	var left_db := AudioServer.get_bus_peak_volume_left_db(mic_bus_idx, 0)
	var right_db := AudioServer.get_bus_peak_volume_right_db(mic_bus_idx, 0)

	var db : float = max(left_db, right_db)

	var min_db := -60.0
	var max_db := -20.0
	var normalized := inverse_lerp(min_db, max_db, db)
	var normalized_left : float = clamp(inverse_lerp(min_db, max_db, left_db), 0.0, 1.0)
	var normalized_right : float = clamp(inverse_lerp(min_db, max_db, right_db), 0.0, 1.0)
	
	add_voice_sample(normalized_left, normalized_right)
	
	if normalized < filter_threshold:
		normalized = 0.0
	
	update_voice(delta, normalized)
	
	if mission_finished:
		return
	
	var now := Time.get_ticks_msec()

	if speech() and phrase.is_empty() and now > start_time:
		phrase = make_phrase(5,8)
		phrase_label.text = phrase[0]
	
		var voices = DisplayServer.tts_get_voices_for_language("en")
		var voice_id = voices[0]
	
		DisplayServer.tts_speak(phrase_label.text, voice_id)

	time_left = max(0, time_left - delta)
	timer_dial.set_time(time_left, max_time, 5.0)

	var new_secs = int(time_left / 5.0)
	if new_secs != tick_time:
		play_sfx(tick_sound)
		tick_time = new_secs
		if not speech():
			pulse_count += non_speech_phrase_length
	
	if time_left <= 0.0:
		timer_label.text = "FAIL!!!"
		finish_mission(false)
	else:
		timer_label.text = "%.1f" % time_left
	
	if hack_progress >= 100.0:
		hacked_blink_time += delta
		hack_label.visible = int(hacked_blink_time * 4.0) % 2 == 0
		finish_mission(true)
	else:
		hack_label.visible = true
		hacked_blink_time = 0.0
	
	if not modem_sound_played:
		play_sfx(modem_sound)
		modem_sound_played = true
	
func _on_trace_vector_panel_trace_cleared() -> void:
	trace_clear = true
