tool
class_name GeneratedTexture
extends ImageTexture

enum Mirroring {
	NONE = 0,
	HORIZONTAL = 1,
	VERTICAL = 2,
	FULL = 3
}

enum Siding {
	NONE = 0,
	NESW = 1,
	DIAGONAL = 2,
	FULL = 3
}

export(int) var _layer_width: int = 32
export(Texture) var _texture: Texture = null
export(Siding) var _outline:int = Siding.NONE
export(Siding) var _remove_stray_pixels:int = Siding.NONE
export(Mirroring) var _mirroring:int = Mirroring.NONE
export(bool) var _outline_pixel: bool
export(Dictionary) var _color_mapping: Dictionary setget set_color_mapping

export(bool) var generate_preview setget generate_texture

var _color_map_index_holder: Dictionary

var _random:RandomNumberGenerator

func _init():
	_random = RandomNumberGenerator.new()
	_random.randomize()


# Removes floating point error
func set_color_mapping(value: Dictionary):
	for k in value.keys():
		# Somehow this is for inspector, the other one is for 2nd time this script runs for program
		if (typeof(k) == TYPE_COLOR):
			_color_mapping[k.to_rgba64()] = value[k]
		else:
			_color_mapping[k] = value[k]


func generate_texture(__) -> void:
	create_from_image(self.generate(), 0)


func generate() -> Image:
	if _texture == null:
		return null
	
	var texture_size:Vector2 = _texture.get_size()
	var layers:int = texture_size.x / _layer_width - 1
	var final_image: Image = Image.new()
	var input_image:Image = _texture.get_data()
	var start_pixel:int = 0
	
	if _outline_pixel:
		start_pixel = 1
		final_image.create(_layer_width + 2, texture_size.y + 2, false, Image.FORMAT_RGBA8)
	else:
		final_image.create(_layer_width, texture_size.y, false, Image.FORMAT_RGBA8)
	
	var generated_width = _layer_width
	var generated_height = texture_size.y
	
	if _mirroring & Mirroring.HORIZONTAL:
		generated_width = floor((generated_width + 1) / 2)
	
	if _mirroring & Mirroring.VERTICAL:
		generated_height = floor((generated_height + 1) / 2)
	
	input_image.lock()
	final_image.lock()
	for layer in range(layers + 1):
		for x in range(generated_width):
			for y in range(generated_height):
				var chance:int = _random.randi_range(1, 255)
				var current_pixel: Color = input_image.get_pixel(layer * _layer_width + x, y)
				if chance <= current_pixel.a8:
					var new_pixel: Color = _choose_new_color(current_pixel)
					final_image.set_pixel(x + start_pixel, y + start_pixel, new_pixel)
					
					if _mirroring & Mirroring.HORIZONTAL:
						final_image.set_pixel(_layer_width - x - 1 + start_pixel, y + start_pixel, new_pixel)
					
					if _mirroring & Mirroring.VERTICAL:
						final_image.set_pixel(x + start_pixel, texture_size.y - y - 1 + start_pixel, new_pixel)
						
					if _mirroring == Mirroring.FULL:
						final_image.set_pixel(_layer_width - x - 1 + start_pixel, texture_size.y - y - 1 + start_pixel, new_pixel)
	
	_color_map_index_holder.clear()
	
	input_image.unlock()
	
	_remove_stray_pixels(final_image)
		
	_add_outline(final_image)
		
	final_image.unlock()
	
	return final_image


func _choose_new_color(pixel:Color) -> Color:
	# Strip alpha channel
	var needle = Color(pixel.r, pixel.g, pixel.b)
	var needle64 = needle.to_rgba64()
	# Test with removing floating point error
	if needle64 in _color_mapping:
		# Either Array or Color
		var mapped_color = _color_mapping.get(needle64)
		if typeof(mapped_color) == TYPE_ARRAY:
			# If it's an array, choose color randomly
			return mapped_color[_get_color_index(mapped_color)]
		return mapped_color
	return needle


func _get_color_index(colors:Array, random:bool = false) -> int:
	# Frontend is missing for randomising colors
	if random:
		return _random.randi_range(0, colors.size() - 1)
	
	if not colors in _color_map_index_holder:
		_color_map_index_holder[colors] = _random.randi_range(0, colors.size() - 1)
	
	return _color_map_index_holder.get(colors)


func _remove_stray_pixels(locked_image:Image) -> void:
	if _remove_stray_pixels == Siding.NONE:
		return
	
	var sides = _prepare_sides(_remove_stray_pixels)
	
	for x in range(locked_image.get_width()):
		for y in range(locked_image.get_height()):
			var current_pixel = locked_image.get_pixel(x, y)
			if current_pixel.a != 0:
				var should_be_removed:bool = true
				for side in sides:
					var new_x = x + side[0]
					var new_y = y + side[1]
					if not _is_in_bounds(new_x, new_y, locked_image.get_width(), locked_image.get_height()):
						continue
					var new_pixel = locked_image.get_pixel(new_x, new_y)
					if (new_pixel.a != 0):
						should_be_removed = false
						break
				if should_be_removed:
					locked_image.set_pixel(x, y, Color.transparent)


func _add_outline(locked_image:Image) -> void:
	if _outline == Siding.NONE:
		return
	
	var sides = _prepare_sides(_outline)
	
	var pixels = []
	for x in range(locked_image.get_width()):
		for y in range(locked_image.get_height()):
			_outline_pixel(locked_image, x, y, sides, pixels)
	
	for pixel in pixels:
		locked_image.set_pixel(pixel[0], pixel[1], Color.black)


func _outline_pixel(locked_image:Image, x:int, y:int, sides:Array, pixels_array:Array) -> void:
	var pixel = locked_image.get_pixel(x, y)
	if pixel.a != 0:
		for side in sides:
			var new_x = x + side[0]
			var new_y = y + side[1]
			if _is_in_bounds(new_x, new_y, locked_image.get_width(), locked_image.get_height()):
				if locked_image.get_pixel(new_x, new_y).a == 0:
					pixels_array.append([new_x, new_y])


func _is_in_bounds(x:int, y:int, x_bound:int, y_bound:int) -> bool:
	if x < 0:
		return false
	if y < 0:
		return false
	if x >= x_bound:
		return false
	if y >= y_bound:
		return false
	return true


func _prepare_sides(determining_variable:int) -> Array:
	var sides = []
	if determining_variable & Siding.NESW:
		sides.append_array([[1, 0], [-1, 0], [0, 1], [0, -1]])
	
	if determining_variable & Siding.DIAGONAL:
		sides.append_array([[1, 1], [1, -1], [-1, 1], [-1, -1]])
	
	return sides
