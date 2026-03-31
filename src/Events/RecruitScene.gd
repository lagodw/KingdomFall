extends Control

func _ready() -> void:
	var label: String = tr("KEY_Units")
	if Bus.map.current_location.num_reward_choices == 1:
		label = tr("KEY_Unit")
	$CardChoicePanel.setup(Bus.map.current_location.unit_options,
		Bus.map.current_location.num_reward_choices, label)
