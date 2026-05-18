extends Node

var last_window_mode = DisplayServer.WINDOW_MODE_WINDOWED

func schedule(object, function_name, delay):
	var timer = Timer.new()
	timer.connect("timeout", Callable(object, function_name))
	timer.connect("timeout", Callable(timer, "queue_free"))
	timer.wait_time = delay
	get_tree().root.add_child.call_deferred(timer)
	timer.autostart = true

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("FullScreen"):
		if get_window().mode == Window.MODE_FULLSCREEN:
			DisplayServer.window_set_mode(last_window_mode)
		else:
			last_window_mode = get_window().mode
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN) 
