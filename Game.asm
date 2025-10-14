.data
gridWidth:  	.word 7   	# Grid width
gridHeight: 	.word 7   	# Grid height

# Chose these dimensions as it was easier for me to test the movements from this position
playerRow:  	.word 3   	# Player's initial row
playerCol:  	.word 3   	# Player's initial column


lastkeyPressed: .word 0   	# Stores the value of the last key pressed by the user
moveDirection:  .word 0   	# Stores movement direction flag 

score:          .word 0    	# Initialize the score count. This keeps updating each time the player collects the reward.

# Predefined ascii labels 
zero: 		  .asciiz "0"
spaceCharacter:  .asciiz " "
playerCharacter: .asciiz "P"    
rewardCharacter: .asciiz "R"
newline:         .asciiz "\n"    
hash: 		  .asciiz "#"
scoreCharacter:	  .asciiz "Score: "
gameOver:        .asciiz "GAME OVER"

# Predefined grid using a 2D arrayt
gridData:
    .asciiz "#######"
    .asciiz "#     #"
    .asciiz "#     #"
    .asciiz "#     #"
    .asciiz "#     #"
    .asciiz "#     #"
    .asciiz "#######"

.text

# The function which calls the important functions that make the entire game work.
main:    
    	jal DisplayScoreChar          	# Print "Score: " label
    	jal score_conversion       	# Display the inital score of 0 at the begining as the player didn't collect any reward yet.
    
    	jal new_line			# Print new line
    	jal initialize_player_in_grid 	# Initialize player position in grid
    	jal display_reward
    	jal display_grid            	# Display the grid

# The loop that reprints the grid after every move
Reprint_grid_loop:
    
    	jal read_input              	# Read user input
    	jal keypress                	# Checks which key was pressed and goes to the corresponding function for that move.
    
    	lw $a0, playerRow           	# Load old row
    	lw $a1, playerCol           	# Load old column
    	jal clear_old_position      	# Clear the players old position in the screen

    	jal move_player             	# Move the player
    
    	jal clear_screen           	# Clear the screen
    
    	jal DisplayScoreChar 	    	# Display the score message

    	jal score_conversion       	# Add 5 to the score each time the player collected a reward.
    
    	jal new_line			# Print new line

    	jal display_grid            	# Redraw grid
    
    	j Reprint_grid_loop         	# Keep looping until the player exits the game by hitting the wall or collecting 100 points.


# This function initialzies the player in the grid
initialize_player_in_grid:
    	addi $sp, $sp, -4       	# Allocate stack space
    	sw $ra, 0($sp)       		# Save return address
	    
    	lw $t0, playerRow		# Load player's row
    	lw $t1, playerCol   		# Load player's column
    	lw $t2, gridWidth   		# Load grid width

    	addi $t2, $t2, 1  		# Accomodate the null terminator
    
    	# Formula for calculating the cell index: index = (row * gridWidth) + column
    	# Start the code taken from "https://stackoverflow.com/questions/34002396/calculate-index-in-a-custom-grid"
    	mul $t3, $t0, $t2   
    	add $t3, $t3, $t1   
	# End the code taken from "https://stackoverflow.com/questions/34002396/calculate-index-in-a-custom-grid"
	
    	la $t4, gridData    		# Load grid base address
    	add $t4, $t4, $t3   		# Get address of player's cell from the offset calculation
    	lb $t5, playerCharacter 	# Load 'P' character
    	sb $t5, 0($t4)      		# Store 'P' in the grid with it's initial coordinates beng (3,3)
    
    	lw $ra, 0($sp)    		# Restore return address
    	addi $sp, $sp, 4  		# Deallocate stack space
    	jr $ra

