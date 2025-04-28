#####################################################################
#
# CSCB58 Winter 2025 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Ishani Thakker, 1010165116, thakkeri, ishani.thakker@mail.utoronto.ca
# # Bitmap Display Configuration:
# - Unit width in pixels: 4
# - Unit height in pixels: 4
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestoneshave been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestones 1, 2, 3 completely, and most of milestone 4
#
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. Moving objects
# 2. Shoot enemies
# 3. Win Condition (collect pickup object)
# 4. Lose Condition (all 3 lives over - collision with enemies)
#
# # Link to video demonstration for final submission:
# - https://youtu.be/22EZa2zj2D0
# # Are you OK with us sharing the video with people outside course staff? 
# - yes
# # Any additional information that the TA needs to know:
# - I have implemented 2 additional features (milestone 4), I was not able to do another 1 mark feature (disappearing platforms)
# - Score is shown on lose screen through number 0
# - Player must safely collide with pickup object to win the game (even if this collision is not explicitly shown)
# - Exiting the game after win or lose screen will take around 5 seconds, mentioning just in case there are issues
#
#####################################################################



.eqv BASE_ADDRESS              0x10008000  # Base address for display
.eqv FRAME_SIZE                64          # Frame size (width and height)
.eqv UNIT_WIDTH_PIXELS         4           # Unit width in pixels
.eqv SCREEN_PIXELS             16384       # 64 * 64 * 4 pixels to clear
.eqv PLAYER_OUTLINE_COLOUR     0x1fb2bf    # Outline colour of player - teal
.eqv PLAYER_BODY_COLOUR        0xffffff    # Body colour of player and enemy - white
.eqv ENEMY_OUTLINE_COLOUR      0xe957ff    # Outline colour of enemy - lavender
.eqv PLATFORM_COLOUR           0x2dfc64    # Colour of 4 platforms - light green
.eqv BLACK_COLOUR              0x000000    # Background colour - black
.eqv PLAYER_BEGINNING_X_POS    0           # Starting x position of the player
.eqv PLAYER_BEGINNING_Y_POS    55          # Starting y position of the player
.eqv ENEMY1_BEGINNING_X_POS    57          # Starting x position of both enemies
.eqv ENEMY1_BEGINNING_Y_POS    17          # Starting y position of top enemy
.eqv ENEMY2_BEGINNING_Y_POS    45          # Starting y position of bottom enemy
.eqv MAIN_CHARACTER_WIDTH      9           # Width of main character (player)
.eqv MAIN_CHARACTER_HEIGHT     9           # Height of main character (player)
.eqv BOTTOM_OF_SCREEN_LEVEL    64          # Pixel height associated with bottom of display
.eqv VELOCITY_BULLET           2           # Bullet shifts 2 pixels at a time
.eqv REVIVE_ENEMY_DELAY        30          # Skip 30 frames till enemy rejuvenates
.eqv STARTING_NUM_LIVES        3           # Starting number of lives player has
.eqv LIVES_COLOUR              0xff0000    # Colour of lives - red hearts
.eqv LIVES_BEGINNING_X_POS     20          # Starting x position for lives
.eqv Y_POS_LIVES               4           # Y position for all lives
.eqv SPACE_BETWEEN_LIVES       8           # Space to separate the lives
.eqv PICKUP_BOX_COLOUR         0x6d46f0    # Colour of the pickup object to win
.eqv X_POS_PICKUP              10          # X position of pickup object on draw_platform_4
.eqv Y_POS_PICKUP              22          # Y position of pickup object on draw_platform_4
.eqv WIDTH_OF_PICKUP           3           # Width and height of pickup object (it is square)
.eqv WIN_LOSE_MESSAGE_COLOUR    0xff2470   # Colour for message on win/lose screen
.eqv X_POS_WIN_MESSAGE         18          # X position for printing "YOU" part of win/lose message
.eqv Y_POS_WIN_MESSAGE         25          # Starting y position for printing win/lose message


.data
	X_POS_PLAYER: .word PLAYER_BEGINNING_X_POS     # Track current x position of the main character
	Y_POS_PLAYER: .word PLAYER_BEGINNING_Y_POS     # Track current y position of the main character
	X_POS_ENEMY_1: .word ENEMY1_BEGINNING_X_POS    # Track current x position of enemy 1
	X_POS_ENEMY_2: .word ENEMY1_BEGINNING_X_POS    # Track current x position of enemy 2
	Y_POS_ENEMY_1: .word ENEMY1_BEGINNING_Y_POS    # Track current y position of enemy 1
	Y_POS_ENEMY_2: .word ENEMY2_BEGINNING_Y_POS    # Track current y position of enemy 2
        X_POS_BULLET: .word -1                # X position for bullet if shot, else -1
    	Y_POS_BULLET: .word -1                # Y position for bullet if shot, else -1
    	ENEMY_1_ALIVE: .word 1                # Value 1 means enemy 1 is alive and moving, 0 means dead
    	ENEMY_2_ALIVE: .word 1                # Value 1 means enemy 2 is alive and moving, 0 means dead
    	REVIVE_ENEMY_1_COUNTDOWN: .word 0     # Countdown for rejuvenating enemy 1
    	REVIVE_ENEMY_2_COUNTDOWN: .word 0     # Countdown for rejuvenating enemy 2
    	BULLET_COLOUR: .word 0xfc6b03         # Colour of bullet shot - orange
    	LIVES: .word STARTING_NUM_LIVES       # Number of leftover lives currently
    	PICKUP_DISPLAYED: .word 1             # 0 means pickup collected & 1 means not collected (still present)


.text
.globl main

main:
	# Display initial frame
	jal draw_platform_1
	jal draw_platform_2
	jal draw_platform_3
	jal draw_platform_4
	jal display_lives
	jal display_winning_pickup
	jal draw_main_character
	jal draw_enemy_1
	jal draw_enemy_2
	
	j main_loop

main_loop:
	# Clear the previous frame
	jal clear_character
	jal clear_current_bullet       # Clear if bullet shot
	
	jal check_key_pressed
	jal simulate_gravity
	jal process_bullet             # Bullet movement and enemy-bullet collisions
	
	# Enemy management
	jal process_reviving_enemies
	
	# Handling collisions
	jal check_player_enemy_collision
	jal process_player_pickup_collision
    
	# Only draw enemies who are alive
	lw $t0, ENEMY_1_ALIVE
	beqz $t0, skip_e1
	jal animate_enemy1

skip_e1:
	lw $t0, ENEMY_2_ALIVE
	beqz $t0, skip_e2
	
	jal animate_enemy2

skip_e2:
	# Display the current frame
	jal draw_platform_1
	jal draw_platform_2
	jal draw_platform_3
	jal draw_platform_4
	jal display_lives
	jal display_winning_pickup
	jal draw_main_character
	jal display_bullet
    
	# Frame delay is 0.2 seconds
	li $v0, 32
	li $a0, 200
	syscall
    
	j main_loop

exit:
	li $v0, 10      # Exit syscall
	syscall         # Program terminates

draw_platform_1:
	li $t5, 25                # Load x position of platform 1
	li $t2, 53                # Load y position of platform 1
	li $t1, PLATFORM_COLOUR   # Load platform colour
	li $t7, BASE_ADDRESS      # Load base address
	
	# Calculate pixel offset
	li $t3, FRAME_SIZE        # Load FRAME_SIZE into register
	mult $t2, $t3             # Y * FRAME_SIZE
	mflo $t3
	add $t3, $t3, $t5         # Add x position
	li $t4, UNIT_WIDTH_PIXELS # Load pixel width
	mult $t3, $t4             # Multiply by pixel width
	mflo $t3
	add $t7, $t7, $t3         # Add to base address
	
	li $t6, 0                 # Counter for platform loop (x = 0)
	
draw_platform_loop_1:
	sw $t1, 0($t7)
	addi $t7, $t7, UNIT_WIDTH_PIXELS
	addi $t6, $t6, 1                    # Increase counter
	blt $t6, 18, draw_platform_loop_1   # Draw platform until it has length 18
	
	jr $ra  # Return to caller

draw_platform_2:
	li $t5, 38                # Load x position of platform 2
	li $t2, 42                # Load y position of platform 2
	li $t1, PLATFORM_COLOUR   # Load platform colour
	li $t7, BASE_ADDRESS      # Load base address
	
	# Calculate pixel offset
	li $t3, FRAME_SIZE        # Load FRAME_SIZE into register
	mult $t2, $t3             # Y * FRAME_SIZE
	mflo $t3
	add $t3, $t3, $t5         # Add x position
	li $t4, UNIT_WIDTH_PIXELS # Load pixel width
	mult $t3, $t4             # Multiply by pixel width
	mflo $t3
	add $t7, $t7, $t3         # Add to base address
	
	li $t6, 0                 # Counter for platform loop (x = 0)
	
draw_platform_loop_2:
	sw $t1, 0($t7)
	addi $t7, $t7, UNIT_WIDTH_PIXELS
	addi $t6, $t6, 1                    # Increase counter
	blt $t6, 18, draw_platform_loop_2   # Draw platform until it has length 18
	
	jr $ra  # Return to caller
	
