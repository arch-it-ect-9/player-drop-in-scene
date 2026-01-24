extends Node
class_name Interactable

enum InteractionType {
	USE,
	PICKUP,
	EXAMINE,
	CLOSE,
	OPEN
}

signal interacted(user: Node)

@export var enabled := true
@export var prompt_override := ""
@export var interaction_type := InteractionType.USE

func interact(user: Node) -> void:
	if not enabled:
		return
	interacted.emit(user)


func get_prompt_text() -> String:
	var p := prompt_override.strip_edges()
	if p != "":
		return p

	match interaction_type:
		InteractionType.USE:
			return "Use"
		InteractionType.PICKUP:
			return "Pick Up"
		InteractionType.EXAMINE:
			return "Examine"
		InteractionType.CLOSE:
			return "Close"
		InteractionType.OPEN:
			return "Open"

	return "Use"


func get_hud_text(key_hint: String = "Press E") -> String:
	# Produces: "Use (Press E)" etc.
	return "%s (%s)" % [get_prompt_text(), key_hint]
