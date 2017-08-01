extends Node
var position = Vector2()
var size = Vector2()
var Cells = []

func setup(p,s):
	position = p
	size = s
	for i in range (0,size.x):
		for j in range (0,size.y):
			Cells.append(Vector2(position.x+i, position.y+j))
		pass

func get_area():
	return Cells.size()