draw_platform_3:
	li $t5, 5                 # Load x position of platform 3
	li $t2, 35                # Load y position of platform 3
	li $t1, PLATFORM_COLOUR   # Load platform colour
	li $t7, BASE_ADDRESS      # Load base address
	
	# Calculate pixel offset
	li $t3, FRAME_SIZE        # Load FRAME_SIZE into register
	mult $t2, $t3             # Y * FRAME_SIZE
	mflo $t3
	add $t3, $t3, $t5         # Add x position
	li $t4, UNIT_WIDTH_PIXELS # Load pixel width
	mult $t3, $t4             # Multiply by pixel width
	mflo $t3
	add $t7, $t7, $t3         # Add to base address
	
	li $t6, 0                 # Counter for platform loop (x = 0)
	
draw_platform_loop_3:
	sw $t1, 0($t7)
	addi $t7, $t7, UNIT_WIDTH_PIXELS
	addi $t6, $t6, 1                    # Increase counter
	blt $t6, 18, draw_platform_loop_3   # Draw platform until it has length 18
	
	jr $ra  # Return to caller
	
draw_platform_4:
	li $t5, 5                 # Load x position of platform 4
	li $t2, 25                # Load y position of platform 4
	li $t1, PLATFORM_COLOUR   # Load platform colour
	li $t7, BASE_ADDRESS      # Load base address
	
	# Calculate pixel offset
	li $t3, FRAME_SIZE        # Load FRAME_SIZE into register
	mult $t2, $t3             # Y * FRAME_SIZE
	mflo $t3
	add $t3, $t3, $t5         # Add x position
	li $t4, UNIT_WIDTH_PIXELS # Load pixel width
	mult $t3, $t4             # Multiply by pixel width
	mflo $t3
	add $t7, $t7, $t3         # Add to base address
	
	li $t6, 0                 # Counter for platform loop (x = 0)
	
draw_platform_loop_4:
	sw $t1, 0($t7)
	addi $t7, $t7, UNIT_WIDTH_PIXELS
	addi $t6, $t6, 1                    # Increase counter
	blt $t6, 18, draw_platform_loop_4   # Draw platform until it has length 18
	
	jr $ra  # Return to caller

draw_main_character:
	lw $t5, X_POS_PLAYER                # Load x position of main character
	lw $t2, Y_POS_PLAYER                # Load y position of main character
	li $t1, PLAYER_OUTLINE_COLOUR       # Load player outline colour
	li $t9, PLAYER_BODY_COLOUR          # Load player body colour
	li $t7, BASE_ADDRESS                # Load base address
	
	# Calculate pixel offset
	li $t3, FRAME_SIZE           # Load frame size into register
	mult $t2, $t3                # Y * FRAME_SIZE
	mflo $t8
	add $t8, $t8, $t5            # Add X position
	li $t4, UNIT_WIDTH_PIXELS    # Load pixel width
	mult $t8, $t4                # Multiply by pixel width
	mflo $t8
	add $t7, $t7, $t8            # Add to base address

	# Display the player now by colouring pixels
	# Row 1
	sw $t1, 8($t7)
	sw $t1, 12($t7)
	sw $t1, 16($t7)
	sw $t1, 20($t7)
	sw $t1, 24($t7)

	# Row 2
	addi $t7, $t7, 256    # Move to next screen row
	sw $t1, 4($t7)
	sw $t9, 8($t7)
	sw $t9, 12($t7)
	sw $t9, 16($t7)
	sw $t9, 20($t7)
	sw $t9, 24($t7)
	sw $t1, 28($t7)

	# Row 3
	addi $t7, $t7, 256
	sw $t1, 4($t7)
	sw $t9, 8($t7)
	sw $t1, 12($t7)
	sw $t9, 16($t7)
	sw $t1, 20($t7)
	sw $t9, 24($t7)
	sw $t1, 28($t7)

	# Row 4
	addi $t7, $t7, 256
	sw $t1, 4($t7)
	sw $t9, 8($t7)
	sw $t1, 12($t7)
	sw $t9, 16($t7)
	sw $t1, 20($t7)
	sw $t9, 24($t7)
	sw $t1, 28($t7)

	# Row 5
	addi $t7, $t7, 256
	sw $t1, 0($t7)
	sw $t1, 4($t7)
	sw $t9, 8($t7)
	sw $t9, 12($t7)
	sw $t9, 16($t7)
	sw $t9, 20($t7)
	sw $t9, 24($t7)
	sw $t1, 28($t7)
	sw $t1, 32($t7)

	# Row 6
	addi $t7, $t7, 256
	sw $t1, 4($t7)
	sw $t1, 8($t7)
	sw $t1, 12($t7)
	sw $t1, 16($t7)
	sw $t1, 20($t7)
	sw $t1, 24($t7)
	sw $t1, 28($t7)

	# Row 7
	addi $t7, $t7, 256
	sw $t1, 4($t7)
	sw $t9, 8($t7)
	sw $t9, 12($t7)
	sw $t9, 16($t7)
	sw $t9, 20($t7)
	sw $t9, 24($t7)
	sw $t1, 28($t7)

	# Row 8
	addi $t7, $t7, 256
	sw $t1, 4($t7)
	sw $t1, 8($t7)
	sw $t9, 12($t7)
	sw $t1, 16($t7)
	sw $t9, 20($t7)
	sw $t1, 24($t7)
	sw $t1, 28($t7)

	# Row 9
	addi $t7, $t7, 256
	sw $t1, 8($t7)
	sw $t1, 12($t7)
	sw $t1, 16($t7)
	sw $t1, 20($t7)
	sw $t1, 24($t7)

	jr $ra  # Return to caller
	
clear_character:
	lw $t5, X_POS_PLAYER         # Load x position of main character
	lw $t2, Y_POS_PLAYER         # Load y position of main character
	li $t1, BLACK_COLOUR         # Load default background colour
	li $t7, BASE_ADDRESS         # Load base address
	
	# Calculate pixel offset
	li $t3, FRAME_SIZE           # Load frame size into register
	mult $t2, $t3                # Y * FRAME_SIZE
	mflo $t8
	add $t8, $t8, $t5            # Add X position
	li $t4, UNIT_WIDTH_PIXELS    # Load pixel width
	mult $t8, $t4                # Multiply by pixel width
	mflo $t8
	add $t7, $t7, $t8            # Add to base address
	
	# Clear character pixel by pixel
	# Row 1
	sw $t1, 8($t7)
	sw $t1, 12($t7)
	sw $t1, 16($t7)
	sw $t1, 20($t7)
	sw $t1, 24($t7)
	
	# Row 2
	addi $t7, $t7, 256
	sw $t1, 4($t7)
	sw $t1, 8($t7)
	sw $t1, 12($t7)
	sw $t1, 16($t7)
	sw $t1, 20($t7)
	sw $t1, 24($t7)
	sw $t1, 28($t7)
    
	# Row 3
	addi $t7, $t7, 256
	sw $t1, 4($t7)
	sw $t1, 8($t7)
	sw $t1, 12($t7)
	sw $t1, 16($t7)
	sw $t1, 20($t7)
	sw $t1, 24($t7)
	sw $t1, 28($t7)

	# Row 4
	addi $t7, $t7, 256
	sw $t1, 4($t7)
	sw $t1, 8($t7)
	sw $t1, 12($t7)
	sw $t1, 16($t7)
	sw $t1, 20($t7)
	sw $t1, 24($t7)
	sw $t1, 28($t7)

	# Row 5
	addi $t7, $t7, 256
	sw $t1, 0($t7)
	sw $t1, 4($t7)
	sw $t1, 8($t7)
	sw $t1, 12($t7)
	sw $t1, 16($t7)
	sw $t1, 20($t7)
	sw $t1, 24($t7)
	sw $t1, 28($t7)
	sw $t1, 32($t7)
	
	# Row 6
	addi $t7, $t7, 256
	sw $t1, 4($t7)
	sw $t1, 8($t7)
	sw $t1, 12($t7)
	sw $t1, 16($t7)
	sw $t1, 20($t7)
	sw $t1, 24($t7)
	sw $t1, 28($t7)
	
	# Row 7
	addi $t7, $t7, 256
	sw $t1, 4($t7)
	sw $t1, 8($t7)
	sw $t1, 12($t7)
	sw $t1, 16($t7)
	sw $t1, 20($t7)
	sw $t1, 24($t7)
	sw $t1, 28($t7)
	
	# Row 8
	addi $t7, $t7, 256
	sw $t1, 4($t7)
	sw $t1, 8($t7)
	sw $t1, 12($t7)
	sw $t1, 16($t7)
	sw $t1, 20($t7)
	sw $t1, 24($t7)
	sw $t1, 28($t7)
	
	# Row 9
	addi $t7, $t7, 256
	sw $t1, 8($t7)
	sw $t1, 12($t7)
	sw $t1, 16($t7)
	sw $t1, 20($t7)
	sw $t1, 24($t7)
	
	jr $ra  # Return to caller
	

check_key_pressed:
	li $t3, 0xffff0000              # Load address for input through keyboard
	lw $t2, 0($t3)                  # Check if key pressed
	beq $t2, 1, key_based_action    # Take appropriate action for key pressed
	
	jr $ra

