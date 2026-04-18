IDEAL
MODEL small
STACK 100h
p386


; -------------------------------------------------------------------------
; MACROS
; -------------------------------------------------------------------------
	
	; -------------------------------------------------------------------------
	; SCREEN AND SPRITE DIMENSIONS
	; -------------------------------------------------------------------------

	; SCREEN_WIDTH: The total horizontal pixel count of the VGA Mode 13h screen.
	; 320 is the standard width for this mode; it is used for coordinate 
	; calculations and to determine the end of a pixel row in memory.
	SCREEN_WIDTH = 320
	
	; -------------------------------------------------------------------------
	; END
	; -------------------------------------------------------------------------

	; -------------------------------------------------------------------------
	; RECURSION AND STACK CONTROL
	; -------------------------------------------------------------------------

	; MaxFloodStackDepth: Defines the maximum depth allowed for the recursive 
	; flood-fill algorithm. This limit prevents the program from exceeding 
	; the allocated CPU stack memory, which would lead to a system crash.
	; 50 is an arbitrary safety threshold chosen to balance the complexity 
	; of fillable areas with the 100h stack size defined in the header.
	MaxFloodStackDepth = 50

	; -------------------------------------------------------------------------
	; END
	; -------------------------------------------------------------------------

; -------------------------------------------------------------------------
; MACROS END
; -------------------------------------------------------------------------


; -------------------------------------------------------------------------
; EXTRA SEGMENT DEFINITION
; -------------------------------------------------------------------------
; This segment is used for off-screen rendering (double buffering).
; By drawing to this buffer first and then copying to the VGA memory (0A000h),
; we prevent screen flickering during animation.
; -------------------------------------------------------------------------
SEGMENT secondBufferSeg

	; secondBuffer: A memory block of 64,000 bytes.
    ; 64,000 corresponds to a full 320x200 VGA Mode 13h screen (320 * 200 = 64,000).
    ; Each byte represents a single pixel's color index.
	secondBuffer db 64000 dup(?)
	
ENDS secondBufferSeg

; -------------------------------------------------------------------------
; END
; -------------------------------------------------------------------------

DATASEG

	moveLeftCnt dw 0

; -------------------------------------------------------------------------
; AUDIO AND SOUND CONTROLS
; -------------------------------------------------------------------------

; ShootSoundTimer: A word-sized counter used to track the duration of the 
; firing sound effect. It is decremented each game loop to ensure the 
; audio frequency doesn't play indefinitely.
	ShootSoundTimer dw 0

; ShootSoundFreq: The frequency value (in Hz) sent to the PC Speaker 
; for the shooting sound effect. 400 is an arbitrary pitch chosen 
; to represent a low-tone projectile launch.
	ShootSoundFreq  dw 400

; -------------------------------------------------------------------------
; END
; -------------------------------------------------------------------------


; -------------------------------------------------------------------------
; ENEMY STATE, MOVMENT, AND TRACKING
; -------------------------------------------------------------------------
	
; DisappearNow: A boolean-style flag (0 or 1) used to trigger the removal 
; of the enemy object from the screen (should start getting "further" away smaller).
; 0 is the default state, meaning the object is currently invisible and inactive.
	DisappearNow db 0	
	
; EnemyY and EnemyX: Word-sized variables storing the current vertical 
; and horizontal coordinates of the enemy aircraft. 
	EnemyY dw ?
	EnemyX dw ?
	
; enemyLeftTimer: A counter used to manage the duration of the enemy's 
; appearance of a enemy spawning on the left part of the screen before starting to 'DisappearNow'.
	enemyLeftTimer dw 0

; enemyLeft: A state flag indicating whether the enemy has spawned
; on the left side of the screen.
; 0 means the enemy is on the right. 
	enemyLeft db 0	
	
	
; killMissile: A status flag used to signal the missile hanlde proc to 
; not continue and spawn the missile, as it exploded / disappeared). 
	killMissile db 0	
	
; EnemyStayAtPlaceTimer: A word-sized variable that controls the duration 
; an enemy remains stationary before moving to the next axis in the way to its traget in MoveEnemyToBoundry.
; it is shifted until CF is appears, than resets.
	EnemyStayAtPlaceTimer dw 1	
	
; StageOneEnemyExplosionComplete: a flag which indicates wether the first enemy explosion image was shown enough 
; time for eye.
	StageOneEnemyExplosionComplete db 0 
	
; EnemyDeadByFire: A specific status indicator that tracks if an enemy 
; was neutralized by a bullet rather then simpley disappering.
	EnemyDeadByFire db 0
	
; a "timer" to wait a number of loop iterations until the second enemy explosion should show.
	WaitForEnemyExp2 db 0
		 

; -------------------------------------------------------------------------
; END
; -------------------------------------------------------------------------

; -------------------------------------------------------------------------
; MISSILE SPRITES 
; -------------------------------------------------------------------------

	; -------------------------------------------------------------------------
	; XXXS MISSILE SPRITE
	; -------------------------------------------------------------------------

	Missile_XXXS dw 0, 0, 20; Black
	dw 1, 0, 20; Black
	dw 2, 0, 20; Black
	dw 3, 0, 20; Black
	dw 4, 0, 20; Black
	dw 0, 1, 20; Black
	dw 1, 1, 1; Gray
	dw 2, 1, 1; Gray
	dw 3, 1,1 ; Gray
	dw 4, 1, 20; Black
	dw 0, 2, 20; Black
	dw 1, 2, 1; Gray
	dw 2, 2, 1; Gray
	dw 3, 2, 1; Gray
	dw 4, 2, 20; Black
	dw 0, 3, 20; Black
	dw 1, 3, 1; Gray
	dw 2, 3, 1; Gray
	dw 3, 3, 1; Gray
	dw 4, 3, 20; Black
	dw 0, 4, 20; Black
	dw 1, 4, 20; Black
	dw 2, 4, 20; Black
	dw 3, 4, 20; Black
	dw 4, 4, 20; Black
	dw 0, 0, 0

	; -------------------------------------------------------------------------
	; END
	; -------------------------------------------------------------------------
	
	; -------------------------------------------------------------------------
	; XXXS MISSILE SPRITE TO COPY 
	; -------------------------------------------------------------------------
	
	; We use this sprite to copy the original values to xxxs, as all missile sync with xxxs missile, 
	; and it needs to respawn.

	Missile_XXXS_TO_COPY dw 0, 0, 20; Black
	dw 1, 0, 20; Black
	dw 2, 0, 20; Black
	dw 3, 0, 20; Black
	dw 4, 0, 20; Black
	dw 0, 1, 20; Black
	dw 1, 1, 1; Gray
	dw 2, 1, 1; Gray
	dw 3, 1,1 ; Gray
	dw 4, 1, 20; Black
	dw 0, 2, 20; Black
	dw 1, 2, 1; Gray
	dw 2, 2, 1; Gray
	dw 3, 2, 1; Gray
	dw 4, 2, 20; Black
	dw 0, 3, 20; Black
	dw 1, 3, 1; Gray
	dw 2, 3, 1; Gray
	dw 3, 3, 1; Gray
	dw 4, 3, 20; Black
	dw 0, 4, 20; Black
	dw 1, 4, 20; Black
	dw 2, 4, 20; Black
	dw 3, 4, 20; Black
	dw 4, 4, 20; Black
	dw 0, 0, 0

	; -------------------------------------------------------------------------
	; END
	; -------------------------------------------------------------------------
	
	; -------------------------------------------------------------------------
	; XXS MISSILE SPRITE
	; -------------------------------------------------------------------------
	
	Missile_XXS  dw 1, 1, 20; Black
	dw 2, 1, 20; Black
	dw 3, 1, 20; Black
	dw 4, 1, 20; Black
	dw 5, 1, 20; Black
	dw 6, 1, 20; Black
	dw 1, 2, 20; Black
	dw 2, 2, 1; Gray
	dw 3, 2, 1; Gray
	dw 4, 2, 1; Gray
	dw 5, 2, 1; Gray
	dw 6, 2, 20; Black
	dw 1, 3, 20; Black
	dw 2, 3, 1; Gray
	dw 3, 3, 1; Gray
	dw 4, 3, 1; Gray
	dw 5, 3, 1; Gray
	dw 6, 3, 20; Black
	dw 1, 4, 20; Black
	dw 2, 4, 1; Gray
	dw 3, 4, 1; Gray
	dw 4, 4, 1; Gray
	dw 5, 4, 1; Gray
	dw 6, 4, 20; Black
	dw 1, 5, 20; Black
	dw 2, 5, 20; Black
	dw 3, 5, 20; Black
	dw 4, 5, 20; Black
	dw 5, 5, 20; Black
	dw 6, 5, 20; Black

	; -------------------------------------------------------------------------
	; END
	; -------------------------------------------------------------------------

	; -------------------------------------------------------------------------
	; XS MISSILE SPRITE
	; -------------------------------------------------------------------------

	Missile_XS  dw 2, 3, 20; Black
	dw 3, 3, 20; Black
	dw 12, 3, 20; Black
	dw 13, 3, 20; Black
	dw 2, 4, 20; Black
	dw 3, 4, 1; Gray
	dw 4, 4, 20; Black
	dw 5, 4, 19 ; Saddle Brown
	dw 10, 4, 19 ; Saddle Brown
	dw 11, 4, 20; Black
	dw 12, 4, 1; Gray
	dw 13, 4, 20; Black
	dw 3, 5, 20; Black
	dw 4, 5, 19 ; Saddle Brown
	dw 5, 5, 19 ; Saddle Brown
	dw 6, 5, 20; Black
	dw 7, 5, 20; Black
	dw 8, 5, 20; Black
	dw 9, 5, 20; Black
	dw 10, 5, 19 ; Saddle Brown
	dw 11, 5, 19 ; Saddle Brown
	dw 12, 5, 20; Black
	dw 4, 6, 19 ; Saddle Brown
	dw 5, 6, 255
	dw 6, 6, 255
	dw 7, 6, 255
	dw 8, 6, 255
	dw 9, 6, 20; Black
	dw 10, 6, 20; Black
	dw 11, 6, 19 ; Saddle Brown
	dw 4, 7, 20; Black
	dw 5, 7, 255
	dw 6, 7, 255
	dw 7, 7, 255
	dw 8, 7, 255
	dw 9, 7, 255
	dw 10, 7, 20; Black
	dw 11, 7, 20; Black
	dw 4, 8, 20; Black
	dw 5, 8, 20; Black
	dw 6, 8, 20; Black
	dw 7, 8, 20; Black
	dw 8, 8, 255
	dw 9, 8, 255
	dw 10, 8, 20; Black
	dw 11, 8, 20; Black
	dw 4, 9, 20; Black
	dw 5, 9, 20; Black
	dw 6, 9, 20; Black
	dw 7, 9, 20; Black
	dw 8, 9, 20; Black
	dw 9, 9, 20; Black
	dw 10, 9, 20; Black
	dw 11, 9, 20; Black
	dw 4, 10, 20; Black
	dw 5, 10, 20; Black
	dw 6, 10, 20; Black
	dw 7, 10, 20; Black
	dw 8, 10, 20; Black
	dw 9, 10, 20; Black
	dw 10, 10, 20; Black
	dw 11, 10, 20; Black
	dw 3, 11, 20; Black
	dw 4, 11, 20; Black
	dw 5, 11, 19 ; Saddle Brown
	dw 6, 11, 20; Black
	dw 7, 11, 20; Black
	dw 8, 11, 20; Black
	dw 9, 11, 20; Black
	dw 10, 11, 19 ; Saddle Brown
	dw 11, 11, 20; Black
	dw 12, 11, 20; Black
	dw 2, 12, 20; Black
	dw 3, 12, 20; Black
	dw 4, 12, 19 ; Saddle Brown
	dw 5, 12, 19 ; Saddle Brown
	dw 10, 12, 19 ; Saddle Brown
	dw 11, 12, 19 ; Saddle Brown
	dw 12, 12, 20; Black
	dw 13, 12, 20; Black
	dw 2, 13, 20; Black
	dw 3, 13, 20; Black
	dw 4, 13, 19 ; Saddle Brown
	dw 11, 13, 19 ; Saddle Brown
	dw 12, 13, 20; Black
	dw 13, 13, 20; Black
	dw 0,0, 0

	; -------------------------------------------------------------------------
	; END
	; -------------------------------------------------------------------------

	; -------------------------------------------------------------------------
	; S MISSILE SPRITE
	; -------------------------------------------------------------------------
	
	Missile_S  dw 3, 4, 1; Gray
	dw 4, 4, 1; Gray
	dw 14, 4, 1; Gray
	dw 15, 4, 1; Gray
	dw 3, 5, 1; Gray
	dw 4, 5, 1; Gray
	dw 14, 5, 1; Gray
	dw 15, 5, 1; Gray
	dw 5, 6, 1; Gray
	dw 6, 6, 1; Gray
	dw 7, 6, 1; Gray
	dw 8, 6, 1; Gray
	dw 9, 6, 1; Gray
	dw 10, 6, 1; Gray
	dw 11, 6, 1; Gray
	dw 12, 6, 1; Gray
	dw 13, 6, 1; Gray
	dw 5, 7, 1; Gray
	dw 6, 7, 20
	dw 7, 7, 20; Black
	dw 8, 7, 20 ; black
	dw 9, 7, 20 ; black
	dw 10, 7, 20 ; black
	dw 11, 7, 20 ; black
	dw 12, 7, 20 ; black
	dw 13, 7, 1; Gray
	dw 5, 8, 1; Gray
	dw 6, 8, 20 ; black
	dw 7, 8, 255
	dw 8, 8, 255
	dw 9, 8, 255
	dw 10, 8, 255
	dw 11, 8, 20 ; black
	dw 12, 8, 20 ; black
	dw 13, 8, 1; Gray
	dw 5, 9, 1; Gray
	dw 6, 9, 20 ; black
	dw 7, 9, 255
	dw 8, 9, 255
	dw 9, 9, 255
	dw 10, 9, 255
	dw 11, 9, 255
	dw 12, 9, 20 ; black
	dw 13, 9, 1; Gray
	dw 5, 10, 1; Gray
	dw 6, 10, 20 ; black
	dw 7, 10, 20 ; black
	dw 8, 10, 20 ; black
	dw 9, 10, 20 ; black
	dw 10, 10, 255
	dw 11, 10, 255
	dw 12, 10, 20 ; black
	dw 13, 10, 1; Gray
	dw 5, 11, 1; Gray
	dw 6, 11, 20 ; black
	dw 7, 11, 20 ; black
	dw 8, 11, 20 ; black
	dw 9, 11, 20 ; black
	dw 10, 11, 20 ; black
	dw 11, 11, 20 ; black
	dw 12, 11, 20 ; black
	dw 13, 11, 1; Gray
	dw 5, 12, 1; Gray
	dw 6, 12, 1; Gray
	dw 7, 12, 1; Gray
	dw 8, 12, 1; Gray
	dw 9, 12, 1; Gray
	dw 10, 12, 1; Gray
	dw 11, 12, 1; Gray
	dw 12, 12, 1; Gray
	dw 13, 12, 1; Gray
	dw 5, 13, 1; Gray
	dw 6, 13, 1; Gray
	dw 7, 13, 1; Gray
	dw 8, 13, 1; Gray
	dw 9, 13, 1; Gray
	dw 10, 13, 1; Gray
	dw 11, 13, 1; Gray
	dw 12, 13, 1; Gray
	dw 13, 13, 1; Gray
	dw 3, 14, 1; Gray
	dw 4, 14, 1; Gray
	dw 5, 14, 1; Gray
	dw 13, 14, 1; Gray
	dw 14, 14, 1; Gray
	dw 15, 14, 1; Gray
	dw 3, 15, 1; Gray
	dw 4, 15, 1; Gray
	dw 5, 15, 1; Gray
	dw 13, 15, 1; Gray
	dw 14, 15, 1; Gray
	dw 15, 15, 1; Gray
	dw 0, 0, 0

	; -------------------------------------------------------------------------
	; END
	; -------------------------------------------------------------------------

	; -------------------------------------------------------------------------
	; M MISSILE SPRITE
	; -------------------------------------------------------------------------

	Missile_M dw 3, 7, 20  ; black
	dw 4, 7, 20  ; black
	dw 5, 7, 20  ; black
	dw 6, 7, 20  ; black
	dw 27, 7, 20 ; BLACK
	dw 28, 7, 20 ; BLACK
	dw 29, 7, 20 ; BLACK
	dw 30, 7, 20 ; BLACK
	dw 3, 8, 20 ; BLACK
	dw 4, 8, 20 ; BLACK
	dw 5, 8, 20 ; BLACK
	dw 6, 8, 20 ; BLACK
	dw 27, 8, 20 ; BLACK
	dw 28, 8, 20 ; BLACK
	dw 29, 8, 20 ; BLACK
	dw 30, 8, 20 ; BLACK
	dw 3, 9, 20 ; BLACK
	dw 4, 9, 20 ; BLACK
	dw 5, 9, 40; GRAY
	dw 6, 9, 40; GRAY
	dw 7, 9, 20 ; BLACK
	dw 8, 9, 20 ; BLACK
	dw 25, 9, 20 ; BLACK
	dw 26, 9, 20 ; BLACK
	dw 27, 9, 40; GRAY
	dw 28, 9, 40; GRAY
	dw 29, 9, 20 ; BLACK
	dw 30, 9, 20 ; BLACK
	dw 3, 10, 20 ; BLACK
	dw 4, 10, 20 ; BLACK
	dw 5, 10, 40; GRAY
	dw 6, 10, 40; GRAY
	dw 7, 10, 20 ; BLACK
	dw 8, 10, 20 ; BLACK
	dw 25, 10, 20 ; BLACK
	dw 26, 10, 20 ; BLACK
	dw 27, 10, 40; GRAY
	dw 28, 10, 40; GRAY
	dw 29, 10, 20 ; BLACK
	dw 30, 10, 20 ; BLACK
	dw 5, 11, 20 ; BLACK
	dw 6, 11, 20 ; BLACK
	dw 7, 11, 40; GRAY
	dw 8, 11, 40; GRAY
	dw 9, 11, 20 ; BLACK
	dw 10, 11, 20 ; BLACK
	dw 15, 11, 79; RED
	dw 16, 11, 79; RED
	dw 17, 11, 70; ORANGE
	dw 18, 11, 70; ORANGE
	dw 23, 11, 20 ; BLACK
	dw 24, 11, 20 ; BLACK
	dw 25, 11, 40; GRAY
	dw 26, 11, 40; GRAY
	dw 27, 11, 20 ; BLACK
	dw 28, 11, 20 ; BLACK
	dw 5, 12, 20 ; BLACK
	dw 6, 12, 20 ; BLACK
	dw 7, 12, 40; GRAY
	dw 8, 12, 40; GRAY
	dw 9, 12, 20 ; BLACK
	dw 10, 12, 20 ; BLACK
	dw 13, 12, 79; RED
	dw 14, 12, 79; RED
	dw 15, 12, 70; ORANGE
	dw 16, 12, 70; ORANGE
	dw 17, 12, 251
	dw 18, 12, 251
	dw 19, 12, 79; RED
	dw 20, 12, 79; RED
	dw 23, 12, 20 ; BLACK
	dw 24, 12, 20 ; BLACK
	dw 25, 12, 40; GRAY
	dw 26, 12, 40; GRAY
	dw 27, 12, 20 ; BLACK
	dw 28, 12, 20 ; BLACK
	dw 7, 13, 20 ; BLACK
	dw 8, 13, 20 ; BLACK
	dw 9, 13, 40; GRAY
	dw 10, 13, 40; GRAY
	dw 11, 13, 20 ; BLACK
	dw 12, 13, 20 ; BLACK
	dw 13, 13, 1
	dw 14, 13, 1
	dw 15, 13, 20 ; BLACK
	dw 16, 13, 20 ; BLACK
	dw 17, 13, 20 ; BLACK
	dw 18, 13, 20 ; BLACK
	dw 19, 13, 1
	dw 20, 13, 1
	dw 21, 13, 20 ; BLACK
	dw 22, 13, 20 ; BLACK
	dw 23, 13, 40; GRAY
	dw 24, 13, 40; GRAY
	dw 25, 13, 20 ; BLACK
	dw 26, 13, 20 ; BLACK
	dw 7, 14, 20 ; BLACK
	dw 8, 14, 20 ; BLACK
	dw 9, 14, 40; GRAY
	dw 10, 14, 40; GRAY
	dw 11, 14, 20 ; BLACK
	dw 12, 14, 20 ; BLACK
	dw 13, 14, 20 ; BLACK
	dw 14, 14, 20 ; BLACK
	dw 15, 14, 20 ; BLACK
	dw 16, 14, 20 ; BLACK
	dw 17, 14, 20 ; BLACK
	dw 18, 14, 20 ; BLACK
	dw 19, 14, 20 ; BLACK
	dw 20, 14, 20 ; BLACK
	dw 21, 14, 20 ; BLACK
	dw 22, 14, 20 ; BLACK
	dw 23, 14, 40; GRAY
	dw 24, 14, 40; GRAY
	dw 25, 14, 20 ; BLACK
	dw 26, 14, 20 ; BLACK
	dw 9, 15, 20 ; BLACK
	dw 10, 15, 20 ; BLACK
	dw 11, 15, 20 ; BLACK
	dw 12, 15, 20 ; BLACK
	dw 13, 15, 20 ; BLACK
	dw 14, 15, 20 ; BLACK
	dw 15, 15, 40; GRAY
	dw 16, 15, 40; GRAY
	dw 17, 15, 255
	dw 18, 15, 255
	dw 19, 15, 20 ; BLACK
	dw 20, 15, 20 ; BLACK
	dw 21, 15, 20 ; BLACK
	dw 22, 15, 20 ; BLACK
	dw 23, 15, 20 ; BLACK
	dw 24, 15, 20 ; BLACK
	dw 9, 16, 20 ; BLACK
	dw 10, 16, 20 ; BLACK
	dw 11, 16, 20 ; BLACK
	dw 12, 16, 20 ; BLACK
	dw 13, 16, 40; GRAY
	dw 14, 16, 40; GRAY
	dw 15, 16, 255
	dw 16, 16, 255
	dw 17, 16, 255
	dw 18, 16, 255
	dw 19, 16, 255
	dw 20, 16, 255
	dw 21, 16, 20 ; BLACK
	dw 22, 16, 20 ; BLACK
	dw 23, 16, 20 ; BLACK
	dw 24, 16, 20 ; BLACK
	dw 9, 17, 1
	dw 10, 17, 1
	dw 11, 17, 20 ; BLACK
	dw 12, 17, 20 ; BLACK
	dw 13, 17, 40; GRAY
	dw 14, 17, 40; GRAY
	dw 15, 17, 40; GRAY
	dw 16, 17, 40; GRAY
	dw 17, 17, 255
	dw 18, 17, 255
	dw 19, 17, 255
	dw 20, 17, 255
	dw 21, 17, 20 ; BLACK
	dw 22, 17, 20 ; BLACK
	dw 23, 17, 1
	dw 24, 17, 1
	dw 7, 18, 79; RED
	dw 8, 18, 79; RED
	dw 9, 18, 20 ; BLACK
	dw 10, 18, 20 ; BLACK
	dw 11, 18, 40; GRAY
	dw 12, 18, 40; GRAY
	dw 13, 18, 20 ; BLACK
	dw 14, 18, 20 ; BLACK
	dw 15, 18, 255
	dw 16, 18, 255
	dw 17, 18, 255
	dw 18, 18, 255
	dw 19, 18, 255
	dw 20, 18, 255
	dw 21, 18, 255
	dw 22, 18, 255
	dw 23, 18, 20 ; BLACK
	dw 24, 18, 20 ; BLACK
	dw 25, 18, 79; RED
	dw 26, 18, 79; RED
	dw 7, 19, 79; RED
	dw 8, 19, 79; RED
	dw 9, 19, 20 ; BLACK
	dw 10, 19, 20 ; BLACK
	dw 11, 19, 40; GRAY
	dw 12, 19, 40; GRAY
	dw 13, 19, 40; GRAY
	dw 14, 19, 40; GRAY
	dw 15, 19, 40; GRAY
	dw 16, 19, 40; GRAY
	dw 17, 19, 255
	dw 18, 19, 255
	dw 19, 19, 255
	dw 20, 19, 255
	dw 21, 19, 255
	dw 22, 19, 255
	dw 23, 19, 20 ; BLACK
	dw 24, 19, 20 ; BLACK
	dw 25, 19, 79; RED
	dw 26, 19, 79; RED
	dw 7, 20, 70; ORANGE
	dw 8, 20, 70; ORANGE
	dw 9, 20, 20 ; BLACK
	dw 10, 20, 20 ; BLACK
	dw 11, 20, 20 ; BLACK
	dw 12, 20, 20 ; BLACK
	dw 13, 20, 40; GRAY
	dw 14, 20, 40; GRAY
	dw 15, 20, 40; GRAY
	dw 16, 20, 40; GRAY
	dw 17, 20, 255
	dw 18, 20, 255
	dw 19, 20, 255
	dw 20, 20, 255
	dw 21, 20, 255
	dw 22, 20, 255
	dw 23, 20, 20 ; BLACK
	dw 24, 20, 20 ; BLACK
	dw 25, 20, 70; ORANGE
	dw 26, 20, 70; ORANGE
	dw 7, 21, 251
	dw 8, 21, 251
	dw 9, 21, 20 ; BLACK
	dw 10, 21, 20 ; BLACK
	dw 11, 21, 20 ; BLACK
	dw 12, 21, 20 ; BLACK
	dw 13, 21, 20 ; BLACK
	dw 14, 21, 20 ; BLACK
	dw 15, 21, 20 ; BLACK
	dw 16, 21, 20 ; BLACK
	dw 17, 21, 255
	dw 18, 21, 255
	dw 19, 21, 40; GRAY
	dw 20, 21, 40; GRAY
	dw 21, 21, 255
	dw 22, 21, 255
	dw 23, 21, 20 ; BLACK
	dw 24, 21, 20 ; BLACK
	dw 25, 21, 251
	dw 26, 21, 251
	dw 7, 22, 70; ORANGE
	dw 8, 22, 70; ORANGE
	dw 9, 22, 20 ; BLACK
	dw 10, 22, 20 ; BLACK
	dw 11, 22, 20 ; BLACK
	dw 12, 22, 20 ; BLACK
	dw 13, 22, 20 ; BLACK
	dw 14, 22, 20 ; BLACK
	dw 15, 22, 20 ; BLACK
	dw 16, 22, 20 ; BLACK
	dw 17, 22, 40; GRAY
	dw 18, 22, 40; GRAY
	dw 19, 22, 255
	dw 20, 22, 255
	dw 21, 22, 40; GRAY
	dw 22, 22, 40; GRAY
	dw 23, 22, 20 ; BLACK
	dw 24, 22, 20 ; BLACK
	dw 25, 22, 70; ORANGE
	dw 26, 22, 70; ORANGE
	dw 7, 23, 79; RED
	dw 8, 23, 79; RED
	dw 9, 23, 20 ; BLACK
	dw 10, 23, 20 ; BLACK
	dw 11, 23, 20 ; BLACK
	dw 12, 23, 20 ; BLACK
	dw 13, 23, 20 ; BLACK
	dw 14, 23, 20 ; BLACK
	dw 15, 23, 20 ; BLACK
	dw 16, 23, 20 ; BLACK
	dw 17, 23, 40; GRAY
	dw 18, 23, 40; GRAY
	dw 19, 23, 40; GRAY
	dw 20, 23, 40; GRAY
	dw 21, 23, 255
	dw 22, 23, 255
	dw 23, 23, 20 ; BLACK
	dw 24, 23, 20 ; BLACK
	dw 25, 23, 79; RED
	dw 26, 23, 79; RED
	dw 9, 24, 1
	dw 10, 24, 1
	dw 11, 24, 20 ; BLACK
	dw 12, 24, 20 ; BLACK
	dw 13, 24, 20 ; BLACK
	dw 14, 24, 20 ; BLACK
	dw 15, 24, 20 ; BLACK
	dw 16, 24, 20 ; BLACK
	dw 17, 24, 20 ; BLACK
	dw 18, 24, 20 ; BLACK
	dw 19, 24, 40; GRAY
	dw 20, 24, 40; GRAY
	dw 21, 24, 20 ; BLACK
	dw 22, 24, 20 ; BLACK
	dw 23, 24, 1
	dw 24, 24, 1
	dw 9, 25, 20 ; BLACK
	dw 10, 25, 20 ; BLACK
	dw 11, 25, 20 ; BLACK
	dw 12, 25, 20 ; BLACK
	dw 13, 25, 20 ; BLACK
	dw 14, 25, 20 ; BLACK
	dw 15, 25, 20 ; BLACK
	dw 16, 25, 20 ; BLACK
	dw 17, 25, 40; GRAY
	dw 18, 25, 40; GRAY
	dw 19, 25, 20 ; BLACK
	dw 20, 25, 20 ; BLACK
	dw 21, 25, 20 ; BLACK
	dw 22, 25, 20 ; BLACK
	dw 23, 25, 20 ; BLACK
	dw 24, 25, 20 ; BLACK
	dw 9, 26, 20 ; BLACK
	dw 10, 26, 20 ; BLACK
	dw 11, 26, 20 ; BLACK
	dw 12, 26, 20 ; BLACK
	dw 13, 26, 20 ; BLACK
	dw 14, 26, 20 ; BLACK
	dw 15, 26, 20 ; BLACK
	dw 16, 26, 20 ; BLACK
	dw 17, 26, 20 ; BLACK
	dw 18, 26, 20 ; BLACK
	dw 19, 26, 20 ; BLACK
	dw 20, 26, 20 ; BLACK
	dw 21, 26, 20 ; BLACK
	dw 22, 26, 20 ; BLACK
	dw 23, 26, 20 ; BLACK
	dw 24, 26, 20 ; BLACK
	dw 7, 27, 20 ; BLACK
	dw 8, 27, 20 ; BLACK
	dw 9, 27, 40; GRAY
	dw 10, 27, 40; GRAY
	dw 11, 27, 20 ; BLACK
	dw 12, 27, 20 ; BLACK
	dw 13, 27, 20 ; BLACK
	dw 14, 27, 20 ; BLACK
	dw 15, 27, 20 ; BLACK
	dw 16, 27, 20 ; BLACK
	dw 17, 27, 20 ; BLACK
	dw 18, 27, 20 ; BLACK
	dw 19, 27, 20 ; BLACK
	dw 20, 27, 20 ; BLACK
	dw 21, 27, 20 ; BLACK
	dw 22, 27, 20 ; BLACK
	dw 23, 27, 40; GRAY
	dw 24, 27, 40; GRAY
	dw 25, 27, 20 ; BLACK
	dw 26, 27, 20 ; BLACK
	dw 7, 28, 20 ; BLACK
	dw 8, 28, 20 ; BLACK
	dw 9, 28, 40; GRAY
	dw 10, 28, 40; GRAY
	dw 11, 28, 20 ; BLACK
	dw 12, 28, 20 ; BLACK
	dw 13, 28, 1
	dw 14, 28, 1
	dw 15, 28, 20 ; BLACK
	dw 16, 28, 20 ; BLACK
	dw 17, 28, 20 ; BLACK
	dw 18, 28, 20 ; BLACK
	dw 19, 28, 1
	dw 20, 28, 1
	dw 21, 28, 20 ; BLACK
	dw 22, 28, 20 ; BLACK
	dw 23, 28, 40; GRAY
	dw 24, 28, 40; GRAY
	dw 25, 28, 20 ; BLACK
	dw 26, 28, 20 ; BLACK
	dw 5, 29, 20 ; BLACK
	dw 6, 29, 20 ; BLACK
	dw 7, 29, 40; GRAY
	dw 8, 29, 40; GRAY
	dw 9, 29, 20 ; BLACK
	dw 10, 29, 20 ; BLACK
	dw 13, 29, 79; RED
	dw 14, 29, 79; RED
	dw 15, 29, 251
	dw 16, 29, 251
	dw 17, 29, 70; ORANGE
	dw 18, 29, 70; ORANGE
	dw 19, 29, 79; RED
	dw 20, 29, 79; RED
	dw 23, 29, 20 ; BLACK
	dw 24, 29, 20 ; BLACK
	dw 25, 29, 40; GRAY
	dw 26, 29, 40; GRAY
	dw 27, 29, 20 ; BLACK
	dw 28, 29, 20 ; BLACK
	dw 5, 30, 20 ; BLACK
	dw 6, 30, 20 ; BLACK
	dw 7, 30, 40; GRAY
	dw 8, 30, 40; GRAY
	dw 9, 30, 20 ; BLACK
	dw 10, 30, 20 ; BLACK
	dw 15, 30, 70; ORANGE
	dw 16, 30, 70; ORANGE
	dw 17, 30, 79; RED
	dw 18, 30, 79; RED
	dw 23, 30, 20 ; BLACK
	dw 24, 30, 20 ; BLACK
	dw 25, 30, 40; GRAY
	dw 26, 30, 40; GRAY
	dw 27, 30, 20 ; BLACK
	dw 28, 30, 20 ; BLACK
	dw 3, 31, 20 ; BLACK
	dw 4, 31, 20 ; BLACK
	dw 5, 31, 40; GRAY
	dw 6, 31, 40; GRAY
	dw 7, 31, 20 ; BLACK
	dw 8, 31, 20 ; BLACK
	dw 25, 31, 20 ; BLACK
	dw 26, 31, 20 ; BLACK
	dw 27, 31, 40; GRAY
	dw 28, 31, 40; GRAY
	dw 29, 31, 20 ; BLACK
	dw 30, 31, 20 ; BLACK
	dw 3, 32, 20 ; BLACK
	dw 4, 32, 20 ; BLACK
	dw 5, 32, 40; GRAY
	dw 6, 32, 40; GRAY
	dw 7, 32, 20 ; BLACK
	dw 8, 32, 20 ; BLACK
	dw 25, 32, 20 ; BLACK
	dw 26, 32, 20 ; BLACK
	dw 27, 32, 40; GRAY
	dw 28, 32, 40; GRAY
	dw 29, 32, 20 ; BLACK
	dw 30, 32, 20 ; BLACK
	dw 3, 33, 20 ; BLACK
	dw 4, 33, 20 ; BLACK
	dw 5, 33, 20 ; BLACK
	dw 6, 33, 20 ; BLACK
	dw 27, 33, 20 ; BLACK
	dw 28, 33, 20 ; BLACK
	dw 29, 33, 20 ; BLACK
	dw 30, 33, 20 ; BLACK
	dw 3, 34, 20 ; BLACK
	dw 4, 34, 20 ; BLACK
	dw 5, 34, 20 ; BLACK
	dw 6, 34, 20 ; BLACK
	dw 27, 34, 20 ; BLACK
	dw 28, 34, 20 ; BLACK
	dw 29, 34, 20 ; BLACK
	dw 30, 34, 20 ; BLACK
	dw 0, 0, 0

	; -------------------------------------------------------------------------
	; END
	; -------------------------------------------------------------------------
	
	; -------------------------------------------------------------------------
	; L MISSILE SPRITE
	; -------------------------------------------------------------------------

	Missile_L dw 3, 8, 20 ; BLACK
	dw 4, 8, 20 ; BLACK
	dw 5, 8, 20 ; BLACK
	dw 6, 8, 20 ; BLACK
	dw 35, 8, 20 ; BLACK
	dw 36, 8, 20 ; BLACK
	dw 37, 8, 20 ; BLACK
	dw 38, 8, 20 ; BLACK
	dw 3, 9, 20 ; BLACK
	dw 4, 9, 20 ; BLACK
	dw 5, 9, 20 ; BLACK
	dw 6, 9, 20 ; BLACK
	dw 35, 9, 20 ; BLACK
	dw 36, 9, 20 ; BLACK
	dw 37, 9, 20 ; BLACK
	dw 38, 9, 20 ; BLACK
	dw 3, 10, 20 ; BLACK
	dw 4, 10, 20 ; BLACK
	dw 5, 10, 40; GRAY
	dw 6, 10, 40; GRAY
	dw 7, 10, 20 ; BLACK
	dw 8, 10, 20 ; BLACK
	dw 33, 10, 20 ; BLACK
	dw 34, 10, 20 ; BLACK
	dw 35, 10, 40; GRAY
	dw 36, 10, 40; GRAY
	dw 37, 10, 20 ; BLACK
	dw 38, 10, 20 ; BLACK
	dw 3, 11, 20 ; BLACK
	dw 4, 11, 20 ; BLACK
	dw 5, 11, 40; GRAY
	dw 6, 11, 40; GRAY
	dw 7, 11, 20 ; BLACK
	dw 8, 11, 20 ; BLACK
	dw 17, 11, 1
	dw 18, 11, 1
	dw 19, 11, 79; RED
	dw 20, 11, 79; RED
	dw 21, 11, 79; RED
	dw 22, 11, 79; RED
	dw 23, 11, 1
	dw 24, 11, 1
	dw 33, 11, 20 ; BLACK
	dw 34, 11, 20 ; BLACK
	dw 35, 11, 40; GRAY
	dw 36, 11, 40; GRAY
	dw 37, 11, 20 ; BLACK
	dw 38, 11, 20 ; BLACK
	dw 5, 12, 20 ; BLACK
	dw 6, 12, 20 ; BLACK
	dw 7, 12, 40; GRAY
	dw 8, 12, 40; GRAY
	dw 9, 12, 20 ; BLACK
	dw 10, 12, 20 ; BLACK
	dw 13, 12, 1
	dw 14, 12, 1
	dw 15, 12, 70; ORANGE
	dw 16, 12, 70; ORANGE
	dw 17, 12, 251
	dw 18, 12, 251
	dw 19, 12, 251
	dw 20, 12, 251
	dw 21, 12, 251
	dw 22, 12, 251
	dw 23, 12, 251
	dw 24, 12, 251
	dw 25, 12, 70; ORANGE
	dw 26, 12, 70; ORANGE
	dw 31, 12, 20 ; BLACK
	dw 32, 12, 20 ; BLACK
	dw 33, 12, 40; GRAY
	dw 34, 12, 40; GRAY
	dw 35, 12, 20 ; BLACK
	dw 36, 12, 20 ; BLACK
	dw 5, 13, 20 ; BLACK
	dw 6, 13, 20 ; BLACK
	dw 7, 13, 40; GRAY
	dw 8, 13, 40; GRAY
	dw 9, 13, 20 ; BLACK
	dw 10, 13, 20 ; BLACK
	dw 11, 13, 79; RED
	dw 12, 13, 79; RED
	dw 13, 13, 70; ORANGE
	dw 14, 13, 70; ORANGE
	dw 15, 13, 251
	dw 16, 13, 251
	dw 17, 13, 251
	dw 18, 13, 251
	dw 19, 13, 251
	dw 20, 13, 251
	dw 21, 13, 251
	dw 22, 13, 251
	dw 23, 13, 251
	dw 24, 13, 251
	dw 25, 13, 251
	dw 26, 13, 251
	dw 27, 13, 1
	dw 28, 13, 1
	dw 29, 13, 1
	dw 30, 13, 1
	dw 31, 13, 20 ; BLACK
	dw 32, 13, 20 ; BLACK
	dw 33, 13, 40; GRAY
	dw 34, 13, 40; GRAY
	dw 35, 13, 20 ; BLACK
	dw 36, 13, 20 ; BLACK
	dw 7, 14, 20 ; BLACK
	dw 8, 14, 20 ; BLACK
	dw 9, 14, 40; GRAY
	dw 10, 14, 40; GRAY
	dw 11, 14, 20 ; BLACK
	dw 12, 14, 20 ; BLACK
	dw 13, 14, 251
	dw 14, 14, 251
	dw 15, 14, 251
	dw 16, 14, 251
	dw 17, 14, 20 ; BLACK
	dw 18, 14, 20 ; BLACK
	dw 19, 14, 20 ; BLACK
	dw 20, 14, 20 ; BLACK
	dw 21, 14, 20 ; BLACK
	dw 22, 14, 20 ; BLACK
	dw 23, 14, 20 ; BLACK
	dw 24, 14, 20 ; BLACK
	dw 25, 14, 251
	dw 26, 14, 251
	dw 27, 14, 70; ORANGE
	dw 28, 14, 70; ORANGE
	dw 29, 14, 20 ; BLACK
	dw 30, 14, 20 ; BLACK
	dw 31, 14, 40; GRAY
	dw 32, 14, 40; GRAY
	dw 33, 14, 20 ; BLACK
	dw 34, 14, 20 ; BLACK
	dw 7, 15, 20 ; BLACK
	dw 8, 15, 20 ; BLACK
	dw 9, 15, 40; GRAY
	dw 10, 15, 40; GRAY
	dw 11, 15, 20 ; BLACK
	dw 12, 15, 20 ; BLACK
	dw 13, 15, 251
	dw 14, 15, 251
	dw 15, 15, 20 ; BLACK
	dw 16, 15, 20 ; BLACK
	dw 17, 15, 40; GRAY
	dw 18, 15, 40; GRAY
	dw 19, 15, 40; GRAY
	dw 20, 15, 40; GRAY
	dw 21, 15, 40; GRAY
	dw 22, 15, 40; GRAY
	dw 23, 15, 40; GRAY
	dw 24, 15, 40; GRAY
	dw 25, 15, 20 ; BLACK
	dw 26, 15, 20 ; BLACK
	dw 27, 15, 251
	dw 28, 15, 251
	dw 29, 15, 20 ; BLACK
	dw 30, 15, 20 ; BLACK
	dw 31, 15, 40; GRAY
	dw 32, 15, 40; GRAY
	dw 33, 15, 20 ; BLACK
	dw 34, 15, 20 ; BLACK
	dw 7, 16, 1
	dw 8, 16, 1
	dw 9, 16, 20 ; BLACK
	dw 10, 16, 20 ; BLACK
	dw 11, 16, 40; GRAY
	dw 12, 16, 40; GRAY
	dw 13, 16, 20 ; BLACK
	dw 14, 16, 20 ; BLACK
	dw 15, 16, 40; GRAY
	dw 16, 16, 40; GRAY
	dw 17, 16, 20 ; BLACK
	dw 18, 16, 20 ; BLACK
	dw 19, 16, 40; GRAY
	dw 20, 16, 40; GRAY
	dw 21, 16, 255
	dw 22, 16, 255
	dw 23, 16, 255
	dw 24, 16, 255
	dw 25, 16, 40; GRAY
	dw 26, 16, 40; GRAY
	dw 27, 16, 20 ; BLACK
	dw 28, 16, 20 ; BLACK
	dw 29, 16, 40; GRAY
	dw 30, 16, 40; GRAY
	dw 31, 16, 20 ; BLACK
	dw 32, 16, 20 ; BLACK
	dw 7, 17, 79; RED
	dw 8, 17, 79; RED
	dw 9, 17, 251
	dw 10, 17, 251
	dw 11, 17, 20 ; BLACK
	dw 12, 17, 20 ; BLACK
	dw 13, 17, 20 ; BLACK
	dw 14, 17, 20 ; BLACK
	dw 15, 17, 20 ; BLACK
	dw 16, 17, 20 ; BLACK
	dw 17, 17, 40; GRAY
	dw 18, 17, 40; GRAY
	dw 19, 17, 40; GRAY
	dw 20, 17, 40; GRAY
	dw 21, 17, 40; GRAY
	dw 22, 17, 40; GRAY
	dw 23, 17, 255
	dw 24, 17, 255
	dw 25, 17, 255
	dw 26, 17, 255
	dw 27, 17, 20 ; BLACK
	dw 28, 17, 20 ; BLACK
	dw 29, 17, 20 ; BLACK
	dw 30, 17, 20 ; BLACK
	dw 31, 17, 251
	dw 32, 17, 251
	dw 33, 17, 70; ORANGE
	dw 34, 17, 70; ORANGE
	dw 7, 18, 70; ORANGE
	dw 8, 18, 70; ORANGE
	dw 9, 18, 251
	dw 10, 18, 251
	dw 11, 18, 20 ; BLACK
	dw 12, 18, 20 ; BLACK
	dw 13, 18, 40; GRAY
	dw 14, 18, 40; GRAY
	dw 15, 18, 40; GRAY
	dw 16, 18, 40; GRAY
	dw 17, 18, 20 ; BLACK
	dw 18, 18, 20 ; BLACK
	dw 19, 18, 20 ; BLACK
	dw 20, 18, 20 ; BLACK
	dw 21, 18, 20 ; BLACK
	dw 22, 18, 20 ; BLACK
	dw 23, 18, 20 ; BLACK
	dw 24, 18, 20 ; BLACK
	dw 25, 18, 40; GRAY
	dw 26, 18, 40; GRAY
	dw 27, 18, 40; GRAY
	dw 28, 18, 40; GRAY
	dw 29, 18, 20 ; BLACK
	dw 30, 18, 20 ; BLACK
	dw 31, 18, 251
	dw 32, 18, 251
	dw 33, 18, 70; ORANGE
	dw 34, 18, 70; ORANGE
	dw 7, 19, 251
	dw 8, 19, 251
	dw 9, 19, 70; ORANGE
	dw 10, 19, 70; ORANGE
	dw 11, 19, 20 ; BLACK
	dw 12, 19, 20 ; BLACK
	dw 13, 19, 20 ; BLACK
	dw 14, 19, 20 ; BLACK
	dw 15, 19, 20 ; BLACK
	dw 16, 19, 20 ; BLACK
	dw 17, 19, 20 ; BLACK
	dw 18, 19, 20 ; BLACK
	dw 19, 19, 255
	dw 20, 19, 255
	dw 21, 19, 255
	dw 22, 19, 255
	dw 23, 19, 20 ; BLACK
	dw 24, 19, 20 ; BLACK
	dw 25, 19, 20 ; BLACK
	dw 26, 19, 20 ; BLACK
	dw 27, 19, 255
	dw 28, 19, 255
	dw 29, 19, 20 ; BLACK
	dw 30, 19, 20 ; BLACK
	dw 31, 19, 70; ORANGE
	dw 32, 19, 70; ORANGE
	dw 33, 19, 251
	dw 34, 19, 251
	dw 7, 20, 70; ORANGE
	dw 8, 20, 70; ORANGE
	dw 9, 20, 20 ; BLACK
	dw 10, 20, 20 ; BLACK
	dw 11, 20, 20 ; BLACK
	dw 12, 20, 20 ; BLACK
	dw 13, 20, 40; GRAY
	dw 14, 20, 40; GRAY
	dw 15, 20, 20 ; BLACK
	dw 16, 20, 20 ; BLACK
	dw 17, 20, 40; GRAY
	dw 18, 20, 40; GRAY
	dw 19, 20, 40; GRAY
	dw 20, 20, 40; GRAY
	dw 21, 20, 255
	dw 22, 20, 255
	dw 23, 20, 255
	dw 24, 20, 255
	dw 25, 20, 20 ; BLACK
	dw 26, 20, 20 ; BLACK
	dw 27, 20, 40; GRAY
	dw 28, 20, 40; GRAY
	dw 29, 20, 40; GRAY
	dw 30, 20, 40; GRAY
	dw 31, 20, 20 ; BLACK
	dw 32, 20, 20 ; BLACK
	dw 33, 20, 70; ORANGE
	dw 34, 20, 70; ORANGE
	dw 35, 20, 1
	dw 36, 20, 1
	dw 5, 21, 1
	dw 6, 21, 1
	dw 7, 21, 251
	dw 8, 21, 251
	dw 9, 21, 20 ; BLACK
	dw 10, 21, 20 ; BLACK
	dw 11, 21, 40; GRAY
	dw 12, 21, 40; GRAY
	dw 13, 21, 20 ; BLACK
	dw 14, 21, 20 ; BLACK
	dw 15, 21, 40; GRAY
	dw 16, 21, 40; GRAY
	dw 17, 21, 40; GRAY
	dw 18, 21, 40; GRAY
	dw 19, 21, 255
	dw 20, 21, 255
	dw 21, 21, 255
	dw 22, 21, 255
	dw 23, 21, 255
	dw 24, 21, 255
	dw 25, 21, 255
	dw 26, 21, 255
	dw 27, 21, 20 ; BLACK
	dw 28, 21, 20 ; BLACK
	dw 29, 21, 40; GRAY
	dw 30, 21, 40; GRAY
	dw 31, 21, 20 ; BLACK
	dw 32, 21, 20 ; BLACK
	dw 33, 21, 251
	dw 34, 21, 251
	dw 35, 21, 1
	dw 36, 21, 1
	dw 5, 22, 1
	dw 6, 22, 1
	dw 7, 22, 251
	dw 8, 22, 251
	dw 9, 22, 20 ; BLACK
	dw 10, 22, 20 ; BLACK
	dw 11, 22, 20 ; BLACK
	dw 12, 22, 20 ; BLACK
	dw 13, 22, 20 ; BLACK
	dw 14, 22, 20 ; BLACK
	dw 15, 22, 40; GRAY
	dw 16, 22, 40; GRAY
	dw 17, 22, 40; GRAY
	dw 18, 22, 40; GRAY
	dw 19, 22, 40; GRAY
	dw 20, 22, 40; GRAY
	dw 21, 22, 255
	dw 22, 22, 255
	dw 23, 22, 255
	dw 24, 22, 255
	dw 25, 22, 255
	dw 26, 22, 255
	dw 27, 22, 20 ; BLACK
	dw 28, 22, 20 ; BLACK
	dw 29, 22, 40; GRAY
	dw 30, 22, 40; GRAY
	dw 31, 22, 20 ; BLACK
	dw 32, 22, 20 ; BLACK
	dw 33, 22, 70; ORANGE
	dw 34, 22, 70; ORANGE
	dw 35, 22, 1
	dw 36, 22, 1
	dw 5, 23, 79; RED
	dw 6, 23, 79; RED
	dw 7, 23, 251
	dw 8, 23, 251
	dw 9, 23, 20 ; BLACK
	dw 10, 23, 20 ; BLACK
	dw 11, 23, 40; GRAY
	dw 12, 23, 40; GRAY
	dw 13, 23, 20 ; BLACK
	dw 14, 23, 20 ; BLACK
	dw 15, 23, 40; GRAY
	dw 16, 23, 40; GRAY
	dw 17, 23, 20 ; BLACK
	dw 18, 23, 20 ; BLACK
	dw 19, 23, 255
	dw 20, 23, 255
	dw 21, 23, 255
	dw 22, 23, 255
	dw 23, 23, 255
	dw 24, 23, 255
	dw 25, 23, 255
	dw 26, 23, 255
	dw 27, 23, 20 ; BLACK
	dw 28, 23, 20 ; BLACK
	dw 29, 23, 255
	dw 30, 23, 255
	dw 31, 23, 20 ; BLACK
	dw 32, 23, 20 ; BLACK
	dw 33, 23, 251
	dw 34, 23, 251
	dw 35, 23, 1
	dw 36, 23, 1
	dw 5, 24, 79; RED
	dw 6, 24, 79; RED
	dw 7, 24, 251
	dw 8, 24, 251
	dw 9, 24, 20 ; BLACK
	dw 10, 24, 20 ; BLACK
	dw 11, 24, 20 ; BLACK
	dw 12, 24, 20 ; BLACK
	dw 13, 24, 20 ; BLACK
	dw 14, 24, 20 ; BLACK
	dw 15, 24, 40; GRAY
	dw 16, 24, 40; GRAY
	dw 17, 24, 40; GRAY
	dw 18, 24, 40; GRAY
	dw 19, 24, 40; GRAY
	dw 20, 24, 40; GRAY
	dw 21, 24, 255
	dw 22, 24, 255
	dw 23, 24, 255
	dw 24, 24, 255
	dw 25, 24, 255
	dw 26, 24, 255
	dw 27, 24, 20 ; BLACK
	dw 28, 24, 20 ; BLACK
	dw 29, 24, 255
	dw 30, 24, 255
	dw 31, 24, 20 ; BLACK
	dw 32, 24, 20 ; BLACK
	dw 33, 24, 251
	dw 34, 24, 251
	dw 35, 24, 79; RED
	dw 36, 24, 79; RED
	dw 5, 25, 79; RED
	dw 6, 25, 79; RED
	dw 7, 25, 251
	dw 8, 25, 251
	dw 9, 25, 20 ; BLACK
	dw 10, 25, 20 ; BLACK
	dw 11, 25, 40; GRAY
	dw 12, 25, 40; GRAY
	dw 13, 25, 20 ; BLACK
	dw 14, 25, 20 ; BLACK
	dw 15, 25, 20 ; BLACK
	dw 16, 25, 20 ; BLACK
	dw 17, 25, 40; GRAY
	dw 18, 25, 40; GRAY
	dw 19, 25, 40; GRAY
	dw 20, 25, 40; GRAY
	dw 21, 25, 255
	dw 22, 25, 255
	dw 23, 25, 255
	dw 24, 25, 255
	dw 25, 25, 255
	dw 26, 25, 255
	dw 27, 25, 20 ; BLACK
	dw 28, 25, 20 ; BLACK
	dw 29, 25, 255
	dw 30, 25, 255
	dw 31, 25, 20 ; BLACK
	dw 32, 25, 20 ; BLACK
	dw 33, 25, 251
	dw 34, 25, 251
	dw 35, 25, 79; RED
	dw 36, 25, 79; RED
	dw 5, 26, 79; RED
	dw 6, 26, 79; RED
	dw 7, 26, 251
	dw 8, 26, 251
	dw 9, 26, 20 ; BLACK
	dw 10, 26, 20 ; BLACK
	dw 11, 26, 20 ; BLACK
	dw 12, 26, 20 ; BLACK
	dw 13, 26, 20 ; BLACK
	dw 14, 26, 20 ; BLACK
	dw 15, 26, 20 ; BLACK
	dw 16, 26, 20 ; BLACK
	dw 17, 26, 20 ; BLACK
	dw 18, 26, 20 ; BLACK
	dw 19, 26, 20 ; BLACK
	dw 20, 26, 20 ; BLACK
	dw 21, 26, 255
	dw 22, 26, 255
	dw 23, 26, 40; GRAY
	dw 24, 26, 40; GRAY
	dw 25, 26, 255
	dw 26, 26, 255
	dw 27, 26, 20 ; BLACK
	dw 28, 26, 20 ; BLACK
	dw 29, 26, 255
	dw 30, 26, 255
	dw 31, 26, 20 ; BLACK
	dw 32, 26, 20 ; BLACK
	dw 33, 26, 251
	dw 34, 26, 251
	dw 35, 26, 79; RED
	dw 36, 26, 79; RED
	dw 5, 27, 1
	dw 6, 27, 1
	dw 7, 27, 251
	dw 8, 27, 251
	dw 9, 27, 20 ; BLACK
	dw 10, 27, 20 ; BLACK
	dw 11, 27, 40; GRAY
	dw 12, 27, 40; GRAY
	dw 13, 27, 20 ; BLACK
	dw 14, 27, 20 ; BLACK
	dw 15, 27, 20 ; BLACK
	dw 16, 27, 20 ; BLACK
	dw 17, 27, 20 ; BLACK
	dw 18, 27, 20 ; BLACK
	dw 19, 27, 20 ; BLACK
	dw 20, 27, 20 ; BLACK
	dw 21, 27, 40; GRAY
	dw 22, 27, 40; GRAY
	dw 23, 27, 255
	dw 24, 27, 255
	dw 25, 27, 40; GRAY
	dw 26, 27, 40; GRAY
	dw 27, 27, 20 ; BLACK
	dw 28, 27, 20 ; BLACK
	dw 29, 27, 255
	dw 30, 27, 255
	dw 31, 27, 20 ; BLACK
	dw 32, 27, 20 ; BLACK
	dw 33, 27, 251
	dw 34, 27, 251
	dw 35, 27, 79; RED
	dw 36, 27, 79; RED
	dw 5, 28, 1
	dw 6, 28, 1
	dw 7, 28, 251
	dw 8, 28, 251
	dw 9, 28, 20 ; BLACK
	dw 10, 28, 20 ; BLACK
	dw 11, 28, 20 ; BLACK
	dw 12, 28, 20 ; BLACK
	dw 13, 28, 20 ; BLACK
	dw 14, 28, 20 ; BLACK
	dw 15, 28, 20 ; BLACK
	dw 16, 28, 20 ; BLACK
	dw 17, 28, 20 ; BLACK
	dw 18, 28, 20 ; BLACK
	dw 19, 28, 20 ; BLACK
	dw 20, 28, 20 ; BLACK
	dw 21, 28, 40; GRAY
	dw 22, 28, 40; GRAY
	dw 23, 28, 40; GRAY
	dw 24, 28, 40; GRAY
	dw 25, 28, 255
	dw 26, 28, 255
	dw 27, 28, 20 ; BLACK
	dw 28, 28, 20 ; BLACK
	dw 29, 28, 40; GRAY
	dw 30, 28, 40; GRAY
	dw 31, 28, 20 ; BLACK
	dw 32, 28, 20 ; BLACK
	dw 33, 28, 251
	dw 34, 28, 251
	dw 35, 28, 1
	dw 36, 28, 1
	dw 5, 29, 1
	dw 6, 29, 1
	dw 7, 29, 70; ORANGE
	dw 8, 29, 70; ORANGE
	dw 9, 29, 20 ; BLACK
	dw 10, 29, 20 ; BLACK
	dw 11, 29, 40; GRAY
	dw 12, 29, 40; GRAY
	dw 13, 29, 20 ; BLACK
	dw 14, 29, 20 ; BLACK
	dw 15, 29, 20 ; BLACK
	dw 16, 29, 20 ; BLACK
	dw 17, 29, 20 ; BLACK
	dw 18, 29, 20 ; BLACK
	dw 19, 29, 20 ; BLACK
	dw 20, 29, 20 ; BLACK
	dw 21, 29, 20 ; BLACK
	dw 22, 29, 20 ; BLACK
	dw 23, 29, 40; GRAY
	dw 24, 29, 40; GRAY
	dw 25, 29, 40; GRAY
	dw 26, 29, 40; GRAY
	dw 27, 29, 20 ; BLACK
	dw 28, 29, 20 ; BLACK
	dw 29, 29, 40; GRAY
	dw 30, 29, 40; GRAY
	dw 31, 29, 20 ; BLACK
	dw 32, 29, 20 ; BLACK
	dw 33, 29, 251
	dw 34, 29, 251
	dw 35, 29, 1
	dw 36, 29, 1
	dw 5, 30, 1
	dw 6, 30, 1
	dw 7, 30, 251
	dw 8, 30, 251
	dw 9, 30, 20 ; BLACK
	dw 10, 30, 20 ; BLACK
	dw 11, 30, 20 ; BLACK
	dw 12, 30, 20 ; BLACK
	dw 13, 30, 20 ; BLACK
	dw 14, 30, 20 ; BLACK
	dw 15, 30, 20 ; BLACK
	dw 16, 30, 20 ; BLACK
	dw 17, 30, 20 ; BLACK
	dw 18, 30, 20 ; BLACK
	dw 19, 30, 20 ; BLACK
	dw 20, 30, 20 ; BLACK
	dw 21, 30, 40; GRAY
	dw 22, 30, 40; GRAY
	dw 23, 30, 20 ; BLACK
	dw 24, 30, 20 ; BLACK
	dw 25, 30, 40; GRAY
	dw 26, 30, 40; GRAY
	dw 27, 30, 20 ; BLACK
	dw 28, 30, 20 ; BLACK
	dw 29, 30, 40; GRAY
	dw 30, 30, 40; GRAY
	dw 31, 30, 20 ; BLACK
	dw 32, 30, 20 ; BLACK
	dw 33, 30, 251
	dw 34, 30, 251
	dw 35, 30, 1
	dw 36, 30, 1
	dw 7, 31, 70; ORANGE
	dw 8, 31, 70; ORANGE
	dw 9, 31, 20 ; BLACK
	dw 10, 31, 20 ; BLACK
	dw 11, 31, 40; GRAY
	dw 12, 31, 40; GRAY
	dw 13, 31, 20 ; BLACK
	dw 14, 31, 20 ; BLACK
	dw 15, 31, 20 ; BLACK
	dw 16, 31, 20 ; BLACK
	dw 17, 31, 20 ; BLACK
	dw 18, 31, 20 ; BLACK
	dw 19, 31, 20 ; BLACK
	dw 20, 31, 20 ; BLACK
	dw 21, 31, 20 ; BLACK
	dw 22, 31, 20 ; BLACK
	dw 23, 31, 40; GRAY
	dw 24, 31, 40; GRAY
	dw 25, 31, 20 ; BLACK
	dw 26, 31, 20 ; BLACK
	dw 27, 31, 40; GRAY
	dw 28, 31, 40; GRAY
	dw 29, 31, 40; GRAY
	dw 30, 31, 40; GRAY
	dw 31, 31, 20 ; BLACK
	dw 32, 31, 20 ; BLACK
	dw 33, 31, 70; ORANGE
	dw 34, 31, 70; ORANGE
	dw 35, 31, 1
	dw 36, 31, 1
	dw 7, 32, 251
	dw 8, 32, 251
	dw 9, 32, 70; ORANGE
	dw 10, 32, 70; ORANGE
	dw 11, 32, 20 ; BLACK
	dw 12, 32, 20 ; BLACK
	dw 13, 32, 40; GRAY
	dw 14, 32, 40; GRAY
	dw 15, 32, 20 ; BLACK
	dw 16, 32, 20 ; BLACK
	dw 17, 32, 20 ; BLACK
	dw 18, 32, 20 ; BLACK
	dw 19, 32, 20 ; BLACK
	dw 20, 32, 20 ; BLACK
	dw 21, 32, 40; GRAY
	dw 22, 32, 40; GRAY
	dw 23, 32, 20 ; BLACK
	dw 24, 32, 20 ; BLACK
	dw 25, 32, 20 ; BLACK
	dw 26, 32, 20 ; BLACK
	dw 27, 32, 255
	dw 28, 32, 255
	dw 29, 32, 20 ; BLACK
	dw 30, 32, 20 ; BLACK
	dw 31, 32, 70; ORANGE
	dw 32, 32, 70; ORANGE
	dw 33, 32, 251
	dw 34, 32, 251
	dw 7, 33, 70; ORANGE
	dw 8, 33, 70; ORANGE
	dw 9, 33, 251
	dw 10, 33, 251
	dw 11, 33, 20 ; BLACK
	dw 12, 33, 20 ; BLACK
	dw 13, 33, 20 ; BLACK
	dw 14, 33, 20 ; BLACK
	dw 15, 33, 40; GRAY
	dw 16, 33, 40; GRAY
	dw 17, 33, 20 ; BLACK
	dw 18, 33, 20 ; BLACK
	dw 19, 33, 20 ; BLACK
	dw 20, 33, 20 ; BLACK
	dw 21, 33, 20 ; BLACK
	dw 22, 33, 20 ; BLACK
	dw 23, 33, 20 ; BLACK
	dw 24, 33, 20 ; BLACK
	dw 25, 33, 40; GRAY
	dw 26, 33, 40; GRAY
	dw 27, 33, 40; GRAY
	dw 28, 33, 40; GRAY
	dw 29, 33, 20 ; BLACK
	dw 30, 33, 20 ; BLACK
	dw 31, 33, 251
	dw 32, 33, 251
	dw 33, 33, 70; ORANGE
	dw 34, 33, 70; ORANGE
	dw 7, 34, 79; RED
	dw 8, 34, 79; RED
	dw 9, 34, 251
	dw 10, 34, 251
	dw 11, 34, 20 ; BLACK
	dw 12, 34, 20 ; BLACK
	dw 13, 34, 20 ; BLACK
	dw 14, 34, 20 ; BLACK
	dw 15, 34, 20 ; BLACK
	dw 16, 34, 20 ; BLACK
	dw 17, 34, 40; GRAY
	dw 18, 34, 40; GRAY
	dw 19, 34, 20 ; BLACK
	dw 20, 34, 20 ; BLACK
	dw 21, 34, 40; GRAY
	dw 22, 34, 40; GRAY
	dw 23, 34, 40; GRAY
	dw 24, 34, 40; GRAY
	dw 25, 34, 255
	dw 26, 34, 255
	dw 27, 34, 20 ; BLACK
	dw 28, 34, 20 ; BLACK
	dw 29, 34, 20 ; BLACK
	dw 30, 34, 20 ; BLACK
	dw 31, 34, 251
	dw 32, 34, 251
	dw 33, 34, 79; RED
	dw 34, 34, 79; RED
	dw 9, 35, 20 ; BLACK
	dw 10, 35, 20 ; BLACK
	dw 11, 35, 40; GRAY
	dw 12, 35, 40; GRAY
	dw 13, 35, 20 ; BLACK
	dw 14, 35, 20 ; BLACK
	dw 15, 35, 40; GRAY
	dw 16, 35, 40; GRAY
	dw 17, 35, 20 ; BLACK
	dw 18, 35, 20 ; BLACK
	dw 19, 35, 40; GRAY
	dw 20, 35, 40; GRAY
	dw 21, 35, 20 ; BLACK
	dw 22, 35, 20 ; BLACK
	dw 23, 35, 40; GRAY
	dw 24, 35, 40; GRAY
	dw 25, 35, 40; GRAY
	dw 26, 35, 40; GRAY
	dw 27, 35, 20 ; BLACK
	dw 28, 35, 20 ; BLACK
	dw 29, 35, 40; GRAY
	dw 30, 35, 40; GRAY
	dw 31, 35, 20 ; BLACK
	dw 32, 35, 20 ; BLACK
	dw 7, 36, 20 ; BLACK
	dw 8, 36, 20 ; BLACK
	dw 9, 36, 40; GRAY
	dw 10, 36, 40; GRAY
	dw 11, 36, 20 ; BLACK
	dw 12, 36, 20 ; BLACK
	dw 13, 36, 251
	dw 14, 36, 251
	dw 15, 36, 20 ; BLACK
	dw 16, 36, 20 ; BLACK
	dw 17, 36, 40; GRAY
	dw 18, 36, 40; GRAY
	dw 19, 36, 20 ; BLACK
	dw 20, 36, 20 ; BLACK
	dw 21, 36, 40; GRAY
	dw 22, 36, 40; GRAY
	dw 23, 36, 20 ; BLACK
	dw 24, 36, 20 ; BLACK
	dw 25, 36, 20 ; BLACK
	dw 26, 36, 20 ; BLACK
	dw 27, 36, 79; RED
	dw 28, 36, 79; RED
	dw 29, 36, 20 ; BLACK
	dw 30, 36, 20 ; BLACK
	dw 31, 36, 40; GRAY
	dw 32, 36, 40; GRAY
	dw 33, 36, 20 ; BLACK
	dw 34, 36, 20 ; BLACK
	dw 7, 37, 20 ; BLACK
	dw 8, 37, 20 ; BLACK
	dw 9, 37, 40; GRAY
	dw 10, 37, 40; GRAY
	dw 11, 37, 20 ; BLACK
	dw 12, 37, 20 ; BLACK
	dw 13, 37, 251
	dw 14, 37, 251
	dw 15, 37, 251
	dw 16, 37, 251
	dw 17, 37, 20 ; BLACK
	dw 18, 37, 20 ; BLACK
	dw 19, 37, 20 ; BLACK
	dw 20, 37, 20 ; BLACK
	dw 21, 37, 20 ; BLACK
	dw 22, 37, 20 ; BLACK
	dw 23, 37, 20 ; BLACK
	dw 24, 37, 20 ; BLACK
	dw 25, 37, 79; RED
	dw 26, 37, 79; RED
	dw 27, 37, 251
	dw 28, 37, 251
	dw 29, 37, 20 ; BLACK
	dw 30, 37, 20 ; BLACK
	dw 31, 37, 40; GRAY
	dw 32, 37, 40; GRAY
	dw 33, 37, 20 ; BLACK
	dw 34, 37, 20 ; BLACK
	dw 5, 38, 20 ; BLACK
	dw 6, 38, 20 ; BLACK
	dw 7, 38, 40; GRAY
	dw 8, 38, 40; GRAY
	dw 9, 38, 20 ; BLACK
	dw 10, 38, 20 ; BLACK
	dw 11, 38, 79; RED
	dw 12, 38, 79; RED
	dw 13, 38, 70; ORANGE
	dw 14, 38, 70; ORANGE
	dw 15, 38, 251
	dw 16, 38, 251
	dw 17, 38, 251
	dw 18, 38, 251
	dw 19, 38, 251
	dw 20, 38, 251
	dw 21, 38, 251
	dw 22, 38, 251
	dw 23, 38, 251
	dw 24, 38, 251
	dw 25, 38, 251
	dw 26, 38, 251
	dw 27, 38, 70; ORANGE
	dw 28, 38, 70; ORANGE
	dw 29, 38, 1
	dw 30, 38, 1
	dw 31, 38, 20 ; BLACK
	dw 32, 38, 20 ; BLACK
	dw 33, 38, 40; GRAY
	dw 34, 38, 40; GRAY
	dw 35, 38, 20 ; BLACK
	dw 36, 38, 20 ; BLACK
	dw 5, 39, 20 ; BLACK
	dw 6, 39, 20 ; BLACK
	dw 7, 39, 40; GRAY
	dw 8, 39, 40; GRAY
	dw 9, 39, 20 ; BLACK
	dw 10, 39, 20 ; BLACK
	dw 11, 39, 1
	dw 12, 39, 1
	dw 13, 39, 79; RED
	dw 14, 39, 79; RED
	dw 15, 39, 70; ORANGE
	dw 16, 39, 70; ORANGE
	dw 17, 39, 251
	dw 18, 39, 251
	dw 19, 39, 251
	dw 20, 39, 251
	dw 21, 39, 251
	dw 22, 39, 251
	dw 23, 39, 251
	dw 24, 39, 251
	dw 25, 39, 70; ORANGE
	dw 26, 39, 70; ORANGE
	dw 27, 39, 1
	dw 28, 39, 1
	dw 31, 39, 20 ; BLACK
	dw 32, 39, 20 ; BLACK
	dw 33, 39, 40; GRAY
	dw 34, 39, 40; GRAY
	dw 35, 39, 20 ; BLACK
	dw 36, 39, 20 ; BLACK
	dw 3, 40, 20 ; BLACK
	dw 4, 40, 20 ; BLACK
	dw 5, 40, 40; GRAY
	dw 6, 40, 40; GRAY
	dw 7, 40, 20 ; BLACK
	dw 8, 40, 20 ; BLACK
	dw 15, 40, 1
	dw 16, 40, 1
	dw 17, 40, 79; RED
	dw 18, 40, 79; RED
	dw 19, 40, 79; RED
	dw 20, 40, 79; RED
	dw 21, 40, 79; RED
	dw 22, 40, 79; RED
	dw 23, 40, 1
	dw 24, 40, 1
	dw 33, 40, 20 ; BLACK
	dw 34, 40, 20 ; BLACK
	dw 35, 40, 40; GRAY
	dw 36, 40, 40; GRAY
	dw 37, 40, 20 ; BLACK
	dw 38, 40, 20 ; BLACK
	dw 3, 41, 20 ; BLACK
	dw 4, 41, 20 ; BLACK
	dw 5, 41, 40; GRAY
	dw 6, 41, 40; GRAY
	dw 7, 41, 20 ; BLACK
	dw 8, 41, 20 ; BLACK
	dw 33, 41, 20 ; BLACK
	dw 34, 41, 20 ; BLACK
	dw 35, 41, 40; GRAY
	dw 36, 41, 40; GRAY
	dw 37, 41, 20 ; BLACK
	dw 38, 41, 20 ; BLACK
	dw 3, 42, 20 ; BLACK
	dw 4, 42, 20 ; BLACK
	dw 5, 42, 20 ; BLACK
	dw 6, 42, 20 ; BLACK
	dw 35, 42, 20 ; BLACK
	dw 36, 42, 20 ; BLACK
	dw 37, 42, 20 ; BLACK
	dw 38, 42, 20 ; BLACK
	dw 3, 43, 20 ; BLACK
	dw 4, 43, 20 ; BLACK
	dw 5, 43, 20 ; BLACK
	dw 6, 43, 20 ; BLACK
	dw 35, 43, 20 ; BLACK
	dw 36, 43, 20 ; BLACK
	dw 37, 43, 20 ; BLACK
	dw 38, 43, 20 ; BLACK
	dw 0, 0, 0

	; -------------------------------------------------------------------------
	; END
	; -------------------------------------------------------------------------
	
; -------------------------------------------------------------------------
; END
; -------------------------------------------------------------------------
	
	
; -------------------------------------------------------------------------
; BMP FILE ASSET DEFINITIONS
; -------------------------------------------------------------------------

; FileName1, FileLeft, FileRight, FileUp, FileDown: These strings define 
; the filenames for the player's aircraft BMPs in different orientations.
; The 0 at the end of each string is a null-terminator.
	FileName1   db  "FIGHTER.bmp" ,0
	FileLeft    db "F_L.bmp" ,0
	FileRight   db "F_R.bmp" ,0
	FileUp      db "F_U.bmp", 0
	FileDown    db "F_D.bmp", 0

; FileMainMenuShow, FileMainReady: Filenames for 
; the graphical user interface and loading screens.
	FileMainMenuShow        db "L_2.bmp" ,0 ; PRESS ANY KEY screen
	FileMainReady           db "LOADING.bmp" ,0 ; 1- PLAY, 3- EXIT screen.

; FileExplosionBmp and FileGameOverBmp: Assets used for endgame states.
; "Explo.bmp" is triggered upon player destruction (crashing to water or missile contact), 
; while "G_O.bmp" displays the final Game Over screen after the player is dead.
	FileExplosionBmp        db "Explo.bmp", 0
	FileGameOverBmp         db "G_O.bmp", 0

; Cutscene Images: Sequences for the "loading" and story 
; before the game starts. the BMPs are cycled (only once).
	FileLoadngPlay1Bmp      db "L1.bmp", 0
	FileLoadngPlay2Bmp      db "L2.bmp", 0
	FileLoadngPlay3Bmp      db "L3.bmp", 0

; Enemy Destruction Assets: Specifically sized explosion images 
; triggered when an enemy unit is successfully neutralized.
; "E_ES" transitions to "E_EB" which creates the exploding animation.
	Enemy_ExplosionSmall    db "E_ES.bmp", 0
	Enemy_ExplosionBig      db "E_EB.bmp", 0
	
	AircraftRunwayBmp db "RW.bmp", 0
	
	AltitudeBmp db "ALT.bmp", 0
	SpeedBmp db "SPD.bmp", 0

; -------------------------------------------------------------------------
; END
; -------------------------------------------------------------------------
	
	
; -------------------------------------------------------------------------
; BULLET COLLISION BOUNDARY COORDINATES
; -------------------------------------------------------------------------

; BulletScreenX1-X4 and BulletScreenY1-Y4: These words define the four 
; corners of the bounding box for the left bullet.
	BulletScreenX1 dw 0   ; left box - top left
	BulletScreenY1 dw 0
	BulletScreenX2 dw 0   ; left box - top right
	BulletScreenY2 dw 0
	BulletScreenX3 dw 0   ; left box - bottom left
	BulletScreenY3 dw 0
	BulletScreenX4 dw 0   ; left box - bottom right
	BulletScreenY4 dw 0

; BulletScreenX5-X8 and BulletScreenY5-Y8: These words define the four 
; corners of the bounding box for the right bullet.
	BulletScreenX5 dw 0   ; right box - top left
	BulletScreenY5 dw 0
	BulletScreenX6 dw 0   ; right box - top right
	BulletScreenY6 dw 0
	BulletScreenX7 dw 0   ; right box - bottom left
	BulletScreenY7 dw 0
	BulletScreenX8 dw 0   ; right box - bottom right
	BulletScreenY8 dw 0
	
	; They Are all updated in-loop.

; -------------------------------------------------------------------------
; END
; -------------------------------------------------------------------------

	cutScenePlayed db 0 ; a vraiable which indicates wether cutscene has already been played.
	
	
; -------------------------------------------------------------------------
; PLAYER PLANE STATE
; -------------------------------------------------------------------------
	
	PlaneState db 0    ; 0=default, 1=right, 2=left, 3=up, 4=down.
	
; -------------------------------------------------------------------------
; END
; -------------------------------------------------------------------------
	  
; -------------------------------------------------------------------------
; BMP FILE HANDLING AND BUFFER STORAGE
; -------------------------------------------------------------------------

; Header: A 54-byte buffer used to store the standard 256 bitmap BMP file header.
	Header 	    db 54 dup(0)

; Palette: A buffer of 1024 bytes (400h) used to store the color map.
; Each of the 256 colors in a VGA BMP uses 4 bytes (Red, Green, Blue, 
; Reserved), totaling 1024 bytes to define the image's color scheme.
	Palette 	db 400h dup (0)

; ScrLine: A temporary buffer used to read a single horizontal row of 
; pixels from the file. It is sized to SCREEN_WIDTH (320 bytes) 
; to match the horizontal resolution of the display mode.
	ScrLine 	db SCREEN_WIDTH dup (0)  ; One Color_1 line read buffer
	
; FileHandle: A word used to store the unique identifier assigned by 
; the OS after successfully opening a file.
	FileHandle	dw ?

; BmpFileErrorMsg: A string displayed if the program fails to locate 
; or open a requested BMP asset. '0dh, 0ah' represent a new line, 
; and '$' is the required terminator for DOS string output (INT 21h, AH=09h).
	BmpFileErrorMsg    db "Error At Opening Bmp File ", 0dh, 0ah,'$'

; FileError and FileFound: Status flags used by the file loading logic.
; 0 serves as the initial state; these are updated to 1 depending on 
; whether the  operation succeeded or failed during runtime.
	FileError db 0
	FileFound db 0
	
; Image: A dedicated memory buffer used to hold pixel information.
	Image db 40*40 dup(0)
	
; Variables for user to set before using OpenShowBmp.
	BmpLeft dw ?
	BmpTop dw ?
	BmpWidth dw ?
	BmpHeight dw ?
	
; -------------------------------------------------------------------------
; END
; -------------------------------------------------------------------------
	

	
		
	; the timer to count (using shl) wether cx (z cord) should grow.
	CxSizeTimer dw 1
	; a variable which is multiplied by 100 to give a cx (z cord) by time passed. 
	cxMODE dw 0
	; a flag which determins wether the bullet is active or not 
	BulletActive db 0
	
	; a counter to count how many iterations have passed since last missile was inbound 
	enemyShootOnPlayerCountdown dw 0
	; the time required to wait for a new missile to be inbound
	enemyShootOnPlayerCountdownLimit dw 120

	; an array of keys to recognize which key is pressed and move the info between different procs.
	keys db 128 dup (0)
	
	Xval dw ? 	; saving the distance the enemy should aspire to go to before disapering below horizon line.

	
; -------------------------------------------------------------------------
; GUN CROSSHAIR SPRTIE
; -------------------------------------------------------------------------
	
	GunsCrosshair dw 153, 93, 255
	dw 154, 93, 255
	dw 157, 93, 255
	dw 158, 93, 255
	dw 153, 94, 255
	dw 158, 94, 255
	dw 153, 97, 255
	dw 158, 97, 255
	dw 153, 98, 255
	dw 154, 98, 255
	dw 157, 98, 255
	dw 158, 98, 255
	dw 0, 0, 0
	
; -------------------------------------------------------------------------
; END
; -------------------------------------------------------------------------

; -------------------------------------------------------------------------
; ENEMY SIZE NORMAL SPRITE
; -------------------------------------------------------------------------
	; ==== ENEMY 1 ====
	EnemyNormal dw 16,  5, 152
    dw 33,  5, 152
    dw 16,  6, 152
    dw 33,  6, 152
    dw 16,  7, 152
    dw 17,  7, 152
    dw 32,  7, 152
    dw 33,  7, 152
    dw 17,  8, 152
    dw 24,  8, 152
    dw 25,  8, 152
    dw 32,  8, 152
    dw 17,  9, 152
    dw 23,  9, 152
    dw 24,  9, 255
    dw 25,  9, 255
    dw 26,  9, 152
    dw 32,  9, 152
    dw 15, 10, 6
    dw 16, 10, 1
    dw 17, 10, 152
    dw 18, 10, 152
    dw 19, 10, 1
    dw 23, 10, 152
    dw 24, 10, 152
    dw 25, 10, 152
    dw 26, 10, 152
    dw 30, 10, 1
    dw 31, 10, 152
    dw 32, 10, 152
    dw 33, 10, 1
    dw 34, 10, 6
    dw  9, 11, 79
    dw 10, 11, 79
    dw 11, 11, 79
    dw 12, 11, 39
    dw 13, 11, 39
    dw 14, 11, 39
    dw 15, 11, 39
    dw 16, 11, 1
    dw 17, 11, 152
    dw 18, 11, 1
    dw 19, 11, 152
    dw 20, 11, 79
    dw 21, 11, 152
    dw 22, 11, 79
    dw 23, 11, 152
    dw 24, 11, 79
    dw 25, 11, 79
    dw 26, 11, 152
    dw 27, 11, 79
    dw 28, 11, 152
    dw 29, 11, 79
    dw 30, 11, 152
    dw 31, 11, 1
    dw 32, 11, 152
    dw 33, 11, 1
    dw 34, 11, 39
    dw 35, 11, 39
    dw 36, 11, 39
    dw 37, 11, 39
    dw 38, 11, 79
    dw 39, 11, 79
    dw 40, 11, 79
    dw  5, 12, 79
    dw  6, 12, 79
    dw  7, 12, 79
    dw  8, 12, 39
    dw  9, 12, 39
    dw 10, 12, 39
    dw 11, 12, 39
    dw 12, 12, 39
    dw 13, 12, 1
    dw 14, 12, 1
    dw 15, 12, 1
    dw 16, 12, 1
    dw 17, 12, 152
    dw 18, 12, 79
    dw 19, 12, 79
    dw 20, 12, 79
    dw 21, 12, 1
    dw 22, 12, 79
    dw 23, 12, 152
    dw 24, 12, 27
    dw 25, 12, 79
    dw 26, 12, 152
    dw 27, 12, 79
    dw 28, 12, 1
    dw 29, 12, 79
    dw 30, 12, 79
    dw 31, 12, 79
    dw 32, 12, 152
    dw 33, 12, 1
    dw 34, 12, 1
    dw 35, 12, 1
    dw 36, 12, 1
    dw 37, 12, 39
    dw 38, 12, 39
    dw 39, 12, 39
    dw 40, 12, 39
    dw 41, 12, 39
    dw 42, 12, 79
    dw 43, 12, 79
    dw 44, 12, 79
    dw  1, 13, 79
    dw  2, 13, 79
    dw  3, 13, 79
    dw  4, 13, 39
    dw  5, 13, 39
    dw  6, 13, 39
    dw  7, 13, 39
    dw  8, 13, 39
    dw  9, 13, 39
    dw 10, 13, 1
    dw 11, 13, 1
    dw 12, 13, 1
    dw 13, 13, 1
    dw 14, 13, 1
    dw 15, 13, 152
    dw 16, 13, 1
    dw 17, 13, 152
    dw 18, 13, 1
    dw 19, 13, 79
    dw 20, 13, 79
    dw 21, 13, 79
    dw 22, 13, 79
    dw 23, 13, 1
    dw 24, 13, 79
    dw 25, 13, 79
    dw 26, 13, 1
    dw 27, 13, 79
    dw 28, 13, 79
    dw 29, 13, 79
    dw 30, 13, 79
    dw 31, 13, 152
    dw 32, 13, 152
    dw 33, 13, 1
    dw 34, 13, 152
    dw 35, 13, 1
    dw 36, 13, 1
    dw 37, 13, 1
    dw 38, 13, 1
    dw 39, 13, 1
    dw 40, 13, 39
    dw 41, 13, 39
    dw 42, 13, 39
    dw 43, 13, 39
    dw 44, 13, 39
    dw 45, 13, 39
    dw 46, 13, 79
    dw 47, 13, 79
    dw 48, 13, 79
    dw 12, 14, 1
    dw 13, 14, 39
    dw 14, 14, 152
    dw 15, 14, 152
    dw 16, 14, 152
    dw 17, 14, 152
    dw 18, 14, 152
    dw 19, 14, 152
    dw 20, 14, 1
    dw 21, 14, 152
    dw 22, 14, 79
    dw 23, 14, 79
    dw 24, 14, 79
    dw 25, 14, 79
    dw 26, 14, 79
    dw 27, 14, 79
    dw 28, 14, 152
    dw 29, 14, 1
    dw 30, 14, 152
    dw 31, 14, 152
    dw 32, 14, 152
    dw 33, 14, 152
    dw 34, 14, 152
    dw 35, 14, 152
    dw 36, 14, 39
    dw 37, 14, 1
    dw  9, 15, 39
    dw 10, 15, 39
    dw 11, 15, 39
    dw 12, 15, 39
    dw 13, 15, 39
    dw 14, 15, 152
    dw 15, 15, 79
    dw 16, 15, 255
    dw 17, 15, 251
    dw 18, 15, 152
    dw 19, 15, 152
    dw 20, 15, 1
    dw 21, 15, 79
    dw 22, 15, 79
    dw 23, 15, 1
    dw 24, 15, 152
    dw 25, 15, 152
    dw 26, 15, 1
    dw 27, 15, 79
    dw 28, 15, 79
    dw 29, 15, 1
    dw 30, 15, 152
    dw 31, 15, 152
    dw 32, 15, 255
    dw 33, 15, 255
    dw 34, 15, 79
    dw 35, 15, 152
    dw 36, 15, 39
    dw 37, 15, 39
    dw 38, 15, 39
    dw 39, 15, 39
    dw 40, 15, 39
    dw  6, 16, 29
    dw  7, 16, 39
    dw  8, 16, 39
    dw  9, 16, 79
    dw 10, 16, 39
    dw 11, 16, 1
    dw 12, 16, 1
    dw 13, 16, 152
    dw 14, 16, 152
    dw 15, 16, 79
    dw 16, 16, 255
    dw 17, 16, 255
    dw 18, 16, 152
    dw 19, 16, 152
    dw 20, 16, 1
    dw 21, 16, 1
    dw 22, 16, 79
    dw 23, 16, 79
    dw 24, 16, 79
    dw 25, 16, 79
    dw 26, 16, 79
    dw 27, 16, 79
    dw 28, 16, 1
    dw 29, 16, 1
    dw 30, 16, 152
    dw 31, 16, 152
    dw 32, 16, 251
    dw 33, 16, 255
    dw 34, 16, 79
    dw 35, 16, 152
    dw 36, 16, 152
    dw 37, 16, 1
    dw 38, 16, 1
    dw 39, 16, 39
    dw 40, 16, 79
    dw 41, 16, 39
    dw 42, 16, 39
    dw 43, 16, 79
    dw 14, 17, 152
    dw 15, 17, 152
    dw 16, 17, 251
    dw 17, 17, 152
    dw 18, 17, 152
    dw 19, 17, 152
    dw 20, 17, 1
    dw 22, 17, 1
    dw 23, 17, 152
    dw 24, 17, 152
    dw 25, 17, 152
    dw 26, 17, 152
    dw 27, 17, 1
    dw 29, 17, 1
    dw 30, 17, 152
    dw 31, 17, 152
    dw 32, 17, 152
    dw 33, 17, 251
    dw 34, 17, 152
    dw 35, 17, 152
    dw 15, 18, 152
    dw 16, 18, 152
    dw 17, 18, 152
    dw 18, 18, 152
    dw 19, 18, 79
    dw 30, 18, 79
    dw 31, 18, 152
    dw 32, 18, 152
    dw 33, 18, 152
    dw 34, 18, 152
    dw 16, 19, 1
    dw 17, 19, 79
    dw 32, 19, 79
    dw 33, 19, 1
	dw 0, 0, 0

; -------------------------------------------------------------------------
; END 
; -------------------------------------------------------------------------

; -------------------------------------------------------------------------
; ENEMY SIZE NORMAL FIXED ARRAY TO RESTORE COORDS TO RESPAWN ENEMY 
; -------------------------------------------------------------------------
	EnemyNormalFixed dw 16,  5, 152
    dw 33,  5, 152
    dw 16,  6, 152
    dw 33,  6, 152
    dw 16,  7, 152
    dw 17,  7, 152
    dw 32,  7, 152
    dw 33,  7, 152
    dw 17,  8, 152
    dw 24,  8, 152
    dw 25,  8, 152
    dw 32,  8, 152
    dw 17,  9, 152
    dw 23,  9, 152
    dw 24,  9, 255
    dw 25,  9, 255
    dw 26,  9, 152
    dw 32,  9, 152
    dw 15, 10, 6
    dw 16, 10, 1
    dw 17, 10, 152
    dw 18, 10, 152
    dw 19, 10, 1
    dw 23, 10, 152
    dw 24, 10, 152
    dw 25, 10, 152
    dw 26, 10, 152
    dw 30, 10, 1
    dw 31, 10, 152
    dw 32, 10, 152
    dw 33, 10, 1
    dw 34, 10, 6
    dw  9, 11, 79
    dw 10, 11, 79
    dw 11, 11, 79
    dw 12, 11, 39
    dw 13, 11, 39
    dw 14, 11, 39
    dw 15, 11, 39
    dw 16, 11, 1
    dw 17, 11, 152
    dw 18, 11, 1
    dw 19, 11, 152
    dw 20, 11, 79
    dw 21, 11, 152
    dw 22, 11, 79
    dw 23, 11, 152
    dw 24, 11, 79
    dw 25, 11, 79
    dw 26, 11, 152
    dw 27, 11, 79
    dw 28, 11, 152
    dw 29, 11, 79
    dw 30, 11, 152
    dw 31, 11, 1
    dw 32, 11, 152
    dw 33, 11, 1
    dw 34, 11, 39
    dw 35, 11, 39
    dw 36, 11, 39
    dw 37, 11, 39
    dw 38, 11, 79
    dw 39, 11, 79
    dw 40, 11, 79
    dw  5, 12, 79
    dw  6, 12, 79
    dw  7, 12, 79
    dw  8, 12, 39
    dw  9, 12, 39
    dw 10, 12, 39
    dw 11, 12, 39
    dw 12, 12, 39
    dw 13, 12, 1
    dw 14, 12, 1
    dw 15, 12, 1
    dw 16, 12, 1
    dw 17, 12, 152
    dw 18, 12, 79
    dw 19, 12, 79
    dw 20, 12, 79
    dw 21, 12, 1
    dw 22, 12, 79
    dw 23, 12, 152
    dw 24, 12, 27
    dw 25, 12, 79
    dw 26, 12, 152
    dw 27, 12, 79
    dw 28, 12, 1
    dw 29, 12, 79
    dw 30, 12, 79
    dw 31, 12, 79
    dw 32, 12, 152
    dw 33, 12, 1
    dw 34, 12, 1
    dw 35, 12, 1
    dw 36, 12, 1
    dw 37, 12, 39
    dw 38, 12, 39
    dw 39, 12, 39
    dw 40, 12, 39
    dw 41, 12, 39
    dw 42, 12, 79
    dw 43, 12, 79
    dw 44, 12, 79
    dw  1, 13, 79
    dw  2, 13, 79
    dw  3, 13, 79
    dw  4, 13, 39
    dw  5, 13, 39
    dw  6, 13, 39
    dw  7, 13, 39
    dw  8, 13, 39
    dw  9, 13, 39
    dw 10, 13, 1
    dw 11, 13, 1
    dw 12, 13, 1
    dw 13, 13, 1
    dw 14, 13, 1
    dw 15, 13, 152
    dw 16, 13, 1
    dw 17, 13, 152
    dw 18, 13, 1
    dw 19, 13, 79
    dw 20, 13, 79
    dw 21, 13, 79
    dw 22, 13, 79
    dw 23, 13, 1
    dw 24, 13, 79
    dw 25, 13, 79
    dw 26, 13, 1
    dw 27, 13, 79
    dw 28, 13, 79
    dw 29, 13, 79
    dw 30, 13, 79
    dw 31, 13, 152
    dw 32, 13, 152
    dw 33, 13, 1
    dw 34, 13, 152
    dw 35, 13, 1
    dw 36, 13, 1
    dw 37, 13, 1
    dw 38, 13, 1
    dw 39, 13, 1
    dw 40, 13, 39
    dw 41, 13, 39
    dw 42, 13, 39
    dw 43, 13, 39
    dw 44, 13, 39
    dw 45, 13, 39
    dw 46, 13, 79
    dw 47, 13, 79
    dw 48, 13, 79
    dw 12, 14, 1
    dw 13, 14, 39
    dw 14, 14, 152
    dw 15, 14, 152
    dw 16, 14, 152
    dw 17, 14, 152
    dw 18, 14, 152
    dw 19, 14, 152
    dw 20, 14, 1
    dw 21, 14, 152
    dw 22, 14, 79
    dw 23, 14, 79
    dw 24, 14, 79
    dw 25, 14, 79
    dw 26, 14, 79
    dw 27, 14, 79
    dw 28, 14, 152
    dw 29, 14, 1
    dw 30, 14, 152
    dw 31, 14, 152
    dw 32, 14, 152
    dw 33, 14, 152
    dw 34, 14, 152
    dw 35, 14, 152
    dw 36, 14, 39
    dw 37, 14, 1
    dw  9, 15, 39
    dw 10, 15, 39
    dw 11, 15, 39
    dw 12, 15, 39
    dw 13, 15, 39
    dw 14, 15, 152
    dw 15, 15, 79
    dw 16, 15, 255
    dw 17, 15, 251
    dw 18, 15, 152
    dw 19, 15, 152
    dw 20, 15, 1
    dw 21, 15, 79
    dw 22, 15, 79
    dw 23, 15, 1
    dw 24, 15, 152
    dw 25, 15, 152
    dw 26, 15, 1
    dw 27, 15, 79
    dw 28, 15, 79
    dw 29, 15, 1
    dw 30, 15, 152
    dw 31, 15, 152
    dw 32, 15, 255
    dw 33, 15, 255
    dw 34, 15, 79
    dw 35, 15, 152
    dw 36, 15, 39
    dw 37, 15, 39
    dw 38, 15, 39
    dw 39, 15, 39
    dw 40, 15, 39
    dw  6, 16, 29
    dw  7, 16, 39
    dw  8, 16, 39
    dw  9, 16, 79
    dw 10, 16, 39
    dw 11, 16, 1
    dw 12, 16, 1
    dw 13, 16, 152
    dw 14, 16, 152
    dw 15, 16, 79
    dw 16, 16, 255
    dw 17, 16, 255
    dw 18, 16, 152
    dw 19, 16, 152
    dw 20, 16, 1
    dw 21, 16, 1
    dw 22, 16, 79
    dw 23, 16, 79
    dw 24, 16, 79
    dw 25, 16, 79
    dw 26, 16, 79
    dw 27, 16, 79
    dw 28, 16, 1
    dw 29, 16, 1
    dw 30, 16, 152
    dw 31, 16, 152
    dw 32, 16, 251
    dw 33, 16, 255
    dw 34, 16, 79
    dw 35, 16, 152
    dw 36, 16, 152
    dw 37, 16, 1
    dw 38, 16, 1
    dw 39, 16, 39
    dw 40, 16, 79
    dw 41, 16, 39
    dw 42, 16, 39
    dw 43, 16, 79
    dw 14, 17, 152
    dw 15, 17, 152
    dw 16, 17, 251
    dw 17, 17, 152
    dw 18, 17, 152
    dw 19, 17, 152
    dw 20, 17, 1
    dw 22, 17, 1
    dw 23, 17, 152
    dw 24, 17, 152
    dw 25, 17, 152
    dw 26, 17, 152
    dw 27, 17, 1
    dw 29, 17, 1
    dw 30, 17, 152
    dw 31, 17, 152
    dw 32, 17, 152
    dw 33, 17, 251
    dw 34, 17, 152
    dw 35, 17, 152
    dw 15, 18, 152
    dw 16, 18, 152
    dw 17, 18, 152
    dw 18, 18, 152
    dw 19, 18, 79
    dw 30, 18, 79
    dw 31, 18, 152
    dw 32, 18, 152
    dw 33, 18, 152
    dw 34, 18, 152
    dw 16, 19, 1
    dw 17, 19, 79
    dw 32, 19, 79
    dw 33, 19, 1
	dw 0, 0, 0
; -------------------------------------------------------------------------
; END
; -------------------------------------------------------------------------
	
; -------------------------------------------------------------------------
; ENEMY NORMAL SIZE SPRITE
; -------------------------------------------------------------------------
	EnemyClose dw 9, 0, 152
dw 22, 0, 152
dw 9, 1, 152
dw 15, 1, 152
dw 16, 1, 152
dw 22, 1, 152
dw 9, 2, 152
dw 10, 2, 1
dw 15, 2, 152
dw 16, 2, 152
dw 21, 2, 1
dw 22, 2, 152
dw 9, 3, 1
dw 10, 3, 152
dw 13, 3, 1
dw 14, 3, 1
dw 15, 3, 29
dw 16, 3, 29
dw 17, 3, 1
dw 18, 3, 1
dw 21, 3, 152
dw 22, 3, 1
dw 8, 4, 1
dw 9, 4, 1
dw 10, 4, 152
dw 11, 4, 1
dw 12, 4, 29
dw 13, 4, 29
dw 14, 4, 152
dw 15, 4, 29
dw 16, 4, 29
dw 17, 4, 152
dw 18, 4, 29
dw 19, 4, 29
dw 20, 4, 1
dw 21, 4, 152
dw 22, 4, 1
dw 23, 4, 1
dw 4, 5, 1
dw 5, 5, 39
dw 6, 5, 39
dw 7, 5, 39
dw 8, 5, 39
dw 9, 5, 1
dw 10, 5, 152
dw 11, 5, 1
dw 12, 5, 29
dw 13, 5, 29
dw 14, 5, 1
dw 15, 5, 29
dw 16, 5, 29
dw 17, 5, 1
dw 18, 5, 29
dw 19, 5, 29
dw 20, 5, 1
dw 21, 5, 152
dw 22, 5, 1
dw 23, 5, 39
dw 24, 5, 39
dw 25, 5, 39
dw 26, 5, 39
dw 27, 5, 1
dw 0, 6, 29
dw 1, 6, 39
dw 2, 6, 39
dw 3, 6, 39
dw 4, 6, 1
dw 5, 6, 1
dw 6, 6, 1
dw 7, 6, 1
dw 8, 6, 1
dw 9, 6, 39
dw 10, 6, 152
dw 11, 6, 152
dw 12, 6, 152
dw 13, 6, 1
dw 14, 6, 29
dw 15, 6, 1
dw 16, 6, 1
dw 17, 6, 29
dw 18, 6, 1
dw 19, 6, 152
dw 20, 6, 152
dw 21, 6, 152
dw 22, 6, 39
dw 23, 6, 1
dw 24, 6, 1
dw 25, 6, 1
dw 26, 6, 1
dw 27, 6, 1
dw 28, 6, 39
dw 29, 6, 39
dw 30, 6, 39
dw 31, 6, 29
dw 7, 7, 1
dw 8, 7, 1
dw 9, 7, 152
dw 10, 7, 29
dw 11, 7, 255
dw 12, 7, 152
dw 13, 7, 1
dw 14, 7, 1
dw 15, 7, 29
dw 16, 7, 29
dw 17, 7, 1
dw 18, 7, 1
dw 19, 7, 152
dw 20, 7, 255
dw 21, 7, 29
dw 22, 7, 152
dw 23, 7, 1
dw 24, 7, 1
dw 4, 8, 29
dw 5, 8, 39
dw 6, 8, 39
dw 7, 8, 39
dw 8, 8, 1
dw 9, 8, 152
dw 10, 8, 29
dw 11, 8, 29
dw 12, 8, 152
dw 14, 8, 1
dw 15, 8, 1
dw 16, 8, 1
dw 17, 8, 1
dw 19, 8, 152
dw 20, 8, 29
dw 21, 8, 29
dw 22, 8, 152
dw 23, 8, 1
dw 24, 8, 39
dw 25, 8, 39
dw 26, 8, 39
dw 27, 8, 29
dw 10, 9, 152
dw 11, 9, 152
dw 20, 9, 152
dw 21, 9, 152
dw 0, 0, 0 

; -------------------------------------------------------------------------
; END
; -------------------------------------------------------------------------


; -------------------------------------------------------------------------
; ENEMY MIDDLE SIZE SPRITE
; -------------------------------------------------------------------------
	EnemyMiddle dw 7, 0, 1
dw 16, 0, 1
dw 7, 1, 152
dw 16, 1, 152
dw 7, 2, 152
dw 12, 2, 152
dw 16, 2, 152
dw 7, 3, 1
dw 8, 3, 152
dw 11, 3, 29
dw 12, 3, 29
dw 15, 3, 152
dw 16, 3, 1
dw 4, 4, 29
dw 5, 4, 39
dw 6, 4, 39
dw 7, 4, 1
dw 8, 4, 152
dw 9, 4, 1
dw 10, 4, 29
dw 11, 4, 1
dw 12, 4, 1
dw 13, 4, 29
dw 14, 4, 1
dw 15, 4, 152
dw 16, 4, 1
dw 17, 4, 39
dw 18, 4, 39
dw 19, 4, 29
dw 0, 5, 29
dw 1, 5, 39
dw 2, 5, 39
dw 3, 5, 39
dw 4, 5, 39
dw 5, 5, 1
dw 6, 5, 1
dw 7, 5, 1
dw 8, 5, 152
dw 9, 5, 29
dw 10, 5, 29
dw 11, 5, 1
dw 12, 5, 29
dw 13, 5, 29
dw 14, 5, 29
dw 15, 5, 152
dw 16, 5, 1
dw 17, 5, 1
dw 18, 5, 1
dw 19, 5, 39
dw 20, 5, 39
dw 21, 5, 39
dw 22, 5, 39
dw 23, 5, 29
dw 4, 6, 29
dw 5, 6, 39
dw 6, 6, 39
dw 7, 6, 152
dw 8, 6, 29
dw 9, 6, 152
dw 10, 6, 1
dw 11, 6, 29
dw 12, 6, 29
dw 13, 6, 1
dw 14, 6, 152
dw 15, 6, 29
dw 16, 6, 152
dw 17, 6, 39
dw 18, 6, 39
dw 19, 6, 29
dw 8, 7, 152
dw 9, 7, 1
dw 11, 7, 1
dw 12, 7, 1
dw 14, 7, 1
dw 15, 7, 152
dw 0, 0, 0

; -------------------------------------------------------------------------
; END 
; -------------------------------------------------------------------------

; -------------------------------------------------------------------------
; ENEMY FAR (SMALL) SIZED SPRITE
; -------------------------------------------------------------------------

	EnemyFar dw 4, 0, 1
dw 11, 0, 1
dw 4, 1, 152
dw 7, 1, 152
dw 8, 1, 152
dw 11, 1, 152
dw 4, 2, 152
dw 5, 2, 1
dw 7, 2, 29
dw 8, 2, 29
dw 10, 2, 1
dw 11, 2, 152
dw 0, 3, 29
dw 1, 3, 39
dw 2, 3, 39
dw 3, 3, 39
dw 4, 3, 152
dw 5, 3, 152
dw 6, 3, 29
dw 7, 3, 1
dw 8, 3, 1
dw 9, 3, 29
dw 10, 3, 152
dw 11, 3, 152
dw 12, 3, 39
dw 13, 3, 39
dw 14, 3, 39
dw 15, 3, 29
dw 2, 4, 39
dw 3, 4, 152
dw 4, 4, 1
dw 5, 4, 152
dw 6, 4, 1
dw 7, 4, 29
dw 8, 4, 29
dw 9, 4, 1
dw 10, 4, 152
dw 11, 4, 1
dw 12, 4, 152
dw 13, 4, 39
dw 4, 5, 152
dw 5, 5, 152
dw 10, 5, 152
dw 11, 5, 152
dw 0, 0, 0

; -------------------------------------------------------------------------
; END 
; -------------------------------------------------------------------------

; SAME EXACT FOR FOLLWING SPRITES:

; ===== ENEMY 2 =====
Enemy2Active db 0 ; a flag to mark if enemy is currently active on screen
Enemy2DelayTimer dw 0 ; the time enemy 2 needs t owait before reseting and summoning new enemy   

Enemy2Normal dw 16,  5, 152
    dw 33,  5, 152
    dw 16,  6, 152
    dw 33,  6, 152
    dw 16,  7, 152
    dw 17,  7, 152
    dw 32,  7, 152
    dw 33,  7, 152
    dw 17,  8, 152
    dw 24,  8, 152
    dw 25,  8, 152
    dw 32,  8, 152
    dw 17,  9, 152
    dw 23,  9, 152
    dw 24,  9, 255
    dw 25,  9, 255
    dw 26,  9, 152
    dw 32,  9, 152
    dw 15, 10, 6
    dw 16, 10, 1
    dw 17, 10, 152
    dw 18, 10, 152
    dw 19, 10, 1
    dw 23, 10, 152
    dw 24, 10, 152
    dw 25, 10, 152
    dw 26, 10, 152
    dw 30, 10, 1
    dw 31, 10, 152
    dw 32, 10, 152
    dw 33, 10, 1
    dw 34, 10, 6
    dw  9, 11, 79
    dw 10, 11, 79
    dw 11, 11, 79
    dw 12, 11, 39
    dw 13, 11, 39
    dw 14, 11, 39
    dw 15, 11, 39
    dw 16, 11, 1
    dw 17, 11, 152
    dw 18, 11, 1
    dw 19, 11, 152
    dw 20, 11, 79
    dw 21, 11, 152
    dw 22, 11, 79
    dw 23, 11, 152
    dw 24, 11, 79
    dw 25, 11, 79
    dw 26, 11, 152
    dw 27, 11, 79
    dw 28, 11, 152
    dw 29, 11, 79
    dw 30, 11, 152
    dw 31, 11, 1
    dw 32, 11, 152
    dw 33, 11, 1
    dw 34, 11, 39
    dw 35, 11, 39
    dw 36, 11, 39
    dw 37, 11, 39
    dw 38, 11, 79
    dw 39, 11, 79
    dw 40, 11, 79
    dw  5, 12, 79
    dw  6, 12, 79
    dw  7, 12, 79
    dw  8, 12, 39
    dw  9, 12, 39
    dw 10, 12, 39
    dw 11, 12, 39
    dw 12, 12, 39
    dw 13, 12, 1
    dw 14, 12, 1
    dw 15, 12, 1
    dw 16, 12, 1
    dw 17, 12, 152
    dw 18, 12, 79
    dw 19, 12, 79
    dw 20, 12, 79
    dw 21, 12, 1
    dw 22, 12, 79
    dw 23, 12, 152
    dw 24, 12, 27
    dw 25, 12, 79
    dw 26, 12, 152
    dw 27, 12, 79
    dw 28, 12, 1
    dw 29, 12, 79
    dw 30, 12, 79
    dw 31, 12, 79
    dw 32, 12, 152
    dw 33, 12, 1
    dw 34, 12, 1
    dw 35, 12, 1
    dw 36, 12, 1
    dw 37, 12, 39
    dw 38, 12, 39
    dw 39, 12, 39
    dw 40, 12, 39
    dw 41, 12, 39
    dw 42, 12, 79
    dw 43, 12, 79
    dw 44, 12, 79
    dw  1, 13, 79
    dw  2, 13, 79
    dw  3, 13, 79
    dw  4, 13, 39
    dw  5, 13, 39
    dw  6, 13, 39
    dw  7, 13, 39
    dw  8, 13, 39
    dw  9, 13, 39
    dw 10, 13, 1
    dw 11, 13, 1
    dw 12, 13, 1
    dw 13, 13, 1
    dw 14, 13, 1
    dw 15, 13, 152
    dw 16, 13, 1
    dw 17, 13, 152
    dw 18, 13, 1
    dw 19, 13, 79
    dw 20, 13, 79
    dw 21, 13, 79
    dw 22, 13, 79
    dw 23, 13, 1
    dw 24, 13, 79
    dw 25, 13, 79
    dw 26, 13, 1
    dw 27, 13, 79
    dw 28, 13, 79
    dw 29, 13, 79
    dw 30, 13, 79
    dw 31, 13, 152
    dw 32, 13, 152
    dw 33, 13, 1
    dw 34, 13, 152
    dw 35, 13, 1
    dw 36, 13, 1
    dw 37, 13, 1
    dw 38, 13, 1
    dw 39, 13, 1
    dw 40, 13, 39
    dw 41, 13, 39
    dw 42, 13, 39
    dw 43, 13, 39
    dw 44, 13, 39
    dw 45, 13, 39
    dw 46, 13, 79
    dw 47, 13, 79
    dw 48, 13, 79
    dw 12, 14, 1
    dw 13, 14, 39
    dw 14, 14, 152
    dw 15, 14, 152
    dw 16, 14, 152
    dw 17, 14, 152
    dw 18, 14, 152
    dw 19, 14, 152
    dw 20, 14, 1
    dw 21, 14, 152
    dw 22, 14, 79
    dw 23, 14, 79
    dw 24, 14, 79
    dw 25, 14, 79
    dw 26, 14, 79
    dw 27, 14, 79
    dw 28, 14, 152
    dw 29, 14, 1
    dw 30, 14, 152
    dw 31, 14, 152
    dw 32, 14, 152
    dw 33, 14, 152
    dw 34, 14, 152
    dw 35, 14, 152
    dw 36, 14, 39
    dw 37, 14, 1
    dw  9, 15, 39
    dw 10, 15, 39
    dw 11, 15, 39
    dw 12, 15, 39
    dw 13, 15, 39
    dw 14, 15, 152
    dw 15, 15, 79
    dw 16, 15, 255
    dw 17, 15, 251
    dw 18, 15, 152
    dw 19, 15, 152
    dw 20, 15, 1
    dw 21, 15, 79
    dw 22, 15, 79
    dw 23, 15, 1
    dw 24, 15, 152
    dw 25, 15, 152
    dw 26, 15, 1
    dw 27, 15, 79
    dw 28, 15, 79
    dw 29, 15, 1
    dw 30, 15, 152
    dw 31, 15, 152
    dw 32, 15, 255
    dw 33, 15, 255
    dw 34, 15, 79
    dw 35, 15, 152
    dw 36, 15, 39
    dw 37, 15, 39
    dw 38, 15, 39
    dw 39, 15, 39
    dw 40, 15, 39
    dw  6, 16, 29
    dw  7, 16, 39
    dw  8, 16, 39
    dw  9, 16, 79
    dw 10, 16, 39
    dw 11, 16, 1
    dw 12, 16, 1
    dw 13, 16, 152
    dw 14, 16, 152
    dw 15, 16, 79
    dw 16, 16, 255
    dw 17, 16, 255
    dw 18, 16, 152
    dw 19, 16, 152
    dw 20, 16, 1
    dw 21, 16, 1
    dw 22, 16, 79
    dw 23, 16, 79
    dw 24, 16, 79
    dw 25, 16, 79
    dw 26, 16, 79
    dw 27, 16, 79
    dw 28, 16, 1
    dw 29, 16, 1
    dw 30, 16, 152
    dw 31, 16, 152
    dw 32, 16, 251
    dw 33, 16, 255
    dw 34, 16, 79
    dw 35, 16, 152
    dw 36, 16, 152
    dw 37, 16, 1
    dw 38, 16, 1
    dw 39, 16, 39
    dw 40, 16, 79
    dw 41, 16, 39
    dw 42, 16, 39
    dw 43, 16, 79
    dw 14, 17, 152
    dw 15, 17, 152
    dw 16, 17, 251
    dw 17, 17, 152
    dw 18, 17, 152
    dw 19, 17, 152
    dw 20, 17, 1
    dw 22, 17, 1
    dw 23, 17, 152
    dw 24, 17, 152
    dw 25, 17, 152
    dw 26, 17, 152
    dw 27, 17, 1
    dw 29, 17, 1
    dw 30, 17, 152
    dw 31, 17, 152
    dw 32, 17, 152
    dw 33, 17, 251
    dw 34, 17, 152
    dw 35, 17, 152
    dw 15, 18, 152
    dw 16, 18, 152
    dw 17, 18, 152
    dw 18, 18, 152
    dw 19, 18, 79
    dw 30, 18, 79
    dw 31, 18, 152
    dw 32, 18, 152
    dw 33, 18, 152
    dw 34, 18, 152
    dw 16, 19, 1
    dw 17, 19, 79
    dw 32, 19, 79
    dw 33, 19, 1
	dw 0, 0, 0

Enemy2NormalFixed dw 16,  5, 152
    dw 33,  5, 152
    dw 16,  6, 152
    dw 33,  6, 152
    dw 16,  7, 152
    dw 17,  7, 152
    dw 32,  7, 152
    dw 33,  7, 152
    dw 17,  8, 152
    dw 24,  8, 152
    dw 25,  8, 152
    dw 32,  8, 152
    dw 17,  9, 152
    dw 23,  9, 152
    dw 24,  9, 255
    dw 25,  9, 255
    dw 26,  9, 152
    dw 32,  9, 152
    dw 15, 10, 6
    dw 16, 10, 1
    dw 17, 10, 152
    dw 18, 10, 152
    dw 19, 10, 1
    dw 23, 10, 152
    dw 24, 10, 152
    dw 25, 10, 152
    dw 26, 10, 152
    dw 30, 10, 1
    dw 31, 10, 152
    dw 32, 10, 152
    dw 33, 10, 1
    dw 34, 10, 6
    dw  9, 11, 79
    dw 10, 11, 79
    dw 11, 11, 79
    dw 12, 11, 39
    dw 13, 11, 39
    dw 14, 11, 39
    dw 15, 11, 39
    dw 16, 11, 1
    dw 17, 11, 152
    dw 18, 11, 1
    dw 19, 11, 152
    dw 20, 11, 79
    dw 21, 11, 152
    dw 22, 11, 79
    dw 23, 11, 152
    dw 24, 11, 79
    dw 25, 11, 79
    dw 26, 11, 152
    dw 27, 11, 79
    dw 28, 11, 152
    dw 29, 11, 79
    dw 30, 11, 152
    dw 31, 11, 1
    dw 32, 11, 152
    dw 33, 11, 1
    dw 34, 11, 39
    dw 35, 11, 39
    dw 36, 11, 39
    dw 37, 11, 39
    dw 38, 11, 79
    dw 39, 11, 79
    dw 40, 11, 79
    dw  5, 12, 79
    dw  6, 12, 79
    dw  7, 12, 79
    dw  8, 12, 39
    dw  9, 12, 39
    dw 10, 12, 39
    dw 11, 12, 39
    dw 12, 12, 39
    dw 13, 12, 1
    dw 14, 12, 1
    dw 15, 12, 1
    dw 16, 12, 1
    dw 17, 12, 152
    dw 18, 12, 79
    dw 19, 12, 79
    dw 20, 12, 79
    dw 21, 12, 1
    dw 22, 12, 79
    dw 23, 12, 152
    dw 24, 12, 27
    dw 25, 12, 79
    dw 26, 12, 152
    dw 27, 12, 79
    dw 28, 12, 1
    dw 29, 12, 79
    dw 30, 12, 79
    dw 31, 12, 79
    dw 32, 12, 152
    dw 33, 12, 1
    dw 34, 12, 1
    dw 35, 12, 1
    dw 36, 12, 1
    dw 37, 12, 39
    dw 38, 12, 39
    dw 39, 12, 39
    dw 40, 12, 39
    dw 41, 12, 39
    dw 42, 12, 79
    dw 43, 12, 79
    dw 44, 12, 79
    dw  1, 13, 79
    dw  2, 13, 79
    dw  3, 13, 79
    dw  4, 13, 39
    dw  5, 13, 39
    dw  6, 13, 39
    dw  7, 13, 39
    dw  8, 13, 39
    dw  9, 13, 39
    dw 10, 13, 1
    dw 11, 13, 1
    dw 12, 13, 1
    dw 13, 13, 1
    dw 14, 13, 1
    dw 15, 13, 152
    dw 16, 13, 1
    dw 17, 13, 152
    dw 18, 13, 1
    dw 19, 13, 79
    dw 20, 13, 79
    dw 21, 13, 79
    dw 22, 13, 79
    dw 23, 13, 1
    dw 24, 13, 79
    dw 25, 13, 79
    dw 26, 13, 1
    dw 27, 13, 79
    dw 28, 13, 79
    dw 29, 13, 79
    dw 30, 13, 79
    dw 31, 13, 152
    dw 32, 13, 152
    dw 33, 13, 1
    dw 34, 13, 152
    dw 35, 13, 1
    dw 36, 13, 1
    dw 37, 13, 1
    dw 38, 13, 1
    dw 39, 13, 1
    dw 40, 13, 39
    dw 41, 13, 39
    dw 42, 13, 39
    dw 43, 13, 39
    dw 44, 13, 39
    dw 45, 13, 39
    dw 46, 13, 79
    dw 47, 13, 79
    dw 48, 13, 79
    dw 12, 14, 1
    dw 13, 14, 39
    dw 14, 14, 152
    dw 15, 14, 152
    dw 16, 14, 152
    dw 17, 14, 152
    dw 18, 14, 152
    dw 19, 14, 152
    dw 20, 14, 1
    dw 21, 14, 152
    dw 22, 14, 79
    dw 23, 14, 79
    dw 24, 14, 79
    dw 25, 14, 79
    dw 26, 14, 79
    dw 27, 14, 79
    dw 28, 14, 152
    dw 29, 14, 1
    dw 30, 14, 152
    dw 31, 14, 152
    dw 32, 14, 152
    dw 33, 14, 152
    dw 34, 14, 152
    dw 35, 14, 152
    dw 36, 14, 39
    dw 37, 14, 1
    dw  9, 15, 39
    dw 10, 15, 39
    dw 11, 15, 39
    dw 12, 15, 39
    dw 13, 15, 39
    dw 14, 15, 152
    dw 15, 15, 79
    dw 16, 15, 255
    dw 17, 15, 251
    dw 18, 15, 152
    dw 19, 15, 152
    dw 20, 15, 1
    dw 21, 15, 79
    dw 22, 15, 79
    dw 23, 15, 1
    dw 24, 15, 152
    dw 25, 15, 152
    dw 26, 15, 1
    dw 27, 15, 79
    dw 28, 15, 79
    dw 29, 15, 1
    dw 30, 15, 152
    dw 31, 15, 152
    dw 32, 15, 255
    dw 33, 15, 255
    dw 34, 15, 79
    dw 35, 15, 152
    dw 36, 15, 39
    dw 37, 15, 39
    dw 38, 15, 39
    dw 39, 15, 39
    dw 40, 15, 39
    dw  6, 16, 29
    dw  7, 16, 39
    dw  8, 16, 39
    dw  9, 16, 79
    dw 10, 16, 39
    dw 11, 16, 1
    dw 12, 16, 1
    dw 13, 16, 152
    dw 14, 16, 152
    dw 15, 16, 79
    dw 16, 16, 255
    dw 17, 16, 255
    dw 18, 16, 152
    dw 19, 16, 152
    dw 20, 16, 1
    dw 21, 16, 1
    dw 22, 16, 79
    dw 23, 16, 79
    dw 24, 16, 79
    dw 25, 16, 79
    dw 26, 16, 79
    dw 27, 16, 79
    dw 28, 16, 1
    dw 29, 16, 1
    dw 30, 16, 152
    dw 31, 16, 152
    dw 32, 16, 251
    dw 33, 16, 255
    dw 34, 16, 79
    dw 35, 16, 152
    dw 36, 16, 152
    dw 37, 16, 1
    dw 38, 16, 1
    dw 39, 16, 39
    dw 40, 16, 79
    dw 41, 16, 39
    dw 42, 16, 39
    dw 43, 16, 79
    dw 14, 17, 152
    dw 15, 17, 152
    dw 16, 17, 251
    dw 17, 17, 152
    dw 18, 17, 152
    dw 19, 17, 152
    dw 20, 17, 1
    dw 22, 17, 1
    dw 23, 17, 152
    dw 24, 17, 152
    dw 25, 17, 152
    dw 26, 17, 152
    dw 27, 17, 1
    dw 29, 17, 1
    dw 30, 17, 152
    dw 31, 17, 152
    dw 32, 17, 152
    dw 33, 17, 251
    dw 34, 17, 152
    dw 35, 17, 152
    dw 15, 18, 152
    dw 16, 18, 152
    dw 17, 18, 152
    dw 18, 18, 152
    dw 19, 18, 79
    dw 30, 18, 79
    dw 31, 18, 152
    dw 32, 18, 152
    dw 33, 18, 152
    dw 34, 18, 152
    dw 16, 19, 1
    dw 17, 19, 79
    dw 32, 19, 79
    dw 33, 19, 1
	dw 0, 0, 0
	

	EnemyClose2 dw 9, 0, 152
				dw 22, 0, 152
				dw 9, 1, 152
				dw 15, 1, 152
				dw 16, 1, 152
				dw 22, 1, 152
				dw 9, 2, 152
				dw 10, 2, 1
				dw 15, 2, 152
				dw 16, 2, 152
				dw 21, 2, 1
				dw 22, 2, 152
				dw 9, 3, 1
				dw 10, 3, 152
				dw 13, 3, 1
				dw 14, 3, 1
				dw 15, 3, 29
				dw 16, 3, 29
				dw 17, 3, 1
				dw 18, 3, 1
				dw 21, 3, 152
				dw 22, 3, 1
				dw 8, 4, 1
				dw 9, 4, 1
				dw 10, 4, 152
				dw 11, 4, 1
				dw 12, 4, 29
				dw 13, 4, 29
				dw 14, 4, 152
				dw 15, 4, 29
				dw 16, 4, 29
				dw 17, 4, 152
				dw 18, 4, 29
				dw 19, 4, 29
				dw 20, 4, 1
				dw 21, 4, 152
				dw 22, 4, 1
				dw 23, 4, 1
				dw 4, 5, 1
				dw 5, 5, 39
				dw 6, 5, 39
				dw 7, 5, 39
				dw 8, 5, 39
				dw 9, 5, 1
				dw 10, 5, 152
				dw 11, 5, 1
				dw 12, 5, 29
				dw 13, 5, 29
				dw 14, 5, 1
				dw 15, 5, 29
				dw 16, 5, 29
				dw 17, 5, 1
				dw 18, 5, 29
				dw 19, 5, 29
				dw 20, 5, 1
				dw 21, 5, 152
				dw 22, 5, 1
				dw 23, 5, 39
				dw 24, 5, 39
				dw 25, 5, 39
				dw 26, 5, 39
				dw 27, 5, 1
				dw 0, 6, 29
				dw 1, 6, 39
				dw 2, 6, 39
				dw 3, 6, 39
				dw 4, 6, 1
				dw 5, 6, 1
				dw 6, 6, 1
				dw 7, 6, 1
				dw 8, 6, 1
				dw 9, 6, 39
				dw 10, 6, 152
				dw 11, 6, 152
				dw 12, 6, 152
				dw 13, 6, 1
				dw 14, 6, 29
				dw 15, 6, 1
				dw 16, 6, 1
				dw 17, 6, 29
				dw 18, 6, 1
				dw 19, 6, 152
				dw 20, 6, 152
				dw 21, 6, 152
				dw 22, 6, 39
				dw 23, 6, 1
				dw 24, 6, 1
				dw 25, 6, 1
				dw 26, 6, 1
				dw 27, 6, 1
				dw 28, 6, 39
				dw 29, 6, 39
				dw 30, 6, 39
				dw 31, 6, 29
				dw 7, 7, 1
				dw 8, 7, 1
				dw 9, 7, 152
				dw 10, 7, 29
				dw 11, 7, 255
				dw 12, 7, 152
				dw 13, 7, 1
				dw 14, 7, 1
				dw 15, 7, 29
				dw 16, 7, 29
				dw 17, 7, 1
				dw 18, 7, 1
				dw 19, 7, 152
				dw 20, 7, 255
				dw 21, 7, 29
				dw 22, 7, 152
				dw 23, 7, 1
				dw 24, 7, 1
				dw 4, 8, 29
				dw 5, 8, 39
				dw 6, 8, 39
				dw 7, 8, 39
				dw 8, 8, 1
				dw 9, 8, 152
				dw 10, 8, 29
				dw 11, 8, 29
				dw 12, 8, 152
				dw 14, 8, 1
				dw 15, 8, 1
				dw 16, 8, 1
				dw 17, 8, 1
				dw 19, 8, 152
				dw 20, 8, 29
				dw 21, 8, 29
				dw 22, 8, 152
				dw 23, 8, 1
				dw 24, 8, 39
				dw 25, 8, 39
				dw 26, 8, 39
				dw 27, 8, 29
				dw 10, 9, 152
				dw 11, 9, 152
				dw 20, 9, 152
				dw 21, 9, 152
				dw 0, 0, 0 

	EnemyMiddle2 dw 7, 0, 1
				dw 16, 0, 1
				dw 7, 1, 152
				dw 16, 1, 152
				dw 7, 2, 152
				dw 12, 2, 152
				dw 16, 2, 152
				dw 7, 3, 1
				dw 8, 3, 152
				dw 11, 3, 29
				dw 12, 3, 29
				dw 15, 3, 152
				dw 16, 3, 1
				dw 4, 4, 29
				dw 5, 4, 39
				dw 6, 4, 39
				dw 7, 4, 1
				dw 8, 4, 152
				dw 9, 4, 1
				dw 10, 4, 29
				dw 11, 4, 1
				dw 12, 4, 1
				dw 13, 4, 29
				dw 14, 4, 1
				dw 15, 4, 152
				dw 16, 4, 1
				dw 17, 4, 39
				dw 18, 4, 39
				dw 19, 4, 29
				dw 0, 5, 29
				dw 1, 5, 39
				dw 2, 5, 39
				dw 3, 5, 39
				dw 4, 5, 39
				dw 5, 5, 1
				dw 6, 5, 1
				dw 7, 5, 1
				dw 8, 5, 152
				dw 9, 5, 29
				dw 10, 5, 29
				dw 11, 5, 1
				dw 12, 5, 29
				dw 13, 5, 29
				dw 14, 5, 29
				dw 15, 5, 152
				dw 16, 5, 1
				dw 17, 5, 1
				dw 18, 5, 1
				dw 19, 5, 39
				dw 20, 5, 39
				dw 21, 5, 39
				dw 22, 5, 39
				dw 23, 5, 29
				dw 4, 6, 29
				dw 5, 6, 39
				dw 6, 6, 39
				dw 7, 6, 152
				dw 8, 6, 29
				dw 9, 6, 152
				dw 10, 6, 1
				dw 11, 6, 29
				dw 12, 6, 29
				dw 13, 6, 1
				dw 14, 6, 152
				dw 15, 6, 29
				dw 16, 6, 152
				dw 17, 6, 39
				dw 18, 6, 39
				dw 19, 6, 29
				dw 8, 7, 152
				dw 9, 7, 1
				dw 11, 7, 1
				dw 12, 7, 1
				dw 14, 7, 1
				dw 15, 7, 152
				dw 0, 0, 0

	EnemyFar2 dw 4, 0, 1
				dw 11, 0, 1
				dw 4, 1, 152
				dw 7, 1, 152
				dw 8, 1, 152
				dw 11, 1, 152
				dw 4, 2, 152
				dw 5, 2, 1
				dw 7, 2, 29
				dw 8, 2, 29
				dw 10, 2, 1
				dw 11, 2, 152
				dw 0, 3, 29
				dw 1, 3, 39
				dw 2, 3, 39
				dw 3, 3, 39
				dw 4, 3, 152
				dw 5, 3, 152
				dw 6, 3, 29
				dw 7, 3, 1
				dw 8, 3, 1
				dw 9, 3, 29
				dw 10, 3, 152
				dw 11, 3, 152
				dw 12, 3, 39
				dw 13, 3, 39
				dw 14, 3, 39
				dw 15, 3, 29
				dw 2, 4, 39
				dw 3, 4, 152
				dw 4, 4, 1
				dw 5, 4, 152
				dw 6, 4, 1
				dw 7, 4, 29
				dw 8, 4, 29
				dw 9, 4, 1
				dw 10, 4, 152
				dw 11, 4, 1
				dw 12, 4, 152
				dw 13, 4, 39
				dw 4, 5, 152
				dw 5, 5, 152
				dw 10, 5, 152
				dw 11, 5, 152
				dw 0, 0, 0

; ===== ENEMY 3 =====
Enemy3Active db 0
Enemy3DelayTimer dw 0

Enemy3Normal dw 16,  5, 152
    dw 33,  5, 152
    dw 16,  6, 152
    dw 33,  6, 152
    dw 16,  7, 152
    dw 17,  7, 152
    dw 32,  7, 152
    dw 33,  7, 152
    dw 17,  8, 152
    dw 24,  8, 152
    dw 25,  8, 152
    dw 32,  8, 152
    dw 17,  9, 152
    dw 23,  9, 152
    dw 24,  9, 255
    dw 25,  9, 255
    dw 26,  9, 152
    dw 32,  9, 152
    dw 15, 10, 6
    dw 16, 10, 1
    dw 17, 10, 152
    dw 18, 10, 152
    dw 19, 10, 1
    dw 23, 10, 152
    dw 24, 10, 152
    dw 25, 10, 152
    dw 26, 10, 152
    dw 30, 10, 1
    dw 31, 10, 152
    dw 32, 10, 152
    dw 33, 10, 1
    dw 34, 10, 6
    dw  9, 11, 79
    dw 10, 11, 79
    dw 11, 11, 79
    dw 12, 11, 39
    dw 13, 11, 39
    dw 14, 11, 39
    dw 15, 11, 39
    dw 16, 11, 1
    dw 17, 11, 152
    dw 18, 11, 1
    dw 19, 11, 152
    dw 20, 11, 79
    dw 21, 11, 152
    dw 22, 11, 79
    dw 23, 11, 152
    dw 24, 11, 79
    dw 25, 11, 79
    dw 26, 11, 152
    dw 27, 11, 79
    dw 28, 11, 152
    dw 29, 11, 79
    dw 30, 11, 152
    dw 31, 11, 1
    dw 32, 11, 152
    dw 33, 11, 1
    dw 34, 11, 39
    dw 35, 11, 39
    dw 36, 11, 39
    dw 37, 11, 39
    dw 38, 11, 79
    dw 39, 11, 79
    dw 40, 11, 79
    dw  5, 12, 79
    dw  6, 12, 79
    dw  7, 12, 79
    dw  8, 12, 39
    dw  9, 12, 39
    dw 10, 12, 39
    dw 11, 12, 39
    dw 12, 12, 39
    dw 13, 12, 1
    dw 14, 12, 1
    dw 15, 12, 1
    dw 16, 12, 1
    dw 17, 12, 152
    dw 18, 12, 79
    dw 19, 12, 79
    dw 20, 12, 79
    dw 21, 12, 1
    dw 22, 12, 79
    dw 23, 12, 152
    dw 24, 12, 27
    dw 25, 12, 79
    dw 26, 12, 152
    dw 27, 12, 79
    dw 28, 12, 1
    dw 29, 12, 79
    dw 30, 12, 79
    dw 31, 12, 79
    dw 32, 12, 152
    dw 33, 12, 1
    dw 34, 12, 1
    dw 35, 12, 1
    dw 36, 12, 1
    dw 37, 12, 39
    dw 38, 12, 39
    dw 39, 12, 39
    dw 40, 12, 39
    dw 41, 12, 39
    dw 42, 12, 79
    dw 43, 12, 79
    dw 44, 12, 79
    dw  1, 13, 79
    dw  2, 13, 79
    dw  3, 13, 79
    dw  4, 13, 39
    dw  5, 13, 39
    dw  6, 13, 39
    dw  7, 13, 39
    dw  8, 13, 39
    dw  9, 13, 39
    dw 10, 13, 1
    dw 11, 13, 1
    dw 12, 13, 1
    dw 13, 13, 1
    dw 14, 13, 1
    dw 15, 13, 152
    dw 16, 13, 1
    dw 17, 13, 152
    dw 18, 13, 1
    dw 19, 13, 79
    dw 20, 13, 79
    dw 21, 13, 79
    dw 22, 13, 79
    dw 23, 13, 1
    dw 24, 13, 79
    dw 25, 13, 79
    dw 26, 13, 1
    dw 27, 13, 79
    dw 28, 13, 79
    dw 29, 13, 79
    dw 30, 13, 79
    dw 31, 13, 152
    dw 32, 13, 152
    dw 33, 13, 1
    dw 34, 13, 152
    dw 35, 13, 1
    dw 36, 13, 1
    dw 37, 13, 1
    dw 38, 13, 1
    dw 39, 13, 1
    dw 40, 13, 39
    dw 41, 13, 39
    dw 42, 13, 39
    dw 43, 13, 39
    dw 44, 13, 39
    dw 45, 13, 39
    dw 46, 13, 79
    dw 47, 13, 79
    dw 48, 13, 79
    dw 12, 14, 1
    dw 13, 14, 39
    dw 14, 14, 152
    dw 15, 14, 152
    dw 16, 14, 152
    dw 17, 14, 152
    dw 18, 14, 152
    dw 19, 14, 152
    dw 20, 14, 1
    dw 21, 14, 152
    dw 22, 14, 79
    dw 23, 14, 79
    dw 24, 14, 79
    dw 25, 14, 79
    dw 26, 14, 79
    dw 27, 14, 79
    dw 28, 14, 152
    dw 29, 14, 1
    dw 30, 14, 152
    dw 31, 14, 152
    dw 32, 14, 152
    dw 33, 14, 152
    dw 34, 14, 152
    dw 35, 14, 152
    dw 36, 14, 39
    dw 37, 14, 1
    dw  9, 15, 39
    dw 10, 15, 39
    dw 11, 15, 39
    dw 12, 15, 39
    dw 13, 15, 39
    dw 14, 15, 152
    dw 15, 15, 79
    dw 16, 15, 255
    dw 17, 15, 251
    dw 18, 15, 152
    dw 19, 15, 152
    dw 20, 15, 1
    dw 21, 15, 79
    dw 22, 15, 79
    dw 23, 15, 1
    dw 24, 15, 152
    dw 25, 15, 152
    dw 26, 15, 1
    dw 27, 15, 79
    dw 28, 15, 79
    dw 29, 15, 1
    dw 30, 15, 152
    dw 31, 15, 152
    dw 32, 15, 255
    dw 33, 15, 255
    dw 34, 15, 79
    dw 35, 15, 152
    dw 36, 15, 39
    dw 37, 15, 39
    dw 38, 15, 39
    dw 39, 15, 39
    dw 40, 15, 39
    dw  6, 16, 29
    dw  7, 16, 39
    dw  8, 16, 39
    dw  9, 16, 79
    dw 10, 16, 39
    dw 11, 16, 1
    dw 12, 16, 1
    dw 13, 16, 152
    dw 14, 16, 152
    dw 15, 16, 79
    dw 16, 16, 255
    dw 17, 16, 255
    dw 18, 16, 152
    dw 19, 16, 152
    dw 20, 16, 1
    dw 21, 16, 1
    dw 22, 16, 79
    dw 23, 16, 79
    dw 24, 16, 79
    dw 25, 16, 79
    dw 26, 16, 79
    dw 27, 16, 79
    dw 28, 16, 1
    dw 29, 16, 1
    dw 30, 16, 152
    dw 31, 16, 152
    dw 32, 16, 251
    dw 33, 16, 255
    dw 34, 16, 79
    dw 35, 16, 152
    dw 36, 16, 152
    dw 37, 16, 1
    dw 38, 16, 1
    dw 39, 16, 39
    dw 40, 16, 79
    dw 41, 16, 39
    dw 42, 16, 39
    dw 43, 16, 79
    dw 14, 17, 152
    dw 15, 17, 152
    dw 16, 17, 251
    dw 17, 17, 152
    dw 18, 17, 152
    dw 19, 17, 152
    dw 20, 17, 1
    dw 22, 17, 1
    dw 23, 17, 152
    dw 24, 17, 152
    dw 25, 17, 152
    dw 26, 17, 152
    dw 27, 17, 1
    dw 29, 17, 1
    dw 30, 17, 152
    dw 31, 17, 152
    dw 32, 17, 152
    dw 33, 17, 251
    dw 34, 17, 152
    dw 35, 17, 152
    dw 15, 18, 152
    dw 16, 18, 152
    dw 17, 18, 152
    dw 18, 18, 152
    dw 19, 18, 79
    dw 30, 18, 79
    dw 31, 18, 152
    dw 32, 18, 152
    dw 33, 18, 152
    dw 34, 18, 152
    dw 16, 19, 1
    dw 17, 19, 79
    dw 32, 19, 79
    dw 33, 19, 1
	dw 0, 0, 0

Enemy3NormalFixed dw 16,  5, 152
    dw 33,  5, 152
    dw 16,  6, 152
    dw 33,  6, 152
    dw 16,  7, 152
    dw 17,  7, 152
    dw 32,  7, 152
    dw 33,  7, 152
    dw 17,  8, 152
    dw 24,  8, 152
    dw 25,  8, 152
    dw 32,  8, 152
    dw 17,  9, 152
    dw 23,  9, 152
    dw 24,  9, 255
    dw 25,  9, 255
    dw 26,  9, 152
    dw 32,  9, 152
    dw 15, 10, 6
    dw 16, 10, 1
    dw 17, 10, 152
    dw 18, 10, 152
    dw 19, 10, 1
    dw 23, 10, 152
    dw 24, 10, 152
    dw 25, 10, 152
    dw 26, 10, 152
    dw 30, 10, 1
    dw 31, 10, 152
    dw 32, 10, 152
    dw 33, 10, 1
    dw 34, 10, 6
    dw  9, 11, 79
    dw 10, 11, 79
    dw 11, 11, 79
    dw 12, 11, 39
    dw 13, 11, 39
    dw 14, 11, 39
    dw 15, 11, 39
    dw 16, 11, 1
    dw 17, 11, 152
    dw 18, 11, 1
    dw 19, 11, 152
    dw 20, 11, 79
    dw 21, 11, 152
    dw 22, 11, 79
    dw 23, 11, 152
    dw 24, 11, 79
    dw 25, 11, 79
    dw 26, 11, 152
    dw 27, 11, 79
    dw 28, 11, 152
    dw 29, 11, 79
    dw 30, 11, 152
    dw 31, 11, 1
    dw 32, 11, 152
    dw 33, 11, 1
    dw 34, 11, 39
    dw 35, 11, 39
    dw 36, 11, 39
    dw 37, 11, 39
    dw 38, 11, 79
    dw 39, 11, 79
    dw 40, 11, 79
    dw  5, 12, 79
    dw  6, 12, 79
    dw  7, 12, 79
    dw  8, 12, 39
    dw  9, 12, 39
    dw 10, 12, 39
    dw 11, 12, 39
    dw 12, 12, 39
    dw 13, 12, 1
    dw 14, 12, 1
    dw 15, 12, 1
    dw 16, 12, 1
    dw 17, 12, 152
    dw 18, 12, 79
    dw 19, 12, 79
    dw 20, 12, 79
    dw 21, 12, 1
    dw 22, 12, 79
    dw 23, 12, 152
    dw 24, 12, 27
    dw 25, 12, 79
    dw 26, 12, 152
    dw 27, 12, 79
    dw 28, 12, 1
    dw 29, 12, 79
    dw 30, 12, 79
    dw 31, 12, 79
    dw 32, 12, 152
    dw 33, 12, 1
    dw 34, 12, 1
    dw 35, 12, 1
    dw 36, 12, 1
    dw 37, 12, 39
    dw 38, 12, 39
    dw 39, 12, 39
    dw 40, 12, 39
    dw 41, 12, 39
    dw 42, 12, 79
    dw 43, 12, 79
    dw 44, 12, 79
    dw  1, 13, 79
    dw  2, 13, 79
    dw  3, 13, 79
    dw  4, 13, 39
    dw  5, 13, 39
    dw  6, 13, 39
    dw  7, 13, 39
    dw  8, 13, 39
    dw  9, 13, 39
    dw 10, 13, 1
    dw 11, 13, 1
    dw 12, 13, 1
    dw 13, 13, 1
    dw 14, 13, 1
    dw 15, 13, 152
    dw 16, 13, 1
    dw 17, 13, 152
    dw 18, 13, 1
    dw 19, 13, 79
    dw 20, 13, 79
    dw 21, 13, 79
    dw 22, 13, 79
    dw 23, 13, 1
    dw 24, 13, 79
    dw 25, 13, 79
    dw 26, 13, 1
    dw 27, 13, 79
    dw 28, 13, 79
    dw 29, 13, 79
    dw 30, 13, 79
    dw 31, 13, 152
    dw 32, 13, 152
    dw 33, 13, 1
    dw 34, 13, 152
    dw 35, 13, 1
    dw 36, 13, 1
    dw 37, 13, 1
    dw 38, 13, 1
    dw 39, 13, 1
    dw 40, 13, 39
    dw 41, 13, 39
    dw 42, 13, 39
    dw 43, 13, 39
    dw 44, 13, 39
    dw 45, 13, 39
    dw 46, 13, 79
    dw 47, 13, 79
    dw 48, 13, 79
    dw 12, 14, 1
    dw 13, 14, 39
    dw 14, 14, 152
    dw 15, 14, 152
    dw 16, 14, 152
    dw 17, 14, 152
    dw 18, 14, 152
    dw 19, 14, 152
    dw 20, 14, 1
    dw 21, 14, 152
    dw 22, 14, 79
    dw 23, 14, 79
    dw 24, 14, 79
    dw 25, 14, 79
    dw 26, 14, 79
    dw 27, 14, 79
    dw 28, 14, 152
    dw 29, 14, 1
    dw 30, 14, 152
    dw 31, 14, 152
    dw 32, 14, 152
    dw 33, 14, 152
    dw 34, 14, 152
    dw 35, 14, 152
    dw 36, 14, 39
    dw 37, 14, 1
    dw  9, 15, 39
    dw 10, 15, 39
    dw 11, 15, 39
    dw 12, 15, 39
    dw 13, 15, 39
    dw 14, 15, 152
    dw 15, 15, 79
    dw 16, 15, 255
    dw 17, 15, 251
    dw 18, 15, 152
    dw 19, 15, 152
    dw 20, 15, 1
    dw 21, 15, 79
    dw 22, 15, 79
    dw 23, 15, 1
    dw 24, 15, 152
    dw 25, 15, 152
    dw 26, 15, 1
    dw 27, 15, 79
    dw 28, 15, 79
    dw 29, 15, 1
    dw 30, 15, 152
    dw 31, 15, 152
    dw 32, 15, 255
    dw 33, 15, 255
    dw 34, 15, 79
    dw 35, 15, 152
    dw 36, 15, 39
    dw 37, 15, 39
    dw 38, 15, 39
    dw 39, 15, 39
    dw 40, 15, 39
    dw  6, 16, 29
    dw  7, 16, 39
    dw  8, 16, 39
    dw  9, 16, 79
    dw 10, 16, 39
    dw 11, 16, 1
    dw 12, 16, 1
    dw 13, 16, 152
    dw 14, 16, 152
    dw 15, 16, 79
    dw 16, 16, 255
    dw 17, 16, 255
    dw 18, 16, 152
    dw 19, 16, 152
    dw 20, 16, 1
    dw 21, 16, 1
    dw 22, 16, 79
    dw 23, 16, 79
    dw 24, 16, 79
    dw 25, 16, 79
    dw 26, 16, 79
    dw 27, 16, 79
    dw 28, 16, 1
    dw 29, 16, 1
    dw 30, 16, 152
    dw 31, 16, 152
    dw 32, 16, 251
    dw 33, 16, 255
    dw 34, 16, 79
    dw 35, 16, 152
    dw 36, 16, 152
    dw 37, 16, 1
    dw 38, 16, 1
    dw 39, 16, 39
    dw 40, 16, 79
    dw 41, 16, 39
    dw 42, 16, 39
    dw 43, 16, 79
    dw 14, 17, 152
    dw 15, 17, 152
    dw 16, 17, 251
    dw 17, 17, 152
    dw 18, 17, 152
    dw 19, 17, 152
    dw 20, 17, 1
    dw 22, 17, 1
    dw 23, 17, 152
    dw 24, 17, 152
    dw 25, 17, 152
    dw 26, 17, 152
    dw 27, 17, 1
    dw 29, 17, 1
    dw 30, 17, 152
    dw 31, 17, 152
    dw 32, 17, 152
    dw 33, 17, 251
    dw 34, 17, 152
    dw 35, 17, 152
    dw 15, 18, 152
    dw 16, 18, 152
    dw 17, 18, 152
    dw 18, 18, 152
    dw 19, 18, 79
    dw 30, 18, 79
    dw 31, 18, 152
    dw 32, 18, 152
    dw 33, 18, 152
    dw 34, 18, 152
    dw 16, 19, 1
    dw 17, 19, 79
    dw 32, 19, 79
    dw 33, 19, 1
	dw 0, 0, 0

	EnemyClose3 dw 9, 0, 152
				dw 22, 0, 152
				dw 9, 1, 152
				dw 15, 1, 152
				dw 16, 1, 152
				dw 22, 1, 152
				dw 9, 2, 152
				dw 10, 2, 1
				dw 15, 2, 152
				dw 16, 2, 152
				dw 21, 2, 1
				dw 22, 2, 152
				dw 9, 3, 1
				dw 10, 3, 152
				dw 13, 3, 1
				dw 14, 3, 1
				dw 15, 3, 29
				dw 16, 3, 29
				dw 17, 3, 1
				dw 18, 3, 1
				dw 21, 3, 152
				dw 22, 3, 1
				dw 8, 4, 1
				dw 9, 4, 1
				dw 10, 4, 152
				dw 11, 4, 1
				dw 12, 4, 29
				dw 13, 4, 29
				dw 14, 4, 152
				dw 15, 4, 29
				dw 16, 4, 29
				dw 17, 4, 152
				dw 18, 4, 29
				dw 19, 4, 29
				dw 20, 4, 1
				dw 21, 4, 152
				dw 22, 4, 1
				dw 23, 4, 1
				dw 4, 5, 1
				dw 5, 5, 39
				dw 6, 5, 39
				dw 7, 5, 39
				dw 8, 5, 39
				dw 9, 5, 1
				dw 10, 5, 152
				dw 11, 5, 1
				dw 12, 5, 29
				dw 13, 5, 29
				dw 14, 5, 1
				dw 15, 5, 29
				dw 16, 5, 29
				dw 17, 5, 1
				dw 18, 5, 29
				dw 19, 5, 29
				dw 20, 5, 1
				dw 21, 5, 152
				dw 22, 5, 1
				dw 23, 5, 39
				dw 24, 5, 39
				dw 25, 5, 39
				dw 26, 5, 39
				dw 27, 5, 1
				dw 0, 6, 29
				dw 1, 6, 39
				dw 2, 6, 39
				dw 3, 6, 39
				dw 4, 6, 1
				dw 5, 6, 1
				dw 6, 6, 1
				dw 7, 6, 1
				dw 8, 6, 1
				dw 9, 6, 39
				dw 10, 6, 152
				dw 11, 6, 152
				dw 12, 6, 152
				dw 13, 6, 1
				dw 14, 6, 29
				dw 15, 6, 1
				dw 16, 6, 1
				dw 17, 6, 29
				dw 18, 6, 1
				dw 19, 6, 152
				dw 20, 6, 152
				dw 21, 6, 152
				dw 22, 6, 39
				dw 23, 6, 1
				dw 24, 6, 1
				dw 25, 6, 1
				dw 26, 6, 1
				dw 27, 6, 1
				dw 28, 6, 39
				dw 29, 6, 39
				dw 30, 6, 39
				dw 31, 6, 29
				dw 7, 7, 1
				dw 8, 7, 1
				dw 9, 7, 152
				dw 10, 7, 29
				dw 11, 7, 255
				dw 12, 7, 152
				dw 13, 7, 1
				dw 14, 7, 1
				dw 15, 7, 29
				dw 16, 7, 29
				dw 17, 7, 1
				dw 18, 7, 1
				dw 19, 7, 152
				dw 20, 7, 255
				dw 21, 7, 29
				dw 22, 7, 152
				dw 23, 7, 1
				dw 24, 7, 1
				dw 4, 8, 29
				dw 5, 8, 39
				dw 6, 8, 39
				dw 7, 8, 39
				dw 8, 8, 1
				dw 9, 8, 152
				dw 10, 8, 29
				dw 11, 8, 29
				dw 12, 8, 152
				dw 14, 8, 1
				dw 15, 8, 1
				dw 16, 8, 1
				dw 17, 8, 1
				dw 19, 8, 152
				dw 20, 8, 29
				dw 21, 8, 29
				dw 22, 8, 152
				dw 23, 8, 1
				dw 24, 8, 39
				dw 25, 8, 39
				dw 26, 8, 39
				dw 27, 8, 29
				dw 10, 9, 152
				dw 11, 9, 152
				dw 20, 9, 152
				dw 21, 9, 152
				dw 0, 0, 0 

	EnemyMiddle3 dw 7, 0, 1
				dw 16, 0, 1
				dw 7, 1, 152
				dw 16, 1, 152
				dw 7, 2, 152
				dw 12, 2, 152
				dw 16, 2, 152
				dw 7, 3, 1
				dw 8, 3, 152
				dw 11, 3, 29
				dw 12, 3, 29
				dw 15, 3, 152
				dw 16, 3, 1
				dw 4, 4, 29
				dw 5, 4, 39
				dw 6, 4, 39
				dw 7, 4, 1
				dw 8, 4, 152
				dw 9, 4, 1
				dw 10, 4, 29
				dw 11, 4, 1
				dw 12, 4, 1
				dw 13, 4, 29
				dw 14, 4, 1
				dw 15, 4, 152
				dw 16, 4, 1
				dw 17, 4, 39
				dw 18, 4, 39
				dw 19, 4, 29
				dw 0, 5, 29
				dw 1, 5, 39
				dw 2, 5, 39
				dw 3, 5, 39
				dw 4, 5, 39
				dw 5, 5, 1
				dw 6, 5, 1
				dw 7, 5, 1
				dw 8, 5, 152
				dw 9, 5, 29
				dw 10, 5, 29
				dw 11, 5, 1
				dw 12, 5, 29
				dw 13, 5, 29
				dw 14, 5, 29
				dw 15, 5, 152
				dw 16, 5, 1
				dw 17, 5, 1
				dw 18, 5, 1
				dw 19, 5, 39
				dw 20, 5, 39
				dw 21, 5, 39
				dw 22, 5, 39
				dw 23, 5, 29
				dw 4, 6, 29
				dw 5, 6, 39
				dw 6, 6, 39
				dw 7, 6, 152
				dw 8, 6, 29
				dw 9, 6, 152
				dw 10, 6, 1
				dw 11, 6, 29
				dw 12, 6, 29
				dw 13, 6, 1
				dw 14, 6, 152
				dw 15, 6, 29
				dw 16, 6, 152
				dw 17, 6, 39
				dw 18, 6, 39
				dw 19, 6, 29
				dw 8, 7, 152
				dw 9, 7, 1
				dw 11, 7, 1
				dw 12, 7, 1
				dw 14, 7, 1
				dw 15, 7, 152
				dw 0, 0, 0

	EnemyFar3 dw 4, 0, 1
				dw 11, 0, 1
				dw 4, 1, 152
				dw 7, 1, 152
				dw 8, 1, 152
				dw 11, 1, 152
				dw 4, 2, 152
				dw 5, 2, 1
				dw 7, 2, 29
				dw 8, 2, 29
				dw 10, 2, 1
				dw 11, 2, 152
				dw 0, 3, 29
				dw 1, 3, 39
				dw 2, 3, 39
				dw 3, 3, 39
				dw 4, 3, 152
				dw 5, 3, 152
				dw 6, 3, 29
				dw 7, 3, 1
				dw 8, 3, 1
				dw 9, 3, 29
				dw 10, 3, 152
				dw 11, 3, 152
				dw 12, 3, 39
				dw 13, 3, 39
				dw 14, 3, 39
				dw 15, 3, 29
				dw 2, 4, 39
				dw 3, 4, 152
				dw 4, 4, 1
				dw 5, 4, 152
				dw 6, 4, 1
				dw 7, 4, 29
				dw 8, 4, 29
				dw 9, 4, 1
				dw 10, 4, 152
				dw 11, 4, 1
				dw 12, 4, 152
				dw 13, 4, 39
				dw 4, 5, 152
				dw 5, 5, 152
				dw 10, 5, 152
				dw 11, 5, 152
				dw 0, 0, 0
		
	
; -------------------------------------------------------------------------
; BRESENHAM VARIABLES
; -------------------------------------------------------------------------
	m dw ?
	x0 dw ?
	x1 dw ?
	y0 dw ?
	y1 dw ?
	ErrorTerm dw ?
	ErrorTerm2 dw ?
	deltaX dw ?
	deltaY dw ?
	D dw ?
	stepX dw ?
	stepY dw ?
	color db ?
; -------------------------------------------------------------------------
; END
; -------------------------------------------------------------------------
	
	CONST_FOCAL dw 200 ; Focal for 3D view 
	

		 	
	points dw 2000 dup(?)
	pointsCount dw 0
	
	
	
	planeSpeed dw 2
	altitude dw 50
	
	WaitForBulletLines dw 1 
	
	MissileExploded db 0
	

		   
	tree2_x0 dw -100
	tree3_x0 dw -400
	tree4_x0 dw 300
		   
tree1_x dw 300
tree1_y dw 120
tree1_z dw 800

tree2_x1 dw 100
tree2_y dw 130
tree2_z dw 1200

tree3_x1 dw 400
tree3_y dw 140
tree3_z dw 800

tree4_x1 dw -300
tree4_y dw 80
tree4_z dw 200

enemy_x     dw 20
enemy_y     dw 180
target_x    dw 110
target_y    dw 160
	moveToggle db 0
	
	missileCnt dw 1

	enemyXtoMove dw 6
	
	MoveRightCnt dw 0
		
	FileNamePtr dw ?
	
	objTREE equ 1
	objMOUNTAIN equ 2
	objLAKE equ 3
	objBUILDING equ 4
	
	OBJ_COUNT equ 8
	OBJ_SIZE equ 8
	
	worldObjects dw objTREE, 200, 120, 800
				 dw	objTREE, -300, 120, 1600
				 dw	objTREE, 500, 120, 1200
				 
	MissileApproachActive db 0
 MissileApproachStage  db 0  
 MissileApproachTimer  dw 0   ; frames per stage
 MissileApproachX      dw 0   ; screen X (tracks player)
 MissileApproachY      dw 0   ; screen Y (tracks player)

	horizonLine dw 110
	
	bmpEnemyLeft db 'E_L.bmp', 0
	bmpEnemyRight db 'E_L.bmp', 0
	bmpEnemyForward db 'ENEMY.bmp', 0
	isLeft db 1
	isDead db 0
	isForawrd db 0
	disappearLevel db 0
	bmpDisappearEnemy db 'E_D1.bmp', 0
	
	; ===== ENEMY 2 STATE =====
isDead2 db 0
isExploded2 db 0
EnemyDeadByFire2 db 0
StageOneEnemyExplosionComplete2 db 0
WaitForEnemyExp2_2 db 0
enemyLeft2 db 0
enemyLeftTimer2 dw 0
normalLeftTImer2 dw 0
EnemyY2 dw ?
EnemyX2 dw ?
DisappearNow2 db 0
EnemyStayAtPlaceTimer2 dw 1
cxMODE2 dw 0
CxSizeTimer2 dw 1
disappearLevel2 db 0
isLeft2 db 1
isForawrd2 db 0

; ===== ENEMY 3 STATE =====
isDead3 db 0
isExploded3 db 0
EnemyDeadByFire3 db 0
StageOneEnemyExplosionComplete3 db 0
WaitForEnemyExp2_3 db 0
enemyLeft3 db 0
enemyLeftTimer3 dw 0
normalLeftTImer3 dw 0
EnemyY3 dw ?
EnemyX3 dw ?
DisappearNow3 db 0
EnemyStayAtPlaceTimer3 dw 1
cxMODE3 dw 0
CxSizeTimer3 dw 1
disappearLevel3 db 0
isLeft3 db 1
isForawrd3 db 0
normalLeftTImer dw 0

			
	enemyBaseX dw 0		
	

    music_data dw 200, 3    ; C4
               dw 220, 4    ; D4
               dw 240, 3    ; E4
               dw 240, 4    ; F4
               dw 220, 3    ; G4
               dw 240, 4    ; A4 (longer)
               dw 220, 4      ; End marker
               dw 200, 4      ; End marker
               dw 180, 4      ; End marker
			   dw 200, 3    ; C4
               dw 220, 4    ; D4
               dw 240, 3    ; E4
               dw 240, 4    ; F4
               dw 220, 3    ; G4
               dw 240, 4    ; A4 (longer)
               dw 220, 4      ; End marker
               dw 200, 4      ; End marker
               dw 180, 7      ; End marker
               dw 0,0      ; End marker
    

	
	BulletLines_generalZ dw 100
	
	BulletLine1_X0 dw 0 
	BulletLine1_X1 dw 5 
	BulletLine1_Y0 dw 2
	BulletLine1_Y1 dw 2 
		
	BulletLine2_X0 dw 0 
	BulletLine2_X1 dw 0 
	BulletLine2_Y0 dw 2    
	BulletLine2_Y1 dw 5 

	BulletLine3_X0 dw 5
	BulletLine3_X1 dw 5 
	BulletLine3_Y0 dw 2    
	BulletLine3_Y1 dw 5

	BulletLine4_X0 dw 0   
	BulletLine4_X1 dw 5    
	BulletLine4_Y0 dw 5
	BulletLine4_Y1 dw 5	
	
	BulletLine1R_X0 dw -5
	BulletLine1R_X1 dw  0
	BulletLine1R_Y0 dw  2
	BulletLine1R_Y1 dw  2

	BulletLine2R_X0 dw  0
	BulletLine2R_X1 dw  0
	BulletLine2R_Y0 dw  2
	BulletLine2R_Y1 dw  5

	BulletLine3R_X0 dw -5
	BulletLine3R_X1 dw -5
	BulletLine3R_Y0 dw  2
	BulletLine3R_Y1 dw  5

	BulletLine4R_X0 dw -5
	BulletLine4R_X1 dw  0
	BulletLine4R_Y0 dw  5
	BulletLine4R_Y1 dw  5
	
	
	BulletLine5_X0 dw 5
	BulletLine5_X1 dw 8 
	BulletLine5_Y0 dw 1    
	BulletLine5_Y1 dw 1

	BulletLine6_X0 dw 0  
	BulletLine6_X1 dw 3    
	BulletLine6_Y0 dw 2
	BulletLine6_Y1 dw 2
	
	cxMODEMissile dw 0
	CxSizeTimerMissile dw 1
	
	moveTimer db 0
	
	MoveDownMedTimer db 0
	
	MissileExplosionBmp db "M_E.bmp", 0
	MissileExplosionBmp2 db "M_E2.bmp",0 

	
    music_length equ ($ - music_data) / 4
    
    current_note_index dw 0
    note_timer dw 0
    old_timer_int dd ?
    music_enabled db 1
	
	GameOver db 0
	enemyMoveCnt db 1
			
screen_xl   dw ?
screen_xr   dw ?
screen_ybase dw ?
screen_ytip  dw ?

	tempArr dw 128 dup (?)
	_spktog dw 0
	
	SB_BASE      EQU 220h
DSP_RESET    EQU SB_BASE + 6
DSP_READ     EQU SB_BASE + 0Ah
DSP_WRITE    EQU SB_BASE + 0Ch
DSP_RDSTAT   EQU SB_BASE + 0Eh
SAMPLE_DELAY EQU 28
CHUNK_SIZE   EQU 400h
SongFile1     DB 'TDZ.raw', 0
SongTakeMyBreathAway     DB 'TMBA.RAW', 0
file_handle  DW 0
bytes_read   DW 0
chunk_buf    DB CHUNK_SIZE DUP(0)
InstFile1 db 'INST_1.raw', 0
InstFile2 db 'INST_2.raw', 0
InstFile3 db 'INST_3.raw', 0
FileExplosionSfx db 'EXPL.raw', 0
FileStallSfx db 'stl.raw', 0
isMissileActive db 0

	explodeTimer db 0
	ExplodeStage2Timer db 0
	
	OldKeyboardInterruptOffset  dw ?   ; Old keaboard interrupt offset
OldKeyboardInterruptSegment dw ?   ; Old keaboard interrupt Segment 
OldTimeInterruptOffset      dw ?   ; Old Time interrupt offset
OldTimeInterruptSegment     dw ?   ; Old Time interrupt Segment

CurrentOldInterruptOffset   dw ?   ; The currnet Old interrupt offset
CurrentOldInterruptSegment  dw ?   ; The currnet Old interrupt
	
keyboardInterruptPOS    equ 9*4    ; The position of the keaborad interrupt in the interrupt vector table
TimeInterruptPOS        equ 28*4   ; The position of the time interrupt in the interrupt vector table
currentInterruptPOS     db ?       ; The cuurent interrupt position in the interrupt vector table
currentInterruptOFFSET  dw ?       ; The cuurent interrupt offset

	msg db "press any key  to see scan codes    or Escape to exit ",13,10,'$'
	
	KB_Event   db 10,13,"KB event: ",'$'   
	Ext_KB_Event db 10,13,"Ext KB event: ",'$'  
	 
	
	 
	Escape  db "ESCAPE  Bye Bye...." ,13,10,'$'  ;1
	;BB  db 13,10,"Bye Bye",13,10,'$'  ;31
	anyKeyPressed db 0
	
	exitLoop db 0
	
	key_pressed db ?
	
	extendedKey db 0
; --------------------------


CODESEG
start:
	mov ax, @data
	mov ds, ax
; --------------------------
	mov ax, 13h
	int 10h
	
@@resets:
	call resetVariabels
	call SpawnEnemyOnRandomCorner
	call Add_XY_ToMissile
	call SyncAllMissiles
	
@@drawLoop:
	call DrawMainMenu
	call TransitionBuffer
	push offset SongFile1
	call PlaySong
	jnc @@drawLoop 
;	call InitMusic
	call setKeyboradInterrupt
@@fullMenu:
	mov [byte ptr keys + 1], 0
	call restoreKeyboradInterrupt
;	call StopMusic
	call SpeakerOff
	mov [GameOver], 0
    call MainMenu
    call TransitionBuffer
    call flushKeys
	push offset SongTakeMyBreathAway
	call PlaySongAndMainMenu
    jc @@end
	call flushKeys
	cmp [cutScenePlayed], 1
	je @@skipCutscene
	call playStartCutscene
@@skipCutscene:
	call setKeyboradInterrupt
	;call LaunchMissileApproach

@@MainGameLoop:
	cmp [byte ptr keys + 1], 1
	je @@fullMenu
	;jc @@fullMenu
	cmp [GameOver], 1
	je @@end
@@continue:	
;	call resetKeys
	;call HandleMusic
	; drawing
	call fillAround
	call TickMusic
	; checking movement
	call CheckAndMoveNew
	call MoveForwards
	
	; draw plane (static) 

	; draw enviorment (moving)
	call DrawGrassLines
	
	;call SetCXbyTime
	;push cx
	;call DrawEnemy
	
	call HandleEnemy
	call HandleEnemy2
	call HandleEnemy3

	call HandleWeapons
	call LaunchMissile

	call DrawPlane

	;push offset EnemyNormal
	;push offset EnemyNormal
	;call DrawFromPixelArray
	
	; DEBUG: FIND color
	
;	call FindColorUnderMouse
	
	; move enemy 
;	call moveEnemy
	
	call HandleAltitude
	call HandleSpeed
	
	;call debugFindColors
	; showing as a whole (everything is copied to secondry buffer)
	
	;call HandleMissileApproach
	call TransitionBuffer
	
	
	; return
	jmp @@MainGameLoop
	
@@end:
;	call StopMusic
	call SpeakerOff
	mov ax, 3h
	int 10h
	

; -------------------------ן
exit:
	mov ax, 4c00h
	int 21h

; =============================================================================
; PROC TickMusic
; -----------------------------------------------------------------------------
; Purpose : Advance the background music by one tick.
;           Checks whether the current note has played long enough; if so,
;           moves to the next note and calls PlayTone.
;
; Entry   : music_data    - array of (frequency, duration) word pairs
;           current_note_index - index of the currently playing note
;           note_timer    - frames elapsed since current note started
;
; Exit    : current_note_index and note_timer updated.
;           PlayTone called when a note transition occurs.
;
; Modifies: (none - all registers preserved via push/pop)
; =============================================================================
proc TickMusic
    push ax
    push bx

    mov bx, [current_note_index]
    shl bx, 2                   ; *4

    cmp [word ptr music_data + bx], 0
    jne @@cont
    mov [current_note_index], 0
    mov [note_timer], 0
    xor bx, bx

@@cont:
    inc [note_timer]
    mov ax, [note_timer]
    cmp ax, [music_data + bx + 2]
    jl @@ret

    mov [note_timer], 0
    inc [current_note_index]
    mov ax, [music_data + bx]
    call PlayTone

@@ret:
    pop bx
    pop ax
    ret
endp TickMusic

; =============================================================================
; PROC TickMusic
; -----------------------------------------------------------------------------
; Purpose : Advance the background music by one tick.
;           Checks whether the current note has played long enough; if so,
;           moves to the next note and calls PlayTone.
;
; Entry   : music_data    - array of (frequency, duration) word pairs
;           current_note_index - index of the currently playing note
;           note_timer    - frames elapsed since current note started
;
; Exit    : current_note_index and note_timer updated.
;           PlayTone called when a note transition occurs.
;
; Modifies: (none - all registers preserved via push/pop)
; =============================================================================
proc ResetMissile
    push ax
	push si 
	push di 

    ; Reset all missile state flags
    mov [isMissileActive], 0
    mov [killMissile], 0
    mov [MissileExploded], 0
    mov [explodeTimer], 0
    mov [ExplodeStage2Timer], 0
    mov [cxMODEMissile], 0
    mov [CxSizeTimerMissile], 1
    mov [MoveDownMedTimer], 0
    mov [moveTimer], 0
    mov [enemyShootOnPlayerCountdown], 0

    ; Restore Missile_XXXS from backup using Add_XY_ToMissile logic
    ; First zero out XXXS by copying from XXXS_TO_COPY directly
    push si
    push di
    push ax

    mov si, offset Missile_XXXS_TO_COPY
    mov di, offset Missile_XXXS

@@copyLoop:
    cmp [word ptr si], 0
    jne @@ok
    cmp [word ptr si+2], 0
    jne @@ok
    cmp [word ptr si+4], 0
    je @@done
@@ok:
    mov ax, [si]
    mov [di], ax
    mov ax, [si+2]
    mov [di+2], ax
    mov ax, [si+4]
    mov [di+4], ax
    add si, 6
    add di, 6
    jmp @@copyLoop
@@done:
    mov [word ptr di], 0
    mov [word ptr di+2], 0
    mov [word ptr di+4], 0

    pop ax
    pop di
    pop si

    ; Now apply the initial X/Y offset (same as Add_XY_ToMissile)
	mov bl, 40 
	mov dl, 80 
	call RandomByCsW
    push offset Missile_XXXS
    push 0
    push ax
    call AddXToOffsetInArray
	
	mov bl, 30 
	mov dl, 60 
	call RandomByCsW
    push offset Missile_XXXS
    push 2
    push ax
    call AddXToOffsetInArray

    call SyncAllMissiles
	
	pop di 
	pop si
    pop ax
    ret
endp ResetMissile

; =============================================================================
; PROC CopyPixelArray
; -----------------------------------------------------------------------------
; Purpose : Copy a pixel-triplet array (X, Y, Color word triplets terminated
;           by 0,0,0) from one array to another.
;
; Entry   : [bp+4] = source array offset 
;           [bp+6] = destination array offset 
;
; Exit    : Destination array is an exact copy of source.
;
; Modifies: Destination array contents only.
; =============================================================================
proc CopyPixelArray
    push bp
    mov bp, sp
    push ax
    push si
    push di

    mov si, [bp+4]   ; source
    mov di, [bp+6]   ; dest

@@copyLoop:
    cmp [word ptr si], 0
    jne @@ok
    cmp [word ptr si+2], 0
    jne @@ok
    cmp [word ptr si+4], 0
    je @@done
@@ok:
    mov ax, [si]
    mov [di], ax
    mov ax, [si+2]
    mov [di+2], ax
    mov ax, [si+4]
    mov [di+4], ax
    add si, 6
    add di, 6
    jmp @@copyLoop

@@done:
    ; copy the terminating 0,0,0
    mov [word ptr di], 0
    mov [word ptr di+2], 0
    mov [word ptr di+4], 0

    pop di
    pop si
    pop ax
    pop bp
    ret 4
endp CopyPixelArray

; =============================================================================
; PROC Add_XY_ToMissile
; -----------------------------------------------------------------------------
; Purpose : Apply a fixed initial (X, Y) offset to every entry in the
;           Missile_XXXS array so that the missile first appears at a
;           reasonable starting position on screen.
;
; Entry   : Missile_XXXS must contain freshly initialised relative coordinates.
;
; Exit    : All X fields in Missile_XXXS incremented by 70.
;           All Y fields in Missile_XXXS incremented by 50.
;
; Registers Effected: None.
; =============================================================================
proc Add_XY_ToMissile

	push offset Missile_XXXS
	push 0
	push 70
	call AddXToOffsetInArray
	
	push offset Missile_XXXS
	push 2
	push 50
	call AddXToOffsetInArray
	
	ret
endp Add_XY_ToMissile

; =============================================================================
; PROC LaunchMissile
; -----------------------------------------------------------------------------
; Purpose : Decides whether to wait for the spawn timer, update the active
;           missile, handle its explosion, or reset it after death.
;
; Entry   : MissileExploded, killMissile, isMissileActive - current state flags.
;
; Exit    : Missile drawn/updated, explosion shown, Game Over, or state reset.
; =============================================================================
proc LaunchMissile
	cmp [MissileExploded], 1
	je @@explode
	cmp [killMissile], 1    ; Only use this if the boss/enemy is dead forever
	je @@enemyToReturn

	cmp [isMissileActive], 1 ; Is the missile currently flying?
	je @@UpdateAndDraw       ; If yes, skip timer and just draw it

	; --- If not active, run the spawn timer ---
	call CheckIfShouldLaunchMissileOnPlayer
	jnc @@ret                ; If carry is clear, not time to shoot yet

	; --- Timer hit! Initialize the missile ---
	mov [isMissileActive], 1 ; The missile is now alive!
	; (You may want to call Add_XY_ToMissile here to reset its starting position)

@@UpdateAndDraw:
    call DrawMissileNew
    call CheckMissileHitPlayer  
	jmp @@ret
@@explode:
	cmp [explodeTimer], 5
	jg @@killPlane 
	inc [explodeTimer]
	call ExplodeMissile
	jmp @@ret
@@killPlane:
	call GameOverProc
	jmp @@ret 
@@enemyToReturn:
	call ResetMissile
@@ret:
	ret
endp LaunchMissile

; =============================================================================
; PROC CheckMissileHitPlayer
; -----------------------------------------------------------------------------
; Purpose : Scan every pixel in the Missile_M sprite (the medium size) 
;           to see whether it overlaps the player's aircraft bounding box.
;           Only the M-stage sprite is tested because earlier stages are too
;           far away to plausibly hit the player, and close ones are triggered 
;           too late.
;
; Entry   : GetMissileSizeToSi must succeed and return SI = Missile_M.
;           Player aircraft is assumed to occupy pixels X: 135-198, Y: 88-136.
;           (BmpLeft=115, sprite width=83. right edge=198;
;            BmpTop=88,  sprite height=48. bottom edge=136.
;            The X left bound is tightened to harden hits for the missile.
;
; Exit    : If a pixel overlaps the player box:
;             isMissileActive = 0, killMissile = 1, MissileExploded = 1.

;           No registers modified (all saved/restored).
; =============================================================================
proc CheckMissileHitPlayer
    ; Only care about medium stage (Missile_M)
    call GetMissileSizeToSi
    jc @@ret                    ; missile done/inactive, skip
    cmp si, offset Missile_M
    jne @@ret                   ; not medium stage, skip

    ; Player plane bounding box (from DrawPlane: BmpLeft=115, BmpTop=88)
    ; Width 83, Height 48 = right=198, bottom=136
    mov di, offset Missile_M

@@scanLoop:
    cmp [word ptr di], 0
    jne @@ok
    cmp [word ptr di+2], 0
    jne @@ok
    cmp [word ptr di+4], 0
    je @@ret                    ; end of array, no hit
@@ok:
    mov ax, [di]                ; missile pixel X
    mov bx, [di+2]              ; missile pixel Y

    ; Check X overlap with player: 115 <= x <= 198
    cmp ax, 135
    jl @@next
    cmp ax, 198
    jg @@next

    ; Check Y overlap with player: 88 <= y <= 136
    cmp bx, 88
    jl @@next
    cmp bx, 136
    jg @@next

    ; HIT! 
    mov [isMissileActive], 0
    mov [killMissile], 1
	mov [MissileExploded], 1
 ;   call ExplodeMissile     ; show explosion at missile position
 ;   call GameOverProc       ; then game over screen
    jmp @@ret

@@next:
    add di, 6
    jmp @@scanLoop

@@ret:
    ret
endp CheckMissileHitPlayer

; =============================================================================
; PROC ExplodeMissile
; -----------------------------------------------------------------------------
; Purpose : Render a two-stage missile explosion animation at the missile's
;           current screen position.
;
; Entry   : Missile_XXXS[0] = current X, Missile_XXXS[2] = current Y
;           ExplodeStage2Timer = frame count within the explosion sequence.
;
; Exit    : BMP drawn to the buffer.
;           ExplodeStage2Timer incremented.
;           Following will be another BMP, to create a cool explosion effect.
;
; Modifies: ExplodeStage2Timer, FileError, BmpLeft, BmpTop, BmpWidth, BmpHeight, FileNamePtr
; =============================================================================
proc ExplodeMissile

	mov [FileError], 0
	
	cmp [ExplodeStage2Timer], 2
	jge @@stage2

	mov ax, [Missile_XXXS]
	mov bx, [Missile_XXXS+2]
	
	mov [FileNamePtr], offset MissileExplosionBmp
	mov [bmpLeft], ax
	mov [BmpTop], bx 
	mov [BmpWidth], 56 
	mov [BmpHeight], 70
    call OpenShowBmp
    cmp [FileError], 1
    je @@exitError
	
	cmp [ExplodeStage2Timer], 2
	jnge @@ret
@@stage2:
	
	mov ax, [Missile_XXXS]
	mov bx, [Missile_XXXS+2]
	
	mov [FileNamePtr], offset MissileExplosionBmp2
	mov [bmpLeft], ax
	mov [BmpTop], bx 
	mov [BmpWidth], 69 
	mov [BmpHeight], 69
	call OpenShowBmp
    cmp [FileError], 1
    je @@exitError
	jmp @@ret
	
@@exitError:
    mov dx, offset BmpFileErrorMsg
    mov ah, 9
    int 21h
@@ret:
	inc [ExplodeStage2Timer]
	ret
endp ExplodeMissile

; =============================================================================
; PROC CheckIfShouldLaunchMissileOnPlayer
; -----------------------------------------------------------------------------
; Purpose : The missile shooting time logic. When it reaches the current 
;           limit, the proc sets carry (signalling the caller to fire) and 
;           picks a new random limit.
;
; Entry   : enemyShootOnPlayerCountdown  - frames elapsed since last shot.
;           enemyShootOnPlayerCountdownLimit - target frame count before firing.
;
; Exit    : Carry set  = fire now (countdown reset, new random limit chosen).
;           Carry clear = not yet (countdown incremented).
;
; =============================================================================
proc CheckIfShouldLaunchMissileOnPlayer
    clc
    mov ax, [enemyShootOnPlayerCountdown]
    cmp ax, [enemyShootOnPlayerCountdownLimit]
    jne @@dontShoot


    ; Generate new random limit - range 19 to 27, multiply by 100
    mov bx, 2
    mov dx, 5
    call RandomByCsW
    ; ax now = random 19..27, bx is trashed by RandomByCsW
    mov bx, 100
    mul bx          ; ax = random * 100  (result in ax, 1900..2700)
    mov [enemyShootOnPlayerCountdownLimit], ax
    
    mov [enemyShootOnPlayerCountdown], 0
    mov [cxMODEMissile], 0
    mov [CxSizeTimerMissile], 1
	   stc
    jmp @@ret

@@dontShoot:
    inc [enemyShootOnPlayerCountdown]
	clc 
@@ret:
    ret
endp CheckIfShouldLaunchMissileOnPlayer

; =============================================================================
; PROC DrawMissileNew
; -----------------------------------------------------------------------------
; Purpose : Each frame, determine the current missile size stage, move the 
;           Missile_XXXS coordinates in the appropriate direction, 
;           synchronise all size sprites, and render the active size sprite to the 
;           off screen buffer.
;
; Entry   : SI = size sprite pointer (set by GetMissileSizeToSi).
;           cxMODEMissile / CxSizeTimerMissile control speed of size growth.
;
; Exit    : Missile_XXXS coordinates updated.
;           Active size sprite rendered.
;
; =============================================================================
proc DrawMissileNew
	push si 
	call GetMissileSizeToSi
	jnc @@cont
	jmp @@ret
@@cont:
	cmp si, offset Missile_M
	je @@moveMed
	jmp @@regular
@@moveMed:
	cmp [MoveDownMedTimer], 24
	jnge @@MoveToPlayer
	push offset Missile_XXXS
	push 0
	push -3
	call AddXToOffsetInArray
	
	push offset Missile_XXXS
	push 2
	push 2
	call AddXToOffsetInArray
@@MoveToPlayer:
	inc [MoveDownMedTimer]
	push offset Missile_XXXS
	push 0
	push 2
	call AddXToOffsetInArray
	
	push offset Missile_XXXS
	push 2
	push 2
	call AddXToOffsetInArray
	jmp @@sync 
@@regular:
	cmp si, offset Missile_L
	je @@Large
	push offset Missile_XXXS
	push 0
	push 1
	call AddXToOffsetInArray
	
	push offset Missile_XXXS
	push 2
	push 1
	call AddXToOffsetInArray
	jmp @@sync 
@@Large:
	cmp [moveTimer], 15
	jne @@regularMove 
@@moveUpRight:
	push offset Missile_XXXS
	push 0
	push -3
	call AddXToOffsetInArray
	
	push offset Missile_XXXS
	push 2
	push -1
	call AddXToOffsetInArray
	jmp @@sync
@@regularMove:
	inc [moveTimer]
	push offset Missile_XXXS
	push 0
	push -3
	call AddXToOffsetInArray
	
	push offset Missile_XXXS
	push 2
	push 3
	call AddXToOffsetInArray
@@sync:
	call SyncAllMissiles
	push si
	call DrawFromPixelArray
@@ret:
	pop si 
	ret
endp DrawMissileNew

; =============================================================================
; PROC setKeyboradInterrupt
; -----------------------------------------------------------------------------
; Purpose : install KeyboardInterrupt as the active handler for the replaced int.  
;
; Entry   : keyboardInterruptPOS   - constant. the byte offset of the INT 09h entry.
;           KeyboardInterrupt      - offset of the custom int servies routine to run.
;
; Exit    : currentInterruptPOS    = keyboardInterruptPOS  (36).
;           currentInterruptOFFSET = offset of KeyboardInterrupt.
;           IVT INT 09h entry      patched to point at KeyboardInterrupt in the current code segment (via SetInterrupt).
;           OldKeyboardInterruptOffset  = original INT 09h handler offset.
;           OldKeyboardInterruptSegment = original INT 09h handler segment.
;
; =============================================================================
proc setKeyboradInterrupt
	mov ax,keyboardInterruptPOS
	mov bx,offset currentInterruptPOS
	mov [word ptr bx],ax
	mov bx,offset currentInterruptOFFSET
	mov ax,offset KeyboardInterrupt
	mov [word ptr bx],ax
	
	call SetInterrupt          
	
	mov bx,offset CurrentOldInterruptOffset
	mov ax,[word ptr bx]
	mov bx,offset OldKeyboardInterruptOffset
	mov [word ptr bx],ax
	mov bx,offset CurrentOldInterruptSegment
	mov ax,[word ptr bx]
	mov bx,offset OldKeyboardInterruptSegment
	mov [word ptr bx],ax 
	ret 
endp 	setKeyboradInterrupt

; =============================================================================
; PROC restoreKeyboradInterrupt
; -----------------------------------------------------------------------------
; Purpose : Undo the keyboard ISR installation performed by
;           setKeyboradInterrupt.  Copies the saved original handler address
;           from OldKeyboardInterruptOffset / OldKeyboardInterruptSegment back.
;
; Entry   : OldKeyboardInterruptOffset  - original INT 09h handler offset
;                                         saved by setKeyboradInterrupt.
;           OldKeyboardInterruptSegment - original INT 09h handler segment.
;           keyboardInterruptPOS        - constant 36 (9*4); IVT byte offset
;                                         for INT 09h.
;
; Exit    : CurrentOldInterruptOffset  = OldKeyboardInterruptOffset.
;           CurrentOldInterruptSegment = OldKeyboardInterruptSegment.
;           INT 09h entry restored to the original BIOS handler
;                                         (via RestoreOldInterrupt).
;
; =============================================================================
proc restoreKeyboradInterrupt
	mov bx,offset OldKeyboardInterruptOffset
	mov ax,[word ptr bx]
	mov bx,offset CurrentOldInterruptOffset
	mov [word ptr bx],ax
	mov bx,offset OldKeyboardInterruptSegment
	mov ax,[word ptr bx]
	mov bx,offset CurrentOldInterruptSegment
	mov [word ptr bx],ax 
	mov ax,keyboardInterruptPOS
	mov bx,offset currentInterruptPOS
	mov [word ptr bx],ax
	call RestoreOldInterrupt	
	ret
endp 	restoreKeyboradInterrupt
	
; =============================================================================
; PROC SetInterrupt
; -----------------------------------------------------------------------------
; Purpose : Install a new interrupt handler by patching the interrupt vector
;           table (at es:0) at the position specified by currentInterruptPOS.
;
; Entry   : currentInterruptPOS    - byte holding the IVT byte-offset of the
;                                    interrupt to replace.
;           currentInterruptOFFSET - word holding the offset of the new
;                                    handler routine to install.
;
; Exit    : IVT entry at currentInterruptPOS patched with the new handler.
;           CurrentOldInterruptOffset   = old int offset  (saved).
;           CurrentOldInterruptSegment  = old int segment (saved).
;
;           All registers preserved (PUSHA / POPA).
;
; =============================================================================
proc SetInterrupt
	pusha
	push es
	push si
	mov ax,0
	mov es,ax
	
	xor ax,ax
	mov bx,offset currentInterruptPOS 
	mov al,[byte ptr bx]
	mov si,ax
	mov dx,[word ptr es:si]
	mov cx,[word ptr es:si+2]
	
	mov bx,offset CurrentOldInterruptOffset
	mov [word ptr bx],dx       
	mov bx,offset CurrentOldInterruptSegment  
	mov [word ptr bx],cx       
	cli       
	mov bx,offset currentInterruptOFFSET	       
	mov ax,[word ptr bx]
	mov cx,0
	mov es,cx	
	mov [word ptr es:si],ax
	mov ax,cs
	mov [word ptr es:si+2],ax
	pop si
	pop es
	sti                ; set interrupt flag        
	popa
ret
endp SetInterrupt

; =============================================================================
; PROC RestoreOldInterrupt
; -----------------------------------------------------------------------------
; Purpose : Undo the effect of SetInterrupt by writing the previously saved
;           handler (offset + segment) back into the IVT at the position
;           specified by currentInterruptPOS, restoring the original ISR.
;
; Entry   : CurrentOldInterruptOffset  - saved offset  of the original handler.
;           CurrentOldInterruptSegment - saved segment of the original handler.
;           currentInterruptPOS        - byte holding the IVT byte-offset of
;                                        the interrupt to restore.
;
; Exit    : IVT entry at currentInterruptPOS restored to the original handler.
;           All registers preserved (PUSHA / POPA).
;
; =============================================================================
proc RestoreOldInterrupt
	pusha
	push es
	mov ax,0
	mov es,ax
	
	cli     ; clear interupt flag
	mov bx,offset CurrentOldInterruptOffset    
	mov ax,[word ptr bx]
	mov bx,offset currentInterruptPOS 	
	xor cx,cx
	mov cl,[byte ptr bx]
	mov si,cx
	mov [word ptr es: si],ax
	mov bx,offset CurrentOldInterruptSegment     
	mov ax,[word ptr bx]
	mov [word ptr es: si+2],ax
	sti     ; set interrupt flag
	pop es
	popa
 ret
endp RestoreOldInterrupt
 
; =============================================================================
; PROC KeyboardInterrupt  (FAR)
; -----------------------------------------------------------------------------
; Purpose : Custom hardware interrupt service routine keyboard. 
;           Reads the scan code from the keyboard controller, strips the release bit to 
;           obtain the key index, and records the key state (pressed or released) in the
;           keys[] array. Async.
;
; Entry   : keys[]          - 128-byte array indexed by scan code.
;           Port 60h        - keyboard data port; yields the raw scan code.
;
; Exit    : keys[scanCode]  = 1 on key press,  0 on key release.
;           anyKeyPressed   updated by AnyKeyPressedCheck.
;           All registers preserved (PUSHA / POPA + DS).
;
; =============================================================================
proc KeyboardInterrupt far
    pusha
    push ds
    mov ax, @data
    mov ds, ax
    in al, 60h
	
   
    mov bl, al
    and bl, 7Fh          ; strip release bit
    xor bh, bh
    
    test al, 80h
    jnz @@release        ; high bit = key release
    
    ; key press
	;mov [byte ptr anyKeyPressed], 1
    mov [byte ptr keys + bx], 1
    jmp @@done
    
@@release:
    mov [byte ptr keys + bx], 0
    
@@done:
	call AnyKeyPressedCheck
    mov al, 20h
    out 20h, al
    pop ds
    popa
    iret
endp KeyboardInterrupt

; =============================================================================
; PROC AnyKeyPressedCheck
; -----------------------------------------------------------------------------
; Purpose : Scan the entire keys[] array (128 bytes) to determine whether
;           any key is currently held.  Sets anyKeyPressed = 1 if found,
;           or 0 if no key is pressed.
;
; Entry   : keys[] array reflects the current keyboard state.
;
; Exit    : anyKeyPressed = 0 or 1.
;
; Modifies: None.
; =============================================================================
proc AnyKeyPressedCheck

	mov cx, 128
	mov si, offset keys 
	
@@checkAnyKey:
	cmp [si], 1
	je @@pressed
	inc si 
	loop @@checkAnyKey
	mov [byte ptr anyKeyPressed], 0 
	jmp @@ret 
@@pressed:
	mov [byte ptr anyKeyPressed], 1
@@ret:
	ret
endp AnyKeyPressedCheck
 

; =============================================================================
; PROC SyncAllMissiles
; -----------------------------------------------------------------------------
; Purpose : After moving Missile_XXXS, sync the same relative position delta to
;           all larger missile sprites (XXS, XS, S, M, L) so that every size
;           variant renders at the same screen location.
;
; Entry   : Missile_XXXS contains the current (moved) position.
;           All other sprites contain their last-synced position.
;
; Exit    : All missile sprites have field[0] (X) and field[2] (Y) equal to
;           those in Missile_XXXS in coordination to their size (of course it can not be 
;           the exact same coords).
;
; Modifies: All missile sprite (except ready XXXS) array's X and Y fields.
; =============================================================================
proc SyncAllMissiles
	push si 
	
	mov si, offset Missile_XXS
	mov di, offset Missile_XXXS
	mov ax, [di]
	
	mov bx, [si]
	
	sub ax, bx
	
	push offset Missile_XXS
	push 0
	push ax
	call AddXToOffsetInArray
	
	mov ax, [di+2]
	
	mov bx, [si+2]
	
	sub ax, bx
	
	push offset Missile_XXS
	push 2
	push ax
	call AddXToOffsetInArray

	mov si, offset Missile_XS
	mov di, offset Missile_XXXS
	mov ax, [di]
	
	mov bx, [si]
	
	sub ax, bx
	
	push offset Missile_XS
	push 0
	push ax
	call AddXToOffsetInArray
	
	mov ax, [di+2]
	
	mov bx, [si+2]
	
	sub ax, bx
	
	push offset Missile_XS
	push 2
	push ax
	call AddXToOffsetInArray

	mov si, offset Missile_S
	mov di, offset Missile_XXXS
	mov ax, [di]
	
	mov bx, [si]
	
	sub ax, bx
	
	push offset Missile_S
	push 0
	push ax
	call AddXToOffsetInArray
	
	mov ax, [di+2]
	
	mov bx, [si+2]
	
	sub ax, bx
	
	push offset Missile_S
	push 2
	push ax
	call AddXToOffsetInArray	
	
	mov si, offset Missile_M
	mov di, offset Missile_XXXS
	mov ax, [di]
	
	mov bx, [si]
	
	sub ax, bx
	
	push offset Missile_M
	push 0
	push ax
	call AddXToOffsetInArray
	
	mov ax, [di+2]
	
	mov bx, [si+2]
	
	sub ax, bx
	
	push offset Missile_M
	push 2
	push ax
	call AddXToOffsetInArray	
	
	mov si, offset Missile_L
	mov di, offset Missile_XXXS
	mov ax, [di]
	
	mov bx, [si]
	
	sub ax, bx
	
	push offset Missile_L
	push 0
	push ax
	call AddXToOffsetInArray
	
	mov ax, [di+2]
	
	mov bx, [si+2]
	
	sub ax, bx
	
	push offset Missile_L
	push 2
	push ax
	call AddXToOffsetInArray
	
	pop si 
	ret
endp SyncAllMissiles

; =============================================================================
; PROC GetMissileSizeToSi
; -----------------------------------------------------------------------------
; Purpose : Get the current missile sprite size according to time passing and load to SI
;           - to serve as the pointer to the sprite.
;
; Entry   : cxMODEMissile / CxSizeTimerMissile (consumed by GetCX), Missile Sprites (from inside the proc).
;
; Exit    : SI = offset of the active sprite.
;           Carry clear = valid sprite returned.
;           Carry set   = missile exceeded maximum range; killMissile set to 1.
;
; =============================================================================
proc GetMissileSizeToSi
	
	call GetCX
	clc 
@@XXXS:
	cmp cx, 100
	jnle @@XXS
	mov si, offset Missile_XXXS
	jmp @@ret
@@XXS:
	cmp cx, 200
	jnle @@XS
	mov si, offset Missile_XXS
	jmp @@ret
@@XS:
	cmp cx, 300 
	jnle @@S
	mov si, offset Missile_XS
	jmp @@ret
@@S:
	cmp cx, 400
	jnle @@M
	mov si, offset Missile_S
	jmp @@ret
@@M:
	cmp cx, 2500
	jnle @@L
	mov si, offset Missile_M
	jmp @@ret
@@L:
    cmp cx, 4000        ; was 2100
    jnle @@drawNothing
    mov si, offset Missile_L
    jmp @@ret
@@DrawNothing:
    stc
    mov [killMissile], 1
	jmp @@finalRet
@@ret:
	clc 
@@finalRet:
	ret
endp GetMissileSizeToSi

; =============================================================================
; PROC GetCX
; -----------------------------------------------------------------------------
; Purpose : Advance the missile size counter (cxMODEMissile) using a
;           shift-register "timer", then compute CX = cxMODEMissile * 100.
;
;   The shift-register "timer" (CxSizeTimerMissile) slows down the size
;   progression
;
; Entry   : cxMODEMissile, CxSizeTimerMissile.
;
; Exit    : CX = cxMODEMissile * 100.
;           cxMODEMissile possibly incremented (max 40).
;
; Modifies: CX
; =============================================================================
proc GetCX
	push ax 
	push bx 
	
	mov ax, 2
	cmp [cxMODE], 4
	jnge @@regular 
	mov ax, 1
@@regular:
    inc [CxSizeTimerMissile]
    cmp [CxSizeTimerMissile], ax    ; slow it down
    jl @@calc
    
    mov [CxSizeTimerMissile], 0
    cmp [cxMODEMissile], 40
    jg @@calc                     ; don't increment past 20
    inc [cxMODEMissile]
@@calc:
    xor cx, cx
    mov ax, [cxMODEMissile]
    mov bx, 100
    mul bx
    add cx, ax
@@ret:
	pop bx 
	pop ax 
    ret
endp GetCX

; =============================================================================
; PROC FreqToDivisor
; -----------------------------------------------------------------------------
; Purpose : Convert a frequency in Hz to the PIT (8253) channel 2 divisor
;           so the correct tone is produced by the PC Speaker.
;
; Entry   : AX = desired frequency in Hz (must be > 0).
;
; Exit    : AX = PIT divisor to send to port 42h.
;
; Modifies: AX (result)
; =============================================================================
proc FreqToDivisor
    push dx
    push bx
    
    mov bx, ax
    mov dx, 0012h      ; High word of 1193180
    mov ax, 34DCh      ; Low word of 1193180
    div bx             ; DX:AX / BX
    
    pop bx
    pop dx
    ret
endp FreqToDivisor

; =============================================================================
; PROC PlayTone
; -----------------------------------------------------------------------------
; Purpose : Emit a tone at the requested frequency.
;
; Entry   : AX = frequency in Hz
;
; Exit    : PC Speaker emitting the requested tone.
;
; Modifies: None
; =============================================================================
proc PlayTone
    push ax
    push dx
    push bx
    

    call FreqToDivisor
    
    ; Tell PIT channel 2 we're sending a new frequency
    push ax
    mov al, 0B6h
    out 43h, al
    pop ax
    
    ; Send divisor
    out 42h, al
    mov al, ah
    out 42h, al
    
    ; Enable speaker correctly
    in al, 61h
    or al, 03h
    out 61h, al
    jmp @@done


@@done:
    pop bx
    pop dx
    pop ax
    ret
endp PlayTone

; =============================================================================
; PROC FindColorUnderMouse
; -----------------------------------------------------------------------------
; Purpose : check the mouse for a left-button click, read the screen
;           pixel color at the cursor position, and display the color index
;           as a decimal number on the text console.
;           Useful only during development/debugging; not called in the
;           final game loop.
;
; Entry   : Graphic mode must be set.
;
; Exit    : If left button was pressed:
;             - Mouse cursor hidden while reading.
;             - Colour index at cursor position printed via ShowAxDecimal.
;             - Mouse cursor restored.
;           All registers preserved.
;
; =============================================================================
proc FindColorUnderMouse
	push ax
	push bx
	push cx
	push dx
	
	mov ax, 0003h
	int 33h
	cmp bx, 1
	jne @@ret
	shr cx, 1
	
	mov ax, 0002h
	int 33h
	
	; we now have cx and dx
	
	mov ah, 0Dh
	mov bh, 0
	int 10h
	
	push ax
	
	
	mov ax, 0001h
	int 33h
	
	pop ax
	xor ah, ah
	call ShowAxDecimal
@@ret:
	
	mov ax, 0001h
	int 33h
	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp FindColorUnderMouse

; =============================================================================
; PROC debugFindColors
; -----------------------------------------------------------------------------
; Purpose : Fill secondBuffer with a rising colour-index ramp
;           (0, 1, 2, … 255, 0, 1, …) so that every VGA palette entry is
;           visible on screen when the buffer is blitted.
;           Debug/development utility only – not called in the final game.
;
; Entry   : secondBuffer segment must be defined.
;
; Exit    : secondBuffer[0..63999] filled with bytes 0-255 repeating.
;           All registers preserved.
;
; Arbitrary numbers explained:
;   64000 - total bytes in a 320×200 VGA Mode-13h frame (320 * 200 = 64 000).
; =============================================================================
proc debugFindColors
	push ax
	push es
	push di
	
	mov ax, seg secondBuffer
	mov es, ax
	
	mov di, 0
	mov al, 0
	
@@loop:
	mov [es:di], al
	inc al 
	inc di
	cmp di, 64000 
	je @@ret
	loop @@loop

@@ret:
	pop di
	pop es
	pop ax
	ret
endp debugFindColors

; =============================================================================
; PROC HandleWeapons
; -----------------------------------------------------------------------------
; Purpose : Top-level dispatcher for all player weapon systems.
;           Currently delegates entirely to HandleGuns.
;           Designed as an extension point so future weapon types
;           (missiles, bombs, etc.) can be added here without touching
;           the main game loop.
;
; Entry   : None.
; Exit    : None (all state changes occur inside called procedures).
; Modifies: What HandleGuns modifies (see that proc).
; =============================================================================
proc HandleWeapons
	
	call HandleGuns

	ret
endp HandleWeapons

; =============================================================================
; PROC HandleGuns
; -----------------------------------------------------------------------------
; Purpose : Each-frame update for the player's gun system.
;           Runs three sub-systems in order:
;             1. HandleShooting  – fire logic and bullet physics.
;             2. HandleShootSound – PC-speaker audio for the gun.
;             3. loadGunsCrosshair – draw the HUD aiming reticle.
;
; Entry   : None.
; Exit    : Shooting control ON-SCREEN.
; Modifies: What the three called procedures modify.
; =============================================================================
proc HandleGuns
	
	call HandleShooting
	call HandleShootSound
	call loadGunsCrosshair

	

	ret
endp HandleGuns

; =============================================================================
; PROC HandleShootSound
; -----------------------------------------------------------------------------
; Purpose : Drive the PC-speaker shooting sound effect one frame at a time.
;
; Entry   : ShootSoundTimer  – frames remaining in the sound effect (0 = end).
;           ShootSoundFreq   – current speaker frequency in Hz.
;
; Exit    : ShootSoundTimer decremented by 1 (if > 0).
;           ShootSoundFreq   incremented by 200 (if timer was > 0).
;
; =============================================================================
proc HandleShootSound
    cmp [ShootSoundTimer], 0
    je @@ret

    mov ax, [ShootSoundFreq]
    call SpeakerOn

    add [ShootSoundFreq], 200   ; 3072 steps / 15 frames = ~200 per frame
    dec [ShootSoundTimer]


@@ret:
    ret
endp HandleShootSound

; =============================================================================
; PROC HandleShooting
; -----------------------------------------------------------------------------
; Purpose : Each-frame update for the player bullet. Spawn it, Move it, Hanlde sound variables, 
;           check hits, etc...
;
; Entry   : BulletActive   – 0 = idle, 1 = in flight.
;           keys[]         – keyboard state array (1 = held).
;           BulletLines_generalZ – current depth of the bullet box.
;
; Exit    : BulletActive may be set to 1 (fire) or 0 (expired/hit).
;           BulletLines_generalZ incremented by 10 each active frame.
;           ShootSoundTimer / ShootSoundFreq initialised on new shot.
; =============================================================================
proc HandleShooting

    cmp [byte ptr BulletActive], 1
    jne @@dontCheckActive
    jmp @@checkActive
@@dontCheckActive:
    cmp [byte ptr keys + 24h], 1
    je @@BulletActive
	jmp @@checkActive
@@bulletActive: 
    mov [byte ptr BulletActive], 1
    mov [BulletLines_generalZ], 100
    
	call ResetBulletCoords


    ; instant non-blocking shoot click - just turn speaker on
    ; it will turn off automatically next frame via SpeakerOff
 ;   mov ax, 800
  ;  call SpeakerOn
	mov [ShootSoundTimer], 7
    mov [ShootSoundFreq], 400
@@checkActive:
    cmp [byte ptr BulletActive], 0
    je @@ret

    call HandleShootingGraphics
    add [BulletLines_generalZ], 10
    call CheckBulletCoords     
    call HandleBulletMovement

@@ret:
    ; turn speaker off after a few frames naturally
    ; or just call SpeakerOff every frame when bullet not active
  ;  cmp [byte ptr BulletActive], 0
@@keepSound:
    ret
endp HandleShooting

; =============================================================================
; PROC ResetBulletCoords
; -----------------------------------------------------------------------------
; Purpose : Restore every bullet-line endpoint to its default centred
;           position so that a newly fired bullet starts as two small
;           squares (left gun + right gun) centred on the player's 'guns'.
;
; Entry   : None.
; Exit    : BulletLine1-4 (left box) and BulletLine1R-4R (right box)
;           endpoint variables reset to default values.
;
; =============================================================================
proc ResetBulletCoords


    mov [BulletLine1_X0], 0
    mov [BulletLine1_X1], 5
    mov [BulletLine1_Y0], 2
    mov [BulletLine1_Y1], 2
    mov [BulletLine2_X0], 0
    mov [BulletLine2_X1], 0
    mov [BulletLine2_Y0], 2
    mov [BulletLine2_Y1], 5
    mov [BulletLine3_X0], 5
    mov [BulletLine3_X1], 5
    mov [BulletLine3_Y0], 2
    mov [BulletLine3_Y1], 5
    mov [BulletLine4_X0], 0
    mov [BulletLine4_X1], 5
    mov [BulletLine4_Y0], 5
    mov [BulletLine4_Y1], 5
    mov [BulletLine1R_X0], -5
    mov [BulletLine1R_X1], 0
    mov [BulletLine1R_Y0], 2
    mov [BulletLine1R_Y1], 2
    mov [BulletLine2R_X0], 0
    mov [BulletLine2R_X1], 0
    mov [BulletLine2R_Y0], 2
    mov [BulletLine2R_Y1], 5
    mov [BulletLine3R_X0], -5
    mov [BulletLine3R_X1], -5
    mov [BulletLine3R_Y0], 2
    mov [BulletLine3R_Y1], 5
    mov [BulletLine4R_X0], -5
    mov [BulletLine4R_X1], 0
    mov [BulletLine4R_Y0], 5
    mov [BulletLine4R_Y1], 5

	ret
endp ResetBulletCoords

; =============================================================================
; PROC KillEnemy
; -----------------------------------------------------------------------------
; Purpose : Animate the death of Enemy 1 in two stages:
;           Stage 1 – show a small explosion BMP (E_ES.bmp) at the enemy
;                     position for 5 frames.
;           Stage 2 – show a large explosion BMP (E_EB.bmp); move the enemy
;                     sprite downward 6 pixels per frame simulating it
;                     falling, until Y > 170 at which point carry is set
;                     to signal the caller that the kill sequence is done.
;
; Entry   : EnemyX / EnemyY – screen position of the dead enemy.
;           StageOneEnemyExplosionComplete – 0 = still in stage 1, 1 = stage 2.
;           WaitForEnemyExp2 – frame counter for stage 1.
;
; Exit    : Carry set  = explosion finished (enemy fell off screen).
;           Carry clear = explosion still running.
;           EnemyY incremented by 6 each stage-2 frame.
;           StageOneEnemyExplosionComplete set to 1 after 5 stage-1 frames.
;
; =============================================================================
proc KillEnemy
	
	
	mov ax, [EnemyX]
	mov bx, [EnemyY]
	
	cmp [byte ptr StageOneEnemyExplosionComplete], 1
	je @@BigExplosion

	; show e_es at enemy 
	mov [bmpWidth], 48
	MOV [BmpHeight], 31
	mov [BmpTop], bx
	mov [bmpLeft], ax 
	mov [FileNamePtr], offset Enemy_ExplosionSmall
	call OpenShowBmp
	
	; wait half sec 
	; wait...
	inc [WaitForEnemyExp2]
	cmp [WaitForEnemyExp2], 5
	clc
	jnge @@ret
	
	mov [byte ptr StageOneEnemyExplosionComplete], 1
	
@@BigExplosion:
	; show e_eb at enemy and falling down 
	mov [bmpWidth], 49
	MOV [BmpHeight], 39
	mov [BmpTop], bx
	mov [bmpLeft], ax 
	mov [FileNamePtr], offset Enemy_ExplosionBig
	call OpenShowBmp
	; enemey moves down from HandleEnemy
	add [EnemyY], 6
	cmp [EnemyY], 170 
	clc 
	jnge @@ret 
	stc

@@ret:
	ret
endp KillEnemy

; =============================================================================
; PROC CheckBulletCoords
; -----------------------------------------------------------------------------
; Purpose : Test the current bullet bounding box against all active, living
;           enemies (1, 2, and 3).  On a confirmed hit the bullet is consumed
;           and the appropriate "dead by fire" flag is set.
;
; Entry   : BulletActive, Enemy2Active, Enemy3Active, isDead2, isDead3 –
;           BulletLines_generalZ – bullet depth (hit only counts if ≥ 200).
;           EnemyNormal / Enemy2Normal / Enemy3Normal – pixel arrays.
;
; Exit    : On hit AND Z ≥ 200:
;             BulletActive = 0.
;             EnemyDeadByFireN = 1 for the struck enemy.
;             EnemyXN / EnemyYN = struck enemy's current first-pixel coords.
;
; Arbitrary numbers explained:
;   200 – minimum depth for a hit to register.
; =============================================================================
proc CheckBulletCoords

    call GetBulletScreenCoords   

    ; Check enemy 1
    mov si, offset EnemyNormal
    call CheckBulletCoordsWithEnemySI
    jc @@hitEnemy1

    ; Check enemy 2
    cmp [Enemy2Active], 1
    jne @@checkEnemy3
    cmp [isDead2], 1
    je @@checkEnemy3
    mov si, offset Enemy2Normal
    call CheckBulletCoordsWithEnemySI
    jc @@hitEnemy2

@@checkEnemy3:
    cmp [Enemy3Active], 1
    jne @@ret
    cmp [isDead3], 1
    je @@ret
    mov si, offset Enemy3Normal
    call CheckBulletCoordsWithEnemySI
    jc @@hitEnemy3
    jmp @@ret

@@hitEnemy1:
    cmp [BulletLines_generalZ], 200
    jnge @@ret
    mov [byte ptr BulletActive], 0
    mov [EnemyDeadByFire], 1
    mov ax, [si]
    mov bx, [si+2]
    mov [EnemyX], ax
    mov [EnemyY], bx
    jmp @@ret

@@hitEnemy2:
    cmp [BulletLines_generalZ], 200
    jnge @@ret
    mov [byte ptr BulletActive], 0
    mov [EnemyDeadByFire2], 1
    mov ax, [si]
    mov bx, [si+2]
    mov [EnemyX2], ax
    mov [EnemyY2], bx
    jmp @@ret

@@hitEnemy3:
    cmp [BulletLines_generalZ], 200
    jnge @@ret
    mov [byte ptr BulletActive], 0
    mov [EnemyDeadByFire3], 1
    mov ax, [si]
    mov bx, [si+2]
    mov [EnemyX3], ax
    mov [EnemyY3], bx

@@ret:
    ret
endp CheckBulletCoords



; =============================================================================
; PROC CheckBulletCoordsWithEnemySI
; -----------------------------------------------------------------------------
; Purpose : Test all 8 projected bullet corners against the enemy pixel array
;           pointed to by SI.  Returns carry set if any corner matches.
;
; Entry   : SI  = offset of the enemy pixel array (word triplets X,Y,Color).
;           BulletScreenX1-X8, BulletScreenY1-Y8 – projected corner coords.
;
; Exit    : Carry set  = at least one corner hit a pixel in the enemy array.
;           Carry clear = no hit.
;           AX, BX, CX preserved.
; =============================================================================
proc CheckBulletCoordsWithEnemySI
    push ax
    push bx
    push cx

    mov ax, [BulletScreenX1]
    mov bx, [BulletScreenY1]
    call CheckBulletCornerSI
    jc @@hit

    mov ax, [BulletScreenX2]
    mov bx, [BulletScreenY2]
    call CheckBulletCornerSI
    jc @@hit

    mov ax, [BulletScreenX3]
    mov bx, [BulletScreenY3]
    call CheckBulletCornerSI
    jc @@hit

    mov ax, [BulletScreenX4]
    mov bx, [BulletScreenY4]
    call CheckBulletCornerSI
    jc @@hit

    mov ax, [BulletScreenX5]
    mov bx, [BulletScreenY5]
    call CheckBulletCornerSI
    jc @@hit

    mov ax, [BulletScreenX6]
    mov bx, [BulletScreenY6]
    call CheckBulletCornerSI
    jc @@hit

    mov ax, [BulletScreenX7]
    mov bx, [BulletScreenY7]
    call CheckBulletCornerSI
    jc @@hit

    mov ax, [BulletScreenX8]
    mov bx, [BulletScreenY8]
    call CheckBulletCornerSI
    jc @@hit

    clc
    jmp @@ret

@@hit:
    stc

@@ret:
    pop cx
    pop bx
    pop ax
    ret
endp CheckBulletCoordsWithEnemySI


; =============================================================================
; PROC CheckBulletCornerSI
; -----------------------------------------------------------------------------
; Purpose : Check the enemy pixel array pointed to by SI and return carry set
;           if the screen coordinate (AX, BX) matches any pixel entry.
;           Termination sentinel: three consecutive zero words (0,0,0).
;
; Entry   : SI = enemy pixel array pointer (word triplets: X, Y, Color).
;           AX = bullet screen X to test.
;           BX = bullet screen Y to test.
;
; Exit    : Carry set  = (AX, BX) found in the array.
;           Carry clear = (AX, BX) not found (end of array reached).
;           SI, AX, BX preserved.
; =============================================================================
proc CheckBulletCornerSI
    push si
    push ax
    push bx

@@loop:
    cmp [word ptr si], 0
    jne @@ok
    cmp [word ptr si+2], 0
    jne @@ok
    cmp [word ptr si+4], 0
    je @@miss
@@ok:
    cmp ax, [si]
    jne @@next
    cmp bx, [si+2]
    jne @@next
    stc
    jmp @@ret
@@next:
    add si, 6
    jmp @@loop

@@miss:
    clc

@@ret:
    pop bx
    pop ax
    pop si
    ret
endp CheckBulletCornerSI

; =============================================================================
; PROC GetBulletScreenCoords
; -----------------------------------------------------------------------------
; Purpose : Project all 8 world-space corners of the bullet's two 3-D boxes
;           onto the 2-D screen using Calc3D (perspective projection) and
;           store the results in BulletScreenX1-X8 / BulletScreenY1-Y8.
;           Must be called once per frame before any bullet hit-testing.
;
; Entry   : BulletLine1/2/3/4 _X0,_X1,_Y0,_Y1 – left box endpoints.
;           BulletLine1R/2R/3R/4R _X0,_X1,_Y0,_Y1 – right box endpoints.
;           BulletLines_generalZ – shared Z depth for both boxes.
;
; Exit    : BulletScreenX1-X8 / BulletScreenY1-Y8 updated with projected coords.
;           AX, BX, CX preserved.
;
; =============================================================================
proc GetBulletScreenCoords
    push ax
    push bx
    push cx

    ; === LEFT BOX ===

    ; top left corner
    mov ax, [BulletLine1_X0]
    mov bx, [BulletLine1_Y0]
    mov cx, [BulletLines_generalZ]
    call Calc3D
    mov [BulletScreenX1], di
    mov [BulletScreenY1], si

    ; top right corner
    mov ax, [BulletLine1_X1]
    mov bx, [BulletLine1_Y1]
    mov cx, [BulletLines_generalZ]
    call Calc3D
    mov [BulletScreenX2], di
    mov [BulletScreenY2], si

    ; bottom left corner
    mov ax, [BulletLine4_X0]
    mov bx, [BulletLine4_Y0]
    mov cx, [BulletLines_generalZ]
    call Calc3D
    mov [BulletScreenX3], di
    mov [BulletScreenY3], si

    ; bottom right corner
    mov ax, [BulletLine4_X1]
    mov bx, [BulletLine4_Y1]
    mov cx, [BulletLines_generalZ]
    call Calc3D
    mov [BulletScreenX4], di
    mov [BulletScreenY4], si

    ; === RIGHT BOX ===

    ; top left corner
    mov ax, [BulletLine1R_X0]
    mov bx, [BulletLine1R_Y0]
    mov cx, [BulletLines_generalZ]
    call Calc3D
    mov [BulletScreenX5], di
    mov [BulletScreenY5], si

    ; top right corner
    mov ax, [BulletLine1R_X1]
    mov bx, [BulletLine1R_Y1]
    mov cx, [BulletLines_generalZ]
    call Calc3D
    mov [BulletScreenX6], di
    mov [BulletScreenY6], si

    ; bottom left corner
    mov ax, [BulletLine4R_X0]
    mov bx, [BulletLine4R_Y0]
    mov cx, [BulletLines_generalZ]
    call Calc3D
    mov [BulletScreenX7], di
    mov [BulletScreenY7], si

    ; bottom right corner
    mov ax, [BulletLine4R_X1]
    mov bx, [BulletLine4R_Y1]
    mov cx, [BulletLines_generalZ]
    call Calc3D
    mov [BulletScreenX8], di
    mov [BulletScreenY8], si

    pop cx
    pop bx
    pop ax

	ret
endp GetBulletScreenCoords	

; =============================================================================
; PROC HandleBulletMovement
; -----------------------------------------------------------------------------
; Purpose : Each frame, decide how the bullet box should move
;
; Entry   : BulletActive          – 0 = idle, 1 = in flight.
;           BulletLines_generalZ  – current Z depth.
;
; Exit    : BulletActive set to 0 if Z ≥ 300.
;           Box coordinates updated via AddXYToBulletsLines / SmallerInPlace.
;
; =============================================================================
proc HandleBulletMovement
    cmp [byte ptr BulletActive], 0
    je @@ret

    cmp [BulletLines_generalZ], 140
    jl @@move
    jge @@moveOther   
	
@@moveOther:
	cmp [BulletLines_generalZ], 300
    jl @@stop
    jmp @@endBullet
	
@@stop:
	call SmallerInPlace
    jmp @@ret

@@move:
    push -2
    push -1
    call AddXYToBulletsLines
	jmp @@ret

@@endBullet:
    mov [byte ptr BulletActive], 0

@@ret:
    ret
endp HandleBulletMovement

; =============================================================================
; PROC SmallerInPlace
; -----------------------------------------------------------------------------
; Purpose : Advance the bullet's Z depth by 15 units (faster than normal)
;           and nudge both boxes one pixel inward/upward, creating the visual
;           impression that the bullet is shrinking as it recedes.
;           Called each frame during a shrink phase.
;
; Entry   : BulletLines_generalZ
; Exit    : BulletLines_generalZ += 15.  All box endpoints shifted by (-1,-1).
;
; =============================================================================
proc SmallerInPlace

	add [BulletLines_generalZ], 15

	push -1
    push -1
    call AddXYToBulletsLines	
	

	ret
endp SmallerInPlace

; =============================================================================
; PROC AddXYToBulletsLines
; -----------------------------------------------------------------------------
; Purpose : Add a x/y offset to all 8 line endpoints of both
;           the left and right bullet boxes.
;
; Entry   : [bp+4] = deltaX
;           [bp+6] = deltaY
;
; Exit    : BulletLine X and Y fields updated.
;           AX preserved.
;
; =============================================================================
proc AddXYToBulletsLines
    push bp 
    mov bp, sp 
    push ax 

    ; LEFT gun - apply X delta normally
    mov ax, [bp+4] 
    add [BulletLine1_X0], ax 
    add [BulletLine1_X1], ax 
    add [BulletLine2_X0], ax 
    add [BulletLine2_X1], ax 
    add [BulletLine3_X0], ax 
    add [BulletLine3_X1], ax 
    add [BulletLine4_X0], ax 
    add [BulletLine4_X1], ax 

    ; RIGHT gun - apply NEGATED X delta (moves opposite direction)
    neg ax
    add [BulletLine1R_X0], ax
    add [BulletLine1R_X1], ax
    add [BulletLine2R_X0], ax
    add [BulletLine2R_X1], ax
    add [BulletLine3R_X0], ax
    add [BulletLine3R_X1], ax
    add [BulletLine4R_X0], ax
    add [BulletLine4R_X1], ax

    ; Y delta applies the same to both
    mov ax, [bp+6] 
    add [BulletLine1_Y0], ax 
    add [BulletLine1_Y1], ax 
    add [BulletLine2_Y0], ax 
    add [BulletLine2_Y1], ax 
    add [BulletLine3_Y0], ax 
    add [BulletLine3_Y1], ax 
    add [BulletLine4_Y0], ax 
    add [BulletLine4_Y1], ax 
	
    add [BulletLine1R_Y0], ax
    add [BulletLine1R_Y1], ax
    add [BulletLine2R_Y0], ax
    add [BulletLine2R_Y1], ax
    add [BulletLine3R_Y0], ax
    add [BulletLine3R_Y1], ax
    add [BulletLine4R_Y0], ax
    add [BulletLine4R_Y1], ax

    pop ax 
    pop bp
    ret 4 
endp AddXYToBulletsLines

; =============================================================================
; PROC HandleShootingGraphics
; -----------------------------------------------------------------------------
; Purpose : Render the player's bullet each frame as two small 3-D boxes
;           (left gun + right gun) by projecting each line endpoint with
;           Calc3D, then drawing the resulting screen-space lines via
;           Bresenham_GetPoints + DrawPoints.
;
; Entry   : BulletLine1-4 (left box) and BulletLine1R-4R (right box) endpoint
;           variables must contain current world-space coordinates.
;           BulletLines_generalZ – current Z depth shared by both boxes.
;
; Exit    : Lines drawn to secondBuffer.
;           AX, BX, CX, SI, DI preserved.
;
; =============================================================================
proc HandleShootingGraphics

    push ax
    push bx
    push cx
	push si 
	push di

    mov [byte ptr color], 78

    ; line 1
    mov ax, [BulletLine1_X0]
    mov bx, [BulletLine1_Y0]
    mov cx, [BulletLines_generalZ]
    call Calc3D
    mov [word ptr x0], di
    mov [word ptr y0], si
 
    mov ax, [BulletLine1_X1]
    mov bx, [BulletLine1_Y1]
    mov cx, [BulletLines_generalZ]
    call Calc3D
    mov [word ptr x1], di
    mov [word ptr y1], si
    call Bresenham_GetPoints
    call DrawPoints

	
    ; line 2
    mov ax, [BulletLine2_X0]
    mov bx, [BulletLine2_Y0]
    mov cx, [BulletLines_generalZ]
    call Calc3D
    mov [word ptr x0], di
    mov [word ptr y0], si

    mov ax, [BulletLine2_X1]
    mov bx, [BulletLine2_Y1]
    mov cx, [BulletLines_generalZ]
    call Calc3D
    mov [word ptr x1], di
    mov [word ptr y1], si
    call Bresenham_GetPoints
    call DrawPoints

    ; line 3
    mov ax, [BulletLine3_X0]
    mov bx, [BulletLine3_Y0]
    mov cx, [BulletLines_generalZ]
    call Calc3D
    mov [word ptr x0], di
    mov [word ptr y0], si

    mov ax, [BulletLine3_X1]
    mov bx, [BulletLine3_Y1]
    mov cx, [BulletLines_generalZ]
    call Calc3D
    mov [word ptr x1], di
    mov [word ptr y1], si
    call Bresenham_GetPoints
    call DrawPoints 
	
	; line 4
    mov ax, [BulletLine4_X0]
    mov bx, [BulletLine4_Y0]
    mov cx, [BulletLines_generalZ]
    call Calc3D
    mov [word ptr x0], di
    mov [word ptr y0], si

    mov ax, [BulletLine4_X1]
    mov bx, [BulletLine4_Y1]
    mov cx, [BulletLines_generalZ]
    call Calc3D
    mov [word ptr x1], di
    mov [word ptr y1], si
    call Bresenham_GetPoints
    call DrawPoints	
	
; right side line 1
    mov ax, [BulletLine1R_X0]
    mov bx, [BulletLine1R_Y0]
    mov cx, [BulletLines_generalZ]
    call Calc3D
    mov [word ptr x0], di
    mov [word ptr y0], si

    mov ax, [BulletLine1R_X1]
    mov bx, [BulletLine1R_Y1]
    mov cx, [BulletLines_generalZ]
    call Calc3D
    mov [word ptr x1], di
    mov [word ptr y1], si
    call Bresenham_GetPoints
    call DrawPoints

    ; right side line 2
    mov ax, [BulletLine2R_X0]
    mov bx, [BulletLine2R_Y0]
    mov cx, [BulletLines_generalZ]
    call Calc3D
    mov [word ptr x0], di
    mov [word ptr y0], si

    mov ax, [BulletLine2R_X1]
    mov bx, [BulletLine2R_Y1]
    mov cx, [BulletLines_generalZ]
    call Calc3D
    mov [word ptr x1], di
    mov [word ptr y1], si
    call Bresenham_GetPoints
    call DrawPoints

    ; right side line 3
    mov ax, [BulletLine3R_X0]
    mov bx, [BulletLine3R_Y0]
    mov cx, [BulletLines_generalZ]
    call Calc3D
    mov [word ptr x0], di
    mov [word ptr y0], si

    mov ax, [BulletLine3R_X1]
    mov bx, [BulletLine3R_Y1]
    mov cx, [BulletLines_generalZ]
    call Calc3D
    mov [word ptr x1], di
    mov [word ptr y1], si
    call Bresenham_GetPoints
    call DrawPoints

    ; right side line 4
    mov ax, [BulletLine4R_X0]
    mov bx, [BulletLine4R_Y0]
    mov cx, [BulletLines_generalZ]
    call Calc3D
    mov [word ptr x0], di
    mov [word ptr y0], si

    mov ax, [BulletLine4R_X1]
    mov bx, [BulletLine4R_Y1]
    mov cx, [BulletLines_generalZ]
    call Calc3D
    mov [word ptr x1], di
    mov [word ptr y1], si
    call Bresenham_GetPoints
    call DrawPoints

@@ret:
	pop di 
	pop si
    pop cx
    pop bx
    pop ax
	ret
endp HandleShootingGraphics
	
; =============================================================================
; PROC loadGunsCrosshair
; -----------------------------------------------------------------------------
; Purpose : Draw the player's gun aiming reticle (crosshair) onto the
;           secondary buffer each frame by rendering the GunsCrosshair
;           pixel-triplet array via DrawFromPixelArray.
;
; Entry   : GunsCrosshair - pixel-triplet array (X, Y, Color) defining the
;                           crosshair shape at its fixed screen position.
;
; Exit    : GunsCrosshair pixels written to secondBuffer.
;
; =============================================================================
proc loadGunsCrosshair
	
	push offset GunsCrosshair
	call DrawFromPixelArray
	
	ret
endp loadGunsCrosshair

; =============================================================================
; PROC playStartCutscene
; -----------------------------------------------------------------------------
; Purpose : Play the one-time intro cutscene shown before the first game
;           session.  Displays three full-screen story BMP images in sequence,
;           each accompanied by its own audio track played via PlaySong.
;           Sets cutScenePlayed = 1 so the cutscene is never shown again in
;           the same session.
;           Also calls PlayRunwayCutscene, showing the player's plane taking off.
;           On any file error, prints an error message and exits early.
;
; Entry   : cutScenePlayed - 0 (checked before)
;           FileLoadngPlay1/2/3Bmp - filenames of the three story screens.
;           InstFile1/2/3          - filenames of the three audio tracks.
;
; Exit    : cutScenePlayed = 1.
;           Three BMP+audio pairs shown and played in order.
;           secondBuffer updated and blitted for each frame via TransitionBuffer.
;           FileError = 1 on any file open failure (error message printed).
;           DX preserved.
;
; Arbitrary numbers explained:
;   320  - full screen width  in pixels (VGA Mode 13h).
;   200  - full screen height in pixels (VGA Mode 13h).
;   Both values fill the entire display so each cutscene image covers the
;   whole screen with no border.
; =============================================================================
proc playStartCutscene 
	push dx
	
	mov [cutScenePlayed], 1
	
	mov dx, offset FileLoadngPlay1Bmp
    mov [FileNamePtr], dx
    mov [BmpLeft], 0
    mov [BmpTop], 0
    mov [BmpWidth], 320
    mov [BmpHeight], 200
    call OpenShowBmp
	call TransitionBuffer
    cmp [FileError], 1
	jne @@continue
    jmp @@exitError
@@continue:
	push offset InstFile1
	call PlaySong
	
	mov dx, offset FileLoadngPlay2Bmp
    mov [FileNamePtr], dx
    mov [BmpLeft], 0
    mov [BmpTop], 0
    mov [BmpWidth], 320
    mov [BmpHeight], 200
    call OpenShowBmp
	call TransitionBuffer
    cmp [FileError], 1
    je @@exitError
	
	push offset InstFile2
	call PlaySong
	
	mov dx, offset FileLoadngPlay3Bmp
    mov [FileNamePtr], dx
    mov [BmpLeft], 0
    mov [BmpTop], 0
    mov [BmpWidth], 320
    mov [BmpHeight], 200
    call OpenShowBmp
	call TransitionBuffer
    cmp [FileError], 1
    je @@exitError
	
	push offset InstFile3
	call PlaySong
	
	call PlayRunwayCutscene
	jmp @@ret

@@exitError:
    mov dx, offset BmpFileErrorMsg
    mov ah, 9
    int 21h

@@ret:
	pop dx
	ret
endp playStartCutscene

; =============================================================================
; PROC PlayRunwayCutscene
; -----------------------------------------------------------------------------
; Purpose : Display a runway scene as the final frame of the intro
;           cutscene, giving the impression the player's aircraft is taking off.
;           Holds the image on screen and shows the player taking off.
;
; Entry   : AircraftRunwayBmp - filename of the runway scene BMP asset.
;           Player's Aircraft spries in different sizes.
;           secondBuffer      - off-screen render target.
;
; Exit    : Runway BMP rendered to secondBuffer and blitted to the screen. Player taking off.
;
; =============================================================================
proc PlayRunwayCutscene
	
	call fillAround
	mov dx, offset AircraftRunwayBmp
	mov [fileNamePtr], dx
	mov [bmpWidth], 112 
	mov [BmpHeight], 70
	mov [BmpTop], 120
	mov [BmpLeft], 100
	call OpenShowBmp
	call TransitionBuffer
		
		
	; in futere develpoment: here ill show the player plane getting smaller as moves
	; up the runway
	call _400MiliSecDelay
	call _400MiliSecDelay
	call _400MiliSecDelay
	call _400MiliSecDelay
	
	


	ret
endp PlayRunwayCutscene

; =============================================================================
; PROC DrawFromPixelArray
; -----------------------------------------------------------------------------
; Purpose : Iterate through a pixel-triplet array (X, Y, Color word triplets)
;           and plot each valid, in-bounds pixel into secondBuffer.
;           Skips any pixel whose X or Y falls outside the screen boundary.
;           Stops at three consecutive zero words: 0,0,0.
;
; Entry   : [bp+4] = offset of the pixel-triplet array to draw.
;           Each entry is 3 words: [X word][Y word][Color word].
;           Array must be terminated by 0, 0, 0.
;           secondBuffer - off-screen render target in its own segment.
;
; Exit    : All in-bounds, non-sentinel pixels written to secondBuffer.
;           The 2-byte stack argument is cleaned up by the procedure (ret 2).
;           AX, BX, CX, DX, DI, SI, ES preserved.
;
; =============================================================================
proc DrawFromPixelArray
	push bp
	mov bp, sp
	push ax
	push bx
	push cx
	push dx
	push di
	push si
	push es
	
	mov ax, seg secondBuffer
	mov es, ax
	
	; get offset pushed
	mov si, [bp+4]

@@drawLoop:
	cmp [word ptr si], 0
	jne @@ok
	cmp [word ptr si+2], 0
	jne @@ok
	cmp [word ptr si+4], 0
	je @@ret
@@ok:
	xor cx, cx
	xor dx, dx
	
	mov cx, [si]
	
	mov dx, [si+2]
	
	
    ; --- Bounds check X ---
    cmp cx, 0
    jl @@skip          ; skip if x < 0
    cmp cx, 319
    jg @@skip          ; skip if x > 319

    ; --- Bounds check Y ---
    cmp dx, 0
    jl @@skip          ; skip if y < 0
    cmp dx, 199
    jg @@skip          ; skip if y > 199
	
	mov ax, dx
	mov di, 320
	mul di
	add ax, cx
	mov di, ax
	
	mov ax, [si+4]
	mov [es:di], al
	
@@skip:
	add si, 6
	
	jmp @@drawLoop
	
@@ret:
	pop es
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret 2
endp DrawFromPixelArray

; ============================================================
; HandleEnemy2 - same logic as HandleEnemy but uses Enemy2 state
; ============================================================
proc HandleEnemy2
	push cx

	cmp [Enemy2Active], 1
	je @@dontWait 
	jmp @@waitDelay
@@dontWait:
	cmp [enemyLeft2], 1
	jne @@regular
	mov [DisappearNow2], 0
	inc [enemyLeftTimer2]
	cmp [enemyLeftTimer2], 70
	jnge @@regular
	mov [DisappearNow2], 1
@@regular:
    cmp [EnemyDeadByFire2], 1
	jne @@checkDeadDisappear
	jmp @@ShowEnemyExploding
@@checkDeadDisappear:
    cmp [isDead2], 1
    jne @@alreadyExists
    jmp @@MakeNewEnemy
@@alreadyExists:
	cmp [DisappearNow2], 1
	je @@startDisappear
	mov di, offset Enemy2Normal

@@normal:
	push di
	push 147
	mov bl, 10
	mov dl, 30
	call RandomByCsW
	mov [Xval], ax 
	mov bx, [horizonLine]
	sub bx, ax 
	push bx 
	call MoveEnemy2ToBoundry
	push di
	call DrawFromPixelArray
@@checkDisappear:
	clc
	push 147
	mov ax, [Xval]
	mov bx, [horizonLine]
	sub bx, ax 
	push bx
	call WaitToDisappear2
	jc @@continueRegular
	jmp @@ret
@@continueRegular:
	mov [DisappearNow2], 1
	jmp @@ret
@@startDisappear:
	call EnemyDisappearStep2
	cmp [isDead2], 1
	jne @@continueDisappear
	jmp @@ret 
@@continueDisappear:
	push di
	;cmp [isLeft], 0
	;;je @@left
	cmp [enemyLeft2], 1
	jne @@moveRight 
@@moveLeft:
	push offset Enemy2Normal
	push 339
	push 20
	call MoveEnemy2ToBoundry
	jmp @@skip
@@moveRight:
	push offset Enemy2Normal
	push 20
	push 20
	call MoveEnemy2ToBoundry
;	jmp @@skip
;@@left:
;	push offset EnemyNormal
;	push 180
;	push 20
;	call MoveEnemyToBoundry
@@skip:
	call SyncAllEnemies2
	pop di
	push di
	call DrawFromPixelArray
	jmp @@ret

@@ShowEnemyExploding:
	; simple: use KillEnemy but with Enemy2 coords
	; we reuse KillEnemy by temporarily copying EnemyX/Y
	push [EnemyX2]
	push [EnemyY2]
	pop [EnemyY]
	pop [EnemyX]
	call KillEnemy
	push [EnemyX]
	push [EnemyY]
	pop [EnemyY2]
	pop [EnemyX2]
	jnc @@ret
	mov [isExploded2], 1

@@MakeNewEnemy:
    mov [EnemyDeadByFire2], 0
    mov [isExploded2], 0
    mov [StageOneEnemyExplosionComplete2], 0
    mov [WaitForEnemyExp2_2], 0
    mov [isDead2], 0
	mov [normalLeftTImer2], 0
	mov [enemyLeftTimer2], 0
	mov [enemyLeft2], 0
	mov [Enemy2Active], 0
	mov [Enemy2DelayTimer], 0
    call resetVariabels2
    call SpawnEnemy2OnRandomCorner

@@waitDelay:
	; not active yet - count frames
	inc [Enemy2DelayTimer]
	cmp [Enemy2DelayTimer], 30    ; 1 second at 30fps
	jl @@ret
	; activate
	mov [Enemy2Active], 1
	mov [Enemy2DelayTimer], 0
	call resetVariabels2
	call SpawnEnemy2OnRandomCorner

@@ret:
	pop cx
	ret
endp HandleEnemy2

; ============================================================
; HandleEnemy3 - same logic, uses Enemy3 state
; ============================================================
proc HandleEnemy3
	push cx

	cmp [Enemy3Active], 1
	je @@dontWait
	jmp @@waitDelay
@@dontWait:
	cmp [enemyLeft3], 1
	jne @@regular
	mov [DisappearNow3], 0
	inc [enemyLeftTimer3]
	cmp [enemyLeftTimer3], 70
	jnge @@regular
	mov [DisappearNow3], 1
@@regular:
    cmp [EnemyDeadByFire3], 1
	jne @@checkDeadDisappear
	jmp @@ShowEnemyExploding
@@checkDeadDisappear:
    cmp [isDead3], 1
    jne @@alreadyExists
    jmp @@MakeNewEnemy
@@alreadyExists:
	cmp [DisappearNow3], 1
	je @@startDisappear
	mov di, offset Enemy3Normal

@@normal:
	push di
	push 147
	mov bl, 40
	mov dl, 100
	call RandomByCsW
	mov [Xval], ax
	mov bx, [horizonLine]
	sub bx, ax 
	push bx 	
	call MoveEnemy3ToBoundry
	push di
	call DrawFromPixelArray
@@checkDisappear3:
	clc
	push 147
	mov ax, [Xval]
	mov bx, [horizonLine]
	sub bx, ax 
	push bx 
	call WaitToDisappear3
	jc @@continueRegular
	jmp @@ret
@@continueRegular:
	mov [DisappearNow3], 1
	jmp @@ret
@@startDisappear:
	call EnemyDisappearStep3
	cmp [isDead3], 1
	jne @@continueDisappear
	jmp @@ret
@@continueDisappear:
    push di
    cmp [enemyLeft3], 1
    jne @@moveRight
@@moveLeft:
    push offset Enemy3Normal
    push 339
    push 20
    call MoveEnemy3ToBoundry
    jmp @@skip
@@moveRight:
    push offset Enemy3Normal
    push 20
    push 20
    call MoveEnemy3ToBoundry
@@skip:
    call SyncAllEnemies3
    pop di
    push di
    call DrawFromPixelArray
    jmp @@ret

@@ShowEnemyExploding:
	push [EnemyX3]
	push [EnemyY3]
	pop [EnemyY]
	pop [EnemyX]
	call KillEnemy
	push [EnemyX]
	push [EnemyY]
	pop [EnemyY3]
	pop [EnemyX3]
	jnc @@ret
	mov [isExploded3], 1

@@MakeNewEnemy:
    mov [EnemyDeadByFire3], 0
    mov [isExploded3], 0
    mov [StageOneEnemyExplosionComplete3], 0
    mov [WaitForEnemyExp2_3], 0
    mov [isDead3], 0
	mov [normalLeftTImer3], 0
	mov [enemyLeftTimer3], 0
	mov [enemyLeft3], 0
	mov [Enemy3Active], 0
	mov [Enemy3DelayTimer], 0
    call resetVariabels3
    call SpawnEnemy3OnRandomCorner

@@waitDelay:
	inc [Enemy3DelayTimer]
	cmp [Enemy3DelayTimer], 60    ; 2 seconds at 30fps
	jl @@ret
	mov [Enemy3Active], 1
	mov [Enemy3DelayTimer], 0
	call resetVariabels3
	call SpawnEnemy3OnRandomCorner

@@ret:
	pop cx
	ret
endp HandleEnemy3

; ============================================================
proc MoveEnemy2ToBoundry
	push bp
	mov bp, sp
	push cx
	push dx

	mov dx, [bp+4]
	mov cx, [bp+6]
	mov di, [bp+8]

	shl [EnemyStayAtPlaceTimer2], 8
	jnc @@checkX2
	mov [EnemyStayAtPlaceTimer2], 1

@@checkY2:
	cmp [di+2], dx
	je @@checkBoth2
	jl @@moreY2
@@lessY2:
	push di
	push 2
	push -1
	call AddXToOffsetInArray
	jmp @@checkX2
@@moreY2:
	push di
	push 2
	push 1
	call AddXToOffsetInArray
	jmp @@checkX2
@@checkBoth2:
	mov ax, cx
	sub ax, [di]
	cmp ax, -10
	jl @@checkX2
	cmp ax, 10
	jg @@checkX2
	jmp @@bothEqual2
@@checkX2:
	mov bx, 2
	mov dx, 3
	call RandomByCsW
	cmp [cxMODE2], 2
	jng @@continue2
	mov ax, 1
@@continue2:
	cmp [di], cx
	je @@ret2
	jl @@moreX2
@@lessX2:
	push di
	push 0
	neg ax
	push ax
	call AddXToOffsetInArray
	mov [isLeft2], 1
	jmp @@ret2
@@moreX2:
	push di
	push 0
	push ax
	call AddXToOffsetInArray
	mov [isLeft2], 0
	jmp @@ret2
@@bothEqual2:
	mov [isForawrd2], 1
@@ret2:
	pop dx
	pop cx
	pop bp
	ret 6
endp MoveEnemy2ToBoundry

proc MoveEnemy3ToBoundry
	push bp
	mov bp, sp
	push cx
	push dx

	mov dx, [bp+4]
	mov cx, [bp+6]
	mov di, [bp+8]

	shl [EnemyStayAtPlaceTimer3], 8
	jnc @@checkX3
	mov [EnemyStayAtPlaceTimer3], 1

@@checkY3:
	cmp [di+2], dx
	je @@checkBoth3
	jl @@moreY3
@@lessY3:
	push di
	push 2
	push -1
	call AddXToOffsetInArray
	jmp @@checkX3
@@moreY3:
	push di
	push 2
	push 1
	call AddXToOffsetInArray
	jmp @@checkX3
@@checkBoth3:
	mov ax, cx
	sub ax, [di]
	cmp ax, -10
	jl @@checkX3
	cmp ax, 10
	jg @@checkX3
	jmp @@bothEqual3
@@checkX3:
	mov bx, 2
	mov dx, 3
	call RandomByCsW
	cmp [cxMODE3], 2
	jng @@continue3
	mov ax, 1
@@continue3:
	cmp [di], cx
	je @@ret3
	jl @@moreX3
@@lessX3:
	push di
	push 0
	neg ax
	push ax
	call AddXToOffsetInArray
	mov [isLeft3], 1
	jmp @@ret3
@@moreX3:
	push di
	push 0
	push ax
	call AddXToOffsetInArray
	mov [isLeft3], 0
	jmp @@ret3
@@bothEqual3:
	mov [isForawrd3], 1
@@ret3:
	pop dx
	pop cx
	pop bp
	ret 6
endp MoveEnemy3ToBoundry

proc WaitToDisappear2
	push bp
	mov bp, sp
	push ax
	push bx

	clc
	mov ax, [bp+6]
	mov bx, [bp+4]
	mov di, offset Enemy2Normal
	mov cx, [di]
	sub cx, ax
	cmp cx, -4
	jl @@ret2
	cmp cx, 4
	jg @@ret2
	mov cx, [di+2]
	sub cx, bx
	cmp cx, -4
	jl @@ret2
	cmp cx, 4
	jg @@ret2
	mov [DisappearNow2], 1
	stc
@@ret2:
	pop bx
	pop ax
	pop bp
	ret 4
endp WaitToDisappear2

proc WaitToDisappear3
	push bp
	mov bp, sp
	push ax
	push bx

	clc
	mov ax, [bp+6]
	mov bx, [bp+4]
	mov di, offset Enemy3Normal
	mov cx, [di]
	sub cx, ax
	cmp cx, -4
	jl @@ret3
	cmp cx, 4
	jg @@ret3
	mov cx, [di+2]
	sub cx, bx
	cmp cx, -4
	jl @@ret3
	cmp cx, 4
	jg @@ret3
	mov [DisappearNow3], 1
	stc
@@ret3:
	pop bx
	pop ax
	pop bp
	ret 4
endp WaitToDisappear3

proc EnemyDisappearStep2
    push ax
    push bx
    push cx

    call SetCXbyTime2

    cmp cx, 100
    jnle @@close2
    mov di, offset Enemy2Normal
    jmp @@ret2
@@close2:
    cmp cx, 200
    jnle @@middle2
    mov di, offset EnemyClose2     
    jmp @@ret2
@@middle2:
    cmp cx, 300
    jnle @@far2
    mov di, offset EnemyMiddle2    
    jmp @@ret2
@@far2:
    cmp cx, 400
    jnle @@isDead2
    mov di, offset EnemyFar2        
    jmp @@ret2
@@isDead2:
    mov [isDead2], 1

@@ret2:
    pop cx
    pop bx
    pop ax
    ret
endp EnemyDisappearStep2

proc EnemyDisappearStep3
    push ax
    push bx
    push cx

    call SetCXbyTime3

    cmp cx, 100
    jnle @@close3
    mov di, offset Enemy3Normal
    jmp @@ret3
@@close3:
    cmp cx, 200
    jnle @@middle3
    mov di, offset EnemyClose3
    jmp @@ret3
@@middle3:
    cmp cx, 300
    jnle @@far3
    mov di, offset EnemyMiddle3
    jmp @@ret3
@@far3:
    cmp cx, 400
    jnle @@isDead3
    mov di, offset EnemyFar3
    jmp @@ret3
@@isDead3:
    mov [isDead3], 1
@@ret3:
    pop cx
    pop bx
    pop ax
    ret
endp EnemyDisappearStep3

proc SyncAllEnemies2
    push di



	mov si, offset EnemyClose2
	mov di, offset Enemy2Normal
	mov ax, [di]
	
	mov bx, [si]
	
	sub ax, bx
	
	push offset EnemyClose2
	push 0
	push ax
	call AddXToOffsetInArray
	
	mov ax, [di+2]
	
	mov bx, [si+2]
	
	sub ax, bx
	
	push offset EnemyClose2
	push 2
	push ax
	call AddXToOffsetInArray

	mov si, offset EnemyMiddle2
	mov di, offset Enemy2Normal
	mov ax, [di]
	
	mov bx, [si]
	
	sub ax, bx
	
	push offset EnemyMiddle2
	push 0
	push ax
	call AddXToOffsetInArray
	
	mov ax, [di+2]
	
	mov bx, [si+2]
	
	sub ax, bx
	
	push offset EnemyMiddle2
	push 2
	push ax
	call AddXToOffsetInArray

	mov si, offset EnemyFar2
	mov di, offset Enemy2Normal
	mov ax, [di]
	
	mov bx, [si]
	
	sub ax, bx
	
	push offset EnemyFar2
	push 0
	push ax
	call AddXToOffsetInArray
	
	mov ax, [di+2]
	
	mov bx, [si+2]
	
	sub ax, bx
	
	push offset EnemyFar2
	push 2
	push ax
	call AddXToOffsetInArray
	
	

    pop di
    ret
endp SyncAllEnemies2

proc SyncAllEnemies3
    push di



	mov si, offset EnemyClose3
	mov di, offset Enemy3Normal
	mov ax, [di]
	
	mov bx, [si]
	
	sub ax, bx
	
	push offset EnemyClose3
	push 0
	push ax
	call AddXToOffsetInArray
	
	mov ax, [di+2]
	
	mov bx, [si+2]
	
	sub ax, bx
	
	push offset EnemyClose3
	push 2
	push ax
	call AddXToOffsetInArray

	mov si, offset EnemyMiddle3
	mov di, offset Enemy3Normal
	mov ax, [di]
	
	mov bx, [si]
	
	sub ax, bx
	
	push offset EnemyMiddle3
	push 0
	push ax
	call AddXToOffsetInArray
	
	mov ax, [di+2]
	
	mov bx, [si+2]
	
	sub ax, bx
	
	push offset EnemyMiddle3
	push 2
	push ax
	call AddXToOffsetInArray

	mov si, offset EnemyFar3
	mov di, offset Enemy3Normal
	mov ax, [di]
	
	mov bx, [si]
	
	sub ax, bx
	
	push offset EnemyFar3
	push 0
	push ax
	call AddXToOffsetInArray
	
	mov ax, [di+2]
	
	mov bx, [si+2]
	
	sub ax, bx
	
	push offset EnemyFar3
	push 2
	push ax
	call AddXToOffsetInArray
	
    pop di
    ret
endp SyncAllEnemies3

proc SetCXbyTime2
	shl [CxSizeTimer2], 1
	jnc @@calc2
	cmp [cxMODE2], 4
	jg @@ret2
	inc [cxMODE2]
	mov [CxSizeTimer2], 1
@@calc2:
	xor cx, cx
	mov ax, [cxMODE2]
	mov bx, 100
	mul bx
	add cx, ax
@@ret2:
	ret
endp SetCXbyTime2

proc SetCXbyTime3
	shl [CxSizeTimer3], 1
	jnc @@calc3
	cmp [cxMODE3], 4
	jg @@ret3
	inc [cxMODE3]
	mov [CxSizeTimer3], 1
@@calc3:
	xor cx, cx
	mov ax, [cxMODE3]
	mov bx, 100
	mul bx
	add cx, ax
@@ret3:
	ret
endp SetCXbyTime3

proc resetVariabels2
	push di
	call setPosToFixedArray2
	mov [disappearLevel2], 0
	mov [DisappearNow2], 0
	mov [cxMODE2], 0
	mov [CxSizeTimer2], 1
	pop di
	ret
endp resetVariabels2

proc resetVariabels3
	push di
	call setPosToFixedArray3
	mov [disappearLevel3], 0
	mov [DisappearNow3], 0
	mov [cxMODE3], 0
	mov [CxSizeTimer3], 1
	pop di
	ret
endp resetVariabels3

proc setPosToFixedArray2
	push si
	push di
	push ax
	mov si, offset Enemy2NormalFixed
	mov di, offset Enemy2Normal
@@loop2:
	cmp [word ptr si], 0
	jne @@ok2
	cmp [word ptr si+2], 0
	jne @@ok2
	cmp [word ptr si+4], 0
	je @@ret2
@@ok2:
	mov ax, [si]
	mov [di], ax
	mov ax, [si+2]
	mov [di+2], ax
	mov ax, [si+4]
	mov [di+4], ax
	add si, 6
	add di, 6
	jmp @@loop2
@@ret2:
	pop ax
	pop di
	pop si
	ret
endp setPosToFixedArray2

proc setPosToFixedArray3
	push si
	push di
	push ax
	mov si, offset Enemy3NormalFixed
	mov di, offset Enemy3Normal
@@loop3:
	cmp [word ptr si], 0
	jne @@ok3
	cmp [word ptr si+2], 0
	jne @@ok3
	cmp [word ptr si+4], 0
	je @@ret3
@@ok3:
	mov ax, [si]
	mov [di], ax
	mov ax, [si+2]
	mov [di+2], ax
	mov ax, [si+4]
	mov [di+4], ax
	add si, 6
	add di, 6
	jmp @@loop3
@@ret3:
	pop ax
	pop di
	pop si
	ret
endp setPosToFixedArray3

proc SpawnEnemy2OnRandomCorner
	push ax
	push bx
	push dx
	push cx

	push offset Enemy2Normal
	push 2
	push 140
	call AddXToOffsetInArray

	mov bx, 0
	mov dx, 1
	call RandomByCsW

	cmp ax, 0
	je @@isRight2
	mov [enemyLeft2], 1
	jmp @@ret2

@@isRight2:
	mov ax, 269
	push offset Enemy2Normal
	push 0
	push ax
	call AddXToOffsetInArray

@@ret2:
	pop cx
	pop dx
	pop bx
	pop ax
	ret
endp SpawnEnemy2OnRandomCorner

proc SpawnEnemy3OnRandomCorner
	push ax
	push bx
	push dx
	push cx

	push offset Enemy3Normal
	push 2
	push 140
	call AddXToOffsetInArray

	mov bx, 0
	mov dx, 1
	call RandomByCsW

	cmp ax, 0
	je @@isRight3
	mov [enemyLeft3], 1
	jmp @@ret3

@@isRight3:
	mov ax, 269
	push offset Enemy3Normal
	push 0
	push ax
	call AddXToOffsetInArray

@@ret3:
	pop cx
	pop dx
	pop bx
	pop ax
	ret
endp SpawnEnemy3OnRandomCorner



; =============================================================================
; PROC HandleEnemy
; -----------------------------------------------------------------------------
; Purpose : Per-frame handler for Enemy 1. Futere being for all.
;           Manages the full enemy lifecycle: left-side timer, fire-death,
;           normal flight, disappear trigger, shrink animation, and respawn.
;
; Entry   : enemyLeft        - 1 if enemy spawned on the left side.
;           enemyLeftTimer   - frames elapsed since left-side spawn.
;           EnemyDeadByFire  - 1 if enemy was shot by the player.
;           isDead           - 1 if enemy has finished its death sequence.
;           DisappearNow     - 1 if shrink/disappear sequence should run.
;           horizonLine      - current horizon Y coordinate.
;
; Exit    : Enemy drawn or removed from screen.
;           isDead, enemyLeft, enemyLeftTimer, DisappearNow updated as needed.
;           On respawn: all Enemy 1 state variables reset,
;           new position assigned via SpawnEnemyOnRandomCorner.
;
; Arbitrary numbers explained:
;   70  - A number fitting until the enemy should disappear, allows for speed to match right.
;   147 - target X before triggering Disappear.
;   20  - target Y before triggering Disappear.
;   339 - target X before triggering Disappear (For Left).
; =============================================================================
proc HandleEnemy
	push cx
	
	cmp [enemyLeft], 1
	jne @@regular
	mov [DisappearNow], 0
	inc [enemyLeftTimer]
	cmp [enemyLeftTimer], 70
	jnge @@regular 
	mov [DisappearNow], 1
@@regular:
    cmp [EnemyDeadByFire], 1
	jne @@checkDeadDisappear
	jmp @@ShowEnemyExploding
@@checkDeadDisappear:
    cmp [isDead], 1
    jne @@alreadyExists
    jmp @@MakeNewEnemy
@@alreadyExists:

	cmp [DisappearNow], 1
	je @@startDisappear
	mov di, offset EnemyNormal

	
	
@@normal:
	push 0
	push di
	push 147
	mov bl, 40
	mov dl, 100
	call RandomByCsW
	mov [Xval], ax
	mov bx, [horizonLine]
	sub bx, ax 
	push bx 
	call MoveEnemyToBoundry
	push di
	call DrawFromPixelArray

@@checkDisappear:
	clc
	push 147
	mov ax, [Xval]
	mov bx, [horizonLine]
	sub bx, ax 
	push bx 	
	call WaitToDisappear
	jc @@continueRegular
	jmp @@ret
@@continueRegular:
	mov [DisappearNow], 1
	jmp @@ret
@@startDisappear:
	call EnemyDisappearStep
	cmp [isDead], 1
	jne @@continueDisappear
	jmp @@ret 
@@continueDisappear:
	push di
	cmp [enemyLeft], 1
	jne @@moveRight 
@@moveLeft:
	push 0
	push offset EnemyNormal
	push 339
	push 20
	call MoveEnemyToBoundry
	jmp @@skip
@@moveRight:
	push 0 
	push offset EnemyNormal
	push 20
	push 20
	call MoveEnemyToBoundry

@@skip:
	call SyncAllEnemies
	pop di
	push di
	call DrawFromPixelArray
	jmp @@ret
@@ShowEnemyExploding:
	call KillEnemy
	jc @@MakeNewEnemy
	jmp @@ret
@@MakeNewEnemy:
    mov [EnemyDeadByFire], 0
    mov [StageOneEnemyExplosionComplete], 0
    mov [WaitForEnemyExp2], 0
    mov [isDead], 0
	mov [normalLeftTImer], 0
	mov [enemyLeftTimer], 0
	mov [enemyLeft], 0
    call resetVariabels
    call SpawnEnemyOnRandomCorner



@@ret:
	pop cx
	ret
endp HandleEnemy

; =============================================================================
; PROC SyncAllEnemies
; -----------------------------------------------------------------------------
; Purpose : After Enemy 1's Normal sprite is moved, move the same
;           positional delta to the Close, Middle, and Far size sprite's array so
;           all four sprites stay at the same relative screen location.
;
; Entry   : EnemyNormal[0]  - current X of the reference (normal-size) sprite.
;           EnemyNormal[2]  - current Y of the reference sprite.
;           EnemyClose, EnemyMiddle, EnemyFar - last-synced positions of the
;           smaller variants (each is a pixel-triplet array).
;
; Exit    : EnemyClose, EnemyMiddle, EnemyFar X and Y fields shifted by the
;           same delta that was applied to EnemyNormal since last sync.
;           Registers Preserved.
;
; =============================================================================
proc SyncAllEnemies
	push di
	push si
	push ax 
	push bx
	
	


	mov si, offset EnemyClose
	mov di, offset EnemyNormal
	mov ax, [di]
	
	mov bx, [si]
	
	sub ax, bx
	
	push offset EnemyClose
	push 0
	push ax
	call AddXToOffsetInArray
	
	mov ax, [di+2]
	
	mov bx, [si+2]
	
	sub ax, bx
	
	push offset EnemyClose
	push 2
	push ax
	call AddXToOffsetInArray

	mov si, offset EnemyMiddle
	mov di, offset EnemyNormal
	mov ax, [di]
	
	mov bx, [si]
	
	sub ax, bx
	
	push offset EnemyMiddle
	push 0
	push ax
	call AddXToOffsetInArray
	
	mov ax, [di+2]
	
	mov bx, [si+2]
	
	sub ax, bx
	
	push offset EnemyMiddle
	push 2
	push ax
	call AddXToOffsetInArray

	mov si, offset EnemyFar
	mov di, offset EnemyNormal
	mov ax, [di]
	
	mov bx, [si]
	
	sub ax, bx
	
	push offset EnemyFar
	push 0
	push ax
	call AddXToOffsetInArray
	
	mov ax, [di+2]
	
	mov bx, [si+2]
	
	sub ax, bx
	
	push offset EnemyFar
	push 2
	push ax
	call AddXToOffsetInArray
	
	pop bx 
	pop ax 
	pop si
	pop di
	ret
endp SyncAllEnemies

; =============================================================================
; PROC resetVariabels
; -----------------------------------------------------------------------------
; Purpose : Restore Enemy 1 to its canonical starting state ready for a
;           fresh spawn.  Copies the fixed coordinate table back
;           into the live EnemyNormal array, resets all animation counters, etc..
;
; Entry   : EnemyNormalFixed - read-only reference array with original coords.
;
; Exit    : EnemyNormal      - overwritten with EnemyNormalFixed fixed values.
;			important related values like:
;           disappearLevel   - 0 (no disappear frames consumed).
;           DisappearNow     - 0 (disappear sequence not active).
;           cxMODE           - 0 (size stage counter reset).
;           CxSizeTimer      - 1 (shift-register timer reset to initial state).
;
; =============================================================================
proc resetVariabels
	call setPosToFixedArray
	mov [disappearLevel], 0
	mov [DisappearNow], 0
	mov [cxMODE], 0
	mov [CxSizeTimer], 1
	mov [EnemyDeadByFire], 0
    mov [StageOneEnemyExplosionComplete], 0
    mov [WaitForEnemyExp2], 0
    mov [isDead], 0
	mov [normalLeftTImer], 0
	mov [enemyLeftTimer], 0
	mov [enemyLeft], 0
	
	ret
endp resetVariabels

; =============================================================================
; PROC setPosToFixedArray
; -----------------------------------------------------------------------------
; Purpose : Copy every (X, Y, Color) triplet from EnemyNormalFixed into
;           EnemyNormal, effectively restoring the sprite to its original
;           design-time position.  Stops at the sentry '0, 0, 0'.
;
; Entry   : EnemyNormalFixed - source array of word triplets, terminated by
;                              three consecutive zero words.
;           EnemyNormal      - destination array of the same layout.
;
; Exit    : EnemyNormal contains an exact copy of EnemyNormalFixed up to and
;           including the sentinel.
;           SI, DI, AX preserved.
;
; Arbitrary numbers explained:
;   6  - byte size of one pixel triplet (3 words x 2 bytes = 6 bytes);
;        SI and DI are advanced by 6 after each copied entry.
; =============================================================================
proc setPosToFixedArray
    push si 
    push di
    push ax
    
    mov si, offset EnemyNormalFixed
    mov di, offset EnemyNormal
    
@@replaceWithFixed:
    cmp [word ptr si], 0
    jne @@ok
    cmp [word ptr si+2], 0
    jne @@ok
    cmp [word ptr si+4], 0
    je @@ret
@@ok:
    mov ax, [si]
    mov [di], ax
    mov ax, [si+2]
    mov [di+2], ax
    mov ax, [si+4]
    mov [di+4], ax
    add si, 6
    add di, 6
    jmp @@replaceWithFixed

@@ret:
    pop ax
    pop di
    pop si
    ret
endp setPosToFixedArray

; =============================================================================
; PROC EnemyDisappearStep
; -----------------------------------------------------------------------------
; Purpose : Each frame during Enemy 1's shrink sequence, select the correct
;           size-variant sprite by reading the time-based CX counter, and
;           load its offset into DI for the caller to draw.
;           When CX exceeds 400 the enemy is marked dead.
;
; Entry   : cxMODE / CxSizeTimer - consumed by SetCXbyTime to produce CX.
;
; Exit    : DI = offset of the sprite to draw this frame:
;             CX <= 100  EnemyNormal  (full size, still close)
;             CX <= 200  EnemyClose   (slightly smaller)
;             CX <= 300  EnemyMiddle  (medium distance)
;             CX <= 400  EnemyFar     (small / far)
;             CX >  400  isDead set to 1, DI unchanged.
;           AX, BX, CX preserved.
;
; Arbitrary numbers explained:
;   100, 200, 300, 400 - CX thresholds corresponding to cxMODE values 1-4
;                        (each mode = 100 units); four stages of shrink before
;                        the sprite is considered gone.
; =============================================================================
proc EnemyDisappearStep
	push ax
	push bx
	push cx
	
	
	call SetCXbyTime
	
	cmp cx, 100
	jnle @@close
	mov di, offset EnemyNormal
	jmp @@ret
@@close:
	cmp cx, 200
	jnle @@middle
	mov di, offset EnemyClose
	jmp @@ret
@@middle:
	cmp cx, 300
	jnle @@far
	mov di, offset EnemyMiddle
	jmp @@ret
@@far:
	cmp cx, 400
	jnle @@isDead
	mov di, offset EnemyFar
	jmp @@ret
@@isDead:
	mov [isDead], 1
	jmp @@ret
	
	
;	push cx
;@@getRes:
;	sub bx, 2
;	sub ax, 8
;	sub cl, 1
;	cmp cl, 1
;	jne @@getRes
;	pop cx
	
;@@skip:
;	push [disappearLevel]
;	push offset EnemyNormal	

;	add cl, '0'
;	mov di, offset bmpDisappearEnemy
;	mov [di+3], cl
;	mov dx, offset bmpDisappearEnemy

@@ret:
	pop cx
	pop bx
	pop ax
	ret
endp EnemyDisappearStep

; =============================================================================
; PROC MoveEnemyToBoundry
; -----------------------------------------------------------------------------
; Purpose : Move every pixel in the given enemy sprite array one step toward
;           a target (X, Y) screen position.  Uses a shift-register timer
;           (EnemyStayAtPlaceTimer) to add a brief per-axis pause.
;
; Entry   : [bp+4]  = target Y screen coordinate.
;           [bp+6]  = target X screen coordinate.
;           [bp+8]  = DI - offset of the pixel-triplet array to move.
;           [bp+10] = AX - initial step size (overridden by random if ax = 0).
;           EnemyStayAtPlaceTimer - shift-register that gates movement.
;
; Exit    : Every pixel's X  Y in the array shifted one step toward target.
;           isLeft  - set to 1 if moving left, 0 if moving right.
;           isForawrd - set to 1 when X and Y both within ±10 of target.
;
;           All registers preserved.
;
; =============================================================================
proc MoveEnemyToBoundry
	push bp
	mov bp, sp
	push cx
	push dx
	push di
	push ax
	

@@skip:
	mov dx, [bp+4] ; y
	mov cx, [bp+6] ; x
	mov di, [bp+8] ; offset
	mov ax, [bp+10] ; BUG - DOESNT ACTULLY WORK
	
	shl [EnemyStayAtPlaceTimer], 8
	jnc @@checkX
	mov [EnemyStayAtPlaceTimer], 1
	
@@checkY:
	cmp [di+2], dx
	je @@checkBoth
	jl @@moreY
@@lessY:
	push di
	push 2
	push -1
	call AddXToOffsetInArray
	jmp @@checkX
@@moreY:
	push di
	push 2
	push 1
	call AddXToOffsetInArray
	jmp @@checkX
@@checkBoth:
	mov ax, cx
	sub ax, [di]
	cmp ax, -10
	jl @@checkX
	cmp ax, 10
	jg @@checkX
	jmp @@bothEqual
@@checkX:
	cmp ax, 0 
	je @@randomize
	jmp @@continue
@@randomize:
	mov bx, 2
	mov dx, 3
	call RandomByCsW
	cmp [cxMODE],2
	jng @@continue
	mov ax, 1
@@continue:
	cmp [di], cx
	je @@ret
	jl @@moreX
@@lessX:
	push di
	push 0
	neg ax
	push ax 
	call AddXToOffsetInArray
	mov [isLeft], 1
	jmp @@ret
@@moreX:
	push di
	push 0
	push ax
	call AddXToOffsetInArray
;	add [enemy_x], ax ; WILL ONLY WORK WITH A TARGET WHERE:TARGET - START DIVIDES BY AX!
	mov [isLeft], 0
	jmp @@ret

@@bothEqual:
	mov [isForawrd], 1
@@ret:
	pop ax 
	pop di
	pop dx
	pop cx
	pop bp
	ret 8
endp MoveEnemyToBoundry

; =============================================================================
; PROC WaitToDisappear
; -----------------------------------------------------------------------------
; Purpose : Test whether Enemy 1's current position is within ±4 pixels of
;           the designated disappear point (X, Y passed on the stack).
;           If so, set DisappearNow and return carry set to signal the caller
;           that the disappear sequence should begin.
;
; Entry   : [bp+4] = target Y (horizon-relative disappear Y).
;           [bp+6] = target X (147 - the fixed screen disappear X).
;           EnemyNormal[0] - current X of the sprite.
;           EnemyNormal[2] - current Y of the sprite.
;
; Exit    : Carry set   = sprite is within ±4 pixels of target; DisappearNow = 1.
;           Carry clear = sprite has not yet reached the target.
;           AX, BX preserved.
;
; Arbitrary numbers explained:
;   4  - tolerance in pixels; the enemy is considered "at" the disappear
;        point when both |dx| ≤ 4 and |dy| ≤ 4, avoiding exact-match
;        dependence when movement steps may overshoot by a pixel.
; =============================================================================
proc WaitToDisappear
	push bp
	mov bp, sp
	push ax
	push bx
	
	clc
	
	mov ax, [bp+6]
	mov bx, [bp+4]
	
	mov di, offset EnemyNormal
	
	mov cx, [di]
	sub cx, ax
	cmp cx, -4
	jl @@ret
	cmp cx, 4
	jg @@ret
	
	mov cx, [di+2]
	sub cx, bx
	cmp cx, -4
	jl @@ret
	cmp cx, 4
	jg @@ret
	
;	cmp [di], ax
;	jne @@ret
;	cmp [di+2], bx
;	jne @@ret
	
	mov [DisappearNow],1 
	
;	clc
;	shl [EnemyStayAtPlaceTimer], 1
;	jnc @@ret
;	mov [EnemyStayAtPlaceTimer], 1
	stc
@@ret:
	pop bx
	pop ax
	pop bp
	ret 4
endp WaitToDisappear

; =============================================================================
; PROC DrawAnything
; -----------------------------------------------------------------------------
; Purpose : Thin wrapper around OpenShowBmp that displays a BMP file using
;           the current values of BmpLeft, BmpTop, BmpWidth, BmpHeight, and
;           FileNamePtr.  Prints an error message to the console if the file
;           cannot be opened.
;
; Entry   : FileNamePtr - offset of null-terminated BMP filename.
;           BmpLeft     - screen X of the top-left corner.
;           BmpTop      - screen Y of the top-left corner.
;           BmpWidth    - pixel width of the BMP.
;           BmpHeight   - pixel height of the BMP.
;
; Exit    : BMP pixels written to secondBuffer via OpenShowBmp.
;           OR FileError (printed error)   - set to 1 on open failure (set inside OpenShowBmp).
;
; Modifies: FileError.
; =============================================================================
proc DrawAnything	
	; needs memory to aleady have:
	; bmpLeft, bmpTop, bmpWidth, hight, and fileNamePtr 
	
    call OpenShowBmp
    cmp [FileError], 1
    jne @@ret

@@exitError:
    mov dx, offset BmpFileErrorMsg
    mov ah, 9
    int 21h

@@ret:
	ret
endp DrawAnything

; =============================================================================
; PROC SpawnEnemyOnRandomCorner
; -----------------------------------------------------------------------------
; Purpose : Initialise Enemy's starting position for a new wave.
;           Always places the sprite at Y = 140 (near the horizon).
;           Randomly selects left-side (enemyLeft = 1, no X offset applied)
;           or right-side (X += 269) spawn using a 0/1 random coin-flip.
;
; Entry   : EnemyNormal - must have been reset via resetVariabels before call.
;
; Exit    : EnemyNormal Y field incremented by 140 for every pixel.
;           If right spawn: EnemyNormal X field incremented by 269 for every
;           pixel, placing the sprite near the right edge of the screen.
;           If left spawn:  enemyLeft = 1; X is left at its reset position
;           (near the left edge).
;           AX, BX, DX, CX preserved.
;
; =============================================================================
proc SpawnEnemyOnRandomCorner
	push ax
	push bx
	push dx
	push cx
	
	push offset EnemyNormal
	push 2
	push 140
	call AddXToOffsetInArray
	
	
	mov bx, 0
	mov dx, 1
	call RandomByCsW
	
	cmp ax, 0
	je @@isRight
	mov [enemyLeft], 1
	jmp @@ret

	
@@isRight:
	mov ax, 269 
@@intialize:
	;mov [enemyBaseX], 269
	;add [enemyBaseX], 250
	push offset EnemyNormal
	push 0
	push ax 
	call AddXToOffsetInArray
	
	;mov cx, 270
	
;@@spawnEnemy:
;	mov dx, offset bmpEnemyForward
 ;   mov [FileNamePtr], dx
 ;	mov [enemy_y], 120
 ;	mov [bmpTop], 120
 ;	mov [BmpLeft], cx
 ;	mov [enemy_x], cx
 ;	mov [bmpWidth], 49
;    mov [BmpHeight], 26
	;call DrawAnything
@@ret:
	pop cx
	pop dx
	pop bx
	pop ax
	ret
endp SpawnEnemyOnRandomCorner

; =============================================================================
; PROC AddXToOffsetInArray
; -----------------------------------------------------------------------------
; Purpose : Add a signed word value to one field of every (X, Y, Color)
;           triplet in a pixel array.  The field is selected by a byte offset
;           (0 = X, 2 = Y, 4 = Color).  Iteration stops at the sentinel
;           triplet (three consecutive zero words).
;
; Entry   : [bp+4]  = signed word delta to add.
;           [bp+6]  = byte offset within each triplet (0, 2, or 4).
;           [bp+8]  = SI - offset of the pixel-triplet array.
;
; Exit    : Every non-sentinel entry's chosen field incremented by delta.
;           SI, AX, BX preserved.
;
; =============================================================================
proc AddXToOffsetInArray
	push bp
	mov bp, sp
	push ax
	push bx
	push si
	
	mov si, [bp+8]
	mov bx, [bp+6]
	mov ax, [bp+4]
	
@@addLoop:
	cmp [word ptr si], 0
	jne @@ok
	cmp [word ptr si+2], 0
	jne @@ok
	cmp [word ptr si+4], 0
	je @@ret
@@ok:
	add [si+bx], ax
	add si, 6
	jmp @@addLoop
@@ret:
	pop si
	pop bx
	pop ax
	pop bp
	ret 6
endp AddXToOffsetInArray

; =============================================================================
; PROC SetCXbyTime
; -----------------------------------------------------------------------------
; Purpose : Advance Enemy's size-stage counter (cxMODE) using a
;           shift-register "timer" (CxSizeTimer), then compute
;           CX = cxMODE * 100.  Caps cxMODE at 4 (after 4 [5]) (four shrink stages).
;
; Entry   : CxSizeTimer - word used as a shift register; carry from SHL
;                         gates each cxMODE increment.
;           cxMODE      - current size stage (0-4).
;
; Exit    : CX = cxMODE * 100  (range 0-400).
;           cxMODE possibly incremented (max 4).
;           CxSizeTimer updated.
;
; =============================================================================
proc SetCXbyTime


	shl[CxSizeTimer], 1
	jnc @@calc
	cmp [cxMODE],4
	jg @@ret
	inc [cxMODE]
	mov [CxSizeTimer], 1
@@calc:
	xor cx, cx
	mov ax, [cxMODE]
	mov bx, 100
	mul bx
	add cx, ax

@@ret:
	ret
endp SetCXbyTime

; =============================================================================
; PROC RandomByCsW
; -----------------------------------------------------------------------------
; Purpose : Generate a random integer in the range (BX, DX) using a
;           combination of the BIOS timer and XOR of opcodes in cs.
; 
; Given a draw range in bx, dx
; 1. We subtract from the largest to the smallest to get a range from 0
; 2. We take a hundredth of a second from the clock 
; 3. We take 2 opcodes from cs using di, mix one of them and do an xor between them together with the address di
; 4. We advance in CS to the next position with di
; 5. We do an xor between the opcodes and the hundredth of a second
; 6. We discard bits that are not in the range (and with a mask of the range)
; 7. If still not in the range, we jump to 2 and do it again.
; 8. Otherwise, we are done, we add the low end of the range to the number drawn and return in ax a number that is muffled.
;
; Entry   : BX = inclusive lower bound.
;           DX = exclusive upper bound.
;           (DX must be > BX)
;
; Exit    : AX = random value in [BX, DX).
;           Position (CS variable) updated for next call.
;           BX, DX, SI, DI, ES preserved.
;
; =============================================================================
proc RandomByCsW
    jmp @@startProc
    Position dw start

@@startProc:
    push es
    push bx
    push dx
    push si
    push di
    mov ax, 40h
    mov es, ax

    sub dx, bx
    cmp dx, 0
    jle @@ExitP
    push bx

    mov di, [word cs:Position]
    call make_mask_right

@@RandLoop:
    mov bx, [es:06ch]
    mov ax, [word cs:di]

    add ax, di
    rol ax, 5
    xchg ah, al

    xor ax, [word cs:di + 2]
    xor ax, bx
    add di, 2
    cmp di, (@@EndProc - start - 2)
    jb @@Continue
    mov di, offset start

@@Continue:
    mov [word cs:Position], di

    and ax, si
    cmp ax, dx
    ja @@RandLoop

    pop bx
    add ax, bx

@@ExitP:
    pop di
    pop si
    pop dx
    pop bx
    pop es
    ret

@@EndProc:
endp RandomByCsW

; =============================================================================
; PROC make_mask_right
; -----------------------------------------------------------------------------
; Purpose : Use a bitmask to make the generated random num in range (bits out of range)
;
; Entry   : DX = range width (DX_original - BX from RandomByCsW).
;
; Exit    : SI = mask
;
; =============================================================================
proc make_mask_right
    push dx
    mov si, 8000h

@@loop1:
    shl dx, 1
    jc @@found
    shr si, 1
    jmp @@loop1

@@found:
    shl si, 1
    dec si
    pop dx
    ret
endp make_mask_right

; =============================================================================
; PROC HandleAltitude
; -----------------------------------------------------------------------------
; Purpose : Per-frame altitude manager.  First checks whether the player has
;           reached a dangerous altitude (triggering warnings or game-over via
;           checkAltitude), then draws the altitude indicator HUD element
;           (a small BMP strip) in the bottom-left corner of the screen.
;
; Entry   : horizonLine    - current horizon Y position; read by checkAltitude
;                            to determine if the player is too high or too low.
;           AltitudeBmp    - null-terminated filename of the altitude HUD BMP.
;           secondBuffer   - off-screen render target written by OpenShowBmp.
;
; Exit    : Altitude danger checks performed (warnings/game-over if needed).
;           Altitude HUD BMP rendered to secondBuffer.
;           FileError      - set to 1 by OpenShowBmp if the BMP cannot be opened.
;
; =============================================================================
proc HandleAltitude

	call checkAltitude
@@DrawAltitude:
	mov [BmpLeft], 2
	mov [BmpTop], 180
	mov dx, offset AltitudeBmp
	mov [FileNamePtr], dx
	mov [BmpWidth], 47 
	mov [BmpHeight], 7
	call OpenShowBmp
	
	
	ret
endp HandleAltitude

; =============================================================================
; PROC checkAltitude
; -----------------------------------------------------------------------------
; Purpose : Each frame, check whether the horizon line has moved so far up
;           or down that the player is at a dangerous altitude, and trigger
;           an audio warning accordingly.
;
; Entry   : horizonLine - current Y position of the horizon in screen pixels.
;
; Exit    : If horizonLine <= 10  : Crash.
;           If horizonLine >= 190 : Altitue Ripped Aircraft Airframe.
;
; =============================================================================
proc checkAltitude
	cmp [horizonLine], 10
	jg @@skip
	call TerrainWarning

@@skip:
	cmp [horizonLine], 190
	jl @@action
	call TerrainWarning

@@action:
	cmp [horizonLine], 190
	jl @@actionLow
	call HearAndSeeExplosion1
	call GameOverProc
@@actionLow:
	cmp [horizonLine], 10
	jg @@ret
	call HearAndSeeExplosion1
	call GameOverProc
@@ret:
	ret
endp checkAltitude


; =============================================================================
; PROC SpeakerOn
; -----------------------------------------------------------------------------
; Purpose : Program PIT with the given frequency divisorand gate the PC Speaker output on.
;
; Entry   : AX = desired frequency in Hz (must be > 0).
;
; Exit    : PC Speaker emitting the tone at AX Hz.
;           All registers preserved.
;
; =============================================================================
proc SpeakerOn
    push ax
    push bx
    push cx
    push dx


    ; program PIT channel 2
    push ax
    mov al, 0B6h        ; channel 2, lobyte/hibyte, square wave
    out 43h, al
    pop ax

    out 42h, al         ; send low byte
    mov al, ah
    out 42h, al         ; send high byte


    pop dx
    pop cx
    pop bx
    pop ax
    ret
endp SpeakerOn

; =============================================================================
; PROC SpeakerOff
; -----------------------------------------------------------------------------
; Purpose : Silence the PC Speaker by clearing speaker-enable bits in port 61h.
;
; Entry   : None.
;
; Exit    : PC Speaker muted.
;           AX preserved.
;
; =============================================================================
proc SpeakerOff
	push ax 
	
    in al, 61h
    and al, 0FCh        ; clear bits 0 and 1
    out 61h, al
	
	pop ax
    ret
endp SpeakerOff

; =============================================================================
; PROC flushKeys
; -----------------------------------------------------------------------------
; Purpose : Drain the BIOS keyboard buffer so that any keys pressed during
;           a previous screen (menu, cutscene, explosion) do not leak into
;           the next input-polling cycle.
;
; Entry   : None.
;
; Exit    : BIOS keyboard buffer empty.
;           All registers preserved.
;
; =============================================================================
proc flushKeys

@@flushKeys:
    mov ah, 1
    int 16h
    jz @@doneFlush
    mov ah, 0
    int 16h
    jmp @@flushKeys
@@doneFlush:
	
	
	ret
endp flushKeys

; =============================================================================
; PROC HandleSpeed
; -----------------------------------------------------------------------------
; Purpose : Per-frame speed manager.  First checks whether the player has
;           reached a dangerous speed (see CheckSpeed), then draws the altitude indicator HUD element
;           (a small BMP strip) in the bottom-left corner of the screen.
;
; Entry   : CheckSpeed Entries (see CheckSpeed).
;           SpeedBmp    - null-terminated filename of the altitude HUD BMP.
;           secondBuffer   - off-screen render target written by OpenShowBmp.
;
; Exit    : Speed danger checks performed.
;           Speed HUD BMP rendered to secondBuffer.
;           FileError      - set to 1 by OpenShowBmp if the BMP cannot be opened.
;
; =============================================================================
proc HandleSpeed
	
	call CheckSpeed
@@DrawSpeed:
	mov [BmpLeft], 2
	mov [BmpTop], 189
	mov dx, offset SpeedBmp
	mov [FileNamePtr], dx
	mov [BmpWidth], 45 
	mov [BmpHeight], 7
	call OpenShowBmp

	ret
endp HandleSpeed

; =============================================================================
; PROC CheckSpeed
; -----------------------------------------------------------------------------
; Purpose : Each frame, read the speed-up and slow-down keys, update
;           planeSpeed, and call Stall if speed has dropped to minimum.
;
; Entry   : keys[]     - current keyboard state (1 = held, 0 = released).
;           planeSpeed - current forward speed (word, 1..40).
;
; Exit    : planeSpeed possibly incremented (speed-up key) or decremented
;           (either slow-down key).
;           Stall called if speed = 1 (handled inside Stall).
;           AX preserved.
;
; Arbitrary numbers explained:
;   39h - Scan code for SPACE BAR (speed up).
;   2Ah - Scan code for LEFT SHIFT (slow down).
;   36h - Scan code for RIGHT SHIFT (slow down).
;   40  - Maximum allowed plane speed- acts as an upper speed cap.
;   1   - Minimum plane speed- dropping below triggers a stall.
; =============================================================================
proc CheckSpeed
	push ax
	
	call stall
	
	cmp [byte ptr keys + 39h], 1
	jne @@checkSlowDown
	cmp [planeSpeed], 40
	jg @@ret
	inc [planeSpeed]
@@checkSlowDown:
	; check left shift
	cmp [byte ptr keys + 2Ah], 1
	jne @@checkRightShift
	cmp [planeSpeed], 1
	jle @@ret
	dec [planeSpeed]
@@checkRightShift:
	cmp [byte ptr keys + 36h], 1
	jne @@ret
	cmp [planeSpeed], 1
	jle @@ret
	dec [planeSpeed]
	
@@ret:
	pop ax
	ret
endp CheckSpeed

; =============================================================================
; PROC checkMainMenu
; -----------------------------------------------------------------------------
; Purpose : Poll the keyboard hardware port directly for a single keypress
;           on the main menu screen.  Returns carry set for "Play", or sets
;           the Direction Flag (DF) to signal "Exit" to the caller.
;
; Entry   : None (reads port 60h directly).
;
; Exit    : Carry set  = scan code 2 pressed (key '1' = Play).
;           DF set     = scan code 4 pressed (key '3' = Exit).
;           Carry clear, DF clear = any other key or key release.
;           AX, BX preserved.
;
; Arbitrary numbers explained:
;   60h  - PC keyboard data port; holds the last scan code.
;   2    - Scan code for the '1' key (Play option).
;   4    - Scan code for the '3' key (Exit option).
; =============================================================================
proc checkMainMenu
    push ax
    push bx
	
    in al, 60h
    
    mov bl, al
    and bl, 7Fh         ; strip release bit
    test al, 80h
	clc 
	cld 
    jnz @@ret   ; ignore releases
    
    ; check on press directly
    cmp bl, 2
    je @@play
  ;  cmp bl, 3
  ;  je @@settings
    cmp bl, 4
	clc
    je @@exit
	jmp @@ret
    ;jmp @@checkAgain

;@@keyReleased:
  ;  jmp @@checkAgain

@@play:
    stc
    jmp @@ret
;@@settings:
    ;call settings
@@exit:
    std
@@ret:
    pop bx
    pop ax
    ret
endp checkMainMenu

; =============================================================================
; PROC DebugPaletteColors
; -----------------------------------------------------------------------------
; Purpose : Development utility.  Draw a row of 16 color swatches (20×20
;           pixels each) starting at Y=5 in secondBuffer so that the first
;           16 VGA palette indices can be visually inspected.
;           Not called in the final game loop.
;
; Entry   : secondBuffer - off-screen frame buffer (must be initialised).
;
; Exit    : secondBuffer contain 16 filled rectangles, one per
;           palette index 0-15.
;           All registers preserved.
;
; Arbitrary numbers explained:
;   16   - Number of palette swatches to draw (indices 0-15).
;   20   - Width and height of each color swatch in pixels.
;   5    - Starting Y coordinate of the swatch row (leaves a small margin).
;   320  - Screen width in bytes per row (VGA Mode 13h).
; =============================================================================
proc DebugPaletteColors
    push es
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov ax, seg secondBuffer
    mov es, ax
    lea si, [secondBuffer]

    mov bx, 0           ; color index

@@nextColor:
    cmp bx, 16
    jge @@done

    ; draw 20x20 square for color bx
    ; x = bx * 20, y = 5
    mov cx, 20          ; 20 rows
@@rowLoop:
    push cx

    ; row number = 5 + (20 - cx)
    mov ax, 20
    sub ax, cx
    add ax, 5           ; y
    mov dx, 320
    mul dx              ; y * 320
    push ax             ; save y*320

    mov ax, bx
    mov dx, 20
    mul dx              ; x = bx * 20

    pop dx
    add ax, dx          ; ax = y*320 + x
    add ax, si          ; add secondBuffer base

    mov di, ax
    mov cx, 20          ; 20 pixels wide
    mov al, bl          ; color = current index
    rep stosb

    pop cx
    loop @@rowLoop

    inc bx
    jmp @@nextColor

@@done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop es
    ret
endp DebugPaletteColors

; =============================================================================
; PROC _200MiliSecDelay
; -----------------------------------------------------------------------------
; Purpose : Busy-wait for approximately 200 milliseconds.
;
; Entry   : None.
;
; Exit    : Approximately 200 ms have elapsed.
;           All registers preserved.
;
; Arbitrary numbers explained:
;   1000 - Outer loop count.
;   600  - Inner loop count. 1000 * 600 = 600,000 iterations.
;          At roughly 3,000,000 iterations per second on a 286-era machine
;          this produces ~200 ms of delay.
; =============================================================================
proc _200MiliSecDelay
    push cx
	
    mov cx, 1000
@@Self1:
    push cx
    mov cx, 600
@@Self2:    loop @@Self2
    pop cx
    loop @@Self1
	
    pop cx
    ret
endp _200MiliSecDelay

; =============================================================================
; PROC _400MiliSecDelay
; -----------------------------------------------------------------------------
; Purpose : Busy-wait for approximately 400 milliseconds by calling
;           _200MiliSecDelay twice in sequence.
;
; Entry   : None.
;
; Exit    : Approximately 400 ms have elapsed.
;           No registers.
; =============================================================================
proc _400MiliSecDelay
    call _200MiliSecDelay
    call _200MiliSecDelay
    ret
endp _400MiliSecDelay

; =============================================================================
; PROC DrawMainMenu
; -----------------------------------------------------------------------------
; Purpose : Render the "Press Any Key" splash screen (L_2.bmp) to the
;           off-screen buffer covering the full 320x200 display.
;           Called once per frame during the pre-menu attract loop.
;
; Entry   : FileMainMenuShow - offset of the null-terminated filename "L_2.bmp".
;           secondBuffer     - destination off-screen frame buffer.
;
; Exit    : secondBuffer filled with the start screen image.
;           OR ileError = 1 and error message printed if file open fails.
;           All registers preserved.
;
; Arbitrary numbers explained:
;   320  - Full screen width in pixels (VGA Mode 13h).
;   200  - Full screen height in pixels (VGA Mode 13h).
;   0, 0 - Top-left corner; image covers the entire screen.
; =============================================================================
proc DrawMainMenu
	push dx 
@@showFileImage1:
    mov dx, offset FileMainMenuShow
    mov [FileNamePtr], dx
    mov [BmpLeft], 0
    mov [BmpTop], 0
    mov [BmpWidth], 320
    mov [BmpHeight], 200
    call OpenShowBmp
    cmp [FileError], 1
    je @@exitError
	jmp @@ret

@@exitError:
    mov dx, offset BmpFileErrorMsg
    mov ah, 9
    int 21h
@@ret:
	pop dx
	ret
endp DrawMainMenu

; =============================================================================
; PROC MainMenu
; -----------------------------------------------------------------------------
; Purpose : Display the main menu selection screen (LOADING.bmp - "1-PLAY,
;           3-EXIT") to the off-screen buffer.  The caller is responsible
;           for blitting and waiting for a key press.
;
; Entry   : FileMainReady - offset of null-terminated filename "LOADING.bmp".
;           secondBuffer  - destination off-screen frame buffer.
;
; Exit    : secondBuffer filled with the menu image.
;           FileError = 1 and error message printed if file open fails.
;           BX, CX, DX preserved.
;
; Arbitrary numbers explained:
;   320  - Full screen width in pixels.
;   200  - Full screen height in pixels.
;   0, 0 - Top-left origin; image covers the entire display.
; =============================================================================
proc MainMenu
	push ax 
	push dx
	
	
    mov dx, offset FileMainReady
@@showFileImage:
    mov [FileNamePtr], dx
    mov [BmpLeft], 0
    mov [BmpTop], 0
    mov [BmpWidth], 320
    mov [BmpHeight], 200
    call OpenShowBmp
    cmp [FileError], 1
    je @@exitError
    jmp @@ret

@@exitError:
    mov dx, offset BmpFileErrorMsg
    mov ah, 9
    int 21h

@@ret:
    pop dx
	pop ax
    ret
endp MainMenu

; =============================================================================
; PROC reset_dsp
; -----------------------------------------------------------------------------
; Purpose : Reset the Sound Blaster DSP to a known idle state before issuing playback commands.
;
; Entry   : DSP_RESET   - SB DSP reset port.
;           DSP_RDSTAT - SB DSP read-data-available status port.
;           DSP_READ  - SB DSP read data port.
;
; Exit    : DSP in reset/idle state.
;           All registers preserved.
;
; =============================================================================
proc reset_dsp
	push ax 
	push cx
	push dx 
	
    mov dx, DSP_RESET
    mov al, 1
    out dx, al
    mov cx, 0FFFFh
@@rd1:
    in al, 80h
    loop @@rd1
    mov al, 0
    out dx, al
    mov cx, 0FFFFh
@@rd2:
    in al, 80h
    loop @@rd2
    mov cx, 16
@@rd3:
    mov dx, DSP_RDSTAT
    in al, dx
    test al, 80h
    jz @@rd4
    mov dx, DSP_READ
    in al, dx
    loop @@rd3
@@rd4:
	pop dx 
	pop cx 
	pop ax
    ret
endp reset_dsp

; =============================================================================
; PROC PlaySong
; -----------------------------------------------------------------------------
; Purpose : Open a raw 8-bit PCM audio file and stream it to the Sound
;           Blaster DSP via direct DAC output commands (DSP command 10h).
;           Stops and returns with carry set if any key is pressed.
;           Stops and returns with carry clear when the file is exhausted.
;
; Entry   : [bp+4] = offset of null-terminated filename for the RAW audio file.
;           DSP_WRITE  - SB DSP write port (EQU 22Ch).
;           DSP_RESET, DSP_READ, DSP_RDSTAT - SB base ports.
;           CHUNK_SIZE (EQU 400h = 1024) - bytes read per disk I/O call.
;           SAMPLE_DELAY (EQU 25) - inter-sample busy-wait iterations
;                                   to approximate the playback sample rate.
;
; Exit    : Carry set   = user pressed a key during playback (early stop).
;           Carry clear = file played to completion normally.
;           file_handle closed on both exit paths.
;           All registers preserved.
;
; =============================================================================
proc PlaySong
	push bp
	mov bp, sp
	push ax 
	push bx
	push cx 
	push dx 
	push si 
	
   mov dx, [bp+4]
    mov ax, 3D00h
    int 21h
    jc @@ret
    mov [file_handle], ax

    call reset_dsp

    ; Speaker on
    mov dx, DSP_WRITE
@@spk_w:
    in al, dx
    test al, 80h
    jnz @@spk_w
    mov al, 0D1h
    out dx, al

@@main_loop:
	mov ah, 1
	int 16h
	jz @@continue 
	stc
	jmp @@ret
@@continue:
    ; --- Read next chunk ---
    mov bx, [file_handle]
    mov dx, OFFSET chunk_buf
    mov cx, CHUNK_SIZE
    mov ah, 3Fh
    int 21h
    jc @@main_done
    or ax, ax
    jz @@main_done
    mov [bytes_read], ax

    ; --- Play chunk via direct DAC ---
    mov si, OFFSET chunk_buf
    mov cx, [bytes_read]
@@sample_loop:
    mov dx, DSP_WRITE
@@dac_w1:
    in al, dx
    test al, 80h
    jnz @@dac_w1
    mov al, 10h
    out dx, al
@@dac_w2:
    in al, dx
    test al, 80h
    jnz @@dac_w2
    mov al, [si]
    out dx, al
    inc si

    push cx
    mov cx, SAMPLE_DELAY
@@delay:
    in al, 80h
    loop @@delay
    pop cx

    loop @@sample_loop
    jmp @@main_loop

@@main_done:
    mov bx, [file_handle]
    mov ah, 3Eh
    int 21h

    ; Speaker off
    mov dx, DSP_WRITE
@@spkoff:
    in al, dx
    test al, 80h
    jnz @@spkoff
    mov al, 0D3h
    out dx, al
	
	clc 
@@ret:
	pop si 
	pop dx 
	pop cx 
	pop bx 
	pop ax
	pop bp
	ret 2
endp PlaySong


proc PlaySongAndMainMenu
	push bp
	mov bp, sp
	
   mov dx, [bp+4]
    mov ax, 3D00h
    int 21h
    jc @@ret
    mov [file_handle], ax

    call reset_dsp

    ; Speaker on
    mov dx, DSP_WRITE
@@spk_w:
    in al, dx
    test al, 80h
    jnz @@spk_w
    mov al, 0D1h
    out dx, al

@@main_loop:
	call checkMainMenu
	jnc @@checkExit 
	clc 
	jmp @@ret
@@CheckExit:
	pushf           ; Push the FLAGS register onto the stack
	pop ax          ; Pop it into AX so we can manipulate it
	test ax, 400h   ; Bit 9 is 400h (binary 0000 0100 0000 0000)
	jz @@continue   ; Jump if DF = 1 (Decrement mode)
; ... if DF = 0 (Increment mode), code continues here
	stc 
	jmp @@ret
    ; --- Call CheckStartingMenu ---
 ;   call CheckStartingMenu
;    jc @@main_done      ; carry set = quit music
@@continue:
    ; --- Read next chunk ---
    mov bx, [file_handle]
    mov dx, OFFSET chunk_buf
    mov cx, CHUNK_SIZE
    mov ah, 3Fh
    int 21h
    jc @@main_done
    or ax, ax
    jz @@main_done
    mov [bytes_read], ax

    ; --- Play chunk via direct DAC ---
    mov si, OFFSET chunk_buf
    mov cx, [bytes_read]
@@sample_loop:
    mov dx, DSP_WRITE
@@dac_w1:
    in al, dx
    test al, 80h
    jnz @@dac_w1
    mov al, 10h
    out dx, al
@@dac_w2:
    in al, dx
    test al, 80h
    jnz @@dac_w2
    mov al, [si]
    out dx, al
    inc si

    push cx
    mov cx, SAMPLE_DELAY
@@delay:
    in al, 80h
    loop @@delay
    pop cx

    loop @@sample_loop
    jmp @@main_loop

@@main_done:
    mov bx, [file_handle]
    mov ah, 3Eh
    int 21h

    ; Speaker off
    mov dx, DSP_WRITE
@@spkoff:
    in al, dx
    test al, 80h
    jnz @@spkoff
    mov al, 0D3h
    out dx, al
	
	clc 
@@ret:
	pop bp
	ret 2
endp PlaySongAndMainMenu

; =============================================================================
; PROC file_open
; -----------------------------------------------------------------------------
; Purpose : Open a file by name for read-only access using DOS INT 21h and
;           store the returned handle in FileHandle.
;           Sets FileError = 1 and FileFound = 0 on failure.
;           Sets FileFound = 1 and FileHandle = handle on success.
;
; Entry   : FileNamePtr - word containing the offset of the null-terminated
;                         filename string to open.
;
; Exit    : FileHandle  = valid DOS file handle (on success).
;           FileFound   = 1 (success) or 0 (failure).
;           FileError   = 0 (success) or 1 (failure).
;           DX preserved.
;
; Arbitrary numbers explained:
;   3Dh  - DOS function: open existing file.
;   AL=0 - Open mode: read-only (no write access).
; =============================================================================
proc file_open
	push dx
	
	mov [FileError], 0
	mov [FileFound], 0
	mov ah, 3Dh
	mov dx, [FileNamePtr]
	int 21h
	jnc @@Success
	mov [FileError] , 1
	jmp @@ret
	
@@Success:
    mov [FileFound],1
	mov [FileHandle], ax
@@ret:	
	pop dx
	ret
endp file_open

; =============================================================================
; PROC DrawGrassLines
; -----------------------------------------------------------------------------
; Purpose : Project three pairs of 3D waves lines endpoints through
;           the perspective transformation and draw each visible line to the
;           off-screen buffer using Bresenham.  Lines below the horizon are
;           clipped (skipped).  Gives the illusion of a receding landscape.
;
; Entry   : tree2_x0/x1, tree3_x0/x1, tree4_x0/x1 - world-space X endpoints
;             for each line (word variables).
;           tree2_z / tree3_z / tree4_z - world-space Z depths.
;           horizonLine - current horizon Y in screen pixels.
;           color       - set to 6 internally (dark green/olive).
;
; Exit    : Up to 3 projected lines drawn to secondBuffer.
;           AX, BX, CX preserved.
;
; Arbitrary numbers explained:
;   6    - Blue color
;
; =============================================================================
proc DrawGrassLines
    push ax
    push bx
    push cx

    mov [byte ptr color], 6

    ; tree 2
    mov ax, [tree2_x0]
    mov bx, [horizonLine]
    mov cx, [tree2_z]
    call Calc3D
    call OverflowFix
    mov [word ptr x0], di
    mov [word ptr y0], si

    ; check if above horizon - skip if so
    mov ax, si
    cmp ax, [horizonLine]
    jl @@skipTree2

    mov ax, [tree2_x1]
    mov bx, [horizonLine]
    mov cx, [tree2_z]
    call Calc3D
    call OverflowFix
    mov [word ptr x1], di
    mov [word ptr y1], si
    call Bresenham_GetPointsRandom
    call DrawPoints

@@skipTree2:
    ; tree 3
    mov ax, [tree3_x0]
    mov bx, [horizonLine]
    mov cx, [tree3_z]
    call Calc3D
    call OverflowFix
    mov [word ptr x0], di
    mov [word ptr y0], si

    mov ax, si
    cmp ax, [horizonLine]
    jl @@skipTree3

    mov ax, [tree3_x1]
    mov bx, [horizonLine]
    mov cx, [tree3_z]
    call Calc3D
    call OverflowFix
    mov [word ptr x1], di
    mov [word ptr y1], si
    call Bresenham_GetPointsRandom
    call DrawPoints

@@skipTree3:
    ; tree 4
    mov ax, [tree4_x0]
    mov bx, [horizonLine]
    mov cx, [tree4_z]
    call Calc3D
    call OverflowFix
    mov [word ptr x0], di
    mov [word ptr y0], si

    mov ax, si
    cmp ax, [horizonLine]
    jl @@skipTree4

    mov ax, [tree4_x1]
    mov bx, [horizonLine]
    mov cx, [tree4_z]
    call Calc3D
    call OverflowFix
    mov [word ptr x1], di
    mov [word ptr y1], si
    call Bresenham_GetPointsRandom
    call DrawPoints

@@skipTree4:
    pop cx
    pop bx
    pop ax
    ret
endp DrawGrassLines

; =============================================================================
; PROC OverflowFix
; -----------------------------------------------------------------------------
; Purpose : Make sure none of the coords exceed the legal values for drawing the waves.
;
; Entry   : DI = projected screen X (may be outside 0-319).
;           SI = projected screen Y (may be above horizon).
;           horizonLine - minimum allowed Y value for ground geometry.
;
; Exit    : DI clamped to [0, 319].
;           SI clamped to [horizonLine, 199] (horizon enforced as minimum).
;           All other registers preserved.
;
; Arbitrary numbers explained:
;   319  - Maximum valid screen X (320 pixels wide).
;   0    - Minimum valid screen X.
; =============================================================================
proc OverflowFix
	
	cmp di, 320
	jnge @@nextCheck
	mov di, 319
	
@@nextCheck:
	cmp di, 0
	jnle @@checkWithHorizon
	mov di, 0

@@checkWithHorizon:
	cmp si, [horizonLine]
	jge @@ret
	mov si, [horizonLine]
@@ret:
	ret
endp OverflowFix

; =============================================================================
; PROC DrawPlane
; -----------------------------------------------------------------------------
; Purpose : Each frame, select the correct player aircraft BMP based on the
;           currently held directional key and draw it to the off-screen
;           buffer.
;           Does nothing if GameOver is set.
;
; Entry   : keys[]     - keyboard state array.
;           PlaneState - cached plane orientation (0-4).
;           GameOver   - if 1, proc returns immediately without drawing.
;           All aircraft BMP filenames and dimensions defined in DATASEG.
;
; Exit    : secondBuffer updated with the correct plane sprite.
;           PlaneState updated to reflect currently held key.
;           DX preserved.
;
; Arbitrary numbers explained:
;   20h  - Scan code for the 'D' key (bank right).
;   1Eh  - Scan code for the 'A' key (bank left).
;   1Fh  - Scan code for the 'S' key (pitch up / climb).
;   11h  - Scan code for the 'W' key (pitch down / dive).
;   115  - Fixed BmpLeft: centres the fighter sprite horizontally within
;          the 320-pixel screen (320/2 - 42 ≈ 115 for an 83-px wide sprite).
;   88   - Fixed BmpTop: positions the sprite in the lower-centre of the
;          screen to simulate a first-person cockpit view.
;   83/85/84 - pixel widths of the respective directional BMP assets.
;   48/38/46/63/45 - pixel heights of the respective directional BMP assets.
; =============================================================================
proc DrawPlane
    push dx
	
	cmp [byte ptr GameOver], 1
	jne @@continue
	jmp @@ret
@@continue:
    cmp [byte ptr keys + 20h], 1   
    je @@setRight
    cmp [byte ptr keys + 1Eh], 1    
    je @@setLeft
    cmp [byte ptr keys + 1Fh], 1    
    je @@setUp
	cmp [byte ptr keys + 11h], 1
	je @@setDown
    jmp @@setDefault

@@setRight:
	cmp [PlaneState], 2
	je @@setDefault
    mov [byte ptr PlaneState], 1
    jmp @@showCurrent
@@setLeft:
	cmp [PlaneState], 1
	je @@setDefault
    mov [byte ptr PlaneState], 2
    jmp @@showCurrent
@@setUp:
	cmp [PlaneState], 4
	je @@setDefault
    mov [byte ptr PlaneState], 3
    jmp @@showCurrent
@@setDown:
	cmp [PlaneState], 3
	je @@setDefault
	mov [byte ptr PlaneState], 4
	jmp @@showCurrent
@@setDefault:
    mov [byte ptr PlaneState], 0
	jmp @@default

@@showCurrent:
    cmp [byte ptr PlaneState], 1
    je @@right
    cmp [byte ptr PlaneState], 2
    je @@left
    cmp [byte ptr PlaneState], 3
    je @@up
	cmp [byte ptr PlaneState], 4
	je @@down

@@default:
    mov dx, offset FileName1
	mov [BmpWidth], 83
	mov [BmpHeight], 48
    jmp @@showFileImage
@@right:	
    mov dx, offset FileRight
	mov [BmpWidth], 85
	mov [BmpHeight], 38
    jmp @@showFileImage
@@left:
    mov dx, offset FileLeft
	mov [BmpWidth], 83
	mov [BmpHeight], 46
    jmp @@showFileImage
@@up:
    mov dx, offset fileUp
	mov [BmpWidth], 84
	mov [BmpHeight], 63
	jmp @@showFileImage
@@down:
	mov dx, offset fileDown
	mov [BmpWidth], 84
	mov [BmpHeight], 45

@@showFileImage:
    mov [FileNamePtr], dx
    mov [BmpLeft], 115
    mov [BmpTop], 88
  ;  mov [BmpWidth], 100
   ; mov [BmpHeight], 30
    call OpenShowBmp
    cmp [FileError], 1
    je @@exitError
    jmp @@ret

@@exitError:
    mov dx, offset BmpFileErrorMsg
    mov ah, 9
    int 21h

@@ret:
    pop dx
    ret
endp DrawPlane

; =============================================================================
; PROC Crash
; -----------------------------------------------------------------------------
; Purpose : Handle an unrecoverable crash event (terrain contact / extreme
;           altitude).  Sets the GameOver flag, hides the plane sprite, and
;           delegates to GameOverProc for the explosion and end screen.
;
; Entry   : None.
;
; Exit    : GameOver = 1.
;           StopDrawingPlane called to remove the plane from rendering.
;           GameOverProc called to show explosion + Game Over screen.
;           Does not return to normal game flow.
; =============================================================================
proc Crash

	mov [GameOver], 1
	
	call GameOverProc
	
	ret
endp Crash

; =============================================================================
; PROC GameOverProc
; -----------------------------------------------------------------------------
; Purpose : Execute the full game-over sequence:
;           1. Silence the PC Speaker.
;           2. Set GameOver flag.
;           3. Show and play the explosion at screen centre.
;           4. Display the G_O.bmp (Game Over) full-screen image.
;           5. Wait until the player presses any key to continue.
;
; Entry   : None.
;
; Exit    : GameOver = 1.
;           secondBuffer filled with G_O.bmp.
;           anyKeyPressed = 1 when proc returns (player confirmed) (from proc called - unless closed dos or exited game by force).
;           DX preserved.
;
; =============================================================================
proc GameOverProc
	push dx
	
	call SpeakerOff
	
	mov [GameOver], 1
	

	push 120
	push 80
	call HearAndSeeExplosion1

	mov dx, offset FileGameOverBmp
	mov [FileNamePtr], dx
	mov [BmpLeft], 0
	mov [BmpTop], 0
	mov [BmpWidth], 320
	mov [BmpHeight], 200
	call OpenShowBmp
	call TransitionBuffer
	call flushKeys

@@checkLoop:
	call AnyKeyPressedCheck 
	cmp [anyKeyPressed], 1
	jne @@checkLoop
	
	
	pop dx
	ret
endp GameOverProc

; =============================================================================
; PROC HearAndSeeExplosion1
; -----------------------------------------------------------------------------
; Purpose : Display the explosion BMP at a caller-specified position and
;           play the explosion sound effect (EXPL.raw) through the Sound
;           Blaster.  Provides both visual and audio feedback for any
;           destruction event.
;
; Entry   : [bp+4]  = BmpLeft  (screen X of explosion sprite).
;           [bp+6]  = BmpTop   (screen Y of explosion sprite).
;           FileExplosionBmp  - filename offset for "Explo.bmp".
;           FileExplosionSfx  - filename offset for "EXPL.raw".
;
; Exit    : Explosion sprite written to secondBuffer and blitted to screen.
;           EXPL.raw played through Sound Blaster.
;           ~400 ms additional delay after sound.
;           AX, DX preserved.
;
; Arbitrary numbers explained:
;   160  - Fixed explosion sprite width in pixels.
;   80   - Fixed explosion sprite height in pixels.
; =============================================================================
proc HearAndSeeExplosion1
	push bp
	mov bp, sp
	push ax
	push dx
	
	mov dx, offset FileExplosionBmp
@@showFileImage:
    mov [FileNamePtr], dx
	mov ax, [bp+4]
    mov [BmpLeft], ax
	mov ax, [bp+6]
    mov [BmpTop], ax
    mov [BmpWidth], 160
    mov [BmpHeight], 80
    call OpenShowBmp
    cmp [FileError], 1
    je @@exitError
	call TransitionBuffer
    jmp @@playSound

@@exitError:
    mov dx, offset BmpFileErrorMsg
    mov ah, 9
    int 21h
	jmp @@ret
@@PlaySound:
	call flushKeys
	push offset FileExplosionSfx
	call PlaySong
	call _400MiliSecDelay
@@ret:
	pop dx
	pop ax
	pop bp
	ret 4
endp HearAndSeeExplosion1

; =============================================================================
; PROC TerrainWarning ; TO FIX - BAD! BLOCKS GAME!
; -----------------------------------------------------------------------------
; Purpose : Emit a repeating low-high two-tone beep via the PC Speaker to
;           warn the player that they are approaching the terrain altitude
;           limit.
;
; Entry   : None (uses PC Speaker directly via SpeakerOn/SpeakerOff).
;
; Exit    : PC Speaker left silent after the final beep cycle.
;           AX, CX, DX preserved.
;
; =============================================================================
proc TerrainWarning
    push ax
    push cx
    push dx

    ; how many times to beep - more urgent = more reps
    mov cx, 3

@@bepLoop:
    push cx

    ; LOW tone - 280Hz
    mov ax, 280
    call SpeakerOn
    mov cx, 800
@@low1:
    push cx
    mov cx, 800
@@low2: loop @@low2
    pop cx
    loop @@low1

    ; SHORT silence
    call SpeakerOff
    mov cx, 100
@@sil1:
    push cx
    mov cx, 400
@@sil2: loop @@sil2
    pop cx
    loop @@sil1

    ; HIGH tone - 880Hz
    mov ax, 880
    call SpeakerOn
    mov cx, 400
@@hi1:
    push cx
    mov cx, 800
@@hi2: loop @@hi2
    pop cx
    loop @@hi1

    call SpeakerOff

    ; pause between repeats
    mov cx, 300
@@pause1:
    push cx
    mov cx, 800
@@pause2: loop @@pause2
    pop cx
    loop @@pause1

    pop cx
    loop @@bepLoop

    pop dx
    pop cx
    pop ax
    ret
endp TerrainWarning

; =============================================================================
; PROC Stall ; TO FIX! - BAD!
; -----------------------------------------------------------------------------
; Purpose : Simulate an aerodynamic stall when planeSpeed drops to 1.
;           Forces the aircraft into a nose-down attitude, lowers the horizon
;           (reduces altitude), plays the stall sound effect, and triggers
;           GameOver if the horizon hits the minimum safe floor.
;
; Entry   : planeSpeed  - current speed (1 = minimum / stall threshold).
;           horizonLine - current horizon Y in screen pixels.
;           altitude    - current altitude value.
;
; Exit    : If planeSpeed > 1: returns immediately (no stall).
;           If planeSpeed = 1:
;             horizonLine -= 8 (aircraft loses altitude rapidly).
;             horizonLine floored at 10 (minimum safe altitude).
;             altitude -= 7 if floor was reached.
;             PlaneState = 4 (nose-down visual state).
;             Stall sound played.
;             GameOver set and GameOverProc called if horizonLine <= 10.
;           All registers preserved.
;
; =============================================================================
proc Stall 

	cmp [planeSpeed], 1
	jg @@ret
	
	call MoveDown
	sub [horizonLine], 8
	cmp [horizonLine],10
	jge @@playSfx
	mov [horizonLine], 10
	sub [altitude], 7
@@playSfx:
	push offset FileStallSfx
	call PlaySong
	
	call MoveDown
		
	mov [PlaneState], 4 ; down
	
	cmp [horizonLine], 10
	jge @@ret
	mov [GameOver], 1
	call GameOverProc

@@ret:
	ret
endp Stall

; =============================================================================
; PROC MoveUp
; -----------------------------------------------------------------------------
; Purpose : Move the player aircraft one unit upward (increase altitude).
;           Adjusts the horizon line, increments altitude, and shifts both
;           the enemy sprite and the in-flight missile array by +1 Y so they
;           appear to move with the world.
;
; Entry   : altitude    - current altitude
;           horizonLine - screen Y of the horizon.
;           EnemyNormal - enemy pixel-triplet array.
;           Missile_XXXS - missile pixel-triplet array.
;
; Exit    : altitude    += 1.
;           horizonLine += 1.
;           All Y fields in EnemyNormal  += 1.
;           All Y fields in Missile_XXXS += 1.
;           AX preserved.
;
; =============================================================================
proc MoveUp
	push ax
	cmp [altitude], 0
	jg @@continue
	call Crash
	jmp @@EnemeyY
@@continue:
	inc [altitude]
	inc [horizonLine]
@@EnemeyY:
	push offset EnemyNormal
	push 2
	push 1
	call AddXToOffsetInArray
@@MissileY:
	push offset Missile_XXXS
	push 2
	push 1
	call AddXToOffsetInArray
@@ret:
	pop ax
	ret
endp MoveUp

; =============================================================================
; PROC CheckAndMoveNew
; -----------------------------------------------------------------------------
; Purpose : Each frame, pull the keys[] array for the four directional keys
;           and call the corresponding movement procedure for each held key.
;           Multiple keys can be held simultaneously.
;
; Entry   : keys[] - interrupt-updated keyboard state array (1=held, 0=released).
;
; Exit    : MoveDown, MoveUp, MoveLeftNew, or MoveRight called as appropriate.
;           AX, BX preserved.
;
; Arbitrary numbers explained:
;   11h  - Scan code for 'W' key (pitch down / dive).
;   1Fh  - Scan code for 'S' key (pitch up / climb).
;   1Eh  - Scan code for 'A' key (turn/slide left).
;   20h  - Scan code for 'D' key (turn/slide right).
; =============================================================================
proc CheckAndMoveNew
	
@@checkKeys:	
	cmp [byte ptr keys+11h], 1
	jne @@CheckS
	call MoveDown
@@CheckS:
	cmp [byte ptr keys + 1Fh], 1
	jne @@checkA
	call MoveUp
@@CheckA:
	cmp [byte ptr keys + 1Eh], 1
	jne @@checkD
	call MoveLeftNew
@@checkD:
	cmp [byte ptr keys + 20h], 1
	jne @@ret
	call MoveRight
	
@@ret:
	ret
endp CheckAndMoveNew

; =============================================================================
; PROC MoveDown
; -----------------------------------------------------------------------------
; Purpose : Move the player aircraft one unit downward (decrease altitude).
;           Decrements horizon and altitude, then shifts both the enemy sprite
;           and missile array by -1 Y so they go by the world.
;
; Entry   : altitude    - current altitude (must be > 0 to descend safely).
;           horizonLine - current horizon screen Y.
;           EnemyNormal - enemy pixel-triplet array.
;           Missile_XXXS - missile pixel-triplet array.
;
; Exit    : altitude    -= 1.
;           horizonLine -= 1.
;           All Y fields in EnemyNormal  -= 1.
;           All Y fields in Missile_XXXS -= 1.
;           If altitude was 0: Crash is called.
;
; =============================================================================
; PROC MoveForwards
; -----------------------------------------------------------------------------
; Purpose : Each frame, advance all four landscape Z-depth values by a
;           speed-dependent step so that ground objects appear to rush toward
;           the player.  Objects that pass too close (Z < 245) are
;           teleported to a far distance via KillObject to create an
;           infinite-looping landscape.
;
; Entry   : planeSpeed - current forward speed (1-40).
;           tree1_z / tree2_z / tree3_z / tree4_z - world Z depths of the
;           four ground-line anchor points.
;
; Exit    : Each tree Z decremented by (planeSpeed * 1 * 4).
;           Trees whose Z crossed 245 are reset to a far position via
;           KillObject.
;           AX, BX modified during calculation (not preserved - caller aware).
;
; Arbitrary numbers explained:
;   4    - SHL AX, 2 = multiply by 4: scales the speed for perceptible
;          landscape motion even at speed 1.
;   245  - Minimum Z threshold before an object is considered "passed";
;          objects closer than this are reset so the loop appears infinite.
; =============================================================================
; =============================================================================
proc MoveDown

	cmp [altitude], 0
	jg @@continue
	call Crash
	jmp @@EnemyY
@@continue:
	dec [altitude]
	dec [horizonLine]
@@EnemyY:
	push offset EnemyNormal
	push 2
	push -1
	call AddXToOffsetInArray
@@MissileY:
	push offset Missile_XXXS
	push 2
	push -1
	call AddXToOffsetInArray
@@ret:
	ret
endp MoveDown

; =============================================================================
; PROC MoveForwards
; -----------------------------------------------------------------------------
; Purpose : Each frame, advance all four landscape Z-depth values by a
;           speed-dependent step so that ground objects appear to rush toward
;           the player.  Objects that pass too close (Z < 245) are
;           teleported to a far distance via KillObject to create an
;           infinite-looping landscape.
;
; Entry   : planeSpeed - current forward speed (1-40).
;           tree1_z / tree2_z / tree3_z / tree4_z - world Z depths of the
;           four ground-line anchor points.
;
; Exit    : Each tree Z decremented by (planeSpeed * 2).
;           Trees whose Z crossed 230 are reset to a far position via
;           KillObject.
;           AX preserved.
;
; =============================================================================
proc MoveForwards
	push ax 
	
	mov ax, [planeSpeed]
	shl ax, 2
	
	cmp [tree1_z], 230
	jl @@KillTree1
	sub [tree1_z], ax
	
    ; =======================
    ; TREE 2
    ; =======================
    cmp [tree2_z], 230
    jl @@KillTree2
    sub [tree2_z], ax

    ; =======================
    ; TREE 3
    ; =======================
    cmp [tree3_z], 230
    jl @@KillTree3
    sub [tree3_z], ax

    ; =======================
    ; TREE 4
    ; =======================
    cmp [tree4_z], 230
    jl @@KillTree4
    sub [tree4_z], ax
	
@@KillTree1: 
	push offset tree1_x 
	call KillObject
	jmp @@ret
@@KillTree2:
    push offset tree2_x1
    call KillObject
	jmp @@ret

@@KillTree3:
    push offset tree3_x1
    call KillObject
	jmp @@ret

@@KillTree4:
    push offset tree4_x1
    call KillObject

@@ret:
	pop ax 
	ret
endp MoveForwards

; =============================================================================
; PROC MoveRight
; -----------------------------------------------------------------------------
; Purpose : Each frame the 'D' key is held, slide all landscape ground lines
;           left by 3 pixels (simulating rightward camera pan) and shift both
;           the enemy sprite and the missile array left by 4 pixels.
;           After 600 consecutive right-movement frames, performs a "FullSpin"
;           reset that teleports all tree X coordinates to new far-right
;           starting positions, creating an infinite-loop landscape.
;
; Entry   : MoveRightCnt - accumulated right-movement frame counter.
;           tree2/3/4 _x0, _x1 - world X endpoints of the three ground lines.
;           EnemyNormal  - enemy pixel-triplet array.
;           Missile_XXXS - missile pixel-triplet array.
;
; Exit    : tree2/3/4 _x0/_x1 each decremented by 3 (normal case).
;           All X fields in EnemyNormal  decremented by 4.
;           All X fields in Missile_XXXS decremented by 4.
;           MoveRightCnt incremented (normal case) or reset to 0 (spin case).
;           On FullSpin: tree X endpoints reset to hardcoded far positions.

;           AX preserved.
;
; =============================================================================
proc MoveRight
	
	cmp [MoveRightCnt], 600
	jae @@FullSpin

	inc [MoveRightCnt]
    sub [tree2_x0], 10
    sub [tree2_x1], 10

    sub [tree3_x0], 10
    sub [tree3_x1], 10

    sub [tree4_x0], 10
    sub [tree4_x1], 10
	jmp @@EnemyX
	
@@FullSpin:	
	mov [MoveRightCnt], 0
	mov [MoveRightCnt], 0
	mov [tree2_x0], 700
	mov [tree2_x1], 900
@@FullSpin2:
	mov [tree3_x0], 400
	mov [tree3_x1], 1200
@@FullSpin3:
	mov [tree4_x0], 500
	mov [tree4_x1], 1100
@@EnemyX:
	push offset EnemyNormal
	push 0
	push -4
	call AddXToOffsetInArray	
	push offset Enemy2Normal
	push 0
	push -4
	call AddXToOffsetInArray	
	push offset Enemy3Normal
	push 0
	push -4
	call AddXToOffsetInArray
@@MissileX:
	push offset Missile_XXXS
	push 0
	push -4
	call AddXToOffsetInArray
	
@@ret:
	ret
endp MoveRight

; =============================================================================
; PROC MoveLeftNew
; -----------------------------------------------------------------------------
; Purpose : Each frame the 'A' key is held, slide all landscape ground lines
;           right by 3 pixels (simulating leftward camera pan) and shift the
;           enemy sprite right by 4 pixels.After 600 consecutive right-movement frames, performs a "FullSpin"
;           reset that teleports all tree X coordinates to new far-left
;           starting positions, creating an infinite-loop landscape.
;
; Entry   : tree2/3/4 _x0, _x1 - world X endpoints of the three ground lines.
;           EnemyNormal  - enemy pixel-triplet array.
;           Missile_XXXS - missile pixel-triplet array.
;			moveLeftCnt - for infinte spin.
;
; Exit    : tree2/3/4 _x0/_x1 each incremented by 3.
;           All X fields in EnemyNormal  incremented by 4.
;           All X fields in Missile_XXXS decremented by 4
;           All registers preserved.
;
; =============================================================================
proc MoveLeftNew
	
	cmp [moveLeftCnt], 600
	jae @@FullSpin
	
	inc [moveLeftCnt]
    add [tree2_x0], 10
    add [tree2_x1], 10

    add [tree3_x0], 10
    add [tree3_x1], 10

    add [tree4_x0], 10
    add [tree4_x1], 10
	jmp @@EnemyX
	
@@FullSpin:
	mov [moveLeftCnt], 0
	mov [MoveRightCnt], 0
	mov [tree2_x0], -700
	mov [tree2_x1], -900
@@FullSpin2:
	mov [tree3_x0], -400
	mov [tree3_x1], -1200
@@FullSpin3:
	mov [tree4_x0], -500
	mov [tree4_x1], -1000
	
@@EnemyX:
	push offset EnemyNormal
	push 0
	push 4
	call AddXToOffsetInArray	
	push offset Enemy2Normal
	push 0
	push 4
	call AddXToOffsetInArray	
	push offset Enemy3Normal
	push 0
	push 4
	call AddXToOffsetInArray
@@MissileX:
	push offset Missile_XXXS
	push 0
	push 4
	call AddXToOffsetInArray
	
@@ret:
	ret
endp MoveLeftNew


; =============================================================================
; PROC KillObject
; -----------------------------------------------------------------------------
; Purpose : Teleport a landscape object to a far-away position so it can
;           re-enter the scene from the distance, creating the illusion of
;           an infinite looping landscape.  Sets both a new Z depth and a
;           new Y (horizon-relative) value via the object's data structure.
;
; Entry   : [bp+4] = SI - pointer to the object's data block.
;                        Word at [SI+2] = Y coordinate to reset.
;                        Word at [SI+4] = Z depth to reset.
;
; Exit    : [SI+4] = 1400  (new far Z depth).
;           [SI+2] = 100   (new Y position near the horizon).
;           SI preserved.
;
; =============================================================================
proc KillObject
	push bp
	mov bp, sp
	push si
	
	mov si, [bp+4]
	mov [word ptr si+4], 1400
	
	mov [word ptr si+2], 100
	
	pop si
	pop bp
	ret 2
endp KillObject

; =============================================================================
; PROC fillAround
; -----------------------------------------------------------------------------
; Purpose : Each frame, clear the off-screen buffer by painting the sky
;           region (above the horizon) and the ground region (below the
;           horizon) with solid colors.  This serves as the background
;           clear before all other objects are drawn on top.
;
; Entry   : horizonLine - current Y coordinate of the horizon in screen pixels.
;           secondBuffer - off-screen frame buffer to fill.
;
; Exit    : secondBuffer top filled with color 9 (sky).
;           secondBuffer bottom filled with color 4 (ground).
;           AX, BX, DX preserved.
;
; Arbitrary numbers explained:
;   320    - Screen width in bytes per row (VGA Mode 13h).
;   9      - VGA palette index for the sky color.
;   4      - VGA palette index for the ground color.
;   64000  - Total bytes in a 320x200 VGA frame (320 * 200); used to derive
;            the ground region size = 64000 - (horizonLine * 320).
; =============================================================================
proc fillAround
	push ax
	push bx
	push dx
	
	mov ax, [horizonLine]
	mov dx, 320
	mul dx
	
	push 0
	push 9
	push ax
	call FillWorld
	
	mov dx, 64000
	sub dx, ax
	push ax
	push 4
	push dx
	call FillWorld
	
	pop dx
	pop bx
	pop ax
endp fillAround


; =============================================================================
; PROC Calc3D
; -----------------------------------------------------------------------------
; Purpose : Transform a 3D world coordinate to a presentable (on a 2d screen) point, with only X,Y, without a third coordinate, while obvioulsy maintaining the third demension. 
;           The formula applied is:
;             screenX = (worldX * FOCAL / Z) + 160
;             screenY = (worldY * FOCAL / Z) + 100
;
; Entry   : AX = world X coordinate (signed word).
;           BX = world Y coordinate (signed word).
;           CX = world Z depth (if as big as z=4 [further = smaller Z], its "behind", which is coords 0, 0).
;           CONST_FOCAL = focal length constant (200).
;			Mid Sceen Values: 160 (320/2) and 100 (200/2) so result doesn’t appear at corner.
;
; Exit    : DI = projected screen X.
;           SI = projected screen Y.
;           If CX <= 4 (point is too close to camera):
;             DI = 0, SI = 0.
;           AX BX CX preserved.
;
; =============================================================================
proc Calc3D
	; ax gets x
	; bx gets y
	; cx gets z
	push ax 
	push bx 
	push cx
		
	cmp cx, 4
	jle @@behind
	
	imul [word ptr CONST_FOCAL]
	idiv cx
	add ax, 160
	mov di, ax
	
	
	mov ax, bx
	imul [word ptr CONST_FOCAL]
	idiv cx
	add ax, 100
	mov si, ax
	jmp @@ret
	
@@behind:
	mov di, 0
	mov si, 0

@@ret:
	pop cx
	pop bx 
	pop ax
	ret
endp Calc3D
	
; =============================================================================
; PROC DrawPoints
; -----------------------------------------------------------------------------
; Purpose : Paint all pixel addresses accumulated by Bresenham_GetPoints into
;           the off-screen buffer (secondBuffer) using the current color value.
;
; Entry   : points[]    - array of word-sized flat buffer offsets for each
;                         pixel to draw (populated by Bresenham_GetPoints).
;           pointsCount - number of valid entries in points[].
;           color       - byte color index to paint at each address.
;           secondBuffer - destination off-screen frame buffer.
;
; Exit    : Drawn pixels at secondBuffer.
;
; Arbitrary numbers explained:
;   2    - Each entry in points[] is a word (2 bytes).
; =============================================================================
proc DrawPoints
    push ax
    push bx
    push cx
    push di
    push es
	push si

    mov ax, seg secondBuffer
    mov es, ax
	lea di, [secondBuffer]

    mov cx, [pointsCount]
    xor bx, bx

@@loop:
    cmp cx, 0
    je @@end

    mov si, [points + bx]
    mov al, [color]
    mov [es:si], al

    add bx, 2
    dec cx
    jmp @@loop

@@end:
	pop si
    pop es
    pop di
    pop cx
    pop bx
    pop ax
    ret
endp DrawPoints
	
; =============================================================================
; PROC FillWorld
; -----------------------------------------------------------------------------
; Purpose : Fill a contiguous region of the off-screen buffer with a single
;           solid color using REP STOSB.  Used by fillAround to paint the
;           sky and ground regions each frame.
;
; Entry   : [bp+8] = start byte offset within secondBuffer.
;           [bp+6] = fill color (byte, VGA palette index).
;           [bp+4] = number of bytes to fill (pixel count).
;
; Exit    : secondBuffer filled (cleared).
;           AX, ES, DI, BP preserved.
;
; =============================================================================
proc FillWorld
	push bp
	mov bp, sp
	push ax
	push es
	push di
	
	mov ax, seg secondBuffer
	mov es, ax
	lea di, [secondBuffer]
	
	add di, [bp+8]
	mov al, [bp+6]	
	mov cx, [bp+4]
	rep stosb
	
	pop di
	pop es
	pop ax
	pop bp
	ret 6
endp FillWorld

proc Bresenham_GetPointsRandom
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    ; reset counter
    mov [pointsCount], 0
    ; dx = abs(x1 - x0)
    mov ax, [x1]
    sub ax, [x0]
    jns @@dx_ok
    neg ax
@@dx_ok:
    mov si, ax        ; dx
    ; dy = -abs(y1 - y0)
    mov ax, [y1]
    sub ax, [y0]
    jns @@dy_ok
    neg ax
@@dy_ok:
    neg ax
    mov di, ax        ; dy (negative)
    ; stepX
    mov ax, [x0]
    cmp ax, [x1]
    jle @@sx_pos
    mov bx, -1
    jmp @@sx_done
@@sx_pos:
    mov bx, 1
@@sx_done:
    mov [stepX], bx
    ; stepY
    mov ax, [y0]
    cmp ax, [y1]
    jle @@sy_pos
    mov bx, -1
    jmp @@sy_done
@@sy_pos:
    mov bx, 1
@@sy_done:
    mov [stepY], bx
    ; error = dx + dy
    mov ax, si
    add ax, di
    mov cx, ax        ; error
@@loop:
    ; calculate address = y*320 + x
    mov ax, [y0]
    mov bx, 320
    mul bx
    add ax, [x0]
    ; store address
    mov bx, [pointsCount]
    shl bx, 1
    mov [points + bx], ax
    inc [pointsCount]

    ; --- random y offset ---
    push cx             ; save error (random may clobber cx)
    push si             ; save dx
    push di             ; save dy
	push bx 
	push dx 
	mov bx, 1
	mov dx, 2
    call RandomByCsW         ; returns 1 or 2 in ax
	pop dx 
	pop bx
    pop di
    pop si
    pop cx
    cmp ax, 1
    jne @@no_offset     ; if random != 1, skip
    mov bx, [pointsCount]
    dec bx              ; point to the point we just stored
    shl bx, 1
    sub [word points + bx], 320  ; subtract 320 = move y up by 1
@@no_offset:

    ; stop condition
    mov ax, [x0]
    cmp ax, [x1]
    jne @@cont
    mov ax, [y0]
    cmp ax, [y1]
    je @@end
@@cont:
    ; e2 = 2*error
    mov ax, cx
    shl ax, 1
    ; if e2 >= dy
    cmp ax, di
    jl @@skipX
    add cx, di
    mov bx, [stepX]
    add [x0], bx
@@skipX:
    ; if e2 <= dx
    cmp ax, si
    jg @@skipY
    add cx, si
    mov bx, [stepY]
    add [y0], bx
@@skipY:
    jmp @@loop
@@end:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
endp Bresenham_GetPointsRandom

; =============================================================================
; PROC Bresenham_GetPoints
; -----------------------------------------------------------------------------
; Purpose : Implements the Bresenham line algorithm to calculate all pixel
;           addresses along a line between (x0, y0) and (x1, y1). The offsets
;           are calculated for a 320x200 screen and stored in an array.
;
; Entry   : x0, y0 - Starting coordinates.
;           x1, y1 - Ending coordinates.
;
; Exit    : points      - Array filled with memory offsets (y*320 + x).
;           pointsCount - Number of points calculated and stored.
;           AX, BX, CX, DX, SI, DI preserved.
;
; =============================================================================
proc Bresenham_GetPoints
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    ; reset counter
    mov [pointsCount], 0

    ; dx = abs(x1 - x0)
    mov ax, [x1]
    sub ax, [x0]
    jns @@dx_ok
    neg ax
@@dx_ok:
    mov si, ax        ; dx

    ; dy = -abs(y1 - y0)
    mov ax, [y1]
    sub ax, [y0]
    jns @@dy_ok
    neg ax
@@dy_ok:
    neg ax
    mov di, ax        ; dy (negative)

    ; stepX
    mov ax, [x0]
    cmp ax, [x1]
    jle @@sx_pos
    mov bx, -1
    jmp @@sx_done
@@sx_pos:
    mov bx, 1
@@sx_done:
    mov [stepX], bx

    ; stepY
    mov ax, [y0]
    cmp ax, [y1]
    jle @@sy_pos
    mov bx, -1
    jmp @@sy_done
@@sy_pos:
    mov bx, 1
@@sy_done:
    mov [stepY], bx

    ; error = dx + dy
    mov ax, si
    add ax, di
    mov cx, ax        ; error

@@loop:
    ; calculate address = y*320 + x
    mov ax, [y0]
    mov bx, 320
    mul bx
    add ax, [x0]

    ; store address
    mov bx, [pointsCount]
    shl bx, 1
    mov [points + bx], ax
    inc [pointsCount]

    ; stop condition
    mov ax, [x0]
    cmp ax, [x1]
    jne @@cont
    mov ax, [y0]
    cmp ax, [y1]
    je @@end

@@cont:
    ; e2 = 2*error
    mov ax, cx
    shl ax, 1

    ; if e2 >= dy
    cmp ax, di
    jl @@skipX
    add cx, di
    mov bx, [stepX]
    add [x0], bx

@@skipX:
    ; if e2 <= dx
    cmp ax, si
    jg @@skipY
    add cx, si
    mov bx, [stepY]
    add [y0], bx

@@skipY:
    jmp @@loop

@@end:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
endp Bresenham_GetPoints

; =============================================================================
; PROC TransitionBuffer
; -----------------------------------------------------------------------------
; Purpose : Copy the completed off-screen frame (secondBuffer) to the VGA
;           display memory (segment 0A000h) in a single burst transfer,
;           implementing double-buffered rendering to eliminate flicker.
;
; Entry   : secondBuffer - fully rendered off-screen frame (64,000 bytes).
;
; Exit    : VGA display memory updated with the new frame.
;           DS, ES, SI, DI, CX preserved.
;
; Arbitrary numbers explained:
;   0A000h - VGA Mode 13h.
;   32000  - Word count for REP MOVSW: 32,000 words * 2 bytes = 64,000 bytes,
;            which is the full 320x200 frame.
; =============================================================================
proc TransitionBuffer
	push ds
	push es
	push si
	push di
	push cx
	
	mov ax, seg secondBuffer
	mov ds, ax
	xor si, si
	
	mov ax, 0A000h
	mov es, ax
	xor di, di
	
	mov cx, 32000
	rep movsw
	
	pop cx
	pop di
	pop si
	pop es
	pop ds
	ret
endp TransitionBuffer

; =============================================================================
; PROC OpenShowBmp
; -----------------------------------------------------------------------------
; Purpose : High-level BMP loader pipeline.  Opens the file, reads the
;           54-byte header, reads and installs the 256-color palette, then
;           draws the pixel data to secondBuffer at the position described
;           by BmpLeft/BmpTop/BmpWidth/BmpHeight.
;           Aborts the pipeline if opening file fails.
;
; Entry   : FileNamePtr - offset of the null-terminated BMP filename.
;           BmpLeft, BmpTop, BmpWidth, BmpHeight - destination rect.
;
; Exit    : secondBuffer updated with the BMP image pixels.
;           FileError = 1 if OpenBmpFile failed (file not found etc.).
;           File handle closed before return on all paths.
; =============================================================================
proc OpenShowBmp  
	mov [FileError],0
	 
	call OpenBmpFile
	cmp [FileError],1
	je @@ExitProc
	
	call ReadBmpHeader
	
	call ReadBmpPalette
	
	call CopyBmpPalette
;	call DebugPaletteColors

	call ShowBMP
	
	 
	call CloseBmpFile

@@ExitProc:
	ret
endp OpenShowBmp

 
; =============================================================================
; PROC OpenBmpFile
; -----------------------------------------------------------------------------
; Purpose : Open the BMP file named by FileNamePtr for read-only access
;           using DOS INT 21h and store the resulting handle in FileHandle.
;           Sets FileError = 1 on any DOS error (file not found, access
;           denied, etc.).
;
; Entry   : FileNamePtr - word containing the offset of the null-terminated
;           filename to open.
; 			input dx filename to open (in proc).

;
; Exit    : FileHandle = valid DOS file handle (on success).
;           FileError  = 0 (success) or 1 (failure).
;           DX preserved.
;
; Arbitrary numbers explained:
;   3Dh  - DOS function number: open existing file.
;   AL=0 - Open access mode: 0 = read-only.
; =============================================================================	
proc OpenBmpFile	 near						 
	push dx
	mov dx, [FileNamePtr]
	mov ah, 3Dh
	xor al, al
	int 21h
	jc @@ErrorAtOpen
	mov [FileHandle], ax
	jmp @@ExitProc
	
@@ErrorAtOpen:
	mov [FileError],1
@@ExitProc:	
	pop dx
	ret
endp OpenBmpFile
 
 
; =============================================================================
; PROC CloseBmpFile
; -----------------------------------------------------------------------------
; Purpose : Close the currently open BMP file using DOS INT 21h to release
;           the file handle stored in FileHandle.
;
; Entry   : FileHandle - valid DOS file handle previously returned by
;           OpenBmpFile.
;
; Exit    : File handle released to DOS.
;           AH BX modified internally restored - low-level routine, caller ok with it).
;
; Arbitrary numbers explained:
;   3Eh  - DOS function number: close file handle.
; =============================================================================
proc CloseBmpFile  near
	mov ah,3Eh
	mov bx, [FileHandle]
	int 21h
	ret
endp CloseBmpFile


; =============================================================================
; PROC ReadBmpHeader
; -----------------------------------------------------------------------------
; Purpose : Read the 54-byte standard BMP file header from the open file
;           into the Header buffer.  This advances the DOS file pointer past
;           the header so the next read will begin at the palette data.
;
; Entry   : FileHandle.
;           Header     - 54-byte buffer in DATASEG.
;
; Exit    : Header[0..53] filled with BMP header bytes - Read 54 bytes the Header.
;           DOS file pointer advanced by 54 bytes.
;           CX, DX preserved.
;
; Arbitrary numbers explained:
;   3Fh  - DOS function number: read from file handle.
;   54   - Standard BMP file header size in bytes (BITMAPFILEHEADER =
;          14 bytes + BITMAPINFOHEADER = 40 bytes = 54 total).
; =============================================================================
proc ReadBmpHeader	 near					
	push cx
	push dx
	
	mov ah,3fh
	mov bx, [FileHandle]
	mov cx,54
	mov dx,offset Header
	int 21h
	
	pop dx
	pop cx
	ret
endp ReadBmpHeader

; =============================================================================
; PROC ReadBmpPalette
; -----------------------------------------------------------------------------
; Purpose : Read the BMP palette from the open file into the Palette buffer.  
;           Must be called after ReadBmpHeader so the file pointer is positioned 
;           after the header.
;
; Entry   : FileHandle - valid open DOS file handle.
;           Palette    - 1024-byte (400h) buffer in DATASEG.
;
; Exit    : Palette[0..1023] filled with pallate color indexes.
;           DOS file pointer advanced by 1024 bytes.
;           CX, DX preserved.
;
; Arbitrary numbers explained:
;   3Fh  - DOS function number: read from file handle.
;   400h - 1024 bytes: 256 palette entries * 4 bytes each.
;
; =============================================================================
proc ReadBmpPalette near ; Read BMP file Color_1 palette, 256 Color_1s * 4 bytes (400h)
						 ; 4 bytes for each Color_1 BGR + null)			
	push cx
	push dx
	
	mov ah,3fh
	mov cx,400h
	mov dx,offset Palette
	int 21h
	
	pop dx
	pop cx
	
	ret
endp ReadBmpPalette

; =============================================================================
; PROC CopyBmpPalette
; -----------------------------------------------------------------------------
; Purpose : Program the VGA with the 256-color palette loaded from the BMP file.
;
; Entry   : Palette[0..1023] 1024B by ReadBmpPalette
;
; Exit    : All 256 VGA entries updated with the BMP palette colors.
;           CX, DX preserved.
;
; Notes   : Will move out to screen memory the Colors
; 			video ports are 3C8h for number of first Color_1
; 			and 3C9h for all rest
;
; =============================================================================

proc CopyBmpPalette	 near						
										
	push cx
	push dx
	
	mov si,offset Palette
	mov cx,256
	mov dx,3C8h
	mov al,0   ; BLACK first							
	out dx,al ;3C8h
	inc dx	  ;3C9h
CopyNextColor:
	mov al,[si+2] 		; RED				
	shr al,2 			; divide by 4 Max (cos max is 63 and we have here max 255 ) (loosing Color_1 resolution).				
	out dx,al 						
	mov al,[si+1] 		; Green.				
	shr al,2            
	out dx,al 							
	mov al,[si] 		; Blue.				
	shr al,2            
	out dx,al 							
	add si,4 			; Point to next Color_1.  (4 bytes for each Color_1 BGR + null)				
								
	loop CopyNextColor
	
	pop dx
	pop cx
	
	ret
endp CopyBmpPalette

; =============================================================================
; PROC ShowBMP
; -----------------------------------------------------------------------------
; Purpose : Read BMP pixel rows from the open file and store in the
;           correct position in secondBuffer. 
;
; Entry   : BmpLeft, BmpTop           - top-left destination in secondBuffer.
;           BmpWidth, BmpHeight       - dimensions of the image.
;           secondBuffer              - destination off-screen frame buffer.
;			ScrLine 				  - one line to show on screen saved. 
;
; Exit    : secondBuffer updated with BMP pixel data.
;           CX preserved.
;
; =============================================================================
 proc ShowBMP  near
	push cx
	
	
	
	mov ax, seg secondBuffer
	mov es, ax
	mov bp,[BmpWidth]
	neg bp
	and bp, 3
	
	mov cx,[BmpHeight]
	dec cx
	add cx,[BmpTop]
	mov di,cx
	shl cx,6
	shl di,8
	add di,cx
	add di,[BmpLeft]
	
	lea ax, [secondBuffer]
	add di, ax
	
	cld
	mov cx, [BmpHeight]
	
	@@NextLine:
	push cx
	push di
	push es
	push ds                 
 
	mov ah,3fh
	mov cx,[BmpWidth]  
	add cx,bp
	mov dx,offset ScrLine
	int 21h
	
	pop ds                  
	pop es
	pop di
	
	mov cx,[BmpWidth]  
	mov si,offset ScrLine
@@copyLoop:
	mov al, [si]
	cmp al, 183            
	je @@skipPixel
	mov [es:di], al
@@skipPixel:
	inc si
	inc di
	loop @@copyLoop
	 
	sub di,[BmpWidth]
	sub di,SCREEN_WIDTH
	pop cx
	loop @@NextLine
	
	pop cx
	ret
endp ShowBMP
 
; =============================================================================
; PROC ShowBMP
; -----------------------------------------------------------------------------
; Purpose : Write on screen the value of ax (decimal)
;               the practice :  
;				Divide AX by 10 and put the Mod on stack 
;               Repeat Until AX smaller than 10 then print AX (MSB) 
;           	then pop from the stack all what we kept there and show it. 
;
; Entry   : AX
;
; Exit    : Screen
; 			All registers restored.
;
; =============================================================================
 proc ShowAxDecimal
	push ax
	push bx
	push cx
	push dx
	jmp PositiveAx
	
	; check if negative
	test ax,08000h
	jz PositiveAx
		
	;  put '-' on the screen
	push ax
	mov dl,'-'
	mov ah,2
	int 21h
	pop ax

	neg ax ; make it positive
PositiveAx:
	mov cx,0   ; will count how many time we did push 
	mov bx,10  ; the divider

put_mode_to_stack:
	xor dx,dx
	div bx
	add dl,30h
	; dl is the current LSB digit 
	; we cant push only dl so we push all dx
	push dx    
	inc cx
	cmp ax,9   ; check if it is the last time to div
	jg put_mode_to_stack


	cmp ax,0
	jz pop_next  ; jump if ax was totally 0
	add al,30h  
	mov dl, al    
	mov ah, 2h
	int 21h        ; show first digit MSB
	   
pop_next: 
	pop ax    ; remove all rest LIFO (reverse) (MSB to LSB)
	mov dl, al
	mov ah, 2h
	int 21h        ; show all rest digits
	loop pop_next

	mov dl, ','
	mov ah, 2h
	int 21h

	pop dx
	pop cx
	pop bx
	pop ax

	ret
endp ShowAxDecimal


END start