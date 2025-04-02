 ################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Dr Mario.
#
# Student 1: Shanaya Goel, 1010153361
# Student 2: Edison Yao, 10097978792
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       1
# - Unit height in pixels:      1
# - Display width in pixels:    64
# - Display height in pixels:   64
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################
    
    .data
##############################################################################
# Immutable Data
##############################################################################
ADDR_DSPL:  .word 0x10008000  # Bitmap display address
ADDR_KBRD:  .word 0xffff0000  # Keyboard address

# Colors
COLOR_GRAY:   .word 0x808080  # Wall color
COLOR_RED:    .word 0xFF0000  # Capsule left half
COLOR_BLUE:   .word 0x0000FF  # Capsule right half
COLOUR_BLACK: .word 0x000000  # Black for background

##############################################################################
# Our Variables
##############################################################################
# The Capsule
CAP0_ADDR:  .word ADDR_DSPL  # center pixel address
CAP0_COL:   .word COLOR_GRAY # center pixel colour
CAP1_ADDR:  .word ADDR_DSPL  # outer pixel address
CAP1_COL:   .word COLOR_GRAY # outer pixel colour
# should I add a variable related to orientation?
V1_ADDR:    .word ADDR_DSPL  # virus 1 location
V2_ADDR:    .word ADDR_DSPL  # virus 2 location
V3_ADDR:    .word ADDR_DSPL  # virus 3 location
# FOR PERUSING THE GRID
CHECKING_X: .word ADDR_DSPL  # x of the spot
CHECKING_Y: .word ADDR_DSPL  # y of the spot

# Gravity stuff
TIMER:      .word 0
TIMER_CAP:  .word 50
TIMER_ON_TIMER:  .word 0

# music stuff

notes:
    .word 
    82, 83, 82, 83, 81, 79, 79, 81, 82, 83, 81, 79, 79, 0, 0, 0, 
    82, 83, 82, 83, 81, 79, 79, 81, 60, 60, 61, 61, 62, 62, 63, 63, 
    82, 83, 82, 83, 81, 79, 79, 81, 82, 83, 81, 79, 79, 0, 0, 0, 
    82, 83, 82, 83, 81, 79, 79, 81, 84, 87, 84, 87, 85, 84, 83, 
    75, 76, 75, 76, 74, 72, 72, 74, 75, 76, 74, 72, 72, 0, 0, 0,
    75, 76, 75, 76, 74, 72, 72, 69, 64, 69, 72, 74, 72, 0, 71, 0, 
    75, 76, 74, 72, 72, 0, 0, 0, 75, 76, 74, 72, 72, 0, 0, 0,
    75, 76, 75, 76, 74, 72, 72, 69, 72, 0, 74, 0, 72, 0, 0
    
length: .word 126


durations:
  .word 100

# index for place in music sequence
MUSIC_INDEX: .word 0

# variable incremented by game loop to determine to move to next music MUSIC_INDEX
NOTE_INCREMENT: .word 0

##############################################################################
# Code
##############################################################################
	.text
	.globl main

main:
    
    la $t0, MUSIC_INDEX
    sw $zero, 0($t0) # reset MUSIC_INDEX

    la $t0, NOTE_INCREMENT
    sw $zero, 0($t0) # reset NOTE_INCREMENT
    
    la $t0, TIMER
    sw $zero, 0($t0) # reset timer
    
    la $t0, TIMER_ON_TIMER
    sw $zero, 0($t0) # reset timer cap
    
    li $t1, 50
    la $t0, TIMER_CAP
    sw $t1, 0($t0) # reset timer
    
    # Load the base address of the display
    lw $t0, ADDR_DSPL 

    # Draw the bottle
    jal draw_bottle
    
    # Draw viruses
    jal draw_viruses
    after_virus_draw:
    # Draw the first capsule
    li $t9, 0 # draw capsule preview for first time
    jal draw_capsule
    
    after_drawing_capsule:
    jal move_preview_capsule_to_main
    
    # Infinite loop (prevents program from exiting)
game_loop:

    # music stuff
    la $t2, MUSIC_INDEX # loading MUSIC INDEX address
    lw $t3, MUSIC_INDEX # loading MUSIC INDEX index
    lw $t4, NOTE_INCREMENT # loading note increment value
    li $t7, 1
    beq $t4, $t7, play_theme_song_note
    la $t5, NOTE_INCREMENT
    addi $t4, $t4, 1 # increment note increment value
    sw $t4, 0($t5) # set increment value
    j after_theme_music_stuff
    
    
    play_theme_song_note:

        li $t7, 126 # duration
        beq $t3, $t7, reset_theme_music_index
        j produce_theme_note

        reset_theme_music_index:
          li $t3, 0
          sw $t3, 0($t2)

        produce_theme_note:
        # sound effect
        
        la $t5, notes
        li $t7, 4
        mul $t6, $t7, $t3 # getting value to add to notes address
        add $t6, $t5, $t6 # t6 now holds actual place with note

        lw $t5, 0($t6) # t5 now holds the actual note
        li   $s4, 200        # Duration of base (i.e., eighth) note in milliseconds
        add   $a0, $zero, $t5      # note as loaded from list  
        li $a1, 100       # Set note duration 
        li   $a2, 17          # Set the MIDI patch 17 
        li   $a3, 64         # Set a volume 
        li   $v0, 33         # Asynchronous play sound
        syscall              # Play note
        
        # Buffer: Silent note (same pitch, volume = 0)
        move $a0, $t5            # Same note pitch
        li   $a1, 10             # Very short duration (10ms)
        li   $a2, 89             # Same instrument
        li   $a3, 0              # Volume = 0 (silent)
        li   $v0, 33             # syscall 33 (async play)
        syscall                  # Play silent note

        addi $t3, $t3, 1 # increment music index
        sw $t3, 0($t2) # set actual value to music index 

        li $t4, 0
        la $t5, NOTE_INCREMENT
        sw $t4, 0($t5) # set reset value of increment
        
    

    after_theme_music_stuff:
  
    # GRAVITY STUFF
    la $t2, TIMER # loading timer address
    lw $t3, TIMER # loading timer time
    addi $t3, $t3, 1 # add 1 to timer
    lw $t4, TIMER_CAP # cap on timer
    beq $t3, $t4, drop_down_gravity
    sw $t3, 0($t2)
    j after_gravity_stuff
    
    
    drop_down_gravity:
    sw $zero, 0($t2) # reset timer
    la $t2, TIMER_CAP # t2 now stores the address of timer_cap
    li $t7, 30
    beq $t7, $t4, respond_to_S # if timer cap = 30, just stay that way and drop
    la $t5, TIMER_ON_TIMER # adress
    lw $t6, TIMER_ON_TIMER # value
    li $t7, 1
    beq $t6, $t7, increase_gravity
    
    addi $t6, $t6, 1 # increment timer on timer
    sw $t6, 0($t5)
    j respond_to_S
    
    increase_gravity:
    addi $t4, $t4, -2 # reduce cap
    sw $t4, 0($t2) # set timer cap to new value
    sw $zero, 0($t5) # reset timer on timer
    j respond_to_S
    
    
    


    after_gravity_stuff:
    
    # check for virus elimination
    lw $t1, V1_ADDR
    lw $t8, 0($t1) # colour at V1_ADDR
    beq $zero, $t8, v2_end_check
    j after_virus_over_check
    v2_end_check:
    lw $t1, V2_ADDR
    lw $t8, 0($t1) # colour at V2_ADDR
    beq $zero, $t8, v3_end_check
    j after_virus_over_check
    
    v3_end_check:
    lw $t1, V3_ADDR
    lw $t8, 0($t1) # colour at V3_ADDR
    beq $zero, $t8, game_over_state
    j after_virus_over_check
    
    after_virus_over_check:
    # 1a. Check if key has been pressed
    li 		$v0, 32
	li 		$a0, 1
	syscall

    lw $t1, ADDR_KBRD               # $t1 = base address for keyboard
    lw $t8, 0($t1)                  # Load first word from keyboard
    beq $t8, 1, keyboard_input      # If first word 1, key is pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	redraw_screen:
	       # Load the base address of the display
           lw $t0, ADDR_DSPL 
           
	       lw $t2 CAP0_ADDR    # Load address of centre pixel
	       lw $t3 CAP0_COL     # Load colour of centre pixel
	       sw $t3 0($t2)       # Change colour of centre pixel to actual colour
	       lw $t2 CAP1_ADDR
	       lw $t3 CAP1_COL
	       sw $t3 0($t2)
	   
	# 3. we have Drawn the screen
	# Now to check if there is something bordering us from below
	lw $t2 CAP0_ADDR
	lw $t6 CAP1_ADDR
	addi $t8, $zero, 256
	sub $t5, $t6, $t2 # outer pixel location - centrak 
	beq $t5, $t8, base_collision_check_outer
	lw $t3 COLOUR_BLACK
	sub $t5, $t2, $t6 # outer pixel location - central
	beq $t5, $t8, base_collision_check_inner # if t4 is not black, there is a collision
	j base_collision_check_both
	# 4. Sleep
	li $v0, 32
	li $a0 16
	syscall

    # 5. Go back to Step 1
    j game_loop  
    
    

    