key_based_action:
	lw $t5, 4($t3)            # Load key code
	
	beq $t5, 0x77, w_action   # w - move up
	beq $t5, 0x73, s_action   # s - move down
	beq $t5, 0x61, a_action   # a - move left
	beq $t5, 0x64, d_action   # d - move right
	
	beq $t5, 0x71, exit               # q - exit game
	beq $t5, 0x20, shooting_action    # space - shoot
	beq $t5, 0x72, restart_game       # r - restart game
	
	jr $ra

w_action:
	lw $t0, Y_POS_PLAYER        # Load current Y position of player
	li $t1, 4                   # Load minimum Y position for moving up
	sub $t2, $t0, $t1           # Calculate number of pixels the player can move up
	blez $t2, avoid_any_action  # If player at or above min position, don't move up
	addi $t0, $t0, -4           # Move up 4 units
	sw $t0, Y_POS_PLAYER        # Store new player y position
	
	jr $ra

s_action:
	lw $t0, Y_POS_PLAYER        # Load current Y position of player
	li $t1, 55                  # Load maximum Y position for player top
	sub $t2, $t1, $t0           # Calculate number of pixels the player can move down
	blez $t2, avoid_any_action  # If player at or below max position, don't move down
	addi $t0, $t0, 1            # Player moves down by 1 pixel
	sw $t0, Y_POS_PLAYER        # Store new player y position
    
	jr $ra                      # Return to caller

a_action:
	lw $t0, X_POS_PLAYER        # Load current X position of player
	li $t1, 2                   # Speed to move left
	blez $t0, avoid_any_action  # Cannot move further left if x <= 0
	mul $t1, $t1, -1
	add $t0, $t0, $t1           # Move player to the left
	sw $t0, X_POS_PLAYER        # Store new player x position
	
	jr $ra

d_action:
	lw $t0, X_POS_PLAYER            # Load current X position of player
	li $t1, 2                       # Speed to move right
	bge $t0, 54, avoid_any_action   # Cannot move further right if x >= 54
	add $t0, $t0, $t1               # Move player to the right
	sw $t0, X_POS_PLAYER            # Store new player x position
	
	jr $ra
	
shooting_action:
	lw $t1, X_POS_BULLET         # Check if bullet shot (get x pos)
	bgez $t1, avoid_any_action   # If shot, no more shooting occurs

	# Load player position into $t1 and $t2
	lw $t1, X_POS_PLAYER         # Load current x position of player
	lw $t2, Y_POS_PLAYER         # Load current y position of player

	# Determine bullet shooting position - right hand of player
	addi $t1, $t1, 8       # Bullet x = Player x + 8 (player right side)
	addi $t2, $t2, 4       # Bullet y = Player y + 4 (right hand position)

	# Store bullet position
	sw $t1, X_POS_BULLET   # Store bullet initial x position
	sw $t2, Y_POS_BULLET   # Store bullet initial y position
    
	j avoid_any_action

avoid_any_action:
	jr $ra
	
restart_game:
	addi $sp, $sp, -4   # Allocate stack space
	sw $ra, 0($sp)      # Save return address $ra
    
	jal clear_screen    # Clear screen before resetting
    
	li $t0, PLAYER_BEGINNING_X_POS
	sw $t0, X_POS_PLAYER    # Reset x to starting position of player
	li $t0, PLAYER_BEGINNING_Y_POS
	sw $t0, Y_POS_PLAYER    # Reset y to starting position of player
    
	li $t0, ENEMY1_BEGINNING_X_POS
	sw $t0, X_POS_ENEMY_1   # Reset enemy 1 x position
	sw $t0, X_POS_ENEMY_2   # Reset enemy 2 x position
    
	li $t0, ENEMY1_BEGINNING_Y_POS
	sw $t0, Y_POS_ENEMY_1   # Reset enemy 1 y position
	li $t0, ENEMY2_BEGINNING_Y_POS
	sw $t0, Y_POS_ENEMY_2   # Reset enemy 2 y position
    
	li $t0, 1
	sw $t0, ENEMY_1_ALIVE   # Reset enemy 1 as alive
	sw $t0, ENEMY_2_ALIVE   # Reset enemy 2 as alive
	sw $zero, REVIVE_ENEMY_1_COUNTDOWN   # Clear countdowns for reviving enemies
	sw $zero, REVIVE_ENEMY_2_COUNTDOWN
    
	li $t0, -1
	sw $t0, X_POS_BULLET    # Mark as no bullet shot
	sw $t0, Y_POS_BULLET
    
	li $t0, STARTING_NUM_LIVES   # Reset number of lives (3)
	sw $t0, LIVES
    
	li $t0, 1
	sw $t0, PICKUP_DISPLAYED     # Display pickup
    
    	# Redisplay elements (player, enemies, platforms, pickup)
	jal draw_platform_1
	jal draw_platform_2
	jal draw_platform_3
	jal draw_platform_4
	jal display_lives
	jal display_winning_pickup
	jal draw_main_character
	jal draw_enemy_1
	jal draw_enemy_2
    
	lw $ra, 0($sp)        # Retrieve return address
	addi $sp, $sp, 4      # Free up stack space
	j main_loop

clear_screen:
	li $t0, BASE_ADDRESS       # Load base address
	li $t1, BLACK_COLOUR       # Load default background colour
	li $t2, 0                  # Counter for clearing (start at 0)
	li $t3, SCREEN_PIXELS      # Total bytes to clear
    
clear_loop:
	sw $t1, 0($t0)             # Paint pixel black
	addi $t0, $t0, 4           # Move to next pixel
	addi $t2, $t2, 4           # Increment counter
	blt $t2, $t3, clear_loop   # Continue clearing for whole screen
	jr $ra

draw_enemy_1:
	lw $t5, X_POS_ENEMY_1   # Load enemy 1 x position
	lw $t2, Y_POS_ENEMY_1   # Load enemy 1 y position
	li $t1, ENEMY_OUTLINE_COLOUR  # Load enemy outline colour
	li $t7, PLAYER_BODY_COLOUR    # Load enemy body colour
	li $t0, BASE_ADDRESS          # Load base address
	
	# Calculate memory offset
	li $t3, FRAME_SIZE           # Load frame size into register first
	mult $t2, $t3                # Y * FRAME_SIZE
	mflo $t8
	add $t8, $t8, $t5            # Add X position
	li $t4, UNIT_WIDTH_PIXELS    # Load pixel width
	mult $t8, $t4                # Multiply by pixel width
	mflo $t8
	add $t0, $t0, $t8            # Add to base address
	
	# Display enemy pixel by pixel
	# Row 1
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	
	# Row 2
	addi $t0, $t0, 256
	sw $t1, 4($t0)
	sw $t7, 8($t0)
	sw $t7, 12($t0)
	sw $t7, 16($t0)
	sw $t1, 20($t0)

	# Row 3
	addi $t0, $t0, 256
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t7, 16($t0)
	sw $t1, 20($t0)

	# Row 4
	addi $t0, $t0, 256
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t7, 16($t0)
	sw $t1, 20($t0)

	# Row 5
	addi $t0, $t0, 256
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t7, 8($t0)
	sw $t7, 12($t0)
	sw $t7, 16($t0)
	sw $t1, 20($t0)
	sw $t1, 24($t0)

	# Row 6
	addi $t0, $t0, 256
	sw $t1, 4($t0)
	sw $t7, 8($t0)
	sw $t7, 12($t0)
	sw $t7, 16($t0)
	sw $t1, 20($t0)

	# Row 7
	addi $t0, $t0, 256
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	sw $t1, 20($t0)

	# Row 8
	addi $t0, $t0, 256
	sw $t1, 8($t0)
	sw $t1, 16($t0)

	jr $ra  # Return to caller
	
draw_enemy_2:
	lw $t5, X_POS_ENEMY_2    # Load enemy 2 x position
	lw $t2, Y_POS_ENEMY_2    # Load enemy 2 y position
	li $t1, ENEMY_OUTLINE_COLOUR   # Load enemy outline colour
	li $t7, PLAYER_BODY_COLOUR     # Load enemy body colour
	li $t0, BASE_ADDRESS           # Load base address
	
	# Calculate memory offset
	li $t3, FRAME_SIZE           # Load frame size into register first
	mult $t2, $t3                # Y * FRAME_SIZE
	mflo $t8
	add $t8, $t8, $t5            # Add X position
	li $t4, UNIT_WIDTH_PIXELS    # Load pixel width
	mult $t8, $t4                # Multiply by pixel width
	mflo $t8
	add $t0, $t0, $t8            # Add to base address
	
	# Display enemy pixel by pixel
	# Row 1
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	
	# Row 2
	addi $t0, $t0, 256
	sw $t1, 4($t0)
	sw $t7, 8($t0)
	sw $t7, 12($t0)
	sw $t7, 16($t0)
	sw $t1, 20($t0)

	# Row 3
	addi $t0, $t0, 256
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t7, 16($t0)
	sw $t1, 20($t0)

	# Row 4
	addi $t0, $t0, 256
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t7, 16($t0)
	sw $t1, 20($t0)

	# Row 5
	addi $t0, $t0, 256
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t7, 8($t0)
	sw $t7, 12($t0)
	sw $t7, 16($t0)
	sw $t1, 20($t0)
	sw $t1, 24($t0)

	# Row 6
	addi $t0, $t0, 256
	sw $t1, 4($t0)
	sw $t7, 8($t0)
	sw $t7, 12($t0)
	sw $t7, 16($t0)
	sw $t1, 20($t0)

	# Row 7
	addi $t0, $t0, 256
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	sw $t1, 20($t0)

	# Row 8
	addi $t0, $t0, 256
	sw $t1, 8($t0)
	sw $t1, 16($t0)

	jr $ra  # Return to caller
	
