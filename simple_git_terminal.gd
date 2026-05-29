@tool
extends EditorPlugin

var dock: VBoxContainer
var output: RichTextLabel
var input: LineEdit
var commit_message_input: LineEdit
var branch_label: Label

var command_history: Array[String] = []
var history_index: int = -1


func _enter_tree() -> void:
	dock = VBoxContainer.new()
	dock.name = "Git Terminal"
	dock.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var toolbar := HBoxContainer.new()
	dock.add_child(toolbar)

	var status_button := Button.new()
	status_button.text = "Status"
	toolbar.add_child(status_button)

	var pull_button := Button.new()
	pull_button.text = "Pull"
	toolbar.add_child(pull_button)

	var push_button := Button.new()
	push_button.text = "Push"
	toolbar.add_child(push_button)

	var refresh_branch_button := Button.new()
	refresh_branch_button.text = "Refresh Branch"
	toolbar.add_child(refresh_branch_button)

	branch_label = Label.new()
	branch_label.text = "Branch: ?"
	toolbar.add_child(branch_label)

	output = RichTextLabel.new()
	output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	output.scroll_following = true
	dock.add_child(output)

	var commit_row := HBoxContainer.new()
	dock.add_child(commit_row)

	commit_message_input = LineEdit.new()
	commit_message_input.placeholder_text = "Commit message"
	commit_message_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	commit_row.add_child(commit_message_input)

	var commit_button := Button.new()
	commit_button.text = "Commit"
	commit_row.add_child(commit_button)

	var commit_push_button := Button.new()
	commit_push_button.text = "Commit & Push"
	commit_row.add_child(commit_push_button)

	var command_row := HBoxContainer.new()
	dock.add_child(command_row)

	input = LineEdit.new()
	input.placeholder_text = "Type any git command"
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	command_row.add_child(input)

	var clear_button := Button.new()
	clear_button.text = "Clear"
	command_row.add_child(clear_button)

	status_button.pressed.connect(func(): run_git_command("git status"))
	pull_button.pressed.connect(func(): run_git_command("git pull"))
	push_button.pressed.connect(func(): run_git_command("git push"))
	refresh_branch_button.pressed.connect(update_branch_label)

	commit_button.pressed.connect(commit_changes)
	commit_push_button.pressed.connect(commit_and_push)

	input.text_submitted.connect(_on_command_submitted)
	input.gui_input.connect(_on_input_gui_input)
	clear_button.pressed.connect(func(): output.clear())

	add_control_to_bottom_panel(dock, "Git Terminal")

	append_output("Simple Git Terminal ready.\n")
	update_branch_label()


func _exit_tree() -> void:
	remove_control_from_bottom_panel(dock)
	dock.queue_free()


func _on_command_submitted(command: String) -> void:
	input.clear()
	run_git_command(command)


func _on_input_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_UP:
			show_previous_command()
			input.accept_event()
		elif event.keycode == KEY_DOWN:
			show_next_command()
			input.accept_event()


func show_previous_command() -> void:
	if command_history.is_empty():
		return

	if history_index == -1:
		history_index = command_history.size() - 1
	elif history_index > 0:
		history_index -= 1

	input.text = command_history[history_index]
	input.caret_column = input.text.length()


func show_next_command() -> void:
	if command_history.is_empty():
		return

	if history_index == -1:
		return

	if history_index < command_history.size() - 1:
		history_index += 1
		input.text = command_history[history_index]
	else:
		history_index = -1
		input.text = ""

	input.caret_column = input.text.length()


func commit_changes() -> void:
	var message := commit_message_input.text.strip_edges()

	if message.is_empty():
		append_output("\nCommit message cannot be empty.\n")
		return

	run_git_command("git add .")
	run_git_command_with_args("git", PackedStringArray(["commit", "-m", message]))
	commit_message_input.clear()
	update_branch_label()


func commit_and_push() -> void:
	commit_changes()
	run_git_command("git push")


func update_branch_label() -> void:
	var result := []
	var exit_code := OS.execute("git", ["branch", "--show-current"], result, true)

	if exit_code == 0 and result.size() > 0:
		branch_label.text = "Branch: " + str(result[0]).strip_edges()
	else:
		branch_label.text = "Branch: ?"


func run_git_command(command: String) -> void:
	command = command.strip_edges()

	if command.is_empty():
		return

	add_to_history(command)
	append_command("\n> " + command + "\n")

	var parts := command.split(" ", false)

	if parts.is_empty():
		return

	if parts[0] != "git":
		append_output("Only git commands are allowed.\n")
		return

	var args := PackedStringArray(parts.slice(1))
	run_git_command_with_args("git", args)


func run_git_command_with_args(program: String, args: PackedStringArray) -> int:
	var result := []
	var exit_code := OS.execute(program, args, result, true)

	for line in result:
		var text := str(line)

		if "error" in text.to_lower():
			append_error(text + "\n")
		else:
			append_output(text + "\n")

	if exit_code == 0:
		append_success("\n[Success]\n")
	else:
		append_error("\n[Exit Code: %d]\n" % exit_code)
	
	return exit_code


func add_to_history(command: String) -> void:
	if command_history.size() > 0 and command_history[-1] == command:
		return

	command_history.append(command)
	history_index = -1


func append_output(text: String) -> void:
	output.append_text(text)


func append_command(text: String) -> void:
	output.append_text("[color=skyblue]" + text + "[/color]")


func append_success(text: String) -> void:
	output.append_text("[color=lightgreen]" + text + "[/color]")


func append_error(text: String) -> void:
	output.append_text("[color=tomato]" + text + "[/color]")


func append_info(text: String) -> void:
	output.append_text("[color=lightgray]" + text + "[/color]")