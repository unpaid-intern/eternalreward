extends Node


onready var _Spawn = preload("res://mods/PurplePuppy-Your_Eternal_Reward/reward.gd").new()

var KeybindsAPI = null
var debug = false
var key_states = {}
var in_game = false
var delay = null

signal _reward

var prefix = "[Reward Config Handler] "

var config_data = {} 

var default_config_data = {
	"reward": 92, 
	"new_skin_delay_seconds": 1.5, 
}

func _ready():
	KeybindsAPI = get_node_or_null("/root/BlueberryWolfiAPIs/KeybindsAPI")
	load_or_create_config()
	print("[Reward] Main script is loaded successfully!")
	add_to_group("rewardkey")
	check_updates()
	if KeybindsAPI:
		var reward_signal = KeybindsAPI.register_keybind({
			"action_name": "reward", 
			"title": "Steal Skin", 
			"key": config_data["reward"], 
		})

		KeybindsAPI.connect(reward_signal, self, "_reward")
		KeybindsAPI.connect("_keybind_changed", self, "_on_keybind_changed")
	else:
		print("[Stamps] KeybindsAPI not found! Falling back to direct key listening.")
		reset_config()
	delay = config_data["new_skin_delay_seconds"]
	add_child(_Spawn)
	

func check_key_presses():
		
	if Input.is_key_pressed(config_data["reward"]):
		handle_reward()
	else:
		key_states["reward"] = false


func handle_reward():
	if not key_states.has("reward"):
		key_states["reward"] = false

	if not key_states["reward"]:
		key_states["reward"] = true
		_reward()


func _get_gdweave_dir()->String:
	if debug:
		return "C:/Users/puppy/Desktop/wuohe"
	else:
		var game_directory: = OS.get_executable_path().get_base_dir()
		var folder_override: String
		var final_directory: String
		for argument in OS.get_cmdline_args():
			if argument.begins_with("--gdweave-folder-override="):
				folder_override = argument.trim_prefix("--gdweave-folder-override=").replace("\\", "/")
		if folder_override:
			var relative_path: = game_directory.plus_file(folder_override)
			var is_relative: = not ":" in relative_path and Directory.new().file_exists(relative_path)
			final_directory = relative_path if is_relative else folder_override
		else:
			final_directory = game_directory.plus_file("GDWeave")
		return final_directory
		
	
func _get_config_location()->String:
	var gdweave_dir = _get_gdweave_dir()
	var config_path = gdweave_dir.plus_file("configs").plus_file("PurplePuppy.Your_Eternal_Reward.json")
	return config_path
	
func _get_config_dir()->String:
	var gdweave_dir = _get_gdweave_dir()
	var config_path = gdweave_dir.plus_file("configs")
	return config_path



func load_or_create_config():
	var config_path = _get_config_location()
	var dir = Directory.new()
	
	
	var config_dir = _get_config_dir()
	if not dir.dir_exists(config_dir):
		if dir.make_dir_recursive(config_dir) == OK:
			print(prefix, "Created config directory at: ", config_dir)
		else:
			print(prefix, "Failed to create config directory at: ", config_dir)
			return 
	
	var file = File.new()
	
	if file.file_exists(config_path):
		
		if file.open(config_path, File.READ) == OK:
			var data = file.get_as_text()
			file.close()
			
			
			var json_result = JSON.parse(data)
			if json_result.error == OK and typeof(json_result.result) == TYPE_DICTIONARY:
				config_data = json_result.result
				print(prefix, "Config loaded successfully: ", config_data)
				if config_data.size() != 2:
					print(prefix, "Invalid Config Size, Resetting")
					reset_config()
				return 
			else:
				print(prefix, "Failed to parse config file. Using default config.")
				config_data = default_config_data.duplicate()
		else:
			print(prefix, "Failed to open config file for reading. Using default config.")
			config_data = default_config_data.duplicate()
	else:
		
		config_data = default_config_data.duplicate()
		print(prefix, "Config file created with default values at: ", config_path)
	
	save_config()

func reset_config():
	var config_path = _get_config_location()
	var file = File.new()
	
	
	config_data = default_config_data.duplicate()
	
	
	if file.open(config_path, File.WRITE) == OK:
		var json_string = JSON.print(config_data, "	")
		file.store_string(json_string)
		file.close()
		print(prefix, "Configuration reset to default values.")
	else:
		print(prefix, "Failed to open config file for writing during reset.")
		


func save_config():
	var config_path = _get_config_location()
	var file = File.new()

	
	if file.open(config_path, File.WRITE) == OK:
		
		var json_string = JSON.print(config_data, "	")
		file.store_string(json_string)
		file.close()
		print(prefix, "Config saved successfully to: ", config_path)
	else:
		print(prefix, "Failed to open config file for writing: ", config_path)


func get_action_scancode(action_name: String)->int:
	if config_data.has(action_name):
		return config_data[action_name]
	else:
		print(prefix, "Action name not found: ", action_name)
		return - 1

func check_updates():
	var was_player_present = false
	var config_path = _get_config_location()
	var file = File.new()

	while true:
		yield (get_tree().create_timer(2.0), "timeout")
		
		var current_scene = get_tree().current_scene
		if current_scene == null:
			print(prefix, "No current scene found.")
			continue

		var _Player = current_scene.get_node_or_null("Viewport/main/entities/player")
		if _Player == null:
			in_game = false
			if was_player_present:
				if _Spawn:
					_Spawn.queue_free()
				_Spawn = preload("res://mods/PurplePuppy-Your_Eternal_Reward/reward.gd").new()
				add_child(_Spawn)
				print(prefix, "Player was removed. Respawned _Spawn node.")
			was_player_present = false
		else:
			if not was_player_present:
				send_keybind()
			was_player_present = true
			in_game = true



func handle_walky_talky_webfish(value):

	var handlers = {
		"get the canvas data bozo": "handle_get_data"
	}

	if handlers.has(value):
		call(handlers[value])
	else:
		var message = "dude idk what " + str(value) + " means"
		PlayerData._send_notification(message, 1)


func handle_get_data():
	emit_signal("get_data")
	print(prefix, "get_data signal emitted.")



func _on_keybind_changed(action_name: String, title: String, input_event: InputEvent)->void :
	if action_name == "":
		return 
	if input_event is InputEventKey:
		var scancode = input_event.scancode
		print(prefix, "Action Name:", action_name, "Key Scancode:", scancode)
		
		if config_data.has(action_name):
			config_data[action_name] = scancode
			save_config()
		else:
			print(prefix, "Action name not found in config: ", action_name)
	else:
		print(prefix, "Input event is not a key event.")


func _reward():
	emit_signal("_reward")
	


func send_keybind():
	var key_name = OS.get_scancode_string(config_data["reward"])
	if key_name == "":
		return 
	yield (get_tree().create_timer(2), "timeout")
	PlayerData._send_notification("Press " + key_name + " to become a skinwalker :3", 0)
