class_name Path
extends Resource

@export var forward_direction: Vector2
@export var events: Array[Event]

@export var event_dict: Dictionary[Vector2, Event] 
@export var connection_dict: Dictionary[Vector2, Array]

func setup(segments: int, reward_events: Array[Event], combat_event: Event):
	for i in segments:
		var tier = i + 1
		var combat_pos = forward_direction * (i * 2 + 1)
		# give paths extra room at start so they aren't too crowded
		combat_pos += forward_direction
		place_event(combat_pos, combat_event, tier)
		
		var ortho = forward_direction.orthogonal()
		var reward_pos_1 = combat_pos + forward_direction + ortho
		var reward_pos_2 = combat_pos + forward_direction - ortho
		
		var chosen_rewards = reward_events.duplicate()
		chosen_rewards.shuffle()
		var reward_1 = chosen_rewards[0]
		var reward_2 = chosen_rewards[1]
		
		place_event(reward_pos_1, reward_1, tier)
		place_event(reward_pos_2, reward_2, tier)
		
		if i == 0:
			connection_dict[Vector2.ZERO] = [combat_pos]
		connection_dict[combat_pos] = [reward_pos_1, reward_pos_2]
		if i < segments - 1:
			connection_dict[reward_pos_1] = [forward_direction * (i * 2 + 3 + 1)]
			connection_dict[reward_pos_2] = [forward_direction * (i * 2 + 3 + 1)]

func place_event(point: Vector2, specific_event: Event, tier: int) -> void:
	if not specific_event:
		return
	var event: Event = specific_event.dupe()
	event.spot = point
	event.tier = tier
	event.setup()
	event_dict[point] = event