#######################GAME OVER CONSTRUCTION###################
game_over_state:
    li $t7, 0xFFFFFF # set colour to white
    jal draw_game_over
    
    # 4. Sleep
	li $v0, 32
	li $a0 16
	syscall
    
    game_over_state_loop:
    # 4. Sleep
	li $v0, 32
	li $a0 16
	syscall
    # 1a. Check if key has been pressed
    li 		$v0, 32
	li 		$a0, 1
	syscall

    lw $t1, ADDR_KBRD               # $t1 = base address for keyboard
    lw $t8, 0($t1)                  # Load first word from keyboard
    beq $t8, 1, check_game_over_keyboard_input      # If first word 1, key is pressed
    b game_over_state_loop
    
    
    
check_game_over_keyboard_input:
    
	
    lw $a0, 4($t1)                  # Load second word from keyboard
    beq $a0, 0x72, respond_to_R     # Check if the key p was pressed

    li $v0, 1                       # ask system to print $a0
    syscall

    b game_over_state_loop

respond_to_R:
    # lw $t7, COLOUR_BLACK
    # jal draw_game_over
    j reset_bitmap_display
    
    


# code for drawing "paused" message when game enters paused state        
        
draw_game_over:
    # assign start point 
    li $t1, 3
    li $t2, 20
    
    # Load the base address of the display
    lw $t0, ADDR_DSPL 
    
    # Screen width
    li $t9, 64 
    
    # $t7 is the colour black or white that is pushed in
    
    mul $t8, $t2, $t9  # assign y * screen width to $t8
    add $t8, $t8, $t1  # add x value to start of row y 
    sll $t8, $t8, 2    # some shifting stuff
    add $t8, $t8, $t0  # add grid location to base bitmap address
    
    # start drawing row 1 
    sw $t7, 0($t8)     # set first one to colour for g
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for a
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for m
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for e
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 12  # draw next pixel for o
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for v
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 8  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for e
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for r
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    
    # row 2 initialize
    li $t1, 3
    addi $t2, $t2, 1
    mul $t8, $t2, $t9  # assign y * screen width to $t8
    add $t8, $t8, $t1  # add x value to start of row y 
    sll $t8, $t8, 2    # some shifting stuff
    add $t8, $t8, $t0  # add grid location to base bitmap address
    # start drawing row 2
    
    sw $t7, 0($t8)     # set first one to colour for g
    
    addi $t8, $t8, 20  # draw next pixel for a
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 8  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for m
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 8  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 8  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for e
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 16  # draw next pixel for o
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 8  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for v
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 8  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for e
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 12  # draw next pixel for R
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 8  # draw next pixel
    sw $t7, 0($t8)     # set to colour

    
    # row 3 initialize
    li $t1, 3
    addi $t2, $t2, 1
    mul $t8, $t2, $t9  # assign y * screen width to $t8
    add $t8, $t8, $t1  # add x value to start of row y 
    sll $t8, $t8, 2    # some shifting stuff
    add $t8, $t8, $t0  # add grid location to base bitmap address
    # start drawing row 3
    
    sw $t7, 0($t8)     # set first one to colour for g
    addi $t8, $t8, 8  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for a
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for m
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 8  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 8  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for E
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 12  # draw next pixel for o
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 8  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for v
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 8  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for e
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for r
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour

    # row 4 initialize
    li $t1, 3
    addi $t2, $t2, 1
    mul $t8, $t2, $t9  # assign y * screen width to $t8
    add $t8, $t8, $t1  # add x value to start of row y 
    sll $t8, $t8, 2    # some shifting stuff
    add $t8, $t8, $t0  # add grid location to base bitmap address
    # start drawing row 4
    
    sw $t7, 0($t8)     # set first one to colour for g
    addi $t8, $t8, 12  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for a
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 8  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for m
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 8  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 8  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for e
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 16  # draw next pixel for o
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 8  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for v
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 8  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for e
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 12  # draw next pixel for R
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    
    ##INSERT ROW 5
    li $t1, 3
    addi $t2, $t2, 1
    mul $t8, $t2, $t9  # assign y * screen width to $t8
    add $t8, $t8, $t1  # add x value to start of row y 
    sll $t8, $t8, 2    # some shifting stuff
    add $t8, $t8, $t0  # add grid location to base bitmap address
    
    # start drawing row 5
    
    sw $t7, 0($t8)     # set first one to colour for g
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for a
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 8  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for m
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 8 # draw next pixel
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 8  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for e
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 12  # draw next pixel for o
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 12  # draw next pixel for v
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 12  # draw next pixel for e
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for r
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 8  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    # time to return
    jr $ra
        