animate_enemy1:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
    
	lw $t5, X_POS_ENEMY_1     # Load x position of enemy 1
	lw $t2, Y_POS_ENEMY_1     # Load y position of enemy 1
	li $t1, BLACK_COLOUR      # Load background colour
	li $t9, BASE_ADDRESS      # Load base address

	li $t3, FRAME_SIZE           # Load frame size into register first
	mult $t2, $t3                # Y * FRAME_SIZE
	mflo $t3
	add $t3, $t3, $t5            # Add X position
	li $t4, UNIT_WIDTH_PIXELS    # Load pixel width
	mult $t3, $t4                # Multiply by pixel width
	mflo $t3
	add $t9, $t9, $t3            # Add to base address
    	
    	# Erase enemy 1 pixel by pixel
	# Row 1
	sw $t1, 8($t9)
	sw $t1, 12($t9)
	sw $t1, 16($t9)
    
	# Row 2
	addi $t9, $t9, 256
	sw $t1, 4($t9)
	sw $t1, 8($t9)
	sw $t1, 12($t9)
	sw $t1, 16($t9)
	sw $t1, 20($t9)
    
	# Row 3
	addi $t9, $t9, 256
	sw $t1, 4($t9)
	sw $t1, 8($t9)
	sw $t1, 12($t9)
	sw $t1, 16($t9)
	sw $t1, 20($t9)

	# Row 4
	addi $t9, $t9, 256
	sw $t1, 4($t9)
	sw $t1, 8($t9)
	sw $t1, 12($t9)
	sw $t1, 16($t9)
	sw $t1, 20($t9)

	# Row 5
	addi $t9, $t9, 256
	sw $t1, 0($t9)
	sw $t1, 4($t9)
	sw $t1, 8($t9)
	sw $t1, 12($t9)
	sw $t1, 16($t9)
	sw $t1, 20($t9)
	sw $t1, 24($t9)
    
	# Row 6
	addi $t9, $t9, 256
	sw $t1, 4($t9)
	sw $t1, 8($t9)
	sw $t1, 12($t9)
	sw $t1, 16($t9)
	sw $t1, 20($t9)
    
	# Row 7
	addi $t9, $t9, 256
	sw $t1, 4($t9)
	sw $t1, 8($t9)
	sw $t1, 12($t9)
	sw $t1, 16($t9)
	sw $t1, 20($t9)
    
	# Row 8
	addi $t9, $t9, 256
	sw $t1, 8($t9)
	sw $t1, 16($t9)
    
	lw $t0, X_POS_ENEMY_1
	addi $t0, $t0, -2            # Move enemy 1 normally 2 units left
    
	bgtz $t0, enemy1_in_bounds   # Check if enemy still in screen bounds
	li $t0, 57                   # Bring enemy back to right side

enemy1_in_bounds:
	sw $t0, X_POS_ENEMY_1        # Store new enemy x position
	jal draw_enemy_1             # Display at new pos
    
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

animate_enemy2:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
    
	lw $t5, X_POS_ENEMY_2    # Load enemy 2 x position
	lw $t2, Y_POS_ENEMY_2    # Load enemy 2 y position
	li $t1, BLACK_COLOUR
	li $t9, BASE_ADDRESS

	li $t3, FRAME_SIZE           # Load frame size into register first
	mult $t2, $t3                # Y * FRAME_SIZE
	mflo $t3
	add $t3, $t3, $t5            # Add X position
	li $t4, UNIT_WIDTH_PIXELS    # Load pixel width
	mult $t3, $t4                # Multiply by pixel width
	mflo $t3
	add $t9, $t9, $t3            # Add to base address
    
    	# Erase enemy 2 pixel by pixel
	# Row 1
	sw $t1, 8($t9)
	sw $t1, 12($t9)
	sw $t1, 16($t9)
    
	# Row 2
	addi $t9, $t9, 256
	sw $t1, 4($t9)
	sw $t1, 8($t9)
	sw $t1, 12($t9)
	sw $t1, 16($t9)
	sw $t1, 20($t9)
    
	# Row 3
	addi $t9, $t9, 256
	sw $t1, 4($t9)
	sw $t1, 8($t9)
	sw $t1, 12($t9)
	sw $t1, 16($t9)
	sw $t1, 20($t9)

	# Row 4
	addi $t9, $t9, 256
	sw $t1, 4($t9)
	sw $t1, 8($t9)
	sw $t1, 12($t9)
	sw $t1, 16($t9)
	sw $t1, 20($t9)

	# Row 5
	addi $t9, $t9, 256
	sw $t1, 0($t9)
	sw $t1, 4($t9)
	sw $t1, 8($t9)
	sw $t1, 12($t9)
	sw $t1, 16($t9)
	sw $t1, 20($t9)
	sw $t1, 24($t9)
    
	# Row 6
	addi $t9, $t9, 256
	sw $t1, 4($t9)
	sw $t1, 8($t9)
	sw $t1, 12($t9)
	sw $t1, 16($t9)
	sw $t1, 20($t9)
    
	# Row 7
	addi $t9, $t9, 256
	sw $t1, 4($t9)
	sw $t1, 8($t9)
	sw $t1, 12($t9)
	sw $t1, 16($t9)
	sw $t1, 20($t9)
    
	# Row 8
	addi $t9, $t9, 256
	sw $t1, 8($t9)
	sw $t1, 16($t9)
    
	lw $t0, X_POS_ENEMY_2
	addi $t0, $t0, -2            # Move enemy 2 normally 2 units left
    
	bgtz $t0, enemy2_in_bounds   # Check if enemy still in screen bounds
	li $t0, 57                   # Bring enemy back to right side

enemy2_in_bounds:
	sw $t0, X_POS_ENEMY_2        # Store new enemy x position
	jal draw_enemy_2             # Display at new pos
    
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

simulate_gravity:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
    
	# Check if the main character is standing on any platform
	jal check_player_platform_collision
    
	# Gravity is applied only if main character is not standing on a platform
	beq $v0, 1, no_gravity_applied
    
	# Gravity simulation (player moves down 1 pixel)
	lw $t0, Y_POS_PLAYER
	addi $t0, $t0, 1
	sw $t0, Y_POS_PLAYER
    
no_gravity_applied:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

check_player_platform_collision:
	li $v0, 0  # Default is player not standing on a platform
	
	# Coordinates and dimensions of main character on screen
	lw $t0, X_POS_PLAYER                   # Load player left
	lw $t1, Y_POS_PLAYER                   # Load player top
	addi $t2, $t0, MAIN_CHARACTER_WIDTH    # Load player right
	addi $t3, $t1, MAIN_CHARACTER_HEIGHT   # Load player bottom
	
	li $t4, BOTTOM_OF_SCREEN_LEVEL   # Check if player on ground and branch accordingly
	bge $t3, $t4, on_ground
	
	# Platform_1 coordinates --> (25, 53, 18)
	li $t5, 25
	li $t6, 53
	li $t7, 43
	
	# Check if player's bottom collides with platform top
	bne $t3, $t6, check_player_platform_2_collide
	# Check if player right < platform left and player left > platform right
	blt $t2, $t5, check_player_platform_2_collide
	bgt $t0, $t7, check_player_platform_2_collide

	j on_platform
    
check_player_platform_2_collide:
	# Platform2 coordinates --> (38, 42, 18)
	li $t5, 38
	li $t6, 42
	li $t7, 56
	
	bne $t3, $t6, check_player_platform_3_collide
	blt $t2, $t5, check_player_platform_3_collide
	bgt $t0, $t7, check_player_platform_3_collide
	
	j on_platform
    
check_player_platform_3_collide:
	# Platform3 coordinates --> (5, 35, 18)
	li $t5, 5
	li $t6, 35
	li $t7, 23
	
	bne $t3, $t6, check_player_platform_4_collide
	blt $t2, $t5, check_player_platform_4_collide
	bgt $t0, $t7, check_player_platform_4_collide
	
	j on_platform
    
check_player_platform_4_collide:
	# Platform4 coordinates --> (5, 25, 18)
	li $t5, 5
	li $t6, 25
	li $t7, 23
	
	bne $t3, $t6, platform_check_done
	blt $t2, $t5, platform_check_done
	bgt $t0, $t7, platform_check_done
	
	j on_platform
    
on_ground:
	li $t1, PLAYER_BEGINNING_Y_POS
	sw $t1, Y_POS_PLAYER
	li $v0, 1   # Return whether player on ground or not
	
	j platform_check_done
    
on_platform:
	# Positions player to stand on platform
	sub $t1, $t6, MAIN_CHARACTER_HEIGHT
	sw $t1, Y_POS_PLAYER
	li $v0, 1   # Return whether player on platform or not
    
platform_check_done:
	jr $ra
    