# Display the reward function
display_reward:
    	addi $sp, $sp, -4   		# Allocate stack space
    	sw   $ra, 0($sp)		# Save return address

	# Generate the lower and upper bound for the random row and column index to use the syscall 42.    	    	
	generate_random_position:
    	# Random row index
   	li   $a0, 1             	# Initiate the lower bound for row index
    	lw   $t0, gridHeight    	
    	addi $t0, $t0, -1       	# Upper bound = gridHeight - 1. As it allows to go to the row before the hash. 
    	move $a1, $t0          	
    	li   $v0, 42            	# Syscall 42: Random integer in the range stored in $a0 and $a1.
    	syscall
    	move $s0, $a0           	# Save random row index in $s0
    
    	# Rndom column index
    	li   $a0, 1             	# Initiate the lower bound for column index
    	lw   $t1, gridWidth     	
    	addi $t1, $t1, -1       	
    	move $a1, $t1           	# Set upper bound in $a1
    	li   $v0, 42            	
    	syscall
    	move $s1, $a0           	# Save random column index in $s1

    	# Calculate the offset 
    	lw   $t2, gridWidth     	# Reload gridWidth
    	addi $t2, $t2, 1        	# Accomodate the null terminator 
    	# Start the code taken from "https://stackoverflow.com/questions/34002396/calculate-index-in-a-custom-grid"
    	mul  $t3, $s0, $t2      	# Multiply random row index by (gridWidth+1)
    	add  $t3, $t3, $s1      	# Add random column index to get final offset
    	# End the code taken from "https://stackoverflow.com/questions/34002396/calculate-index-in-a-custom-grid"

    	la   $t4, gridData      	# Load gridData base address
    	add  $t4, $t4, $t3      	# Compute address for the chosen cell

    	lb   $t5, 0($t4)		
    	lb   $t6, spaceCharacter
   	bne  $t5, $t6, generate_random_position  # Only print the reward if it is a space.
    
    	lb   $t5, rewardCharacter  	# Load reward character ('R')
    	sb   $t5, 0($t4)        	# Store 'R' in the grid

    	lw   $ra, 0($sp)        	# Restore return address
    	addi $sp, $sp, 4        	# Deallocate stack space
    	jr   $ra
    
# Converts the score value into ASCII so that the score can be displayed in the MMIO
score_conversion:
    	addi $sp, $sp, -8         	# Allocate 8 bytes on the stack for saving registers
    	sw   $ra, 0($sp)		# Save the return address ($ra) on the stack.
    	sw   $s0, 4($sp)		# Save register $s0 on the stack.

    	la   $t0, score           	# Load the address of the 'score' variable into register $t0.
    	lw   $t1, 0($t0)          	# Load the value of 'score' from memory into register $t1.

    	
    	beqz $t1, score_display_zero	# If score is 0, display '0'	
	
	# Start the code taken from "https://stackoverflow.com/questions/47666000/mips-assembly-convert-integer-to-ascii-string-using-memory"
    	li   $t2, 1              	# Initialize divisor in $t2 to 1.
    	
	score_divisor_loop:
    	div  $t1, $t2            	# Divide score ($t1) by the current divisor ($t2).
    	mflo $t3                 	# Move the quotient from the division into $t3.
    	li   $t4, 10             	# Load constant 10 into $t4.
    	blt  $t3, $t4, score_display	# If quotient ($t3) is less than 10, the proper divisor is found jump to score_display.
    	mul  $t2, $t2, $t4       	# Multiply divisor ($t2) by 10 to handle the next digit.
    	j    score_divisor_loop		# Repeat the loop with the new divisor.

	score_display:
    	la   $t0, score           	# Reload score value into $t0 for printing
    	lw   $t1, 0($t0)		# Reload the score value into $t1.
   	move $t5, $t1            	# Copy the score to $t5 as a working copy for digit extraction.
	score_display_loop:
   	div  $t5, $t2            	# Divide the working copy ($t5) by the current divisor ($t2) to isolate the current digit.
    	mflo $t7                 	# Move the quotient (current digit 0–9) into $t7.
    	addi $t8, $t7, 48        	# Convert the digit to its ASCII code by adding 48.
	# End the cod taken from "https://stackoverflow.com/questions/47666000/mips-assembly-convert-integer-to-ascii-string-using-memory"

	# Start the code taken from "https://www.cim.mcgill.ca/~langer/273/20-slides.pdf"
	wait_for_score_display:
   	li   $t9, 0xFFFF0008     	
    	lw   $t6, ($t9)
    	andi $t6, $t6, 1
    	beqz $t6, wait_for_score_display
    	li   $t9, 0xFFFF000C     	
    	sb   $t8, 0($t9)         	
	# End the code taken from "https://www.cim.mcgill.ca/~langer/273/20-slides.pdf"
	
    	# Subtract (digit * divisor) from t5:
    	mul  $t3, $t7, $t2       	# Multiply the digit ($t7) by the divisor ($t2) to compute its actual value.
    	sub  $t5, $t5, $t3       	# Subtract that digit's value from the working score ($t5).

    	# Update divisor for the next digit (divide by 10)
    	li   $t4, 10			# Load constant 10 into $t4.
    	div  $t2, $t4			# Divide the current divisor ($t2) by 10.
    	mflo $t2               		# Update $t2 with the new divisor value.

    	bgtz $t2, score_display_loop	# If the new divisor is still greater than 0, continue with the next digit.

    	j return_from_score_display	# If the new divisor is still greater than 0, continue with the next digit.
	
	# Display initial score as 0
	score_display_zero:
    	lb   $a0, zero            	
    	move $t8, $a0
    	# Start the code taken from "https://www.cim.mcgill.ca/~langer/273/20-slides.pdf"
	wait_score_display_zero:
    	li   $t9, 0xFFFF0008     
    	lw   $t6, ($t9)
    	andi $t6, $t6, 1
    	beqz $t6, wait_score_display_zero
    	li   $t9, 0xFFFF000C
    	sb   $t8, 0($t9)        	# Dislay '0'
	# End the code taken from "https://www.cim.mcgill.ca/~langer/273/20-slides.pdf"
	
	return_from_score_display:
    	lw   $ra, 0($sp)        	# Restore return addres
    	lw   $s0, 4($sp)		# Deallocate the stack space
    	addi $sp, $sp, 8		
    	jr   $ra

