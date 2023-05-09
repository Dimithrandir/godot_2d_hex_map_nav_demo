extends TileMap

# hard coded TileMap size
var map_size = Vector2(9, 6)
# graph as a simple dictionary
var map_graph = {}
# graph as an instance of Godot's AStar2D class
var astar


# Called when the node enters the scene tree for the first time.
func _ready():
	_create_graphs()


func _input(event):
	# update labels
	get_node("../WorldPositionLabel").text = str(get_global_mouse_position())
	get_node("../TilePositionLabel").text = str(world_to_hex_map(get_global_mouse_position()))


# Dynamically create the graphs for the TileMap with given map_size
# both as a simple dictionary with cells/nodes as keys and list of neighbors as values
# and as an instance of Godot's own AStar2D implementation
func _create_graphs():
	# find all valid (non-empty) cells
	var valid_cells = []
	for j in range(-1, map_size.y):
		for i in range(map_size.x):
			var cell = Vector2(i, j)
			if not get_cellv(cell) == TileMap.INVALID_CELL:
				valid_cells.append(cell)
	# find all valid neighbors for each valid cell
	for cell in valid_cells:
		# key is string, value is array of strings
		var node = str(cell)
		map_graph[node] = []
		var neighbor_cell = Vector2()
		# go through all neighboring cells, offset taken into account
		# add as neighbor if they're valid tiles
		for i in range(-1, 2):
			for j in range(0, 2) if int(cell.x) % 2 else range(-1, 1):
				neighbor_cell = cell + Vector2(i, j)
				if (j or i) and not get_cellv(neighbor_cell) == TileMap.INVALID_CELL:
					map_graph[node].append(str(neighbor_cell))
		# the one extra tile that we missed in the loops
		neighbor_cell = cell + (Vector2(0, -1) if int(cell.x) % 2 else Vector2(0, 1))
		if not get_cellv(neighbor_cell) == TileMap.INVALID_CELL:
			map_graph[node].append(str(neighbor_cell))
	# initialize astar
	astar = AStar2D.new()
	for id in range(map_graph.keys().size()):
		astar.add_point(id + 1, str_to_vector(map_graph.keys()[id]))
	for node in map_graph.keys():
		for neighbor in map_graph[node]:
			astar.connect_points(get_astar_node_index(node), get_astar_node_index(neighbor))


# Djikstra
func find_path(from : Vector2, to : Vector2) -> Array:
	var start = str(from)
	var end = str(to)

	var distances = {}
	var predecessors = {}
	var unvisited = []
	
	for node in map_graph:
		distances[node] = INF
		predecessors[node] = null
		unvisited.append(node)
	distances[start] = 0
		
	while unvisited:
		var current = unvisited[0]
		for node in unvisited:
			if distances[node] < distances[current]:
				current = node
		if current == end:
			break
		unvisited.erase(current)
		
		for neighbor in map_graph[current]:
			if neighbor in unvisited:
				var alt = distances[current] + 1
				if alt < distances[neighbor]:
					distances[neighbor] = alt
					predecessors[neighbor] = current
	
	var path = []
	var current = end
	if predecessors[current] or current == start:
		while current:
			path.insert(0, str_to_vector(current))
			current = predecessors[current]
	
	return path


# Get real tile position for given world position,
# adjusted for hexagonal tile maps
func world_to_hex_map(pos : Vector2) -> Vector2:
	pos = to_local(pos)
	var tile_map_pos = world_to_map(pos)
	var tile_world_pos = map_to_world(tile_map_pos)
	# relative to the tile's top-left corner
	var relative_pos = Vector2(pos.x - tile_world_pos.x, pos.y - tile_world_pos.y)
	# actual tile map position
	var real_tile_map_pos = tile_map_pos
	# distance from tile top-left corner to hex top right corner
	var temp_l = cell_size.x - tan(PI/6) * cell_size.y / 4
	# top-left
	if relative_pos.y <= - tan(PI/3) * relative_pos.x + cell_size.y / 4:
		real_tile_map_pos.x -= 1
		if not int(tile_map_pos.x) % 2:
			real_tile_map_pos.y -= 1
	# bottom-left
	elif relative_pos.y >= tan(PI/3) * relative_pos.x + 3 * cell_size.y / 4:
		real_tile_map_pos.x -= 1
		if int(tile_map_pos.x) % 2:
			real_tile_map_pos.y += 1
	# top-right
	elif relative_pos.y <= tan(PI/3) * relative_pos.x - tan(PI/3) * temp_l:
		real_tile_map_pos.x += 1
		if not int(tile_map_pos.x) % 2:
			real_tile_map_pos.y -= 1
	# bottom-right
	elif relative_pos.y >= - tan(PI/3) * relative_pos.x + tan(PI/3) * temp_l + cell_size.y:
		real_tile_map_pos.x += 1
		if int(tile_map_pos.x) % 2:
			real_tile_map_pos.y += 1

	return real_tile_map_pos


# Get world position of center of given cell
func get_cell_center(pos : Vector2) -> Vector2:
	var tile_world_pos = map_to_world(pos)
	return Vector2(tile_world_pos.x + cell_size.x / 2, tile_world_pos.y + cell_size.y / 2)


func str_to_vector(string : String) -> Vector2:
	var splitted = string.split(",")
	return Vector2(splitted[0].trim_prefix("("), splitted[1].trim_suffix(")"))


func get_astar_node_index(node : String) -> int:
	return map_graph.keys().find(node) + 1