process_bullet:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
    
	lw $t0, X_POS_BULLET       # Check if bullet shot
	bltz $t0, bullet_updated   # Ignore if no bullet shot

	jal clear_current_bullet   # Clear bullet from current position

	lw $t0, X_POS_BULLET
	addi $t0, $t0, VELOCITY_BULLET   # Move bullet 2 pixels left
	sw $t0, X_POS_BULLET

	li $t1, FRAME_SIZE         # Max right for screen
	bge $t0, $t1, deactivate_bullet  # Remove bullet if it goes past the max right

	jal check_bullet_shot_enemy      # Check if bullet shot an enemy

	jal display_bullet        # Draw bullet after it has shifted left
	j bullet_updated
    
deactivate_bullet:
	li $t0, -1
	sw $t0, X_POS_BULLET      # Reset bullet position when deactivating bullet
	sw $t0, Y_POS_BULLET
    
bullet_updated:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
    
	jr $ra

clear_current_bullet:
	# Only erase if bullet shot
	lw $t5, X_POS_BULLET
	lw $t2, Y_POS_BULLET
	bltz $t5, bullet_cleared
    
	li $t1, BLACK_COLOUR
	li $t6, BASE_ADDRESS
    	
    	# (already mentioned what this does above...)
	li $t4, FRAME_SIZE
	mult $t2, $t4
	mflo $t3
	add $t3, $t3, $t5
	li $t4, UNIT_WIDTH_PIXELS
	mult $t3, $t4
	mflo $t3
	add $t6, $t6, $t3    # Final memory address (with offset applied)
    	
    	# Clear bullet pixel by pixel
	sw $t1, 0($t6)
	sw $t1, 4($t6)
    
bullet_cleared:
	jr $ra

display_bullet:
	# Display bullet at current position if it is shot
	lw $t5, X_POS_BULLET   # Load x position of bullet
	lw $t2, Y_POS_BULLET   # Load y position of bullet
	bltz $t5, bullet_drawn
    
	lw $t1, BULLET_COLOUR  # Load bullet colour
	li $t6, BASE_ADDRESS
    
	li $t4, FRAME_SIZE
	mult $t2, $t4
	mflo $t3
	add $t3, $t3, $t5
	li $t4, UNIT_WIDTH_PIXELS
	mult $t3, $t4
	mflo $t3
	add $t6, $t6, $t3     # Final memory address (with offset applied)
	
	# Display bullet pixel by pixel
	sw $t1, 0($t6)
	sw $t1, 4($t6)
    
bullet_drawn:
	jr $ra
    
check_bullet_shot_enemy:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
    
    	# Only check collision if bullet is shot
	lw $t0, X_POS_BULLET
	lw $t1, Y_POS_BULLET
	
	# Ignore checking collision if no bullet shot
	bltz $t0, bullet_collision_done
	
	# Check bullet collision with enemy 1 if it is alive
	lw $t2, ENEMY_1_ALIVE
	beqz $t2, check_shot_enemy2   # if not alive, handle enemy 2 & bullet collision
    
	lw $t3, X_POS_ENEMY_1         # Load enemy 1 x pos
	lw $t4, Y_POS_ENEMY_1         # Load enemy 1 y pos

	blt $t1, $t4, check_shot_enemy2     # Bullet shot is above enemy 1
	addi $t5, $t4, 8                    # Add enemy 1 height to get bottom y position of enemy 1
	bge $t1, $t5, check_shot_enemy2     # Bullet shot is below enemy 1

	addi $t7, $t0, 2                    # Add bullet width to get right-side x position of bullet
	blt $t7, $t3, check_shot_enemy2     # Bullet shot is on left of enemy 1
	addi $t5, $t3, 7                    # Enemy right edge (7 pixels wide)
	bge $t0, $t5, check_shot_enemy2     # Bullet shot is on right of enemy 1

	li $t0, 0
	sw $t0, ENEMY_1_ALIVE               # Mark enemy as dead if shot
	li $t0, REVIVE_ENEMY_DELAY
	sw $t0, REVIVE_ENEMY_1_COUNTDOWN    # Countdown for reviving the shot enemy
	
	li $t0, -1
	sw $t0, X_POS_BULLET      # Unactivate bullet
	sw $t0, Y_POS_BULLET
	
	jal erase_enemy_1
	j bullet_collision_done

check_shot_enemy2:
	# Check bullet collision with enemy 2 if it is alive
	lw $t2, ENEMY_2_ALIVE
	beqz $t2, bullet_collision_done
    
	lw $t3, X_POS_ENEMY_2      # Load enemy 2 x pos
	lw $t4, Y_POS_ENEMY_2      # Load enemy 2 y pos
	
	# Same checks as for enemy 1 mentioned previously
	blt $t1, $t4, bullet_collision_done
	addi $t5, $t4, 8
	bge $t1, $t5, bullet_collision_done
	
	addi $t7, $t0, 2
	blt $t7, $t3, bullet_collision_done
	addi $t5, $t3, 7
	bge $t0, $t5, bullet_collision_done
	
	li $t0, 0
	sw $t0, ENEMY_2_ALIVE              # Mark enemy as dead if shot
	li $t0, REVIVE_ENEMY_DELAY
	sw $t0, REVIVE_ENEMY_2_COUNTDOWN   # Countdown for reviving the shot enemy

	li $t0, -1
	sw $t0, X_POS_BULLET      # Unactivate bullet
	sw $t0, Y_POS_BULLET
	
	jal erase_enemy_2

bullet_collision_done:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

erase_enemy_1:
	lw $t5, X_POS_ENEMY_1    # Load enemy 1 x pos
	lw $t2, Y_POS_ENEMY_1    # Load enemy 1 y pos
	li $t1, BLACK_COLOUR     # Load background colour
	li $t9, BASE_ADDRESS
    
	li $t4, FRAME_SIZE
	mult $t2, $t4
	mflo $t8
	add $t8, $t8, $t5
	li $t4, UNIT_WIDTH_PIXELS
	mult $t8, $t4
	mflo $t8
	add $t9, $t9, $t8        # Final memory address (with offset applied)
	
	# Erase enemy 1 pixel by pixel
	# Row 1
	sw $t1, 8($t9)
	sw $t1, 12($t9)
	sw $t1, 16($t9)
	
	# Row 2
	addi $t9, $t9, 256
	sw $t1, 4($t9)
	sw $t1, 8($t9)
	sw $t1, 12($t9)
	sw $t1, 16($t9)
	sw $t1, 20($t9)
	
	# Row 3
	addi $t9, $t9, 256
	sw $t1, 4($t9)
	sw $t1, 8($t9)
	sw $t1, 12($t9)
	sw $t1, 16($t9)
	sw $t1, 20($t9)
	
	# Row 4
	addi $t9, $t9, 256
	sw $t1, 4($t9)
	sw $t1, 8($t9)
	sw $t1, 12($t9)
	sw $t1, 16($t9)
	sw $t1, 20($t9)

	# Row 5
	addi $t9, $t9, 256
	sw $t1, 0($t9)
	sw $t1, 4($t9)
	sw $t1, 8($t9)
	sw $t1, 12($t9)
	sw $t1, 16($t9)
	sw $t1, 20($t9)
	sw $t1, 24($t9)
    
	# Row 6
	addi $t9, $t9, 256
	sw $t1, 4($t9)
	sw $t1, 8($t9)
	sw $t1, 12($t9)
	sw $t1, 16($t9)
	sw $t1, 20($t9)
    
	# Row 7
	addi $t9, $t9, 256
	sw $t1, 4($t9)
	sw $t1, 8($t9)
	sw $t1, 12($t9)
	sw $t1, 16($t9)
	sw $t1, 20($t9)
	
	# Row 8
	addi $t9, $t9, 256
	sw $t1, 8($t9)
	sw $t1, 16($t9)
	
	jr $ra

erase_enemy_2:
	lw $t5, X_POS_ENEMY_2    # Load enemy 2 x pos
	lw $t2, Y_POS_ENEMY_2    # Load enemy 2 y pos
	li $t1, BLACK_COLOUR     # Load background colour
	li $t9, BASE_ADDRESS
	
	li $t4, FRAME_SIZE
	mult $t2, $t4
	mflo $t8
	add $t8, $t8, $t5
	li $t4, UNIT_WIDTH_PIXELS
	mult $t8, $t4
	mflo $t8
	add $t9, $t9, $t8        # Final memory address (with offset applied)
	
	# Erase enemy 2 pixel by pixel
	# Row 1
	sw $t1, 8($t9)
	sw $t1, 12($t9)
	sw $t1, 16($t9)
    
	# Row 2
	addi $t9, $t9, 256
	sw $t1, 4($t9)
	sw $t1, 8($t9)
	sw $t1, 12($t9)
	sw $t1, 16($t9)
	sw $t1, 20($t9)
    
	# Row 3
	addi $t9, $t9, 256
	sw $t1, 4($t9)
	sw $t1, 8($t9)
	sw $t1, 12($t9)
	sw $t1, 16($t9)
	sw $t1, 20($t9)

	# Row 4
	addi $t9, $t9, 256
	sw $t1, 4($t9)
	sw $t1, 8($t9)
	sw $t1, 12($t9)
	sw $t1, 16($t9)
	sw $t1, 20($t9)

	# Row 5
	addi $t9, $t9, 256
	sw $t1, 0($t9)
	sw $t1, 4($t9)
	sw $t1, 8($t9)
	sw $t1, 12($t9)
	sw $t1, 16($t9)
	sw $t1, 20($t9)
	sw $t1, 24($t9)
    
	# Row 6
	addi $t9, $t9, 256
	sw $t1, 4($t9)
	sw $t1, 8($t9)
	sw $t1, 12($t9)
	sw $t1, 16($t9)
	sw $t1, 20($t9)
	
	# Row 7
	addi $t9, $t9, 256
	sw $t1, 4($t9)
	sw $t1, 8($t9)
	sw $t1, 12($t9)
	sw $t1, 16($t9)
	sw $t1, 20($t9)
	
	# Row 8
	addi $t9, $t9, 256
	sw $t1, 8($t9)
	sw $t1, 16($t9)
	
	jr $ra

