class_name Palette
extends RefCounted

const NIGHT := Color("2E3A5C")
const NIGHT_DEEP := Color("232D49")
const NIGHT_SOFT := Color("3B4A72")
const SHEET := Color("F6EEDF")
const SHEET_LINE := Color("E6DAC4")
const WOOD := Color("C99B6B")
const WOOD_DARK := Color("A87C50")
const WOOD_LIGHT := Color("DDB488")
const GLOW := Color("FFD98A")
const INK := Color("4A3F4F")
const CREAM := Color("FFF8EC")
const BLUSH := Color("F08C8C")
const OK := Color("7FBF9F")
const NOT_OK := Color("E9837E")

const ANIMALS: Array[String] = ["bunny", "bear", "fox", "elephant", "lamb", "cat"]
const COLOURS: Array[String] = ["rose", "sage", "lavender", "honey", "sky", "biscuit"]
const FABRICS: Array[String] = ["gingham", "dots", "stripes", "fleece"]

const FABRIC_COLOURS := {
	"rose": Color("F2A7A0"),
	"sage": Color("A8CFC0"),
	"lavender": Color("B9B4E0"),
	"honey": Color("F4CF86"),
	"sky": Color("9CC4E4"),
	"biscuit": Color("E3B592"),
}


static func fabric(colour_name: String) -> Color:
	return FABRIC_COLOURS.get(colour_name, FABRIC_COLOURS.rose)
