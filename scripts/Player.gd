extends KinematicBody2D

export (int) var speed = 600

onready var target = position
var velocity = Vector2()
var tile_position = Vector2(1,0)  # hard-coded starting tile position
var tile_path = []  # of tile positions
var world_path = []  # of global coordinates
var dijkstra = true  # path finding algorithm, false for A*
var tile_map
var line_2d

# Called when the node enters the scene tree for the first time.
func _ready():
	tile_map = get_node("../TileMap")
	line_2d = get_node("../Line2D")


func _input(event):
	if event.is_action_pressed("click"):
		tile_path.clear()
		world_path.clear()
		var new_tile_pos = tile_map.world_to_hex_map(get_global_mouse_position())
		# don't find path to same tile or empty tiles
		if not tile_map.get_cellv(new_tile_pos) == TileMap.INVALID_CELL and not tile_position == new_tile_pos:
			var path_found = []
			if dijkstra:
				path_found = tile_map.find_path(tile_position, new_tile_pos)
				line_2d.default_color = Color.webmaroon
			else:
				path_found = tile_map.astar.get_point_path(tile_map.get_astar_node_index(str(tile_position)), tile_map.get_astar_node_index(str(new_tile_pos)))
				line_2d.default_color = Color.navyblue
			# keep both world and map position arrays in memory
			for node in path_found:
				tile_path.append(node)
				world_path.append(tile_map.get_cell_center(node))
			# draw line
			line_2d.points = PoolVector2Array(world_path)
			# remove first (current) position
			tile_path.remove(0)
			world_path.remove(0)
			# get next position to move to
			tile_position = tile_path.pop_front()
			target = world_path.pop_front()


func _physics_process(_delta):
	velocity = position.direction_to(target) * speed
	if position.distance_to(target) > 5:
		velocity = move_and_slide(velocity)
	else:
		# we've reached current destination, get the next one (if any left)
		if tile_path.size():
			tile_position = tile_path.pop_front()
			target = world_path.pop_front()


func _on_CheckBox_toggled(button_pressed):
	dijkstra = button_pressed
