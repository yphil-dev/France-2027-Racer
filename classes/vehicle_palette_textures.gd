class_name VehiclePaletteTextures
extends RefCounted

const BASE_PALETTE: Texture2D = preload("res://models/Textures/colormap.png")
const BODY_PAINT_RECT := Rect2i(192, 256, 64, 128)
const BODY_LUMINANCE_MIN: float = 161.8812 / 255.0
const BODY_LUMINANCE_MAX: float = 213.915 / 255.0

static var _textures_by_color: Dictionary = {}

static func get_texture(paint_color: Color) -> ImageTexture:
	var cache_key := paint_color.to_html(true)
	if _textures_by_color.has(cache_key):
		return _textures_by_color[cache_key] as ImageTexture

	var image := BASE_PALETTE.get_image()
	image.clear_mipmaps()
	_recolor_body_paint(image, paint_color)

	var texture := ImageTexture.create_from_image(image)
	_textures_by_color[cache_key] = texture
	return texture

static func _recolor_body_paint(image: Image, paint_color: Color) -> void:
	for y in range(BODY_PAINT_RECT.position.y, BODY_PAINT_RECT.end.y):
		for x in range(BODY_PAINT_RECT.position.x, BODY_PAINT_RECT.end.x):
			var source := image.get_pixel(x, y)
			var tone := inverse_lerp(
				BODY_LUMINANCE_MIN,
				BODY_LUMINANCE_MAX,
				source.get_luminance()
			)
			tone = clampf(tone, 0.0, 1.0)

			var shade_scale := lerpf(0.55, 1.0, tone)
			var neutral_highlight := lerpf(0.015, 0.12, tone * tone)
			var output := Color(
				clampf(paint_color.r * shade_scale + neutral_highlight, 0.0, 1.0),
				clampf(paint_color.g * shade_scale + neutral_highlight, 0.0, 1.0),
				clampf(paint_color.b * shade_scale + neutral_highlight, 0.0, 1.0),
				source.a
			)
			image.set_pixel(x, y, output)
