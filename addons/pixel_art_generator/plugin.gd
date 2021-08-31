tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("GeneratedTexture", "Texture", load("src/generated_texture.gd"), preload("art/Object.svg"))


func _exit_tree():
	remove_custom_type("GeneratedTexture")
