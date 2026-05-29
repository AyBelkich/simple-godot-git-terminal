@tool
extends EditorPlugin

var dock: VBoxContainer
var output: TextEdit
var input: LineEdit

func _enter_tree() -> void:
	dock = VBoxContainer.new()
	dock.name = "Git Terminal"

	output = TextEdit.new()
	output.editable = false
	output.custom_minimum_size = Vector2(0, 220)
	dock.add_child(output)

	input = LineEdit.new()
	input.placeholder_text = "git status"
	dock.add_child(input)

	input.text_submitted.connect(_on_command_submitted)

	add_control_to_bottom_panel(dock, "Git Terminal")

	output.text = "Simple Git Terminal ready.\n"


func _exit_tree() -> void:
	remove_control_from_bottom_panel(dock)
	dock.queue_free()


func _on_command_submitted(command: String) -> void:
	command = command.strip_edges()
	if command == "":
		return

	input.clear()
	output.text += "\n> " + command + "\n"

	var parts := command.split(" ", false)

	if parts[0] != "git":
		output.text += "Only git commands are allowed for now.\n"
		return

	var args := parts.slice(1)
	var result: Array = []

	var exit_code := OS.execute("git", args, result, true)

	for line in result:
		output.text += str(line) + "\n"

	output.text += "\n[exit code: %s]\n" % exit_code