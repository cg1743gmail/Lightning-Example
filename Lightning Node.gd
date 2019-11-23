extends Node2D

onready var Branch = preload("res://Branch.tscn")
onready var MAX_LIGHTNING_NODES = get_parent().get_node("Lightning Source").MAX_LIGHTNING_NODES

# product of inherited object conductivity and decay_rate
onready var heat = 1.0
onready var heat_decay_rate = 0.15

# controls how erratic
# the lightning looks
onready var radius = 45
# control how wide of a
# circumference you want your
# rayscan search area to be
onready var rayscan_fan = 45
# controls how many branches you will
# spawn per lightning node
onready var rayscan_step_length = 90

onready var neighbors = {}

func get_point_on_arc(angle):
	var x = position.x + radius * cos(angle)
	var y = position.y + radius * sin(angle)
	return Vector2(x, y)

func find_conductive_surface(source, destination):
	var raycast = RayCast2D.new()
	raycast.position = source
	raycast.cast_to = destination
	# cannot return x || y :(
	var collided = raycast.get_collider()
	if collided: return collided
	return raycast

func distance_to_ground_from_root():
	var distance = get_parent().get_node("Lightning Source").position.distance_to(
		get_parent().get_node("Ground").position
	)
	if distance: return distance
	return 1

func transfer_heat(angle):
	var distance_to_ground = position.distance_to(
		get_parent().get_node("Ground").position
	)
	return heat * (
		(distance_to_ground / distance_to_ground_from_root())
		* angle
		* randf()
	)

func create_branch(target, heat):
	var branch = Branch.instance()
	branch.width = heat * 5
	branch.add_point(target)
	branch.add_point(position)
	get_parent().add_child(branch)
	return branch

func adjust_target_space(pos):
	var target = pos + Vector2(rand_range(-50.0, 50.0), rand_range(-50.0, 50.0))
	return target

func find_neighbor_candidates():
	# always seek ground
	var angle_direction = rad2deg(
		get_parent().get_node("Ground").position.angle_to_point(position)
	)
	var start = angle_direction - rayscan_fan
	var end = angle_direction + rayscan_fan
	# find the furthest object out by
	# casting towards the current node
	# so our lightning can propagate
	# a reasonable distance
	var raycast_destination = position
	while start < end:
		var raycast_source = get_point_on_arc(deg2rad((start + angle_direction) / 2))
		var candidate = find_conductive_surface(
			raycast_source, raycast_destination
		)
		var target = adjust_target_space(candidate.position)
		var transfered_heat = transfer_heat(start)
		if (
			not at_ground(target)
			and get_parent().get_child_count() <= MAX_LIGHTNING_NODES
		):
			neighbors[[target, transfered_heat]] = create_branch(
				target, transfered_heat
			)
		start += rayscan_step_length
	return neighbors

func at_ground(pos):
	if pos.y > get_parent().get_node("Ground").position.y: return true
	return false

func on_screen():
	return true
#	return get_node("Notifier").is_on_screen()

func spawn():
	print_debug("spawned new lightning node")

func _ready():
	print("created new lightning")

func _process(delta):
	heat -= heat_decay_rate * (delta + randf())
	for n in neighbors:
		neighbors[n].set_width(heat * 5)

	if heat <= 0:
		for child in get_children():
			child.queue_free()
		for n in neighbors:
			neighbors[n].queue_free()
		queue_free()