# Function that increments 5 each time the player has collected (collided) with the reward
score_update:
    	addi $sp, $sp, -4         	# Allocate stack space
    	sw   $ra, 0($sp)		# Save return address

    	la   $t0, score           	# Load address of score variable
    	lw   $t1, 0($t0)          	# t1 contains the current score
    	addi $t1, $t1, 5          	# Increment score by 5
    	sw   $t1, 0($t0)          	# Store updated score

    	jal score_conversion    	# Display the converted score
    
    	beq $t1, 100, exit_program 	# Exit the game if current score is equal to 100

    	lw   $ra, 0($sp)          	# Restore retrun address
    	addi $sp, $sp, 4		# Deallocate the stack space 
    	jr   $ra
 
# Clears the players old position and replaces it with an empty space after each move.
clear_old_position:
    	addi $sp, $sp, -4   		#  Allocate stack space
    	sw $ra, 0($sp)      		#  Save return address
    
    	lw  $t0, gridWidth   
    	addi $t0, $t0, 1		# Accomodate the null terminator
    	# Start the code taken from "https://stackoverflow.com/questions/34002396/calculate-index-in-a-custom-grid"
    	mul  $t3, $a0, $t0 		# row * width
    	add  $t3, $t3, $a1  		# + column index
	# End the code taken from "https://stackoverflow.com/questions/34002396/calculate-index-in-a-custom-grid
	
    	la   $t4, gridData   		# Load grid base address
    	add  $t4, $t4, $t3  		# Get the address from the offset calculation
    	la   $t5, spaceCharacter 	# Load space character
    	lb   $t5, 0($t5)     		# Load ASCII value of space
    	sb   $t5, 0($t4)     		# Replace old position with space
    
    	lw 	 $ra, 0($sp)     	# Restore return address
    	addi $sp, $sp, 4   		# Deallocate stack space
    	jr 	 $ra


# Read Input Function
read_input:
    	addi $sp, $sp, -4   		# Allocate stack space
    	sw   $ra, 0($sp)      		# Save return address

	# The following loop is a polling loop which waits for the user to enter in the keyboard the desired key.
	# Start the code taken from "https://www.cim.mcgill.ca/~langer/273/20-slides.pdf"
    	li   $t5, 0xFFFF0000
	wait_input_ready:
    	lw   $t6, ($t5)    
    
    	andi $t6, $t6, 1		# Checks if the keyboard board is ready to take the input. 
    	beqz $t6, wait_input_ready	# If not ready, wait until it is.

    	li   $t5, 0xFFFF0004
    
    	lbu  $t7, 0($t5)    		# Read keypress
    	la   $t8, lastkeyPressed 	# Load address of keypress
    	sw   $t7, 0($t8)     		# Store keypress in memory
	# End the code taken from "https://www.cim.mcgill.ca/~langer/273/20-slides.pdf"
	
    	lw 	 $ra, 0($sp)  		# Restore return address
    	addi $sp, $sp, 4  		# Deallocate stack space
    	jr   $ra

