//===========================================================================================
//===========================================================================================
// byuu wrote this code. It takes the 8-bit script from the ROM and converts it to 16-bit
// in a custom area of RAM.
//
// Control codes have to be handled in a special way, due to issues with having each letter
// be a byte now. byuu devised this system:
//
//   Normally, control codes are FFXX, but we're now storing them as F0 through FF, with 
//   the lower nybble dictating how long the following arguments string is * 2.
//
//     #0xf0 - #0xff = control code
//     format:
//     <%1111 llll> l = length * 2
//     #0xff is a special case for the block end command,
//     it will write #0xffff and return from this routine
//     examples:
//     $ff = $ffff
//     $f0,$01 = $ff01
//     $f1,$e1,$0123 = $ffe1 $0123
//
// Going into this routine, r4 has the RAM write offset, and r5 has the ROM read offset.
//===========================================================================================
//===========================================================================================

main_script_hacks:

define space 0x40
define menuspaceyes 0xE8
define menuspaceno 0xE9
define nowidth 0xF0EB

.script_convert:
cmp  r0,r1
bne .load_script
bl  $08021b5c

.load_script:
lsl  r5,r5,#4          // Shift one nybble to the left. This will create a negative number
                       // if we're reading from ROM.
bmi  .dorom            // Branch if we're reading from the ROM
lsr  r5,r5,#4          // Otherwise, don't do anything
  
b    .jeffhack         // Perform jeffman's menu cursor coord hack
bl   $08021b1c         // Get outta here!

//-------------------------------------------------------------------------------------------

.dorom:                // We're reading from the ROM if we're executing this code
lsr  r5,r5,#4          // Fix r5