process_reviving_enemies:
	lw $t9, ENEMY_1_ALIVE    # Load status of enemy 1 (alive or not)
	bnez $t9, handle_enemy_2_revive    # Ignore reviving if enemy 1 allready alive, move on to enemy 2
	
	lw $t8, REVIVE_ENEMY_1_COUNTDOWN   # Get countdown leftover
	beqz $t8, revive_enemy1_now        # Revive enemy if countdown ended
	addi $t8, $t8, -1                  # Decrease countdown
	sw $t8, REVIVE_ENEMY_1_COUNTDOWN   # Store updated countdown value
	
	j handle_enemy_2_revive

revive_enemy1_now:
	li $t7, 1
	sw $t7, ENEMY_1_ALIVE     # Enemy 1 gets alive status
	
	li $t6, ENEMY1_BEGINNING_X_POS
	sw $t6, X_POS_ENEMY_1     # Reset enemy 1 x pos
	li $t5, ENEMY1_BEGINNING_Y_POS
	sw $t5, Y_POS_ENEMY_1     # Reset enemy 1 y pos

handle_enemy_2_revive:
	lw $t4, ENEMY_2_ALIVE    # Load status of enemy 2 (alive or not)
	bnez $t4, revive_enemies_updated    # Ignore reviving if enemy 2 alive
	
	# (process mentioned above already...)
	lw $t3, REVIVE_ENEMY_2_COUNTDOWN
	beqz $t3, revive_enemy2_now
	addi $t3, $t3, -1
	sw $t3, REVIVE_ENEMY_2_COUNTDOWN
	j revive_enemies_updated

revive_enemy2_now:
	li $t2, 1
	sw $t2, ENEMY_2_ALIVE     # Enemy 2 gets alive status
	
	li $t1, ENEMY1_BEGINNING_X_POS
	sw $t1, X_POS_ENEMY_2     # Reset enemy 2 x pos
	li $t0, ENEMY2_BEGINNING_Y_POS
	sw $t0, Y_POS_ENEMY_2     # Reset enemy 2 y pos

revive_enemies_updated:
	jr $ra


check_player_enemy_collision:
	addi $sp, $sp, -16
	sw $ra, 0($sp)
	sw $t0, 4($sp)
	sw $t1, 8($sp)
	sw $t2, 12($sp)
	
	lw $t0, X_POS_PLAYER          # Load player left
	lw $t1, Y_POS_PLAYER          # Load player top
	addi $t2, $t0, MAIN_CHARACTER_WIDTH   # Load player right
	addi $t3, $t1, MAIN_CHARACTER_HEIGHT  # Load player bottom
	
	# Check enemy 1 if alive
	lw $t4, ENEMY_1_ALIVE
	beqz $t4, check_player_enemy2_collision  # Ignore checking collision if not alive, move on to enemy 2
    
	# Enemy 1 coordinates & dimensions
	lw $t5, X_POS_ENEMY_1         # Enemy left edge
	lw $t6, Y_POS_ENEMY_1         # Enemy top edge
	addi $t7, $t5, 7              # Enemy right (7 pixels wide)
	addi $t8, $t6, 8              # Enemy bottom (8 pixels tall)
    
	# Check if player bottom < enemy top, move on to check next enemy
	blt $t3, $t6, check_player_enemy2_collision
	# Check if player top > enemy bottom, move on to check next enemy
	bgt $t1, $t8, check_player_enemy2_collision
	# Check if player right < enemy left, move on to check next enemy
	blt $t2, $t5, check_player_enemy2_collision
	# Check if player left > enemy right, move on to check next enemy
	bgt $t0, $t7, check_player_enemy2_collision
    
	# Handle collision of player with enemy 1
	j player_enemy_collide
    
check_player_enemy2_collision:
	# Check enemy 2 if alive
	lw $t4, ENEMY_2_ALIVE
	beqz $t4, player_enemy_no_collision   # Ignore checking player enemy collision if not alive
    
	# Enemy 2 coordinates
	lw $t5, X_POS_ENEMY_2         # Enemy left edge
	lw $t6, Y_POS_ENEMY_2         # Enemy top edge
	addi $t7, $t5, 7              # Enemy right (7 pixels wide)
	addi $t8, $t6, 8              # Enemy bottom (8 pixels tall)
    
	# Check if player bottom < enemy top, no collision with any enemy
	blt $t3, $t6, player_enemy_no_collision
	# Check if player top > enemy bottom, no collision with any enemy
	bgt $t1, $t8, player_enemy_no_collision
	# Check if player right < enemy left, no collision with any enemy
	blt $t2, $t5, player_enemy_no_collision
	# Check if player left > enemy right, no collision with any enemy
	bgt $t0, $t7, player_enemy_no_collision
	
	# Handle collision of player with enemy 2
	j player_enemy_collide
    
player_enemy_collide:
	lw $t0, LIVES       # Load current number of lives
	blez $t0, player_enemy_no_collision   # Ignore if 0 lives left
	addi $t0, $t0, -1   # Reduce a life
	sw $t0, LIVES       # Store updated number of lives
	
	beqz $t0, end_game  # If no lives left, end the game (player lost)
	
	# Reset main character position to starting point
	li $t0, PLAYER_BEGINNING_X_POS
	sw $t0, X_POS_PLAYER   # Reset player x pos
	li $t0, PLAYER_BEGINNING_Y_POS
	sw $t0, Y_POS_PLAYER   # Reset player y pos
    
	# Clear all lives and redraw them (it will only show updated lives)
	jal erase_all_lives
	jal display_lives
    
	# Add a small delay so player can see the change
	li $v0, 32
	li $a0, 800
	syscall
    
	j player_enemy_no_collision
    
end_game:
	# Clear all hearts from screen - no more lives left
	jal erase_all_lives
	jal draw_lose_screen  # Render the lose screen (game over)
	j exit                # Exit the game

draw_lose_screen:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
    
	jal clear_screen     # Clear the entire screen
    
	# Display "0" for lives (no lives left)
	li $t7, BASE_ADDRESS
	li $t8, Y_POS_LIVES             # Load y position for drawing lives
	li $t9, LIVES_BEGINNING_X_POS   # Load starting x position for drawing lives
    
	li $t4, FRAME_SIZE
	mult $t8, $t4
	mflo $t5
	add $t5, $t5, $t9
	li $t4, UNIT_WIDTH_PIXELS
	mult $t5, $t4
	mflo $t5
	add $t7, $t7, $t5     # Final memory address (with offset applied)
    
	li $t1, LIVES_COLOUR  # Load lives/heart colour
    
	# Draw the "0" character at the top
	sw $t1, 4($t7)
	sw $t1, 8($t7)
	sw $t1, 12($t7)
	
	# Row 1
	addi $t7, $t7, 256
	sw $t1, 0($t7)
	sw $t1, 16($t7)
	
	# Row 2
	addi $t7, $t7, 256
	sw $t1, 0($t7)
	sw $t1, 16($t7)
	
	# Row 3
	addi $t7, $t7, 256
	sw $t1, 0($t7)
	sw $t1, 16($t7)
	
	# Row 4
	addi $t7, $t7, 256
	sw $t1, 4($t7)
	sw $t1, 8($t7)
	sw $t1, 12($t7)

	# Display lose message ("YOU LOSE")
	li $a0, X_POS_WIN_MESSAGE   # Load x pos of message
	li $a1, Y_POS_WIN_MESSAGE   # Load y pos of message
	li $a2, WIN_LOSE_MESSAGE_COLOUR   # Load message colour
    
	jal display_letter_Y
	addi $a0, $a0, 8
	jal display_letter_O
	addi $a0, $a0, 8
	jal display_letter_U
    
	li $a0, X_POS_WIN_MESSAGE
	li $t0, Y_POS_WIN_MESSAGE
	addi $a1, $t0, 8            # Space between YOU and LOSE (different lines)
    
	jal display_letter_L
	addi $a0, $a0, 8
	jal display_letter_O
	addi $a0, $a0, 8
	jal display_letter_S
	addi $a0, $a0, 8
	jal display_letter_E

	# Apply delay of 5 seconds before calling exit
	li $v0, 32
	li $a0, 5000
	syscall
    
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	j exit   # Exit the game

player_enemy_no_collision:
	lw $ra, 0($sp)
	lw $t0, 4($sp)
	lw $t1, 8($sp)
	lw $t2, 12($sp)
	addi $sp, $sp, 16
	
	jr $ra
	
