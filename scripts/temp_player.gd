extends CharacterBody2D


const SPEED = 300.0


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("attack_singleplayer"): #Need to add a timer or something so that the player has to wait for the animation to end before attacking again 
		print("attacking")
	
	if Input.is_action_just_pressed("parry_singleplayer"):
		print("parry")
		
	if Input.is_action_just_pressed("feint_singleplayer"):
		print("feint")

	#Moving left and right
	var direction := Input.get_axis("block_and_move_backwards_singleplayer", "move_forward_singleplayer")
	if direction > 0: #move forwards
		velocity.x = direction * SPEED 
	elif direction < 0: #move backwards, currently moving backwards makes you move slower, but also would likely need to add blocking feature here
		velocity.x = (direction * SPEED) / 2
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
