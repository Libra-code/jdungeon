extends Node2D

class_name JSynchronizer

signal attacked(target: String, damage: int)
signal got_hurt(from: String, hp: int, max_hp: int, damage: int)
signal healed(from: String, hp: int, max_hp: int, healing: int)
signal loop_animation_changed(animation: String, direction: Vector2)
signal died
signal experience_gained(from: String, current_exp: int, amount: int)

const INTERPOLATION_OFFSET = 0.1
const INTERPOLATION_INDEX = 2

@export var to_be_synced: CharacterBody2D

var watchers: Array[JPlayerBody2D] = []

var last_sync_timestamp: float = 0.0

var server_syncs_buffer: Array[Dictionary] = []
var server_network_buffer: Array[Dictionary] = []


func _physics_process(_delta):
	var timestamp = Time.get_unix_time_from_system()

	if J.is_server():
		for watcher in watchers:
			sync.rpc_id(watcher.peer_id, timestamp, to_be_synced.position, to_be_synced.velocity)
	else:
		calculate_position()
		check_server_network_buffer()


func calculate_position():
	var render_time = J.client.clock - INTERPOLATION_OFFSET

	while (
		server_syncs_buffer.size() > 2
		and render_time > server_syncs_buffer[INTERPOLATION_INDEX]["timestamp"]
	):
		server_syncs_buffer.remove_at(0)

	if server_syncs_buffer.size() > INTERPOLATION_INDEX:
		var interpolation_factor = calculate_interpolation_factor(render_time)
		to_be_synced.position = interpolate(interpolation_factor, "position")
		to_be_synced.velocity = interpolate(interpolation_factor, "velocity")
	elif (
		server_syncs_buffer.size() > INTERPOLATION_INDEX - 1
		and render_time > server_syncs_buffer[INTERPOLATION_INDEX - 1]["timestamp"]
	):
		var extrapolation_factor = calculate_extrapolation_factor(render_time)
		to_be_synced.position = extrapolate(extrapolation_factor, "position")
		to_be_synced.velocity = extrapolate(extrapolation_factor, "velocity")


func calculate_interpolation_factor(render_time: float) -> float:
	var interpolation_factor = (
		float(render_time - server_syncs_buffer[INTERPOLATION_INDEX - 1]["timestamp"])
		/ float(
			(
				server_syncs_buffer[INTERPOLATION_INDEX]["timestamp"]
				- server_syncs_buffer[INTERPOLATION_INDEX - 1]["timestamp"]
			)
		)
	)

	return interpolation_factor


func interpolate(interpolation_factor: float, parameter: String) -> Vector2:
	return server_syncs_buffer[INTERPOLATION_INDEX - 1][parameter].lerp(
		server_syncs_buffer[INTERPOLATION_INDEX][parameter], interpolation_factor
	)


func calculate_extrapolation_factor(render_time: float) -> float:
	var extrapolation_factor = (
		float(render_time - server_syncs_buffer[INTERPOLATION_INDEX - 2]["timestamp"])
		/ float(
			(
				server_syncs_buffer[INTERPOLATION_INDEX - 1]["timestamp"]
				- server_syncs_buffer[INTERPOLATION_INDEX - 2]["timestamp"]
			)
		)
	)

	return extrapolation_factor


func extrapolate(extrapolation_factor: float, parameter: String) -> Vector2:
	return server_syncs_buffer[INTERPOLATION_INDEX - 2][parameter].lerp(
		server_syncs_buffer[INTERPOLATION_INDEX - 1][parameter], extrapolation_factor
	)


func check_server_network_buffer():
	for i in range(server_network_buffer.size() - 1, -1, -1):
		var entry = server_network_buffer[i]
		if entry["timestamp"] <= J.client.clock:
			match server_network_buffer[i]["type"]:
				"attack":
					attacked.emit(entry["target"], entry["damage"])
				"hurt":
					got_hurt.emit(entry["from"], entry["hp"], entry["max_hp"], entry["damage"])
				"heal":
					healed.emit(entry["from"], entry["hp"], entry["max_hp"], entry["healing"])
				"loop_animation":
					loop_animation_changed.emit(entry["animation"], entry["direction"])
				"die":
					died.emit()
				"experience":
					experience_gained.emit(entry["from"], entry["current_exp"], entry["amount"])

			server_network_buffer.remove_at(i)


