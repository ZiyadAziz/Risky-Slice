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
var health := 5.0

@onready var player: CharacterBody2D = $"../TempPlayer"
#@onready var player = get_node("/root/MainScene/Player")
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animated_sprite_2d_2: AnimatedSprite2D = $AnimatedSprite2D2
@onready var animated_sprite_2d_3: AnimatedSprite2D = $AnimatedSprite2D3
@onready var animated_sprite_2d_4: AnimatedSprite2D = $AnimatedSprite2D4


func _physics_process(delta: float) -> void:
	if health <= 0.0:
			print("AI dead")
			GameManager.p1_score += 1
			GameManager.reset_round()
			return

	# React to player windup
	var player_windup = player.animated_sprite_2d_2.animation == "Attack Windup"
	var player_distance = global_position.distance_to(player.global_position)

	# AI makes decisions every interval
	decision_timer -= delta
	if decision_timer <= 0:
		make_decision(player_distance, player_windup)
		decision_timer = DECISION_INTERVAL
	
	## Handle dodge
	#if is_dodging:
		#animated_sprite_2d.play("Dodge")
		#dodge_timer -= delta
		#velocity.x = dodge_direction * DODGE_SPEED
		#if dodge_timer <= 0:
			#is_dodging = false
	#else:
		## Simple AI: move towards player
		#var dir = sign(player.global_position.x - global_position.x)
		#velocity.x = dir * SPEED
		#if abs(player_distance) < 50:
			#velocity.x = 0
	
	if !(isAttacking || isParrying || isFeinting):
		var dir = sign(player.global_position.x - global_position.x)
		velocity.x = dir * SPEED
	else:
		velocity.x = 0
	if abs(player_distance) < 20:
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
	
func make_decision(dist, player_windup):
	if isAttacking or isFeinting or isParrying:
		return

	#if player_windup and dist < 80:
		## Try to parry
		#start_parry()
		#return

	if dist < 40:
		var choice = randi() % 100
		if choice < 40:
			start_attack()
		elif choice < 70:
			start_feint()
		else:
			start_feint()
			#start_parry()

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
			health -= 10
			print("here now")
		else:
			isParrying = false

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("PlayerSword"):
		if isBlocking:
			health -= .25
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
		animated_sprite_2d.visible = true
		animated_sprite_2d_4.visible = false
		animated_sprite_2d.play("Got Parried")
		await animated_sprite_2d.animation_finished
		health -= 10
		