reset_bitmap_display:
    # iterate through bitmap display and set each pixel to black
    # Load the base address of the display
    lw $t0, ADDR_DSPL 
    li $t8, 0
    li $t2, 0
    li $t3, 4096
    
    reset_bitmap_screen_loop:
    sw $t8, 0($t0)
    
    addi $t0, $t0, 4
    addi $t2, $t2, 1
    bgt $t3, $t2, reset_bitmap_screen_loop
    lw $t0, ADDR_DSPL 
    j main
    
    
    
    








#####################GAME OVER CONSTRCTII -------------------
    
    
    
base_collision_check_outer:
    lw $t2 CAP1_ADDR
	lw $t4 256($t2) # set t4 to address 1 lower than t2
	lw $t3 COLOUR_BLACK
	bne $t4, $t3, downward_collision # if t4 is not black, there is a collision
	li $v0, 32
	li $a0 16
	syscall
	j game_loop
base_collision_check_inner:
    lw $t2 CAP0_ADDR
	lw $t4 256($t2) # set t4 to address 1 lower than t2
	lw $t3 COLOUR_BLACK
	bne $t4, $t3, downward_collision # if t4 is not black, there is a collision
	li $v0, 32
	li $a0 16
	syscall
	j game_loop
	
base_collision_check_both:
    lw $t2 CAP1_ADDR
	lw $t4 256($t2) # set t4 to address 1 lower than t2
	lw $t3 COLOUR_BLACK
	bne $t4, $t3, downward_collision # if t4 is not black, there is a collision
	lw $t2 CAP0_ADDR
	lw $t4 256($t2) # set t4 to address 1 lower than t2
	lw $t3 COLOUR_BLACK
	bne $t4, $t3, downward_collision # if t4 is not black, there is a collision
    li $v0, 32
	li $a0 16
	syscall
	j game_loop

downward_collision:
    # First check if we should create new capsule
    lw $t2, CAP0_ADDR
    lw $t3, CAP1_ADDR
    # Check if the capsule has reached the top and the game is over
    beq $t2, 0x10009b28, game_over_state # check cap0 to redirect
    beq $t3, 0x10009c28, game_over_state # check cap1 to redirect
    
    
    # Load capsule colors to compare against
    lw $t4, CAP0_COL
    lw $t5, CAP1_COL
    
    li $t9, 0  # counter for CAP0 column matches
    li $t8, 0  # counter for CAP1 column matches
    
    # Check vertical column below CAP0
    check_cap0_column:
        lw $t6, 0($t2)       # current pixel color
        beq $t6, $t4, cap0_match  # if matches CAP0 color
        j check_cap1_column   # no match, move to CAP1 check
        
    cap0_match:
        addi $t9, $t9, 1      # increment match counter
        addi $t2, $t2, 256    # move down
        lw $t6, 0($t2)        # check next pixel
        beq $t6, $t4, cap0_match  # continue if still matching
    
    # Check vertical column below CAP1
    check_cap1_column:
        lw $t6, 0($t3)       # current pixel color
        beq $t6, $t5, cap1_match  # if matches CAP1 color
        j check_horizontal_rows # no match, move to horizontal check
        
    cap1_match:
        addi $t8, $t8, 1      # increment match counter
        addi $t3, $t3, 256    # move down
        lw $t6, 0($t3)        # check next pixel
        beq $t6, $t5, cap1_match  # continue if still matching
    
    check_horizontal_rows:
        # Check row for CAP0 first
        lw $t1, CAP0_ADDR
        andi $t7, $t1, 0xFFFFFF00 # Align to start of row
        
        # Prepare to scan the row
        li $s0, 0             # Current streak counter
        lw $s1, CAP0_COL      # Color to match
        move $s2, $t7         # Current position
        addi $s3, $t7, 64     # End of row
        li $s4, 0             # Start position of streak
        
    scan_row_for_streak:
        lw $t6, 0($s2)        # Get pixel color
        bne $t6, $s1, reset_streak # Reset if color doesn't match
        
        # If this is start of new streak, save position
        beqz $s0, set_streak_start
        j increment_streak
        
    set_streak_start:
        move $s4, $s2         # Save start of potential streak
        
    increment_streak:
        addi $s0, $s0, 1      # Increment streak counter
        bge $s0, 4, erase_streak # Found 4 in a row
        
    continue_scanning:
        addi $s2, $s2, 4      # Move to next pixel
        blt $s2, $s3, scan_row_for_streak
        j check_cap1_row       # No streak found in CAP0's row
        
    reset_streak:
        li $s0, 0             # Reset streak counter
        j continue_scanning
        
    erase_streak:
        # Plays a sound;
        li   $s3, 300        # Medium duration
        li   $a0, 84         # High pitch (C6)
        li   $a1, 300
        li   $a2, 13         # Bright bell-like sound
        li   $a3, 100        # Loud volume
        li   $v0, 33
        syscall
        
        # Add harmonic
        li   $a0, 96         # Even higher pitch
        li   $a1, 300
        syscall
        
        # Erase just the 4-pixel streak
        lw $t6, COLOUR_BLACK
        sw $t6, 0($s4)        # Erase first pixel
        sw $t6, 4($s4)        # Erase second pixel
        sw $t6, 8($s4)        # Erase third pixel
        sw $t6, 12($s4)       # Erase fourth pixel
        
        j check_vertical_erase # Skip CAP1 row check
        
    check_cap1_row:
        # Only check CAP1's row if different from CAP0's
        lw $t1, CAP1_ADDR
        andi $t7, $t1, 0xFFFFFF00
        beq $t7, $s4, check_vertical_erase # Skip if same row
        
        # Reset counters for CAP1's row
        li $s0, 0
        lw $s1, CAP1_COL
        move $s2, $t7
        addi $s3, $t7, 64
        
    scan_cap1_row:
        lw $t6, 0($s2)        # Get pixel color
        bne $t6, $s1, reset_cap1_streak
        
        beqz $s0, set_cap1_start
        j increment_cap1_streak
        
    set_cap1_start:
        move $s4, $s2         # Save start position
        
    increment_cap1_streak:
        addi $s0, $s0, 1
        bge $s0, 4, erase_cap1_streak
        j continue_cap1_scan
        
    reset_cap1_streak:
        li $s0, 0
        j continue_cap1_scan
        
    erase_cap1_streak:
        # Plays a sound;
        li   $s4, 300        # Medium duration
        li   $a0, 84         # High pitch (C6)
        li   $a1, 300
        li   $a2, 13         # Bright bell-like sound
        li   $a3, 100        # Loud volume
        li   $v0, 33
        syscall
        
        # Add harmonic
        li   $a0, 96         # Even higher pitch
        li   $a1, 300
        syscall
        
        lw $t6, COLOUR_BLACK
        sw $t6, 0($s4)
        sw $t6, 4($s4)
        sw $t6, 8($s4)
        sw $t6, 12($s4)
        
    continue_cap1_scan:
        addi $s2, $s2, 4
        blt $s2, $s3, scan_cap1_row
    check_vertical_erase:
        # Only erase if we have 4 or more in a column
        blt $t9, 4, check_cap1_erase

        # Plays a sound;
        li   $s4, 300        # Medium duration
        li   $a0, 84         # High pitch (C6)
        li   $a1, 300
        li   $a2, 13         # Bright bell-like sound
        li   $a3, 100        # Loud volume
        li   $v0, 33
        syscall
        
        # Add harmonic
        li   $a0, 96         # Even higher pitch
        li   $a1, 300
        syscall
        
        # Erase CAP0 column
        lw $t2, CAP0_ADDR
        lw $t6, COLOUR_BLACK
        sw $t6, 0($t2)        # erase first
        addi $t2, $t2, 256
        sw $t6, 0($t2)        # erase second
        addi $t2, $t2, 256
        sw $t6, 0($t2)        # erase third
        addi $t2, $t2, 256
        sw $t6, 0($t2)        # erase fourth
        
    check_cap1_erase:
        blt $t8, 4, column_check_done
        
        # Erase CAP1 column
        lw $t3, CAP1_ADDR
        lw $t6, COLOUR_BLACK
        sw $t6, 0($t3)        # erase first
        addi $t3, $t3, 256
        sw $t6, 0($t3)        # erase second
        addi $t3, $t3, 256
        sw $t6, 0($t3)        # erase third
        addi $t3, $t3, 256
        sw $t6, 0($t3)        # erase fourth
        
    column_check_done:
        li   $s4, 150        # Medium duration
        li   $a0, 60         # Lower pitch (C4) for "thud" effect
        li   $a1, 150        # Medium duration
        li   $a2, 13         # Xylophone instrument
        li   $a3, 90         # Strong volume
        li   $v0, 33
        syscall
        
        # Small delay before new capsule
        li $v0, 32
        li $a0, 16
        syscall
        
        jal drop_down_extras
        
        # Draw new capsule + move preview to main
        jal move_preview_capsule_to_main
        
