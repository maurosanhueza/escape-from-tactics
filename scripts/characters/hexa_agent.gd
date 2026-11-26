
extends Node2D

@export var tileMap: TileMapLayer
@export var offSet = Vector2(0, -6)

var isMoving = false


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("leftCLick"):
		_move()


func _move() -> void:
	if isMoving:
		return

	# Posición del mouse: global -> local del TileMap -> celda
	var mouseLocalPosition = tileMap.to_local(get_global_mouse_position())
	var targetTilePosition = tileMap.local_to_map(mouseLocalPosition)

	if not _has_tile(targetTilePosition):
		return

	# Posición del jugador: global -> local del TileMap -> celda
	var playerLocalPosition = tileMap.to_local(get_parent().global_position)
	var startTilePosition = tileMap.local_to_map(playerLocalPosition - offSet)

	if startTilePosition == targetTilePosition:
		return

	var movementArray = _get_route(startTilePosition, targetTilePosition)

	if movementArray.is_empty():
		return

	isMoving = true

	var currentTilePosition = startTilePosition

	for movement in movementArray:
		currentTilePosition += movement

		# Celda -> posición local -> posición global
		var targetLocalPosition = tileMap.map_to_local(currentTilePosition) + offSet
		var targetGlobalPosition = tileMap.to_global(targetLocalPosition)

		var tween = create_tween()
		tween.tween_property(
			get_parent(),
			"global_position",
			targetGlobalPosition,
			0.3
		)

		await tween.finished

	isMoving = false



func _get_route(startPosition: Vector2i, targetPosition: Vector2i) -> Array:
	var queue: Array[Vector2i] = [startPosition]
	var visited = {startPosition: true}
	var cameFrom = {}

	var queueIndex = 0
	var found = false

	# Buscar la ruta más corta
	while queueIndex < queue.size():
		var current = queue[queueIndex]
		queueIndex += 1

		if current == targetPosition:
			found = true
			break

		# Obtener los vecinos hexagonales reales del TileSet
		for neighbor in tileMap.get_surrounding_cells(current):
			if visited.has(neighbor):
				continue

			if not _has_tile(neighbor):
				continue

			visited[neighbor] = true
			cameFrom[neighbor] = current
			queue.append(neighbor)

	if not found:
		print("No existe una ruta hasta: ", targetPosition)
		return []

	# Reconstruir la ruta desde el destino al origen
	var path: Array[Vector2i] = []
	var current = targetPosition

	while current != startPosition:
		path.push_front(current - cameFrom[current])
		current = cameFrom[current]

	return path


func snap(vector: Vector2i) -> Vector2i:
	return Vector2i(
		sign(vector.x),
		sign(vector.y)
	)


func _has_tile(tilePosition: Vector2i) -> bool:
	var tileData = tileMap.get_cell_atlas_coords(tilePosition)
	return tileData != Vector2i(-1, -1)