push {r1}              // adding this code in to fix the 4+ option special menus
ldr  r0,=#0x2014304    // this value will tell if we're doing a special menu or not
mov  r1,#0x0
strb r1,[r0,#0]        // set the flag to 0 by default
pop  {r1}

push {r1-r4}           // now back to byuu's code
ldr  r4,=#0x2038000    // $2038000 - $203ffff is unused and will be our custom area of RAM
push {r4}

// ------------
ldrb r0,[r5,#0]        // Jeff hack - check for the [FE XX XX] custom hot springs lookup,
bl   .decode_byte
cmp  r0,#0xFE          // change the ROM pointer if necessary
bne  +
push {r0-r3}
ldrb r0,[r5,#1]        // load the line number
add  r5,#1
bl   .decode_byte
sub  r5,#1
push {r0}
ldrb r0,[r5,#2]
add  r5,#2
bl   .decode_byte
sub  r5,#1
mov  r1,r0
pop  {r0}

lsl  r1,r1,#8
add  r1,r0,r1
mov  r0,#13            // block 13 in r0, line # in r1
ldr  r2,=#0x936A6F8
lsl  r0,r0,#3          // address of pointer = 936A6F8 + (blocknum * 8)
ldr  r0,[r2,r0]
add  r2,r0,r2
sub  r2,#4
lsl  r1,r1,#1          // address of sub-pointer = r2 + (linenum * 2)
ldrh r1,[r2,r1]
mov  r3,#0xFF
lsl  r3,r3,#8
add  r3,#0xFF
-
add  r2,#2             // now we gotta loop until 0xFFFF is encountered
ldrh r0,[r2,#0]
cmp  r0,r3
bne  -
add  r5,r2,r1          // now we have a ROM pointer
pop  {r0-r3}
//----------

+

.load_loop:
ldrb r0,[r5,#0]        // load byte from ROM
bl   .decode_byte      // decode it
add  r5,#1

cmp  r0,#0xEF          // test if value is control code
beq  .custom_cc
cmp  r0,#0xF0
bge  .control_code

strh r0,[r4,#0x0]      // if not, convert 8-bit char and store 16-bit result
add  r4,#2
b    .load_loop

//-------------------------------------------------------------------------------------------

.control_code:
cmp  r0,#0xff          // test for [END]
beq  .end_load

//mov  r1,r0             // r1 = r0 & 0x0F
//mov  r0,#0xF
//and  r1,r0
lsl  r1,r0,#0x1C
lsr  r1,r1,#0x1C       // simplified

mov  r0,#0xFF          // write control code flag
strb r0,[r4,#1]

ldrb r0,[r5,#0]        // copy next byte directly (0xnn -> 0xffnn)
bl   .decode_byte      // decode byte again

add  r5,#1
strb r0,[r4,#0]
add  r4,#2

.control_code_loop:
tst  r1,r1             // test if end of control code string
beq  .load_loop
sub  r1,#1

ldrb r0,[r5,#0]        // copy word value from ROM to RAM, and loop
bl   .decode_byte      // decode first byte of word argument
strb r0,[r4,#0]

add  r5,#1
ldrb r0,[r5,#0]        // read next byte of word argument
bl   .decode_byte      // decode it
strb r0,[r4,#1]
add  r5,#1
add  r4,#2
b    .control_code_loop

.end_load:
strb r0,[r4,#0]        // write end flag (r0 always equals #0xFF here)
strb r0,[r4,#1]

pop {r5}               // set read offset to $02038000
pop {r1-r4}            // restore various registers

//-------------------------------------------------------------------------------------------
// This is Jeff's menu coordinate hack. Possible space characters: 40, A5, A6
// Here's the plan, and it can be accomplished without making a menu choice terminator char.
// Check until [06 FF XX XX] is encountered.
// If not encountered, exit the subroutine.
// If encountered, loop until a non-space character is encountered.
// Begin accumulating the letter widths until A5 or A6 is encountered.
// Add the width of A5 or A6 to the width accumulator.
// Store the width accumulator to 201AB3C.
//
// r5 has the address to the already-expanded text.
//-------------------------------------------------------------------------------------------

.jeffhack:

push {r0,r2-r4}
mov  r3,#0             // loop counter
ldr  r2,=#0xFF06       // we're looking for the FF06 control code

.menucheck:
ldrh r0,[r5,r3]
cmp  r0,r1
beq  .endall
add  r3,#2
cmp  r0,r2
bne  .menucheck
add  r3,#2

.choicecheck:
ldrh r0,[r5,r3]
add  r3,#2
cmp  r0,#{space}
beq  .addwidths
cmp  r0,#{menuspaceyes}
beq  .addwidths
cmp  r0,#{menuspaceno}
beq  .addwidths
b    .choicecheck

.addwidths:
mov  r2,#0
mov  r4,#8
ldr  r4,=#0x8D1CE78

.addwidths_loop:
ldrh r0,[r5,r3]
cmp  r0,#{menuspaceyes}
beq  .endwidths
cmp  r0,#{menuspaceno}
beq  .endwidths
add  r3,#2
ldrb r0,[r4,r0]
add  r2,r2,r0
b    .addwidths_loop

.endwidths:
ldrb r0,[r4,r0]
add  r2,r2,r0
ldr  r4,=#0x201AB3C    // check this later
strb r2,[r4,#0x0]
  
.endall:
pop {r0,r2-r4}
bl $08021B1C

//-------------------------------------------------------------------------------------------
// This is Mato's custom control code hack. The format of our custom control codes is
// [EF 00]. When encountered, the game will look into the custom item info table we've
// inserted into the ROM and replace [EF 00] with the proper string. This is used mainly
// for messages where you find an item, so we can use "a/an/the/some" and stuff like that.
//-------------------------------------------------------------------------------------------

.custom_cc:
push {r1-r2}

ldrb r0,[r5,#0]                   // load the argument byte
bl   .decode_byte

mov  r2,r0                        // r2 will be an offset into the extra item data slot

// ----------------
lsr  r0,r0,#7                     // Jeff hack - if bit 0x80 of the arg byte is set,
cmp  r0,#0                        // use 201AAF8 instead for the address
beq  +
ldr  r0,=#0x201AAF8
sub  r2,#0x80                     // re-adjust r2 by unsetting the 0x80 flag
lsr  r1,r2,#5                     // allow for more CCs based on the stack position
lsl  r1,r1,#2
add  r0,r0,r1
mov  r1,#0x1F
and  r2,r1                        // re-adjust
b    .custom_cc_adrcheck
+
ldr  r0,=#0x2014324               // this is where the current item # will be saved by another hack
.custom_cc_adrcheck:
// ----------------

cmp  r2,#0x10
blt  +
b    .custom_cc_item
+

.custom_cc_enemy:
cmp  r2,#2
bge  +
mov  r2,#2                        //Make it so this is a valid enemy article EF
+
ldr  r1,=#0x201AAF8
cmp  r0,r1                        //Make sure enemies don't look at the item address, but only look at the stack
bge  +
mov  r0,r1
+
sub  r2,r2,#2
ldrh r0,[r0,#0]
mov  r1,r0
lsl  r0,r0,#3                     // offset = enemy ID * 8 bytes
ldr  r1,=#{enemy_extras_address}  // this is the base address of our extra enemy data table in ROM
b    .custom_cc_end

.custom_cc_item:
sub  r2,#0x10
ldrh r0,[r0,#0]                   // load the current item #
mov r1,#9
mul r0,r1                         // offset = item ID * 9 bytes
ldr  r1,=#{item_extras_address}   // this is the base address of our extra item data table in ROM

.custom_cc_end:
add  r0,r0,r1                     // r0 now has the proper address of the current entry's data slot
ldrb r0,[r0,r2]                   // load the proper line # to use from custom_text.bin
mov  r1,#40
mul  r0,r1                        // calculate the offset into custom_text.bin
ldr  r1,=#{custom_text_address}   // load r1 with the base address of our custom text array in ROM
add  r0,r0,r1                     // r0 now has the address of the string we want
mov  r1,r4

bl   custom_strcopy               // r0 returns from this with the # of bytes copied
add  r4,r4,r0
add  r5,#1

pop  {r1-r2}
b    .load_loop

//===========================================================================================
// This is Jeff's fix for the PK [FAVORITETHING] stuff. The game had a couple hard-coded
// things that messed up with our English hack, but this code here fixes all that.
// This appears to affect the main menus and battle stuff too. Lucky us!
//===========================================================================================

.pk_fav_fix:
lsl  r0,r7,#1
add  r0,r0,r2
ldrh r0,[r0,#0]
strh r0,[r1,#4]
mov  r0,#0x40
strh r0,[r1,#2]
bx   lr

//===========================================================================================
// These code snippets save the value of the currently active item to a halfword in RAM.
// We need to have this value easily available when we do our custom control code stuff
// later on.
//===========================================================================================

.current_item_save1:
mov  r3,r1
ldr  r0,=#0x2014324
strh r1,[r0,#0]
bx   lr

//-------------------------------------------------------------------------------------------

.current_item_save2:
cmp  r0,#0
beq  +

push {r6}
ldr  r6,=#0x2014324
strh r0,[r6,#0]
pop  {r6}

+
str  r0,[r2,#0]
add  r0,r5,#1
bx   lr



//===========================================================================================
// This is Paul's chapter end 8-bit script conversion code. It converts the 8-bit text in
// the ROM to the 16-bit format the game expects.  Code to branch from is located at 08027F68.
//
// r0 contains the read location
// r6 should contain the read location we started with, except in RAM
// r0 should contain the next byte on return
//
// Text wil be unpacked at 2038000 temporarily. This area is supposedly unused by the game.
//
// Note that this hack actually applies to much more than just chapter end text. It affects
// a whole bunch of Block 0 text.
//===========================================================================================

.chapter_end_convert:

// ------
// Jeff hack - store r6, which is the current line number of Block 0, to 203FFFA
//           -> it gets read later by extra_hacks.scrolly_text_fix
//           - store $0000 to 203FFF8 (block number)
push {r0,r6}
ldr  r0,=#0x203FFF8
strh r6,[r0,#2]
mov  r6,#0
strh r6,[r0,#0]
pop  {r0,r6}
// ------

lsl  r0,r0,#4                // Shift one nybble to the left. This will create a negative number if we're reading from ROM.
bmi  +                       // Are we copying from the ROM? If so, we need to expand the text to 16-bit 
lsr  r0,r0,#4                // Shift the address back where it belongs 
pop  {r4-r6,pc}              // If we haven't jumped, then we're already working from RAM, so return now

//--------------------------------------------------------------------------------------

+ 
push {r0-r1}              // adding this code in to fix the 4+ option special menus
ldr  r0,=#0x2014304       // this value will tell if we're doing a special menu or not
mov  r1,#0x0
strb r1,[r0,#0]           // set the flag to 0 by default
pop  {r0-r1}              // now back to paul's regular code


lsr  r0,r0,#4                // Shift the address back where it belongs 
push {r1-r3,r7}              // save these for later
ldr  r1,=#0x2038000

.chap_end_loop:
push {r0,r5}
mov  r5,r0
ldrb r3,[r0,#0]              // Load r3 with our next byte
mov  r0,r3
bl   .decode_byte            // decode it
mov  r3,r0
pop  {r0,r5}

cmp  r3,#0xEF                // is this a custom control code?
beq  .chap_end_custom_cc
 
cmp  r3,#0xF0               // Is this a control code? 
bcs  .chap_end_cc            // If so, do a 16-bit copy. 
strh r3,[r1,#0]              // Store it at r1 
add  r1,r1,#2                // Increment our destination by 2 
add  r0,r0,#1                // Increment our source by 1 
b    .chap_end_loop          // Loop for the next byte 

//--------------------------------------------------------------------------------------

.chap_end_cc:
cmp  r3,#0xFF
beq  .chap_end_end           // Get out of here if it's a terminator  

sub  r3,#0xF0
mov  r6,#0xFF
strb r6,[r1,#1]
ldrb r6,[r0,#1]              // Load the control code command
push {r0,r5}
add  r5,r0,#1
mov  r0,r6
bl   .decode_byte            // decode it
mov  r6,r0
pop  {r0,r5}

strb r6,[r1,#0]              // Store it
add  r0,r0,#2                // Add two to the address we're supposed to read from 
add  r1,r1,#2                // Add two to the destination 

-
cmp  r3,#0x0                 // Does r3 == 0?
beq  .chap_end_loop          // Done with copy, get the next byte  
ldrb r6,[r0,#1]
push {r0,r5}
add  r5,r0,#1
mov  r0,r6
bl   .decode_byte            // decode it
mov  r6,r0
pop  {r0,r5}
lsl  r6,r6,#8

ldrb r4,[r0,#0]
push {r0,r5}
mov  r5,r0
mov  r0,r4
bl   .decode_byte            // decode it
mov  r4,r0
pop  {r0,r5}

add  r6,r6,r4                // r0 should be loaded with the next argument 
strh r6,[r1,#0]              // Store the destination 
sub  r3,#1                   // Subtract one from remaining arguments 
add  r1,#2                   // Add two to the destination 
add  r0,#2                   // Add two to the address we're supposed to read from 
b -                          // Loop for more data 

//--------------------------------------------------------------------------------------

.chap_end_end:
mov  r3,#1
neg  r3,r3
strh r3,[r1,#0]              // Store FFFF into r1
ldr  r0,=#0x2038000

pop  {r1-r3,r7}              // restore registers to previous values
pop  {r4-r6,pc}              // And return 

//--------------------------------------------------------------------------------------
// There are no real custom CCs needed in chapter end text, but most of the "you got item"
// script lines are in Block 0, so that's why this is here.
//--------------------------------------------------------------------------------------

.chap_end_custom_cc:
push {r0}
push {r1-r2,r5}

add  r5,r0,#1
ldrb r0,[r0,#1]                   // load the argument byte
bl   .decode_byte

mov  r2,r0                        // r2 will be an offset into the extra item data slot

// ----------------
lsr  r0,r0,#7                     // Jeff hack - if bit 0x80 of the arg byte is set,
cmp  r0,#0                        // use 201AAF8 instead for the address
beq  +
ldr  r0,=#0x201AAF8
sub  r2,#0x80                     // re-adjust r2 by unsetting the 0x80 flag
lsr  r1,r2,#5                     // allow for more CCs based on the stack position
lsl  r1,r1,#2
add  r0,r0,r1
mov  r1,#0x1F
and  r2,r1                        // re-adjust
b    .chap_end_custom_cc_adrcheck
+
ldr  r0,=#0x2014324               // this is where the current item # will be saved by another hack
.chap_end_custom_cc_adrcheck:
// ----------------

cmp  r2,#0x10
blt  +
b    .chap_end_custom_cc_item
+

.chap_end_custom_cc_enemy:
cmp  r2,#2
bge  +
mov  r2,#2                        //Make it so this is a valid enemy article EF
+
ldr  r1,=#0x201AAF8
cmp  r0,r1                        //Make sure enemies don't look at the item address, but only look at the stack
bge  +
mov  r0,r1
+
sub  r2,r2,#2
ldrh r0,[r0,#0]
mov  r1,r0
lsl  r0,r0,#3                     // offset = enemy ID * 8 bytes
ldr  r1,=#{enemy_extras_address}  // this is the base address of our extra enemy data table in ROM
b    .chap_end_custom_cc_end

.chap_end_custom_cc_item:
sub  r2,#0x10
ldrh r0,[r0,#0]                   // load the current item #
mov r1,#9
mul r0,r1                         // offset = item ID * 9 bytes
ldr  r1,=#{item_extras_address}   // this is the base address of our extra item data table in ROM

.chap_end_custom_cc_end:
add  r0,r0,r1                     // r0 now has the proper address of the current entry's data slot
ldrb r0,[r0,r2]                   // load the proper line # to use from custom_text.bin
mov  r1,#40
mul  r0,r1                        // calculate the offset into custom_text.bin
ldr  r1,=#{custom_text_address}   // load r1 with the base address of our custom text array in ROM
add  r0,r0,r1                     // r0 now has the address of the string we want

pop  {r1-r2,r5}
bl   custom_strcopy               // r0 gets the # of bytes copied as the return value
add  r1,r1,r0

pop  {r0}
add  r0,#2
b    .chap_end_loop

//===========================================================================================
// This makes the main script routine switch between only two glyph buffer structs.
// This lets us use as many letters as we want, rather than the limited # of the original
// game. It messes up the debug room menus, though.
//===========================================================================================

.move_to_next_glyph:
push {lr}
ldr  r1,=#0x2014304        // load the flag to tell if this is a 4+ menu option or not
ldrb r1,[r1,#0]
mov  r3,#1
cmp  r1,r3
bne  +                     // if equal, we need to manually copy to the screen, else skip

push {r0-r2}
mov  r1,r8
mov  r0,r8
add  r0,#8                 // r0 = start of current glyph in current struct
ldr  r1,[r1,#0]            // load r1 with the target address to display to
mov  r2,#0x60              // # of bytes to copy
bl   $8001A14              // perform the copy

mov  r1,r8
mov  r0,r8
add  r0,#0x68              // r0 = second half of glyph
ldr  r1,[r1,#0]
mov  r2,#0x80
lsl  r2,r2,#3
add  r1,r1,r2              // r1 = second part of target address
mov  r2,#0x60
bl   $8001A14              // perform the second copy
pop  {r0-r2}

+
ldr  r3,=#0x201C460
mov  r1,r8
cmp  r1,r3
bne  +
add  r3,#0xCC
+
mov  r8,r3
mov  r0,#0xC8
add  r6,r3,r0
pop  {pc}

//===========================================================================================
// If the text speed is set to Fast, some problems might show up if an odd # of letters
// is to be dealt with. These two little hacks add an extra blank letter (0xA9) to even
// things out if necessary.
//===========================================================================================

.insert_extra_letter1:
ldr  r2,=#0x2014300        // store the current letter address in RAM
str  r0,[r2,#0]

ldr  r2,=#0xFFF            // clobbered code
mov  r1,r2
bx   lr

//-------------------------------------------------------------------------------------------

.insert_extra_letter2:
push {r0-r4}
ldr  r4,=#0x2005C08        // skip all this if it's not Fast text speed
ldrb r4,[r4,#0]
lsr  r4,r4,#6              // r4 now has speed, 0 = fast, 1 = medium, 2 = slow
cmp  r4,#0                 // if it's not 0, skip all this
bne  +

ldr  r4,=#0x2027CB3
ldrb r0,[r4,#0]            // load the # of passes that are scheduled
cmp  r0,#1                 // if it's not 1, then skip all this extra junk
bne  +

mov  r1,#2
strb r1,[r4,#0]            // set it so we have 2 letters this cycle now too

ldr  r3,=#0x2014300
ldr  r3,[r3,#0]
ldr  r1,=#{nowidth}        // a space character
str  r1,[r3,#4]            // store the data

mov  r1,r8                 // increment the # of letters we've added
cmp  r1,#1
ble  +
add  r1,#1                 // don't increment if we're starting a new line I guess
mov  r8,r1

+
pop  {r0-r4}
ldr  r1,=#0x1444           // clobbered code
add  r0,r6,r1
bx   lr

//===========================================================================================

.change_clear_amount:
push {lr}
ldr  r1,=#0x400
bl   $8001ACC
pop  {r0}
add  r0,#2
bx   r0

//===========================================================================================
// This hack sets a flag whenever the line being processed is actually part of a special
// 4+ menu option line, like those used in the debug menu. Because the game handles the
// displaying of these lines differently, some special stuff has to be done to make these
// lines display fully. The default value is 0, which is set during byuu's 8-bit code hack.
//===========================================================================================

.set_specialmenuflag:
ldr  r0,=#0x2014304    // this value will tell if we're doing a special menu or not
mov  r1,#1
strb r1,[r0,#0]        // set the flag to 1

push {r0-r3}                // all this code here clears the bottom text line on the screen
ldr  r0,=#0x7777
ldr  r1,=#0x600C820
ldr  r2,=#0x1C0
push {r0}
mov  r0,sp
mov  r3,#1
lsl  r3,r3,#24
orr  r2,r3
swi  #0x0B
pop  {r0}

ldr  r0,=#0x7777
ldr  r1,=#0x600CC20
ldr  r2,=#0x1C0
push {r0}
mov  r0,sp
mov  r3,#1
lsl  r3,r3,#24
orr  r2,r3
swi  #0x0B
pop  {r0}
pop  {r0-r3}

mov  r0,r4             // clobbered code
mov  r1,#0
bx   lr

//===========================================================================================
// This hack fixes [FAVFOOD], but also affects [HINAWA], [FAVTHING] and [PLAYERNAME].
//===========================================================================================

.favfood_fix:
push {lr}
mov  r0,r1
mov  r2,#16        // default length
bl   check_name
cmp  r0,#0
beq  +
mov  r2,r0
+
mov  r0,r5         // clobbered code
pop  {pc}

//===========================================================================================
// This hack saves data used for optimizing character printing
//===========================================================================================

define line_printing_data $203FF98

.save_data_optimized_printing:
ldrh r2,[r5,#2]    //Load the current height
ldrh r5,[r5,#0]
add  r0,r0,r5      //Default code, calculated the current width for printing
ldr  r1,=#{line_printing_data}
str  r4,[r1,#4]
lsl  r2,r2,#8
orr  r2,r0
strh r2,[r1,#2]    //Store both width and height
ldrh r2,[r1,#0]    //Store letter counter
add  r2,#1
strh r2,[r1,#0]    //Increment the counter by 1
bx   lr

//===========================================================================================
// This hack is an optimized version of the normal overworld search for printing characters
// In particular, it finds the correct line to print faster for special menus...
// For the other type of lines, it instantly loads where the game is in terms of line width
// and address, skipping a good amount of useless checks that really slowed the overworld
// printing process
//===========================================================================================

.optimized_character_search_overworld:
push {lr}
add  r6,r2,r1      //Default code
add  sp,#-8

ldr  r1,=#0x2014304
ldrb r1,[r1,#0]    //This is 1 if we're in a special menu. If we are, skip this...
cmp  r1,#1
bne  +
b    .optimized_character_search_overworld_special_menu
+

ldr  r1,[r4,#4]
lsl  r0,r1,#0xE
cmp  r0,#0         //Is this a new line? If it is, it will be 0 here
bge  .optimized_character_search_overworld_new_line
mov  r1,#4         //Check if there is a new line in the second line
lsl  r1,r1,#8
sub  r1,r1,#4
add  r4,r4,r1
ldr  r1,[r4,#4]
lsl  r0,r1,#0x14   //If this is 0, this bottom line is entirely empty
cmp  r0,#0
beq  .optimized_character_search_overworld_not_new_line
lsl  r0,r1,#0xE
cmp  r0,#0         //Do we need to print this line?
blt  .optimized_character_search_overworld_not_new_line

.optimized_character_search_overworld_new_line:
ldr  r1,=#{line_printing_data}
mov  r0,#0
str  r0,[r1,#0]    //Set width and current letter to 0
str  r0,[r1,#4]    //Set last used address to 0
b    .optimized_character_search_overworld_end

.optimized_character_search_overworld_not_new_line:
ldr  r1,=#{line_printing_data}
ldr  r4,[r1,#4]
add  r4,#4         //Get the next letter
ldrh r5,[r1,#2]    //Get the current width + height
ldrh r3,[r1,#0]    //Get the current number of printed letters

//In r4 we have the first printable character, we now need to prepare some things to
//match what the game expects
mov  r2,r9
sub  r2,r2,#4
lsl  r0,r5,#0x18
lsr  r0,r0,#0x18
strh r0,[r2,#0]    //Save the current width of the line
lsr  r0,r5,#8
strh r0,[r2,#2]    //Save the current height of the line
ldr  r2,=#0x322A
add  r0,r7,r2
ldrb r2,[r0,#0]
mov  r1,#1
orr  r2,r1
strb r2,[r0,#0]
add  r0,#2
sub  r1,r4,#4
str  r1,[r0,#0]
mov  r1,#1
and  r1,r3         //If we're in an odd position, move the buffer to the next one
cmp  r1,#0
bne  +
mov  r1,r8
sub  r1,#1         //We prepare the swap
mov  r8,r1
+
bl   .move_to_next_glyph
b    .optimized_character_search_overworld_end

//Faster line loading for the special menus
.optimized_character_search_overworld_special_menu:
str  r4,[sp,#0]
mov  r0,#0xCC
lsl  r0,r0,#4
add  r0,r4,r0
str  r0,[sp,#4]    //Save where we'll end
add  r4,#4         //The first one is empty, it makes the game print 0xC from the left

.optimized_character_search_overworld_fast_search_loop:
ldr  r0,[r4,#0]
lsl  r0,r0,#0x14
cmp  r0,#0
bne  +

ldr  r4,[sp,#0]    //If we found a 0, go forward a bit
mov  r0,#4
lsl  r0,r0,#8
add  r4,r4,r0      //0xFF letters per line
sub  r0,r4,#4
str  r0,[sp,#0]    //Move to the next line if we find 0
ldr  r1,[sp,#4]
cmp  r4,r1         //Check if we're at the end of the buffer
blt  .optimized_character_search_overworld_fast_search_loop
sub  r4,r1,#4
b    .optimized_character_search_overworld_end
+

ldr  r0,[r4,#0]
lsl  r0,r0,#0xE
cmp  r0,#0         //Do we need to print this line?
bge  +

add  r4,#4
ldr  r1,[sp,#4]
cmp  r4,r1         //Check if we're at the end of the buffer
blt  .optimized_character_search_overworld_fast_search_loop
sub  r4,r1,#4
b    .optimized_character_search_overworld_end
+

//We found something we need to print in this line! Print away with the normal routine!
//We'll make part of the loading process much faster...
ldr  r4,[sp,#0]

.optimized_character_search_overworld_end:
add  sp,#8
pop  {pc}

//============================================================================================
// This section of code stores the letter from the font's data to the stack.
// Main font version. Returns if there is data to print or not.
// r0 is the letter. r1 is the stack pointer
//============================================================================================

.fast_prepare_main_font:
ldr  r2,=#{main_font}     // we already know we're loading main font
lsl  r0,r0,#5
add  r0,r2,r0             // get the address
mov  r5,r0
mov  r1,sp
mov  r2,#8
swi  #0xB                 // CpuSet for 0x10 bytes
mov  r0,r5
add  r0,#0x10
add  r1,sp,#0x18
mov  r2,#8
swi  #0xB                 // CpuSet for 0x10 bytes
bx   lr

//===========================================================================================
// These hacks give proper text positioning to scrolling/notebook text
//===========================================================================================

.block0_text_fix1:
.flyover_fix1:
push {r4-r5,lr}
mov  r4,r2
sub  r5,r1,r0
mov  r0,r5
mov  r1,#4
bl   $8002FC0
mov  r5,r0
mov  r1,#0x32
bl   $8002FD4
lsl  r1,r0,#1
add  r1,r1,r0
lsl  r1,r1,#2
strh r1,[r4,#0]
mov  r0,r5
mov  r1,#0x32
bl   $8002FC0
ldr  r1,=#0x201433E
ldrb r1,[r1,#0]              //Position properly on the Y level by adding where we are
add  r0,r0,r1
ldr  r1,=#0x2016028
ldr  r2,=#0x11C89
add  r1,r1,r2
ldrb r1,[r1,#0]
mul  r0,r1
strh r0,[r4,#2]
pop  {r4-r5}
pop  {r0}
bx   r0


.flyover_fix2:
lsl  r0,r0,#0x10
lsr  r0,r0,#0x10
lsl  r1,r1,#0x10
lsr  r1,r1,#0x10
mov  r2,#0x32
mul  r2,r1
add  r0,r0,r2
lsl  r0,r0,#2
ldr  r1,=#0x201E9D0
add  r0,r0,r1
bx   lr


.block0_text_fix2:
lsl  r0,r0,#0x10
lsr  r0,r0,#0x10
lsl  r1,r1,#0x10
lsr  r1,r1,#0x10
ldr  r2,=#0x201433C
ldrh r3,[r2,#0]              //Here we store how much the base offset is if it starts at 0
cmp  r3,#0
bne  +
strh r1,[r2,#0]
+
ldrh r2,[r2,#0]              //Subtract the base offset from our inside Y value
sub  r1,r1,r2
mov  r2,#0x32
mul  r2,r1
add  r0,r0,r2
lsl  r0,r0,#2
ldr  r1,=#0x201E9D0
add  r0,r0,r1
bx   lr

.prepare_info_zone:
push {lr}
mov  r6,r0
ldr  r0,=#0x201433C
mov  r1,#0
str  r1,[r0,#0]
mov  r1,#0x88
pop  {pc}

//===========================================================================================
// This hack makes it so notebook/stinkbug's memory can be printed properly
//===========================================================================================

.improve_notebook_printing:
push {r5-r7,lr}
ldr  r0,=#0x201B7A0
ldr  r1,=#0xC1E8
add  r1,r0,r1
ldr  r6,[r1,#0]
ldrb r2,[r6,#9]
ldr  r5,=#0x201433C
mov  r1,#0
strh r1,[r5,#0]                        //Setup the current base height to 0
add  r5,#2                             //Address for our printing info zone
cmp  r1,r2
bcc  +                                 //Did a new request to print come?
ldrb r2,[r5,#1]                        //If it didn't, check if we must still print stuff
cmp  r2,#0
bne  .improve_notebook_printing_frame

//Do clobbered code if we don't have to print
bl    .improve_notebook_printing_second_part
b     .improve_notebook_printing_end

+
ldr  r1,=#0x2018CB8                    //Block default behaviour that insta-prints the first page
mov  r3,#0
strh r3,[r1,#0]

bl   .swap_graphics_buffer_notebook    //Change the buffer for the graphics

ldrb r1,[r5,#1]
cmp  r1,#0
beq  +
push {r0,r2}                           //Setup for a new printing request...
ldr  r0,=#0x2016078                    //Make it so the arrangements are clear
mov  r1,#0x80                          //Only if we weren't done printing
lsl  r1,r1,#4
bl   $80019DC
bl   .swap_graphics_buffer_notebook    //Change the buffer for the graphics back, it means the previous one wasn't printed
pop  {r0,r2}
+

mov  r1,#2                             //Setup our zone that contains info on where to print stuff
strb r1,[r5,#0]                        //and where we're at
strb r2,[r5,#1]

.improve_notebook_printing_frame:
cmp  r2,#2                             //We print a maximum of two lines per frame (100 characters of the 133 maximum)
ble  +
mov  r2,#2
+
strb r2,[r6,#9]                        //Store the number of lines we'll print
ldrb r1,[r5,#0]
sub  r1,#2
mov  r2,#0x6C
mul  r1,r2
mov  r2,#0x6C
add  r4,r1,r2
ldr  r6,[r6,#0]
ldr  r2,=#0x2014340
add  r1,r1,r2
add  r2,r2,r4
ldr  r7,[r6,#0]
ldr  r4,[r6,#0x10]
str  r1,[r6,#0]                        //Store where to look at into the text
str  r2,[r6,#0x10]                     //Store where to look at into the text
bl   $80096EC
bl   .improve_notebook_printing_second_part
str  r7,[r6,#0]                        //Restore the old info
str  r4,[r6,#0x10]                     //Restore the old info
ldrb r2,[r5,#0]                        //Update the printing info by adding 2 to the Y coordinate
add  r2,#2
strb r2,[r5,#0]
ldrb r2,[r5,#1]                        //Update the printing info by subtracting 2 from the number of lines to print
sub  r2,#2
cmp  r2,#0
bge  +
mov  r2,#0
+
strb r2,[r5,#1]

.improve_notebook_printing_end:
pop  {r5-r7,pc}

.improve_notebook_printing_second_part:
push {r7,lr}
ldr  r7,=#0x2016028                    //Clobbered code
ldr  r1,=#0x11C8C
add  r0,r7,r1
sub  r1,r0,#1
ldrb r0,[r0,#0]
strb r0,[r1,#0]
lsl  r0,r0,#0x18
cmp  r0,#0
beq  +
ldr  r0,=#0x5778
add  r4,r7,r0
mov  r0,r4
bl   $8009828
mov  r0,r4
bl   $8009A48
+
pop  {r7,pc}

//===========================================================================================
// This hack makes it so the notebook/stinkbug's graphic buffer is swapped
//===========================================================================================

.swap_graphics_buffer_notebook:
push {r2}
ldr  r1,=#0x201B3D8          //Address for the graphics. Swap between two slots
ldrb r3,[r1,#1]              //in order to avoid having graphical issues...
mov  r2,#0x70                //(Without this, there would be 1 frame without some part of the text if we had > 2 lines)
strb r2,[r1,#1]
cmp  r3,r2
bgt  +
mov  r2,#0xB0
strb r2,[r1,#1]
+
pop  {r2}
bx   lr

//===========================================================================================
// This hack makes it so the notebook/stinkbug's memory arrangements are cleared only if we're done
//===========================================================================================

.remove_tiles_cleaning_notebook:
push {lr}
ldr  r0,=#0x201433E          //Here we store how many tiles we're missing before completion
ldrb r0,[r0,#1]
cmp  r0,#0
bne  +
mov  r0,r4
bl   $80019DC                //Actual arrangements cleaning routine

+
pop  {pc}

//===========================================================================================
// This hack makes it so the notebook/stinkbug's arrangements are printed only if we're done
//===========================================================================================

.remove_tiles_showing_notebook:
push {lr}
ldr  r0,=#0x201433E          //Here we store how many tiles we're missing before completion
ldrb r0,[r0,#1]
cmp  r0,#0
bne  +
mov  r0,r4
bl   $8007318                //Actual arrangements printing routine

+
pop  {pc}

//===========================================================================================
// These hacks change the address of Block 0 display stuff from 201B184 to 203C000.
//===========================================================================================

.blockzero_address:
ldr  r4,=#0x2014340
bx   lr


//===========================================================================================
// An edited version of the routine at 0x8002474.
// This hack compares two strings up to a length and then checks whether the second string has ended or not. Returns 0 if they're the same. Otherwise it returns which one is the greater or smaller one.
//===========================================================================================

.compare_strings_edited:
push {r4-r6,lr}
mov r3,r0 //r0 has the first string's address
mov r4,r1 //r1 has the second string's address
lsl r2,r2,#0x10 //r2 has the length
ldr r5,=#0xFFFF0000
asr r0,r2,#0x10
cmp r2,r5 //Checks that the length is a valid number
bne .valid_number
ldrh r1,[r3,#0]
lsr r0,r5,#0x10
cmp r1,r0
beq + //If the first string ends instantly, then it returns true. Probably used to prevent the player from entering void names
add r2,r0,#0

.end_first:
ldrh r0,[r4,#0]
add r4,r4,#2
add r3,r3,#2
cmp r2,r0 //Does the second string end here?
beq .end_second

.reached_difference:
sub r3,r3,#2
sub r4,r4,#2
ldrh r0,[r3,#0]
ldrh r4,[r4,#0]
cmp r0,r4
bhi .different_first_greater
mov r0,#1 //The second string is greater. Returns 0xFFFFFFFF
neg r0,r0
b .end

.end_second:
ldrh r1,[r3,#0]
cmp r1,r2 //Does the first string have an end one character after the first one?
bne .end_first
b +

.different_first_greater:
mov r0,#1 //The first string is greater. Returns 1
b .end

.valid_number:
mov r2,#0
cmp r2,r0
bge + //If it has to compare strings of 0 length, it returns true
ldr r6,=#0xFFFF
add r5,r0,#0

-
ldrh r1,[r3,#0]
ldrh r0,[r4,#0]
add r4,#2
add r3,#2
cmp r1,r0
bne .reached_difference
cmp r1,r6 //Have we reached the strings' end?
beq +
add r0,r2,#1
lsl r0,r0,#0x10
lsr r2,r0,#0x10
cmp r2,r5
blt -

//NEW CODE HERE
//Checks if the second string has ended. If it has, then returns 0. Otherwise it returns 1
ldrh r0,[r4,#0]
cmp r0,r6 
bne .different_first_greater

+
mov r0,#0

.end:
pop {r4-r6}
pop {pc}

//===========================================================================================
// This hack decodes the main script, give r0 the raw, encoded value from the ROM, and
// this routine will return the decoded value back in r0. This routine is an important one.
//===========================================================================================

// Encoded byte is in r0, address is in r5
.decode_byte:
//push {r0-r3}

// Check if the intro code hack is present
//ldr  r0,=#0x100B5A2A // I scrambled the values around a bit so they're harder to
//lsr  r0,r0,#1        // find with a hex editor
//sub  r0,#1
//ldr  r0,[r0,#0]
//ldr  r1,=#0xF0E2
//sub  r1,#1
//ldr  r2,=#0xFC5F
//add  r2,#1
//lsl  r2,r2,#0x10
//add  r1,r1,r2
//cmp  r0,r1
//beq  +

// Spit out 'random' values
//ldr  r0,[sp,#0x14] // Whatever is here gets returned
//lsl  r0,r0,#0x18
//lsr  r0,r0,#0x18
//b    .dend

//+

// Determine if it's even or odd
//lsl  r1,r5,#0x1F
//lsr  r1,r1,#0x1F
//cmp  r1,#0
//beq  .deven

// Odd
//     char = ((byte + 89) ^ code_byte) - 8
//     where code_byte = [13C5F2 + ((byte_address >> 1) % 10E)]
//lsr  r0,r5,#1
//mov  r1,#0x93
//lsl  r1,r1,#1
//swi  #6 // Div -> r1 = r0 % r1
//pop  {r0}
//ldr  r2,=#0x813C5D8
//ldrb r1,[r2,r1]         // r1 = gfx_byte
//add  r0,#89
//eor  r0,r1
//sub  r0,#8
//lsl  r0,r0,#0x18
//lsr  r0,r0,#0x18
//b    .dend

// Even
//     char = ((byte - 7) ^ gfx_byte) + 3
//     where gfx_byte = [1C9C800 + ((byte_address >> 1) % 3A10)]
//.deven:
//lsr  r0,r5,#1
//ldr  r1,=#0x3A20
//swi  #6 // Div -> r1 = r0 % r1
//pop  {r0}
//ldr  r2,=#0x9C9C800
//ldrb r1,[r2,r1]         // r1 = gfx_byte
//sub  r0,#7
//eor  r0,r1
//add  r0,#3
//lsl  r0,r0,#0x18
//lsr  r0,r0,#0x18

//.dend:
//pop  {r1-r3}
bx   lr

//===========================================================================================
// This hack puts an end in the multi-line menus and makes odd lines even (which fixes stuff)
//===========================================================================================

define size_limit $FE
define empty_tile $EB

.end_line_multi_menu:
mov  r2,r0
sub  r2,r2,r5                //r2 has the number of characters to store now
lsl  r2,r2,#0x10
lsr  r2,r2,#0x10             //Unsigned short in r2
cmp  r2,#{size_limit}
ble  +
mov  r2,#{size_limit}        //Limit the number of characters in order to make this safe
+
add  r1,r6,r2                //Get to the section's end
mov  r0,#2
and  r0,r2
cmp  r0,#0                   //If it's not even, make this even so the last tile isn't removed
beq  +
mov  r0,#{empty_tile}        //Add an empty tile to make it work
strh r0,[r1,#0]
add  r1,#2                   //Go forward by 1 letter
+
ldr  r0,=#0xFFFF
strh r0,[r1,#0]              //Store the end of the line
bx   lr

//===========================================================================================
// This set of hacks makes it so a displayed script can have no speaker displayed while the
// speaker keeps speaking.
//===========================================================================================

define arbitrary_value $DA8

//Setup the speaker box block
.speaker_different_unused_val_setup:
push {r1-r2,lr}
mov  r1,r7
sub  r1,#8
ldr  r1,[r1,#4]
ldr  r2,=#{arbitrary_value} //Arbitrary value
cmp  r1,r2
bne  +
add  r1,r1,r0
strh r1,[r5,#2]             //This will be 0xFFFF if we're here
+

mov  r0,r6                  //Clobbered code
add  r0,#0xBC
pop  {r1-r2,pc}

//------------------------------------------------------------------------------------------------------

//If we did the setup, skip printing the speaker box
.speaker_different_unused_val_block:
push {lr}
push {r2}
mov  r3,#2
ldsh r2,[r1,r3]
ldr  r3,=#{arbitrary_value} //Arbitrary value
add  r3,r3,r0
cmp  r2,r3
bne  +

ldr  r0,=#0x8023E27         //Avoid printing a speaker box
pop  {r1}
pop  {r1}
bx   r0

+

mov  r3,#0                  //Reset value and do the normal stuff
pop  {r2}
bl   $8036BD8
pop  {pc}
