extends Node

onready var floondler = get_tree().get_nodes_in_group("rewardkey")[0]
var reskin_delay = null
var _Player = null
var skinwalker_mode = false
var _hud = null


func _ready():
	floondler.connect("_reward", self, "_skin_steal")
	reskin_delay = floondler.delay

func _skin_steal():
	get_player()
	if _hud.using_chat and _hud:
		return 
	if Input.is_key_pressed(KEY_CONTROL):
		skinwalker_mode = not skinwalker_mode
		if skinwalker_mode:
			PlayerData._send_notification("Skinwalker mode enabled", 0)
		else:
			PlayerData._send_notification("Skinwalker mode disabled", 1)
		start_loop()
	else:
		_steal_closest()

func start_loop():
	if not skinwalker_mode: return
	while true:
		if not skinwalker_mode: break
		_steal_closest()
		yield(get_tree().create_timer(reskin_delay), "timeout")

func _steal_closest():
	if get_player():
		var victim_node = _get_nearest_player()
		if victim_node:
			var data = victim_node.cosmetic_data
			var size = victim_node.player_scale 
			_update_skin(data, size)
		

func _get_nearest_player() -> Node:
	if Network.PLAYING_OFFLINE or Network.STEAM_LOBBY_ID <= 0:
		print("Offline or no lobby. Returning null.")
		return null

	var local_player_loaded = false
	var local_player_ref = null
	for actor in get_tree().get_nodes_in_group("controlled_player"):
		if is_instance_valid(actor):
			local_player_loaded = true
			local_player_ref = actor
			break
	if not local_player_loaded:
		print("Local player not yet loaded. Returning null.")
		return null

	var all_players := []
	for actor in get_tree().get_nodes_in_group("actor"):
		if is_instance_valid(actor) and actor.actor_type == "player" and not actor.dead_actor:
			all_players.append(actor)

	if all_players.size() <= 1:
		print("No other actors aside from local player. Returning null.")
		return null

	var closest_actor: Node = null
	var min_distance: float = INF
	var local_pos = local_player_ref.global_transform.origin

	for actor in all_players:
		if actor == local_player_ref:
			continue

		var dist = local_pos.distance_to(actor.global_transform.origin)
		if dist < min_distance:
			min_distance = dist
			closest_actor = actor

	if closest_actor:
		print("Found closest actor: ", closest_actor, " distance: ", min_distance)
	else:
		print("Did not find any valid remote actor, returning null.")
		return null

	return closest_actor

func get_player():
	if not _Player:
		_Player = get_tree().current_scene.get_node_or_null("Viewport/main/entities/player")
		if not _Player:
			return false
	if not _hud:
		_hud = get_node_or_null("/root/playerhud")
		if not _hud:
			return false
	return true

func _update_skin(cos_data, _new_size):
	#_Player.player_scale = _new_size
	if cos_data == PlayerData.cosmetics_equipped: return 
	PlayerData.cosmetics_equipped = cos_data
	_Player._change_cosmetics()

func get_random_quote() -> String: #thanks to Al or AI or something idk ill impliment in spy mode coming soon
	var quotes = [
		"You disgust me!",
		"I appreciate your help.",
		"You got blood on my suit.",
		"Oh dear, I've made quite a mess.",
		"Pardon me.",
		"Surprise!",
		"Sorry to 'pop-in' unannounced.",
		"Peek-a-boo!",
		"I never really was on your side.",
		"Well, off to visit your mother!",
		"Nothing personal, I just had to shut you up.",
		"I dominate you, you sluggish simpleton.",
		"Dominated, you mush-mouthed freak!",
		"Good Lord! You fight like a woman!",
		"The world will thank me for this, you monster!",
		"Burn in hell, you mumbling abomination!",
		"Don't feel bad; you did a fine job tossing your little balls around!",
		"I've merely finished what your liver started!",
		"Oh, fat man, please! This is getting awkward!",
		"You disgust me, fat man!",
		"You died as you lived: morbidly obese!",
		"Howdy, pardner!",
		"Happy trails, laborer!",
		"Did I throw a wrench into your plans?",
		"Laughter really is the best medicine!",
		"Does it hurt when I do that? It does, doesn't it?!",
		"Boo! You repulsive bushman!",
		"You disgust me, filthy jar man!",
		"Go to hell, and take your cheap suit with you!",
		"We all knew you were a Spy!",
		"You are an amateur and a fool!",
		"Hello again, dumbbell!",
		"I'm back, you subnormal halfwit!",
		"Did you forget about me?!",
		"Ahem.",
		"Thank you, my friend.",
		"Was there ever any doubt?",
		"Cheers!",
		"Excellent!",
		"What did they expect?",
		"Splendid!",
		"Magnificent!",
		"The outcome was never really in doubt.",
		"Success!",
		"Too easy!",
		"And it is done!",
		"Ha-ha! Yes!",
		"A surprise to no one!",
		"Very nice!",
		"Hah. Much better.",
		"Gentlemen. I'm back!",
		"Voilà!",
		"I have returned!",
		"Eh, wasn't worth it.",
		"Gentlemen?",
		"Jealous?",
		"Hmm. Not bad.",
		"Tell no one of this.",
		"Today, I am a pony god!",
		"I am the prettiest unicorn!",
		"I claim this point for France, and the unicorns!"
	]
	return quotes[randi() % quotes.size()]
