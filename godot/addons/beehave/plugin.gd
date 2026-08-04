@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_custom_type("BehaviorTree", "Node", preload("nodes/beehave_tree.gd"), null)
	add_custom_type("Selector", "Node", preload("nodes/composites/selector.gd"), null)
	add_custom_type("Sequence", "Node", preload("nodes/composites/sequence.gd"), null)
	add_custom_type("ActionLeaf", "Node", preload("nodes/leaves/action_leaf.gd"), null)


func _exit_tree() -> void:
	remove_custom_type("BehaviorTree")
	remove_custom_type("Selector")
	remove_custom_type("Sequence")
	remove_custom_type("ActionLeaf")