display_lives:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
    
	# Clear all lives from screen
	jal erase_all_lives
    
	# Display only the current lives
	li $s0, 0                         # Counter for keeping track of lives to display
	li $t5, LIVES_BEGINNING_X_POS     # Starting X position for drawing lives
    
display_lives_loop:
	lw $t0, LIVES                          # Load the current lives
	bge $s0, $t0, lives_displayed_end      # Only draw active lives
	
	# Display one life/heart at coordinate (t5, Y_POS_LIVES) - these are arguments
	move $a0, $t5
	li $a1, Y_POS_LIVES
	jal life_sketch

	# Skip to the position for displaying next life/heart
	addi $t5, $t5, SPACE_BETWEEN_LIVES
	addi $s0, $s0, 1                       # Display lives counter++
	
	j display_lives_loop
    
lives_displayed_end:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

life_sketch:
	li $t7, BASE_ADDRESS
    
	li $t4, FRAME_SIZE
	mult $a1, $t4
	mflo $t8
	add $t8, $t8, $a0
	li $t4, UNIT_WIDTH_PIXELS
	mult $t8, $t4
	mflo $t8
	add $t7, $t7, $t8     # Final memory address (with offset applied)
    
	li $t1, LIVES_COLOUR  # Load lives/hearts colour
    
    	# Draw a single heart representing a life, pixel by pixel
	# Row 1
	sw $t1, 4($t7)
	sw $t1, 12($t7)
    
	# Row 2
	addi $t7, $t7, 256
	sw $t1, 0($t7)
	sw $t1, 4($t7)
	sw $t1, 8($t7)
	sw $t1, 12($t7)
	sw $t1, 16($t7)
    
	# Row 3
	addi $t7, $t7, 256
	sw $t1, 4($t7)
	sw $t1, 8($t7)
	sw $t1, 12($t7)
    
	# Row 4
	addi $t7, $t7, 256
	sw $t1, 8($t7)
    
	jr $ra

erase_all_lives:
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s0, 4($sp)
    
	li $s0, 0                        # Counter for keeping track of (all) lives to clear
	li $t5, LIVES_BEGINNING_X_POS    # Starting X position for drawing lives
    
erase_all_lives_loop:
	li $t0, STARTING_NUM_LIVES           # We need to clear all possible hearts
	bge $s0, $t0, lives_erased_end
	
	# Clear one life/heart at coordinate (t5, Y_POS_LIVES) - these are arguments
	move $a0, $t5
	li $a1, Y_POS_LIVES
	jal single_life_erase
	
	# Move to next heart position
	addi $t5, $t5, SPACE_BETWEEN_LIVES
	addi $s0, $s0, 1                    # Erase lives counter++
	
	j erase_all_lives_loop
    
lives_erased_end:
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	addi $sp, $sp, 8
	
	jr $ra

single_life_erase:
	li $t7, BASE_ADDRESS
    
	li $t4, FRAME_SIZE
	mult $a1, $t4
	mflo $t8
	add $t8, $t8, $a0
	li $t4, UNIT_WIDTH_PIXELS
	mult $t8, $t4
	mflo $t8
	add $t7, $t7, $t8     # Final memory address (with offset applied)
    
	li $t1, BLACK_COLOUR  # Load background colour
    
    	# Erase a single heart, representing a life being taken away
	# Row 1
	sw $t1, 4($t7)
	sw $t1, 12($t7)
    
	# Row 2
	addi $t7, $t7, 256
	sw $t1, 0($t7)
	sw $t1, 4($t7)
	sw $t1, 8($t7)
	sw $t1, 12($t7)
	sw $t1, 16($t7)
    
	# Row 3
	addi $t7, $t7, 256
	sw $t1, 4($t7)
	sw $t1, 8($t7)
	sw $t1, 12($t7)
    
	# Row 4
	addi $t7, $t7, 256
	sw $t1, 8($t7)
    
	jr $ra

display_winning_pickup:
	lw $t0, PICKUP_DISPLAYED   # Get status of pickup object (whether to display or not)
	beqz $t0, winning_pickup_handled
	li $t1, PICKUP_BOX_COLOUR  # Load pickup object colour
	li $t4, X_POS_PICKUP       # Load x pos of pickup
	li $t3, Y_POS_PICKUP       # Load y pos of pickup
	li $t2, BASE_ADDRESS
    
	li $t6, FRAME_SIZE
	mult $t3, $t6
	mflo $t5
	add $t5, $t5, $t4
	li $t6, UNIT_WIDTH_PIXELS
	mult $t5, $t6
	mflo $t5
	add $t2, $t2, $t5         # Final memory address (with offset applied)
    
    	# Display the winning pickup object pixel by pixel
	# Row 1
	sw $t1, 0($t2)
	sw $t1, 4($t2)
	sw $t1, 8($t2)
    
	# Row 2
	addi $t2, $t2, 256
	sw $t1, 0($t2)
	sw $t1, 4($t2)
	sw $t1, 8($t2)
    
	# Row 3
	addi $t2, $t2, 256
	sw $t1, 0($t2)
	sw $t1, 4($t2)
	sw $t1, 8($t2)
    
winning_pickup_handled:
	jr $ra

erase_winning_pickup:
	li $t1, BLACK_COLOUR
	li $t4, X_POS_PICKUP  # Load x pos of pickup object
	li $t3, Y_POS_PICKUP  # Load y pos of pickup object
	li $t2, BASE_ADDRESS
    
	li $t6, FRAME_SIZE
	mult $t3, $t6
	mflo $t5
	add $t5, $t5, $t4
	li $t6, UNIT_WIDTH_PIXELS
	mult $t5, $t6
	mflo $t5
	add $t2, $t2, $t5   # Final memory address (with offset applied)
    
	# Row 1
	sw $t1, 0($t2)
	sw $t1, 4($t2)
	sw $t1, 8($t2)
    
	# Row 2
	addi $t2, $t2, 256
	sw $t1, 0($t2)
	sw $t1, 4($t2)
	sw $t1, 8($t2)
    
	# Row 3
	addi $t2, $t2, 256
	sw $t1, 0($t2)
	sw $t1, 4($t2)
	sw $t1, 8($t2)
    
	jr $ra
    
process_player_pickup_collision:
	lw $t0, PICKUP_DISPLAYED    # Get status of pickup (displayed or not)
	beqz $t0, player_pickup_collision_handled  # Ignore checking collision if no pickup displayed
    
	# Current coordinates of main character on screen
	lw $t1, X_POS_PLAYER            # Current x position of the pickup
	lw $t2, Y_POS_PLAYER            # Current y position of the pickup
	addi $t3, $t1, MAIN_CHARACTER_WIDTH   # Add player width to get right side x position
	addi $t4, $t2, MAIN_CHARACTER_HEIGHT  # Add player height to get bottom y position
	
	# Coordinates and dimensions of the winning pickup object (a 3*3 box)
	li $t5, X_POS_PICKUP            # X position of the pickup  
	li $t6, Y_POS_PICKUP            # Y position of the pickup
	addi $t7, $t5, WIDTH_OF_PICKUP  # Add pickup width to start x pos to give right side x pos
	addi $t8, $t6, WIDTH_OF_PICKUP  # Add pickup height to start y pos to give bottom y pos
	
	blt $t4, $t6, player_pickup_collision_handled  # Player above
	bgt $t2, $t8, player_pickup_collision_handled  # Player below
	blt $t3, $t5, player_pickup_collision_handled  # Player left
	bgt $t1, $t7, player_pickup_collision_handled  # Player right
	
	jal erase_winning_pickup
	sw $zero, PICKUP_DISPLAYED    # No pickup displayed status
	
	# Display the win screen, showing leftover lives
	jal draw_win_screen
    
player_pickup_collision_handled:
	jr $ra
    
draw_win_screen:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
    
	jal clear_screen     # Clear the entire screen
    
	# Draw remaining lives/hearts
	jal display_lives

	# Display win message ("YOU WIN!")
	li $a0, X_POS_WIN_MESSAGE   # Load x pos of message
	li $a1, Y_POS_WIN_MESSAGE   # Load y pos of message
	li $a2, WIN_LOSE_MESSAGE_COLOUR  # Load message colour
    
	jal display_letter_Y
	addi $a0, $a0, 8
	jal display_letter_O
	addi $a0, $a0, 8
	jal display_letter_U
    
	li $a0, X_POS_WIN_MESSAGE
	li $t0, Y_POS_WIN_MESSAGE
	addi $a1, $t0, 8     # Space kept between two lines (YOU and WIN!)
    
	jal display_letter_W
	addi $a0, $a0, 8
	jal display_letter_I
	addi $a0, $a0, 8
	jal display_letter_N
	addi $a0, $a0, 8

	jal display_exclamation_mark
	
	# 5 second delay applied before calling exit
	li $v0, 32
	li $a0, 5000
	syscall
    
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	j exit    # Exit the game

