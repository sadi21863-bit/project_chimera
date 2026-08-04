extends Node
class_name BeehaveNode

enum Status { SUCCESS, FAILURE, RUNNING }

var actor: Node
var blackboard: Blackboard


func tick(_delta: float) -> Status:
	return Status.FAILURE


func get_child_nodes() -> Array:
	var nodes: Array = []
	for child in get_children():
		if child is BeehaveNode:
			nodes.append(child)
	return nodes