paused_state:
    li $t7, 0xFFFFFF # set colour to white
    jal draw_paused
    
    # 4. Sleep
	li $v0, 32
	li $a0 16
	syscall
    
    paused_state_loop:
    # 4. Sleep
	li $v0, 32
	li $a0 16
	syscall
    # 1a. Check if key has been pressed
    li 		$v0, 32
	li 		$a0, 1
	syscall

    lw $t1, ADDR_KBRD               # $t1 = base address for keyboard
    lw $t8, 0($t1)                  # Load first word from keyboard
    beq $t8, 1, check_paused_keyboard_input      # If first word 1, key is pressed
    b paused_state_loop
    
    
    
check_paused_keyboard_input:
    
	
    lw $a0, 4($t1)                  # Load second word from keyboard
    beq $a0, 0x70, respond_to_P     # Check if the key p was pressed

    li $v0, 1                       # ask system to print $a0
    syscall

    b paused_state_loop

respond_to_P:
    lw $t7, COLOUR_BLACK
    jal draw_paused
    j redraw_screen
    
    


# code for drawing "paused" message when game enters paused state        
        
draw_paused:
    # assign start point 
    li $t1, 3
    li $t2, 20
    
    # Load the base address of the display
    lw $t0, ADDR_DSPL 
    
    # Screen width
    li $t9, 64 
    
    # $t7 is the colour black or white that is pushed in
    
    mul $t8, $t2, $t9  # assign y * screen width to $t8
    add $t8, $t8, $t1  # add x value to start of row y 
    sll $t8, $t8, 2    # some shifting stuff
    add $t8, $t8, $t0  # add grid location to base bitmap address
    
    # start drawing row 1 
    sw $t7, 0($t8)     # set first one to colour for p
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for a
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for u
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 8  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 12  # draw next pixel for s
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for E
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for D
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    # row 2 initialize
    li $t1, 3
    addi $t2, $t2, 1
    mul $t8, $t2, $t9  # assign y * screen width to $t8
    add $t8, $t8, $t1  # add x value to start of row y 
    sll $t8, $t8, 2    # some shifting stuff
    add $t8, $t8, $t0  # add grid location to base bitmap address
    # start drawing row 2
    
    sw $t7, 0($t8)     # set first one to colour for p
    addi $t8, $t8, 8  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for a
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 8  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for u
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 8  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 12  # draw next pixel for s
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 12  # draw next pixel for E
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 12  # draw next pixel for D
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 12  # draw next pixel
    sw $t7, 0($t8)     # set to colour

    
    # row 3 initialize
    li $t1, 3
    addi $t2, $t2, 1
    mul $t8, $t2, $t9  # assign y * screen width to $t8
    add $t8, $t8, $t1  # add x value to start of row y 
    sll $t8, $t8, 2    # some shifting stuff
    add $t8, $t8, $t0  # add grid location to base bitmap address
    # start drawing row 3
    
    sw $t7, 0($t8)     # set first one to colour for p
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for a
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for u
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 8  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 12  # draw next pixel for s
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 12  # draw next pixel for E
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for D
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 12  # draw next pixel
    sw $t7, 0($t8)     # set to colour

    # row 4 initialize
    li $t1, 3
    addi $t2, $t2, 1
    mul $t8, $t2, $t9  # assign y * screen width to $t8
    add $t8, $t8, $t1  # add x value to start of row y 
    sll $t8, $t8, 2    # some shifting stuff
    add $t8, $t8, $t0  # add grid location to base bitmap address
    # start drawing row 4
    
    sw $t7, 0($t8)     # set first one to colour for p
    
    addi $t8, $t8, 16  # draw next pixel for a
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 8  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for u
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 8  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 12  # draw next pixel for s
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 12  # draw next pixel for E
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 12  # draw next pixel for D
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 12  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    
    ##INSERT ROW 5
    li $t1, 3
    addi $t2, $t2, 1
    mul $t8, $t2, $t9  # assign y * screen width to $t8
    add $t8, $t8, $t1  # add x value to start of row y 
    sll $t8, $t8, 2    # some shifting stuff
    add $t8, $t8, $t0  # add grid location to base bitmap address
    
    # start drawing row 5
    
    sw $t7, 0($t8)     # set first one to colour for p
    
    addi $t8, $t8, 16  # draw next pixel for a
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 8  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for u
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for s
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 12  # draw next pixel for E
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    addi $t8, $t8, 8  # draw next pixel for D
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    addi $t8, $t8, 4  # draw next pixel
    sw $t7, 0($t8)     # set to colour
    
    
    
    # time to return
    jr $ra
        
        
        
        
