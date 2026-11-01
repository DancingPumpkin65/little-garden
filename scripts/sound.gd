class_name GardenSound
extends Node

var player := AudioStreamPlayer.new()
var hum := AudioStreamPlayer.new()

func _ready() -> void:
	add_child(player)
	add_child(hum)
	if DisplayServer.get_name() == "headless": return
	player.volume_db = -14
	hum.volume_db = -29
	var stream := tone(196, 4.0, true)
	hum.stream = stream
	hum.play()

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
	hum.stop()
	player.stream = null
	hum.stream = null
