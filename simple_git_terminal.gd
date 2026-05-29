@tool
extends EditorPlugin

var dock: VBoxContainer
var output: TextEdit
var input: LineEdit

func _enter_tree() -> void:
	dock = VBoxContainer.new()
	dock.name = "Git Terminal"
	dock.size_flags_vertical = Control.SIZE_EXPAND_FILL

	output = TextEdit.new()
	output.editable = false
	output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dock.add_child(output)

	var row := HBoxContainer.new()
	dock.add_child(row)

	input = LineEdit.new()
	input.placeholder_text = "git status"
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(input)

	var clear_button := Button.new()
	clear_button.text = "Clear"
	row.add_child(clear_button)

	input.text_submitted.connect(_on_command_submitted)
	clear_button.pressed.connect(_on_clear_pressed)

	add_control_to_bottom_panel(dock, "Git Terminal")

	append_output("Simple Git Terminal ready.\n")


func _exit_tree() -> void:
	remove_control_from_bottom_panel(dock)
	dock.queue_free()


func _on_clear_pressed() -> void:
	output.clear()


func _on_command_submitted(command: String) -> void:
	command = command.strip_edges()

	if command.is_empty():
		return

	append_output("\n> " + command + "\n")
	input.clear()

	var parts := command.split(" ", false)

	if parts.is_empty():
		return

	if parts[0] != "git":
		append_output("Only git commands are allowed.\n")
		return

	var args := PackedStringArray(parts.slice(1))

	var result := []
	var exit_code := OS.execute("git", args, result, true)

	for line in result:
		append_output(str(line) + "\n")

	append_output("\n[Exit Code: %d]\n" % exit_code)


func append_output(text: String) -> void:
	output.text += text
	output.scroll_vertical = output.get_line_count()