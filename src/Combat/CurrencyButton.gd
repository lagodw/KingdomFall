extends Button

var currency_type: String
var amt: int

func setup():
	match currency_type:
		"gold":
			%Icon.texture = load("uid://k4fhlip7l4rd")
		"wood":
			%Icon.texture = load("uid://d1q5uhkg0mssk")
		"stone":
			%Icon.texture = load("uid://7pyqgwlmaabj")
	%Amount.text = str(amt)
	
