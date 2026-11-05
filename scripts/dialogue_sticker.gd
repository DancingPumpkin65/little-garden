class_name GardenDialogueSticker
extends TextureRect

# Dialogue stays plain text; sticker filenames never enter the typewriter or voice sounds.
const ASSIGNMENTS: Dictionary[String, String] = {
	"3arfek yala jaya men lkhadma, 3iyana o darek rassek o darak kerchek okulchi...": "myhead",
	"O tlu7iha f ssela O": "ok",
	"3awtani majbtihach :/ wa9ila fik n3ass...": "overworked",
	"Ma3lich had lmara tjibiha, \"TALTA TABTA\"": "hihi",
	"Salma Ez Zyry...": "hem",
	"B9iiiina hnaya": "dfaar",
	"Bravo! Makuntch 3aref rak sportif!": "pat",
	"3la slama... Bravo 3lik!": "pat",
	"Jibi liya lyed dyali o3tiha liya... 3afaak": "actingcute",
	"Khalini n7el lik lbab": "mouse",
	"Had lpassage twil... b7al tri9 dyalk lkhadma!": "walking",
	"Ymkn khassna namchiw na9zo ltmak": "hihi",
	"Chufi chkoun l9it mna9ez m3aya... Rajli": "coffee",
	"9rabna nwasslo, mab9a walo": "walking",
	"Yak ssaliti l3cha!?": "emmm",
	"Salaaaaam Salma, finally kanchufek!": "chincrying",
	"Happy birthdaaaaay!": "butterflies",
	"Ach ban lik thazi rass dyali otharssi bih zaj...": "ok",
	"Darbi zaj machi lhwa": "really",
	"Wa9ila ma3arfach tchayeri...": "alone",
	"Aaaay, kunt 3arfek bghiti darbini mn ch7al hadi...": "mkhassma",
	"Salmaaaaa ghatharssi rassi huwa lwal...": "hem",
	"WEEEEEEEEEEEE!!!": "noice",
	"Happy birthday!!!": "butterflies",
	"Kima kabrat had jerda, tantiya kberti o ba9i ghatkabri...": "chincrying",
	"Chufi! Fin kandouz kaytla3 lward": "flouss",
	"Salma, had nhar dyalk. Khodi ra7tek": "hihi",
}

var sticker_name := ""
var clip: SpriteFrames
var frame := 0
var clock := 0.0

func set_line(text: String) -> void:
	sticker_name = ASSIGNMENTS.get(text, "")
	clip = GardenStickerLibrary.CLIPS.get(sticker_name)
	frame = 0
	clock = 0
	texture = clip.get_frame_texture(&"default", 0) if clip else null
	hide()

func advance(delta: float) -> void:
	if clip == null or not visible or get_tree().paused: return
	var count := clip.get_frame_count(&"default")
	if count <= 1: return
	clock += delta
	while clock >= clip.get_frame_duration(&"default", frame):
		clock -= clip.get_frame_duration(&"default", frame)
		frame = (frame + 1) % count
	texture = clip.get_frame_texture(&"default", frame)
