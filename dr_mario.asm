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

##############################################################################
# Code
##############################################################################
	.text
	.globl main

main:
    # Load the base address of the display
    lw $t0, ADDR_DSPL 

    # Draw the bottle
    jal draw_bottle

    # Draw the first capsule
    jal draw_capsule

    # Infinite loop (prevents program from exiting)
game_loop:
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
    # sleep then create new capsule
    lw $t2 CAP0_ADDR
    lw $t3 CAP1_ADDR
    add $t9 , $0, 3
    add $t8 , $0, 3
    # loop through column of 4 to see if it eliminates
    next_4_cap0: 
        lw $t6 0($t2) # colour at CAP0
        lw $t7 256($t2) # colour at 1 below CAP0
        bne $t6, $t7, next_4_cap1   # if colours not same, loop over
        addi $t9, $t9, -1   # reduce counter
        addi $t2, $t2, 256
        bge $t9, $zero, next_4_cap0 # if there are greater than 0 steps left, loop
        # code for erasing column
        lw $t6 COLOUR_BLACK # assign black to t6
        lw $t2 CAP0_ADDR
        sw $t6 0($t2) # erase first
        addi $t2, $t2, 256
        sw $t6 0($t2) # erase second
        addi $t2, $t2, 256
        sw $t6 0($t2) # erase third 
        addi $t2, $t2, 256
        sw $t6 0($t2) # erase fourth 
        
    next_4_cap1:    
        lw $t3 CAP1_ADDR
        lw $t6 0($t3) # colour at CAP1
        lw $t7 256($t3) # colour at 1 below CAP1
        bne $t6, $t7, colour_column_loop_over # if colours not same, loop over
        addi $t8, $t8, -1   # reduce counter
        addi $t3, $t3, 256
        bge $t8, $zero, next_4_cap1 # if there are greater than 0 steps left, loop
        # code for erasing column
        lw $t6 COLOUR_BLACK # assign black to t6
        lw $t3 CAP1_ADDR
        sw $t6 0($t3) # erase first
        addi $t3, $t3, 256
        sw $t6 0($t3) # erase second
        addi $t3, $t3, 256
        sw $t6 0($t3) # erase third 
        addi $t3, $t3, 256
        sw $t6 0($t3) # erase fourth 
        
        
    colour_column_loop_over: # for when the loop is over
    li $v0, 32
	li $a0 16
	syscall
    jal draw_capsule

keyboard_input:                     # A key is pressed
    lw $a0, 4($t1)                  # Load second word from keyboard
    beq $a0, 0x71, respond_to_Q     # Check if the key q was pressed
    beq $a0, 0x77, respond_to_W     # Check if the key w was pressed
    beq $a0, 0x61, respond_to_A     # Check if the key a was pressed
    beq $a0, 0x73, respond_to_S     # Check if the key s was pressed
    beq $a0, 0x64, respond_to_D     # Check if the key d was pressed

    li $v0, 1                       # ask system to print $a0
    syscall

    b game_loop
# Quit
respond_to_Q:
	li $v0, 10                      # Quit gracefully
	syscall
# Rotate 90 degrees clockwise
respond_to_W:
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


draw_capsule:
    jal choose_random_color # Get a random number (1, 2, or 3)
    move $t1, $v0           # Store result in $t1
    la $t7, CAP0_COL
    sw $t1 0($t7)
    jal choose_random_color # Get a random number (1, 2, or 3)
    move $t2, $v0           # Store result in $t2
    la $t7, CAP1_COL
    sw $t2 0($t7)

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
    j game_loop     # I was facing a problem with the following line causing a loop and not working, so I added this
    jr $ra  # Return