##############UNDER MAJOR CONSTRUCTION##########
##############UNDER MAJOR CONSTRUCTION##########
##############UNDER MAJOR CONSTRUCTION##########

        
downward_collision_after_dropping_extras:
    lw $t1, ADDR_KBRD               # $t1 = base address for keyboard

    # LETS SAY $t8 is the location of the current pixel
    add $t2, $t8, $zero # assign current pixel address to og address of cap0
    
    # Check if the capsule has reached the top and the game is over
    beq $t2, 0x10009b28, respond_to_Q # check cap0 to redirect
   
    
    
    # Load capsule colors to compare against
    lw $t4, 0($t2)
    
    
    li $t9, 0  # counter for pixel column matches
    
    
    # Check vertical column below pixel
    check_pix_column:
        lw $t6, 0($t2)       # current pixel color
        beq $t6, $t4, pix_match  # if matches pix color
        j check_horizontal_rows_pix   # no match, move to chck horizontal rows
        
    pix_match:
        addi $t9, $t9, 1      # increment match counter
        addi $t2, $t2, 256    # move down
        lw $t6, 0($t2)        # check next pixel
        beq $t6, $t4, pix_match  # continue if still matching
    
    
    check_horizontal_rows_pix:
        # Check row for CAP0 first
        add $t1, $t8, $zero
        andi $t7, $t1, 0xFFFFFF00 # Align to start of row
        
        # Prepare to scan the row
        li $s0, 0             # Current streak counter
        lw $s1, 0($t8)      # Color to match
        move $s2, $t7         # Current position
        addi $s3, $t7, 64     # End of row
        li $s4, 0             # Start position of streak
        
    scan_row_for_streak_pix:
        lw $t6, 0($s2)        # Get pixel color
        bne $t6, $s1, reset_streak_pix # Reset if color doesn't match
        
        # If this is start of new streak, save position
        beqz $s0, set_streak_start_pix
        j increment_streak_pix
        
    set_streak_start_pix:
        move $s4, $s2         # Save start of potential streak
        
    increment_streak_pix:
        addi $s0, $s0, 1      # Increment streak counter
        bge $s0, 4, erase_streak_pix # Found 4 in a row
        
    continue_scanning_pix:
        addi $s2, $s2, 4      # Move to next pixel
        blt $s2, $s3, scan_row_for_streak_pix
        j check_vertical_erase_pix       # No streak found in pix's row
        
    reset_streak_pix:
        li $s0, 0             # Reset streak counter
        j continue_scanning_pix
        
    erase_streak_pix:
        # Erase just the 4-pixel streak
        lw $t6, COLOUR_BLACK
        sw $t6, 0($s4)        # Erase first pixel
        sw $t6, 4($s4)        # Erase second pixel
        sw $t6, 8($s4)        # Erase third pixel
        sw $t6, 12($s4)       # Erase fourth pixel
        j check_vertical_erase_pix # 
        
    
    check_vertical_erase_pix:
        # Only erase if we have 4 or more in a column
        blt $t9, 4, column_check_done_pix
        # Erase CAP0 column
        add $t2, $t8, $zero
        lw $t6, COLOUR_BLACK
        sw $t6, 0($t2)        # erase first
        addi $t2, $t2, 256
        sw $t6, 0($t2)        # erase second
        addi $t2, $t2, 256
        sw $t6, 0($t2)        # erase third
        addi $t2, $t2, 256
        sw $t6, 0($t2)        # erase fourth
        
    column_check_done_pix:
      
        # Small delay before new capsule
        li $v0, 32
        li $a0, 16
        syscall
        
        j post_dropping_extras_stuff






#############UNDER CONSTRUCTION##########
#############UNDER CONSTRUCTION##########
#############UNDER CONSTRUCTION##########
#############UNDER CONSTRUCTION##########


        
        
        
        
        
        
        
        
        
        

# When column is cleared drop down extra unsupported bits
drop_down_extras:
    # check row first then column iterate elements of bottom row, then next from bottom, then...
    # Load the base address of the display
    lw $t0, ADDR_DSPL
    
    # Screen width
    li $t9, 64 
    
    # starting column
    li $t1, 5
    la $t3, CHECKING_X
    sw $t1, 0($t3) # set CHECKING_X to 5
    # starting row
    li $t2, 47
    la $t3, CHECKING_Y
    sw $t2, 0($t3) # set CHECKING_Y to 47
    
    drop_down_extra_run:
    # Load the base address of the display
    lw $t0, ADDR_DSPL 
    
    # Screen width
    li $t9, 64 
    
    #hopefully this works
    lw $t1, CHECKING_X
    lw $t2, CHECKING_Y
    
    mul $t8, $t2, $t9  # assign y * screen width to $t8
    add $t8, $t8, $t1  # add x value to start of row y 
    sll $t8, $t8, 2    # some shifting stuff
    add $t8, $t8, $t0  # add grid location to base bitmap address to produce actual bitmap address
    
    check_virus_for_drop_down_extras:
    # checking if its a virus
    
    lw $t4, V1_ADDR
    beq $t8, $t4, post_dropping_extras_stuff # if we're looking at v1 location, just skip past droping pixel
    lw $t4, V2_ADDR
    beq $t8, $t4, post_dropping_extras_stuff # if we're looking at v2 location, just skip past dropping pixel
    lw $t4, V3_ADDR
    beq $t8, $t4, post_dropping_extras_stuff # if we're looking at v3 location, just skip past dropping pixel
    
    #######TESTING#######
    dropping_pixel_T:
     lw $t7, 0($t8) # colour of current pixel
     beq $t7, $zero, after_drop_testing
     
     addi $t5, $t8, 256 # next pixel address is t5
     
     lw $t6, 0($t5) # colour of next pixel
     bne $t6, $zero, downward_collision_after_dropping_extras
     sw $zero, 0($t8)
     sw $t7, 0($t5)        # Change to curr pixel colour
     addi $t8, $t8, 256 # increment $t8 curr pixel address
     j dropping_pixel_T
    
    after_drop_testing:
    #######TESTING#########
    
    
    ################UNDER CONSTRUCTION ################
    # check at location of $t8
    #CODE STUFFHEWHFAGFGEW
    
    ################
    post_dropping_extras_stuff:
    
    li $t4, 16 # max x value
    la $t3, CHECKING_X
    lw $t1, 0($t3) # set $t1 to X value
    beq $t1, $t4, one_row_up
    addi $t1, $t1, 1 # increase column by 1
    sw $t1, 0($t3) # set CHECKING_X to to new value
    #j drop_down_extra_run
    # STAY ON ALERT
    j drop_down_extra_run
    
    one_row_up:
        li $t1, 5
        la $t3, CHECKING_X
        sw $t1, 0($t3) # set CHECKING_X to 5
        # take in row
        li $t4, 31 # max y value
        la $t3, CHECKING_Y
        lw $t2, 0($t3) # set $t2 to Y value
        
        # check for end row which is row 31
        beq $t2, $t4, end_drop_down_stuff
        addi $t2, $t2, -1 # increase row by 1
        sw $t2, 0($t3) # set CHECKING_Y to new value
        j drop_down_extra_run
    
    end_drop_down_stuff:
        #ADD CODE LATER TO END THIS DROPPING DOWN SEQUENCE ##############
        jr $ra
    

