extends Button

var building: BuildingResource

func _ready() -> void:
	if building:
		var texture: Texture = R.building_art.get_matching_resource(
			["**%s.png"%building.building_name])[0]
		$H/Icon.texture = texture
		$H/Name.text = building.building_name
		$H/Description.text = building.description
