# Background music

`musicbackground.mp3` is the user-supplied recording of Piero Umiliani's "Volto di donna (Orchestra Version)". The original `.mpeg` filename contained MPEG-1 Layer III audio, so it was renamed to `.mp3` without re-encoding. Inspection reports 208.42 seconds, stereo, 48 kHz, 320 kbps.

`GardenSound` plays it with native MP3 looping, a 2.5-second fade-in, and a -26 dB target volume. It uses a separate player, leaving dialogue and effects independent. The existing Mute sound control affects it, and scene restart/shutdown stops the previous player.

MP3 already supplies compressed audio. Converting this compressed source to another lossy format would sacrifice quality without addressing the measured rendering bottleneck. Godot documents [native MP3 streams and looping](https://docs.godotengine.org/en/stable/classes/class_audiostreammp3.html).