keyboard_input:                     # A key is pressed
    lw $a0, 4($t1)                  # Load second word from keyboard
    move $t2, $a0   # move value from $a0 to $t2
    
    beq $t2, 0x71, respond_to_Q     # Check if the key q was pressed
    beq $t2, 0x77, respond_to_W     # Check if the key w was pressed
    beq $t2, 0x61, respond_to_A     # Check if the key a was pressed
    beq $t2, 0x73, respond_to_S     # Check if the key s was pressed
    beq $t2, 0x64, respond_to_D     # Check if the key d was pressed
    beq $t2, 0x70, paused_state     # Check if the key p was pressed

    li $v0, 1                       # ask system to print $a0
    syscall

    b game_loop
    
# Quit
respond_to_Q:
	li $v0, 10                      # Quit gracefully
	syscall
    
# Rotate 90 degrees clockwise
respond_to_W:

    # sound effect
    li   $s4, 100        # Duration of base (i.e., eighth) note in milliseconds
  
    li   $a0, 72     # note   
    li $a1, 100       # Set note duration 
    li   $a2, 96          # Set the MIDI patch 0 (piano)
    li   $a3, 88         # Set a volume 
    li   $v0, 33         # Asynchronous play sound
    syscall              # Play note
    
    jal erase_capsule
    lw $t2 CAP0_ADDR    # load current pixel0 location
    lw $t3 CAP1_ADDR    # load current pixel1 location
    sub $t4, $t3, $t2
    addi $t5, $zero, 4
    beq $t4, $t5, W_rotate_r # if outer pixel is right of center
    addi $t5, $zero, -4
    beq $t4, $t5, W_rotate_l # if outer pixel is left of center
    addi $t5, $zero, 256
    beq $t4, $t5, W_rotate_d # if outer pixel is downward of center
    addi $t5, $zero, -256
    beq $t4, $t5, W_rotate_u # if outer pixel is upward of center
    
    W_rotate_r:
        addi $t3, $t3, 252
        la $t2 CAP1_ADDR
        lw $t6 COLOUR_BLACK
        lw $t7 0($t3)
        bne $t7, $t6, redraw_screen # if this change would cause pixel to overlap, just go back to rebuild capsule 
        sw $t3 0($t2)    # rotates outer pixel onto down
        j redraw_screen # go back to redraw screen in game_loop
        
    W_rotate_l:
        addi $t3, $t3, -252
        la $t2 CAP1_ADDR # load address of CAP1_ADDR into $t2 so it can be adjusted
        lw $t6 COLOUR_BLACK
        lw $t7 0($t3)
        bne $t7, $t6, redraw_screen # if this change would cause pixel to overlap, just go back to rebuild capsule 
        sw $t3 0($t2)    # rotates outer pixel onto up
        j redraw_screen # go back to redraw screen in game_loop
    W_rotate_d:
        addi $t3, $t3, -260
        la $t2 CAP1_ADDR
        lw $t6 COLOUR_BLACK
        lw $t7 0($t3)
        bne $t7, $t6, redraw_screen # if this change would cause pixel to overlap, just go back to rebuild capsule 
        sw $t3 0($t2)    # rotates outer pixel onto left
        j redraw_screen # go back to redraw screen in game_loop
    W_rotate_u:
        addi $t3, $t3, 260
        la $t2 CAP1_ADDR
        lw $t6 COLOUR_BLACK
        lw $t7 0($t3)
        bne $t7, $t6, redraw_screen # if this change would cause pixel to overlap, just go back to rebuild capsule 
        sw $t3 0($t2)    # rotates outer pixel onto right
        j redraw_screen # go back to redraw screen in game_loop

# Move left
respond_to_A:
    jal erase_capsule
    la $t3 CAP0_ADDR    # load address of cap0
    lw $t2 CAP0_ADDR    # load current pixel0 location
    addi $t2, $t2, -4   # move left
    lw $t6 COLOUR_BLACK
        lw $t7 0($t2)
        bne $t7, $t6, redraw_screen # if this change would cause pixel to overlap, just go back to rebuild capsule 
    add $t8, $zero, $t2
    add $t9, $zero, $t3
    la $t3 CAP1_ADDR    # load address of cap1
    lw $t2 CAP1_ADDR    # load current pixel1 location
    addi $t2, $t2, -4
    lw $t6 COLOUR_BLACK
        lw $t7 0($t2)
        bne $t7, $t6, redraw_screen # if this change would cause pixel to overlap, just go back to rebuild capsule 
    sw $t8 0($t9)    # store
    sw $t2 0($t3)
    j redraw_screen # go back to redraw screen in game_loop
    
# Move down
respond_to_S:
    
    jal erase_capsule
    la $t3 CAP0_ADDR 
    lw $t2 CAP0_ADDR    # load current pixel0 location
    addi $t2, $t2, 256  # move down
    lw $t6 COLOUR_BLACK
        lw $t7 0($t2)
        bne $t7, $t6, redraw_screen # if this change would cause pixel to overlap, just go back to rebuild capsule 
    add $t8, $zero, $t2
    add $t9, $zero, $t3
    la $t3 CAP1_ADDR    # load address of cap1
    lw $t2 CAP1_ADDR    # load current pixel1 location
    addi $t2, $t2, 256
    lw $t6 COLOUR_BLACK
        lw $t7 0($t2)
        bne $t7, $t6, redraw_screen # if this change would cause pixel to overlap, just go back to rebuild capsule 
    sw $t8 0($t9)    # store
    sw $t2 0($t3)
    j redraw_screen # go back to redraw screen in game_loop
    
