extends Node2D

const STARTING_HEAT = 1.0
onready var LightningNode = preload("res://Lightning Node.tscn")

func new_lightning_node(pos, heat):
	print_debug(pos, heat)
	var node = LightningNode.instance()
	node.position = pos
	node.heat = heat
	return node

func spawn_lightning(pos):
	var lightning_queue = [new_lightning_node(pos, STARTING_HEAT)]
	print(lightning_queue)
	while not lightning_queue.empty():
		print(lightning_queue.size())
		var lightning_node = lightning_queue.pop_front()
		get_parent().add_child(lightning_node)
		print("creating new node")
		var candidates = lightning_node.find_neighbor_candidates()
		for c in candidates:
			lightning_queue.push_back(new_lightning_node(c[0], c[1]))
	print("lightning queue empty")

func _ready():
	randomize()

func _process(delta):
	position = get_viewport().get_mouse_position()

func _input(event):
	if event is InputEventMouseButton:
		call_deferred("spawn_lightning", event.position)