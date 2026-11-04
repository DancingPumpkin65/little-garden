extends SceneTree
var failed := false

func _initialize() -> void:
 run.call_deferred()

func check(condition: bool, message: String) -> void:
 if not condition:
  push_error(message)
  failed = true

func run() -> void:
 var hud := GardenInterface.new()
 root.add_child(hud)
 hud.set_process(false)
 var plain := hud.letter_delay("abcdef",0)
 check(plain >= 0.065,"ordinary letters must reveal noticeably slower than 44 ms")
 var line := "abcd, ef!"
 check(hud.letter_delay(line,1)>plain,"slowdown starts three characters before punctuation")
 check(hud.letter_delay(line,2)>hud.letter_delay(line,1),"approach slows progressively")
 check(hud.letter_delay(line,3)>hud.letter_delay(line,2),"last letter before punctuation slows further")
 check(hud.letter_delay(line,4)>hud.letter_delay(line,3),"punctuation lands deliberately")
 check(hud.letter_delay(line,5)>=plain+0.20,"comma leaves a readable pause")
 hud.speech(line)
 var elapsed := 0.0
 while hud.dialogue.visible_characters<line.length():
  hud._process(0.001)
  elapsed+=0.001
  if elapsed>10: break
 check(absf(elapsed-hud.typing_duration(line))<0.003,"duration follows actual reveal loop")
 if not failed: print("DIALOGUE_PACING_PASS reveal seconds=",elapsed," plain letter=",plain)
 quit(1 if failed else 0)
