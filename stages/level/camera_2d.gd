extends Camera2D

var ssCount = 1

func _ready():
	var dir = DirAccess.open("user://")
	dir.make_dir("screenshots")

	var dir2 = DirAccess.open("user://screenshots")
	for n in dir2.get_files():
		ssCount += 1

func screenshot():
	await RenderingServer.frame_post_draw

	var viewport = get_viewport()
	var image = viewport.get_texture().get_image()
	var path = "user://screenshots/screenshot_" + str(ssCount) + ".png"
	image.save_png(path)
	ssCount += 1
	print("Screenshot saved to: " + path)
