extends CharacterBody2D

const SPEED = 50.0
# AI decision timing
const DECISION_INTERVAL = 0.8
var decision_timer = 0.0

var isAttacking := false
var isFeinting := false
var isParrying := false
var isBlocking := false

var parried := false
var health := 4.0

@onready var player: CharacterBody2D = $"../TempPlayer"
#@onready var player = get_node("/root/MainScene/Player")
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animated_sprite_2d_2: AnimatedSprite2D = $AnimatedSprite2D2
@onready var animated_sprite_2d_3: AnimatedSprite2D = $AnimatedSprite2D3
@onready var animated_sprite_2d_4: AnimatedSprite2D = $AnimatedSprite2D4


func _physics_process(delta: float) -> void:
	if health <= 0.0:
			print("AI dead")
			#Have a death animation 
			GameManager.p1_score += 1
			GameManager.reset_round()
			return

	# React to player windup
	var player_windup = player.animated_sprite_2d_2.animation == "Attack Windup"
	var player_feint = player.animated_sprite_2d_2.animation == "Feint"
	var player_distance = global_position.distance_to(player.global_position)

	# AI makes decisions every interval
	if velocity.x == 0:
		decision_timer -= delta
	if decision_timer <= 0:
		make_decision(player_distance, player_windup, player_feint)
		decision_timer = DECISION_INTERVAL

	
	if !(isAttacking || isParrying || isFeinting):
		var dir = sign(player.global_position.x - global_position.x)
		
		if abs(player_distance) < 10:
			# Too close, move backwards
			dir *= -1
			velocity.x = dir * SPEED
		elif abs(player_distance) < 20:
			# Within range but not too close, stop moving
			velocity.x = 0
		else:
			# Otherwise, move toward the player
			velocity.x = dir * SPEED
	else:
		# If attacking, parrying, or feinting, don't move
		velocity.x = 0


	# Animate idle/walk
	if !(isAttacking || isFeinting || isParrying):
		if velocity.x == 0:
			animated_sprite_2d.play("Idle")
		elif velocity.x > 0:
			animated_sprite_2d.play("Walk Backwards")
		else:
			animated_sprite_2d.play("Walk Forwards")
			

	move_and_slide()
	
func make_decision(dist, player_windup, player_feint):
	if isAttacking or isFeinting or isParrying:
		return

	if (player_windup || player_feint) and dist < 20:
		#Try to parry a feint or an actual attack
		var parry_chance = randi() % 100
		if player_feint && parry_chance < 10:
			start_parry()
		elif player_windup && parry_chance < 5:
			start_parry()
		return

	if dist < 40:
		var choice = randi() % 100
		if choice < 20:
			start_feint()
		elif choice < 80:
			start_attack()
		elif choice < 90:
			start_parry()
		else:
			return

func start_attack():
	print("AI Attacking")
	isAttacking = true
	animated_sprite_2d_2.visible = true
	animated_sprite_2d.visible = false
	animated_sprite_2d_2.play("Attack Windup")
	$WindupArea/CollisionShape2D.disabled = false

func start_feint():
	print("AI Feint")
	isFeinting = true
	animated_sprite_2d_2.visible = true
	animated_sprite_2d.visible = false
	animated_sprite_2d_2.play("Feint")


func start_parry():
	print("AI Parrying")
	isParrying = true
	animated_sprite_2d_3.visible = true
	animated_sprite_2d.visible = false
	animated_sprite_2d_3.play("Parry")
	$ParryArea/CollisionShape2D.disabled = false
	
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
		if !parried:
			animated_sprite_2d_3.visible = false
			animated_sprite_2d.visible = true
			animated_sprite_2d.play("Parry Fail")
			await animated_sprite_2d.animation_finished
			isParrying = false
			GameManager.p1_score += 1
			GameManager.reset_round()
		else:
			isParrying = false

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("PlayerSword"):
		if isBlocking:
			health -= .5
		else:
			health -= 1.0
		

func _on_parry_area_area_entered(area: Area2D) -> void:	
	if area.is_in_group("PlayerWindup"):
		parried = true
		animated_sprite_2d_3.visible = false
		animated_sprite_2d.visible = true
		animated_sprite_2d.play("Parry Success")
		await animated_sprite_2d.animation_finished
	
func _on_windup_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("PlayerParry"):
		isParrying = true
		animated_sprite_2d_2.visible = false
		animated_sprite_2d_4.visible = false
		animated_sprite_2d.visible = true
		animated_sprite_2d.play("Got Parried")
		await animated_sprite_2d.animation_finished
		GameManager.p1_score += 1
		GameManager.reset_round()
		

func apply_hitstop(duration: float = 0.1):
	Engine.time_scale = 0.0
	await get_tree().create_timer(duration, true).timeout
	Engine.time_scale = 1.0
