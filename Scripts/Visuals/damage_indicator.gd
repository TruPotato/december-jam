extends Label

const MAXIMUM_LIFESPAN = 1
var vely = -50
var velx
var current_lifespan = MAXIMUM_LIFESPAN
var random_number = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	velx = random_number.randf_range(-30,30)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	position.y += vely*delta
	vely += 70*delta
	position.x += velx*delta
	current_lifespan-=delta
	if current_lifespan <= 0:
		queue_free()
	pass
