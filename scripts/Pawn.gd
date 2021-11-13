extends Node2D
class_name Pawn

enum CellType { PLAYER, NPC, ENEMY, INTERACTIVE, WALL }
#warning-ignore:unused_class_variable
export(CellType) var type = CellType.PLAYER
