extends Node

func schedule(object, function_name, delay):
  var timer = Timer.new()
  timer.connect("timeout", Callable(object, function_name))
  timer.connect("timeout", Callable(timer, "queue_free"))
  timer.wait_time = delay
  get_tree().root.add_child.call_deferred(timer)
  timer.autostart = true
