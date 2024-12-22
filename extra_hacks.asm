extra_hacks:

// ================================================
// This adds a bronze/silver/gold star sprite to the
// Battle Memory screen if you've seen every enemy.
// ================================================

// This is the stream of byte flags to compare against
.allenemies_frontcompare:
  db $FE,$FD,$57,$93,$FF,$FF,$FF,$DF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  db $DF,$FF,$FD,$FF,$FF,$FC,$CF,$03,$00,$00,$00,$00,$00,$00,$00,$00

// This is the stream of byte flags for back pics
.allenemies_backcompare:
  db $D8,$1C,$06,$82,$F9,$B7,$FF,$DF,$FF,$FF,$FD,$EF,$D9,$FF,$FF,$DF
  db $DF,$BF,$FD,$FF,$F3,$BC,$CF,$03,$00,$00,$00,$00,$00,$00,$00,$00
 
 
// This routine returns 1 if you have the silver star and 0 if you don't
.allenemies_frontcheck:
push {r1,lr}
ldr  r0,=#0x2004FAA
ldr  r1,=#.allenemies_frontcompare
bl   .allenemies_check
pop  {r1,pc}

// This routine returns 1 if you have the back sprites star and 0 if you don't
.allenemies_backcheck:
push {r1,lr}
ldr  r0,=#0x2004FCA
ldr  r1,=#.allenemies_backcompare
bl   .allenemies_check
pop  {r1,pc}