display_letter_Y:
	li $t7, BASE_ADDRESS
    
	li $t4, FRAME_SIZE            
	mult $a1, $t4
	mflo $t8
	add $t8, $t8, $a0
	li $t4, UNIT_WIDTH_PIXELS     
	mult $t8, $t4
	mflo $t8
	add $t7, $t7, $t8

	# Display Y pixel by pixel
	sw $a2, 0($t7)
	sw $a2, 16($t7)
    
	addi $t7, $t7, 256
	sw $a2, 4($t7)
	sw $a2, 12($t7)
    
	addi $t7, $t7, 256
	sw $a2, 8($t7)
    
	addi $t7, $t7, 256
	sw $a2, 8($t7)
    
	addi $t7, $t7, 256
	sw $a2, 8($t7)
    
	jr $ra

display_letter_O:
	li $t7, BASE_ADDRESS
    
	li $t4, FRAME_SIZE            
	mult $a1, $t4
	mflo $t8
	add $t8, $t8, $a0
	li $t4, UNIT_WIDTH_PIXELS     
	mult $t8, $t4
	mflo $t8
	add $t7, $t7, $t8
	
	# Display O pixel by pixel
	sw $a2, 4($t7)
	sw $a2, 8($t7)
	sw $a2, 12($t7)
    
	addi $t7, $t7, 256
	sw $a2, 0($t7)
	sw $a2, 16($t7)
    
	addi $t7, $t7, 256
	sw $a2, 0($t7)
	sw $a2, 16($t7)
    
	addi $t7, $t7, 256
	sw $a2, 0($t7)
	sw $a2, 16($t7)
    
	addi $t7, $t7, 256
	sw $a2, 4($t7)
	sw $a2, 8($t7)
	sw $a2, 12($t7)
    
	jr $ra

display_letter_U:
	li $t7, BASE_ADDRESS
    
	li $t4, FRAME_SIZE            
	mult $a1, $t4
	mflo $t8
	add $t8, $t8, $a0
	li $t4, UNIT_WIDTH_PIXELS     
	mult $t8, $t4
	mflo $t8
	add $t7, $t7, $t8

	# Display U pixel by pixel
	sw $a2, 0($t7)
	sw $a2, 16($t7)
    
	addi $t7, $t7, 256
	sw $a2, 0($t7)
	sw $a2, 16($t7)
    
	addi $t7, $t7, 256
	sw $a2, 0($t7)
	sw $a2, 16($t7)
    
	addi $t7, $t7, 256
	sw $a2, 0($t7)
	sw $a2, 16($t7)
    
	addi $t7, $t7, 256
	sw $a2, 4($t7)
	sw $a2, 8($t7)
	sw $a2, 12($t7)
    
	jr $ra

display_letter_W:
	li $t7, BASE_ADDRESS
    
	li $t4, FRAME_SIZE            
	mult $a1, $t4
	mflo $t8
	add $t8, $t8, $a0
	li $t4, UNIT_WIDTH_PIXELS     
	mult $t8, $t4
	mflo $t8
	add $t7, $t7, $t8
	
	# Display W pixel by pixel
	sw $a2, 0($t7)
	sw $a2, 16($t7)
    
	addi $t7, $t7, 256
	sw $a2, 0($t7)
	sw $a2, 16($t7)
    
	addi $t7, $t7, 256
	sw $a2, 0($t7)
	sw $a2, 8($t7)
	sw $a2, 16($t7)
    
	addi $t7, $t7, 256
	sw $a2, 0($t7)
	sw $a2, 8($t7)
	sw $a2, 16($t7)
    
	addi $t7, $t7, 256
	sw $a2, 0($t7)
	sw $a2, 4($t7)
	sw $a2, 12($t7)
	sw $a2, 16($t7)
    
	jr $ra

display_letter_I:
	li $t7, BASE_ADDRESS
    
	li $t4, FRAME_SIZE            
	mult $a1, $t4
	mflo $t8
	add $t8, $t8, $a0
	li $t4, UNIT_WIDTH_PIXELS     
	mult $t8, $t4
	mflo $t8
	add $t7, $t7, $t8
	
	# Display I pixel by pixel
	sw $a2, 0($t7)
	sw $a2, 4($t7)
	sw $a2, 8($t7)
	sw $a2, 12($t7)
	sw $a2, 16($t7)
    
	addi $t7, $t7, 256
	sw $a2, 8($t7)
    
	addi $t7, $t7, 256
	sw $a2, 8($t7)
    
	addi $t7, $t7, 256
	sw $a2, 8($t7)
    
	addi $t7, $t7, 256
	sw $a2, 0($t7)
	sw $a2, 4($t7)
	sw $a2, 8($t7)
	sw $a2, 12($t7)
	sw $a2, 16($t7)
    
	jr $ra

display_letter_N:
	li $t7, BASE_ADDRESS
    
	li $t4, FRAME_SIZE            
	mult $a1, $t4
	mflo $t8
	add $t8, $t8, $a0
	li $t4, UNIT_WIDTH_PIXELS     
	mult $t8, $t4
	mflo $t8
	add $t7, $t7, $t8

	# Display N pixel by pixel
	sw $a2, 0($t7)
	sw $a2, 16($t7)
    
	addi $t7, $t7, 256
	sw $a2, 0($t7)
	sw $a2, 4($t7)
	sw $a2, 16($t7)
    
	addi $t7, $t7, 256
	sw $a2, 0($t7)
	sw $a2, 8($t7)
	sw $a2, 16($t7)
    
	addi $t7, $t7, 256
	sw $a2, 0($t7)
	sw $a2, 12($t7)
	sw $a2, 16($t7)
    
	addi $t7, $t7, 256
	sw $a2, 0($t7)
	sw $a2, 16($t7)
    
	jr $ra

display_letter_L:
	li $t7, BASE_ADDRESS
    
	li $t4, FRAME_SIZE            
	mult $a1, $t4
	mflo $t8
	add $t8, $t8, $a0
	li $t4, UNIT_WIDTH_PIXELS     
	mult $t8, $t4
	mflo $t8
	add $t7, $t7, $t8
    	
    	# Display L pixel by pixel
	sw $a2, 0($t7)
    
	addi $t7, $t7, 256
	sw $a2, 0($t7)
    
	addi $t7, $t7, 256
	sw $a2, 0($t7)
    
	addi $t7, $t7, 256
	sw $a2, 0($t7)
    
	addi $t7, $t7, 256
	sw $a2, 0($t7)
	sw $a2, 4($t7)
	sw $a2, 8($t7)
	sw $a2, 12($t7)
	sw $a2, 16($t7)
    
	jr $ra
    
display_letter_S:
	li $t7, BASE_ADDRESS
    
	li $t4, FRAME_SIZE            
	mult $a1, $t4
	mflo $t8
	add $t8, $t8, $a0
	li $t4, UNIT_WIDTH_PIXELS     
	mult $t8, $t4
	mflo $t8
	add $t7, $t7, $t8
    
    	# Display S pixel by pixel
	sw $a2, 0($t7)
	sw $a2, 4($t7)
	sw $a2, 8($t7)
	sw $a2, 12($t7)
	sw $a2, 16($t7)
    
	addi $t7, $t7, 256
	sw $a2, 0($t7)
    
	addi $t7, $t7, 256
	sw $a2, 0($t7)
	sw $a2, 4($t7)
	sw $a2, 8($t7)
	sw $a2, 12($t7)
	sw $a2, 16($t7)
    
	addi $t7, $t7, 256
	sw $a2, 16($t7)
    
	addi $t7, $t7, 256
	sw $a2, 0($t7)
	sw $a2, 4($t7)
	sw $a2, 8($t7)
	sw $a2, 12($t7)
	sw $a2, 16($t7)
    
	jr $ra
    
display_letter_E:
	li $t7, BASE_ADDRESS
    
	li $t4, FRAME_SIZE            
	mult $a1, $t4
	mflo $t8
	add $t8, $t8, $a0
	li $t4, UNIT_WIDTH_PIXELS     
	mult $t8, $t4
	mflo $t8
	add $t7, $t7, $t8
    	
    	# Display E pixel by pixel
	sw $a2, 0($t7)
	sw $a2, 4($t7)
	sw $a2, 8($t7)
	sw $a2, 12($t7)
	sw $a2, 16($t7)
    
	addi $t7, $t7, 256
	sw $a2, 0($t7)
    
	addi $t7, $t7, 256
	sw $a2, 0($t7)
	sw $a2, 4($t7)
	sw $a2, 8($t7)
    
	addi $t7, $t7, 256
	sw $a2, 0($t7)
    
	addi $t7, $t7, 256
	sw $a2, 0($t7)
	sw $a2, 4($t7)
	sw $a2, 8($t7)
	sw $a2, 12($t7)
	sw $a2, 16($t7)
    
	jr $ra

display_exclamation_mark:
	li $t7, BASE_ADDRESS
    
	li $t4, FRAME_SIZE            
	mult $a1, $t4
	mflo $t8
	add $t8, $t8, $a0
	li $t4, UNIT_WIDTH_PIXELS     
	mult $t8, $t4
	mflo $t8
	add $t7, $t7, $t8
	
	# Display ! pixel by pixel
	sw $a2, 4($t7)
    
	addi $t7, $t7, 256
	sw $a2, 4($t7)
    
	addi $t7, $t7, 256
	sw $a2, 4($t7)
    
	addi $t7, $t7, 256
    
	addi $t7, $t7, 256
	sw $a2, 4($t7)
    
	jr $ra
    

    
