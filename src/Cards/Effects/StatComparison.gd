class_name StatComparison
extends Resource

@export_enum("current_health", "max_health", "current_damage",
		"max_damage", "current_shield", "max_shield", "current_speed", "max_speed"
		) var stat_to_compare: String
@export_enum("greater", "greater_equal", "equal", "less_equal", "less"
		) var comparison_method: String

func compare_units(unit1: Unit, unit2: Unit) -> bool:
	var stat1: int = unit1.get(stat_to_compare)
	var stat2: int = unit2.get(stat_to_compare)
	return(compare_numbers(stat1, stat2))
	
func compare_numbers(num1: int, num2: int) -> bool:
	match comparison_method:
		"greater":
			return(num1 > num2)
		"greater_equal":
			return(num1 >= num2)
		"equal":
			return(num1 == num2)
		"less_equal":
			return(num1 <= num2)
		"less":
			return(num1 < num2)
	return(false)
