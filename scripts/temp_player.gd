extends CharacterBody2D

const SPEED = 50.0

#Need to fiddle with these numbers to get the dodge to feel good
const DODGE_SPEED = 500.0 #Can think of this as how fast the dodge happens
const DODGE_TIME = 0.08 #Can think of this as the distance of the dodge
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
@onready var animated_sprite_2d_2: AnimatedSprite2D = $AnimatedSprite2D2
@onready var animated_sprite_2d_3: AnimatedSprite2D = $AnimatedSprite2D3
@onready var animated_sprite_2d_4: AnimatedSprite2D = $AnimatedSprite2D4

var parried := false

var health := 4.0

func _physics_process(delta: float) -> void:
	if health <= 0.0: #This might have to be in physics process
		#Have a death animation 
		print("player dead")
		GameManager.p2_score += 1
		GameManager.reset_round()
			
	# Attack
	if Input.is_action_just_pressed("attack_singleplayer") && !(isAttacking || isParrying || isFeinting): #The &&isAttacking makes you have to wait for the attack to finish before being able to attack again
		animated_sprite_2d_2.visible = true
		animated_sprite_2d.visible = false
		animated_sprite_2d_2.play("Attack Windup") #Still need a windup area2d
		$WindupArea/CollisionShape2D.disabled = false
		isAttacking = true
		
	if Input.is_action_just_pressed("parry_singleplayer") && !(isAttacking || isParrying || isFeinting): #Parry hitbox should actually likely be the same as the hurtbox while also being a bit larger
		animated_sprite_2d_3.visible = true
		animated_sprite_2d.visible = false
		animated_sprite_2d_3.play("Parry")
		isParrying = true
		$ParryArea/CollisionShape2D.disabled = false

	#This shouldnt have any hitbox, it should just play a feint animation to bait the enemy 
	if Input.is_action_just_pressed("feint_singleplayer") && !(isAttacking || isParrying || isFeinting):
		animated_sprite_2d_2.visible = true
		animated_sprite_2d.visible = false
		animated_sprite_2d_2.play("Feint")
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
	pass

func _on_animated_sprite_2d_2_animation_finished() -> void:
	if animated_sprite_2d_2.animation == "Attack Windup":
		animated_sprite_2d_2.play("Attack")
		animated_sprite_2d_4.visible = true
		animated_sprite_2d_4.play("Slash")
		$WindupArea/CollisionShape2D.disabled = true
		$AttackArea/CollisionShape2D.disabled = false
	elif animated_sprite_2d_2.animation == "Attack":
		$AttackArea/CollisionShape2D.disabled = true
		isAttacking = false
		animated_sprite_2d_4.visible = false
		animated_sprite_2d_2.visible = false
		animated_sprite_2d.visible = true
	
	elif animated_sprite_2d_2.animation == "Feint":
		isFeinting = false
		animated_sprite_2d_2.visible = false
		animated_sprite_2d.visible = true

func _on_animated_sprite_2d_3_animation_finished() -> void:
	if animated_sprite_2d_3.animation == "Parry":
		$ParryArea/CollisionShape2D.disabled = true
		if parried == false:
			animated_sprite_2d_3.visible = false
			animated_sprite_2d.visible = true
			animated_sprite_2d.play("Parry Fail")
			await animated_sprite_2d.animation_finished
			isParrying = false
			GameManager.p2_score += 1
			GameManager.reset_round()
		else:
			isParrying = false

func _on_parry_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("EnemyWindup"):
		parried = true
		animated_sprite_2d_3.visible = false
		animated_sprite_2d.visible = true
		animated_sprite_2d.play("Parry Success")
		await animated_sprite_2d.animation_finished

func _on_windup_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("EnemyParry"):
		isParrying = true
		print("player attack got parried")
		animated_sprite_2d_2.visible = false
		animated_sprite_2d.visible = true
		animated_sprite_2d_4.visible = false
		animated_sprite_2d.play("Got Parried") #This needs to change to a getting parried animation where the player stumbles and the enemy does a slash to kill them (reduce hp by like 10 here)
		await animated_sprite_2d.animation_finished
		GameManager.p2_score += 1
		GameManager.reset_round()

func _on_hurt_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("EnemySword"):
		if isBlocking:
			health -= .5
		else:
			health -= 1.0
