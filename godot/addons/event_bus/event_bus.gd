extends Node

## Global event bus for decoupled communication.

var _listeners: Dictionary = {}


func subscribe(event_name: String, callback: Callable) -> void:
	if not _listeners.has(event_name):
		_listeners[event_name] = []
	_listeners[event_name].append(callback)


func unsubscribe(event_name: String, callback: Callable) -> void:
	if _listeners.has(event_name):
		_listeners[event_name].erase(callback)


func emit_event(event_name: String, data: Variant = null) -> void:
	if not _listeners.has(event_name):
		return
	for callback: Callable in _listeners[event_name]:
		callback.call(data)
