extends CharacterBody2D

const SPEED = 300.0

#Need to fiddle with these numbers to get the dodge to feel good
const DODGE_SPEED = 700.0 #Can think of this as how fast the dodge happens
const DODGE_TIME = 0.2 #Can think of this as the distance of the dodge
const DOUBLE_TAP_TIME = 0.3 #Can think of this as how quick the player needs to double tap to actually dodge

#These dont need to be edited 
var dodge_timer := 0.0
var is_dodging := false
var dodge_direction := 0
var last_tap_time_left := -1.0
var last_tap_time_right := -1.0

#Attacking Code (will probs have to do something similar with parrying and feint)
var isAttacking := false #Not sure if I want them to be able to attack while moving, (I dont want the to attack while dodging) 
var isFeinting := false
var isParrying := false
var isBlocking := false

func _physics_process(delta: float) -> void:
	# Attack
	if Input.is_action_just_pressed("attack_singleplayer"): #Need to add a timer or something so that the player has to wait for the animation to end before attacking again 
		isAttacking = true #This will likely have to be moved to when the windup of the attack animation finishes 
		$AttackArea/CollisionShape2D.disabled = false
		await get_tree().create_timer(0.5).timeout #this probs shouldnt be the solution, I'd want to tie the timer to the attack animation when I make one 
		$AttackArea/CollisionShape2D.disabled = true
		isAttacking = false #This should be tied to the animation, but since I dont have one, this will do

	#this should have a similar hitbox system as the attack, 
	#but instead of looking for a player hitbox it would look for the attack hitbox, so im gonna have to do funny layer stuff i think
	if Input.is_action_just_pressed("parry_singleplayer"):
		$ParryArea/CollisionShape2D.disabled = false
		await get_tree().create_timer(1).timeout
		$ParryArea/CollisionShape2D.disabled = true
		print("parry")

	#This shouldnt have any hitbox, it should just play a feint animation to bait the enemy 
	if Input.is_action_just_pressed("feint_singleplayer"):
		print("feint")



	# Handle dodge logic
	if is_dodging:
		dodge_timer -= delta
		velocity.x = dodge_direction * DODGE_SPEED
		if dodge_timer <= 0:
			is_dodging = false
	else:
		var direction := Input.get_axis("block_and_move_backwards_singleplayer", "move_forward_singleplayer")
		
		#Makes blocking true if the player is moving backwards
		isBlocking = Input.is_action_pressed("block_and_move_backwards_singleplayer") && direction < 0

		# Detect double-tap for dodge
		var current_time := Time.get_ticks_msec() / 1000.0
		
		#moving right
		if Input.is_action_just_pressed("move_forward_singleplayer"):
			if current_time - last_tap_time_right < DOUBLE_TAP_TIME:
				start_dodge(1)
			last_tap_time_right = current_time

		#moving left
		elif Input.is_action_just_pressed("block_and_move_backwards_singleplayer"):
			if current_time - last_tap_time_left < DOUBLE_TAP_TIME:
				start_dodge(-1)
			last_tap_time_left = current_time

		# Normal movement if not dodging
		if direction > 0 && isAttacking == false:
			velocity.x = direction * SPEED
		elif direction < 0 && isAttacking == false: #move backwards, currently moving backwards makes you move slower
			velocity.x = (direction * SPEED) / 2
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()


func start_dodge(dir: int) -> void:
	is_dodging = true
	dodge_timer = DODGE_TIME
	dodge_direction = dir
	print("Dodging in direction:", dir)