# Keypress function determines the direction of the player movement
keypress:
    	addi $sp, $sp, -4		# Allocate stack space
    	sw $ra, 0($sp)			# Save return address

    	la $t8, lastkeyPressed 		# Load keypress variable address
    	lw $t7, 0($t8)          	# Get last pressed key from memory

    	li $t6, 'w'			# If the user pressed 'w', go to the set_up function
    	beq $t7, $t6, set_up	

    	li $t6, 's'			# If the user pressed 's', go to the set_up function
    	beq $t7, $t6, set_down

    	li $t6, 'a'			# If the user pressed 'a', go to the set_up function
    	beq $t7, $t6, set_left

    	li $t6, 'd'			# If the user pressed 'd, go to the set_up function
    	beq $t7, $t6, set_right
	
	# This function is used for exception handling. If the user eneterd any key other than "w, a, s or d", the program will wait till the user enters the right key.    
	# Start the code taken from "https://www.cim.mcgill.ca/~langer/273/20-slides.pdf"
	wait_for_valid_input:
    	jal  read_input         	# Read a new key from MMIO
    	la  $t8, lastkeyPressed
    	lw  $t7, 0($t8)
    	li  $t6, 'w'
    	beq $t7, $t6, set_up
    	li  $t6, 's'
    	beq $t7, $t6, set_down
    	li  $t6, 'a'
    	beq $t7, $t6, set_left
    	li  $t6, 'd'
    	beq $t7, $t6, set_right
    	j   wait_for_valid_input   	# Loop until a valid key is pressed
   	# End the code taken from "https://www.cim.mcgill.ca/~langer/273/20-slides.pdf"
   	
	# The following "set" functions store "flags" which determine the movement of the player depending on the key that was pressed.
	set_up:
   	li $t9, 1   			# 1 = Up
    	j store_direction

	set_down:
    	li $t9, 2  			# 2 = Down
    	j store_direction

	set_left:
   	li $t9, 3   			# 3 = Left
    	j store_direction

	set_right:
    	li $t9, 4   			# 4 = Right
    	j store_direction	

	store_direction:
    	la $t8, moveDirection  		# Load the move direction address, which stores the value of the last key pressed and according to the flag, goes to that movement function.
    	sw $t9, 0($t8)         		# Store movement flag
    	j return_keypress              	# Return back to the caller for the next user input to determine the diection

	return_keypress:
    	lw $ra, 0($sp)			# Restore the return address
    	addi $sp, $sp, 4		# Deallocate the stack space
    	jr $ra