# Move right
respond_to_D:
    
    jal erase_capsule
    la $t3 CAP0_ADDR 
    lw $t2 CAP0_ADDR    # load current pixel0 location
    addi $t2, $t2, 4   # move right
    lw $t6 COLOUR_BLACK
        lw $t7 0($t2)
        bne $t7, $t6, redraw_screen # if this change would cause pixel to overlap, just go back to rebuild capsule 
    add $t8, $zero, $t2
    add $t9, $zero, $t3
    la $t3 CAP1_ADDR    # load address of cap1
    lw $t2 CAP1_ADDR    # load current pixel1 location
    addi $t2, $t2, 4
    lw $t6 COLOUR_BLACK
        lw $t7 0($t2)
        bne $t7, $t6, redraw_screen # if this change would cause pixel to overlap, just go back to rebuild capsule 
    sw $t8 0($t9)    # store
    sw $t2 0($t3)
    j redraw_screen # go back to redraw screen in game_loop
erase_capsule:
    lw $t4 COLOUR_BLACK # load colour black
    lw $t2 CAP0_ADDR
    sw $t4 0($t2)    # set pixel0 of capsule to black
    lw $t2 CAP1_ADDR
    sw $t4 0($t2)
    jr $ra

##############################################################################
# Draw the bottle (Middle-Left)
##############################################################################
draw_bottle:
    li $t1, 0x808080   # Gray color for the walls
    li $t2, 30         # Start at y = 30
    li $t3, 4          # Left wall x = 4
    li $t4, 17         # Right wall x = 17
    li $t6, 64         # Screen width

    # Draw left wall
draw_left_wall:
    bgt $t2, 48, end_left_wall
    mul $t7, $t2, $t6  # y * 64
    add $t7, $t7, $t3  # y * 64 + x (left wall)
    sll $t7, $t7, 2    # Convert to byte address
    add $t7, $t7, $t0  # Add base address
    sw $t1, 0($t7)     # Store color
    addi $t2, $t2, 1   # Move down
    j draw_left_wall
    
end_left_wall:

    # Draw right wall
    li $t2, 30
    
draw_right_wall:
    bgt $t2, 48, end_right_wall
    mul $t7, $t2, $t6  
    add $t7, $t7, $t4  
    sll $t7, $t7, 2    
    add $t7, $t7, $t0  
    sw $t1, 0($t7)     
    addi $t2, $t2, 1  
    j draw_right_wall
    
end_right_wall:

    # Draw bottom
    li $t2, 48
    li $t3, 4
    
draw_bottom:
    bgt $t3, 17, end_bottom
    mul $t7, $t2, $t6  
    add $t7, $t7, $t3  
    sll $t7, $t7, 2    
    add $t7, $t7, $t0  
    sw $t1, 0($t7)     
    addi $t3, $t3, 1  
    j draw_bottom

end_bottom:
    li $t2, 26         # Neck start at y = 26
    li $t3, 8          # Neck left side x = 8
    li $t4, 13         # Neck right side x = 13
  
    # Draw vertical neck
draw_neck_vertical:
    bgt $t2, 29, end_neck_vertical
    mul $t7, $t2, $t6  # y * 64
    add $t8, $t7, $t3  # Left side (y * 64 + x)
    add $t9, $t7, $t4  # Right side (y * 64 + x)
    sll $t8, $t8, 2    # Convert to byte address
    sll $t9, $t9, 2    # Convert to byte address
    add $t8, $t8, $t0  # Add base address
    add $t9, $t9, $t0  # Add base address
    sw $t1, 0($t8)     # Store left color
    sw $t1, 0($t9)     # Store right color
    addi $t2, $t2, 1   # Move down
    j draw_neck_vertical
    
end_neck_vertical:

    # Draw diagonal connection from walls to neck
    li $t2, 30         # Start y = 24
    li $t3, 4          # Start x = 4 (left wall)
    li $t4, 10         # End x (left side of neck opening)
    li $t5, 13         # Start x (right side of neck opening)
    li $t6, 17         # End x (right wall)
    li $t7, 64         # Screen width

    # Draw left horizontal line (left wall to neck opening)
draw_left_neck_line:
    bgt $t3, 8, end_left_neck_line
    mul $t8, $t2, $t7  # y * 64
    add $t8, $t8, $t3  # y * 64 + x
    sll $t8, $t8, 2    # Convert to byte address
    add $t8, $t8, $t0  # Add base address
    sw $t1, 0($t8)     # Store color
    addi $t3, $t3, 1   # Move right
    j draw_left_neck_line
end_left_neck_line:

    # Draw right horizontal line (right side of neck opening to right wall)
draw_right_neck_line:
    bgt $t5, $t6, end_right_neck_line
    mul $t8, $t2, $t7  # y * 64
    add $t8, $t8, $t5  # y * 64 + x
    sll $t8, $t8, 2    # Convert to byte address
    add $t8, $t8, $t0  # Add base address
    sw $t1, 0($t8)     # Store color
    addi $t5, $t5, 1   # Move right
    j draw_right_neck_line
    
end_right_neck_line:

    jr $ra  # Return


##############################################################################
# Draw the first capsule (top of bottle)
##############################################################################

choose_random_color:
    li $v0, 42         # Syscall for random integer (0 ≤ result < $a0)
    li $a0, 0
    li $a1, 3    
    syscall            # Get a random number in $a0

    addi $a0, $a0, 1   # Shift range from (0-2) to (1-3)

    li $v0, 1          # Print integer (for testing)
    syscall

    beq $a0, 1, return_red
    beq $a0, 2, return_green
    beq $a0, 3, return_blue

return_red:
    li $v0, 0xFF0000
    jr $ra

return_green:
    li $v0, 0x00FF00
    jr $ra

return_blue:
    li $v0, 0x0000FF
    jr $ra

#############################
# construction@!!@3oufhudshfdgyfhsahfewiudgweuiF
#############################

draw_capsule:
    jal choose_random_color # Get a random number (1, 2, or 3)
    move $t1, $v0           # Store result in $t1
    jal choose_random_color # Get a random number (1, 2, or 3)
    move $t2, $v0           # Store result in $t2

    # Position the capsule at the top center of the bottle
    li $t3, 35   # Y position
    li $t4, 20   # Center(ish) of the bottle

    # Screen width
    li $t5, 64  

    # Draw upper half of capsule
    mul $t6, $t3, $t5  
    add $t6, $t6, $t4  
    sll $t6, $t6, 2    
    add $t6, $t6, $t0  
    
    sw $t1, 0($t6)

    # Draw right side of capsule
    addi $t3, $t3, 1  # Move to next pixel
    mul $t6, $t3, $t5  
    add $t6, $t6, $t4  
    sll $t6, $t6, 2    
    add $t6, $t6, $t0  
    sw $t2, 0($t6)   
    
    
    beq $t9, 0, after_drawing_capsule # if signal is 0 go to game loop
    beq $t9, 1, after_draw_capsule_in_move_preview_capsule_to_main
    jr $ra  # Return

    
