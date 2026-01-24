extends StaticBody3D

func _on_interactable_interacted(user: Node) -> void:
	print("Button used by: ", user.name)