# The move player function calculates and stores the updated players position in the grid.
move_player:
    	addi $sp, $sp, -4      		# Allocates stack memory
    	sw $ra, 0($sp)			# Save return address
    
   	la $t8, moveDirection  		# Load move direction address
    	lw $t9, 0($t8)         		# Get the current movement flag so that the program knows which movement to initiate.
    
	# Load the players initial position and the grids width and height
    	lw $t0, playerRow
    	lw $t1, playerCol
    	lw $t2, gridHeight
    	lw $t3, gridWidth

    	li $t6, 1			# If the flag equals to 1, execute the move_up function
    	beq $t9, $t6, move_up

    	li $t6, 2			# If the flag equals to 2, execute the move_down function
    	beq $t9, $t6, move_down

    	li $t6, 3			# If the flag equals to 3, execute the move_left function
    	beq $t9, $t6, move_left

    	li $t6, 4			# If the flag equals to 4, execute the move_right function
    	beq $t9, $t6, move_right    

    	j return_move_player  		# Return back to the caller if the flag didn't pick up the direction

	move_up:
    	beq $t0, 1, exit_program  	# Makes sure that the player cannot touch the wall
    	addi $t0, $t0, -1 		# Move up
    	j check_collision		# Check if the player has hit the wall or the reward

	move_down:
   	addi $t4, $t2, -2
    	beq $t0, $t4, exit_program 	# Makes sure that the player cannot touch the wall
    	addi $t0, $t0, 1  		# Move down
    	j check_collision		# Check if the player has hit the wall or the reward

	move_left:
    	beq $t1, 1, exit_program	# Makes sure that the player cannot touch the wall
    	addi $t1, $t1, -1  		# Move left
    	j check_collision		# Check if the player has hit the wall or the reward

	move_right:
    	addi $t4, $t3, -2
    	beq  $t1, $t4, exit_program 	# Makes sure that the player cannot touch the wall
    	addi $t1, $t1, 1  		# Move right
    	j check_collision		# Check if the player has hit the wall or the reward

	store_new_position:
    	sw $t0, playerRow   		# Store updated row
    	sw $t1, playerCol   		# Store updated column

    	# Compute new cell index and update grid
    	lw $t2, gridWidth
    	addi $t2, $t2, 1		# Accomodate the null terminator
    	# Start the code taken from "https://stackoverflow.com/questions/34002396/calculate-index-in-a-custom-grid"
    	mul $t3, $t0, $t2
    	add $t3, $t3, $t1
    	# End the code taken from "https://stackoverflow.com/questions/34002396/calculate-index-in-a-custom-grid"
    	
    	la $t4, gridData		# Load grid data address
    	add $t4, $t4, $t3		# Get the index of the grid data from the offset calculation 
    
    	la $t5, playerCharacter	# Load the address of the player character 
    	lb $t5, 0($t5)
    	sb $t5, 0($t4)  		# Store the playe at new position
    
    	j return_move_player

	check_collision:
	# Compute new cell index and update grid
    	lw $t2, gridWidth
    	addi $t2, $t2, 1     		# Accomodate the null terminator
    	# Start the code taken from "https://stackoverflow.com/questions/34002396/calculate-index-in-a-custom-grid"
    	mul $t3, $t0, $t2    		
    	add $t3, $t3, $t1
    	# End the code taken from "https://stackoverflow.com/questions/34002396/calculate-index-in-a-custom-grid"

    	la $t4, gridData     		
    	add $t4, $t4, $t3		# Add the index to the grid
    	lb $t5, 0($t4)       		# Load the index to the grid

    	la $a0, hash			# Load the the address of the hash chracter
    	move $t6, $a0			# 
    	beq $t5, $t6, exit_program 	# Check if the current cell in the grid is a hash, if it is, exit the game.
    

    	la   $a0, rewardCharacter  	# Load the addreess of the reward character
    	lb   $t7, 0($a0)           	# Load the 'R' in the cell of the grid
    	beq  $t5, $t7, player_collide_reward  # If the current cell is 'R',  go to the 'player_collide_reward function and execute.

    	j store_new_position      	# If the cell is not 'R' or "#', go to the store_new_position function
    
	player_collide_reward:
    	# When the cell contains 'R', replace it with the player's character.
    	la   $a0, playerCharacter	# Load the address of the players character
    	lb   $t8, 0($a0)         	# Load the player character in $t8
    	sb   $t8, 0($t4)         	# Overwrite the reward's position with player's character
    
    	# Update the player's position
    	sw   $t0, playerRow
    	sw   $t1, playerCol
    
    	# If the player collided witht he reward, jump to score_update function 
    	jal score_update

    	# After overwritting the reward with the player, regenerate the reward at a random cell again.
    	jal display_reward    
     
	return_move_player:
    	lw $ra, 0($sp)         		# Restore return address
    	addi $sp, $sp, 4           	# Deallocate stack space
    	jr $ra   
    
   
# This function displays the grid
display_grid:
    	addi $sp, $sp, -4   		# Allocate stack space
    	sw $ra, 0($sp)    		# Save return address

    	la $t0, gridData  		# Load grid base address
    	li $t1, 0         		# Row counter
    	lw $t2, gridHeight  		# Get grid height

	row_loop:
   	beq $t1, $t2, exit_display_grid  # When the row counter is equal to the grid height (7), exit the loop.
    
    	li $t3, 0          		# Initiate the column counter
    	lw $t4, gridWidth  		# Get the grid width from memory
    	addi $t4, $t4, 1   		# Increment the grid width by 1 to accomodate the null terminator

	col_loop:
    	beq $t3, $t4, row_end  		# If at end of row, move to next line

    	# Compute index of a cell in 1D array:
    	lw $t5, gridWidth   		# Reinitialize the gridwidth 
    	addi $t5, $t5, 1    		# Increment the grid width by 1 to accomodate the null terminator
    	
    	# Start the code taken from "https://stackoverflow.com/questions/34002396/calculate-index-in-a-custom-grid"
    	mul $t6, $t1, $t5   		# row * width
    	add $t6, $t6, $t3   		# + column
	# End the code taken from "https://stackoverflow.com/questions/34002396/calculate-index-in-a-custom-grid"
	
    	la $t7, gridData    		# Load base address
    	add $t7, $t7, $t6   		# Get address of cell
    	lb $a0, 0($t7)      		# Load character at this position

	# Start the code taken from "https://www.cim.mcgill.ca/~langer/273/20-slides.pdf"
    	li $t5, 0xFFFF0008  		# MMIO address
	wait_ready:
    	lw $t6, ($t5)
    	andi $t6, $t6, 1
    	beqz $t6, wait_ready

    	li $t5, 0xFFFF000C
    	sb $a0, 0($t5)      		# Print character
	# End the code taken from "https://www.cim.mcgill.ca/~langer/273/20-slides.pdf"
	
    	addi $t3, $t3, 1
    	j col_loop

	# End of row 
	row_end:
    	jal new_line      		# Print new line when reached the end of the row
    	addi $t1, $t1, 1  		# Increment the row counter by 1
    	j row_loop        		# Go back to the row_loop for the next row

	exit_display_grid:
    	lw $ra, 0($sp)    		# Restore return address
    	addi $sp, $sp, 4		# Deallocate stack space
    	jr $ra

