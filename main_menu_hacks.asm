main_menu_hacks:

//=============================================================================================
// This set of hacks makes the game load and display long strings on main menu stuff correctly.
//=============================================================================================

.write_item_text:
push {r0-r1,lr}

// custom jeff code
ldr  r0,=#0x201A288
ldrb r0,[r0,#0]
cmp  r0,#6
bne  +
pop  {r0}
str  r0,[sp,#0xC]            // clobbered code
ldr  r0,[r4,#0x0]
pop  {r1,pc}
//

+
mov  r1,#0x58                // # of max letters per item * 4, since each letter has 4 bytes for some reason
cmp  r0,#0x10                //If we're in the loading/saving menu, give some extra space
bne  +
mov  r1,#1
lsl  r1,r1,#8                //This needs to print an actual string, not an item
+
ldr  r0,=#0x2013070          // starting address of our item names in RAM
mul  r1,r6                   // r6 has the current item counter, which is nice and convenient for us
add  r0,r0,r1                // r2 now has the proper spot in RAM for the item

pop  {r1}                    // get the address the game would write to normally
str  r0,[r1,#0x0]            // r0 leaves with the new address in RAM for longer names yay

str  r0,[sp,#0xC]            // clobbered code
ldr  r0,[r4,#0x0]
pop  {r1,pc}

//=============================================================================================

.write_item_eos:
push {lr}

// custom jeff code
ldr  r0,=#0x201A288
ldrb r0,[r0,#0]
cmp  r0,#6
beq  .write_item_eos_memoes

ldr  r1,=#0x2013070
mov  r2,#0x58
cmp  r0,#0x10
bne  +
mov  r2,#1
lsl  r2,r2,#8
+
mov  r0,r10
sub  r0,#1
mul  r0,r2
add  r1,r0,r1
lsl  r6,r6,#2
add  r1,r1,r6
mov  r0,#1
neg  r0,r0
str  r0,[r1,#0]
b    .write_item_eos_end

.write_item_eos_memoes:
ldr  r0,[sp,#8]
mov  r1,#1
neg  r1,r1
str  r1,[r0,#0]

.write_item_eos_end:
mov  r1,r10                  // clobbered code
lsl  r0,r1,#0x10
pop  {pc}

//=============================================================================================

.clear_data:
push {r2-r3,lr}

// custom jeff code
ldr  r2,=#0x201A288
ldrb r2,[r2,#0]
cmp  r2,#6
beq  +
//

mov  r0,#0
push {r0}
mov  r0,sp

ldr  r1,=#0x2013060
ldr  r2,=#0x8EE

mov  r3,#1
lsl  r3,r3,#24
orr  r2,r3                   // set the 24th bit of r2 so it'll know to fill instead of copy
swi  #0x0B                   // clear old data out

add  sp,#4
+
mov  r0,#0xD8 // I assume this is clobbered code?
lsl  r0,r0,#0x7
pop  {r2-r3,pc}

//=============================================================================================

.find_str:
push {lr}

ldr  r2,[sp,#4+0x2C]
ldrb r1,[r2,#0x4]            // swap_address_set
mov  r0,#2

cmp  r1,#1
beq  .find_str_end

mov  r3,#0xAA
lsl  r3,r3,#3
add  r3,r4,r3                // last possible address

-
ldr  r0,[r6,#0x0]            // load the real next value
lsl  r0,r0,#0x14
cmp  r0,#0
bne  .find_str_found
add  r6,#4
cmp  r6,r3
bcs  .find_str_not_found
b    -

.find_str_found:
ldr  r1,[sp,#4+0x20]
cmp  r1,#6
beq  +                       // if this is the memo menu, we don't swap around, still save we're mid-printing

str  r6,[r2,#0]              // save swap_address
ldr  r6,[r6,#0]              // new address

+

mov  r1,#1
strb r1,[r2,#4]              // swap_address_set = true


mov  r0,#1
.find_str_end:
pop  {pc}

.find_str_not_found:
mov  r0,#0                   // not found any string, signal this and reset everything
sub  r2,#0x20
str  r0,[r2,#0]              // set these to 0, we're done printing
b    .find_str_end

//=============================================================================================

.exit_str:
push {lr}

ldr  r2,[sp,#4+0x2C]
ldr  r1,[sp,#4+0x20]
cmp  r1,#6
beq  +

ldrb r1,[r2,#0x4]            // swap_address_set

cmp  r1,#1
bne  +

ldr  r6,[r2,#0]              // load swap_address if not in the memos menu and it's set

+
mov  r1,#0
strb r1,[r2,#4]              // swap_address_set = false

pop  {pc}

//=============================================================================================

// Allocates the tiles buffer for the given input in the stack
.alloc_tiles_buffer:
push {r0-r6,lr}
ldr  r4,[sp,#0x20+4]         // current buffer address
ldr  r5,[sp,#0x20+0x10]      // curr_X
ldr  r6,[sp,#0x20+0xC]       // Y
ldr  r0,[sp,#0x20+0x18]      // Special arrangement loading?
cmp  r0,#0
beq  +
lsr  r0,r5,#3
bl   .new_get_address
b    .alloc_tiles_buffer_got_vram_addr
+
lsr  r0,r5,#3
asr  r1,r6,#3
bl   $80498B0                // VRAM address
.alloc_tiles_buffer_got_vram_addr:
str  r0,[r4,#0]
lsr  r0,r5,#3
asr  r1,r6,#3
bl   $80498C4                // Arrangement address
str  r0,[r4,#4]
ldr  r1,=#0x6008000
ldr  r2,[r4,#0]
sub  r2,r2,r1                // Get how many tiles this is from the start of VRAM
mov  r1,#0x40
add  r1,r0,r1                // Position of bottom arrangements
lsr  r2,r2,#5                // Top arrangements
mov  r3,#0x20
add  r3,r2,r3                // Bottom arrangements
strh r2,[r0,#0]              // Set the buffer arrangements
strh r3,[r1,#0]
add  r2,#1
add  r3,#1
strh r2,[r0,#2]              // Set the buffer arrangements
strh r3,[r1,#2]
add  r2,#1
add  r3,#1
strh r2,[r0,#4]              // Set the buffer arrangements
strh r3,[r1,#4]

// Time to prepare the actual buffers
ldr  r0,[sp,#0x20+0x14]      // Is this the first?
cmp  r0,#0
beq  +

ldr  r0,=#0x2013040
mov  r1,r4
add  r1,#8
ldr  r2,[r0,#8]
str  r2,[r1,#0]
ldr  r2,[r0,#0xC]
str  r2,[r1,#4]
ldr  r2,[r0,#0x10]
str  r2,[r1,#8]              // Restore the old top tile buffer we saved here
add  r1,#0x60
ldr  r2,[r0,#0x14]
str  r2,[r1,#0]
ldr  r2,[r0,#0x18]
str  r2,[r1,#4]
ldr  r2,[r0,#0x1C]
str  r2,[r1,#8]              // Restore the old bottom tile buffer we saved here

mov  r0,#0
push {r0}
mov  r0,sp
mov  r1,#0x28
add  r1,r4,r1
mov  r3,#1
lsl  r3,r3,#0x18
mov  r2,#0x20
orr  r2,r3
swi  #0xB                    // Set the other 2 top tiles of the buffer
mov  r0,sp
mov  r1,#0x88
add  r1,r4,r1
mov  r3,#1
lsl  r3,r3,#0x18
mov  r2,#0x20
orr  r2,r3
swi  #0xB                    // Set the other 2 bottom tiles of the buffer
pop  {r0}

b    .alloc_tiles_buffer_end
+

mov  r0,#0
push {r0}
mov  r0,sp
mov  r1,#8
add  r1,r4,r1
mov  r3,#1
lsl  r3,r3,#0x18
mov  r2,#0x30
orr  r2,r3
swi  #0xB                    // Set the 3 top tiles of the buffer
mov  r0,sp
mov  r1,#0x68
add  r1,r4,r1
mov  r3,#1
lsl  r3,r3,#0x18
mov  r2,#0x30
orr  r2,r3
swi  #0xB                    // Set the 3 bottom tiles of the buffer
pop  {r0}

.alloc_tiles_buffer_end:
ldr  r0,[sp,#0x20+0]         // max_buffers
sub  r0,#1
str  r0,[sp,#0x20+0]
ldr  r0,[sp,#0x20+4]
mov  r1,#0xCC
add  r0,r0,r1
str  r0,[sp,#0x20+4]

mov  r0,#0
str  r0,[sp,#0x20+0x14]      // Set this as not the first
pop  {r0-r6,pc}

//=============================================================================================

// Initializes the specified number of tiles in the buffer.
// It takes in r0 the max amount of buffers to allocate, in r1 the current buffer address,
// X in r2 and Y in r3
.alloc_tiles_buffers:
push {r4-r7,lr}
add  sp,#-0x28
str  r0,[sp,#0]              // max buffers
str  r1,[sp,#4]              // buffer address
str  r2,[sp,#8]              // X
str  r3,[sp,#0xC]            // Y
str  r2,[sp,#0x10]           // curr_X
ldr  r1,[sp,#0x3C+0x1C]
str  r1,[sp,#0x14]           // save whether to reload the first tile or not
ldr  r1,[sp,#0x3C+0x34]
str  r1,[sp,#0x18]           // save extra data for special vram printing
cmp  r1,#0
beq  +
ldr  r1,[sp,#0x3C+0x38]      // WARNING! THESE ARE ALMOST AT THE INSTRUCTION'S RANGE LIMIT!
str  r1,[sp,#0x1C]           // save first base address
ldr  r1,[sp,#0x3C+0x3C]
str  r1,[sp,#0x20]           // save second base address
ldr  r1,[sp,#0x3C+0x40]
str  r1,[sp,#0x24]           // save switch value
+

mov  r1,#7
and  r2,r1
sub  r4,r6,#4                // save str to r4
mov  r5,#0                   // tile_was_printed
mov  r3,#1
neg  r3,r3                   // EOS
ldr  r7,[sp,#0x3C+0x30]

-
add  r4,#4
ldr  r0,[r4,#0x0]            // load the real next value
cmp  r0,r3                   // go to the end if it's EOS
beq  .alloc_tiles_buffers_end
lsl  r0,r0,#0x14
lsr  r0,r0,#0x14             // load the actual value
add  r0,r7,r0
ldrb r0,[r0,#0]              // get the character's length
add  r2,r2,r0                // increase the length
cmp  r5,#0
bne  +

mov  r5,#1                   // set tile_was_printed
bl   .alloc_tiles_buffer     // alloc the buffer
ldr  r0,[sp,#0]
cmp  r0,#0
ble  .alloc_tiles_buffers_end

+
cmp  r2,#0x18
blt  -
ldr  r0,[sp,#0x10]

.alloc_tiles_buffers_subtract_width:
sub  r2,#0x18
add  r0,#0x18
cmp  r2,#0
beq  +
str  r0,[sp,#0x10]
bl   .alloc_tiles_buffer
ldr  r1,[sp,#0]
cmp  r1,#0
ble  .alloc_tiles_buffers_end
cmp  r2,#0x18
bge  .alloc_tiles_buffers_subtract_width
b    -

+
str  r0,[sp,#0x10]
mov  r5,#0                   // unset tile_was_printed
b    -

.alloc_tiles_buffers_end:
ldr  r0,[sp,#0]              // free buffers
add  sp,#0x28
pop  {r4-r7,pc}

//=============================================================================================

.check_special_bit:
push {r2,lr} // why are you pushing r2? :P
strh r1,[r6,#2]              // original code
ldr  r0,[r4,#0]

// custom jeff code
// maybe this is why :O
ldr  r2,=#0x201A288
ldrb r2,[r2,#0]
cmp  r2,#6
beq  +
//

ldr  r0,[r0,#0]              // load the first letter data of the real text in
+
pop  {r2,pc}

//=============================================================================================

.store_total_strings:
// custom jeff code
ldr  r2,=#0x2013040
strb r0,[r2,#2]              // store the strings total
add  r3,sp,#0xC
mov  r8,r3
bx   lr

//=============================================================================================

// 2013040  halfword  total # of letters
// 2013041  ...
// 2013042  byte      total # of passes that will be needed
// 2013043  byte      current pass #
// this routine initializes most of this stuff

.reset_processed_strings:
push {lr}

// custom jeff code
ldr  r4,=#0x2013040          // custom area of RAM for this is here
mov  r2,#0
strb r2,[r4,#3]              // total # of strings processed = 0
pop  {pc}

//=============================================================================================

.load_remaining_strings:
// custom jeff code
ldr  r0,[sp,#0x28]
ldrb r1,[r0,#2]              // get the strings #
ldrb r0,[r0,#3]              // get the currently processed strings
sub  r1,r1,r0
bx   lr

//=============================================================================================

.load_remaining_strings_external:
// custom jeff code
ldr  r0,=#0x2013040
ldrb r1,[r0,#2]              // get the strings #
ldrb r0,[r0,#3]              // get the currently processed strings
sub  r1,r1,r0
bx   lr

//=============================================================================================

.decrement_remaining_strings:
// custom jeff code
ldr  r0,[sp,#0x28]
ldrb r1,[r0,#2]              // get the strings #
ldrb r2,[r0,#3]              // get the currently processed strings
add  r2,#1
strb r2,[r0,#3]              // increase them by 1
sub  r1,r1,r2
bx   lr

//=============================================================================================

.group_add_check:
push {r2-r3}
// custom jeff code
mov  r0,#0                   // this will be the final default result

ldr  r2,=#0x2013040          // address of start of counter area
ldrb r1,[r2,#3]              // load the current string #
ldrb r3,[r2,#2]              // load the total # of strings

cmp  r1,r3                   // is curr_str >= total_str?, if so, set r0 to 4 to signal the end
blt  +                       // if it's <= total_str, skip this extra stuff

mov  r0,#4                   // this will be r0 at the end, it signals the code that items are done
mov  r1,#0                   // set the strings # back to 0
strh r1,[r2,#2]              // set the total length back to 0 so the game won't freak out

+

mov  r1,#7                   // clobbered code
pop  {r2-r3}
bx   lr

//============================================================================================
// This routine converts the VRAM entries from 1bpp to 4bpp.
// We want to go VERY FAST.
//============================================================================================
.convert_1bpp_4bpp:
push {r2,r4-r6,lr}
cmp  r1,#0
beq  .convert_1bpp_4bpp_end

ldr  r6,=#0x8CDF9F8
mov  r2,#0xAA
lsl  r2,r2,#3
add  r5,r2,r4
add  r5,#8                // Starting tiles
mov  r4,r1

.convert_1bpp_4bpp_loop_start:

ldrb r0,[r5,#8]
cmp  r0,#0
beq  +
mov  r0,#3
bl   convert_1bpp_4bpp_tiles
+

.convert_1bpp_4bpp_loop_bottom:

add  r5,#0x60
ldrb r0,[r5,#8]
cmp  r0,#0
beq  +
mov  r0,#3
bl   convert_1bpp_4bpp_tiles
+

.convert_1bpp_4bpp_loop_end:
sub  r4,#1                // One entry is done
cmp  r4,#0
ble  .convert_1bpp_4bpp_end
add  r5,#0x6C
b    .convert_1bpp_4bpp_loop_start

.convert_1bpp_4bpp_end:
pop  {r2,r4-r6,pc}

//=============================================================================================

// THIS CODE AND THE ONE IN text_weld INSIDE sprite_text_hacks ARE BASICALLY THE SAME!
// THEY'RE SEPARATED IN ORDER TO MAXIMIZE PERFORMANCES, BUT IF A BUG IS IN ONE OF THEM,
// IT'S PROBABLY IN THE OTHER ONE AS WELL

//Writes a Glyph stored in r0 to the buffer in r1. r2 is the X and r3 is the letter's info
.write_Glyph_1bpp:
push {r4-r7,lr}              // This is an efficient version of the printing routine
mov  r5,r1
mov  r6,r1
add  r6,#0x20
mov  r4,r0
mov  r7,r2

lsl  r2,r3,#0x10
lsr  r2,r2,#0x1C

mov  r0,#1
strb r0,[r5,#8]              // This tile is used
strb r2,[r5,#9]              // Store the palette

ldr  r3,[sp,#0x14+0x20]      // The current letter's width

cmp  r7,#8
blt  +
mov  r5,r6
add  r6,#0x20
cmp  r7,#0x10
blt  +
sub  r7,#0x10
mov  r5,r6
mov  r0,#0x8C
add  r6,r6,r0
add  r0,r7,r3                // Does this cross to the other tile?
cmp  r0,#8
blt  +
mov  r0,#1
strb r0,[r6,#8]              // This tile is used
strb r2,[r6,#9]              // Store the palette
+

add  r2,r3,#7                // If this isn't a multiple of 8, it will go over a multiple of 8 now
lsr  r2,r2,#3                // Get total tiles number
cmp  r2,#2
blt  +
mov  r2,#2                   // Prevent bad stuff
+

//---------------------------------------------------------------------------------------------

mov  r0,r8
push {r0}
mov  r8,r2
mov  r2,#0xFF                // If we had access to the stack, using a precompiled
mov  r0,#7
and  r0,r7
lsr  r2,r0                   // array would be faster... Probably
lsl  r0,r2,#8
orr  r2,r0
lsl  r0,r2,#0x10
orr  r2,r0

.loop_start:
push {r3,r7}
mov  r0,#7                   // Only consider part of the tile
and  r7,r0

ldr  r3,[r4,#0]              // Load the first 4 rows
mov  r1,r3
lsr  r3,r7                   // Shift them by curr_x
mov  r0,#8
sub  r0,r0,r7
lsl  r1,r0
and  r3,r2                   // Left side
mvn  r2,r2                   // Get the inverted version
and  r1,r2                   // Right side

// TOP FOUR - LEFT
ldr  r0,[r5,#0]              // load what's in the current row
orr  r0,r3                   // OR them together
str  r0,[r5,#0]              // and now store it back

// TOP FOUR - RIGHT
str  r1,[r6,#0]              // and now store it back

// Now we do the bottom four!

ldr  r3,[r4,#4]              // Load the last 4 rows
mov  r1,r3
lsr  r3,r7                   // Shift them by curr_x
mov  r0,#8
sub  r0,r0,r7
lsl  r1,r0
and  r1,r2                   // Right side
mvn  r2,r2                   // Get the inverted version
and  r3,r2                   // Left side

// BOTTOM FOUR - LEFT
ldr  r0,[r5,#4]              // load what's in the current row
orr  r0,r3                   // OR them together
str  r0,[r5,#4]              // and now store it back

// BOTTOM FOUR - RIGHT
str  r1,[r6,#4]              // and now store it back

pop  {r3,r7}

mov  r0,r8                   // increment counter
cmp  r0,#1                   // see if we're still under the # of tiles we need to process
ble  .routine_end
sub  r0,#1
mov  r8,r0
add  r7,#8
mov  r0,r5
mov  r5,r6
add  r6,#0x20
cmp  r7,#0x10
blt  +
add  r6,#0x6C
sub  r3,#8
add  r1,r7,r3
cmp  r1,#8
blt  +
sub  r0,#0x20
ldrb r1,[r0,#9]              // Grab the colour
mov  r0,#1
strb r0,[r6,#8]              // This tile is used
strb r1,[r6,#9]              // Store the palette
+
add  r4,#8
b    .loop_start
//---------------------------------------------------------------------------------------------
.routine_end:
pop  {r0}

mov  r8,r0
pop  {r4-r7,pc}

//=============================================================================================

//Prints a letter in one of the buffers. r0 is the letter, r1 is the buffer, r2 is the X
.print_letter:
push {r4-r7,lr}
add  sp,#-0x24
mov  r7,r0

lsl  r3,r7,#0x14             // load the current letter's width
lsr  r3,r3,#0x14
ldr  r0,[sp,#0x38+0x30]
add  r0,r0,r3
ldrb r3,[r0,#0]              // r3 = letter's width
str  r3,[sp,#0x20]           // the current letter's width

mov  r4,r2
mov  r6,r1
bl   .fast_prepare_main_font // load the letter in the stack
mov  r5,r0
cmp  r5,#0                   // is there something to print at all?
beq  .print_letter_end
sub  r5,#1
cmp  r5,#1                   // is there something to print at the top?
beq  +

mov  r0,sp
mov  r1,r6
add  r1,#8
mov  r2,r4
mov  r3,r7
bl   .write_Glyph_1bpp

+
cmp  r5,#0                   // is there something to print at the bottom?
beq  .print_letter_end

add  r0,sp,#0x10
mov  r1,r6
add  r1,#0x68
mov  r2,r4
mov  r3,r7
bl   .write_Glyph_1bpp

.print_letter_end:
ldr  r0,[sp,#0x20]
add  sp,#0x24
pop  {r4-r7,pc}

//=============================================================================================

//Checks wheter the next letter will overflow the allocated number of buffers
//r0 current letter, r1 number of still not fully used buffers, r2 curr_X in the current "Three tile"
.check_if_overflow:
push {r4,lr}
mov  r4,r1
lsl  r3,r0,#0x14             // load the current letter's width
lsr  r3,r3,#0x14
ldr  r0,[sp,#8+0x30]
add  r0,r0,r3
ldrb r3,[r0,#0]              // r3 = letter's width
add  r0,r2,r3
add  r0,#0x17                // Check for crossing the line
mov  r1,#0x18
swi  #6                      // Divide by 0x18
sub  r2,r4,r0                // Free buffers after this
mov  r0,#0
cmp  r2,#0                   // Are there any free buffers left?
bge  +
mov  r0,#1                   // Signal overflow

+
pop  {r4,pc}

//============================================================================================
// This section of code stores the letter from the font's data to the stack.
// Main font version. Returns if there is data to print or not.
// r0 is the letter. r1 is the stack pointer
//============================================================================================

.fast_prepare_main_font:
ldr  r2,=#{main_font}        // we already know we're loading main font
lsl  r0,r7,#0x14
lsr  r0,r0,#0x14
lsl  r0,r0,#5
add  r0,r2,r0                // get the address
mov  r5,r0
mov  r1,sp
mov  r2,#8
swi  #0xB                    // CpuSet for 0x10 bytes
mov  r0,r5
add  r0,#0x10
add  r1,sp,#0x10
mov  r2,#8
swi  #0xB                    // CpuSet for 0x10 bytes
ldr  r0,=#{main_font_usage}
lsl  r1,r7,#0x14
lsr  r1,r1,#0x14
add  r0,r0,r1
ldrb r0,[r0,#0]              // Load tile usage for the letter
bx   lr

//============================================================================================
// This section of code stores the last tile in a buffer, so it can be reloaded
// later when doing the rest of the strings.
// r1 is the number of used triple tiles buffers.
//============================================================================================

.save_next_tile:
push {r1}
cmp  r1,#0
ble  .save_next_tile_end
ldr  r2,[sp,#4+0x2C]
ldrb r2,[r2,#4]              // Is there a partially incomplete string?
cmp  r2,#0
beq  .save_next_tile_end

ldr  r2,[sp,#4+0x14]
ldr  r0,[sp,#4+0x18]
sub  r2,r2,r0                // Get the currently not fully used buffers
sub  r1,r1,r2                // Get the proper buffer the last tile is in
mov  r0,#0xCC
mul  r1,r0
ldr  r2,[sp,#4+0x24]         // Load the X and Y coords
ldrh r2,[r2,#8]              // Final X
ldr  r0,[sp,#4+8]            // Last X
sub  r0,r2,r0                // X in the final triple tile
mov  r2,#0xAA
lsl  r2,r2,#3
add  r2,r2,r4                // Buffers
add  r2,r2,r1                // Get into the final buffer
add  r2,#8                   // Enter the actual buffer
lsr  r3,r0,#3
lsl  r3,r3,#3
cmp  r0,r3
beq  .save_next_tile_end     // If it's 8-pixels aligned, it won't use this info
lsr  r0,r0,#3
lsl  r0,r0,#5                // Get where the tile is in the buffer
ldr  r1,[sp,#4+0x28]         // Load where to temp store this data
ldr  r3,[r2,#8]              // Load the colour and whether it's used or not - Top Tile
str  r3,[r1,#0x10]
add  r0,r2,r0                // Get to the top tile
ldr  r3,[r0,#0]
str  r3,[r1,#8]
ldr  r3,[r0,#4]
str  r3,[r1,#0xC]            // Store the top tile

add  r2,#0x60                // Process the bottom tile

ldr  r3,[r2,#8]              // Load the colour and whether it's used or not - Bottom Tile
str  r3,[r1,#0x1C]
add  r0,#0x60                // Get to the bottom tile
ldr  r3,[r0,#0]
str  r3,[r1,#0x14]
ldr  r3,[r0,#4]
str  r3,[r1,#0x18]           // Store the bottom tile

.save_next_tile_end:
pop  {r1}
bx   lr

//=============================================================================================
// This hack is called in order to change how everything is printed in VRAM. Based on 0x8048CE4
//=============================================================================================
define max_tiles $28

.print_vram:
push {r4-r7,lr}
mov  r7,r10                            // Base code
mov  r6,r9
mov  r5,r8
push {r5-r7}
add  sp,#-0x44
mov  r4,r0
mov  r0,#{max_tiles}                   // max_tiles = buffer max
str  r0,[sp,#0x10]
str  r1,[sp,#0x34]                     // Save type of arrangements loading to r1
cmp  r1,#0
beq  +
mov  r0,#0x74                          // Change this value if the sp add changes from -0x44 (or the pushes change)!!!
mov  r1,sp                             // This is where the data we want is now
add  r0,r1,r0
ldr  r1,[r0,#0]
str  r1,[sp,#0x38]
ldr  r1,[r0,#4]
str  r1,[sp,#0x3C]
ldr  r1,[r0,#8]
str  r1,[sp,#0x40]
+
ldr  r1,=#0x25F4
add  r0,r4,r1
str  r0,[sp,#0x24]                     // Cache a bunch of values to the stack
ldr  r6,[r0,#0]
ldr  r0,=#0x201A288
ldrb r0,[r0,#0]
str  r0,[sp,#0x20]                     // Which menu this is
ldr  r0,=#{main_font_width}
str  r0,[sp,#0x30]                     // main_font_width
mov  r2,#0xAA
lsl  r2,r2,#3
add  r2,r2,r4
mov  r9,r2
ldr  r0,=#0x2013040
str  r0,[sp,#0x28]                     // Start of the printing data
add  r0,#0x20
str  r0,[sp,#0x2C]                     // Replacement data
bl   .load_remaining_strings           // Load the remaining number of strings
str  r1,[sp,#0xC]
mov  r2,sp
mov  r0,#1
strh r0,[r2,#0]
cmp  r1,#0
bne  +
b    .print_vram_end
+
add  r1,sp,#4
mov  r10,r1
add  r2,sp,#8
mov  r8,r2
mov  r3,#0xC3
lsl  r3,r3,#3
add  r7,r4,r3

.print_vram_start_of_str_loop:
bl   .find_str                         // Search for the next string
cmp  r0,#0
bne  +
b    .print_vram_end
+

sub  r0,#1
str  r0,[sp,#0x1C]                     // Save whether to restore the old tiles or not
cmp  r0,#0
bne  .print_vram_get_old_coords

// COORD STUFF
mov  r0,r4
mov  r1,r6
ldr  r2,[sp,#0x20]
cmp  r2,#6                             // Skip if memo menu
beq  +
ldr  r1,[sp,#0x2C]                     // Load the address this was saved to
ldr  r1,[r1,#0]              
+
add  r2,sp,#4
bl   $8049280                          // Get the string's coords

b    .print_vram_got_coords

.print_vram_get_old_coords:
ldr  r1,[sp,#0x24]
add  r1,#8
ldrh r0,[r1,#0]                        //Load and save old X
mov  r3,r10
strh r0,[r3,#0]
lsr  r2,r0,#3
lsl  r2,r2,#3
cmp  r2,r0                             // If it starts at 0 pixels in a new tile, then it doesn't need to restore the old tiles
bne  +
mov  r0,#0
str  r0,[sp,#0x1C]                     // Don't restore the old tiles
+
ldrh r0,[r1,#2]                        // Load and save old Y
strh r0,[r3,#2]

.print_vram_got_coords:
add  r5,sp,#4
mov  r2,#0
ldsh r2,[r5,r2]
lsr  r1,r2,#3
lsl  r1,r1,#3
str  r1,[sp,#8]
mov  r3,#2
ldsh r3,[r5,r3]
mov  r1,r9
ldr  r0,[sp,#0x10]
bl   .alloc_tiles_buffers              // Allocate the buffers for the string
ldr  r1,[sp,#0x10]
str  r0,[sp,#0x10]                     // New amount of free buffers
sub  r0,r1,r0
str  r0,[sp,#0x14]                     // Amount of buffers used by the string
mov  r0,#0
str  r0,[sp,#0x18]                     // Currently fully used buffers
str  r0,[sp,#0x1C]                     // Do not restore the old tiles

-
mov  r0,#1
neg  r0,r0
ldr  r1,[r6,#0]
cmp  r0,r1
beq  .print_vram_eos

ldr  r1,[sp,#0x14]
ldr  r0,[sp,#0x18]
sub  r1,r1,r0                          // Get the currently not fully used buffers
ldrh r2,[r5,#0]
ldr  r0,[sp,#8]
sub  r2,r2,r0                          // Get the "Three tile" X coord
ldr  r0,[r6,#0]                        // Get the current letter
bl   .check_if_overflow
cmp  r0,#0
bne  .print_vram_out_of_loop

mov  r1,r9
ldr  r0,[sp,#0x18]
mov  r2,#0xCC
mul  r0,r2
add  r1,r1,r0                          // Get the current buffer
ldrh r2,[r5,#0]
ldr  r0,[sp,#8]
sub  r2,r2,r0                          // Get the "Three tile" X coord
ldr  r0,[r6,#0]                        // Load the letter
bl   .print_letter                     // Returns in r0 the current letter's width
ldrh r2,[r5,#0]
add  r2,r2,r0
strh r2,[r5,#0]
ldr  r0,[sp,#8]
sub  r2,r2,r0                          // Get the "Three tile" X coord
cmp  r2,#0x18
blt  +
.print_vram_handle_long_char:
ldr  r0,[sp,#8]
add  r0,#0x18
str  r0,[sp,#8]
ldr  r0,[sp,#0x18]
add  r0,#1                             // Increase the number of fully used buffers
str  r0,[sp,#0x18]
sub  r2,#0x18
cmp  r2,#0x18
bge  .print_vram_handle_long_char
+
.print_vram_end_of_str_loop:
add  r6,#4
b    -

.print_vram_eos:
bl   .exit_str
add  r6,#4
mov  r1,r9
ldr  r0,[sp,#0x14]
mov  r2,#0xCC
mul  r0,r2
add  r1,r1,r0                          // Get the next buffer
mov  r9,r1
bl   .decrement_remaining_strings
ldr  r0,[sp,#0x10]
cmp  r0,#0                             // Have we printed all that we could?
beq  .print_vram_out_of_loop
cmp  r1,#0                             // Have we printed all the strings?
bgt  .print_vram_start_of_str_loop

.print_vram_out_of_loop:
ldr  r0,[sp,#0x24]                     // clobbered code
str  r6,[r0,#0]
mov  r1,r10
ldrh r2,[r1,#0]                        // Save current coords
strh r2,[r0,#8]
ldrh r2,[r1,#2]
strh r2,[r0,#0xA]

.print_vram_end:
ldr  r0,=#0x76D7
add  r2,r4,r0
ldr  r0,[sp,#0x10]
mov  r1,#{max_tiles}                   // Get how many buffers were used
sub  r1,r1,r0
strb r1,[r2,#0]                        // Save the number so the game can use them
bl   .save_next_tile
bl   .convert_1bpp_4bpp
add  sp,#0x44
pop  {r3-r5}
mov  r8,r3
mov  r9,r4
mov  r10,r5
pop  {r4-r7,pc}

//=============================================================================================
// This hack fixes the string used when you try to sell an item at a shop.
//=============================================================================================

.sell_text:
push {r4-r6,lr}
mov  r6,r8
mov  r0,r7
push {r0,r6}
add  sp,#-0x8

mov  r7,#0x26                // starting x position

// Add the sell string to the shitpile
// First get its address
mov  r0,#0x7F                // using entry #0x7D in menus1
bl   $80486A0                // gets the address of the sell string

/// custom mato code!
mov  r8,r0                   // save the address in r0 real quick
ldr  r5,=#0x2014330
ldr  r0,=#0xFFFFFFFF         // clear out our area of RAM we need
mov  r1,r5
ldr  r2,=#0x100
bl   fill_mem

mov  r1,r8                   // copy string to RAM and parse custom CCs
mov  r0,r5
bl   $8048108

mov  r0,r5                   // this is where the string now is
bl   get_string_width
mov  r8,r0                   // store string width in r8
mov  r0,r5                   // give the string address back to r0

// Set the variables/coords and add it to the shitpile
mov  r5,#0x1
neg  r5,r5
mov  r2,#0xF
str  r2,[sp,#0]
mov  r6,#1
str  r6,[sp,#0x4]
mov  r1,r7
mov  r2,#0x87
mov  r3,r5
bl   $8047CDC

// Add the item string to the shitpile
mov  r0,r8                   // pos += width of last string
add  r7,r7,r0

ldr  r4,=#0x201A1FD
ldrb r0,[r4,#0]
mov  r1,#0xC
mov  r2,#0x86
bl   $8046974
ldrb r1,[r4,#0]
mov  r0,#0x2
bl   $8001C5C

push {r0}
bl   get_string_width
mov  r8,r0
pop  {r0}

mov  r4,r0
mov  r1,#0xF
str  r1,[sp,#0x0]
str  r6,[sp,#0x4]
mov  r1,r7
mov  r2,#0x87
mov  r3,#0x16
bl   $8047CDC

mov  r0,r8
add  r1,r7,r0

// Add the question mark to the shitpile
ldr  r0,=#.question_mark     // address of a question mark
mov  r2,#0x87
mov  r3,#1
bl   $8047CDC

// Add yes/no to the shitpile
mov  r0,#0x3
bl   $80486A0
mov  r1,#0xF
str  r1,[sp,#0]
str  r6,[sp,#0x4]
mov  r1,#0x44
mov  r2,#0x93
mov  r3,r5
bl   $8047CDC
mov  r0,#0x4
bl   $80486A0
mov  r2,#0xF
str  r2,[sp,#0]
str  r6,[sp,#0x4]
mov  r1,#0x94
mov  r2,#0x93
mov  r3,r5
bl   $8047CDC

add  sp,#0x8
pop  {r3,r4}
mov  r7,r4
mov  r8,r3
pop  {r4-r6,pc}

.question_mark:
dw $001F


//=============================================================================================
// This hack fixes the string used when you try to sell an equipped item.
//=============================================================================================

.sell_equipped_text:
push {r4-r6,lr}
mov  r6,r8
mov  r0,r7
push {r0,r6}
add  sp,#-0x8

ldr  r0,=#0x2016028
ldr  r1,=#0x41D5
add  r0,r0,r1
ldrb r0,[r0,#0]
mov  r1,#0xC
mov  r2,#0x86
bl   $8046974

mov  r0,#0x82
bl   $80486A0

/// custom mato code!
mov  r8,r0                   // save the address in r0 real quick
ldr  r5,=#0x2014330
ldr  r0,=#0xFFFFFFFF         // clear out our area of RAM we need
mov  r1,r5
ldr  r2,=#0x100
bl   fill_mem

mov  r1,r8                   // copy string to RAM and parse custom CCs
mov  r0,r5
bl   $8048108

mov  r0,r5                   // this is where the string now is
bl   get_string_width
mov  r8,r0                   // store string width in r8
mov  r0,r5                   // give the string address back to r0

mov  r6,#0x1
neg  r6,r6
mov  r5,#0xF
str  r5,[sp,#0]
mov  r4,#0x1
str  r4,[sp,#0x4]
mov  r1,#0x26
mov  r2,#0x87
mov  r3,r6
bl   $8047CDC
mov  r0,#0x3
bl   $80486A0
str  r5,[sp,#0]
str  r4,[sp,#0x4]
mov  r1,#0x44
mov  r2,#0x93
mov  r3,r6
bl   $8047CDC
mov  r0,#0x4
bl   $80486A0
str  r5,[sp,#0]
str  r4,[sp,#0x4]
mov  r1,#0x94
mov  r2,#0x93
mov  r3,r6
bl   $8047CDC

add  sp,#0x8
pop  {r3,r4}
mov  r7,r4
mov  r8,r3
pop  {r4-r6}
pop  {r0}
bx   r0


//=============================================================================================
// This hack fixes the string used when you try to buy an item at a shop.
//=============================================================================================

.buy_text:
push {r4-r6,lr}
mov  r6,r8
mov  r0,r7
push {r0,r6}
add  sp,#-0x8

mov  r7,#0x26                // starting x position

// Add the buy string to the shitpile
// First get its address
mov  r0,#0x7C                // using entry #0x7C in menus1
bl   $80486A0                // gets the address of the buy string

/// custom mato code!
mov  r8,r0                   // save the address in r0 real quick
ldr  r5,=#0x2014330
ldr  r0,=#0xFFFFFFFF         // clear out our area of RAM we need
mov  r1,r5
ldr  r2,=#0x100
bl   fill_mem

mov  r1,r8                   // copy string to RAM and parse custom CCs
mov  r0,r5
bl   $8048108

mov  r0,r5                   // this is where the string now is
bl   get_string_width
mov  r8,r0                   // store string width in r8
mov  r0,r5                   // give the string address back to r0

// Set the variables/coords and add it to the shitpile
mov  r5,#0x1
neg  r5,r5
mov  r2,#0xF
str  r2,[sp,#0]
mov  r6,#1
str  r6,[sp,#0x4]
mov  r1,r7
mov  r2,#0x87
mov  r3,r5
bl   $8047CDC

// Add the item string to the shitpile
mov  r0,r8                   // pos += width of last string
add  r7,r7,r0

ldr  r4,=#0x201A1FD
ldrb r0,[r4,#0]
mov  r1,#0xC
mov  r2,#0x86
bl   $8046974
ldrb r1,[r4,#0]
mov  r0,#0x2
bl   $8001C5C

push {r0}
bl   get_string_width
mov  r8,r0
pop  {r0}

mov  r4,r0
mov  r1,#0xF
str  r1,[sp,#0x0]
str  r6,[sp,#0x4]
mov  r1,r7
mov  r2,#0x87
mov  r3,#0x16
bl   $8047CDC

mov  r0,r8
add  r1,r7,r0

// Add the question mark to the shitpile
ldr  r0,=#.question_mark     // address of a question mark
mov  r2,#0x87
mov  r3,#1
bl   $8047CDC

// Add yes/no to the shitpile
mov  r0,#0x3
bl   $80486A0
mov  r1,#0xF
str  r1,[sp,#0]
str  r6,[sp,#0x4]
mov  r1,#0x44
mov  r2,#0x93
mov  r3,r5
bl   $8047CDC
mov  r0,#0x4
bl   $80486A0
mov  r2,#0xF
str  r2,[sp,#0]
str  r6,[sp,#0x4]
mov  r1,#0x94
mov  r2,#0x93
mov  r3,r5
bl   $8047CDC

add  sp,#0x8
pop  {r3,r4}
mov  r7,r4
mov  r8,r3
pop  {r4-r6,pc}

//=============================================================================================
// This hack fixes the first frame that appears when you try to use an item.
//=============================================================================================

//.setup_block_use_frame1:
//push    {lr}
//ldr     r0,=#0x2003F08 //Don't print menu for the next frame
//mov     r1,#1
//strb    r1,[r0,#0]
//mov     r1,r9
//ldrb    r0,[r1,#0]
//pop     {pc}

//.prevent_printing_maybe:
//push    {lr}
//ldr     r1,=#0x2003F08 //Don't print menu for the next frame
//ldrb    r2,[r1,#0]
//cmp     r2,#1
//bne +
//mov     r2,#0
//strb    r2,[r1,#0]
//mov     r5,#1
//b .end_prevent_printing_maybe
//+
//mov     r5,#0
//.end_prevent_printing_maybe:
//pop     {r1}
//str     r4,[sp,#0]
//str     r5,[sp,#4]
//bx      r1

//.block_normal_use_frame1:
//push    {lr}
//ldr     r0,=#0x2003F08 //Do we need to print this?
//ldrb    r1,[r0,#0]
//cmp     r1,#1
//bne +
//mov     r1,#2
//strb    r1,[r0,#0]
//pop     {r1}
//ldr     r1,=#0x8045E6D //If not, then branch away, we'll have .use_frame1 print instead
//bx      r1
//+
//mov      r0,#0x3E
//bl       $80486A0
//pop     {pc}

//.print_normal_use_frame1:
//push    {lr}
//ldr     r0,=#0x2003F08 //Do we need to print this?
//ldrb    r1,[r0,#0]
//cmp     r1,#2
//bne +
//mov     r1,#1
//strb    r1,[r0,#0]

//push    {r0-r7}
//push    {r5-r6}
//add     sp,#-0x8
//mov     r0,#0x41 // Goods
//bl      $80486A0
//mov     r7,#0x1
//neg     r7,r7
//mov     r6,#0xF
//str     r6,[sp,#0]
//mov     r4,#0x1
//str     r4,[sp,#0x4]
//mov     r1,#0xBF
//mov     r2,#0x07
//mov     r3,r7
//bl      $8047CDC
//add     sp,#0x8
//pop     {r5-r6}
//pop     {r0-r7}

//+
//mov      r0,#0x3E
//bl       $80486A0
//pop     {pc}

//.block_frame1_goods:
//push    {lr}
//ldr     r0,=#0x2003F08 //Do we need to print this?
//ldrb    r1,[r0,#0]
//cmp     r1,#1
//bne +
//mov r1,#2
//strb r1,[r0,#0]
//pop {r1}
//ldr r1,=#0x804045F
//bx r1
//+
//mov      r0,#0x41
//bl       $80486A0
//pop     {pc}

//.use_frame1:
//push    {lr}
//mov     r0,r2
//bl      $8055594 // Call that sets the OAM entries for the text
// Everything from here to the next comment loads the Menu/Use/Give/Drop sprites, so we skip those
//push    {r0-r7}
//push    {r5-r6}
//ldr     r0,=#0x2003F08 //Do we need to print this?
//ldrb    r7,[r0,#0]
//cmp     r7,#1
//bne     .end_use_frame1
//add     sp,#-0x8
//mov     r0,#0x41 // Goods
//bl      $80486A0
//mov     r7,#0x1
//neg     r7,r7
//mov     r6,#0xF
//str     r6,[sp,#0]
//mov     r4,#0x1
//str     r4,[sp,#0x4]
//mov     r1,#0xBF
//mov     r2,#0x07
//mov     r3,r7
//bl      $8047CDC
//mov     r0,#0x3C // Menu
//bl      $80486A0
//mov     r7,#0x1
//neg     r7,r7
//mov     r6,#0xF
//str     r6,[sp,#0]
//mov     r4,#0x0
//str     r4,[sp,#0x4]
//mov     r1,#0x1A
//mov     r2,#0x30
//mov     r3,r7
//bl      $8047CDC
//mov     r0,#0x3E // Use
//bl      $80486A0
//str     r6,[sp,#0]
//str     r4,[sp,#0x4]
//mov     r1,#0x1A
//mov     r2,#0x3C
//mov     r3,r7
//bl      $8047CDC
//mov     r0,#0x3F // Give
//bl      $80486A0
//str     r6,[sp,#0]
//str     r4,[sp,#0x4]
//mov     r1,#0x1A
//mov     r2,#0x48
//mov     r3,r7
//bl      $8047CDC
//mov     r0,#0x40 // Drop
//bl      $80486A0
//str     r6,[sp,#0]
//str     r4,[sp,#0x4]
//mov     r1,#0x1A
//mov     r2,#0x54
//mov     r3,r7
//bl      $8047CDC
//ldr     r0,=#0x2003F08    //If we printed this once, then it's not needed anymore
//mov     r1,#0x0
//strb    r1,[r0,#0]
//add     sp,#0x8
//.end_use_frame1:
//pop     {r5-r6}
//pop     {r0-r7}
//pop     {pc}

//=============================================================================================
// This hack fixes the string used when you try to drop an item.
//=============================================================================================

.drop_text:
// ----------------------------------------------
// Everything from here to the next comment loads the Menu/Use/Give/Drop sprites, so we skip those
push    {r4-r7,lr}
mov     r6,r8
push    {r6}
add     sp,#-0x8
mov     r0,#0x3C // Menu
bl      $80486A0
mov     r7,#0x1
neg     r7,r7
mov     r6,#0xF
str     r6,[sp,#0]
mov     r4,#0x0
str     r4,[sp,#0x4]
mov     r1,#0x1A
mov     r2,#0x30
mov     r3,r7
bl      $8047CDC
mov     r0,#0x3E // Use
bl      $80486A0
str     r6,[sp,#0]
str     r4,[sp,#0x4]
mov     r1,#0x1A
mov     r2,#0x3C
mov     r3,r7
bl      $8047CDC
mov     r0,#0x3F // Give
bl      $80486A0
str     r6,[sp,#0]
str     r4,[sp,#0x4]
mov     r1,#0x1A
mov     r2,#0x48
mov     r3,r7
bl      $8047CDC
mov     r0,#0x40 // Drop
bl      $80486A0
str     r6,[sp,#0]
str     r4,[sp,#0x4]
mov     r1,#0x1A
mov     r2,#0x54
mov     r3,r7
bl      $8047CDC
// ----------------------------------------------
// Get some value
ldr     r0,=#0x2015D98
ldrb    r0,[r0,#0]
// Only load the text if the throw submenu is open (this value << 0x1D < 0)
lsl     r0,r0,#0x1D
cmp     r0,#0x0
blt     .drop_text_end
// ----------------------------------------------
// Load the "-- Throw away?" text address
mov     r0,#0x81
bl      $80486A0

/// custom mato code!
mov  r8,r0                   // save the address in r0 real quick
ldr  r5,=#0x2014330
ldr  r0,=#0xFFFFFFFF         // clear out our area of RAM we need
mov  r1,r5
ldr  r2,=#0x100
bl   fill_mem

mov  r1,r8                   // copy string to RAM and parse custom CCs
mov  r0,r5
bl   $8048108

mov  r0,r5                   // this is where the string now is
bl   get_string_width
mov  r8,r0                   // store string width in r8
mov  r0,r5                   // give the string address back to r0

// ----------------------------------------------
// Add the Throw Away text to the shitpile
mov     r5,#1
str     r6,[sp,#0]
str     r5,[sp,#0x4]
mov     r1,#0x26
mov     r8,r1 // store the current X loc to r9
mov     r2,#0x87
mov     r3,r7
mov     r4,r0 // back up the address
bl      $8047CDC
// ----------------------------------------------
// Get the width of the Throw Away string
mov  r0,r4
bl   get_string_width
add  r8,r0 // xloc += width_of_throwaway
// ----------------------------------------------
// Get the item ID
ldr  r4,=#0x201A1FD
ldrb r0,[r4,#0]
// ----------------------------------------------
// Do something mysterious
mov  r1,#0xC
mov  r2,#0x86
bl   $8046974
// ----------------------------------------------
// Gets the item address
ldrb r1,[r4,#0]
mov  r0,#0x2
bl   $8001C5C
mov  r4,r0
//      r0/r4 = address, r3 = max length
// ----------------------------------------------
// Add the item name to the shitpile
str     r6,[sp,#0]
str     r5,[sp,#0x4]
mov     r1,r8
mov     r2,#0x87
mov     r3,#0x16             // max length for normal items
bl      $8047CDC
// ----------------------------------------------
// Get the width of the item name

mov  r0,r4
bl   get_string_width
add  r8,r0 // xloc += width_of_itemname
// ----------------------------------------------
// Add the question mark to the shitpile
str  r6,[sp,#0]
str  r5,[sp,#0x4]
ldr  r0,=#.question_mark
mov  r1,r8
mov  r2,#0x87
mov  r3,#1
bl   $8047CDC
// ----------------------------------------------
// Add Yes and No to the shitpile
mov     r0,#0x3
bl      $80486A0
str     r6,[sp,#0]
str     r5,[sp,#0x4]
mov     r1,#0x44
mov     r2,#0x93
mov     r3,r7
bl      $8047CDC
mov     r0,#0x4
bl      $80486A0
str     r6,[sp,#0]
str     r5,[sp,#0x4]
mov     r1,#0x94
mov     r2,#0x93
mov     r3,r7
bl      $8047CDC
// ----------------------------------------------
.drop_text_end:
add     sp,#0x8
pop     {r3}
mov     r8,r3
pop     {r4-r7}
pop     {r0}
bx      r0

//=============================================================================================
// This hack fixes the string used when you are asked to equip a bought item.
//=============================================================================================

.equip_text:
push    {r4-r6,lr}
mov     r6,r8
push    {r6}
add     sp,#-0x8
// ----------------------------------------------
// Check the menu status value again
ldr     r0,=#0x2015D98
ldrb    r0,[r0,#0]
lsl     r0,r0,#0x1D
cmp     r0,#0x0
bge     +
// ----------------------------------------------
// If it's negative again, use a different string
mov     r0,#0xB9 // [person] equipped the [item]!
bl      $80486A0
mov     r4,r0
mov     r1,#0x1C
mov     r2,#0x87
bl      $8047F28
b       .equip_text_end
+
// ----------------------------------------------
// Load the "-- Equip now?" text address
mov     r0,#0x80
bl      $80486A0

/// custom mato code!
mov  r8,r0                   // save the address in r0 real quick
ldr  r5,=#0x2014330
ldr  r0,=#0xFFFFFFFF         // clear out our area of RAM we need
mov  r1,r5
ldr  r2,=#0x100
bl   fill_mem

mov  r1,r8                   // copy string to RAM and parse custom CCs
mov  r0,r5
bl   $8048108

mov  r0,r5                   // this is where the string now is
bl   get_string_width
mov  r8,r0                   // store string width in r8
mov  r0,r5                   // give the string address back to r0


// ----------------------------------------------
// Add it to the shitpile
mov     r5,#0xF
str     r5,[sp,#0]
mov     r6,#0x1
str     r6,[sp,#0x4]
mov     r1,#0x26
mov     r8,r1
mov     r2,#0x87
mov     r3,#1
neg     r3,r3
mov     r4,r0
bl      $8047CDC
// ----------------------------------------------
// Get the width of the equip text
mov  r0,r4
bl   get_string_width
add  r8,r0
// ----------------------------------------------
// Do the mystery item function
ldr     r4,=#0x201A1FD
ldrb    r0,[r4,#0]
mov     r1,#0xC
mov     r2,#0x86
bl      $8046974
// ----------------------------------------------
// Get the item address
ldrb    r1,[r4,#0]
mov     r0,#0x2
bl      $8001C5C
mov     r4,r0
// ----------------------------------------------
// Add the item name to the shitpile
str     r5,[sp,#0]
str     r6,[sp,#0x4]
mov     r0,r4
mov     r1,r8
mov     r2,#0x87
mov     r3,#0x16
bl      $8047CDC
// ----------------------------------------------
// Get the width of the item name
mov  r0,r4
bl   get_string_width
add  r8,r0
// ----------------------------------------------
// Add " now?" to the shitpile
str  r5,[sp,#0]
str  r6,[sp,#0x4]
ldr  r0,=#.equip_now_text
mov  r1,r8
mov  r2,#0x87
//mov  r3,#5
mov  r3,#1
bl   $8047CDC
// ----------------------------------------------
// Add Yes and No to the shitpile
mov  r4,#1
neg  r4,r4
mov     r0,#0x3
bl      $80486A0
str     r5,[sp,#0]
str     r6,[sp,#0x4]
mov     r1,#0x44
mov     r2,#0x93
mov     r3,r4
bl      $8047CDC
mov     r0,#0x4
bl      $80486A0
str     r5,[sp,#0]
str     r6,[sp,#0x4]
mov     r1,#0x94
mov     r2,#0x93
mov     r3,r4
bl      $8047CDC
// ----------------------------------------------
.equip_text_end:
add     sp,#0x8
pop     {r3}
mov     r8,r3
pop     {r4-r6}
pop     {r0}
bx      r0

.equip_now_text:
dw $001F
//dw $0040,$004E,$004F,$0057,$001F

//=============================================================================================
// This hack fixes the string used when you are asked to sell a currently equipped item after
// buying new equipment.
//=============================================================================================

//print pc
.sell_old_equip_text:
push    {r4-r7,lr}
mov     r7,r9
mov     r6,r8
push    {r6,r7}
add     sp,#-0x8
// ----------------------------------------------
// Get the address of "Sell your "
mov  r0,#0x7D
bl   $80486A0
mov  r4,r0

// ----------------------------------------------
// Add it to the shitpile
mov  r5,#0xF
str  r5,[sp,#0]
mov  r6,#0x1
str  r6,[sp,#0x4]
mov  r1,#0x26
mov  r8,r1
mov  r2,#0x87
mov  r3,#1
neg  r3,r3
bl   $8047CDC
// ----------------------------------------------
// Get the width of "Sell your "
mov  r0,r4
bl   get_string_width
add  r8,r0
// ----------------------------------------------
// Get the item ID, do the mystery function
ldr     r7,=#0x201A1FD
ldrb    r0,[r7,#0]
mov     r1,#0xC
mov     r2,#0x86
bl      $8046974
// ----------------------------------------------
// Get the item address
ldrb    r1,[r7,#0]
mov     r0,#0x2
bl      $8001C5C
// ----------------------------------------------
// Add the item to the shitpile
mov     r4,r0
str     r5,[sp,#0]
str     r6,[sp,#0x4]
mov     r1,r8
mov     r2,#0x87
mov     r3,#0x16
bl      $8047CDC
// ----------------------------------------------
// Get the item width
mov  r0,r4
bl   get_string_width
add  r8,r0
// ----------------------------------------------
// Do some extra crap; don't touch
ldr     r2,=#0x80E5108
ldrb    r1,[r7,#0]
mov     r0,#0x6C
mul     r0,r1
add     r0,r0,r2
ldrh    r1,[r0,#0xA]
ldr     r0,=#0x201A518
strh    r1,[r0,#0]
// ----------------------------------------------
// Get the address of "-- [DPAMT] DP"
mov     r0,#0x7E
bl      $80486A0
// ----------------------------------------------
// Add the DP text to the shitpile
mov     r1,r8
mov     r2,#0x87
bl      $8047F28 // alternate shitpiler
// ----------------------------------------------
// Get the width of the parsed DP text
ldr  r0,=#0x203FFFC
ldr  r0,[r0,#0]
bl   get_string_width
add  r8,r0
// ----------------------------------------------
// Add Yes and No to the shitpile
mov     r0,#0x3
bl      $80486A0
mov     r4,#1
neg     r4,r4
str     r5,[sp,#0]
str     r6,[sp,#0x4]
mov     r1,#0x44
mov     r2,#0x93
mov     r3,r4
bl      $8047CDC
mov     r0,#0x4
bl      $80486A0
str     r5,[sp,#0]
str     r6,[sp,#0x4]
mov     r1,#0x94
mov     r2,#0x93
mov     r3,r4
bl      $8047CDC
// ----------------------------------------------
add     sp,#0x8
pop     {r3,r4}
mov     r8,r3
mov     r9,r4
pop     {r4-r7}
pop     {r0}
bx      r0

//=============================================================================================
// This hack steps into the menu text parser and stores the parsed address to 203FFFC.
//=============================================================================================

.parser_stepin:
ldr  r0,=#0x203FFF8
str  r6,[r0,#0] // Original address
str  r5,[r0,#4] // Parsed address
lsl  r4,r4,#2
add  r4,r9
bx   lr

// This sets the parsed flag for use with 8047CDC
.parser_stepin2:
ldr  r4,=#0x203FFF7
mov  r5,#1
strb r5,[r4,#0]
mov  r5,r0
mov  r4,r1 // clobbered code
bx   lr

// This adds the real address to the table at 203FFA0
.parser_stepin3:
push {r0,r2,r3}
// r0 = counter
// ----------------------------------------------
// Get the target address ready; addr = 203FFA0 + (counter * 4)
ldr  r1,=#0x203FFA0
lsl  r0,r0,#2
add  r1,r1,r0
// ----------------------------------------------
// Check the parsed flag
ldr  r2,=#0x203FFF7
ldrb r0,[r2,#0]
mov  r3,#0
strb r3,[r2,#0]
cmp  r0,#0
bne  +
// Use the address in r5
str  r5,[r1,#0]
b    .parser_stepin3_end
+
// Use the original address from 203FFF8
add  r2,#1
ldr  r0,[r2,#0]
// ----------------------------------------------
// Store it to the table
str  r0,[r1,#0]

.parser_stepin3_end:
pop  {r0,r2,r3}
mov  r1,r0
lsl  r0,r1,#2 // clobbered code
bx   lr

//=============================================================================================
// This hack applies a VWF to item text and other non-sprite text in the main menus.
//=============================================================================================

.item_vwf:
push {r2,r6,lr}

ldr  r6,[r6,#0]
lsl  r6,r6,#0x14
lsr  r0,r6,#0x14             // r0 has the letter now

ldr  r2,=#{main_font_width}  // r2 now points to the start of 16x16 font's width table
ldrb r0,[r2,r0]              // load r0 with the appropriate width
pop  {r2,r6,pc}

//=============================================================================================
// This hack makes Chapter End (and other stuff?) appear nicely on the file select screens
//=============================================================================================

.chap_end_text:
push {lr}

cmp  r1,#0xCA
bne  +
sub  r0,r0,#2

+
lsl  r0,r0,#0x10
add  r3,r6,r0
asr  r3,r3,#0x10
pop  {pc}

//=============================================================================================
// This hack manually clears the tile layer with non-sprite text on it, since the game
// doesn't seem to want to do it itself all the time. We're basically shoving a bunch of 0s
// into the tilemap.
//
//
// Note that this is buggy so it's not being used now. Fix it later maybe?
//=============================================================================================

.clear_non_sprite_text:
push {lr}

cmp  r4,#0
bne  +

bl   .delete_vram

+
mov  r0,r5                   // clobbered code
mov  r1,r6
pop  {pc}


//=============================================================================================
// This hack implements a VWF for the battle memory non-sprite text.
//=============================================================================================

.battle_mem_vwf:
push {r5,lr}                 // We're going to use r5, so we need to keep it in 
ldr  r5,[sp,#0x08]           // Load r5 with our former LR value? 
mov  r14,r5                  // Move the former LR value back into LR 
ldr  r5,=#0x804999B          // This is different from the other functions. At the old code from the branch,
                             // there is an unconditional branch after mov r0,#8 to this address.
                             // This is where we want to return to.
str  r5,[sp,#0x08]           // Store it over the previous one 
pop  {r5}                    // Get back r5 
add  sp,#0x04                // Get the un-needed value off the stack 

ldr  r0,=#{main_font_width}  // load r0 with the address of our 16x16 font width table (FIX : that was 8x8)
ldrb r0,[r0,r1]
pop  {pc}


//=============================================================================================
// This hack will make the game load alternate text than the game would normally expect.
// This affects:
//   - Short enemy names in the Battle Memory screen
//   - Short enemy names used in gray name boxes outside
//   - Fixed item descriptions in battle, with descs that would normally use status icons
//   - Sleep mode message, which had to be done using prewelded text
//=============================================================================================

.load_alternate_text:
push {r5,lr}                 // We're going to use r5, so we need to keep it in 
ldr  r5,[sp,#0x08]           // Load r5 with our former LR value? 
mov  lr,r5                   // Move the former LR value back into LR 
ldr  r5,[sp,#0x04]           // Grab the LR value for THIS function 
str  r5,[sp,#0x08]           // Store it over the previous one 
pop  {r5}                    // Get back r5 
add  sp,#0x04                // Get the un-needed value off the stack 

push {r5-r6}                 // need to use these registers real quick
cmp  r2,#0x07                // if r2 == 7, then we're dealing with enemy names
beq  .short_enemy_name

cmp  r2,#0x00                // in battle, status icons don't get displayed
beq  .status_icon_text       // so we prepare alternate text

cmp  r1,#0x25                // we have to do some magic to make the sleep mode message work
beq  .sleepmode_text

b    .orig_load_code         // so let's just jump to the original code for non-enemy names

//---------------------------------------------------------------------------------------------

.short_enemy_name:
ldr  r5,=#0x80476FB          // load r5 with 0x80476FB, which we'll use to compare the calling address from
ldr  r6,[sp,#0x1C]           // load in the calling address
cmp  r5,r6                   // if equal, this is for the battle memory menu
beq  +

//Load r5 with the scrolling printing routine for the battle memory
ldr  r5,=#.new_battle_memo_scroll_print_after_function+1
cmp  r5,r6
beq  +                       // if equal, this is for the battle memory menu

ldr  r5,=#0x8023B1F          // load r5 with 0x8023B1F, which is used for the gray name boxes
cmp  r5,r6                    
bne  .orig_load_code         // if not equal, jump to the original code

+
ldr  r0,=#0x8D23494          // load the base address of the abbreviated names list
b    .end_load_code

//---------------------------------------------------------------------------------------------

.status_icon_text:
ldr  r5,=#0x8064B89          // see if this is being loaded from battle, if not, do normal code
ldr  r6,[sp,#0x18]
cmp  r5,r6
bne  .orig_load_code

cmp  r4,#0x8B                // if item # < 0x8B or item # > 0x92, use normal code and desc text
blt  .orig_load_code
cmp  r4,#0x92
bgt  .orig_load_code

ldr  r0,=#0x9F8F004          // else use special item descriptions just for this instance
cmp  r1,#4
bne  +
ldr  r0,=#0x9F8F204

+
b    .end_load_code

//---------------------------------------------------------------------------------------------

.sleepmode_text:
ldr  r5,=#0x9AF3790          // just making extra sure we won't trigger this fix on accident
cmp  r0,r5                   // see if r0 directs to the menus3 block
bne  .orig_load_code         // if it doesn't, skip all this and do the original code

ldr  r5,=#0x9FB0300          // start of custom sleep mode text/data

cmp  r6,#0x1F                // if this is the first sleep mode line, redirect pointer
bne  +                       // if this isn't the first sleep mode line, see if it's the 2nd
mov  r0,r5
add  r0,#2                   // r0 now has the address of the first line of custom SM text
b    .special_end_load

+
cmp  r6,#0x20                // see if this is the 2nd line of sleep mode text
bne  .orig_load_code         // if it isn't, we continue the original load routine as usual
ldrh r0,[r5,#0]              // load the offset to the 2nd line
add  r0,r5,r0                // r0 now has the address to the 2nd line
b    .special_end_load

//---------------------------------------------------------------------------------------------

.orig_load_code:
lsl r1,r1,#0x10              // when this whole routine ends, it will go back to 80028A4
lsr r1,r1,#0x0E
add r1,r1,r0
ldr r1,[r1,#0x04]
add r0,r0,r1

.end_load_code:
pop {r5-r6,pc}               // Pop the registers we used off the stack, and return 

//---------------------------------------------------------------------------------------------

.special_end_load:
mov  r5,lr                   // we need to do some return address magic if we're doing
add  r5,#8                   // the sleep mode text fix
mov  lr,r5
pop  {r5-r6,pc}
                         


//=============================================================================================
// These three little hacks move item descriptions in RAM and allow for up to 256 letters,
// though there wouldn't be enough room in the box for that of course :P
//=============================================================================================

.load_desc_address1:
ldr  r0,=#0x2014330
mov  r2,r8
bx   lr

//---------------------------------------------------------------------------------------------

.load_desc_address2:
mov  r0,r4
ldr  r1,=#0x2014330
bx   lr

//---------------------------------------------------------------------------------------------

.load_desc_clear_length:
ldr  r1,=#0x1F8
mov  r2,r8
bx   lr




//=============================================================================================
// These six hacks allow for longer messages in main menus. The max is somewhere around 200
// letters.
//=============================================================================================

.save_menu_msg_address:
add  r5,#2
ldr  r0,=#0x2014310
str  r5,[r0,#0]
pop  {r4-r7}
pop  {r0}
bx   lr

//---------------------------------------------------------------------------------------------

.load_menu_msg_address:
ldr  r0,=#0x2014310
ldr  r5,[r0,#0]
bx   lr

//---------------------------------------------------------------------------------------------

.init_menu_msg_address:
ldr  r0,=#0x201A374
ldr  r7,=#0x2014310
str  r0,[r7,#0]
mov  r7,#0
mov  r0,#1
bx   lr

//---------------------------------------------------------------------------------------------

.change_menu_msg_address1:
push {r2,lr}
ldr  r0,=#0xFFFFFFFF
ldr  r1,=#0x2014330
ldr  r2,=#0x100
bl   fill_mem
mov  r0,r6
pop  {r2,pc}

//---------------------------------------------------------------------------------------------

.change_menu_msg_address2:
mov  r0,r5
ldr  r1,=#0x2014330
bx   lr

//---------------------------------------------------------------------------------------------

.change_menu_msg_clear_amt:
ldr  r1,=#0x201A510
sub  r1,r1,r5
mov  r2,r8
bx   lr


//=============================================================================================
// This hack processes our custom control codes. Since we don't need to bother with enemy
// stuff here, only custom item control codes need to be handled here.
//
// The custom item control codes are [10 EF] through [15 EF].
//
//   [10 EF] - Prints the proper article if it's the first word of a sentence (ie "A/An")
//   [11 EF] - Prints the proper article if it's not the first word of a sentence (ie "a/an")
//   [12 EF] - Prints an uppercase definite article ("The", etc.)
//   [13 EF] - Prints a lowercase definite article ("the", etc.)
//   [14 EF] - Prints this/these/nothing depending on the item
//   [15 EF] - Prints is/are/nothing depending on the item
//   [16 EF] - Prints it/them depending on the item
//   [17 EF] - Prints was/were depending on the item
//
//   [20 EF] - Prints string fragments about the type of equipment the current item is
//
//=============================================================================================

.execute_custom_cc:
push {r0-r3,lr}

ldrb r0,[r4,#1]                  // load the high byte of the current letter
cmp  r0,#0xEF                    // if it isn't 0xEF, do normal stuff and then leave
beq  +

ldrh r0,[r4,#0]                  // load the correct letter again
strh r0,[r5,#0]                  // store the letter
add  r4,#2                       // increment the read address
add  r5,#2                       // increment the write address
b    .ecc_end                    // leave this subroutine

//---------------------------------------------------------------------------------------------

+
ldrb r0,[r4,#0]                  // load the low byte of the current letter, this is our argument
cmp  r0,#0x20                    // if this is EF20, go do that code elsewhere
beq  +

mov  r2,#0x10
sub  r2,r0,r2                    // r2 = argument - #0x10, this will make it easier to work with

ldr  r0,=#0x201A1FD              // this gets the current item #
ldrb r0,[r0,#0]

mov r1,#9
mul r0,r1                        // r0 = item num * 9
ldr  r1,=#{item_extras_address}  // this is the base address of our extra item data table in ROM
add  r0,r0,r1                    // r0 now has the address of the correct item table
ldrb r0,[r0,r2]                  // r0 now has the proper article entry #
mov  r1,#40
mul  r0,r1                       // calculate the offset into custom_text.bin
ldr  r1,=#{custom_text_address}  // load r1 with the base address of our custom text array in ROM
add  r0,r0,r1                    // r0 now has the address of the string we want

mov  r1,r5                       // r1 now has the address to write to
bl   custom_strcopy              // r0 returns with the # of bytes copied

add  r5,r5,r0                    // update the write address
add  r4,#2                       // increment the read address
b    .ecc_end

//---------------------------------------------------------------------------------------------

+                                // all this code here prints the proper "is equipment" message
ldr  r0,=#0x201A1FD              // this gets the current item #
ldrb r0,[r0,#0]
ldr  r1,=#0x80E510C              // start of item data blocks + item_type address
mov  r2,#0x6C                    // size of each item data block
mul  r0,r2                       // item_num * 6C
add  r0,r0,r1                    // stored at this address is the current item's type
ldrb r0,[r0,#0]                  // load the item type
add  r0,#4                       // add 4 -- starting on line 4 of custom_extras.txt are the strings we want
mov  r1,#40
mul  r0,r1
ldr  r1,=#{custom_text_address}  // this is the base address of our custom text array
add  r0,r0,r1                    // r0 now has the correct address

mov  r1,r5
bl   custom_strcopy              // r0 returns the # of bytes copied

add  r5,r5,r0                    // update the write address
add  r4,#2                       // increment the read address

//---------------------------------------------------------------------------------------------

.ecc_end:
pop  {r0-r3,pc}


//=============================================================================================
// This hack fixes the main menu string length counting routine so that character names
// don't wind up with extra long names. If the counting routine thought a name was > 8,
// manually make the length = 8.
//=============================================================================================

.counter_fix1:
push {lr}
//mov  r5,#8                   // r5 will be the new value to change to if need be

ldr  r0,[sp,#8]              // load r0 with the base address of the string we just counted
bl   check_name              // check if the name is custom
cmp  r0,#0
beq  +

cmp  r3,r0                   // is the length > r5 (normally 8)?
ble  +                       // if not, continue as normal, else manually make it = r5 (normally 8)
mov  r3,r0

+
mov  r0,r3                   // clobbered code
pop  {r4}
mov  lr,r4
pop  {r4,r5}
bx   lr


//=============================================================================================
// This hack fixes the rare case of the menu message "Fav. Food - XXX has XXX of this item."
// The game always assumes the fav. food's max length is 22, because that's the length of
// normal items.
//=============================================================================================

.counter_fix2:
ldr  r2,=#0x2004F02          // load the address of where the fav. food string is stored
cmp  r4,r2                   // if we're working with the fav. food address, alter the max length
bne  +
mov  r0,#9                   // 9 is the max length for fav. food

+
lsl  r0,r0,#0x10             // clobbered code
lsr  r2,r0,#0x10
bx   lr

//=============================================================================================
// This hack deletes the content of VRAM that is being shown
//=============================================================================================
.delete_vram:
push {r0-r2,lr}

mov  r0,#0
push {r0}
mov  r0,sp
ldr  r1,=#0x600E800
ldr  r2,=#0x01000140         // (0x500 => 160 pixels, the GBA screen's height, 24th bit is 1 to fill instead of copying)

swi  #0x0C                   // clear old data out
pop {r0}

pop  {r0-r2,pc}

//=============================================================================================
// This hack deletes the content of text's OAM VRAM that can be used
//=============================================================================================
.delete_oam_vram:
push {r0-r2,lr}

mov  r0,#0
push {r0}
mov  r0,sp
ldr  r1,=#0x06010000
ldr  r2,=#0x01000C00         // (0x3000 => The full OAM we use for text)

swi  #0x0C                   // clear old data out
pop {r0}

pop  {r0-r2,pc}

//=============================================================================================
// This hack deletes the content of a subsection of text's OAM VRAM that can be used
//=============================================================================================

//These 2 values must reflect {new_pos_base_alternative2}!!!
define delete_oam_vram_subsection_target_addr $6012000
define delete_oam_vram_subsection_zone_size ($6013000-$6012000)/$4

.delete_oam_vram_subsection:
push {r0-r3,lr}

mov  r0,#0
push {r0}
mov  r0,sp
ldr  r1,=#{delete_oam_vram_subsection_target_addr}
ldr  r2,=#{delete_oam_vram_subsection_zone_size}
mov  r3,#1
lsl  r3,r3,#0x18
orr  r2,r3                   // (0x1000 => The rest of the OAM)

swi  #0x0C                   // clear old data out
pop {r0}

pop  {r0-r3,pc}

//=============================================================================================
// This hack deletes the content of VRAM in equip when the data shouldn't be shown. Optimized.
//=============================================================================================
.delete_vram_equip:
push {r1-r7,lr}
bl   $805504C                // Get if the character's data can be shown
lsl  r0,r0,#0x10

cmp  r0,#0                   // If it can be shown, jump to the end
beq  +

push {r0}

// Setup
ldr  r6,=#0x01000008         // (0x20 bytes of arrangements, 24th bit is 1 to fill instead of copying)
ldr  r7,=#0x600E9A0
mov  r4,#0x40
lsl  r5,r4,#2
mov  r0,#0
push {r0}

//Actual clearing

//Weapon
//First row
mov  r0,sp
mov  r1,r7
mov  r2,r6
swi  #0x0C                   // clear old data out
//Second row
mov  r0,sp
add  r1,r7,r4
mov  r2,r6
swi  #0x0C                   // clear old data out

add  r7,r7,r5                // Next section

//Body
//First row
mov  r0,sp
mov  r1,r7
mov  r2,r6
swi  #0x0C                   // clear old data out
//Second row
mov  r0,sp
add  r1,r7,r4
mov  r2,r6
swi  #0x0C                   // clear old data out

add  r7,r7,r5                // Next section

//Head
//First row
mov  r0,sp
mov  r1,r7
mov  r2,r6
swi  #0x0C                   // clear old data out
//Second row
mov  r0,sp
add  r1,r7,r4
mov  r2,r6
swi  #0x0C                   // clear old data out

add  r7,r7,r5                // Next section

//Other
//First row
mov  r0,sp
mov  r1,r7
mov  r2,r6
swi  #0x0C                   // clear old data out
//Second row
mov  r0,sp
add  r1,r7,r4
mov  r2,r6
swi  #0x0C                   // clear old data out

pop  {r0}                    // Ending
pop  {r0}

+
pop  {r1-r7,pc}

//=============================================================================================
// This hack deletes the content of VRAM in status when the data shouldn't be shown. Optimized.
//=============================================================================================
.delete_vram_status:
push {r1-r7,lr}
bl   $805504C                // Get if the character's data can be shown
lsl  r0,r0,#0x10

cmp  r0,#0                   // If it can be shown, jump to the end
beq  +

push {r0}

// Setup
ldr  r6,=#0x0100000E         // (0x1C bytes of arrangements, 24th bit is 1 to fill instead of copying)
ldr  r7,=#0x600EAA4
mov  r4,#0x40
lsl  r5,r4,#1
mov  r0,#0
push {r0}

//Actual clearing

//Weapon
//First row
mov  r0,sp
mov  r1,r7
mov  r2,r6
swi  #0x0B                   // clear old data out
//Second row
mov  r0,sp
add  r1,r7,r4
mov  r2,r6
swi  #0x0B                   // clear old data out

add  r7,r7,r5                // Next section

//Body
//First row
mov  r0,sp
mov  r1,r7
mov  r2,r6
swi  #0x0B                   // clear old data out
//Second row
mov  r0,sp
add  r1,r7,r4
mov  r2,r6
swi  #0x0B                   // clear old data out

add  r7,r7,r5                // Next section

//Head
//First row
mov  r0,sp
mov  r1,r7
mov  r2,r6
swi  #0x0B                   // clear old data out
//Second row
mov  r0,sp
add  r1,r7,r4
mov  r2,r6
swi  #0x0B                   // clear old data out

add  r7,r7,r5                // Next section

//Other
//First row
mov  r0,sp
mov  r1,r7
mov  r2,r6
swi  #0x0B                   // clear old data out
//Second row
mov  r0,sp
add  r1,r7,r4
mov  r2,r6
swi  #0x0B                   // clear old data out

add  r7,r7,r5                // Next section

//Skill
//First row
mov  r0,sp
mov  r1,r7
mov  r2,r6
swi  #0x0B                   // clear old data out
//Second row
mov  r0,sp
add  r1,r7,r4
mov  r2,r6
swi  #0x0B                   // clear old data out

pop  {r0}                    // Ending
pop  {r0}

+
pop  {r1-r7,pc}

//=============================================================================================
// This hack deletes the content of VRAM that is being shown when going from the inventory to the battle memory
// It also clears OAM's text VRAM.
//=============================================================================================
.delete_vram_inv_to_battle_memory:
push {lr}

bl   .delete_vram
bl   .delete_oam_vram

bl   $800399C                // Clobbered code
pop  {pc}

//=============================================================================================
// This hack deletes the content of VRAM that is being shown when going from the battle memory to the inventory
// It also clears OAM's text VRAM.
//=============================================================================================
.delete_vram_battle_memory_to_inv:
push {lr}

bl   .delete_vram
bl   .delete_oam_vram

bl   $804BE64                // Clobbered code
pop  {pc}

//=============================================================================================
// This hack puts an alternate menu text palette for certain menus. Used for optimizing
//=============================================================================================
.add_extra_menu_palette:
push {lr}
bl   $800160C                //Normal expected code

ldr  r0,=#0x2004100
ldrb r0,[r0,#0]
cmp  r0,#2                   // Is this the PSI menu?
beq  +
cmp  r0,#5                   // Or the shop's menu?
bne  .add_extra_menu_palette_end
+
mov  r0,r4                   // If it is, load an extra palette as the 8th one
ldr  r1,=#{alternate_menu_text_palette}
mov  r2,#0x08
mov  r3,#0x20
bl   $800160C

.add_extra_menu_palette_end:
pop  {pc}

//=============================================================================================
// This hack changes how up/down scrolling in menus works - Based off of 0x8046D90, which is basic menu printing
//=============================================================================================

.new_print_menu_offset_table:
  dd .new_main_inventory_scroll_print+1; dd .new_equip_print+1; dd .new_psi_scroll_print+1; dd .new_status_print+1
  dd .new_skills_scroll_print+1; dd .new_memoes_scroll_print+1; dd .new_default_scroll_print+1; dd .new_battle_memo_scroll_print+1
  dd .new_default_scroll_print+1; dd .new_default_scroll_print+1; dd .new_shop_scroll_print+1; dd .new_shop_scroll_print+1
  dd .new_default_scroll_print+1; dd .new_default_scroll_print+1; dd .new_default_scroll_print+1; dd .new_withdrawing_scroll_print+1
  dd .new_default_scroll_print+1; dd .new_default_scroll_print+1; dd .new_default_scroll_print+1; dd .new_default_scroll_print+1
  dd .new_default_scroll_print+1; dd .new_default_scroll_print+1; dd .new_default_scroll_print+1; dd .new_default_scroll_print+1
  dd .new_default_scroll_print+1; dd .new_default_scroll_print+1; dd .new_default_scroll_print+1; dd .new_default_scroll_print+1
  dd .new_default_scroll_print+1; dd .new_default_scroll_print+1; dd .new_default_scroll_print+1; dd .new_default_scroll_print+1

.new_print_menu_offset_table_special:
  dd .new_equip_submenu_scroll_print+1; dd .new_equip_submenu_scroll_print+1; dd .new_equip_submenu_scroll_print+1; dd .new_equip_submenu_scroll_print+1
  
.new_print_menu_addition_value_table:
  dw $41EC; dw $41F4; dw $41EC; dw $41EC; dw $41EC; dw $41FC; dw $41EC; dw $41FC;
  dw $41EC; dw $41EC; dw $4204; dw $4204; dw $41EC; dw $41EC; dw $41EC; dw $41EC;
  dw $41EC; dw $41EC; dw $41EC; dw $41EC; dw $41EC; dw $41EC; dw $41EC; dw $41EC;
  dw $41EC; dw $41EC; dw $41EC; dw $41EC; dw $41EC; dw $41EC; dw $41EC; dw $41EC;

.new_print_menu_up_down:
push {r4,lr}
ldr  r3,=#0x2016028                    // Base code
ldr  r0,=#0x44F2
add  r2,r3,r0
ldrb r1,[r2,#0]
lsl  r0,r1,#0x1C
cmp  r0,#0
bge  +
b    .end_new_print_menu_up_down
+
mov  r0,#8
orr  r0,r1
strb r0,[r2,#0]
ldr  r1,=#0x4260
add  r0,r3,r1                          //Get the type of menu this is
ldrb r0,[r0,#0]
cmp  r0,#0x10
bhi  +
ldr  r2,=#.new_print_menu_addition_value_table
lsl  r0,r0,#1
ldsh r2,[r2,r0]
ldr  r0,=#0x2016078
add  r1,r0,r2
mov  r2,#1
mov  r3,#0

bl   .new_clear_menu                   //New code!!!

+
bl   $8049D5C                          //Back to base code
ldr  r3,=#0x2016028
ldr  r1,=#0x41C6
add  r0,r3,r1
ldrb r1,[r0,#0]
mov  r0,#1
and  r0,r1
cmp  r0,#0
beq  +
ldr  r2,=#0x41BC
add  r1,r3,r2
ldrh r0,[r1,#0]
cmp  r0,#3
bhi  .end_new_print_menu_up_down
ldrh r1,[r1,#0]
lsl  r1,r1,#2
ldr  r0,=#.new_print_menu_offset_table_special
add  r1,r1,r0
ldrh r0,[r1,#0]
ldrh r1,[r1,#2]
lsl  r1,r1,#0x10
orr  r1,r0
ldr  r4,=#0x3060
add  r0,r3,r4
bl   $8091938
b    .end_new_print_menu_up_down
+
ldr  r0,=#0x4260
add  r2,r3,r0
ldrb r0,[r2,#0]
cmp  r0,#0x12
bhi  .end_new_print_menu_up_down
lsl  r0,r0,#5
mov  r4,#0xB8
lsl  r4,r4,#6
add  r1,r3,r4
add  r0,r0,r1
ldr  r1,=#0x201A288
ldrb r1,[r1,#0]
lsl  r1,r1,#2
ldr  r2,=#.new_print_menu_offset_table
add  r1,r2,r1
ldrh r2,[r1,#2]
lsl  r2,r2,#0x10
ldrh r1,[r1,#0]
add  r1,r1,r2

bl   $8091938  // New code!

.end_new_print_menu_up_down:
pop  {r4,pc}

//=============================================================================================
// This hack changes how a removal in menus works - Based off of 0x8046D90, which is basic menu printing
// Same code as above except for the points in which it's present the comment DIFFERENT!!!
//=============================================================================================

.new_print_menu_a_offset_table:
  dd .new_default_scroll_print+1; dd .new_default_scroll_print+1; dd .new_default_scroll_print+1; dd .new_default_scroll_print+1
  dd .new_default_scroll_print+1; dd .new_default_scroll_print+1; dd .new_default_scroll_print+1; dd .new_default_scroll_print+1
  dd .new_default_scroll_print+1; dd .new_default_scroll_print+1; dd .new_default_scroll_print+1; dd .new_shop_scroll_print+1
  dd .new_default_scroll_print+1; dd .new_default_scroll_print+1; dd .new_default_scroll_print+1; dd .new_withdrawing_a_print+1
  dd .new_default_scroll_print+1; dd .new_default_scroll_print+1; dd .new_default_scroll_print+1; dd .new_default_scroll_print+1
  dd .new_default_scroll_print+1; dd .new_default_scroll_print+1; dd .new_default_scroll_print+1; dd .new_default_scroll_print+1
  dd .new_default_scroll_print+1; dd .new_default_scroll_print+1; dd .new_default_scroll_print+1; dd .new_default_scroll_print+1
  dd .new_default_scroll_print+1; dd .new_default_scroll_print+1; dd .new_default_scroll_print+1; dd .new_default_scroll_print+1

.new_print_menu_a:
push {r4,lr}
ldr  r3,=#0x2016028                    // Base code
ldr  r0,=#0x44F2
add  r2,r3,r0
ldrb r1,[r2,#0]
lsl  r0,r1,#0x1C
cmp  r0,#0
bge  +
b    .end_new_print_menu_a
+
mov  r0,#8
orr  r0,r1
strb r0,[r2,#0]
ldr  r1,=#0x4260
add  r0,r3,r1                          //Get the type of menu this is
ldrb r0,[r0,#0]
cmp  r0,#0x10
bhi  +
ldr  r2,=#.new_print_menu_addition_value_table
lsl  r0,r0,#1
ldsh r2,[r2,r0]
ldr  r0,=#0x2016078
add  r1,r0,r2
mov  r2,#1
mov  r3,#0

bl   .new_clear_menu_a                 //DIFFERENT!!!

+
bl   $8049D5C                          //Back to base code
ldr  r3,=#0x2016028
ldr  r1,=#0x41C6
add  r0,r3,r1
ldrb r1,[r0,#0]
mov  r0,#1
and  r0,r1
cmp  r0,#0
beq  +
ldr  r2,=#0x41BC
add  r1,r3,r2
ldrh r0,[r1,#0]
cmp  r0,#3
bhi  .end_new_print_menu_a
ldr  r0,=#0x9B8FD74
ldrh r1,[r1,#0]
lsl  r1,r1,#2
add  r1,r1,r0
ldr  r4,=#0x3060
add  r0,r3,r4
ldr  r1,[r1,#0]
bl   $8091938
b    .end_new_print_menu_a
+
ldr  r0,=#0x4260
add  r2,r3,r0
ldrb r0,[r2,#0]
cmp  r0,#0x12
bhi  .end_new_print_menu_a
lsl  r0,r0,#5
mov  r4,#0xB8
lsl  r4,r4,#6
add  r1,r3,r4
add  r0,r0,r1
ldr  r1,=#0x201A288
ldrb r1,[r1,#0]
lsl  r1,r1,#2                          //DIFFERENT!!!
ldr  r2,=#.new_print_menu_a_offset_table
add  r1,r2,r1
ldrh r2,[r1,#2]
lsl  r2,r2,#0x10
ldrh r1,[r1,#0]
add  r1,r1,r2

bl   $8091938  // New code!

.end_new_print_menu_a:
pop  {r4,pc}

//=============================================================================================
// This hack changes how menu clearing works, based off of 0x80012BC
//=============================================================================================

.new_swap_arrangement_routine_table:
  dd .new_clear_inventory+1; dd .new_clear_equipment+1; dd .new_clear_inventory+1; dd .new_clear_status+1
  dd .new_clear_inventory+1; dd .new_clear_memoes+1; dd .new_clear_inventory+1; dd .new_clear_battle_memo+1
  dd .new_clear_inventory+1; dd .new_clear_inventory+1; dd .new_clear_shop+1; dd .new_clear_shop+1
  dd .new_clear_inventory+1; dd .new_clear_inventory+1; dd .new_clear_inventory+1; dd .new_clear_inventory+1
  dd .new_clear_inventory+1; dd .new_clear_inventory+1; dd .new_clear_inventory+1; dd .new_clear_inventory+1
  dd .new_clear_inventory+1; dd .new_clear_inventory+1; dd .new_clear_inventory+1; dd .new_clear_inventory+1
  dd .new_clear_inventory+1; dd .new_clear_inventory+1; dd .new_clear_inventory+1; dd .new_clear_inventory+1
  dd .new_clear_inventory+1; dd .new_clear_inventory+1; dd .new_clear_inventory+1; dd .new_clear_inventory+1

.new_swap_arrangement_routine_special_table:
  dd .new_clear_equip_submenu+1; dd .new_clear_equip_submenu+1; dd .new_clear_equip_submenu+1; dd .new_clear_equip_submenu+1

.new_clear_menu:
push {r4-r7,lr}
mov  r7,r8                             //base code
push {r7}
add  sp,#-0xC
mov  r8,r0
mov  r5,r1
lsl  r2,r2,#0x10
lsr  r7,r2,#0x10
mov  r0,sp
strh r3,[r0,#0]
cmp  r5,#0
beq  .new_clear_menu_next_spot
mov  r1,#0
ldsh r0,[r5,r1]
cmp  r0,#0
bge  +
add  r0,#7
+
lsl  r0,r0,#0xD
lsr  r0,r0,#0x10
ldr  r2,=#0xFFFF0000
ldr  r1,[sp,#4]
and  r1,r2
orr  r1,r0
str  r1,[sp,#4]
mov  r1,#2
ldsh r0,[r5,r1]
cmp  r0,#0
bge  +
add  r0,#7
+
asr  r0,r0,#3
add  r4,sp,#4
strh r0,[r4,#2]
ldrh r0,[r5,#4]
lsr  r0,r0,#3
strh r0,[r4,#4]
ldrh r0,[r5,#6]
lsr  r0,r0,#3
strh r0,[r4,#6]
ldrh r2,[r4,#0]
ldrh r3,[r4,#2]
mov  r0,r8
mov  r1,r7
bl   $8001378
mov  r5,r0
mov  r6,#0
ldrh r0,[r4,#6]
cmp  r6,r0
bcs  +

//New code!
ldr  r0,=#0x201A1EE                    //If this is an equip submenu, load the special table
ldrb r0,[r0,#0]
mov  r1,#1
and  r0,r1
cmp  r0,#0
beq  .new_clear_menu_normal_menu
ldr  r0,=#0x201A1E4
ldrb r0,[r0,#0]
cmp  r0,#3
bhi  +
lsl  r0,r0,#2
ldr  r1,=#.new_swap_arrangement_routine_special_table
b    .new_clear_menu_load_address

.new_clear_menu_normal_menu:
ldr  r0,=#0x201A288                    //This is a normal menu
ldrb r0,[r0,#0]
lsl  r0,r0,#2
ldr  r1,=#.new_swap_arrangement_routine_table

.new_clear_menu_load_address:
add  r1,r1,r0
ldrh r0,[r1,#0]
ldrh r1,[r1,#2]
lsl  r1,r1,#0x10
add  r1,r1,r0
bl   $8091938
b    +

.new_clear_menu_next_spot:             //Back to base code
mov  r0,r8
mov  r1,r7
mov  r2,#0
mov  r3,#0
bl   $8001378
mov  r5,r0
mov  r1,#0x80
lsl  r1,r1,#4
bl   $80019DC
+
.new_clear_menu_general:
mov  r0,sp
ldrh r0,[r0,#0]
cmp  r0,#0
beq  +
lsl  r1,r7,#1
mov  r0,#0xB1
lsl  r0,r0,#6
add  r0,r8
add  r0,r0,r1
ldrh r1,[r0,#0]
mov  r1,#1
strh r1,[r0,#0]
+
add  sp,#0xC
pop  {r3}
mov  r8,r3
pop  {r4-r7,pc}

//=============================================================================================
// This hack changes how menu clearing works, based off of 0x80012BC
// Same as above, except it cuts a part
//=============================================================================================
.new_clear_menu_a:
push {r4-r7,lr}
mov  r7,r8                             //base code
push {r7}
add  sp,#-0xC
mov  r8,r0
mov  r5,r1
lsl  r2,r2,#0x10
lsr  r7,r2,#0x10
mov  r0,sp
strh r3,[r0,#0]
cmp  r5,#0
bne  +
b    .new_clear_menu_next_spot
+
mov  r1,#0
ldsh r0,[r5,r1]
cmp  r0,#0
bge  +
add  r0,#7
+
lsl  r0,r0,#0xD
lsr  r0,r0,#0x10
ldr  r2,=#0xFFFF0000
ldr  r1,[sp,#4]
and  r1,r2
orr  r1,r0
str  r1,[sp,#4]
mov  r1,#2
ldsh r0,[r5,r1]
cmp  r0,#0
bge  +
add  r0,#7
+
asr  r0,r0,#3
add  r4,sp,#4
strh r0,[r4,#2]
ldrh r0,[r5,#4]
lsr  r0,r0,#3
strh r0,[r4,#4]
ldrh r0,[r5,#6]
lsr  r0,r0,#3
strh r0,[r4,#6]
ldrh r2,[r4,#0]
ldrh r3,[r4,#2]
mov  r0,r8
mov  r1,r7
bl   $8001378

b    .new_clear_menu_general

//=============================================================================================
// Swaps the arrangements' place for the inventory
//=============================================================================================
.new_clear_inventory:
push {lr}
bl   .get_direction
cmp  r0,#0
bne  .new_clear_inventory_descending
//Swap arrangements' place - if we're ascending
mov  r1,r5
mov  r0,#0x38
lsl  r0,r0,#4
add  r4,r1,r0                          // Get to bottom
-
mov  r1,r4
mov  r0,#0x80
sub  r4,r4,r0
mov  r0,r4
mov  r2,#0x20                          // Put the arrangements one below
swi  #0xC
cmp  r4,r5
bgt  -
mov  r0,#0
push {r0}
mov  r0,sp
mov  r1,r5
ldr  r2,=#0x01000020                   // (0x80 bytes of arrangements, 24th bit is 1 to fill instead of copying)
swi  #0xC
pop  {r0}
b    .new_clear_inventory_end

//Swap arrangements' place - if we're descending
.new_clear_inventory_descending:
mov  r1,r5
mov  r0,#0x80
add  r0,r0,r1
mov  r2,#0xE0                          // Put the arrangements one above
swi  #0xC
mov  r0,#0
push {r0}
mov  r0,#0x38
lsl  r1,r0,#4
mov  r0,sp
add  r1,r1,r5
ldr  r2,=#0x01000020                   // (0x80 bytes of arrangements, 24th bit is 1 to fill instead of copying)
swi  #0xC
pop  {r0}

.new_clear_inventory_end:
pop  {pc}

//=============================================================================================
// Clears the arrangements for the Status menu
//=============================================================================================
.new_clear_status:
push {lr}
mov  r1,r5
mov  r0,#0x69
lsl  r0,r0,#2
add  r4,r1,r0
mov  r3,#0
-
push {r3}
mov  r0,#0
push {r0}
mov  r0,sp
mov  r1,r4
ldr  r2,=#0x0100000E                   // (0x18 bytes of arrangements, 24th bit is 1 to fill instead of copying)
swi  #0xB
mov  r0,sp
mov  r1,r4
add  r1,#0x40
ldr  r2,=#0x0100000E                   // (0x18 bytes of arrangements, 24th bit is 1 to fill instead of copying)
swi  #0xB
pop  {r0}
pop  {r3}
mov  r0,#8
lsl  r0,r0,#4
add  r4,r4,r0                          // Prepare the next one
add  r3,#1
cmp  r3,#5
bne  -

pop  {pc}

//=============================================================================================
// Clears the arrangements for the Equipment menu
//=============================================================================================
.new_clear_equipment:
push {lr}
mov  r1,r5
mov  r0,#0x84
add  r4,r1,r0
mov  r3,#0
-
push {r3}
mov  r0,#0
push {r0}
mov  r0,sp
mov  r1,r4
ldr  r2,=#0x0100000E                   // (0x18 bytes of arrangements, 24th bit is 1 to fill instead of copying)
swi  #0xB
mov  r0,sp
mov  r1,r4
add  r1,#0x40
ldr  r2,=#0x0100000E                   // (0x18 bytes of arrangements, 24th bit is 1 to fill instead of copying)
swi  #0xB
pop  {r0}
pop  {r3}
mov  r0,#1
lsl  r0,r0,#8
add  r4,r4,r0                          // Prepare the next one
add  r3,#1
cmp  r3,#4
bne  -

pop  {pc}

//=============================================================================================
// Swaps the arrangements' place for the equipment submenu
//=============================================================================================
.new_clear_equip_submenu:
push {lr}
bl   .get_direction_submenu
cmp  r0,#0
bne  .new_clear_equip_submenu_descending
//Swap arrangements' place - if we're ascending
mov  r1,r5
mov  r0,#0x38
lsl  r0,r0,#4
add  r4,r1,r0                          // Get to bottom
-
mov  r1,r4
mov  r0,#0x80
sub  r0,r4,r0
mov  r2,#0x8                          // Put the arrangements one below
swi  #0xC
mov  r1,r4
mov  r0,#0x80
sub  r4,r4,r0
mov  r0,r4
add  r0,#0x40
add  r1,#0x40
mov  r2,#0x8                          // Put the arrangements one below
swi  #0xC
cmp  r4,r5
bgt  -
mov  r0,#0
push {r0}
mov  r0,sp
mov  r1,r5
ldr  r2,=#0x01000008                   // (0x20 bytes of arrangements, 24th bit is 1 to fill instead of copying)
swi  #0xC
mov  r0,sp
mov  r1,r5
add  r1,#0x40
ldr  r2,=#0x01000008                   // (0x20 bytes of arrangements, 24th bit is 1 to fill instead of copying)
swi  #0xC
pop  {r0}
b    .new_clear_equip_submenu_end

//Swap arrangements' place - if we're descending
.new_clear_equip_submenu_descending:
mov  r1,r5
mov  r0,#0x38
lsl  r0,r0,#4
add  r4,r1,r0                          // Get to bottom
-
mov  r1,r5
mov  r0,#0x80
add  r0,r0,r1
mov  r2,#0x8                           // Put the arrangements one above
swi  #0xC
mov  r1,r5
add  r1,#0x40
mov  r0,#0x80
add  r0,r0,r1
mov  r2,#0x8                           // Put the arrangements one above
swi  #0xC
add  r5,#0x80
cmp  r4,r5
bgt  -
mov  r0,#0
push {r0}
mov  r0,sp
mov  r1,r5
ldr  r2,=#0x01000008                   // (0x20 bytes of arrangements, 24th bit is 1 to fill instead of copying)
swi  #0xC
mov  r0,sp
mov  r1,r5
add  r1,#0x40
ldr  r2,=#0x01000008                   // (0x20 bytes of arrangements, 24th bit is 1 to fill instead of copying)
swi  #0xC
pop  {r0}

.new_clear_equip_submenu_end:
pop  {pc}

//=============================================================================================
// Swaps the arrangements' place for the battle memories
//=============================================================================================
.new_clear_battle_memo:
push {lr}
add  r5,#0x40
bl   .get_direction
cmp  r0,#0
bne  .new_clear_battle_memo_descending
//Swap arrangements' place - if we're ascending
mov  r1,r5
mov  r0,#0x38
lsl  r0,r0,#4
add  r4,r1,r0                          // Get to bottom
-
mov  r1,r4
mov  r0,#0x80
sub  r4,r4,r0
mov  r0,r4
mov  r2,#0x20                          // Put the arrangements one below
swi  #0xC
cmp  r4,r5
bgt  -
mov  r0,#0
push {r0}
mov  r0,sp
mov  r1,r5
ldr  r2,=#0x01000020                   // (0x80 bytes of arrangements, 24th bit is 1 to fill instead of copying)
swi  #0xC
pop  {r0}
b    .new_clear_battle_memo_end

//Swap arrangements' place - if we're descending
.new_clear_battle_memo_descending:
mov  r1,r5
mov  r0,#0x80
add  r0,r0,r1
mov  r2,#0xE0                          // Put the arrangements one above
swi  #0xC
mov  r0,#0
push {r0}
mov  r0,#0x38
lsl  r1,r0,#4
mov  r0,sp
add  r1,r1,r5
ldr  r2,=#0x01000020                   // (0x80 bytes of arrangements, 24th bit is 1 to fill instead of copying)
swi  #0xC
pop  {r0}

.new_clear_battle_memo_end:
sub  r5,#0x40
pop  {pc}

//=============================================================================================
// Swaps the arrangements' place for the memoes
//=============================================================================================
.new_clear_memoes:
push {lr}
add  r5,#0xBE
bl   .get_direction
cmp  r0,#0
bne  .new_clear_memoes_descending
//Swap arrangements' place - if we're ascending
mov  r1,r5
mov  r0,#0x30
lsl  r0,r0,#4
add  r4,r1,r0                          // Get to bottom
-
mov  r1,r4
mov  r0,#0x80
sub  r4,r4,r0
mov  r0,r4
mov  r2,#0x20                          // Put the arrangements one below
swi  #0xC
cmp  r4,r5
bgt  -
mov  r0,#0
push {r0}
mov  r0,sp
mov  r1,r5
ldr  r2,=#0x01000020                   // (0x80 bytes of arrangements, 24th bit is 1 to fill instead of copying)
swi  #0xC
pop  {r0}
b    .new_clear_memoes_end

//Swap arrangements' place - if we're descending
.new_clear_memoes_descending:
mov  r1,r5
mov  r0,#0x80
add  r0,r0,r1
mov  r2,#0xC0                          // Put the arrangements one above
swi  #0xC
mov  r0,#0
push {r0}
mov  r0,#0x30
lsl  r1,r0,#4
mov  r0,sp
add  r1,r1,r5
ldr  r2,=#0x01000020                   // (0x80 bytes of arrangements, 24th bit is 1 to fill instead of copying)
swi  #0xC
pop  {r0}

.new_clear_memoes_end:
sub  r5,#0xBE
pop  {pc}

//=============================================================================================
// Swaps the arrangements' place for the shop
//=============================================================================================
.new_clear_shop:
push {lr}
add  r5,#0x2A
bl   .get_direction
cmp  r0,#0
bne  .new_clear_shop_descending
//Swap arrangements' place - if we're ascending
mov  r1,r5
mov  r0,#0x28
lsl  r0,r0,#4
add  r4,r1,r0                          // Get to bottom
-
mov  r1,r4
mov  r0,#0x80
sub  r4,r4,r0
mov  r0,r4
mov  r2,#0x20                          // Put the arrangements one below
swi  #0xC
cmp  r4,r5
bgt  -
mov  r0,#0
push {r0}
mov  r0,sp
mov  r1,r5
ldr  r2,=#0x01000020                   // (0x80 bytes of arrangements, 24th bit is 1 to fill instead of copying)
swi  #0xC
pop  {r0}
b    .new_clear_shop_end

//Swap arrangements' place - if we're descending
.new_clear_shop_descending:
mov  r1,r5
mov  r0,#0x80
add  r0,r0,r1
mov  r2,#0xC0                          // Put the arrangements one above
swi  #0xC
mov  r0,#0
push {r0}
mov  r0,#0x28
lsl  r1,r0,#4
mov  r0,sp
add  r1,r1,r5
ldr  r2,=#0x01000020                   // (0x80 bytes of arrangements, 24th bit is 1 to fill instead of copying)
swi  #0xC
pop  {r0}

.new_clear_shop_end:
sub  r5,#0x2A
pop  {pc}

//=============================================================================================
// This hack gives a default print scroller
//=============================================================================================
.new_default_scroll_print:
bx   lr

//=============================================================================================
// This hack changes what the battle memo scrolling will print, based off of 0x80476C0
//=============================================================================================
.new_battle_memo_scroll_print:
push {r4-r7,lr}
add  sp,#-4                            //base code
mov  r2,r0
ldr  r1,=#0x2016028

mov  r6,#1                             //New code
bl   .get_direction
cmp  r0,#0
bne  .new_battle_memo_scroll_print_descending
ldrh r0,[r2,#8]
b    +
.new_battle_memo_scroll_print_descending:
ldrh r0,[r2,#8]
mov  r2,#8
sub  r2,r2,r6
add  r0,r0,r2
+

.new_battle_memo_scroll_print_general:
lsl  r0,r0,#2                          //base code
mov  r2,#0xE0
lsl  r2,r2,#6
add  r1,r1,r2
add  r4,r0,r1
mov  r5,#0
cmp  r5,r6
bcs  .new_battle_memo_scroll_print_end
mov  r7,#0xF
-
ldr  r0,[r4,#0]
lsl  r0,r0,#0xA
cmp  r0,#0
bge  +
ldrb r1,[r4,#0]                        //Change a bit how this works in order to save space
mov  r0,#7
bl   $8001C5C
.new_battle_memo_scroll_print_after_function:
b    .new_battle_memo_scroll_print_single_continue
+
mov  r0,#1
bl   $80486A0
.new_battle_memo_scroll_print_single_continue:
add  r2,r5,#2

bl   .get_battle_memoes_height         //New code

lsl  r2,r2,#0x10                       //base code
lsr  r2,r2,#0x10
str  r7,[sp,#0]
mov  r1,#1
mov  r3,#1
neg  r3,r3
bl   $8047B9C
add  r0,r5,#1
lsl  r0,r0,#0x10
lsr  r5,r0,#0x10
add  r4,#4
cmp  r5,r6
bcc  -

.new_battle_memo_scroll_print_end:
add  sp,#4
pop  {r4-r7,pc}

//=============================================================================================
// This hack changes what the skill scrolling will print, based off of 0x80473EC
//=============================================================================================
.new_skills_scroll_print:
push {r4-r7,lr}
mov  r7,r9                             //base code
mov  r6,r8
push {r6,r7}
add  sp,#-8
mov  r4,r0
ldrh r0,[r4,#0xA]
bl   $8054FE0
add  r3,sp,#4
mov  r2,sp
add  r2,#6
mov  r1,#0
strh r1,[r2,#0]
ldrh r1,[r2,#0]
strh r1,[r3,#0]
ldrb r0,[r0,#0]
mov  r9,r2
cmp  r0,#3
beq  .duster_skills_scroll_print
cmp  r0,#3
bgt  +
cmp  r0,#2
beq  .psi_skills_scroll_print
b    .generic_skills_scroll_print
+
cmp  r0,#4
bne  .generic_skills_scroll_print
.psi_skills_scroll_print:
add  r1,sp,#4
mov  r0,#1
b    +
.duster_skills_scroll_print:
mov  r0,#1
mov  r1,r9
+
strh r0,[r1,#0]
.generic_skills_scroll_print:
ldr  r1,=#0x2016028
ldr  r2,=#0x427A

bl   .get_direction                    //New code!
cmp  r0,#0
bne  .new_skills_scroll_print_descending
mov  r0,#2
ldrh r2,[r4,#8]
b    +
.new_skills_scroll_print_descending:
add  r0,r1,r2
ldrh r0,[r0,#0]
ldrh r2,[r4,#8]
add  r2,#0xE
sub  r0,r0,r2
cmp  r0,#2
ble  +
mov  r0,#2
+

lsl  r0,r0,#0x10                       //base code
lsr  r3,r0,#0x10
mov  r8,r3
lsl  r2,r2,#2
mov  r3,#0xDE
lsl  r3,r3,#6
add  r1,r1,r3
add  r5,r2,r1
mov  r6,#0
lsr  r0,r0,#0x11
cmp  r6,r0
bcs  .end_double_skills_print
mov  r7,#0xF                           //Set the thing to print the bottom two skills at the right position
add  r0,sp,#4                          //But we optimize the code size
ldrh r0,[r0,#0]
cmp  r0,#0
beq  +
mov  r6,#8
mov  r4,#0xA
b    .double_skills_print
+
mov  r1,r9
ldrh r0,[r1,#0]
mov  r4,#0xB
cmp  r0,#0
beq  +
mov  r6,#2
b    .double_skills_print
+
mov  r6,#0xD

.double_skills_print:                  //Actual double skills printing
ldrb r1,[r5,#0]
mov  r0,r6
bl   $8001C5C
str  r7,[sp,#0]
mov  r1,#1
bl   .get_inventory_height
mov  r3,#0x16
bl   $8047B9C
add  r5,#4
ldrb r1,[r5,#0]
mov  r0,r6
bl   $8001C5C
str  r7,[sp,#0]
mov  r1,r4
bl   .get_inventory_height
mov  r3,#0x16
bl   $8047B9C
cmp  r6,#0x8
bne  +
mov  r0,#0
mov  r1,#0
mov  r2,#1
bl   $8047D90
+
.end_double_skills_print:
mov  r0,#1
mov  r3,r8
and  r0,r3
cmp  r0,#0
beq  .new_skills_scroll_print_end

add  r0,sp,#4                          //Set the thing to print the bottom skill at the right position
ldrh r0,[r0,#0]                        //But we optimize the code size
cmp  r0,#0
beq  +
mov  r6,#8
b    .single_skill_print
+
mov  r1,r9
ldrh r0,[r1,#0]
cmp  r0,#0
beq  +
mov  r6,#2
b    .single_skill_print
+
mov  r6,#0xD

.single_skill_print:                   //Actual single skill printing
mov  r7,#0xF
ldrb r1,[r5,#0]
mov  r0,r6
bl   $8001C5C
str  r7,[sp,#0]
mov  r1,#1
bl   .get_inventory_height
mov  r3,#0x16
bl   $8047B9C

.new_skills_scroll_print_end:
add  sp,#8
pop  {r3,r4}
mov  r8,r3
mov  r9,r4
pop  {r4-r7,pc}

//=============================================================================================
// This hack changes what the equipment submenu scrolling will print, based off of 0x8047A78
//=============================================================================================
.new_equip_submenu_scroll_print:
push {r4-r7,lr}
add  sp,#-4                            //base code
mov  r2,r0
ldr  r1,=#0x2016028


mov  r6,#1                             //New code
bl   .get_direction_submenu
cmp  r0,#0
bne  .new_equip_submenu_scroll_print_descending
ldrh r0,[r2,#8]
b    +

.new_equip_submenu_scroll_print_descending:
ldrh r0,[r2,#8]
add  r0,#7

+

lsl  r0,r0,#2                          //base code
mov  r2,#0xD3
lsl  r2,r2,#6
add  r1,r1,r2
add  r4,r0,r1
mov  r5,#0
cmp  r5,r6
bcs  .new_equip_submenu_scroll_print_end
mov  r7,#0xF
ldrb r0,[r4,#0]
cmp  r0,#0
bne  .new_equip_submenu_scroll_print_item
// This branch prints None at the bottom
mov  r0,#0x58
bl   $80486A0

bl   .get_equip_submenu_height         //New code

str  r7,[sp,#0]                        //base code
mov  r1,#0xC
mov  r3,#1
neg  r3,r3
bl   $8047B9C
b    .new_equip_submenu_scroll_print_end

.new_equip_submenu_scroll_print_item:
ldrb r1,[r4,#0]
mov  r0,#2
bl   $8001C5C
mov  r1,r0

bl   .get_equip_submenu_height         //New code

ldr  r0,[r4,#0]                        //base code
lsl  r0,r0,#9
cmp  r0,#0
bge  .new_equip_submenu_scroll_print_item_grey
str  r7,[sp,#0]
b    +
.new_equip_submenu_scroll_print_item_grey:
mov  r0,#1
str  r0,[sp,#0]
+
mov  r0,r1
mov  r1,#0xC
mov  r3,#0x16
bl   $8047B9C

.new_equip_submenu_scroll_print_end:
add  sp,#4
pop  {r4-r7,pc}

//=============================================================================================
// This hack changes what the selling menu scrolling will print, based off of 0x80477BC.
// Also covers buying thanks to .get_x_shop, which is at 0x804774C
//=============================================================================================
.new_shop_scroll_print:
push {r4-r6,lr}
add  sp,#-4
mov  r2,r0                             //base code
ldr  r1,=#0x2016028

bl   .get_direction                    //New code
cmp  r0,#0
bne  .new_shop_scroll_print_descending
ldrh r0,[r2,#8]
b    +
.new_shop_scroll_print_descending:
ldrh r0,[r2,#8]
add  r0,#5
+

bl   .get_added_value_menu_valid       //Code used in order to cover both buying and selling

lsl  r0,r0,#2                          //base code
add  r1,r1,r2
add  r4,r0,r1
ldrb r1,[r4,#0]                        //If we're scrolling, we have at least one item here
mov  r0,#2
bl   $8001C5C
mov  r1,r0

bl   .get_shop_height                  //New code

ldr  r0,[r4,#0]                        //base code
lsl  r0,r0,#0xA
cmp  r0,#0
bge  +
mov  r0,#0xF
b    .new_shop_scroll_print_continue
+
mov  r0,#1
.new_shop_scroll_print_continue:
str  r0,[sp,#0]
mov  r0,r1

bl   .get_x_shop                       //Covers both buying and selling

mov  r3,#0x16
bl   $8047B9C

add  sp,#4
pop  {r4-r6,pc}

//=============================================================================================
// Returns as the X the menu identifier -1. This is an optimization due to where stuff is normally printed.
// The two values are not actually related. They're 0xA for selling and 0x9 for buying
//=============================================================================================
.get_x_shop:
ldr  r1,=#0x201A288
ldrb r1,[r1,#0]
sub  r1,#1
bx   lr

//=============================================================================================
// Returns the value that has to be added in order to go to the proper menu's inventory.
// If it's for the PSI menu, it has the inventory's number in r0
//=============================================================================================
.get_added_value_menu_valid:
push {r1}
ldr  r2,=#0x201A288
ldrb r2,[r2,#0]
cmp  r2,#0xB
beq  .get_added_value_sell_valid
cmp  r2,#0xA
beq  .get_added_value_buy_valid
cmp  r2,#0x2
beq  .get_added_value_psi_valid
b    +

.get_added_value_psi_valid:
mov  r2,#0x35
lsl  r2,r2,#8
lsl  r1,r0,#7
add  r2,r2,r1
b    +
.get_added_value_buy_valid:
ldr  r2,=#0x3D44
b    +
.get_added_value_sell_valid:
mov  r2,#0xD2
lsl  r2,r2,#6
+
pop  {r1}
bx   lr

//=============================================================================================
// This hack changes what the psi scrolling will print, based off of 0x80471B4
// Base game bug: when you use a party wide PSI in this menu and end up with fewer PPs than
// the PPs required to use a PSI, this isn't reflected in the PSI's colour.
// Putting this here in order to fix it at a later date.
//=============================================================================================
.new_psi_scroll_print:
push {r4-r7,lr}
add  sp,#-4
mov  r2,r0                             //base code
ldr  r4,=#0x2016028
ldrh r3,[r2,#0xA]
lsl  r0,r3,#1
ldr  r5,=#0x4270
add  r1,r4,r5
add  r1,r0,r1                          //If we're scrolling, the character has for sure > 0 PSI

bl   .get_direction                    //New code!
cmp  r0,#0
bne  .new_psi_scroll_print_descending
mov  r0,#2
ldrh r1,[r2,#8]
b    +
.new_psi_scroll_print_descending:
ldrh r0,[r1,#0]
ldrh r1,[r2,#8]
add  r1,#0xE
sub  r0,r0,r1
cmp  r0,#2
ble  +
mov  r0,#2
+

lsl  r2,r0,#0x10                       //base code
lsr  r7,r2,#0x10
lsl  r3,r3,#7
lsl  r0,r1,#2
mov  r5,#0xD4
lsl  r5,r5,#6
add  r1,r4,r5
add  r0,r0,r1
add  r4,r3,r0
mov  r6,#0
lsr  r2,r2,#0x11
cmp  r6,r2
bcs  +
ldrb r1,[r4,#0]                        //Set the thing to print the bottom two psi at the right position
mov  r0,#8
bl   $8001C5C
mov  r3,r0
bl   .get_inventory_height
mov  r5,r2
ldr  r0,[r4,#0]
bl   .get_psi_usable
str  r0,[sp,#0]
mov  r0,r3
mov  r1,#1
mov  r3,#0x16
bl   $8047B9C
add  r4,#4
ldrb r1,[r4,#0]
mov  r0,#8
bl   $8001C5C
mov  r3,r0
mov  r2,r5
ldr  r0,[r4,#0]
bl   .get_psi_usable
str  r0,[sp,#0]
mov  r0,r3
mov  r1,#0xA
mov  r3,#0x16
bl   $8047B9C
mov  r0,#0
mov  r1,#0
mov  r2,#1
bl   $8047D90
+
mov  r5,#1
mov  r0,r7
and  r0,r5
cmp  r0,#0
beq  +
ldrb r1,[r4,#0]                        //Set the thing to print the bottom psi at the right position
mov  r0,#8
bl   $8001C5C
mov  r3,r0
bl   .get_inventory_height
ldr  r0,[r4,#0]
bl   .get_psi_usable
str  r0,[sp,#0]
mov  r0,r3
mov  r1,#1
mov  r3,#0x16
bl   $8047B9C
+
add  sp,#4
pop  {r4-r7,pc}

//=============================================================================================
// This hack changes what the memoes scrolling will print, based off of 0x80475A4
//=============================================================================================
.new_memoes_scroll_print:
push {r4-r7,lr}
mov  r7,r8                             //base code
push {r7}
add  sp,#-4
ldr  r3,=#0x2016028
ldr  r2,=#0x427E
add  r1,r3,r2
mov  r2,r0

bl   .get_direction                    //New code!
cmp  r0,#0
bne  .new_memoes_scroll_print_descending
mov  r0,#2
ldrh r1,[r2,#8]
b    +
.new_memoes_scroll_print_descending:
ldrh r0,[r1,#0]
ldrh r1,[r2,#8]
add  r1,#0xC
sub  r0,r0,r1
cmp  r0,#2
ble  +
mov  r0,#2
+

lsl  r0,r0,#0x10                       //base code
lsr  r4,r0,#0x10
mov  r8,r4
lsl  r2,r1,#2
ldr  r4,=#0x3BFC
add  r1,r3,r4
add  r4,r2,r1
mov  r7,#0
lsr  r0,r0,#0x11
cmp  r7,r0
bcs  .new_memoes_scroll_print_end_of_double
ldr  r0,[r4,#0]
lsl  r0,r0,#0xA
cmp  r0,#0
bge  .new_memoes_scroll_print_end_of_double
ldrb r0,[r4,#0]
bl   $80486D8
mov  r3,r0

bl   .get_memoes_height                //New code
mov  r6,#1
neg  r6,r6
ldr  r0,[r4,#0]
lsl  r0,r0,#9
bl   .new_memoes_scroll_print_get_colour
str  r0,[sp,#0]                        //Optimize code size

mov  r0,r3                             //base code
mov  r1,#1
mov  r3,r6
bl   $8047B9C
add  r4,#4
ldr  r0,[r4,#0]
lsl  r0,r0,#0xA
cmp  r0,#0
bge  .new_memoes_scroll_print_end_of_double
ldrb r0,[r4,#0]
bl   $80486D8
mov  r1,r0

bl   .get_memoes_height                //New code
mov  r3,#1
neg  r3,r3
ldr  r0,[r4,#0]
lsl  r0,r0,#9
bl   .new_memoes_scroll_print_get_colour
str  r0,[sp,#0]                        //Optimize code size

mov  r0,r1                             //base code
mov  r1,#0xB
bl   $8047B9C
add  r4,#4
.new_memoes_scroll_print_end_of_double:
ldr  r0,[r4,#0]
lsl  r0,r0,#0xA
cmp  r0,#0
bge  .new_memoes_scroll_print_end
mov  r5,#1
mov  r0,r8
and  r0,r5
cmp  r0,#0
beq  .new_memoes_scroll_print_end
ldrb r0,[r4,#0]
bl   $80486D8
mov  r1,r0

bl   .get_memoes_height                //New Code
ldr  r0,[r4,#0]
lsl  r0,r0,#9
bl   .new_memoes_scroll_print_get_colour
str  r0,[sp,#0]                        //Optimize code size

mov  r0,r1                             //base code
mov  r1,#0x1
neg  r3,r1
bl   $8047B9C

.new_memoes_scroll_print_end:
add  sp,#4
pop  {r3}
mov  r8,r3
pop  {r4-r7,pc}

//=============================================================================================
// This hack gets the colour that should be printed for the memo item
//=============================================================================================
.new_memoes_scroll_print_get_colour:
cmp  r0,#0
bge  +
mov  r0,#0xF
b    .new_memoes_scroll_print_get_colour_end
+
mov  r0,#1
.new_memoes_scroll_print_get_colour_end:
bx   lr

//=============================================================================================
// This hack changes what the withdrawing scrolling will print, based off of 0x8047900
//=============================================================================================
.new_withdrawing_scroll_print:
push {r4-r7,lr}
mov  r7,r9
mov  r6,r8
push {r6,r7}
add  sp,#-4                            //base code
mov  r1,r0
ldr  r3,=#0x2016028
ldr  r0,=#0x4282
add  r2,r3,r0

bl   .get_direction                    //New code!
cmp  r0,#0
bne  .new_withdrawing_scroll_print_descending
mov  r0,#2
ldrh r1,[r1,#8]
b    +
.new_withdrawing_scroll_print_descending:
ldrh r0,[r2,#0]
ldrh r1,[r1,#8]
add  r1,#0xE
sub  r0,r0,r1
cmp  r0,#2
ble  +
mov  r0,#2
+

lsl  r2,r0,#0x10                       //base code
lsr  r4,r2,#0x10
mov  r9,r4
lsl  r1,r1,#2
ldr  r4,=#0x3DBC
add  r0,r3,r4
add  r5,r1,r0
mov  r7,#0xF
mov  r6,#0
lsr  r0,r2,#0x11
cmp  r6,r0
bcs  +
mov  r8,r0                             //Set the thing to print the bottom two items at the right position
ldrb r1,[r5,#0]
mov  r0,#2
bl   $8001C5C
str  r7,[sp,#0]
mov  r1,#1
bl   .get_inventory_height
mov  r3,#0x16
bl   $8047B9C
add  r5,#4
ldrb r1,[r5,#0]
mov  r0,#2
bl   $8001C5C
str  r7,[sp,#0]
mov  r1,#0xA
bl   .get_inventory_height
mov  r3,#0x16
bl   $8047B9C
mov  r0,#0
mov  r1,#0
mov  r2,#1
bl   $8047D90
+
mov  r0,#1
mov  r1,r9
and  r0,r1
cmp  r0,#0
beq  +
ldrb r1,[r5,#0]                        //Set the thing to print the bottom item at the right position
mov  r0,#2
bl   $8001C5C
str  r7,[sp,#0]
mov  r1,#0x1
bl   .get_inventory_height
mov  r3,#0x16
bl   $8047B9C
+
add  sp,#4
pop  {r3,r4}
mov  r8,r3
mov  r9,r4
pop  {r4-r7,pc}

//=============================================================================================
// This hack changes what the withdrawing will print, based off of 0x8047900
//=============================================================================================
.new_withdrawing_a_print:
push {r4-r7,lr}
mov  r7,r9
mov  r6,r8
push {r6,r7}
add  sp,#-4                            //base code
mov  r1,r0
ldr  r3,=#0x2016028
ldr  r0,=#0x4282
add  r2,r3,r0
ldrh r0,[r2,#0]
ldrh r1,[r1,#8]
add  r1,#0xF
sub  r0,r0,r1
cmp  r0,#1
ble  +
mov  r0,#1
+

lsl  r2,r0,#0x10                       //base code
lsr  r4,r2,#0x10
mov  r9,r4
lsl  r1,r1,#2
ldr  r4,=#0x3DBC
add  r0,r3,r4
add  r5,r1,r0
mov  r7,#0xF
mov  r0,#1
mov  r1,r9
and  r0,r1
cmp  r0,#0
beq  +
ldrb r1,[r5,#0]                        //Set the thing to print the bottom item at the right position
mov  r0,#2
bl   $8001C5C
str  r7,[sp,#0]
mov  r1,#0xA
mov  r2,#0x9
mov  r3,#0x16
bl   $8047B9C
mov  r0,#0
mov  r1,#0
mov  r2,#1
bl   $8047D90
+
add  sp,#4
pop  {r3,r4}
mov  r8,r3
mov  r9,r4
pop  {r4-r7,pc}

//=============================================================================================
// This hack changes what the status menu will print, based off of 0x80472BC
//=============================================================================================
.new_status_print:
push {r4-r7,lr}
add  sp,#-4                            //base code
ldrh r0,[r0,#0xA]
bl   $8054FE0                          //Get character's address
mov  r5,r0
bl   .delete_vram_status
cmp  r0,#0                             //Can this character's data be shown?
beq  +
b    .new_status_print_end
+

mov  r4,#0
mov  r7,r5
add  r7,#0x34                          //Go pick up the character's equipment
mov  r6,#0xF
-
add  r1,r7,r4                          //Get Xth item
ldrb r0,[r1,#0]
cmp  r0,#0
bne  .new_status_print_item            //Is an item equipped?

mov  r0,#2
bl   $80486A0                          //If not, order printing "-----"
add  r2,r4,#5
str  r6,[sp,#0]
mov  r1,#0xC
mov  r3,#1
neg  r3,r3
bl   $8047B9C                          //Order its printing
b    +

.new_status_print_item:
ldrb r1,[r1,#0]                        //Load the item that has to be printed
mov  r0,#2
bl   $8001C5C                          //Load its address
add  r2,r4,#5
str  r6,[sp,#0]
mov  r1,#0xC
mov  r3,#0x16
bl   $8047B9C                          //Order its printing

+
add  r4,#1
cmp  r4,#3                             //Cycle the equipment in its entirety
bls  -

mov  r0,r5
bl   $8047B0C                          //Print Skill

ldr  r0,=#0x20169FA                    //Has the gray text been printed?
ldrh r0,[r0,#0]
cmp  r0,#0
beq  +
b    .new_status_print_end
+

mov  r0,#0x47                          //If it hasn't, reprint it
bl   $80486A0                          //Level text, get the pointer to it
mov  r5,#1
neg  r5,r5
mov  r4,#1
str  r4,[sp,#0]                        //Gray text
mov  r1,#1
mov  r2,#3
mov  r3,r5
bl   $8047B9C                          //Order its printing

mov  r0,#0x48                          //Offense text
bl   $80486A0                          //Get the pointer to it
str  r4,[sp,#0]                        //Gray text
mov  r1,#1
mov  r2,#4
mov  r3,r5
bl   $8047B9C                          //Order its printing

mov  r0,#0x49                          //Defense text
bl   $80486A0                          //Get the pointer to it
str  r4,[sp,#0]                        //Gray text
mov  r1,#1
mov  r2,#5
mov  r3,r5
bl   $8047B9C                          //Order its printing

mov  r0,#0x4A                          //IQ text
bl   $80486A0                          //Get the pointer to it
str  r4,[sp,#0]                        //Gray text
mov  r1,#1
mov  r2,#6
mov  r3,r5
bl   $8047B9C                          //Order its printing

mov  r0,#0x4B                          //Speed text
bl   $80486A0                          //Get the pointer to it
str  r4,[sp,#0]                        //Gray text
mov  r1,#1
mov  r2,#7
mov  r3,r5
bl   $8047B9C                          //Order its printing

mov  r0,#0x4C                          //EXP text
bl   $80486A0                          //Get the pointer to it
str  r4,[sp,#0]                        //Gray text
mov  r1,#1
mov  r2,#8
mov  r3,r5
bl   $8047B9C                          //Order its printing

mov  r0,#0x4D                          //Next Level text
bl   $80486A0                          //Get the pointer to it
str  r4,[sp,#0]                        //Gray text
mov  r1,#1
mov  r2,#9
mov  r3,r5
bl   $8047B9C                          //Order its printing

mov  r0,#0x4E                          //HP text
bl   $80486A0                          //Get the pointer to it
str  r4,[sp,#0]                        //Gray text
mov  r1,#9
mov  r2,#3
mov  r3,r5
bl   $8047B9C                          //Order its printing

mov  r0,#0x50                          //PP text
bl   $80486A0                          //Get the pointer to it
str  r4,[sp,#0]                        //Gray text
mov  r1,#9
mov  r2,#4
mov  r3,r5

bl improve_performances_menus.status_vram_equip_descriptors //Load OAM entries in VRAM

.new_status_print_end:
add  sp,#4
pop  {r4-r7,pc}

//=============================================================================================
// This hack changes what the equipment menu will print, based off of 0x80470A8
//=============================================================================================
.new_equip_print:
push {r4-r6,lr}
add  sp,#-4                            //base code
ldrh r0,[r0,#0xA]
bl   $8054FE0                          //Get character's address
mov  r5,r0
bl   .delete_vram_equip
cmp  r0,#0                             //Can this character's data be shown?
beq  +
b    .new_equip_print_end
+

mov  r4,#0
mov  r6,r5
add  r6,#0x34                          //Go pick up the character's equipment
mov  r5,#0xF
-
add  r1,r6,r4                          //Get Xth item
ldrb r0,[r1,#0]
cmp  r0,#0
bne  .new_equip_print_item            //Is an item equipped?

mov  r0,#2
bl   $80486A0                          //If not, order printing "-----"
lsl  r2,r4,#0x11
mov  r1,#0xC0
lsl  r1,r1,#0xA
add  r2,r2,r1
lsr  r2,r2,#0x10
str  r5,[sp,#0]
mov  r1,#0xC
mov  r3,#1
neg  r3,r3
bl   $8047B9C                          //Order its printing
b    +

.new_equip_print_item:
ldrb r1,[r1,#0]                        //Load the item that has to be printed
mov  r0,#2
bl   $8001C5C                          //Load its address
lsl  r2,r4,#0x11
mov  r1,#0xC0
lsl  r1,r1,#0xA
add  r2,r2,r1
lsr  r2,r2,#0x10
str  r5,[sp,#0]
mov  r1,#0xC
mov  r3,#0x16
bl   $8047B9C                          //Order its printing

+
add  r4,#1
cmp  r4,#3                             //Cycle the equipment in its entirety
bls  -

ldr  r0,=#0x20169FA                    //Has the gray text been printed?
ldrh r0,[r0,#0]
cmp  r0,#0
beq  +
b    .new_equip_print_end
+

//If it hasn't, reprint it
bl improve_performances_menus.equipment_vram_equip_descriptors //Load OAM entries in VRAM

mov  r0,#0x47                          //Level text
bl   $80486A0                          //Get the pointer to it
mov  r5,#1
neg  r5,r5
mov  r4,#1
str  r4,[sp,#0]                        //Gray text
mov  r1,#1
mov  r2,#3
mov  r3,r5
bl   $8047B9C                          //Order its printing

mov  r0,#0x4F                          //Max HP text
bl   $80486A0                          //Get the pointer to it
str  r4,[sp,#0]                        //Gray text
mov  r1,#1
mov  r2,#4
mov  r3,r5
bl   $8047B9C                          //Order its printing

mov  r0,#0x51                          //Max PP text
bl   $80486A0                          //Get the pointer to it
str  r4,[sp,#0]                        //Gray text
mov  r1,#1
mov  r2,#5
mov  r3,r5
bl   $8047B9C                          //Order its printing

mov  r0,#0x48                          //Offense text
bl   $80486A0                          //Get the pointer to it
str  r4,[sp,#0]                        //Gray text
mov  r1,#1
mov  r2,#6
mov  r3,r5
bl   $8047B9C                          //Order its printing

mov  r0,#0x49                          //Defense text
bl   $80486A0                          //Get the pointer to it
str  r4,[sp,#0]                        //Gray text
mov  r1,#1
mov  r2,#7
mov  r3,r5
bl   $8047B9C                          //Order its printing

mov  r0,#0x4A                          //IQ text
bl   $80486A0                          //Get the pointer to it
str  r4,[sp,#0]                        //Gray text
mov  r1,#1
mov  r2,#8
mov  r3,r5
bl   $8047B9C                          //Order its printing

mov  r0,#0x4B                          //Speed text
bl   $80486A0                          //Get the pointer to it
str  r4,[sp,#0]                        //Gray text
mov  r1,#1
mov  r2,#9
mov  r3,r5
bl   $8047B9C                          //Order its printing

.new_equip_print_end:
add  sp,#4
pop  {r4-r6,pc}

//=============================================================================================
// This hack changes what the main inventory scrolling will print, based off of 0x8046EF0
//=============================================================================================
.new_main_inventory_scroll_print:
push {r4-r7,lr}
mov  r7,r9
mov  r6,r8
push {r6,r7}
add  sp,#-4                            //base code
mov  r3,r0
ldr  r2,=#0x2016028
ldr  r0,=#0x2DFA
add  r1,r2,r0
ldrh r0,[r3,#0xA]
ldrh r1,[r1,#0]                        //is this the key items inventory?
cmp  r0,r1
bcc  .new_main_inventory_scroll_print_end
mov  r0,r3
bl   .new_key_inventory_scroll_print

.new_main_inventory_scroll_print_end:
add  sp,#4
pop  {r3,r4}
mov  r8,r3
mov  r9,r4
pop  {r4-r7,pc}

//=============================================================================================
// This hack changes what scrolling in the key items inventory will print, based off of 0x8046FD8
//=============================================================================================
.new_key_inventory_scroll_print:
push {r4-r7,lr}
mov  r7,r9
mov  r6,r8
push {r6,r7}
add  sp,#-4                            //base code
mov  r1,r0
ldr  r3,=#0x2016028
bl   .get_direction
cmp  r0,#0
bne  .new_key_inventory_scroll_print_descending_items
mov  r0,#2                             //If we're scrolling up, there will be two items for sure. No need to edit r1 either.
ldrh r1,[r1,#8]
b    +
.new_key_inventory_scroll_print_descending_items:
ldr  r0,=#0x426A
add  r2,r3,r0
ldrh r0,[r2,#0]
ldrh r1,[r1,#8]
add  r1,#0xE                           //Only if we're descending!
sub  r0,r0,r1
cmp  r0,#2
ble  +
mov  r0,#2
+
lsl  r2,r0,#0x10
lsr  r4,r2,#0x10
mov  r9,r4
lsl  r1,r1,#2
mov  r4,#0xC2
lsl  r4,r4,#6
add  r0,r3,r4
add  r5,r1,r0
mov  r6,#0
lsr  r0,r2,#0x11
cmp  r6,r0
bcs  +
mov  r7,#0xF                           //Set the thing to print the bottom two items at the right position
ldrb r1,[r5,#0]
mov  r0,#2
bl   $8001C5C
str  r7,[sp,#0]
mov  r1,#1
bl   .get_inventory_height
mov  r3,#0x16
bl   $8047B9C
add  r5,#0x4
ldrb r1,[r5,#0]
mov  r0,#2
bl   $8001C5C
str  r7,[sp,#0]
mov  r1,#0xB
bl   .get_inventory_height
mov  r3,#0x16
bl   $8047B9C
+
mov  r0,#1
mov  r1,r9
and  r0,r1
cmp  r0,#0
beq  .new_key_inventory_scroll_print_end

mov  r7,#0xF                           //Set the thing to print the bottom item at the right position
ldrb r1,[r5,#0]
mov  r0,#2
bl   $8001C5C
str  r7,[sp,#0]
mov  r1,#1
bl   .get_inventory_height
mov  r3,#0x16
bl   $8047B9C

.new_key_inventory_scroll_print_end:
add  sp,#4
pop  {r3,r4}
mov  r8,r3
mov  r9,r4
pop  {r4-r7,pc}

//=============================================================================================
// This hack gets the scrolling direction for any given menu
//=============================================================================================
.get_direction:
push {r1-r2,lr}
ldr  r1,=#0x201A288
ldrb r1,[r1,#0]                        //Get menu type
lsl  r1,r1,#5
ldr  r2,=#0x2016028
ldr  r0,=#0x2DFA
add  r0,r2,r0                          //Get menu info array in RAM
add  r1,r0,r1
mov  r2,#1
ldrh r0,[r1,#0xA]
ldrh r1,[r1,#0xE]
lsr  r0,r0,#1
lsr  r1,r1,#1
cmp  r0,r1
bne +
mov  r2,#0                             //Going up if they're the same! Otherwise, going down!
+
mov  r0,r2
pop  {r1-r2,pc}

//=============================================================================================
// This hack gets the scrolling direction for any given submenu
//=============================================================================================
.get_direction_submenu:
push {r1-r2,lr}
ldr  r1,=#0x2016028
ldr  r2,=#0x3060
add  r1,r1,r2                          //Get submenu info array in RAM
ldrh r0,[r1,#0x4]
ldrh r1,[r1,#0x8]
lsr  r0,r0,#1
lsr  r1,r1,#1
mov  r2,#1
cmp  r0,r1
bne +
mov  r2,#0                             //Going up if they're the same! Otherwise, going down!
+
mov  r0,r2
pop  {r1-r2,pc}

//=============================================================================================
// This hack gets the index of the top item for any given menu
//=============================================================================================
.get_top_index:
push {r1-r2,lr}
ldr  r1,=#0x201A288
ldrb r1,[r1,#0]                        //Get menu type
lsl  r1,r1,#5
ldr  r2,=#0x2016028
ldr  r0,=#0x2DFA
add  r0,r2,r0                          //Get menu info array in RAM
add  r1,r0,r1
ldrh r0,[r1,#0xE]
pop  {r1-r2,pc}

//=============================================================================================
// This hack gets the number of items in any given menu
//=============================================================================================
.get_total_indexes:
push {r1-r2,lr}
ldr  r1,=#0x201A288
ldrb r1,[r1,#0]                        //Get menu type
lsl  r1,r1,#5
ldr  r2,=#0x2016028
ldr  r0,=#0x2DFA
add  r0,r2,r0                          //Get menu info array in RAM
add  r1,r0,r1
ldrh r0,[r1,#0x8]
pop  {r1-r2,pc}

//=============================================================================================
// This hack gets the number of items in a character's inventory
//=============================================================================================
.get_character_inventory_total_indexes:
push {r1,lr}
ldr  r0,=#0x2016028
ldr  r1,=#0x426C
add  r0,r0,r1
ldrh r0,[r0,#0]
pop  {r1,pc}

//=============================================================================================
// This hack gets the number of show-able items in any given menu
//=============================================================================================
.get_possible_indexes:
push {r1-r2,lr}
ldr  r1,=#0x201A288
ldrb r1,[r1,#0]                        //Get menu type
lsl  r1,r1,#5
ldr  r2,=#0x2016028
ldr  r0,=#0x2DFA
add  r0,r2,r0                          //Get menu info array in RAM
add  r1,r0,r1
ldrh r0,[r1,#0xC]
pop  {r1-r2,pc}

//=============================================================================================
// This hack gets the index of the currently selected item for any given menu
//=============================================================================================
.get_selected_index:
push {r1-r2,lr}
ldr  r1,=#0x201A288
ldrb r1,[r1,#0]                        //Get menu type
lsl  r1,r1,#5
ldr  r2,=#0x2016028
ldr  r0,=#0x2DFA
add  r0,r2,r0                          //Get menu info array in RAM
add  r1,r0,r1
ldrh r0,[r1,#0xA]
pop  {r1-r2,pc}

//=============================================================================================
// This hack sets the index of the currently selected item to a specific value.
// It returns in r0 the previous selected item value
//=============================================================================================
.set_selected_index:
push {r1-r3,lr}
mov  r3,r0
ldr  r1,=#0x201A288
ldrb r1,[r1,#0]                        //Get menu type
lsl  r1,r1,#5
ldr  r2,=#0x2016028
ldr  r0,=#0x2DFA
add  r0,r2,r0                          //Get menu info array in RAM
add  r1,r0,r1
ldrh r0,[r1,#0xA]
strh r3,[r1,#0xA]
pop  {r1-r3,pc}

//=============================================================================================
// This hack gets the difference between the top index and the total amount of items
//=============================================================================================
.get_difference_top_total:
push {r1-r2,lr}
ldr  r1,=#0x201A288
ldrb r1,[r1,#0]                        //Get menu type
lsl  r1,r1,#5
ldr  r2,=#0x2016028
ldr  r0,=#0x2DFA
add  r0,r2,r0                          //Get menu info array in RAM
add  r1,r0,r1
ldrh r0,[r1,#0xE]                      //Top index
ldrh r1,[r1,#0x8]                      //Total items
sub  r0,r1,r0                          //Total items - Top index
pop  {r1-r2,pc}

//=============================================================================================
// This hack gets the height for printing in the inventory/withdrawing menu
//=============================================================================================
.get_inventory_height:
push {r0,lr}
bl   .get_direction
cmp  r0,#0
bne  .get_inventory_height_descending
mov  r2,#0x2
b    .get_inventory_height_end
.get_inventory_height_descending:
mov  r2,#0x9
.get_inventory_height_end:
pop  {r0,pc}

//=============================================================================================
// This hack gets the height for printing in the equip submenu
//=============================================================================================
.get_equip_submenu_height:
push {r0,lr}
bl   .get_direction_submenu
cmp  r0,#0
bne  .get_equip_submenu_height_descending
mov  r2,#0x2
b    .get_equip_submenu_height_end
.get_equip_submenu_height_descending:
mov  r2,#0x9
.get_equip_submenu_height_end:
pop  {r0,pc}

//=============================================================================================
// This hack gets the height for printing in the battle memoes menu
//=============================================================================================
.get_battle_memoes_height:
push {r0,lr}
bl   .get_direction
cmp  r0,#0
beq  +
mov  r0,#8
sub  r0,r0,r6
add  r2,r2,r0
+
pop  {r0,pc}

//=============================================================================================
// This hack gets the height for printing in the memoes menu
//=============================================================================================
.get_memoes_height:
push {r0,lr}
bl   .get_direction
cmp  r0,#0
bne  .get_memoes_height_descending
mov  r2,#0x3
b    .get_memoes_height_end
.get_memoes_height_descending:
mov  r2,#0x9
.get_memoes_height_end:
pop  {r0,pc}

//=============================================================================================
// This hack gets the height for printing in the shop menu
//=============================================================================================
.get_shop_height:
push {r0,lr}
bl   .get_direction
cmp  r0,#0
bne  .get_shop_height_descending
mov  r2,#0x2
b    .get_shop_height_end
.get_shop_height_descending:
mov  r2,#0x7
.get_shop_height_end:
pop  {r0,pc}

//=============================================================================================
// This hack gets the color for the psi when printing in the psi menu. r0 is the input value
//=============================================================================================
.get_psi_usable:
lsl  r0,r0,#0xA
cmp  r0,#0
bge  .psi_not_usable
mov  r0,#0xF
b    +
.psi_not_usable:
mov  r0,#1
+
bx   lr

//=============================================================================================
// This hack is called in order to change where everything is printed in VRAM. Based on 0x80487D4
//=============================================================================================
.new_print_vram_container:
push {r4,r5,lr}
add  sp,#-4
str  r0,[sp,#0]
ldr  r4,=#0x201AEF8                    //We avoid printing OAM entries...
ldr  r0,=#0x76DC                       //Base code
add  r5,r4,r0
ldrb r1,[r5,#0]
mov  r0,#8
and  r0,r1
cmp  r0,#0
beq  +
mov  r0,r4
bl   $8048878
mov  r0,r4
bl   $80489F8
mov  r0,r4
bl   $8048C5C
+
bl   .load_remaining_strings_external
ldr  r3,=#0x76D6
add  r0,r4,r3
mov  r2,#0
strb r1,[r0,#0]
add  r3,#1
add  r0,r4,r3
strb r2,[r0,#0]
lsl  r1,r1,#0x18
cmp  r1,#0
beq  +

mov  r0,r4
ldr  r1,[sp,#0]
bl   .print_vram                   //New code!

+
ldr  r1,=#0x6C28
add  r0,r4,r1
ldr  r0,[r0,#0]
ldrb r1,[r0,#0x11]
cmp  r1,#0
bne  +
ldr  r2,=#0x3004B00
ldrh r0,[r2,#0]
cmp  r0,#0
beq  +
ldr  r3,=#0xFFFFF390
add  r0,r4,r3
ldrb r0,[r0,#0]
cmp  r0,#0
blt  +
cmp  r0,#2
ble  .new_print_vram_container_inner
cmp  r0,#4
bne  +
.new_print_vram_container_inner:
strh r1,[r2,#0]
+
add  sp,#4
pop  {r4,r5,pc}

//=============================================================================================
// This hack moves the graphics for the Equip menu and the Status menu.
// It also makes the arrangements point to them
//=============================================================================================
.new_graphics_arrangements_movement_table:
dd $01A40204; dd $02A40105

.new_move_graphics_arrangements:
push {r4-r7,lr}
ldr  r0,=#0x201A288
ldrb r0,[r0,#0]
lsr  r0,r0,#1
lsl  r0,r0,#2
ldr  r1,=#.new_graphics_arrangements_movement_table
add  r6,r1,r0                          //Load how to move stuff, based upon the menu
ldr  r7,=#0x600E800
ldrh r1,[r6,#2]
add  r7,r7,r1                          //Where to start
mov  r5,#0                             //Current entry

.new_move_graphics_arrangements_loop:
mov  r4,#0                             //Number of tiles to move
mov  r1,r7
ldrh r3,[r1,#0]                        //Save starting tile
-
ldrh r0,[r1,#0]                        //Get how many tiles need to be moved
cmp  r0,#0
beq  +
add  r4,#1
add  r1,#2
b    -

+
cmp  r4,#0                             //If nothing to copy, skip!
beq  +

lsr  r2,r5,#1                          //Get where to put the graphics
lsl  r2,r2,#11
mov  r1,#1
and  r1,r5
lsl  r1,r1,#9
add  r2,r2,r1
add  r2,#0x20
push {r5-r7}
lsr  r7,r2,#5                          //Save starting tile number
lsl  r0,r3,#5                          //Get actual address
ldr  r1,=#0x6008000                    //Graphics start
add  r0,r1,r0                          //Source
add  r1,r1,r2                          //Target
mov  r5,r0
mov  r6,r1
lsl  r2,r4,#3                          //Number of words to copy
swi  #0xC
mov  r0,r5
mov  r1,r6
mov  r2,#4
lsl  r2,r2,#8
add  r0,r0,r2                          //Copy the bottom as well
add  r1,r1,r2
lsl  r2,r4,#3                          //Number of words to copy
swi  #0xC

mov  r0,r7                             //New starting tile number
mov  r1,r7
add  r1,#0x20                          //New bottom starting tile number
pop  {r5-r7}
mov  r2,r7                             //Replace arrangements
mov  r3,r7
add  r3,#0x40

-
strh r0,[r2,#0]
strh r1,[r3,#0]
add  r0,#1
add  r1,#1
add  r2,#2
add  r3,#2

sub  r4,#1
cmp  r4,#0
bne  -
+

ldrb r1,[r6,#0]                        //Number of entries
ldrb r2,[r6,#1]
lsl  r2,r2,#7
add  r7,r7,r2                          //How much to add to the base arrangements
add  r5,#1
cmp  r5,r1
bne  .new_move_graphics_arrangements_loop

pop  {r4-r7,pc}

//=============================================================================================
// This hack gets the selected character's number.
//=============================================================================================
.new_get_menu_character_number:
push {r1-r3,lr}
mov  r2,r0
ldr  r1,=#0x2016028
mov  r0,#0xB8
lsl  r0,r0,#6
add  r0,r0,r1
lsl  r1,r2,#5
add  r0,r0,r1
ldrh r0,[r0,#0xA]
bl   $8054FE0
ldrb r0,[r0,#0]
pop  {r1-r3,pc}

//=============================================================================================
// This hack changes the target vram address to whatever we want it to be.
// It uses the values found by new_get_empty_tiles
//=============================================================================================
.new_get_address:
ldr  r1,[sp,#0x20+0x24]
cmp  r0,r1                             //If we're after a certain threshold (which depends on the menu), use the second address
blt  +
ldr  r1,[sp,#0x20+0x1C]
b    .new_get_address_keep_going
+
ldr  r1,[sp,#0x20+0x20]
.new_get_address_keep_going:
lsl  r0,r0,#0x10
lsr  r0,r0,#0xB
add  r0,r0,r1
bx   lr

//=============================================================================================
// This hack gets the tiles which will be empty
//=============================================================================================

//Table that dictates which menus are valid to read the empty buffer tiles of
.new_get_empty_tiles_valid:
  dw $8CB7; dw $0000

//Table which dictates the limit value of a menu used to change the valid buffer tiles to the second ones
.new_get_empty_tiles_limit_values:
  db $10; db $12; db $0F; db $FF; db $0F; db $10; db $FF; db $10
  db $FF; db $FF; db $0D; db $0F; db $FF; db $FF; db $FF; db $0F
  db $FF; db $FF; db $FF; db $FF; db $FF; db $FF; db $FF; db $FF
  db $FF; db $FF; db $FF; db $FF; db $FF; db $FF; db $FF; db $FF
  
//Table that indicates which menus only use one line to the right instead of one to the left (safe) or two
.new_get_empty_tiles_types:
  dw $80B7; dw $0000

.new_get_empty_tiles:
push {r4-r6,lr}
add  sp,#-4
ldr  r0,=#0x2016078
mov  r1,#1
mov  r2,#0
mov  r3,#0
bl   $8001378
ldr  r1,=#0x201A288
ldr  r3,=#.new_get_empty_tiles_valid
ldrh r2,[r3,#2]
ldrh r3,[r3,#0]
lsl  r2,r2,#0x10
orr  r3,r2
ldrb r2,[r1,#0]
mov  r1,#1
lsl  r1,r2
and  r1,r3
cmp  r1,#0
bne  +
ldr  r6,=#0x6008000
mov  r0,r6
mov  r1,r6
b    .end_new_get_empty_tiles
+
mov  r3,r0
add  r3,#0x82
ldr  r4,=#.new_get_empty_tiles_types   //Determine if this is a right single column menu or not
ldrh r0,[r4,#2]
ldrh r4,[r4,#0]
lsl  r0,r0,#0x10
orr  r4,r0
mov  r0,#1
lsl  r0,r2
and  r0,r4
cmp  r0,#0
beq  +
ldr  r4,=#0xFFF00003                   //Bitmap for occupied/not occupied zone when double columned
b    .new_get_empty_tiles_gotten_type
+
ldr  r4,=#0xFFF55557                   //Bitmap for occupied/not occupied zone when single columned right

.new_get_empty_tiles_gotten_type:
mov  r5,#0
ldr  r6,=#.new_get_empty_tiles_limit_values
add  r6,r6,r2
ldrb r6,[r6,#0]
cmp  r2,#4
bne +
mov  r0,r2
bl   .new_get_menu_character_number    //All characters in skills besides the PSI users use 0x10 as a base
cmp  r0,#2
beq  +
cmp  r0,#4
beq  +
add  r6,#1
+
str  r6,[sp,#0]
lsl  r6,r6,#1
sub  r6,#2
-
add  r3,#0x80
ldrh r0,[r3,#0]
lsr  r2,r0,#5
lsl  r1,r2,#5
sub  r1,r0,r1
mov  r0,r2
ldr  r2,[sp,#0]
cmp  r1,r2
blt  +
mov  r1,#1
orr  r0,r1
+
mov  r1,#1
lsl  r1,r0
orr  r4,r1                             //Set the zone to occupied
ldsh r0,[r3,r6]
lsr  r2,r0,#5
lsl  r1,r2,#5
sub  r1,r0,r1
mov  r0,r2
ldr  r2,[sp,#0]
cmp  r1,r2
blt  +
mov  r1,#1
orr  r0,r1
+
mov  r1,#1
lsl  r1,r0
orr  r4,r1                             //Set the zone to occupied
add  r5,#1
cmp  r5,#8
blt  -
mov  r5,#0                             //Now get the free zones
mov  r3,#0
mov  r2,#0
mov  r1,#0
-
mov  r0,#1
lsl  r0,r5
and  r0,r4
cmp  r0,#0
bne  +
mov  r2,r3
mov  r3,r5
add  r1,#1
+
add  r5,#1
cmp  r5,#0x20
bge  +
cmp  r1,#2
blt  -
+
// r2 and r3 have our numbers
ldr  r6,=#0x6008000
ldr  r1,[sp,#0]
mov  r5,#1
and  r5,r2
sub  r2,r2,r5
lsl  r2,r2,#5
cmp  r5,#1
bne  +
orr  r2,r1
+
lsl  r2,r2,#5
add  r0,r2,r6
mov  r5,#1
and  r5,r3
sub  r3,r3,r5
lsl  r3,r3,#5
cmp  r5,#1
bne  +
orr  r3,r1
+
lsl  r3,r3,#5
add  r1,r3,r6
ldr  r2,=#0x201A288
ldrb r3,[r2,#0]
ldr  r4,=#.new_get_empty_tiles_limit_values
ldrb r2,[r4,r3]
cmp  r3,#4
bne +
mov  r4,r0
mov  r0,r3
bl   .new_get_menu_character_number    //All characters in skills besides the PSI users use 0x10 as a base
mov  r3,r0
mov  r0,r4
cmp  r3,#2
beq  +
cmp  r3,#4
beq  +
add  r2,#1
+
lsl  r3,r2,#5
sub  r1,r1,r3

.end_new_get_empty_tiles:
add  sp,#4
pop  {r4-r6,pc}

//=============================================================================================
// This hack negates VRAM printing for a frame
//=============================================================================================
.negate_printing:
ldr  r0,=#0x20225D4                    //Don't print this frame
ldrb r1,[r0,#0]
mov  r2,#9
neg  r2,r2
and  r1,r2
strb r1,[r0,#0]
bx   lr

//=============================================================================================
// This hack combines all the hacks above.
// It moves the arrangements around instead of re-printing everything.
// It only prints what needs to be printed.
//=============================================================================================
.up_down_scrolling_print:
push {lr}
add  sp,#-0xC
bl   .new_get_empty_tiles
str  r2,[sp,#8]
str  r0,[sp,#4]
str  r1,[sp,#0]
bl   .new_print_menu_up_down
ldr  r4,=#0x201AEF8
mov  r0,r4
bl   $803E908
-
mov  r0,#1
bl   .new_print_vram_container
mov  r0,r4
bl   $803E908
ldr  r0,=#0x2013040                    //Check for two names with a total of 41+ letters on the same line.
ldrb r1,[r0,#2]                        //Max item name size is 21, so it's possible, but unlikely.
ldrb r2,[r0,#3]                        //At maximum 2 letters must be printed, so it's fast.
cmp  r1,r2                             //Can happen with (pickled veggie plate or jar of yummy pickles or saggittarius bracelet
bne  -                                 //or mole cricket brother) + bag of big city fries on the same line.
add  sp,#0xC
pop  {pc}

//=============================================================================================
// This hack combines all the hacks above.
// It moves the arrangements and the graphics around, then allows re-printing.
// It only prints what needs to be printed.
//=============================================================================================
.move_and_print:
push {lr}
bl   .new_print_menu_up_down
pop  {pc}

//=============================================================================================
// This hack combines all the hacks above.
// It moves the arrangements around instead of re-printing everything.
// It only prints what needs to be printed.
// This version takes pre-established free tiles instead of determining them on the fly
//=============================================================================================
.up_down_scrolling_print_no_get_empty_tiles:
push {lr}
add  sp,#-0xC
str  r2,[sp,#8]
str  r0,[sp,#4]
str  r1,[sp,#0]
bl   .new_print_menu_up_down
ldr  r4,=#0x201AEF8
mov  r0,r4
bl   $803E908
-
mov  r0,#1
bl   .new_print_vram_container
mov  r0,r4
bl   $803E908
ldr  r0,=#0x2013040                    //Check for two names with a total of 41+ letters on the same line.
ldrb r1,[r0,#2]                        //Max item name size is 21, so it's possible, but unlikely.
ldrb r2,[r0,#3]                        //At maximum 2 letters must be printed, so it's fast.
cmp  r1,r2                             //Can happen with (pickled veggie plate or jar of yummy pickles or saggittarius bracelet
bne  -                                 //or mole cricket brother) + bag of big city fries on the same line.
add  sp,#0xC
pop  {pc}

//=============================================================================================
// This hack combines all the hacks above.
// It moves the arrangements around instead of re-printing everything.
// It only prints what needs to be printed.
// This version takes pre-established free tiles instead of determining them on the fly
//=============================================================================================
.pressing_a_scrolling_print_no_get_empty_tiles:
push {lr}
add  sp,#-0xC
str  r2,[sp,#8]
str  r0,[sp,#4]
str  r1,[sp,#0]
bl   .new_print_menu_a
ldr  r4,=#0x201AEF8
mov  r0,r4
bl   $803E908
-
mov  r0,#1
bl   .new_print_vram_container
mov  r0,r4
bl   $803E908
ldr  r0,=#0x2013040                    //Check for two names with a total of 41+ letters on the same line.
ldrb r1,[r0,#2]                        //Max item name size is 21, so it's possible, but unlikely.
ldrb r2,[r0,#3]                        //At maximum 2 letters must be printed, so it's fast.
cmp  r1,r2                             //Can happen with (pickled veggie plate or jar of yummy pickles or saggittarius bracelet
bne  -                                 //or mole cricket brother) + bag of big city fries on the same line.
add  sp,#0xC
pop  {pc}

//=============================================================================================
// This hack swaps the arrangements in order to not re-print everything when removing/moving an item
//=============================================================================================
.new_generic_swap_arrangement:
push {r3-r6,lr}
mov  r4,r0                             //This has the selected index before anything was removed/moved.
                                       //Using that covers the player selecting the last item and getting
                                       //their cursor moved

ldr  r5,=#0x2016978
bl   .get_positions_lines_array
mov  r6,r0
bl   .get_possible_indexes
sub  r3,r0,#1
cmp  r4,r3                             //Cover edge case
bge  +
-
mov  r0,r4                             //Swap a single item's arrangement
bl   .new_handle_selling_swap_arrangement
bl   .new_general_swap_single_line
add  r4,#1
cmp  r4,r3
blt  -
+
mov  r0,r3
bl   .new_handle_selling_swap_arrangement
bl   .new_general_clear_final_line     //Clear the last item's arrangement
pop  {r3-r6,pc}

//=============================================================================================
// This hack copies an item's arrangements in order to not re-print everything when moving an item
//=============================================================================================
.new_generic_copy_arrangement:
push {r4-r7,lr}
mov  r4,r0                             //This has the selected index before anything was removed/moved.
                                       //Using that covers the player selecting the last item and getting
                                       //their cursor moved
mov  r3,r1                             //Put in r3 whether to copy from or to the item's arrangement
mov  r7,r2                             //Put in r7 the target
ldr  r5,=#0x2016978
bl   .get_positions_lines_array
mov  r6,r0
mov  r0,r4                             //Copies a single item's arrangements from/to r7
mov  r1,r3
mov  r2,r7
bl   .new_general_copy_single_line
pop  {r4-r7,pc}

//=============================================================================================
// This hack handles the selling special case
//=============================================================================================
.new_handle_selling_swap_arrangement:
push {lr}
ldr  r1,=#0x201A288
ldrb r1,[r1,#0]
cmp  r1,#0xB
bne  +
lsl  r0,r0,#1
add  r0,#1
+
pop  {pc}

//=============================================================================================
// This hack swaps the deposit arrangements in order to not re-print everything when depositing an item.
// It also handles the inventory arrangements swapping
//=============================================================================================
.new_inventory_deposit_swap_arrangement:
push {lr}
ldr  r0,[r0,#0x8]
bl   .new_generic_swap_arrangement
pop  {pc}

//=============================================================================================
// This hack copies one line of inventory's arrangements in order to not re-print everything when moving an item.
//=============================================================================================
.new_inventory_copy_arrangement:
push {lr}
ldr  r0,[r0,#0x8]
bl   .new_generic_copy_arrangement
pop  {pc}

//=============================================================================================
// This hack swaps the withdraw arrangements in order to not re-print everything when withdrawing an item
//=============================================================================================
.new_withdraw_swap_arrangement:
push {lr}
ldr  r1,[r0,#4]
ldr  r0,[r0,#8]
sub  r0,r0,r1
bl   .new_generic_swap_arrangement
pop  {pc}

//=============================================================================================
// Hack that stores the flag that puts the arrangement buffer back to VRAM
//=============================================================================================
.store_arrangements_buffer:
push {r0-r5,lr}

mov  r0,#0x0                           //Order printing a blank tile
bl   $80486A0                          //Blank text, get the pointer to it
mov  r5,#1
neg  r5,r5
mov  r4,#1
str  r4,[sp,#0]                        //Gray text
mov  r1,#0
mov  r2,#0
mov  r3,r5
bl   $8047B9C                          //Order its printing

ldr  r4,=#0x201AEF8
mov  r0,r4
bl   $803E908                          //Print this to VRAM now!
bl   $80487D4
mov  r0,r4
bl   $803E908

pop  {r0-r5,pc}

//=============================================================================================
// Gets the array of the positions for swapping
// Order (reversed) is:
// Right side's position | Left side's position | Distance between right and lower left | Size
//=============================================================================================
.positions_swapping_array:
  dd $10620220; dd $00000000; dd $00000000; dd $00000000
  dd $00000000; dd $00000000; dd $00000000; dd $00000000
  dd $00000000; dd $00000000; dd $00000000; dd $1080001E
  dd $00000000; dd $00000000; dd $10620220; dd $0E64021E
  dd $00000000; dd $00000000; dd $00000000; dd $00000000
  dd $00000000; dd $00000000; dd $00000000; dd $00000000
  dd $00000000; dd $00000000; dd $00000000; dd $00000000
  dd $00000000; dd $00000000; dd $00000000; dd $00000000

.get_positions_lines_array:
ldr  r1,=#.positions_swapping_array
ldr  r0,=#0x201A288
ldrb r0,[r0,#0]
lsl  r0,r0,#2
add  r0,r1,r0
bx   lr

//=============================================================================================
// Swaps a single item's arrangement
//=============================================================================================
.new_general_swap_single_line:
push {r3-r4,lr}
mov  r2,#1
and  r2,r0
lsr  r0,r0,#1
lsl  r0,r0,#7
cmp  r2,#0
beq  +
ldrb r2,[r6,#0]
+
add  r1,r5,r0
add  r1,r1,r2                          //Get the arrangement address
mov  r4,r1
cmp  r2,#0
bne  +

ldrb r2,[r6,#0]
add  r0,r4,r2                          //Branch for an item to the left
ldrb r2,[r6,#1]
add  r1,r1,r2
ldrb r2,[r6,#3]
swi  #0xB
add  r4,#0x40
ldrb r2,[r6,#0]
add  r0,r4,r2
ldrb r2,[r6,#1]
add  r1,r4,r2
ldrb r2,[r6,#3]
swi  #0xB
b    .new_general_swap_single_line_end
+

ldrb r2,[r6,#2]
add  r0,r4,r2                          //Branch for an item to the right
ldrb r2,[r6,#3]
swi  #0xB
add  r4,#0x40
ldrb r2,[r6,#2]
add  r0,r4,r2
mov  r1,r4
ldrb r2,[r6,#3]
swi  #0xB

.new_general_swap_single_line_end:
pop  {r3-r4,pc}

//=============================================================================================
// Copies a single item's arrangement to a given address r2.
// r1 controls whether to copy to or copy from r2
//=============================================================================================
.new_general_copy_single_line:
push {r3-r7,lr}
add  sp,#-0x10
mov  r7,r2
mov  r3,#1
and  r3,r0
lsr  r0,r0,#1
lsl  r0,r0,#7
ldrb r2,[r6,#1]
cmp  r3,#0
beq  +
ldrb r2,[r6,#0]                        //Handle the right side differently
+
add  r0,r5,r0
add  r0,r0,r2                          //Get the arrangement address
mov  r2,#0x20                          //Save the arrangement address and the target/source address on the stack
add  r5,r7,r2                          //This allows using a generic copying routine
mov  r2,#0x40
add  r2,r0,r2
cmp  r1,#1
beq  +
str  r0,[sp,#0]
str  r2,[sp,#4]
str  r7,[sp,#8]
str  r5,[sp,#0xC]
b    .new_general_copy_single_line_start_copy
+
str  r7,[sp,#0]
str  r5,[sp,#4]
str  r0,[sp,#8]
str  r2,[sp,#0xC]

.new_general_copy_single_line_start_copy:
ldr  r0,[sp,#0]
ldr  r1,[sp,#8]
ldrb r2,[r6,#3]
swi  #0xB
ldr  r0,[sp,#4]
ldr  r1,[sp,#0xC]
ldrb r2,[r6,#3]
swi  #0xB

add  sp,#0x10
pop  {r3-r7,pc}

//=============================================================================================
// Clears the last item's arrangement
//=============================================================================================
.new_general_clear_final_line:
push {r4,lr}
mov  r2,#1
lsr  r0,r0,#1
lsl  r0,r0,#7
cmp  r2,#0
beq  +
ldrb r2,[r6,#0]
+
add  r1,r5,r0
add  r1,r1,r2
mov  r4,r1
mov  r0,#0
push {r0}
mov  r0,sp                             //Part that clears the top of the last item's arrangement
ldr  r2,=#0x01000008
swi  #0xC
add  r4,#0x40
mov  r0,sp
mov  r1,r4                             //Part that clears the bottom of the last item's arrangement
ldr  r2,=#0x01000008
swi  #0xC
pop  {r0}
pop  {r4,pc}

//=============================================================================================
// Prepares the withdraw inventory for swapping character. Based off of $804C39A.
// Removes the part that resets the cursor's position
//=============================================================================================
.prepare_swap_char_withdraw:
push {r4,lr}
ldr  r2,=#0x2016028
ldr  r0,=#0x4260
add  r1,r2,r0
mov  r3,#0
mov  r0,#0xF
strb r0,[r1,#0]                        //Saves the fact that this is the withdrawing menu
ldr  r0,=#0x2FE0
add  r1,r2,r0
ldr  r0,=#0x4264
add  r2,r2,r0
ldrb r0,[r2,#0]
strh r0,[r1,#0xA]                      //Remove position resetting
ldrh r0,[r1,#0xA]
bl   $8054FE0
mov  r4,r0
bl   $80524EC
mov  r0,r4
bl   $80531C8
pop  {r4,pc}

//=============================================================================================
// Prepares the buying inventory for swapping character. Based off of $804C254.
// Removes the part that resets the cursor's position
//=============================================================================================
.prepare_swap_char_buying:
push {r4-r6,lr}
ldr  r6,=#0x2016028
ldr  r0,=#0x4260
add  r1,r6,r0
mov  r2,#0
mov  r0,#0xA
strb r0,[r1,#0]                        //Saves the fact that this is the buying menu
mov  r1,#0xBD
lsl  r1,r1,#6
add  r5,r6,r1
ldr  r1,=#0x4264
add  r0,r6,r1
ldrb r0,[r0,#0]
strh r0,[r5,#0xA]                      //Remove position resetting
ldrh r0,[r5,#0xA]
bl   $8054FE0
mov  r4,r0
bl   $80524EC
mov  r0,r4
bl   $8052F9C
mov  r0,#0x85
lsl  r0,r0,#7
add  r6,r6,r0
ldrh r0,[r6,#0]
strh r0,[r5,#2]
pop  {r4-r6,pc}

//=============================================================================================
// This hack saves in r1 whether the game is still printing or not
//=============================================================================================
.check_if_printed:
push {r0,lr}
ldr  r0,=#0x2013040          //Do the thing only IF we're done printing.
ldrh r1,[r0,#2]              //Prevents issues with arrangements not being there
pop  {r0,pc}

//=============================================================================================
// This hack saves in the stack the info used for printing stuff when things are removed/moved
//=============================================================================================
.store_menu_movement_data:
push {r0,lr}
bl   main_menu_hacks.get_selected_index
str  r0,[sp,#0x10]
bl   main_menu_hacks.get_top_index
str  r0,[sp,#0xC]
bl   main_menu_hacks.get_total_indexes
str  r0,[sp,#8]
pop  {r0,pc}

//=============================================================================================
// This hack changes the palette for an item's arrangement that is stored in r0
//=============================================================================================
.change_palette:
push {r1-r5,lr}
mov  r4,r0                   //r4 = r0 = initial address
ldr  r2,=#0x0FFF             //r2 = 0xFFF, used to get the non-palette part
ldrh r1,[r0,#0]
mov  r3,r1
and  r1,r2
cmp  r1,#0
beq  .change_palette_end     //If there is no item, stop here
mov  r1,r3
mov  r5,#0xF0
lsl  r5,r5,#8
and  r5,r1
mov  r3,#0                   //Get whether this was 0x8XXX or 0x0XXX
cmp  r5,#0
bne  +
mov  r3,#0x80
lsl  r3,r3,#8
+
mov  r5,r3                   //r5 now has either 0x0000 or 0x8000
mov  r3,#0                   //r3 is a counter used in order to avoid issues

-
ldrh r1,[r0,#0]
and  r1,r2                   //Pick the non-palette part
cmp  r1,#0
beq  +                       //If it's 0, proceed to the next step
orr  r1,r5                   //Otherwise, or it with the new palette
strh r1,[r0,#0]              //and then store it
add  r0,#2
add  r3,#1                   //Continue along
cmp  r3,#0x10
blt  -
+

mov  r0,r4
add  r0,#0x40                //Get the bottom address. Initial one + 0x40
mov  r3,#0

-
ldrh r1,[r0,#0]
and  r1,r2                   //Pick the non-palette part
cmp  r1,#0
beq  +                       //If it's 0, proceed to the next step
orr  r1,r5                   //Otherwise, or it with the new palette
strh r1,[r0,#0]              //and then store it
add  r0,#2
add  r3,#1                   //Continue along
cmp  r3,#0x10
blt  -
+

.change_palette_end:
pop  {r1-r5,pc}

//=============================================================================================
// This hack sets in r0 a bitmask of the currently valid options
// It takes r0 as the base address and r1 as the amount to check
//=============================================================================================
.get_valid_options:
push {r4-r6,lr}
mov  r4,r0
mov  r5,r1
mov  r6,#0                   //Counter
mov  r0,#0                   //Setup starting bitmask
cmp  r5,#0x20                //In 4 bytes there are only 0x20 bits
bgt  .get_valid_options_end
-
mov  r2,#0
ldr  r1,[r4,#0]
lsl  r1,r1,#0xA              //Check validity
cmp  r1,#0
bge  +
mov  r2,#1
+
lsl  r2,r6
orr  r0,r2                   //Set r6-th bit in bitmask to r2
add  r4,#4
add  r6,#1
cmp  r5,r6
bgt  -

.get_valid_options_end:
pop  {r4-r6,pc}

//=============================================================================================
// This hack properly handles updating the old options for the shop menu
//=============================================================================================
.update_shop_valid_options:
push {r3,lr}
sub  r3,r1,r2                //r1 contains the old selected index, r2 contains the old top index
mov  r2,#0x20
sub  r2,r2,r3
mov  r1,r0                   //Discard the bit of the old selected item and re-compact this
lsl  r1,r2
lsr  r1,r2
add  r2,r3,#1
lsr  r0,r2
lsl  r0,r3
orr  r0,r1
pop  {r3,pc}

//=============================================================================================
// This hack gets the valid options for the certain menus
//=============================================================================================
.get_menu_valid_options:
push {r2,lr}
bl   main_menu_hacks.get_added_value_menu_valid
ldr  r1,=#0x2016028          //Prepare the address
add  r1,r1,r2
bl   main_menu_hacks.get_top_index
lsl  r0,r0,#2                //Go to the proper first item on the screen
add  r2,r1,r0
bl   main_menu_hacks.get_possible_indexes
mov  r1,r0                   //Set the number of maximum items
mov  r0,r2
bl   main_menu_hacks.get_valid_options
pop  {r2,pc}

//=============================================================================================
// This hack changes the palette for the options that changed validity in the shop menus
//=============================================================================================
.change_shop_options:
push {r4-r6,lr}
mov  r4,r0                   //Save in r4 what changed
mov  r5,r1                   //Arrangement start
mov  r6,#1                   //Number to and with
bl   .get_possible_indexes
mov  r3,r0                   //Number of items in this menu
mov  r1,#0                   //Current index
-
mov  r0,r6
and  r0,r4
cmp  r0,#0
beq  +
lsl  r0,r1,#7                //If this isn't 0, it changed...
add  r0,r5,r0                //Prepare the corresponding arrangement address
bl   main_menu_hacks.change_palette
+
add  r1,#1
lsl  r6,r6,#1                //Prepare to check the next bit
cmp  r1,r3                   //There are r3 items displayed top in this menu
blt  -

pop  {r4-r6,pc}

//=============================================================================================
// This hack changes the palette for the options that changed validity in the psi menu
//=============================================================================================
.change_psi_options:
push {r4-r6,lr}
mov  r4,r0                   //Save in r4 what changed
mov  r5,r1                   //Arrangement start
mov  r6,#1                   //Number to and with
bl   .get_possible_indexes
mov  r3,r0                   //Number of items in this menu
mov  r1,#0                   //Current index
-
mov  r0,r6
and  r0,r4
cmp  r0,#0
beq  .change_psi_options_end_single
lsr  r0,r1,#1                //If this isn't 0, it changed...
lsl  r2,r0,#7
mov  r0,#1
and  r0,r1
cmp  r0,#1
bne  +
mov  r0,#0x1C                //Handle the right side
+
add  r0,r0,r2
add  r0,r5,r0                //Prepare the corresponding arrangement address
bl   main_menu_hacks.change_palette
.change_psi_options_end_single:
add  r1,#1
lsl  r6,r6,#1                //Prepare to check the next bit
cmp  r1,r3                   //There are r3 items displayed top in this menu
blt  -

pop  {r4-r6,pc}

//=============================================================================================
// This hack removes an item and then prints a new one if need be
//=============================================================================================
.printing_pressed_a:
push {r4-r7,lr}
mov  r7,r0
ldr  r1,[r7,#0]
bl   main_menu_hacks.get_total_indexes
cmp  r0,r1                   //Skip printing if we don't remove an item from the withdrawing menu
beq  .printing_pressed_a_end

bl   main_menu_hacks.get_possible_indexes
mov  r1,r0
bl   main_menu_hacks.get_difference_top_total
cmp  r0,r1                   //We'll need the free tiles if we have more than r1 items after the top one
blt  +

bl   main_menu_hacks.new_get_empty_tiles
mov  r4,r0                   //We need to get them now and to store them in order to avoid
mov  r5,r1                   //writing to a bunch of tiles that was just freed
mov  r6,r2
+

//Move the items' arrangements around by one
mov  r0,r7
bl   main_menu_hacks.new_withdraw_swap_arrangement

bl   main_menu_hacks.get_possible_indexes
mov  r1,r0
bl   main_menu_hacks.get_difference_top_total
cmp  r0,r1                   //If this is >= r1, then we need to print new stuff!
bge  +

//If we don't need to print new stuff, just set buffer to be updated and end this here
mov  r0,#1
b    .printing_pressed_a_end_update

+
ldr  r1,[r7,#4]
bl   main_menu_hacks.get_top_index
cmp  r0,r1                   //Check if the top index changed between the A press and now...
beq  +

//If it did, the menu position was moved up by one. We don't need to print new stuff at the bottom,
//but we'll need to print new stuff at the top (the top two new items) and to move everything down
//by one line. Luckily, up_down_scrolling_print_no_get_empty_tiles handles it for us.
//We'll just need to trick it into thinking the selected_index corresponds to the top one.
bl   main_menu_hacks.set_selected_index
mov  r2,r0
mov  r0,r4
mov  r1,r5
mov  r5,r2                   //Saves the old selected_index in r5 temporarily
mov  r2,r6
bl   main_menu_hacks.up_down_scrolling_print_no_get_empty_tiles
mov  r0,r5                   //Restores the old selected_index
bl   main_menu_hacks.set_selected_index
b    .printing_pressed_a_end

+
//If it didn't, we need to print one item at the bottom right
mov  r1,r0
bl   main_menu_hacks.get_possible_indexes
sub  r0,#1
add  r0,r1,r0
bl   main_menu_hacks.set_selected_index
mov  r2,r0
mov  r0,r4
mov  r1,r5
mov  r5,r2                   //Saves the old selected_index in r5 temporarily
mov  r2,r6
bl   main_menu_hacks.pressing_a_scrolling_print_no_get_empty_tiles
mov  r0,r5                   //Restores the old selected_index
bl   main_menu_hacks.set_selected_index

.printing_pressed_a_end:
mov  r0,#0
.printing_pressed_a_end_update:
pop  {r4-r7,pc}

//=============================================================================================
// This hack calls printing_pressed_a and then updates the greyed out options. Used only by the sell menu
//=============================================================================================
.printing_pressed_a_update_grey:
push {r4-r5,lr}
mov  r4,r0
bl   .printing_pressed_a
mov  r5,r0
cmp  r0,#1
bne  +                       //Store the arrangements buffer if it returned 1
bl   .store_arrangements_buffer
+
ldr  r1,[r4,#0]
bl   .get_total_indexes
cmp  r1,r0                   //Check if the number of items in the menu changed, otherwise do nothing
beq  .printing_pressed_a_update_grey_end
bl   .get_menu_valid_options
mov  r3,r0
ldr  r0,[r4,#0xC]
ldr  r1,[r4,#0x8]
ldr  r2,[r4,#0x4]
bl   .update_shop_valid_options
mov  r2,r0
cmp  r5,#0
bne  .printing_pressed_a_update_grey_compare
ldr  r1,[r4,#4]
bl   .get_top_index
sub  r0,r0,r1
mov  r1,#0x1F
cmp  r0,#0                   //Check if the top index changed between the A press and now...
beq  +
lsl  r2,r2,#1                //These are now the bottom options, not the top ones
lsl  r1,r1,#1
+
and  r3,r1                   //Make it so the bit that isn't in r2 and the one that is in r3 match

.printing_pressed_a_update_grey_compare:
eor  r2,r3                   //If the valid options changed, change
cmp  r2,#0                   //the assigned palette for those that changed
beq  +                       //and then set the arrangements to be updated
mov  r0,r2
ldr  r1,=#0x2016996
bl   main_menu_hacks.change_shop_options
+
.printing_pressed_a_update_grey_end:
pop  {r4-r5,pc}

//=============================================================================================
// This hack fixes 8-letter names on the main file load screen.
//=============================================================================================

.filechoose_lengthfix:
str  r3,[sp,#0]     // clobbered code
// Address in r0. Return the length in r3.
push {r0,lr}
mov  r3,#9          // default value
bl   check_name     // see if it's a custom name
cmp  r0,#0
beq  +
mov  r3,r0
+
pop  {r0,pc}

//=============================================================================================
// Gender for status ailments
//=============================================================================================
.status_gender:
push {lr}
mov  r1,r9
ldrb r1,[r1,#0]
cmp  r1,#0x4                 //Id for Kumatora (when Lucas is 1 instead of 0)
bne  +
add  r0,#0x8
+
bl   $80486A0
pop  {pc}

//=============================================================================================
// This hack fixes the fact that if you lose the first battle Claus won't have any PP left
//=============================================================================================

claus_pp_fix:
.main:
push {lr}
lsl  r0,r0,#0x10             //Character identifier
lsr  r0,r0,#0x10
cmp  r0,#2                   //Lucas
beq  +
cmp  r0,#4                   //Kumatora
beq  +
cmp  r0,#0xD                 //Claus
bne  .failure
+
mov  r0,#1                   //Allow copying PPs
b    .end

.failure:                    //If it's not one of them, then they should not have PPs
mov  r0,#0

.end:
pop  {pc}

//=============================================================================================
// This set of hacks cleans the writing stack
//=============================================================================================
refreshes:

//=============================================================================================
// The main hack that clears the actual writing stack
//=============================================================================================
.main:
push {lr}
ldr  r1,=#0x2013040          //Address of the stack
mov  r0,#0
str  r0,[r1,#0x0]           //Clean the words' lengths so it won't print
str  r0,[r1,#0x10]
str  r0,[r1,#0x14]
str  r0,[r1,#0x18]
str  r0,[r1,#0x1C]
pop  {pc}


//=============================================================================================
// These hacks call the main one to clear the writing stack
//=============================================================================================
.lr:
push {lr}
bl   .main
ldrh r1,[r5,#0xA]            //Normal stuff the game expects from us
ldr  r2,=#0x4264
pop  {pc}

.b:
push {lr}
bl   .main
mov  r0,#0xD3                //Normal stuff the game expects from us
bl   $800399C
pop  {pc}

.inv_spec_a:
push {lr}
bl   .main
ldr  r1,=#0x426A             //Normal stuff the game expects from us
add  r0,r1,r7
pop  {pc}

.memo_a:
push {lr}
bl   .main
mov  r0,r5                   //Normal stuff the game expects from us
bl   $804EEE8
pop  {pc}

.equip_a:
push {lr}
bl   .main
mov  r0,r4                   //Normal stuff the game expects from us
bl   $804EB68
pop  {pc}

.inner_memo_scroll:
push {r1,lr}                 //Let's save r1, since the game needs it
bl   .main
pop  {r1}
mov  r0,r1                   //Normal stuff the game expects from us
bl   $804EF38
pop  {pc}

.inner_equip_a:
push {lr}
bl   .main
ldr  r7,=#0x2016028          //Normal stuff the game expects from us
ldr  r0,=#0x41C6
pop  {pc}

.switch_lr:
push {lr}
bl   .main
ldrh r0,[r4,#4]              //Normal stuff the game expects from us
bl   $8053E98
pop  {pc}

.status_lr:
push {lr}
bl   .main
ldrh r1,[r4,#0xA]            //Normal stuff the game expects from us
ldr  r2,=#0x4264
pop  {pc}

//=============================================================================================
// These hacks call the main one to clear the writing stack and then blank out the tiles.
// This makes it so the printing process isn't showed
//=============================================================================================
.deposit_lr:
push {lr}
bl   .main
bl   main_menu_hacks.delete_vram
bl   $804C35C                //Normal stuff the game expects from us
pop  {pc}

.psi_select:
push {lr}
bl   .main
bl   main_menu_hacks.delete_vram
mov  r0,#0xD2                //Normal stuff the game expects from us
bl   $800399C
pop  {pc}

.status_a:
push {lr}
ldr  r0,=#0x201A288
ldrb r0,[r0,#0]
cmp  r0,#4
bne  +
bl   .main
bl   main_menu_hacks.delete_oam_vram
+
bl   $8046D90                //Normal stuff the game expects from us
pop  {pc}

.skills_b:
push {lr}
bl   .main
bl   main_menu_hacks.delete_oam_vram
mov  r0,#0xD3                //Normal stuff the game expects from us
bl   $800399C
pop  {pc}

//=============================================================================================
// This hack blanks out a part of OAM's text tiles.
// This makes it so the printing process isn't showed
//=============================================================================================
.inv_submenu_a:
push {lr}
ldr  r0,=#0x201A288
ldrb r0,[r0,#0]
cmp  r0,#0                   //Make sure we're in the inventory. Double checking never hurts
bne  +                       //If we are, clean a subsection of OAM's VRAM
bl   main_menu_hacks.delete_oam_vram_subsection
+
bl   $804FA5C                //Normal stuff the game expects from us
pop  {pc}

//=============================================================================================
// This hack calls the main one to clear the writing stack.
// It then changes how the withdraw menu swaps character. (Top index and selected item won't change)
//=============================================================================================
.withdraw_lr:
push {lr}
bl   .main                   //Don't refresh the withdraw menu when we swap character...
bl   main_menu_hacks.prepare_swap_char_withdraw
pop  {pc}

//=============================================================================================
// This hack calls the main one to clear the writing stack.
// It then moves the text up/down and prints only the bottom/top line
//=============================================================================================
.up_and_down:
push {r0-r2,lr}
bl   .main
//bl   $8046D90              //Normal stuff the game expects from us
bl   main_menu_hacks.up_down_scrolling_print
pop  {r0-r2,pc}

//=============================================================================================
// This hack calls the main one to clear the writing stack only if the game's done printing.
// If the game's done printing, it then moves the text up/down and prints only the bottom/top line
//=============================================================================================
.up_and_down_battle_memoes:
push {lr}
add  sp,#-4
ldr  r0,[sp,#8]
str  r0,[sp,#0]

bl   main_menu_hacks.check_if_printed
mov  r0,#0                   //Do the thing only IF we're done printing.
cmp  r1,#0                   //Prevents issues with arrangements not being there
bne  +
mov  r0,r5
mov  r1,r7
bl   $8053598
lsl  r0,r0,#0x10
lsr  r0,r0,#0x10
cmp  r0,#2
bne  +
push {r0-r2}
bl   .main
bl   main_menu_hacks.up_down_scrolling_print
ldr  r1,=#0xC5AD             //Signal printing
add  r1,r1,r6
ldrb r0,[r1,#0]
mov  r2,#1
orr  r0,r2
strb r0,[r1,#0]
pop  {r0-r2}
mov  r0,#1
+
add  sp,#4
pop  {pc}

//=============================================================================================
// These hacks allow input reading only if the game's done printing.
//=============================================================================================
.inv_block_a:
push {lr}
bl   main_menu_hacks.check_if_printed
cmp  r1,#0                   //Have we finished printing?
beq  .inv_block_a_passed     //Yes! Then let it do what it wants to do
pop  {r0}
ldr  r0,=#0x804CC35          //No! Prevent the game from opening stuff we don't want yet.
bx   r0

.inv_block_a_passed:
ldr  r0,=#0x2DFA             //Normal stuff the game expects from us
add  r1,r7,r0
pop  {pc}

.inv_submenu_block_a:
push {lr}
bl   main_menu_hacks.check_if_printed
mov  r0,r1
mov  r1,#0                   //Have we finished printing?
cmp  r0,#0
bne  +
ldrh r1,[r4,#0]              //Normal input loading
+
mov  r0,#3
pop  {pc}

.sell_block_input_up_and_down:
push {lr}
add  sp,#-0x8
str  r0,[sp,#4]
ldr  r0,[sp,#0xC]
str  r0,[sp,#0]              //Prepare args for the function
mov  r2,r1

bl   main_menu_hacks.check_if_printed
mov  r0,#0                   //Do this only if it's done printing
cmp  r1,#0
bne  +
ldr  r0,[sp,#4]
mov  r1,r2
mov  r2,r5
bl   $8053598
+
add  sp,#0x8
pop  {pc}

.sell_a:
push {lr}
bl   main_menu_hacks.check_if_printed
cmp  r1,#0
bne  +
push {r2}                    //Let's save r2, since the game needs it
bl   .main
pop  {r2}
mov  r0,r2                   //Normal stuff the game expects from us
bl   $804F0D4
+
pop  {pc}

.psi_prevent_input_a_select:
push {lr}
bl   main_menu_hacks.check_if_printed
mov  r0,r1
ldrh r1,[r7,#0]              //Input
cmp  r0,#0
beq  +
ldr  r0,=#0xFFFA
and  r1,r0                   //Prevent using A and SELECT if the PSI menu isn't fully done printing
+
cmp  r1,#1                   //Clobbered code
pop  {pc}

.withdraw_psi_memo_block_input_up_and_down:
push {lr}
add  sp,#-0xC
ldr  r0,[sp,#0x10]
str  r0,[sp,#0]
ldr  r0,[sp,#0x14]
str  r0,[sp,#4]
ldr  r0,[sp,#0x18]
str  r0,[sp,#8]              //Prepare args for the function

bl   main_menu_hacks.check_if_printed
mov  r0,#0                   //Do this only if it's done printing
cmp  r1,#0
bne  +
add  r0,r5,#4
mov  r1,r5
add  r1,#8
bl   $8053968
+
add  sp,#0xC
pop  {pc}

.withdraw_block_input_lr:
push {lr}
add  sp,#-4
ldr  r0,[sp,#8]
str  r0,[sp,#0]              //Prepare arg for the function

bl   main_menu_hacks.check_if_printed
mov  r0,#0                   //Do the thing only IF we're done printing.
cmp  r1,#0                   //Prevents issues with arrangements not being there
bne  +
add  r0,r4,#4
mov  r1,r7
bl   $8053754
+
add  sp,#4
pop  {pc}

.buy_block_a:
push {lr}
bl   main_menu_hacks.check_if_printed
cmp  r1,#0                   //Prevent confirming buying (it interacts with
bne  +                       //the arrangements) unless everything's printed
bl   $8050008
+
pop  {pc}

.buy_block_up_down:
push {lr}
add  sp,#-4
mov  r2,r0
bl   main_menu_hacks.check_if_printed
mov  r0,#0                   //Prevent scrolling up or down (it interacts with
cmp  r1,#0                   //the arrangements) unless everything's printed
bne  +
ldr  r0,[sp,#8]              //Prepare args for the function
str  r0,[sp,#0]
mov  r0,r2
mov  r2,r5
add  r1,r0,#4
bl   $8053598
+
add  sp,#4
pop  {pc}

.buy_block_lr:
push {lr}
add  sp,#-4
mov  r2,r0
bl   main_menu_hacks.check_if_printed
mov  r0,#0                   //Prevent changing character (it interacts with
cmp  r1,#0                   //the arrangements) unless everything's printed
bne  +
ldr  r0,[sp,#8]              //Prepare args for the function
str  r0,[sp,#0]
mov  r1,r5
mov  r0,r2
mov  r2,#0
bl   $8053754
+
add  sp,#4
pop  {pc}

.equip_block_input_lr:
push {lr}
add  sp,#-4
ldr  r0,[sp,#8]
str  r0,[sp,#0]              //Prepare arg for the function

bl   main_menu_hacks.check_if_printed
mov  r0,#0                   //Do the thing only IF we're done printing.
cmp  r1,#0                   //Prevents issues with arrangements not being there
bne  +
mov  r0,r4
add  r0,#0xA
mov  r1,r5
mov  r2,#0
bl   $8053754
+
add  sp,#4
pop  {pc}

.status_block_input_lr:
push {lr}
add  sp,#-4
ldr  r0,[sp,#8]
str  r0,[sp,#0]              //Prepare arg for the function

bl   main_menu_hacks.check_if_printed
mov  r0,#0                   //Do the thing only IF we're done printing.
cmp  r1,#0                   //Prevents issues with arrangements not being there
bne  +
mov  r0,r4
add  r0,#0xA
mov  r1,r2
mov  r2,#0
bl   $8053754
+
add  sp,#4
pop  {pc}

//=============================================================================================
// This hack updates the inventory.
// It then returns both the new inventory size and the one before updating it
//=============================================================================================
.inv_load_new_old_size:
push {lr}
add  sp,#-4
mov  r1,r0
bl   main_menu_hacks.get_character_inventory_total_indexes
str  r0,[sp,#0]              //Save old inventory's size
mov  r0,r1
bl   $80524EC                //Routine that updates inventory's size
bl   main_menu_hacks.get_character_inventory_total_indexes
ldr  r1,[sp,#0]              //Put in r0 the new size and in r1 the old one
add  sp,#4
pop  {pc}

//=============================================================================================
// This hack makes it so if we're in the buying menu, a certain B branch doesn't update the screen.
// This happens in the "Equip X?" and "Sell X?" submenus
//=============================================================================================
.shop_block_b_update:
push {lr}
ldr  r0,=#0x201A288
ldrb r0,[r0,#0]              //Load the menu type
cmp  r0,#0xA                 //Is this the buying menu?
beq  +
bl   $8046D90                //If not, proceed normally
+
pop  {pc}

//=============================================================================================
// This hack handles using/giving/throwing inventory items in an optimized way by not printing
//=============================================================================================
.inv_handle_item_movement:
push {r4,lr}
add  sp,#-0x50
mov  r4,#0
str  r4,[sp,#0xC]            //Set this address to a default
mov  r4,r2
bl   main_menu_hacks.store_menu_movement_data
bl   .inv_load_new_old_size

cmp  r0,r1
bne  +                       //Did the inventory's size change?
                             //If it did not, check if we should move the item to the bottom
cmp  r4,#1
bne  .inv_handle_item_movement_end

str  r0,[sp,#0xC]            //Save the fact that we should move the item to the bottom
mov  r0,sp
mov  r1,#0                   //Copy from the arrangements
mov  r2,#0x10
add  r2,r2,r0                //Load the item's arrangements in
bl   main_menu_hacks.new_inventory_copy_arrangement

+
mov  r0,sp
bl   main_menu_hacks.new_inventory_deposit_swap_arrangement
ldr  r0,[sp,#0xC]
cmp  r0,#0
beq  +

sub  r0,r0,#1
str  r0,[sp,#8]              //Put the target in the movement data
mov  r0,sp
mov  r1,#1                   //Copy to the arrangements
mov  r2,#0x10
add  r2,r2,r0                //Move the item's arrangement to the bottom
bl   main_menu_hacks.new_inventory_copy_arrangement

+
bl   main_menu_hacks.store_arrangements_buffer
mov  r0,#0                   //Return the fact that the size changed
.inv_handle_item_movement_end:
add  sp,#0x50
pop  {r4,pc}

//=============================================================================================
// This hack handles using and throwing inventory items
//=============================================================================================
.inv_use_throw:
push {r2,lr}
mov  r2,#0                   //If the size stays the same, no operation to be done
bl   .inv_handle_item_movement
cmp  r0,#0
bne  +
ldr  r0,=#0x2015D98
ldrb r1,[r0,#0]
mov  r2,#4                   //Prevents glitch in which the new currently selected item's data would show up for the top OAM
orr  r1,r2
strb r1,[r0,#0]
+
pop  {r2,pc}

//=============================================================================================
// This hack handles giving inventory items (It's a special case because you can give them
// to the same character and change the inventory's order without changing its size)
//=============================================================================================
.inv_give:
push {r2,lr}
mov  r2,#1                   //If the size stays the same, move the item to the bottom
bl   .inv_handle_item_movement
pop  {r2,pc}

//=============================================================================================
// These hacks save which entries are valid and then update them.
// This allows changing the palette of certain entries instead of reprinting them
//=============================================================================================
.sell_confirmed_a:
push {lr}
add  sp,#-0x10
bl   main_menu_hacks.store_menu_movement_data
bl   main_menu_hacks.get_menu_valid_options
str  r0,[sp,#0xC]

bl   $8050218
add  sp,#0x10
pop  {pc}

.sell_confirmed_equipment_a:
push {lr}
add  sp,#-0x10
bl   main_menu_hacks.store_menu_movement_data
bl   main_menu_hacks.get_menu_valid_options
str  r0,[sp,#0xC]

bl   $805030C
add  sp,#0x10
pop  {pc}

//=============================================================================================
// These hacks update the palette of certain entries instead of reprinting them.
// They also remove the sold item and only print the one at the bottom (if it exists)
//=============================================================================================
.sell_equipment_confirmed_printing_pressed_a:
push {lr}
mov  r0,sp
add  r0,#0x1C
bl   main_menu_hacks.printing_pressed_a_update_grey
pop  {pc}

.sell_confirmed_printing_pressed_a:
push {lr}
mov  r0,sp
add  r0,#0x14
bl   main_menu_hacks.printing_pressed_a_update_grey
pop  {pc}

//=============================================================================================
// These hacks update the palette of certain entries instead of reprinting them
//=============================================================================================
.psi_used:
push {r4,lr}
add  sp,#-4
mov  r4,r0
bl   main_menu_hacks.get_menu_valid_options
str  r0,[sp,#0]              //Get the valid options now
mov  r0,r4
bl   $8052864                //Do the PSI used routine...
mov  r0,r4
bl   main_menu_hacks.get_menu_valid_options
ldr  r1,[sp,#0]
eor  r0,r1                   //If the valid options changed, change
cmp  r0,#0                   //the assigned palette for those that changed
beq  +                       //and then set the arrangements to be updated
ldr  r1,=#0x201697A
bl   main_menu_hacks.change_psi_options
bl   main_menu_hacks.store_arrangements_buffer
+
add  sp,#4
pop  {r4,pc}

.buy_a:
push {lr}
add  sp,#-4
bl   .main
bl   main_menu_hacks.get_menu_valid_options
str  r0,[sp,#0]              //Get the valid options now
mov  r0,r4
bl   $8052F9C                //Do the confirming buying routine...
bl   main_menu_hacks.get_menu_valid_options
ldr  r1,[sp,#0]
eor  r0,r1                   //If the valid options changed, change
cmp  r0,#0                   //the assigned palette for those that changed
beq  +                       //and then set the arrangements to be updated
ldr  r1,=#0x2016992
bl   main_menu_hacks.change_shop_options
bl   main_menu_hacks.store_arrangements_buffer
+
add  sp,#4
pop  {pc}

.buy_lr:
push {lr}
add  sp,#-4
bl   .main
bl   main_menu_hacks.get_menu_valid_options
str  r0,[sp,#0]              //Get the valid options now
bl   main_menu_hacks.prepare_swap_char_buying
bl   main_menu_hacks.get_menu_valid_options
ldr  r1,[sp,#0]
eor  r0,r1                   //If the valid options changed, change
cmp  r0,#0                   //the assigned palette for those that changed
beq  +                       //and then set the arrangements to be updated
ldr  r1,=#0x2016992
bl   main_menu_hacks.change_shop_options
bl   main_menu_hacks.store_arrangements_buffer
+
add  sp,#4
pop  {pc}

.sell_after_buy_a:
push {r4,lr}
mov  r4,r5                   //Cover the -selling old equipment
bl   .buy_a                  //after buying new one- case
pop  {r4,pc}

//=============================================================================================
// This hack allows input reading only if the game's done printing.
// If it is done, then it saves the current position of the cursor in order to
// only remove what is needed without reprinting the entire menu
//=============================================================================================
.deposit_a:
push {lr}
bl   main_menu_hacks.check_if_printed
mov  r0,#0                   //Do the thing only IF we're done printing.
cmp  r1,#0                   //Prevents issues with arrangements not being there
bne  +
add  sp,#-0xC                //Prepare the item's index for the deposit-movement routine
bl   main_menu_hacks.store_menu_movement_data

bl   .main
mov  r0,r4                   //Normal stuff the game expects from us
bl   $804F1D8
add  sp,#0xC
+
pop  {pc}

//=============================================================================================
// This hack moves the items in the deposit menu around instead of reprinting them
//=============================================================================================
.deposit_printing_pressed_a:
push {lr}
mov  r0,sp
add  r0,#0x1C
bl   main_menu_hacks.new_inventory_deposit_swap_arrangement
bl   main_menu_hacks.store_arrangements_buffer
pop  {pc}

//=============================================================================================
// This hack allows input reading only if the game's done printing.
// If it is done, then it saves the current position of the cursor in order to
// only remove what is needed without reprinting the entire menu
// It also checks whether there is space in the character's inventory
//=============================================================================================
.withdraw_a:
push {lr}
add  sp,#-0xC
bl   main_menu_hacks.store_menu_movement_data

bl   main_menu_hacks.check_if_printed
cmp  r1,#0                   //Do the thing only IF we're done printing.
bne  .withdraw_a_end         //Prevents issues with arrangements not being there

ldr  r0,=#0x201A294          //Check if the inventory is full. If it is, then the game won't print again and we need to let it do its thing. We need to manually increment this, as the original devs forgot to do it.
ldrh r1,[r0,#0]
cmp  r1,#0x10
bge  +

add  r1,#1
strh r1,[r0,#0]
bl   .main
+

mov  r0,r5                   //Normal stuff the game expects from us
bl   $804F294

.withdraw_a_end:
add  sp,#0xC
pop  {pc}

//=============================================================================================
// This hack moves the items in the withdraw menu around instead of reprinting them
//=============================================================================================
.withdraw_printing_pressed_a:
push {lr}
mov  r0,sp
add  r0,#0x14
bl   main_menu_hacks.printing_pressed_a
cmp  r0,#1
bne  +                       //Store the arrangements buffer if it returned 1
bl   main_menu_hacks.store_arrangements_buffer
+
pop  {pc}



//=============================================================================================
// This set of hack tries to improve the performances of menus that may use most of the CPU
// in certain specific situations (Status and Equip).
//=============================================================================================
improve_performances_menus:

//=============================================================================================
// This hack prints "Weapon", "Body", "Head", "Other" and "Skills" in VRAM.
//=============================================================================================
.status_vram_equip_descriptors:
push {lr}
add  sp,#-4
str  r4,[sp,#0]
bl   $8047B9C                //Base code, orders printing "PP"

mov  r0,#0x52
bl   $80486A0                //Load up "Weapon"
str  r4,[sp,#0]
mov  r1,#9
mov  r2,#5
mov  r3,r5
bl   $8047B9C                //Order its printing

mov  r0,#0x54
bl   $80486A0                //Load up "Body"
str  r4,[sp,#0]
mov  r1,#9
mov  r2,#6
mov  r3,r5
bl   $8047B9C                //Order its printing

mov  r0,#0x53
bl   $80486A0                //Load up "Head"
str  r4,[sp,#0]
mov  r1,#9
mov  r2,#7
mov  r3,r5
bl   $8047B9C                //Order its printing

mov  r0,#0x55
bl   $80486A0                //Load up "Other"
str  r4,[sp,#0]
mov  r1,#9
mov  r2,#8
mov  r3,r5
bl   $8047B9C                //Order its printing

mov  r0,#0x59
bl   $80486A0                //Load up "Skills"
str  r4,[sp,#0]
mov  r1,#9
mov  r2,#9
mov  r3,r5
bl   $8047B9C                //Order its printing

add  sp,#4
pop  {pc}

//=============================================================================================
// This hack prints "Weapon", "Body", "Head" and "Other" in VRAM.
//=============================================================================================
.equipment_vram_equip_descriptors:
push {lr}
add  sp,#-4
mov  r4,#1
mov  r5,#1
neg  r5,r5

mov  r0,#0x52
bl   $80486A0                //Load up "Weapon"
str  r4,[sp,#0]
mov  r1,#0xB
mov  r2,#2
mov  r3,r5
bl   $8047B9C                //Order its printing

mov  r0,#0x54
bl   $80486A0                //Load up "Body"
str  r4,[sp,#0]
mov  r1,#0xB
mov  r2,#4
mov  r3,r5
bl   $8047B9C                //Order its printing

mov  r0,#0x53
bl   $80486A0                //Load up "Head"
str  r4,[sp,#0]
mov  r1,#0xB
mov  r2,#6
mov  r3,r5
bl   $8047B9C                //Order its printing

mov  r0,#0x55
bl   $80486A0                //Load up "Other"
str  r4,[sp,#0]
mov  r1,#0xB
mov  r2,#8
mov  r3,r5
bl   $8047B9C                //Order its printing

ldr  r0,=#0x201A51B
mov  r1,#0
add  sp,#4
pop  {pc}

//=============================================================================================
// Avoid reprinting stuff we don't need to when closing the equipment submenu
//=============================================================================================
.equip_avoid_left_reprint:
push {lr}
ldr  r0,=#0x201A51B
mov  r1,#4
strb r1,[r0,#0]              //Specify no reprinting for left column

bl   $8046D90                //Call printing

ldr  r0,=#0x201A51B
mov  r1,#0
strb r1,[r0,#0]              //Restore previous value
pop  {pc}



//=============================================================================================
// This set of hack removes the lag from the "Delete all saves" menu.
// To access it, press LOAD in the main menu with L + R + START + A held down
//=============================================================================================
fix_lag_delete_all:

//=============================================================================================
// This hack makes it so the "LV" icon has the same priority as the other OAM entries.
// Otherwise it could pop over the backgorund
//=============================================================================================
.change_level_priority:
mov  r6,#2
str  r6,[sp,#0]
mov  r6,#1                   //Set r6 to 1 because the rest of the function expects it to be 1
bx   lr

//=============================================================================================
// This hack makes it so BG1 (the VRAM BG) is 5 pixels lower.
// It makes it possible to match the original text.
//=============================================================================================
.change_bg1_coords:
ldr  r1,=#0x2016028
cmp  r0,#9
bne  +
ldrh r0,[r1,#0x1C]           //Move the Y axys by 5 pixels
mov  r0,#3
strh r0,[r1,#0x1C]
mov  r0,#9
+
cmp  r0,#8
bx   lr

//=============================================================================================
// This hack adds VRAM entries for the text in the "Delete all saves" menu.
// It also hides BG1
//=============================================================================================
.add_extra_vram:
push {lr}
add  sp,#-4

ldr  r0,=#0x2004100
ldrb r0,[r0,#0]
cmp  r0,#9
bne  +

ldr  r0,=#0x2016028
ldrh r1,[r0,#0xC]
mov  r2,#3
orr  r1,r2
strh r1,[r0,#0xC]            //Hide BG1 until we need to show it

mov  r5,#1
neg  r5,r5
mov  r4,#0xF                 //Generic text stuff

mov  r0,#0x1D                //"Delete all saves" text
bl   $80486A0
str  r4,[sp,#0]
mov  r1,#0x3
mov  r2,#4
mov  r3,r5
bl   $8047B9C                //Order printing

mov  r0,#0x21                //"Is that okay" text
bl   $80486A0
str  r4,[sp,#0]
mov  r1,#0x3
mov  r2,#5
mov  r3,r5
bl   $8047B9C                //Order printing

mov  r0,#0x03                //"Yes" text
bl   $80486A0
str  r4,[sp,#0]
mov  r1,#0x7
mov  r2,#6
mov  r3,r5
bl   $8047B9C                //Order printing

mov  r0,#0x04                //"No" text
bl   $80486A0
str  r4,[sp,#0]
mov  r1,#0xB
mov  r2,#6
mov  r3,r5
bl   $8047B9C                //Order printing

mov  r0,#9
+
add  sp,#4
pop  {pc}

//=============================================================================================
// This hack hides BG1 (the VRAM backgorund).
// Used when Yes or No has been pressed
//=============================================================================================
.hide_background:
push {r1-r2}
ldr  r0,=#0x2016028
ldrh r1,[r0,#0xC]
mov  r2,#3
orr  r1,r2
strh r1,[r0,#0xC]            //Hide back VRAM content in BG1

mov  r0,#0
pop  {r1-r2}
bx   lr

//=============================================================================================
// This hack changes the BG0 and the BG1 priority for the "Delete all saves" menu.
// BG1 (VRAM text) goes over BG0 (submenu window).
// The default code goes on to print some OAM entries, which are skipped
// in the "Delete all saves" menu.
//=============================================================================================
.change_background_priority_remove_oam:
push {lr}
ldr  r0,=#0x201A288
ldrb r0,[r0,#0]
cmp  r0,#0x10                //Is this the saving menu?
bne  +
ldr  r0,=#0x2004100
ldrb r0,[r0,#0]
cmp  r0,#9                   //Is this the "Delete all files" menu?
bne  +

ldrh r0,[r4,#0xA]
mov  r1,#1
orr  r0,r1                   //Change BG0 priority to 1
strh r0,[r4,#0xA]
ldrh r0,[r4,#0xC]
mov  r1,#4
neg  r1,r1
and  r0,r1                   //Change BG1 priority to 0. Bring forth the text written in VRAM
strh r0,[r4,#0xC]
pop  {r0}
ldr  r0,=#0x8045DE7
bx   r0                      //Sadly, we need to skip part of the routine and this is the best way that came to mind...

+
ldr  r0,=#0x41CC             //Default code
add  r4,r4,r0
pop  {pc}

//=============================================================================================
// This hack removes the cursor while the "Delete all files" menu is loading up
//=============================================================================================
.remove_starting_cursor:
push {lr}
add  sp,#-4
ldr  r3,=#0x201A288
ldrb r3,[r3,#0]
cmp  r3,#0x10
bne  +
ldr  r3,=#0x2004100
ldrb r3,[r3,#0]
cmp  r3,#0x9
bne  +
ldr  r3,=#0x201A202          //0x2016028 + 0x41C6
ldrb r3,[r3,#0]
cmp  r3,#0x4
bne  +
b    .remove_starting_cursor_end
+

ldr  r3,[sp,#8]
str  r3,[sp,#0]
mov  r3,#0x20                //Function parameters
bl   $8046A28

.remove_starting_cursor_end:
add  sp,#4
pop  {pc}

//=============================================================================================
// This hack makes it so the window is loaded up for the "Delete all files" menu only after
// the fadein is over
//=============================================================================================
.hack:
push {lr}
push {r0-r3}
ldr  r2,=#0x2016028
ldr  r0,=#0x41DA
add  r3,r2,r0
mov  r1,#0x12
sub  r1,r0,r1
add  r0,r1,r2                //Load the submenu we're in. 5 is a sub-submenu
ldrh r1,[r0,#4]              //Load the subscreen we're in. 0x1D is the "Delete all saves" one.
cmp  r1,#0x1D
bne  +
ldrh r1,[r0,#0]
cmp  r1,#5
bne  +
ldrb r0,[r3,#0]              //Make it so this is properly added only once we can get the input
cmp  r0,#4
bne  +
mov  r1,#0x86
add  r1,r1,r3
ldrb r1,[r1,#0]
cmp  r1,#0x10                //Is this the file selection menu?
bne  +
mov  r1,#0x16
add  r1,r1,r3
ldrh r0,[r1,#0]
cmp  r0,#0x16                //Have a 6 frames windows for the fadein to properly end
bne  +

mov  r0,#5
strb r0,[r3,#0]

+

pop  {r0-r3}
ldrb r0,[r0,#0]              //Clobbered code
lsl  r0,r0,#0x1F
pop  {pc}
