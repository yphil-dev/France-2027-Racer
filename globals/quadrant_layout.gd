class_name QuadrantLayout
extends RefCounted

const CARD_WIDTH_RATIO: float = 0.34
const CARD_MAX_HEIGHT_RATIO: float = 0.34
const CARD_ASPECT_RATIO: float = 16.0 / 9.0
const HORIZONTAL_GAP: float = 32.0
const VERTICAL_GAP: float = 24.0

static func get_card_size(viewport_size: Vector2) -> Vector2:
	var card_width := viewport_size.x * CARD_WIDTH_RATIO
	var card_height := card_width / CARD_ASPECT_RATIO
	var max_height := viewport_size.y * CARD_MAX_HEIGHT_RATIO

	if card_height > max_height:
		card_height = max_height
		card_width = card_height * CARD_ASPECT_RATIO

	return Vector2(card_width, card_height)

static func get_grid_size(viewport_size: Vector2) -> Vector2:
	var card_size := get_card_size(viewport_size)
	return Vector2(
		card_size.x * 2.0 + HORIZONTAL_GAP,
		card_size.y * 2.0 + VERTICAL_GAP
	)

static func get_rects(viewport_size: Vector2) -> Array[Rect2]:
	var card_size := get_card_size(viewport_size)
	var grid_size := get_grid_size(viewport_size)
	var origin := (viewport_size - grid_size) * 0.5
	var rects: Array[Rect2] = []

	for index in 4:
		var column := index % 2
		var row := int(index / 2)
		var position := origin + Vector2(
			column * (card_size.x + HORIZONTAL_GAP),
			row * (card_size.y + VERTICAL_GAP)
		)
		rects.append(Rect2(position, card_size))

	return rects
