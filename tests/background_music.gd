extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
 assert(DisplayServer.get_name()!="headless","native audio backend required")
 Engine.max_fps=60
 var sound:=GardenSound.new()
 root.add_child(sound)
 assert(sound.music.stream is AudioStreamMP3,"supplied MPEG file imports as MP3")
 assert(sound.music.playing and sound.music.volume_db<=-55,"music starts quietly")
 var stream:=sound.music.stream as AudioStreamMP3
 assert(stream.loop and stream.get_length()>200 and stream.get_length()<215,"full recording loops")
 await create_timer(2.8).timeout
 assert(absf(sound.music.volume_db-sound.MUSIC_VOLUME_DB)<.1,"gentle fade reaches low target volume")
 sound.music.seek(stream.get_length()-.12)
 await create_timer(.6).timeout
 assert(sound.music.playing and sound.music.get_playback_position()<2,"playback crosses song end and loops")
 var muted:=AudioServer.is_bus_mute(0)
 AudioServer.set_bus_mute(0,true)
 assert(sound.music.playing,"mute preserves loop position")
 AudioServer.set_bus_mute(0,muted)
 sound.murmur("a")
 sound.jump()
 sound.chime()
 assert(sound.voice.playing and sound.effects.playing and sound.player.playing,"dialogue and effects remain independent")
 sound.silence()
 assert(not sound.music.playing and sound.music.stream==null,"restart/shutdown can stop and release music")
 print("BACKGROUND_MUSIC_PASS MP3 format, full recording, fade, actual loop boundary, mute and effects")
 quit()