// This routine checks whether you have all the enemies' fronts/backs or not
.allenemies_check:
push {r2-r5,lr}
mov  r4,#0
-
ldrh r2,[r0,#0]                    //Sum is needed because it's not 4 bytes-aligned
ldrh r3,[r0,#2]
lsl  r3,r3,#0x10
add  r2,r2,r3
ldrh r3,[r1,#0]                    //Sum is needed because it's not guaranteed 4 bytes-aligned
ldrh r5,[r1,#2]
lsl  r5,r5,#0x10
add  r3,r3,r5
and  r2,r3
cmp  r2,r3
bne  +
add  r0,#4
add  r1,#4
add  r4,#1
cmp  r4,#8
bne  -
mov  r0,#1
b    .end_allenemies_check
+
mov  r0,#0

.end_allenemies_check:
pop  {r2-r5,pc}

// This hack checks if your enemy flags match and then displays the star sprite
.allenemies:
// ----------------------------------------------
// The base code already checks that we're in the battle memo screen
push {lr}
push {r0-r5}

// ----------------------------------------------
// Check for front pics
bl   .allenemies_frontcheck
mov  r4,r0

// Check for the back pics
bl   .allenemies_backcheck
lsl  r0,r0,#1
orr  r0,r4

bl   .read_star_sprite

.allenemies_end:
pop  {r0-r5}
ldrh r1,[r2,#0x1A]                 //Clobbered code
lsl  r0,r1,#2
pop  {pc}

// ----------------------------------------------
.read_star_sprite:
push {lr}
mov  r1,#3
and  r1,r0
cmp  r1,#0
beq  .end_read_star_sprite
cmp  r1,#3
bne  +
mov  r0,#0xBB                      // Gold
b    .do_set_start_sprite
+
cmp  r1,#2
bne  +
mov  r0,#0x6B                      // Silver
b    .do_set_start_sprite
+
mov  r0,#0xDB                      // Bronze

.do_set_start_sprite:
bl   .set_start_sprite

.end_read_star_sprite:
pop  {pc}

// ----------------------------------------------
.set_start_sprite:
push {r4,lr}
mov  r4,r0

// Load the star sprite into tile memory
ldr  r0,=#{star_sprite_address}
ldr  r1,=#0x60177E0
mov  r2,#0x8
swi  #0xC
mov  r0,r4

// ----------------------------------------------
// Load the OAM data into the OAM buffer
ldr  r3,=#0x2016028
ldr  r4,=#0xC620
add  r2,r3,r4
ldr  r4,=#0x2C98
add  r4,r3,r4
ldrh r1,[r4,#0]                    // Update objects counter to account for this one
add  r1,#1
strh r1,[r4,#0]
sub  r4,r1,#1
lsl  r4,r4,#3
ldr  r3,[r2,#0]
add  r3,r3,r4
mov  r4,#0x45
lsl  r4,r4,#0x10
add  r4,#0xE
str  r4,[r3,#0]
lsl  r4,r0,#8
add  r4,#0xBF
str  r4,[r3,#4]
// ----------------------------------------------
pop  {r4,pc}



// ---------------------------------------------------------------------------------------
// Intro screen
// (This code is no longer used; to make changes, recompile this and update data_introscreen.bin
// ---------------------------------------------------------------------------------------

//print "Intro screen routine: ",pc
//org $813C5D8
.intro_screen:
push {r0-r4}

// Enable VBlank interrupt crap
ldr  r2,=#0x4000000
mov  r0,#0xB
strh r0,[r2,#4]                    // LCD control
mov  r1,#2
lsl  r1,r1,#8
ldrh r0,[r2,r1]
mov  r3,#1
orr  r0,r3
strh r0,[r2,r1]                    // Master interrupt control

// Enable BG0
ldrh r0,[r2,#0]
mov  r1,#1
lsl  r1,r1,#8
orr  r0,r1
strh r1,[r2,#0]

// Tile data
ldr  r0,=#{disclaimer_address}
ldr  r1,=#0x6008000
swi  #0x12                         // LZ77UnCompVram
// ldr  r2,=#0x1FE0
// swi  #0xC

// Map data
ldr  r0,=#{disclaimer_map_address}
mov  r1,#6
lsl  r1,r1,#0x18
mov  r2,#2
lsl  r2,r2,#8
swi  #0xC

// Palette
ldr  r0,=#{disclaimer_pal_address}
mov  r1,#5
//Cambia el valor de el este codigo de arriba de #5 a #4 y en el juego ocurrirá un efecto superchulo sklfjñdlskjafñdlasjfkdñlsaj
lsl  r1,r1,#0x18
mov  r2,#1
lsl  r2,r2,#7
swi  #0xC

// Fade in
ldr  r2,=#0x4000050
mov  r0,#0x81
strh r0,[r2,#0]                    // Set blending mode to whiteness for BG0
mov  r4,#0x10
-
strh r4,[r2,#4]
swi  #5
swi  #5                            // 15 loops with 2 intrs each gives a total fade-in time of 0.5 seconds
sub  r4,#1
bpl  -

// Conditional delay for ~2 seconds
// 0x78 VBlankIntrWaits is 2 seconds
// 2005128 == 1 for save slot 1's existence, 200518C for slot 2
ldr  r0,=#0x2005128
ldrb r2,[r0,#0]
add  r0,#0x64
ldrb r1,[r0,#0]
add  r1,r1,r2
cmp  r1,#0
bne  +
mov  r4,#0x78
-
swi  #5
sub  r4,#1
cmp  r4,#0
bne  -
+

// Wait for any button press
ldr  r2,=#0x4000130
ldr  r4,=#0x3FF
-
swi  #5                            // VBlankIntrWait
ldrh r0,[r2,#0]
cmp  r0,r4
beq  -

// Fade out
ldr  r2,=#0x4000050
mov  r0,#0x81
strh r0,[r2,#0]                    // Set blending mode to whiteness for BG0
mov  r4,#0x0
-
strh r4,[r2,#4]
swi  #5
swi  #5                            // 15 loops with 2 intrs each gives a total fade-out time of 0.5 seconds
add  r4,#1
cmp  r4,#0x10
bls  -

// Clear the palette
mov  r0,#1
neg  r0,r0
push {r0}
mov  r0,sp
mov  r1,#5
lsl  r1,r1,#0x18
mov  r2,#1
lsl  r2,r2,#24
add  r2,#0x80
swi  #0xC
add  sp,#4

// ----------------------
pop  {r0-r4}

.intro_screen_end:
push {lr}
bl   $805AD24
pop  {pc}



// ---------------------------------------------------------------------------------------
// Changes the "Some sort of beat" item (0x90) icon to the bell
// This particular hack lets it use a custom palette
// ---------------------------------------------------------------------------------------

.bellringer:
// New version replaces the whole GetItemPaletteAddress routine
// Item number is in r0, both out-of-battle and in-battle
// Return the address in r2
push {lr}
cmp  r0,#0x90
beq  +
// ---------- Existing routine
lsl  r0,r0,#0x10
mov  r1,#0xB4
lsl  r1,r1,#0x12
add  r0,r0,r1
lsr  r0,r0,#0x10
bl   $8036D18
mov  r4,r0
mov  r0,#0
bl   $8036DDC
ldrb r1,[r4,#1]
lsl  r1,r1,#0x1C
lsr  r1,r1,#0x17
add  r0,r0,r1
pop  {pc}
+
// ---------- Custom routine
ldr  r0,=#0x9FABFE0
pop  {pc}

// Output r1 with the palette address
// Item ID in r7
//cmp  r7,#0x90
//bne  +
//ldr  r0,=#0x9FABFE0
//b    .bellringer_end
//+
//lsr  r1,r1,#0x17
//add  r0,r0,r1
//.bellringer_end:
//bx   lr

// ---------------------------------------------------------------------------------------
// Makes the Memo screen stretch vertically correctly.
// ---------------------------------------------------------------------------------------

.memo_stretch:
push {r0-r4,lr}
// ----------------------------------------------
// Fill 30040F0 with 1C8 00's
mov  r0,#0
push {r0}
mov  r0,sp
ldr  r1,=#0x30040F0
mov  r2,#1
lsl  r2,r2,#24                     // Fill
mov  r3,#0xE4
orr  r2,r3
swi  #0xB
add  sp,#4
// ----------------------------------------------
pop  {r0-r4}
mov  r2,#0                         // clobbered code
mov  r0,#5
pop  {pc}

// ---------------------------------------------------------------------------------------
// Fixes the string counter in the Memo screen. Possibly fixes things elsewhere.
// ---------------------------------------------------------------------------------------

.memo_counterfix1:
// Return length in r0
push {r0,r5,lr}
mov  r0,r4
bl   check_name
cmp  r0,#0
beq  +

add  sp,#4
pop  {r5,pc}

+
pop  {r0,r5}
mov  r1,r0                         // original code
lsl  r1,r1,#0x10
lsr  r1,r1,#0x10
ldr  r0,=#0x8D1EE78
bl   $800289C
ldrh r0,[r0,#0]
pop  {pc}

// ---------------------------------------------------------------------------------------
// Another string counter fixer. Fixes the [44 FF] code in particular.
// ---------------------------------------------------------------------------------------

.memo_counterfix2:
push {r0,lr}

// Address in r1, length in r2
mov  r0,r1
bl   check_name
cmp  r0,#0
beq  +
mov  r2,r0
+
lsl  r2,r2,#0x10                   // clobbered code
lsr  r5,r2,#0x10
pop  {r0,pc}

// ---------------------------------------------------------------------------------------
// Fixes printing in the memo screen. Also changes position of the right column in the withdrawing menu
// ---------------------------------------------------------------------------------------

.memo_printfix_withdraw_positionfix:
push {lr}
ldr  r2,=#0x201A288
ldrb r2,[r2,#0]
cmp  r2,#6
beq  .memo_printfix_withdraw_positionfix_memo
lsl  r1,r0,#1
add  r1,r1,r0
lsl  r1,r1,#2
cmp  r2,#0xF
bne  +
cmp  r0,#0xA
bne  .memo_printfix_withdraw_positionfix_end
add  r1,#4                         //Cover being in the withdraw menu - moves the right column 4 pixels to the right
b    .memo_printfix_withdraw_positionfix_end
+
cmp  r2,#0x10
bne  +
cmp  r0,#0xB
bne  .memo_printfix_withdraw_positionfix_end
add  r1,#4                         //Cover being in the delete all saves menu - moves "No" 4 pixels to the right
b    .memo_printfix_withdraw_positionfix_end
+
cmp  r2,#0x1
bne  .memo_printfix_withdraw_positionfix_end
cmp  r0,#0xB
bne  .memo_printfix_withdraw_positionfix_end
add  r1,#2                         //Cover being in the equipment menu - moves Equipment type's text 2 pixels to the right
b    .memo_printfix_withdraw_positionfix_end

.memo_printfix_withdraw_positionfix_memo:
mov  r0,r5
sub  r0,#0x2
cmp  r0,#1                         //Is this the first letter?
beq  +
mov  r0,#1                         //If it's not, check if it's an icon
sub  r1,r4,#4
ldr  r1,[r1,#0]
cmp  r1,#0
bne  +
mov  r0,#2                         //Cover case when done with memo icon
+
lsl  r1,r0,#1                      //If it's not an icon, the line starts at 1
add  r1,r1,r0
lsl  r1,r1,#2

.memo_printfix_withdraw_positionfix_end:
strh r1,[r6,#0]
pop  {pc}

// ---------------------------------------------------------------------------------------
// Fixes printing in the memo screen. Vertical fix in order to allow more space per line
// ---------------------------------------------------------------------------------------

.memo_printfix_vertical:
push {lr}
bl   $8002FC0
ldr  r1,=#0x201A288
ldrb r1,[r1,#0]
cmp  r1,#6
bne  .memo_printfix_vertical_end
sub  r1,r4,#4
ldr  r1,[r1,#0]              //Get the height from the previous set of bytes
lsr  r0,r1,#0x1C
cmp  r0,#3
bgt  +
mov  r0,#3                   //Memoes start at a height of 3
+

.memo_printfix_vertical_end:
pop  {pc}

// ---------------------------------------------------------------------------------------
// Fixes printing in the memo screen. Changes how letters are stored
// ---------------------------------------------------------------------------------------

.memo_printfix_storage:
push {r3-r4,lr}
ldr  r0,=#0x201A288
ldrb r0,[r0,#0]
cmp  r0,#6
bne  +                       //Do this only for the memo menu

ldr  r0,=#0x201AEF8
ldrb r1,[r0,#3]
add  r1,#0x11
strb r1,[r0,#3]              //Store, as info, the Y we're currently at
ldr  r3,[r4,#0]
sub  r3,r6,r3                //Letters are now stored sequentially, not by line
lsl  r4,r1,#0x1C
lsr  r4,r4,#0x1C
lsr  r2,r3,#1
add  r2,r2,r4
add  r2,#1
strh r2,[r5,#0]


lsl  r3,r2,#2
add  r0,r0,r3
add  r0,#4
lsr  r1,r1,#4
lsl  r1,r1,#4
add  r1,#0x30
strb r1,[r0,#3]              //Store, as info, the Y this line should be at when printed
b    .memo_printfix_storage_end
+

ldrh r0,[r4,#8]              //Default code
strh r0,[r5,#0]
ldrh r0,[r5,#2]
add  r0,#1
strh r0,[r5,#2]

.memo_printfix_storage_end:
pop  {r3-r4,pc}

// ---------------------------------------------------------------------------------------
// Makes each line in the memo screen use 0xFFFFFFFF as its delimiter
// ---------------------------------------------------------------------------------------

.memo_eos:
push {lr}
ldr  r1,=#0x201A288
ldrb r1,[r1,#0]
cmp  r1,#6
bne  .memo_eos_default
mov  r1,#0xFF
lsl  r1,r1,#8
add  r1,#1
cmp  r1,r3
bne  .memo_eos_default

ldr  r1,=#0x2013040
ldrb r0,[r1,#2]
add  r0,#1                   //Increment number of strings
strb r0,[r1,#2]

mov  r1,#1
neg  r1,r1
str  r1,[r2,#0]              //Store an EOS
b    .memo_eos_end

.memo_eos_default:
mov  r1,#1
orr  r0,r1
strb r0,[r2,#2]

.memo_eos_end:
pop  {pc}

// ---------------------------------------------------------------------------------------
// Improves buffer size for the memo menus
// ---------------------------------------------------------------------------------------

.memo_expand_buffer_start_routine:
add  sp,#-0x100
add  sp,#-0x168
lsl  r0,r0,#0x10
bx   lr

.memo_expand_buffer_middle_routine:
ldr  r1,=#0x268
bx   lr

.memo_expand_buffer_end_routine:
add  sp,#0x100
add  sp,#0x168
pop  {r3}
bx   lr

.memo_expand_writing_buffer:
push {lr}
ldr  r2,=#0x201A288
ldrb r2,[r2,#0]
cmp  r2,#6
bne  +
lsl  r0,r0,#2
ldr  r1,=#0x201AEF8
add  r1,#8
add  r0,r1,r0
b    .memo_expand_writing_buffer_end

+
bl   $8049894

.memo_expand_writing_buffer_end:
pop  {pc}

// ---------------------------------------------------------------------------------------
// These hacks are for activating the Memo screen.
// ---------------------------------------------------------------------------------------

.memo_check:
push {r0,lr}
ldr  r0,=#0x4000130
ldrh r0,[r0,#0]
lsl  r0,r0,#0x16
lsr  r0,r0,#0x1E                   // r0 = (r0 & 0x300) >> 8
cmp  r0,#0                         // we're checking for at least L+R, so other buttons are irrelevant
pop  {r0}
beq  +
bl   $804BF34                      // Status
pop  {pc}
+
bl   $804BFCC                      // Memo
pop  {pc}

// ---------------------------------------------------------------------------------------
// This hack fixes the scrolly sprite flashing by enabling the OBJ layer indefinitely
// whenever a scrolly line is being executed.
// ---------------------------------------------------------------------------------------

.scrolly_sprite_fix:
push {r2,lr}
ldrh r1,[r4,#8]
mov  r0,#0xFF
and  r0,r1

// Check for scrolly text
ldr  r2,=#0x203FFF8
ldrh r1,[r2,#0]
cmp  r1,#0
bne  +                             // ignore if not block 0
ldrh r1,[r2,#2]

cmp  r1,#7
beq  .scrolly_do_fix

cmp  r1,#8
beq  .scrolly_do_fix

cmp  r1,#9
beq  .scrolly_do_fix

cmp  r1,#10
beq  .scrolly_do_fix

cmp  r1,#11
beq  .scrolly_do_fix

cmp  r1,#12
beq  .scrolly_do_fix

cmp  r1,#13
beq  .scrolly_do_fix

cmp  r1,#15
beq  .scrolly_do_fix

cmp  r1,#16
beq  .scrolly_do_fix

// Add other lines here if necessary

b    +

.scrolly_do_fix:
mov  r1,#0x80
lsl  r1,r1,#0x5
orr  r0,r1

+
ldrh r1,[r4,#8]
strh r0,[r4,#8]
pop  {r2,pc}

// ---------------------------------------------------------------------------------------
// This hack updates the 203FFF8 RAM area with the block # and line # so that the
// above fix doesn't constantly enable the OBJ layer when it shouldn't be.
// ---------------------------------------------------------------------------------------

// r6 >> 1 == block number
// r7 == line number

.scrolly_sprite_fix2:
push {r0,lr}
ldr  r0,=#0x203FFF8
lsr  r6,r6,#1
strh r6,[r0,#0]
strh r7,[r0,#2]
lsl  r6,r6,#1
pop  {r0}
bl   $800289C                      // clobbered code
pop  {pc}


// ---------------------------------------------------------------------------------------
// This hack stretches the left column of text vertically in the Battle Memory menu.
// ---------------------------------------------------------------------------------------

.battlemem_stretch:
push {r0-r4,lr}
// ----------------------------------------------
// Fill 30040F0 with 1C8 00's
mov  r0,#0
push {r0}
mov  r0,sp
ldr  r1,=#0x30040F0
mov  r2,#1
lsl  r2,r2,#24 // Fill
mov  r3,#0xE4
orr  r2,r3
swi  #0xB
add  sp,#4
// ----------------------------------------------
pop  {r0-r4}
add  r0,r0,r1                      // clobbered code
ldr  r0,[r0,#0]
pop  {pc}


// ---------------------------------------------------------------------------------------
// This hack moves the Key goods cursor left by one pixel in the left column.
// ---------------------------------------------------------------------------------------

.keygoods_cursorfix1:
and  r0,r1                         // clobbered code
mov  r2,#0xFF                      // r2 was originally 0, so to move it left we need to make it -1, or 0xFFFF (signed hword)
lsl  r2,r2,#0x8
add  r2,#0xFF
bx   lr

// ---------------------------------------------------------------------------------------
// PSI menu
.psi_cursorfix1:
and  r0,r1                         // clobbered code
mov  r2,#0xFF                      // we want -3
lsl  r2,r2,#0x8
add  r2,#0xFD
bx   lr

// ---------------------------------------------------------------------------------------
// Withdraw menu
.withdraw_cursorfix1:
and  r0,r1                         // clobbered code
mov  r2,#0xFF                      // we want -3
lsl  r2,r2,#0x8
add  r2,#0xFD
bx   lr

// ---------------------------------------------------------------------------------------
// Skills (other) menu
.skills_cursorfix1:
and  r0,r1                         // clobbered code
mov  r2,#0xFF                      // we want -5
lsl  r2,r2,#0x8
add  r2,#0xFB
bx   lr


//---------------------------------------------------------------------------------------
// double's an enemy's HP at battle start if hard mode is enabled
//---------------------------------------------------------------------------------------

.double_hp1:
push {r4,lr}
push {r0}
bl   .is_hardmode         // see if hard mode is enabled
mov  r4,r0
pop  {r0}
cmp  r4,#0                // if not, skip the math junk
beq  +

lsl  r0,r0,#1             // double the hp

+
str  r0,[r1,#0]
mov  r1,#0x98
pop  {r4,pc}

//------------------------------------------

.double_hp2:
push {r0,lr}

ldr  r1,[r1,#0x14]
bl   .is_hardmode
cmp  r0,#0
beq  +

lsl  r1,r1,#1             // double the hp

+
ldr  r2,[r2,#4]
pop  {r0,pc}


//---------------------------------------------------------------------------------------
// quadruples the enemy's speed at the start of battle if hard mode is enabled
//---------------------------------------------------------------------------------------

.quadruple_speed:
push {r0,lr}

ldrb r1,[r2,#0x1F]  // load normal speed
bl   .is_hardmode   // see if this is hard mode
cmp  r0,#0          // if it isn't, skip the extra math
beq  +

lsl  r1,r1,#2       // quadruple the enemy's speed
mov  r2,#0xFF
cmp  r1,r2
blt  +

mov  r1,#0xFF       // make the speed FF if the doubled value would be too high otherwise

+
ldr  r2,[r3,#4]
pop  {r0,pc}


//---------------------------------------------------------------------------------------
// returns 0 in r0 if the player name isn't "HARD MODE". Returns non-zero if it is.
//---------------------------------------------------------------------------------------

.is_hardmode:
push {r1-r4}
mov  r0,#0                 // return value is FALSE by default
ldr  r3,=#0x2004F26        // player's name in memory is here
ldr  r4,=#hardmodestring   // string to compare against

ldrh r1,[r3,#0]            // compare "HA"
ldrh r2,[r3,#2]
lsl  r2,r2,#16
orr  r1,r2
ldr  r2,[r4,#0]
cmp  r1,r2
bne  +

add  r3,#4                 // compare "RD"
add  r4,#4
ldrh r1,[r3,#0]
ldrh r2,[r3,#2]
lsl  r2,r2,#16
orr  r1,r2
ldr  r2,[r4,#0]
cmp  r1,r2
bne  +

add  r3,#4                 // compare " M"
add  r4,#4
ldrh r1,[r3,#0]
ldrh r2,[r3,#2]
lsl  r2,r2,#16
orr  r1,r2
ldr  r2,[r4,#0]
cmp  r1,r2
bne  +

add  r3,#4                 // compare "OD"
add  r4,#4
ldrh r1,[r3,#0]
ldrh r2,[r3,#2]
lsl  r2,r2,#16
orr  r1,r2
ldr  r2,[r4,#0]
cmp  r1,r2
bne  +

add  r3,#4                 // compare "E[END]"
add  r4,#4
ldrh r1,[r3,#0]
ldrh r2,[r3,#2]
lsl  r2,r2,#16
orr  r1,r2
ldr  r2,[r4,#0]
cmp  r1,r2
bne  +

mov  r0,#1                 // if we made it this far, the strings are equal

+
pop  {r1-r4}
bx   lr

//---------------------------------------------------------------------------------------
// Properly handles equipment position when removing multiple items from an inventory
//---------------------------------------------------------------------------------------
.position_equipment_item_removal:
push {r4-r7,lr}
mov  r7,r1
mov  r6,#0
mov  r3,#1
neg  r3,r3
add  r0,#0x38
mov  r5,r0
add  r4,r0,#4
-

ldrb r0,[r4,#0]
ldrb r1,[r7,#0]
cmp  r0,r1
beq  +
ldr  r0,[r5,#0]
mov  r1,r3
and  r1,r0
lsr  r1,r1,#1
neg  r2,r3
sub  r2,r2,#1
and  r2,r0
orr  r1,r2
str  r1,[r5,#0]
b    .position_equipment_item_removal_end_of_loop
+
add  r4,#1
lsl  r3,r3,#1
.position_equipment_item_removal_end_of_loop:
add  r7,#1
add  r6,#1
cmp  r6,#0xF
ble  -

.position_equipment_item_removal_end:
pop  {r4-r7,pc}

//---------------------------------------------------------------------------------------
// Pushes the battle memo status. 0 if not full in any way, 1 if front sprites are full,
// 2 if back sprites are full, 3 if totally full - 04 00 9C 00
//---------------------------------------------------------------------------------------
.push_battle_memo_status:
push {r4,lr}

// Check for front pics
bl   .allenemies_frontcheck
mov  r4,r0

// Check for the back pics
bl   .allenemies_backcheck
lsl  r0,r0,#1
orr  r0,r4

bl   $80218E8
mov  r0,#0
pop  {r4,pc}

//---------------------------------------------------------------------------------------
// Sets the current money on hand to an arbitrary value - 04 00 9E 00
//---------------------------------------------------------------------------------------
.set_money_on_hand:
push {lr}
mov  r1,#0
bl   $8021914
ldr  r2,=#0x2004860
str  r0,[r2,#8]
mov  r0,#0
pop  {pc}

//---------------------------------------------------------------------------------------
// Pushes the current money on hand. If it's too high, set it to 10000 - 04 00 9F 00
//---------------------------------------------------------------------------------------
.push_money_on_hand:
push {lr}
ldr  r2,=#0x2004860
ldr  r0,[r2,#8]
ldr  r1,=#0xF423F          // Maximum money is 999999
cmp  r0,r1
ble  +
ldr  r1,=#0x2710           // Set it to 10000
str  r1,[r2,#8]
+
bl   $80218E8
mov  r0,#0
pop  {pc}
