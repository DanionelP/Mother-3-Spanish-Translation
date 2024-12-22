outside_hacks:

define current_font_overworld $2027CAC
//===========================================================================================
// This hack centers names in the Name/HP/PP boxes when you press Select outside.
//===========================================================================================

.center_names:
push {r2,r4-r5,lr}
ldr  r2,=#{small_font_width} // This is the address of the 8x8 font width table
mov  r0,r9
mov  r3,#0
mov  r4,#0
mov  r5,#0xFF
lsl  r5,r5,#8

-
ldrh r3,[r0,#0]
add  r0,#2
cmp  r3,r5
bge  +
ldrb r3,[r2,r3]
add  r4,r4,r3
b -

+
lsr  r4,r4,#1
sub  r3,r1,r4
pop  {r2,r4-r5,pc}


//===========================================================================================
// This hack is used in many places throughout the game. It counts strings and parts of
// strings. We're hacking it here to allow for longer character names and nameable names.
//===========================================================================================

.string_length_count:
push {r2,r4-r7,lr}

mov  r5,#0                   // r5 is our count

mov  r2,#8                   // max length of names in RAM
ldr  r4,=#0x200417E          // Flint's name in RAM = $200417E
cmp  r0,r4
beq  .limited_count

add  r4,#0x6C                // Lucas' name in RAM = $20041EA
cmp  r0,r4
beq  .limited_count

add  r4,#0x6C                // Duster's name in RAM = $2004256
cmp  r0,r4
beq  .limited_count

add  r4,#0x6C                // Kumatora's name in RAM = $20042C2
cmp  r0,r4
beq  .limited_count

add  r4,#0x6C                // Boney's name in RAM = $200432E
cmp  r0,r4
beq  .limited_count

add  r4,#0x6C                // Salsa's name in RAM = $200439A
cmp  r0,r4
beq  .limited_count

add  r4,#0xFC
add  r4,#0xFC
add  r4,#0xFC                // Claus's name in RAM = $200468E
cmp  r0,r4
beq  .limited_count

ldr  r4,=#0x2004EE2          // Hinawa's name in RAM = $2004EE2
cmp  r0,r4
beq  .limited_count

add  r4,#0x10                // Claus's repeated name in RAM = $2004EF2
cmp  r0,r4
beq  .limited_count

mov  r2,#9                   // Japanese version allowed for 9 letters...
add  r4,#0x10                // Fav. Food in RAM = $2004F02
cmp  r0,r4
beq  .limited_count

mov  r2,#8                   // back to 8 letters max
add  r4,#0x12                // Fav. Thing in RAM = $200F414
cmp  r0,r4
beq  .limited_count

mov  r2,#16                  // player's name can be 16 letters
add  r4,#0x12                // Player's name in RAM = $800F426
cmp  r0,r4
beq  .limited_count

b    .unlimited_count

//--------------------------------------------------------------------------------------------

.limited_count:
ldr  r4,=#0xFFFF             // r4 is the [END] code

ldrh r1,[r0,#0]              // load current character
cmp  r1,r4                   // is it an end code?
beq  +                       // if so, end
add  r5,#1                   // otherwise increment our count

cmp  r5,r2                   // check to see if we're >= our RAM name limit
bge  +                       // so quit if the name is too far

add  r0,#2                   // and increment the read address by 2
b    .limited_count          // and loop back

//--------------------------------------------------------------------------------------------

.unlimited_count:
ldr  r4,=#0xFFFF             // r4 is the [END] code

ldrh r1,[r0,#0]              // load the current character
cmp  r1,r4                   // is it an end code?
beq  +                       // if so, end
add  r5,#1                   // otherwise increment our count
add  r0,#2                   // and increment the read address by 1
b    .unlimited_count

//--------------------------------------------------------------------------------------------

+
mov  r0,r5                   // r0 now has the count, as the game expects
pop  {r2,r4-r7,pc}


//===========================================================================================
// This routine is meant to trick the game into using a good size for the gray name boxes.
// This is because we now have a VWF in there, so not everything is 8 pixels wide. We're
// basically gonna calculate up the total width of the name, divide it by 8, and round up
// if there's a remainder. Then we'll do some code we clobbered.
//
// There's a chance we might need to insert another hack elsewhere so that the game will
// use the correct # for the string's length and not our output value here.
//
// This hack should be linked from 8023A10.
//
// r0 starts with the string length
// [sp + 8] contains the address of the current string
//
// the resultant value needs to be stored in r7 before leaving

//===========================================================================================
//===========================================================================================
// This is some routine initialization stuff

.gray_box_resize:
push {r1-r6,lr}


mov  r1,r0                   // r1 has the string length now
mov  r2,#0                   // r2 will be our loop counter
mov  r0,#4                   // r0 will be our width counter
ldr  r5,[sp,#0x24]           // load r5 with the address of the string
ldr  r6,=#0x8D1CF78          // r6 has the address of our 8x8 font width table


//--------------------------------------------------------------------------------------------
// Now we need to do a loop to get the total width of the current string


-
ldrh r3,[r5,#0]              // load the current letter
ldrb r3,[r6,r3]              // load the current letter's width
add  r0,r0,r3                // add the current width to the total width


add  r5,#2                   // increment the read address


add  r2,#1                   // increment the loop counter
cmp  r2,r1                   // compare the loop counter with the string length
bge  +                       // if >= string length, then time to move to the math conv. stuff
b    -


//--------------------------------------------------------------------------------------------


+
mov  r7,r0                    // r7 now has the final result
pop  {r1-r6,pc}

//===========================================================================================
// This hack is used in order to better calculate how many grey boxes to use
//===========================================================================================

.gray_box_number:
push {r0-r3}
sub  r7,#0x21                 // Remove the valid tile parts from the beginning and the end.
                              // Each double tile is 16 pixels long, however they all overlap
                              // by 4 pixels, making a double tile 0xC pixels long
mov  r0,#0xB
add  r0,r7,r0                 // By adding 0xB, we make it so the remainder
mov  r1,#0xC                  // now rolls over to the next integer.
swi  #6                       // Divide by 0xC
mov  r7,r0
mov  r8,r7
pop  {r0-r3}
bx   lr

//===========================================================================================
// This hack is used in order to understand whether the game is printing 
// with the 8x8 font or a 16x16 font
//===========================================================================================

.is_small_font:
push {r1-r2}
ldr  r0,=#{current_font_overworld}     //Load the font address
ldr  r0,[r0,#0]
mov  r2,#1
ldr  r1,=#{small_font}                 //Small font address
cmp  r0,r1
beq  +
mov  r2,#0
+
mov  r0,r2                             //Put the output in r2

pop  {r1-r2}
bx   lr

//===========================================================================================
// This hack is used in order to make obj memory occupation less in the overworld by making
// oam size smaller for the 8x8 font
//===========================================================================================

.different_oam_size:
push {r0,lr}
mov  r3,#0x80                //Size 1 (With Square, it's 16x16)
bl   .is_small_font
cmp  r0,#0
beq  +
mov  r3,#0                   //Size 0 (With Square, it's 8x8)
+
lsl  r3,r3,#7

pop  {r0,pc}

//===========================================================================================
// This hack is used in order to make obj memory occupation less in the overworld by making
// tiles assigned to oam closer for the 8x8 font
//===========================================================================================

.different_tiles_add:
push {r1,lr}
bl   .is_small_font
mov  r1,r0
ldr  r0,[sp,#0x24]
add  r0,#1                   //If the font is 8x8, add only 1 to the tile counter
cmp  r1,#1
beq  +
add  r0,#3                   //Otherwise, add 4 to the tile counter
+

pop  {r1,pc}

//===========================================================================================
// This hack is used in order to make obj memory occupation less in the overworld by making
// it so the tiles to which the game prints are closer for the 8x8 font
//===========================================================================================

.different_tiles_print:
push {lr}
bl   .is_small_font
ldr  r3,[sp,#0x10]
add  r3,#0x20                //If the font is 8x8, add only 0x20 to the VRAM counter
cmp  r0,#1
beq  +
add  r3,#0x60                //Otherwise, add 0x80 to the VRAM counter
+

pop  {pc}

//===========================================================================================
// This hack is used in order to make obj memory occupation less in the overworld by making
// it so only the tiles that need to be printed are for the 8x8 font
//===========================================================================================

.different_tiles_storage:
push {lr}
bl   .is_small_font
mov  r1,r0
add  r0,r7,#4

cmp  r1,#0
beq  +
mov  r1,#0x20                //Only prepare for the copy of the 8x8 tile
bl   $8001ACC
mov  r1,r7
add  r1,#0x24
ldr  r0,[sp,#0x10]
add  r0,#0x20
mov  r2,#0x18
swi  #0xC

b    .different_tiles_storage_end
+

mov  r1,#0x40                //Default code for 16x16
bl   $8001ACC
mov  r0,r7
add  r0,#0x44
mov  r1,#0x40
bl   $8001ACC

.different_tiles_storage_end:

pop  {pc}

//============================================================================================
// This section of code stores the letter from the font's data to the stack.
// Main/Castroll font version. Returns if there is data to print or not.
// r0 is the letter. r1 is the stack pointer
//============================================================================================

.fast_prepare_main_castroll_font:
mov  r5,r0
ldr  r2,=#{current_font_overworld}
ldr  r2,[r2,#0]           // get which font we're loading (main or castroll)
lsl  r0,r0,#5
add  r0,r2,r0             // get the address
mov  r1,sp
mov  r2,#0x10
swi  #0xB                 // CpuSet for 0x20 bytes
cmp  r5,#0xFF
ble  +
mov  r5,#3                // set tile usage to max
b    .fast_prepare_main_font_end
+
ldr  r0,=#{main_font_usage}
add  r0,r0,r5
ldrb r5,[r0,#0]           // Load tile usage for the letter
.fast_prepare_main_font_end:
bx   lr

//===========================================================================================
// This hack is used in order to make it so maps aren't loaded too fast by spamming R
//===========================================================================================
define map_block_frames $5
define map_block_address $2004170

.block_loading_map:
ldr  r1,=#{map_block_address}
ldrb r3,[r1,#0]
cmp  r3,#0
beq  +
mov  r0,#0                   //Inaccessible map if this was too fast
b    .block_loading_map_end
+

mov  r3,#{map_block_frames}  //Otherwise setup the timer for the map-side
strb r3,[r1,#0]

.block_loading_map_end:
pop  {r3}                    //Default code
mov  r8,r3
bx   lr

//===========================================================================================
// This hack is used in order to make it so you can't exit maps too fast
//===========================================================================================
.block_loading_map_inside:
push {r4,lr}
ldr  r4,=#{map_block_address}
ldrb r3,[r4,#0]
cmp  r3,#0
bne  +                       //Inaccessible map if this was too fast

bl   $80052E4                //Actual routine that closes the map
mov  r3,#{map_block_frames}  //Setup the timer for the overworld-side
strb r3,[r4,#0]

+
pop  {r4,pc}

//===========================================================================================
// Routine that accesses the map block and decrements it if it's > 0
//===========================================================================================
.decrement_block_map_logic:
push {lr}
ldr  r0,=#{map_block_address}
ldrb r1,[r0,#0]
cmp  r1,#0
beq  .decrement_block_map_logic_end
sub  r1,#1
cmp  r1,#{map_block_frames}
ble  +
mov  r1,#{map_block_frames}
+
strb r1,[r0,#0]

.decrement_block_map_logic_end:
pop  {pc}

//===========================================================================================
// Wrapper that decrements the map block for the normal overworld
//===========================================================================================
.decrement_block_map:
push {lr}
bl   .decrement_block_map_logic
mov  r0,#0                   //Default code
bl   $8036BD8
pop  {pc}

//===========================================================================================
// Wrapper that decrements the map block for the map menu
//===========================================================================================
.decrement_block_map_inside:
push {lr}
bl   .decrement_block_map_logic
ldr  r3,=#0x20196A8          //Default code
ldrh r2,[r3,#0]
pop  {pc}