##########################UNDER CONSTRUCTION##############################################################

#Move preview capsule to main
move_preview_capsule_to_main:
    # Screen width
    li $t5, 64  
    lw $t0, ADDR_DSPL # base bitmap address
    #add collect and store colour heree
    
    li $t3, 35   # Y position of preview
    li $t4, 20   # X position of bottle 
    # get colour of upper pixel
    mul $t6, $t3, $t5  
    add $t6, $t6, $t4  
    sll $t6, $t6, 2    
    add $t6, $t6, $t0  
    
    lw $t1, 0($t6) # assign colour to $t1
    la $t7 CAP0_COL
    sw $t1 0($t7)   # store colour

    # get colour of lower pixel
    addi $t3, $t3, 1  # Move to next pixel
    mul $t6, $t3, $t5  
    add $t6, $t6, $t4  
    sll $t6, $t6, 2    
    add $t6, $t6, $t0  
    lw $t2, 0($t6)   # assign colour to $t2
    
    la $t7 CAP1_COL
    sw $t2 0($t7)   # store colour
    
    
    

    # draw actual capsule in position

    # Position the capsule at the top center of the bottle
    li $t3, 27   # Y position
    li $t4, 10   # Center(ish) of the bottle

    # Screen width
    li $t5, 64  

    # Draw upper half of capsule
    mul $t6, $t3, $t5  
    add $t6, $t6, $t4  
    sll $t6, $t6, 2    
    add $t6, $t6, $t0  
    
    sw $t1, 0($t6)
    la $t7 CAP0_ADDR
    sw $t6 0($t7)   # store central pixel address

    # Draw right side of capsule
    addi $t3, $t3, 1  # Move to next pixel
    mul $t6, $t3, $t5  
    add $t6, $t6, $t4  
    sll $t6, $t6, 2    
    add $t6, $t6, $t0  
    sw $t2, 0($t6)   
    
    la $t7 CAP1_ADDR
    sw $t6 0($t7)   # store outer pixel address
    
    # INSERT CALL TO CREATE CAPSULE FOR SIDE FUNCTION
    li $t9, 1 # send signal to come back to here
    jal draw_capsule
    
    after_draw_capsule_in_move_preview_capsule_to_main:
    j game_loop     # I was facing a problem with the following line causing a loop and not working, so I added this
    jr $ra  # Return
    
############################# UNDER CONSTRUCTION ############################           


##########################################################
# Drawing the viruses (does not store places of viruses for game over case)
##########################################################
choose_v_location_x:
    li $v0, 42         # Syscall for random integer (0 ≤ result < $a0)
    li $a0, 0
    li $a1, 9    
    syscall            # Get a random number in $a0
    
    addi $a0, $a0, 6   # Shift range from (0-9) to (6-15) to be in bottle range
    move $v0, $a0

    jr $ra
    
choose_v_location_y:
    li $v0, 42         # Syscall for random integer (0 ≤ result < $a0)
    li $a0, 0
    li $a1, 8    
    syscall            # Get a random number in $a0
    
    addi $a0, $a0, 38   # Shift range from (0-8) to (38-46) to be in bottle range
    move $v0, $a0

    jr $ra
    
draw_viruses:
    jal choose_v_location_x
    move $t1, $v0 # assign x location for v1
    jal choose_v_location_y
    move $t2, $v0 # assign y location for v1
    choose_v2_loc:
    jal choose_v_location_x
    move $t3, $v0 # assign x location for v2
    jal choose_v_location_y
    move $t4, $v0 # assign y location for v2
    # check if location is same as v1
    beq $t1, $t3, check_eq_y_v2 # if x is same, check y
    j choose_v3_loc
    check_eq_y_v2:
        beq $t2, $t4, choose_v2_loc # if y is same choose another v2 location
    choose_v3_loc:
    jal choose_v_location_x
    move $t5, $v0 # assign x location for v3
    jal choose_v_location_y
    move $t6, $v0 # assign y location for v3
    # check if location is same as v1
    beq $t1, $t3, check_v1eq_y_v3  # if x is same, check y
    j start_actually_drawing_viruses
    check_v1eq_y_v3:
        beq $t2, $t4, choose_v3_loc # if y is same choose another v2 location
    # check if location is same as v2
    beq $t3, $t5, check_v2eq_y_v3 # if x is same, check y
    j start_actually_drawing_viruses
    check_v2eq_y_v3:
        beq $t4, $t6, choose_v3_loc # if y is same choose another v2 location
        
    ####### Start actually drawing viruses ################## FEEL FREE TO REVIEW
    start_actually_drawing_viruses:
    # Load the base address of the display
    lw $t0, ADDR_DSPL 
    
    # Screen width
    li $t9, 64 
    # v1 drawing
    jal choose_random_color
    move $t7, $v0 # assign colour for v1
    
    mul $t8, $t2, $t9  # assign y * screen width to $t8
    add $t8, $t8, $t1  # add x value to start of row y 
    sll $t8, $t8, 2    # some shifting stuff
    add $t8, $t8, $t0  # add grid location to base bitmap address
    
    sw $t7, 0($t8)
    
    # temporarily ressign $t0 to virus address address
    la $t0, V1_ADDR
    sw $t8, 0($t0)
    lw $t0, ADDR_DSPL # reset $t0
    
    
    # v2 drawing
    jal choose_random_color
    move $t7, $v0 # assign colour for v2
    
    mul $t8, $t4, $t9  
    add $t8, $t8, $t3  
    sll $t8, $t8, 2    
    add $t8, $t8, $t0  
    
    sw $t7, 0($t8)
    
    # temporarily ressign $t0 to virus address address
    la $t0, V2_ADDR
    sw $t8, 0($t0)
    lw $t0, ADDR_DSPL # reset $t0
    
    # v3 drawing
    jal choose_random_color
    move $t7, $v0 # assign colour for v3
    
    mul $t8, $t6, $t9  
    add $t8, $t8, $t5  
    sll $t8, $t8, 2    
    add $t8, $t8, $t0  
    
    sw $t7, 0($t8)
    
    # temporarily ressign $t0 to virus address address
    la $t0, V3_ADDR
    sw $t8, 0($t0)
    lw $t0, ADDR_DSPL # reset $t0
    
    j after_virus_draw # trying to escape a bug
    jr $ra