@tool
class_name EducationCatalog
extends Resource
## Todos los mundos educativos, en orden. Añadir un mundo o nivel = datos.

@export var worlds: Array[WorldDefinition] = []


func get_world(world_id: StringName) -> WorldDefinition:
	for world: WorldDefinition in worlds:
		if world != null and world.id == world_id:
			return world
	return null


func get_level(level_id: StringName) -> LevelDefinition:
	for world: WorldDefinition in worlds:
		for level: LevelDefinition in world.levels:
			if level != null and level.id == level_id:
				return level
	return null


func world_of(level_id: StringName) -> WorldDefinition:
	for world: WorldDefinition in worlds:
		for level: LevelDefinition in world.levels:
			if level != null and level.id == level_id:
				return world
	return null