# Display new line character into MMIO 
new_line:
	# Start the code taken from "https://www.cim.mcgill.ca/~langer/273/20-slides.pdf"
    	li $t5, 0xFFFF0008
	wait_ready_newline:
    	lw $t6, ($t5)
    	andi $t6, $t6, 1
    	beqz $t6, wait_ready_newline

    	li $t5, 0xFFFF000C
    	la $a0, newline
    	lb $t7, 0($a0)
    	sb $t7, 0($t5)
    	# End the code taken from "https://www.cim.mcgill.ca/~langer/273/20-slides.pdf"
    	jr $ra
        
# Display the print message to the MMIO
DisplayScoreChar:
    	la $a0, scoreCharacter
    	# This loop goes throgh each character in the game over message and displays the entire message instead of just one character
	loop_each_character:
    	lb $t7, 0($a0)
    	# Start the cod taken from "https://www.cim.mcgill.ca/~langer/273/20-slides.pdf"
    	beqz $t7, exit_display_score
    	li $t5, 0xFFFF0008
	wait_ready_score:
    	lw $t6, ($t5)
    	andi $t6, $t6, 1
    	beqz $t6, wait_ready_score

    	li $t5, 0xFFFF000C
    	sb $t7, 0($t5)
    	addi $a0, $a0, 1
    	j loop_each_character
 	# End the code takenfrom "https://www.cim.mcgill.ca/~langer/273/20-slides.pdf"
 	
	exit_display_score:
    	jr $ra
                                
# ASCII 12, to clear the screen                                   
clear_screen:
    	li $t4, 12 # ASCII character for form feed, which clears the screen
    	# Start the code taken from "https://www.cim.mcgill.ca/~langer/273/20-slides.pdf"    
    	li $t5, 0xFFFF0008
	wait_clear_screen:
    	lw $t6, ($t5)
    	andi $t6, $t6, 1
    	beqz $t6, wait_clear_screen

    	li $t5, 0xFFFF000C
    	sb $t4, 0($t5)
    	# End the code taken from "https://www.cim.mcgill.ca/~langer/273/20-slides.pdf"
    	jr $ra

# Display game over message to the MMIO
game_over:
    	la $a0, gameOver
    	# This loop goes throgh each character in the game over message and displays the entire message instead of just one character
	loop_each_letter:
    	lb $t7, 0($a0) 
    	beqz $t7, exit_display_score
    	# Start the code taken from ""https://www.cim.mcgill.ca/~langer/273/20-slides.pdf
    	li $t5, 0xFFFF0008
	wait_game_over:
    	lw $t6, ($t5)
    	andi $t6, $t6, 1
    	beqz $t6, wait_game_over
    	li $t5, 0xFFFF000C
    	sb $t7, 0($t5)
    	# End the code taken from "https://www.cim.mcgill.ca/~langer/273/20-slides.pdf"
    	addi $a0, $a0, 1
    	j loop_each_letter

# Exit the program after game over
exit_program:
    	jal clear_screen 	# Calls the clear screen function
    	jal game_over		# Calls the game over function to display the game over message
    	jal new_line		# Prints new line
    	jal DisplayScoreChar	# Displays the score message
    	jal score_conversion	# Displays the ascii value of the currrent score in the MMIO
    	
    	li $v0, 10    		# Exit program syscall
    	syscall
