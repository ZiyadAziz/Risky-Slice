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
var isAttacking := false 
var isFeinting := false
var isParrying := false
var isBlocking := false

#Animations
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# Attack
	if Input.is_action_just_pressed("attack_singleplayer") && !(isAttacking || isParrying || isFeinting): #The &&isAttacking makes you have to wait for the attack to finish before being able to attack again
		animated_sprite_2d.play("Attack Windup") #Still need a windup area2d
		isAttacking = true
		

	#this should have a similar hitbox system as the attack, 
	#but instead of looking for a player hitbox it would look for the attack hitbox, so im gonna have to do funny layer stuff i think
	if Input.is_action_just_pressed("parry_singleplayer") && !(isAttacking || isParrying || isFeinting): #Parry hitbox should actually likely be the same as the hurtbox while also being a bit larger
		animated_sprite_2d.play("Parry")
		isParrying = true
		$ParryArea/CollisionShape2D.disabled = false

	#This shouldnt have any hitbox, it should just play a feint animation to bait the enemy 
	if Input.is_action_just_pressed("feint_singleplayer") && !(isAttacking || isParrying || isFeinting):
		animated_sprite_2d.play("Feint")
		isFeinting = true


	# Handle dodge logic
	if is_dodging && !(isAttacking || isParrying || isFeinting):
		animated_sprite_2d.play("Dodge")
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

		#Play movement animations
		if direction == 0 && !(isAttacking || isParrying || isFeinting):
			animated_sprite_2d.play("Idle")
		elif direction > 0 && !(isAttacking || isParrying || isFeinting):
			animated_sprite_2d.play("Walk Forwards")
		elif direction < 0 && !(isAttacking || isParrying || isFeinting):
			animated_sprite_2d.play("Walk Backwards")
			

		# Normal movement if not dodging
		if direction > 0 && !(isAttacking || isParrying || isFeinting):
			velocity.x = direction * SPEED
		elif direction < 0 && !(isAttacking || isParrying || isFeinting): #move backwards, currently moving backwards makes you move slower
			velocity.x = (direction * SPEED) / 2
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()


func start_dodge(dir: int) -> void:
	is_dodging = true
	dodge_timer = DODGE_TIME
	dodge_direction = dir
	print("Dodging in direction:", dir)
	

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "Attack Windup":
		animated_sprite_2d.play("Attack")
		$AttackArea/CollisionShape2D.disabled = false
	elif animated_sprite_2d.animation == "Attack":
		$AttackArea/CollisionShape2D.disabled = true
		isAttacking = false
	elif animated_sprite_2d.animation == "Parry":
		$ParryArea/CollisionShape2D.disabled = true
		isParrying = false
	elif animated_sprite_2d.animation == "Feint":
		isFeinting = false