func sync_attack(target: String, damage: int):
	var timestamp = Time.get_unix_time_from_system()

	for watcher in watchers:
		attack.rpc_id(watcher.peer_id, timestamp, target, damage)

	attacked.emit(target, damage)


func sync_hurt(from: String, hp: int, max_hp: int, damage: int):
	var timestamp = Time.get_unix_time_from_system()

	for watcher in watchers:
		hurt.rpc_id(watcher.peer_id, timestamp, from, hp, max_hp, damage)

	got_hurt.emit(from, hp, max_hp, damage)


func sync_heal(from: String, hp: int, max_hp: int, healing: int):
	var timestamp = Time.get_unix_time_from_system()

	for watcher in watchers:
		heal.rpc_id(watcher.peer_id, timestamp, from, hp, max_hp, healing)

	healed.emit(from, hp, max_hp, healing)


func sync_loop_animation(animation: String, direction: Vector2):
	var timestamp = Time.get_unix_time_from_system()

	for watcher in watchers:
		loop_animation.rpc_id(watcher.peer_id, timestamp, animation, direction)

	loop_animation_changed.emit(animation, direction)


func sync_die():
	var timestamp = Time.get_unix_time_from_system()

	for watcher in watchers:
		die.rpc_id(watcher.peer_id, timestamp)

	died.emit()


func sync_experience(from: String, current_exp: int, amount: int):
	var timestamp = Time.get_unix_time_from_system()

	experience.rpc_id(to_be_synced.peer_id, timestamp, from, current_exp, amount)

	experience_gained.emit(from, current_exp, amount)


@rpc("call_remote", "authority", "unreliable")
func sync(timestamp: float, pos: Vector2, vec: Vector2):
	# Ignore older syncs
	if timestamp < last_sync_timestamp:
		return

	last_sync_timestamp = timestamp
	server_syncs_buffer.append({"timestamp": timestamp, "position": pos, "velocity": vec})


@rpc("call_remote", "authority", "reliable")
func attack(timestamp: float, target: String, damage: int):
	server_network_buffer.append(
		{"type": "attack", "timestamp": timestamp, "target": target, "damage": damage}
	)


@rpc("call_remote", "authority", "reliable")
func hurt(timestamp: float, from: String, hp: int, max_hp: int, damage: int):
	server_network_buffer.append(
		{
			"type": "hurt",
			"timestamp": timestamp,
			"from": from,
			"hp": hp,
			"max_hp": max_hp,
			"damage": damage
		}
	)


@rpc("call_remote", "authority", "reliable")
func heal(timestamp: float, from: String, hp: int, max_hp: int, healing: int):
	server_network_buffer.append(
		{
			"type": "heal",
			"timestamp": timestamp,
			"from": from,
			"hp": hp,
			"max_hp": max_hp,
			"healing": healing
		}
	)


@rpc("call_remote", "authority", "reliable")
func loop_animation(timestamp: float, animation: String, direction: Vector2):
	server_network_buffer.append(
		{
			"type": "loop_animation",
			"timestamp": timestamp,
			"animation": animation,
			"direction": direction
		}
	)


@rpc("call_remote", "authority", "reliable") func die(timestamp: float):
	server_network_buffer.append({"type": "die", "timestamp": timestamp})


@rpc("call_remote", "authority", "reliable")
func experience(timestamp: float, from: String, current_exp: int, amount: int):
	server_network_buffer.append(
		{
			"type": "experience",
			"timestamp": timestamp,
			"from": from,
			"current_exp": current_exp,
			"amount": amount
		}
	)
