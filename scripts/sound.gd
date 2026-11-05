class_name GardenSound
extends Node

var player := AudioStreamPlayer.new()
var voice := AudioStreamPlayer.new()
var effects := AudioStreamPlayer.new()
var syllables: Array[AudioStreamWAV] = []
var jump_clip: AudioStreamWAV

func _ready() -> void:
	add_child(player)
	add_child(voice)
	add_child(effects)
	if DisplayServer.get_name() == "headless": return
	voice.volume_db = -20
	effects.volume_db = -17
	for frequency in [135, 148, 161, 174, 187]: syllables.append(voice_tone(frequency))
	jump_clip = jump_tone()
	player.volume_db = -14

func tone(frequency: float, seconds: float, looped: bool = false) -> AudioStreamWAV:
	var rate := 22050
	var bytes := PackedByteArray()
	bytes.resize(int(rate * seconds) * 2)
	for i in range(int(rate * seconds)):
		var t := float(i) / rate
		var envelope := 0.3 if looped else exp(-t * 5) * minf(t * 50, 1)
		var wave := sin(TAU * frequency * t) + 0.25 * sin(TAU * frequency * 2 * t)
		bytes.encode_s16(i * 2, int(wave * envelope * 18000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	if looped:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = int(rate * seconds)
	return stream

func chime(frequency: float = 523.25) -> void:
	if DisplayServer.get_name() == "headless": return
	player.stream = tone(frequency, 1.2)
	player.play()

func silence() -> void:
	player.stop()
	voice.stop()
	effects.stop()
	voice.stream = null
	effects.stream = null
	player.stream = null

# Short voiced syllables vary by letter without interrupting chimes.
func voice_tone(frequency: float) -> AudioStreamWAV:
	var stream := tone(frequency, 0.075)
	var data := stream.data
	for i in range(data.size() / 2):
		var t := i / 22050.0
		var envelope := sin(PI * t / 0.075)
		var wave := sin(TAU * frequency * t) + 0.32 * sin(TAU * frequency * 3 * t) + 0.14 * sin(TAU * 720 * t)
		data.encode_s16(i * 2, int(wave * envelope * 11000))
	stream.data = data
	return stream

func murmur(letter: String) -> void:
	if syllables.is_empty(): return
	voice.stream = syllables[letter.unicode_at(0) % syllables.size()]
	voice.play()

func jump_tone() -> AudioStreamWAV:
	var stream := tone(280, 0.24)
	var phase := 0.0
	var data := stream.data
	for i in range(data.size() / 2):
		var t := i / 22050.0
		var progress := t / 0.24
		phase += TAU * lerpf(220, 560, sin(progress * PI)) / 22050.0
		data.encode_s16(i * 2, int((sin(phase) + 0.15 * sin(phase * 2)) * sin(PI * progress) * 11000))
	stream.data = data
	return stream

func jump() -> void:
	if jump_clip == null: return
	effects.stream = jump_clip
	effects.play()

# A short brittle impact grows into a longer burst on the third hit.
func glass_impact(broken: bool) -> void:
	if DisplayServer.get_name() == "headless": return
	var seconds := 0.65 if broken else 0.18
	var stream := tone(1800,seconds)
	var data := stream.data
	var random := RandomNumberGenerator.new()
	random.seed = 531 if broken else 213
	for i in range(data.size()/2):
		var t := i/22050.0
		var envelope := exp(-t*(7 if broken else 23))
		var wave := random.randf_range(-1,1)*0.55+sin(TAU*2300*t)*0.25+sin(TAU*3610*t)*0.2
		data.encode_s16(i*2,int(wave*envelope*21000))
	stream.data = data
	effects.stream = stream
	effects.play()
