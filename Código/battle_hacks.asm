battle_hacks:

//=========================================================================================== 
// Modifies the GetAddressofGlyphBitmap for mostly battle text stuff. The main reason for
// having this hack is that the routine uses it to load both 16x16 and 8x8 fonts, depending
// on inputs. But because of changes to our 16x16 stuff, the original code wouldn't work for
// both font sets. So we're gonna do a cheap fix for it. Basically, if it's gonna load a
// 16x16 font, we do new code, otherwise we jump to a carbon copy of the original routine's
// code.
//=========================================================================================== 

.get_glyph_address:
push {lr}
cmp  r2,#0x08                // if r2 == 8, load the 8x8 font instead
beq  +

mov  r0,#0x20                // if we're running this code, we're loading 16x16 stuff
add  r1,r5,#0
mov  r1,r5
mul  r1,r0
ldr  r0,[r4,#0x04]
add  r0,r0,r1
pop  {pc}                    // return

+
asr  r0,r0,#3                // if we're running this code, we're loading 8x8 stuff
add  r0,#1
mul  r0,r2
add  r0,#2
mov  r1,r5
mul  r1,r0
ldr  r0,[r4,#0x04]
add  r0,r0,r1
add  r0,#2
pop  {pc}                    // return


//=========================================================================================== 
// this routine determines the number of tiles to be cleared when text in battle menus needs
// to be deleted. Normally, it assumes the # of tiles to be deleted = the # of letters in
// the current string. But with our VWF, this is no longer a valid assumption.
//
// The battle menu VWF has been modified so that the total VWF width of the current string
// can be found at the byte 0x2014300.
//
// We'll use this value, divide it by 10 (10 pixels wide per tile) and then round up. This
// will give us the total # of tiles to be cleared away.
//
// This final value needs to be in r0 when the routine ends. This value is stored by the
// game at the instruction at 806EBBE,
//=========================================================================================== 

.get_number_of_tiles_to_clear:
push {lr}

ldr  r1,=#0x2014300          // get the total width of the current string, stored here previously
ldrb r0,[r1,#0]              // r0 now has the width of the string

mov  r1,#10
swi  #6                      // now divide the total width by 10
cmp  r1,#0                   // r1 has the remainder, if it's non-zero,
beq  +                       // then we need to include the partial tile too
add  r0,r0,#0x01             // this includes the partial tile

+
cmp  r0,#0x16                // 0x16 is the highest possible, any higher and other stuff gets erased
bls  +
mov  r0,#0x16

+
pop  {pc}                    // end of routine! r0 now has the correct # of tiles to erase


//=========================================================================================== 
// Replaces the printing routine for mostly battle text stuff.
// In r8 we have the Y. We need to print 0xB rows of our characters (apparently).
// In r3 we have the current VRAM base address.
// In r6 we have the current colour.
// In SP,#0x10 + (current_stack_size) we have the glyph.
// In SP,#0x3C + (current_stack_size) we have the current letter.
// In SP,#0x0C + (current_stack_size) we have the info for our X and our Y.
//=========================================================================================== 

.fast_printing:
push {lr}
add  sp,#-8
ldr  r0,[sp,#0x24]
ldr  r1,[sp,#0x14]
bl   $8088E58                // clobbered code
mov  r2,r6
mov  r6,r8
mov  r0,#7
and  r6,r0                   // get the initial row # in the tiles
ldr  r7,[sp,#0x18]
mov  r1,#0
ldsh r7,[r7,r1]              // get the X
cmp  r7,#0
bge  +
add  r7,#7
+
and  r7,r0                   // get the subtile X
mov  r9,r3
ldr  r0,=#{main_font_width}
ldr  r1,[sp,#0x48]
lsl  r1,r1,#0x10
lsr  r1,r1,#0x10
ldr  r3,=#0xFF22
ldrb r0,[r0,r1]              // get the letter's width
add  r0,r0,#7
lsr  r0,r0,#3                // get the number of tiles to print
cmp  r3,r1                   // is this the E symbol?
bne  +
mov  r0,#1                   // the E symbol is only 1 tile wide
+
cmp  r0,#2
blt  +
mov  r0,#2                   // limit the number of tiles
+
mov  r10,r0

mov  r4,#0xFF
lsr  r4,r7                   // get the valid left-tile positions
lsl  r4,r4,#0x18
lsr  r5,r4,#8
orr  r4,r5
lsr  r5,r4,#0x10
orr  r4,r5
mvn  r5,r4                   // get the inverted version
str  r4,[sp,#0]              // save our masks
str  r5,[sp,#4]

lsl  r5,r2,#0x1C
lsr  r5,r5,#0x1C             // get the colour
lsl  r5,r5,#0x10
lsr  r5,r5,#0x6
ldr  r0,=#0x8CDF9F8          // get the 1bpp > 4bpp conversion table
add  r5,r5,r0

-

ldr  r2,[sp,#0x1C]           // load the current glyph
ldr  r2,[r2,#0]              // load the first 4 rows
mov  r3,r2
lsr  r2,r7                   // shift them by curr_x
mov  r0,#8
sub  r0,r7,r0
neg  r0,r0
lsl  r3,r0
ldr  r4,[sp,#0]
and  r2,r4                   // left side
ldr  r4,[sp,#4]
and  r3,r4                   // right side

lsl  r0,r6,#2
mov  r4,r9
add  r4,r4,r0                // get the current position

// ONE - LEFT
lsl  r0,r2,#0x18             // Get only one byte
lsr  r0,r0,#0x18

lsl  r0,r0,#2                // now multiply by four
ldr  r0,[r5,r0]              // r0 now has the converted 4bpp version
ldr  r1,[r4,#0]              // load what's in the current row
orr  r1,r0                   // OR them together
str  r1,[r4,#0]              // and now store it back

// ONE - RIGHT
lsl  r0,r3,#0x18             // Get only one byte
lsr  r0,r0,#0x18

lsl  r0,r0,#2                // now multiply by four
ldr  r0,[r5,r0]              // r0 now has the converted 4bpp version
str  r0,[r4,#0x20]           // now store it

add  r6,#1
mov  r1,#7
and  r1,r6
lsl  r1,r1,#2                // get the subtile part
lsr  r0,r6,#3                // get the Y part
lsl  r0,r0,#0xA
mov  r4,r9                   // add it all together
add  r4,r4,r0
add  r4,r4,r1

// TWO - LEFT
lsl  r0,r2,#0x10             // Get only one byte
lsr  r0,r0,#0x18

lsl  r0,r0,#2                // now multiply by four
ldr  r0,[r5,r0]              // r0 now has the converted 4bpp version
ldr  r1,[r4,#0]              // load what's in the current row
orr  r1,r0                   // OR them together
str  r1,[r4,#0]              // and now store it back

// TWO - RIGHT
lsl  r0,r3,#0x10             // Get only one byte
lsr  r0,r0,#0x18

lsl  r0,r0,#2                // now multiply by four
ldr  r0,[r5,r0]              // r0 now has the converted 4bpp version
str  r0,[r4,#0x20]           // now store it

add  r6,#1
mov  r1,#7
and  r1,r6
lsl  r1,r1,#2                // get the subtile part
lsr  r0,r6,#3                // get the Y part
lsl  r0,r0,#0xA
mov  r4,r9                   // add it all together
add  r4,r4,r0
add  r4,r4,r1

// THREE - LEFT
lsl  r0,r2,#0x8              // Get only one byte
lsr  r0,r0,#0x18

lsl  r0,r0,#2                // now multiply by four
ldr  r0,[r5,r0]              // r0 now has the converted 4bpp version
ldr  r1,[r4,#0]              // load what's in the current row
orr  r1,r0                   // OR them together
str  r1,[r4,#0]              // and now store it back

// THREE - RIGHT
lsl  r0,r3,#0x8              // Get only one byte
lsr  r0,r0,#0x18

lsl  r0,r0,#2                // now multiply by four
ldr  r0,[r5,r0]              // r0 now has the converted 4bpp version
str  r0,[r4,#0x20]           // now store it

add  r6,#1
mov  r1,#7
and  r1,r6
lsl  r1,r1,#2                // get the subtile part
lsr  r0,r6,#3                // get the Y part
lsl  r0,r0,#0xA
mov  r4,r9                   // add it all together
add  r4,r4,r0
add  r4,r4,r1

// FOUR - LEFT
lsr  r0,r2,#0x18             // Get only one byte

lsl  r0,r0,#2                // now multiply by four
ldr  r0,[r5,r0]              // r0 now has the converted 4bpp version
ldr  r1,[r4,#0]              // load what's in the current row
orr  r1,r0                   // OR them together
str  r1,[r4,#0]              // and now store it back

// FOUR - RIGHT
lsr  r0,r3,#0x18             // Get only one byte

lsl  r0,r0,#2                // now multiply by four
ldr  r0,[r5,r0]              // r0 now has the converted 4bpp version
str  r0,[r4,#0x20]           // now store it



ldr  r2,[sp,#0x1C]           // load the current glyph
ldr  r2,[r2,#4]              // load the second 4 rows
mov  r3,r2
lsr  r2,r7                   // shift them by curr_x
mov  r0,#8
sub  r0,r7,r0
neg  r0,r0
lsl  r3,r0
ldr  r4,[sp,#0]
and  r2,r4                   // left side
ldr  r4,[sp,#4]
and  r3,r4                   // right side



add  r6,#1
mov  r1,#7
and  r1,r6
lsl  r1,r1,#2                // get the subtile part
lsr  r0,r6,#3                // get the Y part
lsl  r0,r0,#0xA
mov  r4,r9                   // add it all together
add  r4,r4,r0
add  r4,r4,r1

// FIVE - LEFT
lsl  r0,r2,#0x18             // Get only one byte
lsr  r0,r0,#0x18

lsl  r0,r0,#2                // now multiply by four
ldr  r0,[r5,r0]              // r0 now has the converted 4bpp version
ldr  r1,[r4,#0]              // load what's in the current row
orr  r1,r0                   // OR them together
str  r1,[r4,#0]              // and now store it back

// FIVE - RIGHT
lsl  r0,r3,#0x18             // Get only one byte
lsr  r0,r0,#0x18

lsl  r0,r0,#2                // now multiply by four
ldr  r0,[r5,r0]              // r0 now has the converted 4bpp version
str  r0,[r4,#0x20]           // now store it

add  r6,#1
mov  r1,#7
and  r1,r6
lsl  r1,r1,#2                // get the subtile part
lsr  r0,r6,#3                // get the Y part
lsl  r0,r0,#0xA
mov  r4,r9                   // add it all together
add  r4,r4,r0
add  r4,r4,r1

// SIX - LEFT
lsl  r0,r2,#0x10             // Get only one byte
lsr  r0,r0,#0x18

lsl  r0,r0,#2                // now multiply by four
ldr  r0,[r5,r0]              // r0 now has the converted 4bpp version
ldr  r1,[r4,#0]              // load what's in the current row
orr  r1,r0                   // OR them together
str  r1,[r4,#0]              // and now store it back

// SIX - RIGHT
lsl  r0,r3,#0x10             // Get only one byte
lsr  r0,r0,#0x18

lsl  r0,r0,#2                // now multiply by four
ldr  r0,[r5,r0]              // r0 now has the converted 4bpp version
str  r0,[r4,#0x20]           // now store it

add  r6,#1
mov  r1,#7
and  r1,r6
lsl  r1,r1,#2                // get the subtile part
lsr  r0,r6,#3                // get the Y part
lsl  r0,r0,#0xA
mov  r4,r9                   // add it all together
add  r4,r4,r0
add  r4,r4,r1

// SEVEN - LEFT
lsl  r0,r2,#0x8              // Get only one byte
lsr  r0,r0,#0x18

lsl  r0,r0,#2                // now multiply by four
ldr  r0,[r5,r0]              // r0 now has the converted 4bpp version
ldr  r1,[r4,#0]              // load what's in the current row
orr  r1,r0                   // OR them together
str  r1,[r4,#0]              // and now store it back

// SEVEN - RIGHT
lsl  r0,r3,#0x8              // Get only one byte
lsr  r0,r0,#0x18

lsl  r0,r0,#2                // now multiply by four
ldr  r0,[r5,r0]              // r0 now has the converted 4bpp version
str  r0,[r4,#0x20]           // now store it

add  r6,#1
mov  r1,#7
and  r1,r6
lsl  r1,r1,#2                // get the subtile part
lsr  r0,r6,#3                // get the Y part
lsl  r0,r0,#0xA
mov  r4,r9                   // add it all together
add  r4,r4,r0
add  r4,r4,r1

// EIGHT - LEFT
lsr  r0,r2,#0x18             // Get only one byte

lsl  r0,r0,#2                // now multiply by four
ldr  r0,[r5,r0]              // r0 now has the converted 4bpp version
ldr  r1,[r4,#0]              // load what's in the current row
orr  r1,r0                   // OR them together
str  r1,[r4,#0]              // and now store it back

// EIGHT - RIGHT
lsr  r0,r3,#0x18             // Get only one byte

lsl  r0,r0,#2                // now multiply by four
ldr  r0,[r5,r0]              // r0 now has the converted 4bpp version
str  r0,[r4,#0x20]           // now store it



ldr  r2,[sp,#0x1C]           // load the current glyph
ldr  r2,[r2,#0x10]           // load the third 4 rows
mov  r3,r2
lsr  r2,r7                   // shift them by curr_x
mov  r0,#8
sub  r0,r7,r0
neg  r0,r0
lsl  r3,r0
ldr  r4,[sp,#0]
and  r2,r4                   // left side
ldr  r4,[sp,#4]
and  r3,r4                   // right side



add  r6,#1
mov  r1,#7
and  r1,r6
lsl  r1,r1,#2                // get the subtile part
lsr  r0,r6,#3                // get the Y part
lsl  r0,r0,#0xA
mov  r4,r9                   // add it all together
add  r4,r4,r0
add  r4,r4,r1

// NINE - LEFT
lsl  r0,r2,#0x18             // Get only one byte
lsr  r0,r0,#0x18

lsl  r0,r0,#2                // now multiply by four
ldr  r0,[r5,r0]              // r0 now has the converted 4bpp version
ldr  r1,[r4,#0]              // load what's in the current row
orr  r1,r0                   // OR them together
str  r1,[r4,#0]              // and now store it back

// NINE - RIGHT
lsl  r0,r3,#0x18             // Get only one byte
lsr  r0,r0,#0x18

lsl  r0,r0,#2                // now multiply by four
ldr  r0,[r5,r0]              // r0 now has the converted 4bpp version
str  r0,[r4,#0x20]           // now store it

add  r6,#1
mov  r1,#7
and  r1,r6
lsl  r1,r1,#2                // get the subtile part
lsr  r0,r6,#3                // get the Y part
lsl  r0,r0,#0xA
mov  r4,r9                   // add it all together
add  r4,r4,r0
add  r4,r4,r1

// TEN - LEFT
lsl  r0,r2,#0x10             // Get only one byte
lsr  r0,r0,#0x18

lsl  r0,r0,#2                // now multiply by four
ldr  r0,[r5,r0]              // r0 now has the converted 4bpp version
ldr  r1,[r4,#0]              // load what's in the current row
orr  r1,r0                   // OR them together
str  r1,[r4,#0]              // and now store it back

// TEN - RIGHT
lsl  r0,r3,#0x10             // Get only one byte
lsr  r0,r0,#0x18

lsl  r0,r0,#2                // now multiply by four
ldr  r0,[r5,r0]              // r0 now has the converted 4bpp version
str  r0,[r4,#0x20]           // now store it

add  r6,#1
mov  r1,#7
and  r1,r6
lsl  r1,r1,#2                // get the subtile part
lsr  r0,r6,#3                // get the Y part
lsl  r0,r0,#0xA
mov  r4,r9                   // add it all together
add  r4,r4,r0
add  r4,r4,r1

// ELEVEN - LEFT
lsl  r0,r2,#0x8              // Get only one byte
lsr  r0,r0,#0x18

lsl  r0,r0,#2                // now multiply by four
ldr  r0,[r5,r0]              // r0 now has the converted 4bpp version
ldr  r1,[r4,#0]              // load what's in the current row
orr  r1,r0                   // OR them together
str  r1,[r4,#0]              // and now store it back

// ELEVEN - RIGHT
lsl  r0,r3,#0x8              // Get only one byte
lsr  r0,r0,#0x18

lsl  r0,r0,#2                // now multiply by four
ldr  r0,[r5,r0]              // r0 now has the converted 4bpp version
str  r0,[r4,#0x20]           // now store it

mov  r0,r10
sub  r0,#1
cmp  r0,#0
ble  +
mov  r10,r0                  // increase the counter
ldr  r0,[sp,#0x1C]
add  r0,#8                   // increase the glyph's address
str  r0,[sp,#0x1C]
sub  r6,#0xA                 // get r6 back to its initial value
mov  r3,r9
add  r3,#0x20                // go one tile to the right
mov  r9,r3
b    -
+

add  sp,#8
pop  {pc}                    // return


//=========================================================================================== 
// this centers various text that appears in the sound player and also does the custom
// control code text parsing for battle text. What a weird combination!
//
// r1 has the address of the current string
// we'll also need to re-perform some code that we clobbered
//
// Link to this from 8088E00.
//===========================================================================================

.prepare_custom_cc:

// Time to do some shuffling. This will get lr back with it's original value 
push {r5,lr}                 // We're going to use r5, so we need to keep it in 
ldr r5,[sp,#0x08]            // Load r5 with our former LR value? 
mov r14,r5                   // Move the former LR value back into LR 
ldr r5,[sp,#0x04]            // Grab the LR value for THIS function 
str r5,[sp,#0x08]            // Store it over the previous one 
pop {r5}                     // Get back r5 
add sp,#0x04                 // Get the un-needed value off the stack 

push {r0-r3,r6}

//-------------------------------------------------------------------------------------------

ldr  r6,=#{main_font_width}  // r2 contains 08D1CE78, the width table's address
mov  r0,#0x0                 // initialize the total width counter
ldr  r3,=#0xFEFF             // r3 has the [END] code

//-------------------------------------------------------------------------------------------

-
ldrh r2,[r1,#0]              // load the current character

cmp  r2,r3                   // check for [END]
bgt  +                       // if encountered, exit the subroutine

add  r2,r6,r2                // get address of current character's width
ldrb r2,[r2,#0]              // load current char's width
add  r0,r0,r2                // add current width to the total

add  r1,r1,#0x02             // move to next character
b    -                       // do the loop over again

//-------------------------------------------------------------------------------------------

+
ldr  r6,=#0x2014300          // we're gonna store the final width here temporarily
strh r0,[r6,#0]

pop  {r0-r3,r6}              // restore registers now that we've done our stuff

ldrh r2,[r2,#0x2]            // original code we overwrote
lsl  r2,r2,#1                // multiply the pointer/offset by two
sub  r2,r2,r0
lsr  r2,r2,#0x1
sub  r2,#1


//==================================================================================
// it turns out r2 above calculates the length of the string, and this is used
// to allocate the correct amount of RAM to copy the string to. We need to modify
// this to take our custom battle control codes into account, so this hack has
// turned from mainly a sound player text centering hack to a string count hack.
//
// r2 now has the normal string length, we need to compensate for EF codes now.
//
// r1 has the string address at this point
//==================================================================================

push {r0}
push {r1}
push {r3}
push {r4}

ldr  r3,=#0xFFFF             // load r3 with the [END] code

//--------------------------------------------------------------------------------------------

-
ldrb r0,[r1,#1]              // load the high byte of the current character
cmp  r0,#0xEF                // see if this is a custom control code
beq  .custom_cc              // if so, jump to our special code to calculate its length unpacked

ldrh r0,[r1,#0]              // otherwise, load the current character
cmp  r0,r3                   // check if it's an [END] code
beq  +                       // if it is, then jump to the end of the routine

mov  r0,#0                   // this was a non-custom CC, so we're not gonna increment the count

.main_loop_next:
add  r2,r2,r0                // increment the letter count
add  r1,#2                   // increment the read count
b    -                       // do another loop iteration

//--------------------------------------------------------------------------------------------

+
pop  {r4}
pop  {r3}
pop  {r1}
pop  {r0}
pop  {pc}

//--------------------------------------------------------------------------------------------
.custom_cc:
sub  r2,#1                   // need to subtract 1 to counter the raw custom control code itself

ldrb r4,[r1,#0]              // load the current low byte of the custom control code
mov  r0,#0x1F
and  r0,r4                   // Load the first 5 bits of the custom codes

cmp  r0,#0x00                // check for 0xEF00, which will print the current enemy's name
bne  +
b    .cc_enemy_name
+

cmp  r4,#0x21                // check for 0xEF21, which will print the pigmask's article
bne  +
b    .cc_en_articles
+

cmp  r0,#0x01                // check for 0xEF01, which will print the cohorts string
bne  +
b    .cc_cohorts
+

cmp  r0,#0x02                // check for 0xEF02, which will print an initial uppercase article if need be
bne  +
b    .cc_en_articles
+

cmp  r0,#0x03                // check for 0xEF03, which will print an initial lowercase article if need be
bne  +
b    .cc_en_articles
+

cmp  r0,#0x04                // check for 0xEF04, which will print an uppercase article if need be
bne  +
b    .cc_en_articles
+

cmp  r0,#0x05                // check for 0xEF05, which will print a lowercase article if need be
bne  +
b    .cc_en_articles
+

cmp  r0,#0x06                // check for 0xEF06, which will print a lowercase possessive if need be
bne  +
b    .cc_en_articles
+

cmp r0,#0x07
bne  +
b    .cc_en_articles
+

cmp r0,#0x08
bne  +
b    .cc_en_articles
+

cmp r0,#0x09
bne  +
b    .cc_en_articles
+

cmp  r0,#0x10                // check for 0xEF10, which will print an initial uppercase article for items
bne  +
b    .cc_it_articles
+

cmp  r0,#0x11                // check for 0xEF11, which will print an initial lowercase article for items
bne  +
b    .cc_it_articles
+

cmp  r0,#0x12                // check for 0xEF12, which will print an uppercase article for items
bne  +
b    .cc_it_articles
+

cmp  r0,#0x13                // check for 0xEF13, which will print a lowercase article for items
bne  +
b    .cc_it_articles
+

cmp r0,#0x15
bne  +
b    .cc_it_articles
+

cmp  r0,#0x16                // check for 0xEF16, which will print a lowercase pronoun for items
bne  +
b    .cc_it_articles
+

cmp  r0,#0x17                // check for 0xEF17, which will print a lowercase past-tense verb for items
bne  +
b    .cc_it_articles
+

mov  r0,#0                   // if this executes, it's an unknown control code, so treat it normally
b    .main_loop_next         // jump back to the part of the main loop that increments and such

//--------------------------------------------------------------------------------------------

.cc_it_articles:
push {r1-r2}

sub  r0,#0x10
mov  r2,r0                       // r2 will be an offset into the extra item data slot
ldr  r0,=#0x2014324              // this is where the current item # will be saved by another hack
cmp  r4,#0x20                    // check if this is EF 30 or more
blt  +
ldr  r0,=#0x2014724              // then load the second last item for the extra data, this location is used by another hack to save the second last item's id
+
ldrh r0,[r0,#0]                  // load the current item #
mov r1,#9
mul r0,r1                        // offset = item ID * 9 bytes
ldr  r1,=#{item_extras_address}  // this is the base address of our extra item data table in ROM
add  r0,r0,r1                    // r0 now has the proper address of the current item's data slot
ldrb r0,[r0,r2]                  // load the proper line # to use from custom_text.bin
mov  r1,#40
mul  r0,r1                       // calculate the offset into custom_text.bin
ldr  r1,=#{custom_text_address}  // load r1 with the base address of our custom text array in ROM
add  r0,r0,r1                    // r0 now has the address of the string we want
pop  {r1-r2}

bl   custom_strlen               // count the length of our special string, store its length in r2
b    .main_loop_next             // now jump back to the part of the main loop that increments and such

//--------------------------------------------------------------------------------------------

.cc_enemy_name:
push {r1-r2}
ldr  r0,=#0x2014320               // this is where current_enemy_save.asm saves the current enemy's ID #
ldrh r0,[r0,#0]                   // load the current #
cmp  r4,#0x20                     // is this the pigmask code?
bne  +
cmp  r0,#6                        // is the actor the Pork Tank?
bne  +
mov  r0,#149                      // if it is, then change it to the Pigmask
+
ldr  r2,=#0x149
cmp  r0,r2                        // If the actor id is > 0x149, it's going to be a character. Let's call them properly
blt  +

ldr  r1,=#0x2004110               // Character data address
sub  r0,r0,r2                     // Remove 0x149 to get their ID
mov  r2,#0x6C
mul  r0,r2                        // Multiply it by 0x6C, each character's data length
add  r0,#2                        // Add 2 to get their name
add  r0,r0,r1                     // r0 now has the address of the character's name
pop  {r1-r2}
bl   custom_strlen_party          // count the length of our special string, store its length in r2, this is special because party member can have non 0xFFFF terminated names
b    .end_cc_enemy_name

+
mov  r1,#50
mul  r0,r1                        // offset = enemy ID * 50 bytes
ldr  r1,=#{enemynames_address}+4  // this is the base address of the enemy name array in ROM
add  r0,r0,r1                     // r0 now has the address of the enemy's name
pop  {r1-r2}

.count_and_inc:
bl   custom_strlen                // count the length of our special string, store its length in r2

.end_cc_enemy_name:
b    .main_loop_next              // now jump back to the part of the main loop that increments and such

//--------------------------------------------------------------------------------------------

.cc_cohorts:
push {r1-r3}
mov  r3,#0                   // r3 will be our total # of bytes changed


ldr  r0,=#0x2014322          // load the # of enemies
ldrb r0,[r0,#0]
cmp  r0,#1
beq  .cc_cohorts_end         // don't print anything if there's only one enemy


ldr  r0,=#0x2014322          // load the # of enemies
ldrb r0,[r0,#0]
sub  r0,#1                   // subtract one for ease of use


push {r1}


ldr  r1,=#0x8D0829C          // load r1 with the base address of our custom text array in ROM
mov  r2,#40
mul  r0,r2
add  r0,r0,r1                // r0 now has the address of the proper cohorts string
pop  {r1}                    // restore r1 with the target address
bl   custom_strlen           // count the length of our special string, store its length in r2
add  r3,r3,r0                // update special string length


.cc_cohorts_end:
mov  r0,r3                   // r0 now has the total # of bytes we added


pop  {r1-r3}
b    .main_loop_next         // now jump back to the part of the main loop that increments and such

//--------------------------------------------------------------------------------------------

.cc_en_articles:
push {r1-r2}

sub  r2,r0,#2                      // r2 will be an offset into the extra enemy data slot
                                   // this is a quicker method of doing a bunch of related codes at once
                                   // we take the low byte of the current CC and subtract 2, and that'll
                                   // be our offset
sub  r4,r4,#2

mov  r1,r4
lsr  r4,r4,#5
lsl  r4,r4,#5
ldr  r0,=#0x2014320                // this is where the routines save the other ID #
add  r0,r0,r4
ldrh r0,[r0,#0]                    // load the current #
mov  r4,r1
cmp  r4,#0x1F                      // is this the pigmask's article code?
bne  +
mov  r2,#2                         // Change the code so it makes sense
cmp  r0,#6                         // is the actor the Pork Tank?
bne  +
mov  r0,#149                       // if it is, then change it to the Pigmask
+
lsl  r0,r0,#3                      // offset = enemy ID * 8 bytes
ldr  r1,=#{enemy_extras_address}   // this is the base address of our extra enemy data table in ROM
add  r0,r0,r1                      // r0 now has address of this enemy's extra data entry
ldrb r0,[r0,r2]                    // r0 now has the proper line # to use from custom_text.bin
mov  r1,#40
mul  r0,r1                         // calculate the offset into custom_text.bin
ldr  r1,=#{custom_text_address}    // load r1 with the base address of our custom text array in ROM
add  r0,r0,r1                      // r0 now has the address of the string we want
pop  {r1-r2}

bl   custom_strlen                 // count the length of our special string, store its length in r2
b    .main_loop_next               // now jump back to the part of the main loop that increments and such

//=========================================================================================== 
// This code applies a VWF to battle menus and other stuff. It doesn't apply to battle text.
// It basically replaces these three lines of code:
//
//    ldrh r1,[r6]
//    add  r0,r0,r1
//    strh r0,[r6]
// 
// At [r6] is the current X position the last character was drawn to.
// At [r6]-4 is the character we've just drawn.
// We need to blank out the 2nd half of r0, look up [r6]-4 in a table, add it's width to r0.
// Then do what the original code does.
//=========================================================================================== 

.menu_vwf:
push {r4,r7,lr}

mov  r4,#0                   // r4 will be 0 if 16x16 font, #0x100 if 8x8 font
ldr  r7,=#0x2014300          // r7 will be our custom address in RAM to store the total width

cmp  r5,#0                   // if r5 is 0, we're starting on a new string
bne  +                       // in which case, let's see set the curr total width to 0

mov  r3,#0
strb r3,[r7,#0]              // initialize the total width as 0

//-------------------------------------------------------------------------------------------

+
ldrb r3,[r7,#0]              // load the current total width

lsr  r1,r1,#0x10
cmp  r1,#8
bne  +

ldr  r4,=#0x100              // set r4 to 0x100 so we'll load from the right width table later

//-------------------------------------------------------------------------------------------

+
push {r2,r5,r6}
ldrh r1,[r6,#0]              // Load our old X position into r1 
lsr  r0,r0,#8
lsl  r0,r0,#8                // Blank out the width of the current character
add  r0,r0,r1                // Add the old X position to r0 
sub  r6,#4                   // Move the pointer back some for now 
ldr  r5,[r6,#0]              // Load r5 with our current character

ldr  r6,=#{main_font_width}  // r6 = address of 16x16 font width table
add  r6,r6,r4                // add r4 to r6, it'll be 8D1CF78 if the 8x8 font is being used

ldr  r4,=#0x1FF              // see if the letter is in the normal text range
cmp  r5,r4                   // if it is, go and load the width from the width table
ble  +

mov  r5,#0                   // otherwise, use the width of Character 0, which is 10
                             // this mainly applies to things like the (E) icon by equipment

//-------------------------------------------------------------------------------------------

+
ldrb r5,[r6,r5]              // r5 = width of current letter
add  r0,r0,r5                // add width to the X coordinate

add  r3,r3,r5                // now add to the total width, r3 will have this after the hack too
strb r3,[r7,#0]              // store the new total width back to our custom RAM spot
pop  {r2,r5,r6}              // restore the registers we used

pop  {r4,r7,pc}              // restore other registers and return




//===========================================================================================
//===========================================================================================
// This is the first part of a hack to make battle text work right.
//
// This routine should be linked to from 80840D2.
//
// This first part takes the place of the place in the game's code where it loads the current
// character right before doing control code checks. Later on in the code, the game will load
// the character again if it wasn't a control code. This later part will be handled by
// battle_vwf2.asm. We're doing things this way so that control codes like [WAIT] will work
// as intended.
//
// Basically, this part of the hack will prep a special block of RAM for battle_vwf2.asm
// and then perform the code we overwrote.
//===========================================================================================
//--------------------------------------------------------------------------------------------
//
// We're going to need to use a few bytes of RAM, starting from 0x2014300
//
// 2014300   byte   DO NOT USE!
// 2014301   byte   init_flag -- If this is 0, we know we need to initialize everything
// 2014302   hword  current letter/character/control code
// 2014303   ...
// 2014304   word   current x and y coordinates
// 2014305   ...
// 2014306   ...
// 2014307   ...
// 2014308   word   base address of the current string
// 2014309   ...
// 201430A   ...
// 201430B   ...
// 201430C   hword  current position in the string
// 201430D   ...
// 201430E   hword  total length of the current string
// 201430F   ...
// 2014310   hword  current line # we're on
// 2014311   ...
// 2014312   byte   newline_encountered flag -- 0 if no, non-zero if yes
//
//--------------------------------------------------------------------------------------------
// Coming into this, the registers are as follows:
//
//  r0  = current address (so when this is first called, it's the start of the string)
//  r1  = current position in the current string
//  r2  = ???
//  r3  = ???
//  r4  = ???
//  r5  = ???
//  r6  = ??? (seems to be pretty important though)
//  r7  = current string/tile counter (this is the key to making our hack run long enough)
//  r8  = not sure, but (r8 + 6) is where the total string length is stored
//  r9  = ???
//  r10 = ???
//  r11 = ???
//  r12 = ???
//===========================================================================================
// This is some routine initialization stuff

.main_vwf1:
push {r5,lr}                 // We're going to use r5, so we need to keep it in 
ldr r5,[sp,#0x08]            // Load r5 with our former LR value? 
mov lr,r5                    // Move the former LR value back into LR 
ldr r5,[sp,#0x04]            // Grab the LR value for THIS function 
str r5,[sp,#0x08]            // Store it over the previous one 
pop {r5}                     // Get back r5 
add sp,#0x04                 // Get the un-needed value off the stack

//-----------------

push {r5,r7}                 // this is unrelated to this hack really
ldr  r7,=#0x2014320          // it's used to clear the enemy value each line of text
mov  r5,#0                   // this is the easiest way to do it, so never mind this stuff
strh r5,[r7,#0]              // clears current enemy value, sets to 0
pop  {r5,r7}

//-----------------

lsl  r1,r1,#1                // this is code we clobbered while linking here
ldr  r0,[r0,#0]
add  r0,r0,r1

push {r5-r6}
ldr  r6,=#0x2014300          // Load r6 with the base address of our custom RAM block
ldr  r5,=#{main_font_width}  // load r5 with the address of the font width table

cmp  r7,#0
bne  +                       // if we're on the first character, init stuff, else do main code

//--------------------------------------------------------------------------------------------
// This initializes our custom RAM block

str  r0,[r6,#0x8]            // store the base address of the string in the RAM block

mov  r0,#0x0
strh r0,[r6,#0xC]            // starting position = 0
strh r0,[r6,#0x10]           // current line = 0
strb r0,[r6,#0x12]           // newline_encountered flag = FALSE

mov  r0,#1
strb r0,[r6,#1]              // init_flag = 1, this makes the game not re-initialize everything

mov  r0,#12
strh r0,[r6,#0x4]            // start x = 12
mov  r0,#6
strh r0,[r6,#0x6]            // start y = 6

mov  r0,r8
ldrb r0,[r0,#0x6]            // [r8 + 6] has the total string length
strb r0,[r6,#0xE]            // store total length in our RAM block

bl   .word_wrap_setup        // add any newlines if text gets too long in the current string

//--------------------------------------------------------------------------------------------
// This is the meat of the code -- this is why we're doing this hack

+
ldr  r0,[r6,#0x8]            // load the base address of the string
ldrh r1,[r6,#0xC]            // load the current position in the string
lsl  r1,r1,#1                // multiply it by 2, since there are two bytes per letter
add  r0,r0,r1                // get the address for the current letter
ldrh r0,[r0,#0]              // load the current character
strh r0,[r6,#0x2]            // store the current character in our RAM block

ldr  r1,=#0xFF02
cmp  r0,r1                   // see if this is a [WAIT] code (0xFF02)
beq  .set_newline
sub  r1,#0x1
cmp  r0,r1                   // see if this is a [BREAK] code (0xFF01)
beq  .set_newline
lsr  r0,r0,#8                // shift right 1 byte
cmp  r0,#0xFF                // is this a control code? 
beq  .move_to_next_char      // if so, manually move to the next char
b    .end_main_vwf1

//--------------------------------------------------------------------------------------------
// If we're executing this code, we've encountered a code that signifies a line break

.set_newline:
ldrh r0,[r6,#0x10]           // load current line #
add  r0,r0,#0x1
strh r0,[r6,#0x10]           // line_num++

mov  r0,#0x1
strb r0,[r6,#0x12]           // newline_encountered flag = TRUE

.move_to_next_char:
ldrh r0,[r6,#0x0C]           // load current position
add  r0,r0,#0x1              // we need to increment it manually if we're on a control code
strh r0,[r6,#0x0C]

//--------------------------------------------------------------------------------------------
// This is the end area of the code, mostly preparing to leave and doing lines we clobbered

.end_main_vwf1:
ldrh r1,[r6,#0x2]            // load the current character in r1, the game expects this
ldr  r0,=#0xFF30             // load r0 with FF30, which the game expects to be here

pop  {r5-r6,pc}              // time to leave!


//===========================================================================================
//===========================================================================================
// This is the automatic word wrap routine, we call it once, when everything is getting inited
//
// The register layout during most of this is as follows:
//
//   r0: scratch register
//   r1: curr_char_address, points to the current character in the string
//   r2: start_address, this points to the beginning of the string
//   r3: end_address, this points to the final character of the string
//   r4: curr_width, we use this to total up widths until it exceeds a certain amount (208)
//   r5: contains the address of the font width table
//   r6: starts with our RAM block's address, but I also need it for scratch usage too
//   r7: contains the address of the last "space-ish" character, so we'll know where to put
//       a newline if need be

//--------------------------------------------------------------------------------------------
// We're just initializing everything here. Lots of registers being used for ease of coding

.word_wrap_setup:
push {r2-r4,r7}

ldr  r2,[r6,#0x8]            // load r2 with the start address of the string
ldrh r3,[r6,#0xE]            // load r3 with the length of the string
lsl  r3,r3,#1                // multiply the length by two, since two bytes per letter
add  r3,r2,r3                // r3 now has the end address of the string

push {r6}

mov  r1,r2                   // r1 is the current character's address
mov  r4,#0                   // r4 is curr_width
mov  r7,r2                   // r7 is last_space, the spot where the last space was

//--------------------------------------------------------------------------------------------
// Now we do the meat of the auto word wrap stuff

.word_wrap_loop:
ldr  r6,=#0xFF01

cmp  r1,r3
bge  .word_wrap_end          // jump to the end if we're past the end of the string

ldrh r0,[r1,#0]              // load the current character
cmp  r0,#0x40                // is the current character a space?
beq  .space_found
cmp  r0,r6                   // is the current character a [BREAK]?
beq  .newline_found
add  r6,#1
cmp  r0,r6                   // is the current character a [WAIT]?
beq  .newline_found

mov  r6,r0
lsr  r0,r0,#0x8              // clear the first two bytes of the current character
cmp  r0,#0xFF                // if r0 == 0xFF, this is a CC, so skip the width adding junk
beq  .no_wrap_needed
mov  r0,r6
b    .main_wrap_code

//--------------------------------------------------------------------------------------------
// We found a space or a space-like character, so reset some values

.newline_found:
mov  r4,#0                   // this was a [WAIT] or [BREAK], so reset the width
mov  r7,r1                   // last_space = curr_char_address
b    .no_wrap_needed

.space_found:
mov  r7,r1                   // last_space = curr_char_address
                     
//--------------------------------------------------------------------------------------------
// Here is the real meat of the auto word wrap routine

.main_wrap_code:
ldrb r0,[r5,r0]              // get the width of the current character
add  r4,r4,r0                // curr_width += width of current character

cmp  r4,#208
blt  .no_wrap_needed         // if curr_width < 208, go to no_wrap_needed to update the width and such

mov  r4,#0                   // if we're executing this, then width >= 208, so do curr_width = 0 now

mov  r1,r7                   // curr_char_address = last_space_address// we're gonna recheck earlier stuff

ldr  r0,=#0xFF01             // replace the last space-ish character with a newline code
strh r0,[r7,#0]              // barring any incredibly crazy text, this should almost never overwrite
                             // existing [BREAK]s or [WAIT]s

//--------------------------------------------------------------------------------------------
// Get ready for the next loop iteration

.no_wrap_needed:
add  r1,#2                   // curr_char_address += 2
b    .word_wrap_loop         // do the next loop iteration

//--------------------------------------------------------------------------------------------
// Let's get out of here!

.word_wrap_end:
pop  {r6}
pop  {r2-r4,r7}
bx   lr


//===========================================================================================
// This is the second part of a hack to make battle text work right.
//
// This routine should be linked to from 808418E.
//
// The first part has set up the values in the RAM block for us. Some code then parsed
// control codes out if necessary. Now we need to calculate the coordinates for the letter
// about to be printed, as well as trick the game into continuing its loop longer. Also
// gotta do some manual newline handling and perform stuff we clobbered linking to this hack.
//
// See the documentation for main_vwf1 for details on the custom RAM area.
//===========================================================================================
// Coming into this, the registers are as follows:
//
//  r0  = current address (so when this is first called, it's the start of the string)
//  r1  = current position in the current string
//  r2  = ???
//  r3  = ???
//  r4  = area in current struct (add #0x38 to get the current X and Y coords)
//  r5  = ???
//  r6  = ???
//  r7  = current string/tile counter (this is the key to making our hack run long enough)
//  r8  = not sure, but (r8 + 6) is where the total string length is stored
//  r9  = ???
//  r10 = ???
//  r11 = ???
//  r12 = ???
//
//===========================================================================================
// This is some routine initialization stuff

.main_vwf2:
push {r5,lr}                 // We're going to use r5, so we need to keep it in 
ldr  r5,[sp,#0x08]           // Load r5 with our former LR value? 
mov  lr,r5                   // Move the former LR value back into LR 
ldr  r5,[sp,#0x04]           // Grab the LR value for THIS function 
str  r5,[sp,#0x08]           // Store it over the previous one 
pop  {r5}                    // Get back r5 
add  sp,#0x04                // Get the un-needed value off the stack

push {r5-r6}                 // we really need these registers right now

ldr  r5,=#{main_font_width}  // load r5 with the address of the font width table
ldr  r6,=#0x2014300          // Load r6 with the base address of our custom RAM block

//--------------------------------------------------------------------------------------------

bl   .process_line           // see if we need to move to a new line, and if so, do stuff accordingly

ldr  r1,[r6,#0x4]            // load the x and y coordinates into r1, these were updated by process_line
mov  r0,r4
add  r0,#0x38                // r4 + #0x38 is where the struct's coordinates are
str  r1,[r0,#0]              // store our custom coordinates in the struct

ldrh r0,[r6,#0x2]            // load the current character
add  r0,r0,r5                // get the address of the current character's width
ldrb r0,[r0,#0]              // load the current character's width

ldrh r1,[r6,#0x4]            // load the current x coordinate
add  r0,r0,r1                // x = x + width_of_current_character
strh r0,[r6,#0x4]            // store the new x coordinate into our RAM block, will be used next call
                             // even if the current character is a control code, we'll still catch it
                             // later and correct it, so it's okay if it gets something crazy here

ldr  r1,[r6,#0x4]            // load the x and y coordinates into r1
mov  r0,r4
str  r1,[r0,#0x44]           // store the next char's location in the location where the next erase is

ldrh r0,[r6,#0xC]            // load our current char position
add  r0,#1                   // increment our current char position
strh r0,[r6,#0xC]            // store it back in our RAM block

ldrh r1,[r6,#0xE]            // load r1 with the total length of this string
cmp  r0,r1                   // see if current character count >= the length of this string
bcc  .end_main_vwf2          // go to the last part of our code if we're under the total length

mov  r0,#0                   // set init_flag to 0 so that things here will get re-initialized next string
strb r0,[r6,#1]

//--------------------------------------------------------------------------------------------
// This stuff basically gets everything ready before leaving this hack

.end_main_vwf2:
ldrh r1,[r6,#0x2]            // load r1 with the current character, the game expects this

pop  {r5-r6}                 // get the original values back in these registers

mov  r0,#0
strh r0,[r6,#0x2A]           // make the game think we're always on line 0
strh r0,[r6,#0x2C]           // make the game think we're on character 0 always

ldr  r2,[r5,#0x4]            // another clobbered line
mov  r0,r4                   // and another

pop  {pc}                    // time to leave!


//=============================================================================================
//---------------------------------------------------------------------------------------------
// This routine determines if we're on Line 2 or higher, and if we are, recorrect stuff
// and reposition coordinates to be at the proper place
//
//    r0 has the current line # when this function is called

.process_line:
ldrb r1,[r6,#0x12]           // load newline_encountered_flag
cmp  r1,#0                   // compare it to 0
beq  .end_process_line       // don't do any of this code if it's set to FALSE

ldrh r0,[r6,#0x10]           // check current line #
cmp  r0,#2
bcc  +                       // don't scroll if don't need to

mov  r0,#1
strh r0,[r6,#0x10]           // set us back to Line #1
push {lr}
bl   .move_text_up           // hand-coded text scrolling routine to move text up
pop  {r1}
mov  lr,r1

+
mov  r1,#11
mul  r0,r1
add  r0,#6                   // y = line * 11 + init_y (do init_y stuff later)
strh r0,[r6,#0x6]            // store the new y in our RAM block
mov  r0,#12                  // x = 12
strh r0,[r6,#0x4]            // store the new x in our RAM block

mov  r0,#0x0
mov  r1,r4
add  r1,#0x30
strb r0,[r1,#0]              // sets the "display this glyph" flag in the current struct

.end_process_line:
mov  r0,#0
strb r0,[r6,#0x12]           // set newline_encountered flag to FALSE

bx   lr


//=============================================================================================
// This hack clears all the text in the battle text window area. The game's way of doing this
// is stupid, and the easiest way to fix problems with it is to erase everything on our own
// first. This erases the top 32 pixel lines of the screen.
//=============================================================================================

.clear_battle_window:
push {r5,lr}                 // We're going to use r5, so we need to keep it in 
ldr  r5,[sp,#0x08]           // Load r5 with our former LR value? 
mov  lr,r5                   // Move the former LR value back into LR 
ldr  r5,[sp,#0x04]           // Grab the LR value for THIS function 
str  r5,[sp,#0x08]           // Store it over the previous one 
pop  {r5}                    // Get back r5 
add  sp,#0x04                // Get the un-needed value off the stack

//--------------------------------------------------------------------------------------------

push {r0-r3}

mov  r0,#0
push {r0}
mov  r0,sp

ldr  r1,=#0x6000000
ldr  r2,=#0x800

mov  r3,#1
lsl  r3,r3,#24
orr  r2,r3                   // set the 24th bit of r2 so it'll know to fill instead of copy
swi  #0x0B                   // clear old data out

pop  {r0}
pop  {r0-r3}

mov  r5,r0                   // perform the lines we clobbered
mov  r7,r1
ldr  r0,=#0x9F83DB0

pop  {pc}                    // time to leave!


//=============================================================================================
// Here it is, THE function that copies the text from one line to the line up above it.
// Copying around tilemap memory is really inconvenient, so this will take a lot of work :(
//=============================================================================================

.move_text_up:
push {r0}
push {r5}
push {r6}
push {r3}

mov  r3,#0                   // r3 = 0 so we can easily clear crap out
mov  r1,#0                   // r1 is gonna be our loop counter

-
ldr  r5,=#0x6000018          // r5 is our address in tile memory for the top line of text
ldr  r6,=#0x6000804          // r6 is our address in tile memory for the bottom line of text
lsl  r0,r1,#5                // r0 = r1 * 0x20, a quick way to multiply rather than use mul
add  r5,r5,r0                // this gets us the tiles to use based on the loop counter #
add  r6,r6,r0

ldr  r0,[r6,#0]              // get first pixel row of bottom line
str  r0,[r5,#0]              // copy the pixel row to the first pixel row of the top line
str  r3,[r6,#0]              // clear out first pixel row of bottom line

ldr  r0,[r6,#0x4]            // get second pixel row of bottom line
str  r0,[r5,#0x4]            // copy the pixel row to the second pixel row of the top line
str  r3,[r6,#0x4]            // clear out second pixel row of bottom line

ldr  r5,=#0x6000400          // now we're doing the next section, which is the bulk of the stuff
ldr  r6,=#0x600080C          // 
lsl  r0,r1,#5                // r0 = r1 * 0x20, a quick way to multiply rather than use mul
add  r5,r5,r0                // this gets us the tiles to use based on the loop counter #
add  r6,r6,r0

ldr  r0,[r6,#0]              // row 3
str  r0,[r5,#0]
str  r3,[r6,#0]

ldr  r0,[r6,#0x4]            // row 4
str  r0,[r5,#0x4]
str  r3,[r6,#0x4]

ldr  r0,[r6,#0x8]            // row 5
str  r0,[r5,#0x8]
str  r3,[r6,#0x8]

ldr  r0,[r6,#0xC]            // row 6
str  r0,[r5,#0xC]
str  r3,[r6,#0xC]

ldr  r0,[r6,#0x10]           // row 7
str  r0,[r5,#0x10]
str  r3,[r6,#0x10]

ldr  r5,=#0x6000414          // now we're doing the next section
ldr  r6,=#0x6000C00
lsl  r0,r1,#5                // r0 = r1 * 0x20, a quick way to multiply rather than use mul
add  r5,r5,r0                // this gets us the tiles to use based on the loop counter #
add  r6,r6,r0

ldr  r0,[r6,#0]              // row 8
str  r0,[r5,#0]
str  r3,[r6,#0]

ldr  r0,[r6,#0x4]            // row 9
str  r0,[r5,#0x4]
str  r3,[r6,#0x4]

ldr  r0,[r6,#0x8]            // row 10
str  r0,[r5,#0x8]
str  r3,[r6,#0x8]

ldr  r5,=#0x6000800          // now we're doing the final section, which is just one row
ldr  r6,=#0x6000C0C
lsl  r0,r1,#5                // r0 = r1 * 0x20, a quick way to multiply rather than use mul
add  r5,r5,r0                // this gets us the tiles to use based on the loop counter #
add  r6,r6,r0

ldr  r0,[r6,#0]              // row 11
str  r0,[r5,#0]
str  r3,[r6,#0]

add  r1,#1
cmp  r1,#0x1E
blt  -                       // r1++, if r1 < 1E (# of tiles wide the screen is) then loop back

pop  {r3}
pop  {r6}
pop  {r5}
pop  {r0}
bx   lr


//=============================================================================================
// This hack character names in the HP/PP boxes in battle.
//
// At 807D2D8, the value in [r7-#0x40] is dependent on n.
// It's in multiples of 6, starts at 8 for n=0
// altering your party doesn't change this pattern.
// However, if the 0th party character is 0x00 (ie., your party is 00 02 03 04),
// it doesn't begin with 14, it's still 8.
// This case shouldn't ever happen naturally though, so we should be fine.
// Party characters: ch = [2004860 + n], n: 0-3
// Party names: 2004112 + (ch * 0x6C)
//=============================================================================================

.center_name:
push {r5,lr}                 // We're going to use r5, so we need to keep it in 
ldr  r5,[sp,#0x08]           // Load r5 with our former LR value? 
mov  lr,r5                   // Move the former LR value back into LR 
ldr  r5,[sp,#0x04]           // Grab the LR value for THIS function 
str  r5,[sp,#0x08]           // Store it over the previous one 
pop  {r5}                    // Get back r5 
add  sp,#0x04                // Get the un-needed value off the stack 

push {r0,r1,r3,r4,r5}

mov  r0,r7
sub  r0,#0x40
ldrb r0,[r0,#0]
sub  r0,#8
mov  r1,#6
swi  #6
ldr  r1,=#0x2004860
ldrb r1,[r1,r0]
mov  r0,#0x6C
mul  r1,r0
ldr  r0,=#0x2004112
add  r0,r0,r1

mov  r1,#0xFF
lsl  r1,r1,#8
ldr  r4,=#{small_font_width}
mov  r5,#0

-
ldrh r3,[r0,#0]
add  r0,#2
cmp  r3,r1
bge  +
ldrb r3,[r4,r3]
add  r5,r5,r3
b    -

+
lsr  r5,r5,#1
sub  r2,r2,r5

// this new snippet fixes the weird bug where the far-left name in a 4-member team
// can mess up if the name is too wide. The problem is that the game would try to
// print at a negative X position, so we'll just set it to 0 in those cases.
cmp  r2,#00
bge  +
mov  r2,#0

+
mov  r7,#0x30
add  r7,r8                   // this line assembles weird with goldroad. Hexedit to [47 44] if it doesn't assemble as that.
mov  r12,r7

pop {r0,r1,r3,r4,r5,pc}


//=============================================================================================
// This code saves the value of the currently active enemy to a halfword in RAM.
// We need to have this value easily available when we do our custom control code
// stuff later on.
//=============================================================================================

.save_current_enemy:
ldr  r0,=#0x2014320          // this is the address where we'll store the current enemy's value
strh r1,[r0,#0]              // store the value. How easy!
bx   lr


//=============================================================================================
// This code clears the currently active enemy to 0. Called before .save_current_enemy.
// This helps (but doesn't 100% fix) the "The Flint" problem.
//=============================================================================================

.clear_current_enemy:
ldr  r7,=#0x2014320
mov  r5,#0
strh r5,[r7,#0]              // clears current enemy value, sets to 0
mov  r7,r0                   // do clobbered code
mov  r5,r1
bx   lr


//=============================================================================================
// This code saves the value of the currently active enemy to a halfword in RAM.
// We need to have this value easily available when we do our custom control code
// stuff later on.
//=============================================================================================

.save_total_enemies:
push {r4}
ldr  r4,=#0x2014322          // we're going to store the total # of enemies here

ldr  r1,[r3,#0x4]            // original code, loads r1 with the total # of enemies
add  r0,r0,r1

mov  r1,r0                   // only need to know if 1, 2, or 3 enemies. 
cmp  r1,#3                   // if it's over 3, just say it's 3
blt  +
mov  r1,#3

+
strh r1,[r4,#0]              // store our count in our RAM block area for later reading
pop  {r4}
bx   lr


//=============================================================================================
// This code saves the value of the currently active item to a halfword in RAM.
// We need to have this value easily available when we do our custom control code
// stuff later on.
//=============================================================================================

.save_current_item:
push {r3}
ldr  r0,=#0x2014324          //Get ex current item
ldrh r3,[r0,#0]
ldr  r0,=#0x2014724          //Write it in this location of the RAM
strh r3,[r0,#0]
ldr  r0,=#0x2014324          //Save the new current item
strh r1,[r0,#0]
pop  {r3}
bx   lr




//=============================================================================================
// This hack implements a custom control code system used by the battle text.
// Since the battle text stuff is shared by other code in the game, it may affect other
// stuff too, but since that other stuff won't use any of our new control codes, it
// shouldn't matter. Note that this is very similar to the code that follows the
// sound player text-centering code. The difference is that this code actually copies the
// new data, the other code simply determines how much extra space the text from the custom
// control codes will take.
//
// The original control codes all start with FF in their most significant byte. Our
// custom control codes will start with EF. We could use FE, but then we'd be inconsistent
// with our CC formats between main script text and battle/etc. text.
//
// This hack should be linked from 806E464.
//
// The main registers in this hack are:
//
//   r0  = address of the current letter/code to read in
//   r1  = address of the current write location
//   r2  = length of the current string (we'll need to toy with this beforehand maybe)
//   r3  = somewhere on the stack, [r3 + ???] is the current letter count
//
//=============================================================================================
// This is some routine initialization stuff

.execute_custom_cc:
push {r5,lr}                 // We're going to use r5, so we need to keep it in 
ldr  r5,[sp,#0x08]           // Load r5 with our former LR value? 
mov  lr,r5                   // Move the former LR value back into LR 
ldr  r5,[sp,#0x04]           // Grab the LR value for THIS function 
str  r5,[sp,#0x08]           // Store it over the previous one 
pop  {r5}                    // Get back r5 
add  sp,#0x04                // Get the un-needed value off the stack 

push {r6-r7}                 // this original code counts stuff confusingly,
mov  r6,#0                   // so we're gonna use r6 as OUR counter

//--------------------------------------------------------------------------------------------

-
lsl  r0,r0,#1                // original code
cmp  r0,#0x0                 // see if this is the first letter
bne  .ecc_char_check         // if it isn't, skip this part
add  r1,r0,r4                // initialize the write address if this is the first letter

//--------------------------------------------------------------------------------------------

.ecc_char_check:
add  r0,r0,r5                // original code, gets the proper read location
ldrb r7,[r0,#1]              // check the high byte of the current letter
cmp  r7,#0xEF
beq  .check_custom_cc        // if this is a custom CC, go do stuff, else do old code and leave

.ecc_inc:
ldrh r0,[r0,#0]              // this is the original code
strh r0,[r1,#0]
ldrh r0,[r3,#0x6]
add  r0,#1
strh r0,[r3,#0x6]
add  r1,#2                   // increment the read address
add  r6,r6,#1                // increment our counter

.ecc_len_check:
cmp  r6,r2                   // this replaces the original check
blt  -                       // loop again if we haven't finished copying

strh r6,[r3,#0x6]
pop  {r6-r7,pc}              // restore registers and exit

//--------------------------------------------------------------------------------------------

.check_custom_cc:
ldrb r7,[r0,#0]              // load the current character
mov  r0,#0x1F
and  r0,r7                   // load the important part of the byte

cmp  r0,#0x00                // check for 0xEF00, which will print the current enemy's name
bne  +
b    .ecc_enemy_name
+

cmp  r7,#0x21                // check for 0xEF21, which will print the Pigmask's uppercase article if need be
bne  +
b    .ecc_en_articles
+

cmp  r0,#0x01                // check for 0xEF01, which will print "and cohort/and cohorts" if need be
bne  +
b    .ecc_cohorts
+

cmp  r0,#0x02                // check for 0xEF02, which will print an initial uppercase article if need be
bne  +
b    .ecc_en_articles
+

cmp  r0,#0x03                // check for 0xEF03, which will print an initial lowercase article if need be
bne  +
b    .ecc_en_articles
+

cmp  r0,#0x04                // check for 0xEF04, which will print an uppercase article if need be
bne  +
b    .ecc_en_articles
+

cmp  r0,#0x05                // check for 0xEF05, which will print a lowercase article if need be
bne  +
b    .ecc_en_articles
+

cmp  r0,#0x06                // check for 0xEF06, which will print a lowercase possessive if need be
bne  +
b    .ecc_en_articles
+

cmp r0,#0x07
bne  +
b    .ecc_en_articles
+

cmp r0,#0x08
bne  +
b    .ecc_en_articles
+

cmp r0,#0x09
bne  +
b    .ecc_en_articles
+

cmp  r0,#0x10                // check for 0xEF10, which will print an initial uppercase article for items
bne  +
b    .ecc_it_articles
+

cmp  r0,#0x11                // check for 0xEF11, which will print an initial lowercase article for items
bne  +
b    .ecc_it_articles
+

cmp  r0,#0x12                // check for 0xEF12, which will print an uppercase article for items
bne  +
b    .ecc_it_articles
+

cmp  r0,#0x13                // check for 0xEF13, which will print a lowercase article for items
bne  +
b    .ecc_it_articles
+

cmp r0,#0x15
bne  +
b    .ecc_it_articles
+

cmp  r0,#0x16                // check for 0xEF16, which will print a lowercase pronoun for items
bne  +
b    .ecc_it_articles
+

cmp  r0,#0x17                // check for 0xEF17, which will print a lowercase past-tense verb for items
bne  +
b    .ecc_it_articles
+

b    .ecc_inc                // treat this code normally if it's not a valid custom control code

//--------------------------------------------------------------------------------------------

.customcc_inc:
add  r1,r1,r0                // update our write address
lsr  r0,r0,#0x1
add  r6,r6,r0                // update our own custom counter

ldrh r0,[r3,#0x6]            // increment the char count, which will later increment the read address
add  r0,#1
strh r0,[r3,#0x6]

b    .ecc_len_check

//--------------------------------------------------------------------------------------------

.ecc_it_articles:
push {r1-r2}

sub  r0,#0x10
mov  r2,r0                       // r2 will be an offset into the extra item data slot
ldr  r0,=#0x2014324              // this is where the current item # will be saved by another hack
cmp  r7,#0x20                    // check if this is > EF 30
blt  +
ldr  r0,=#0x2014724              // then load the second last item for the extra data, this location is used by another hack to save the second last item's id
+
ldrh r0,[r0,#0]                  // load the current item #
mov r1,#9
mul r0,r1                        // offset = item ID * 9 bytes
ldr  r1,=#{item_extras_address}  // this is the base address of our extra item data table in ROM
add  r0,r0,r1                    // r0 now has the proper address of the current item's data slot
ldrb r0,[r0,r2]                  // load the proper line # to use from custom_text.bin
mov  r1,#40
mul  r0,r1                       // calculate the offset into custom_text.bin
ldr  r1,=#{custom_text_address}  // load r1 with the base address of our custom text array in ROM
add  r0,r0,r1                    // r0 now has the address of the string we want
pop  {r1-r2}

bl   custom_strcopy              // r0 gets the # of bytes copied afterwards
b    .customcc_inc               // go to the common custom CC incrementing, etc. code

//--------------------------------------------------------------------------------------------

.ecc_enemy_name:
push {r1-r2}
ldr  r0,=#0x2014320               // this is where current_enemy_save.asm saves the current enemy's ID #
ldrh r0,[r0,#0]                   // load the current #
cmp  r7,#0x20                     // is this the pigmask code?
bne  +
cmp  r0,#6                        // is the actor the Pork Tank?
bne  +
mov  r0,#149                      // if it is, then change it to the Pigmask
+
ldr  r2,=#0x149
cmp  r0,r2                        // If the actor id is > 0x149, it's going to be a character. Let's call them properly
blt  +

ldr  r1,=#0x2004110               // Character data address
sub  r0,r0,r2                     // Remove 0x149 to get their ID
mov  r2,#0x6C
mul  r0,r2                        // Multiply it by 0x6C, each character's data length
add  r0,#2                        // Add 2 to get their name
add  r0,r0,r1                     // r0 now has the address of the character's name
pop  {r1-r2}
bl   custom_strcopy_party         // This is a special case. We cannot use the normal strcopy because party members can have non 0xFFFF terminated names

b    .end_ecc_enemy_name

+
mov  r1,#50
mul  r0,r1                        // offset = enemy ID * 50 bytes
ldr  r1,=#{enemynames_address}+4  // this is the base address of the enemy name array in ROM
add  r0,r0,r1                     // r0 now has the address of the enemy's name
pop  {r1-r2}
bl   custom_strcopy               // r0 gets the # of bytes copied afterwards

.end_ecc_enemy_name:
b    .customcc_inc                // go to the common custom CC incrementing, etc. code

//--------------------------------------------------------------------------------------------

.ecc_cohorts:
push {r1-r3}
mov  r3,#0                   // r3 will be our total # of bytes changed


ldr  r0,=#0x2014322          // load the # of enemies
ldrb r0,[r0,#0]
cmp  r0,#1
beq  +                       // don't print anything if there's only one enemy


ldr  r0,=#0x2014322          // load the # of enemies
ldrb r0,[r0,#0]
sub  r0,#1                   // subtract one for ease of use


push {r1}                    // now we're going to print "cohort/cohorts" stuff


ldr  r1,=#0x8D0829C          // load r1 with the base address of our custom text array in ROM
mov  r2,#40
mul  r0,r2
add  r0,r0,r1                // r0 now has the address of the proper cohorts string
pop  {r1}                    // restore r1 with the target address
bl   custom_strcopy          // r0 gets the # of bytes copied afterwards
add  r3,r3,r0                // we just copied the possessive pronoun now


+
mov  r0,r3                   // r0 now has the total # of bytes we added


pop  {r1-r3}
b    .customcc_inc           // go to the common custom CC incrementing, etc. code


//--------------------------------------------------------------------------------------------

.ecc_en_articles:
push {r1-r2}

sub  r2,r0,#2                     // r2 will be an offset into the extra enemy data slot
                                  // this is a quicker method of doing a bunch of related codes at once
                                  // we take the low byte of the current CC and subtract 2, and that'll
                                  // be our offset
sub  r7,r7,#2
mov  r1,r7
lsr  r7,r7,#5
lsl  r7,r7,#5
ldr  r0,=#0x2014320               // this is where current_enemy_save.asm saves the current enemy's ID #
add  r0,r0,r7
ldrh r0,[r0,#0]                   // load the current #
cmp  r1,#0x1F                     // is this the pigmask's article code?
bne  +
mov  r2,#2                        // Change the code so it makes sense
cmp  r0,#6                        // is the actor the Pork Tank?
bne  +
mov  r0,#149                      // if it is, then change it to the Pigmask
+
mov  r1,r0
lsl  r0,r0,#3                     // offset = enemy ID * 8 bytes
ldr  r1,=#{enemy_extras_address}  // this is the base address of our extra enemy data table in ROM
add  r0,r0,r1                     // r0 now has address of this enemy's extra data entry
ldrb r0,[r0,r2]                   // r0 now has the proper line # to use from custom_text.bin
mov  r1,#40
mul  r0,r1                        // calculate the offset into custom_text.bin
ldr  r1,=#{custom_text_address}   // load r1 with the base address of our custom text array in ROM
add  r0,r0,r1                     // r0 now has the address of the string we want
pop  {r1-r2}

bl   custom_strcopy               // r0 gets the # of bytes copied afterwards
b    .customcc_inc                // go to the common custom CC incrementing, etc. code


//--------------------------------------------------------------------------------------------




.text_pointer_fix:
push {r5,lr}                 // We're going to use r5, so we need to keep it in 
ldr  r5,[sp,#0x08]           // Load r5 with our former LR value? 
mov  lr,r5                   // Move the former LR value back into LR 
ldr  r5,[sp,#0x04]           // Grab the LR value for THIS function 
str  r5,[sp,#0x08]           // Store it over the previous one 
pop  {r5}                    // Get back r5 
add  sp,#0x04                // Get the un-needed value off the stack 

add  r2,r2,r0
ldrh r0,[r2,#0]
lsl  r0,r0,#1
ldr  r1,[r1,#4]
pop  {pc}


//=============================================================================================
//This lets only 9 letters show up for the favorite food in the battle goods menu.
//=============================================================================================

.favfood_9letters:
// r4 = item address; compare with 2004F02
// r2 = item length

// old code
lsl  r2,r2,#0x10
lsr  r2,r2,#0x10

// compare, etc
ldr  r0,=#0x2004F02
cmp  r0,r4
bne  +
mov  r2,#9
+
bx   lr




















// "too many items" battle VWF
// r6 is the internal counter

.toomany_vwf1:
push {r5,lr}                 // We're going to use r5, so we need to keep it in 
ldr  r5,[sp,#0x08]           // Load r5 with our former LR value? 
mov  lr,r5                   // Move the former LR value back into LR 
ldr  r5,[sp,#0x04]           // Grab the LR value for THIS function 
str  r5,[sp,#0x08]           // Store it over the previous one 
pop  {r5}                    // Get back r5 
add  sp,#0x04                // Get the un-needed value off the stack

lsl  r1,r1,#1                // this is code we clobbered while linking here
ldr  r0,[r0,#0]
add  r0,r0,r1

//ldr  r4,=#0x3006D14

push {r5-r7}
ldr  r6,=#0x2014300          // Load r6 with the base address of our custom RAM block
ldr  r5,=#{main_font_width}  // load r5 with the address of the font width table

mov  r7,r9
cmp  r7,#0
bne  +                       // if we're on the first character, init stuff, else do main code

//--------------------------------------------------------------------------------------------
// This initializes our custom RAM block

str  r0,[r6,#0x8]            // store the base address of the string in the RAM block

mov  r0,#0x0
strh r0,[r6,#0xC]            // starting position = 0
strh r0,[r6,#0x10]           // current line = 0
strb r0,[r6,#0x12]           // newline_encountered flag = FALSE

mov  r0,#1
strb r0,[r6,#1]              // init_flag = 1, this makes the game not re-initialize everything

mov  r0,#12
strh r0,[r6,#0x4]            // start x = 12
mov  r0,#6
strh r0,[r6,#0x6]            // start y = 6

mov  r0,r10
ldrb r0,[r0,#0x6]            // [r10 + 6] has the total string length
strb r0,[r6,#0xE]            // store total length in our RAM block

bl   .word_wrap_setup        // add any newlines if text gets too long in the current string

//--------------------------------------------------------------------------------------------
// This is the meat of the code -- this is why we're doing this hack

+
ldr  r0,[r6,#0x8]            // load the base address of the string
ldrh r1,[r6,#0xC]            // load the current position in the string
lsl  r1,r1,#1                // multiply it by 2, since there are two bytes per letter
add  r0,r0,r1                // get the address for the current letter
ldrh r0,[r0,#0]              // load the current character
strh r0,[r6,#0x2]            // store the current character in our RAM block

ldr  r1,=#0xFF02
cmp  r0,r1                   // see if this is a [WAIT] code (0xFF02)
beq  .tm_set_newline
sub  r1,#0x1
cmp  r0,r1                   // see if this is a [BREAK] code (0xFF01)
beq  .tm_set_newline
lsr  r0,r0,#8                // shift right 1 byte
cmp  r0,#0xFF                // is this a control code? 
beq  .tm_move_to_next_char   // if so, manually move to the next char
b    .end_toomany_vwf1

//--------------------------------------------------------------------------------------------
// If we're executing this code, we've encountered a code that signifies a line break

.tm_set_newline:
ldrh r0,[r6,#0x10]           // load current line #
add  r0,r0,#0x1
strh r0,[r6,#0x10]           // line_num++

mov  r0,#0x1
strb r0,[r6,#0x12]           // newline_encountered flag = TRUE

.tm_move_to_next_char:
ldrh r0,[r6,#0x0C]           // load current position
add  r0,r0,#0x1              // we need to increment it manually if we're on a control code
strh r0,[r6,#0x0C]

//--------------------------------------------------------------------------------------------
// This is the end area of the code, mostly preparing to leave and doing lines we clobbered

.end_toomany_vwf1:
ldrh r1,[r6,#0x2]            // load the current character in r1, the game expects this
ldr  r0,=#0xFF32             // load r0 with FF30, which the game expects to be here

pop  {r5-r7,pc}              // time to leave!











// part 2 of the too many vwf


.toomany_vwf2:
push {r5,lr}                 // We're going to use r5, so we need to keep it in 
ldr r5,[sp,#0x08]            // Load r5 with our former LR value? 
mov lr,r5                    // Move the former LR value back into LR 
ldr r5,[sp,#0x04]            // Grab the LR value for THIS function 
str r5,[sp,#0x08]            // Store it over the previous one 
pop {r5}                     // Get back r5 
add sp,#0x04                 // Get the un-needed value off the stack

push {r5-r6}                 // we really need these registers right now

ldr  r5,=#{main_font_width}  // load r5 with the address of the font width table
ldr  r6,=#0x2014300          // Load r6 with the base address of our custom RAM block

//--------------------------------------------------------------------------------------------

bl   .process_line           // see if we need to move to a new line, and if so, do stuff accordingly

ldr  r1,[r6,#0x4]            // load the x and y coordinates into r1, these were updated by process_line
mov  r0,r4
add  r0,#0x38                // r4 + #0x38 is where the struct's coordinates are
str  r1,[r0,#0]              // store our custom coordinates in the struct

ldr  r1,=#0xFF00
ldrh r0,[r6,#0x2]            // load the current character
cmp  r0,r1                   // if it's a control code, width = 0
blt  +

mov  r0,#0
b    .tm_load_width

+
add  r0,r0,r5                // get the address of the current character's width
ldrb r0,[r0,#0]              // load the current character's width

.tm_load_width:
ldrh r1,[r6,#0x4]            // load the current x coordinate
add  r0,r0,r1                // x = x + width_of_current_character
strh r0,[r6,#0x4]            // store the new x coordinate into our RAM block, will be used next call
                             // even if the current character is a control code, we'll still catch it
                             // later and correct it, so it's okay if it gets something crazy here

ldr  r1,[r6,#0x4]            // load the x and y coordinates into r1
mov  r0,r4
str  r1,[r0,#0x44]           // store the next char's location in the location where the next erase is

ldrh r0,[r6,#0xC]            // load our current char position
add  r0,#1                   // increment our current char position
strh r0,[r6,#0xC]            // store it back in our RAM block

ldrh r1,[r6,#0xE]            // load r1 with the total length of this string
cmp  r0,r1                   // see if current character count >= the length of this string
bcc  .end_toomany_vwf2       // go to the last part of our code if we're under the total length

mov  r0,#0                   // set init_flag to 0 so that things here will get re-initialized next string
strb r0,[r6,#1]

//--------------------------------------------------------------------------------------------
// This stuff basically gets everything ready before leaving this hack

.end_toomany_vwf2:
ldrh r1,[r6,#0x2]            // load r1 with the current character, the game expects this

pop  {r5-r6}                 // get the original values back in these registers

mov  r0,#0
strh r0,[r6,#0x2A]           // make the game think we're always on line 0
strh r0,[r6,#0x2C]           // make the game think we're on character 0 always

ldr  r2,[r5,#0x4]            // another clobbered line
mov  r0,r4                   // and another

pop  {pc}                    // time to leave!





.toomany_vwf_clear_window:
push {r5,lr}                 // We're going to use r5, so we need to keep it in 
ldr  r5,[sp,#0x08]           // Load r5 with our former LR value? 
mov  lr,r5                   // Move the former LR value back into LR 
ldr  r5,[sp,#0x04]           // Grab the LR value for THIS function 
str  r5,[sp,#0x08]           // Store it over the previous one 
pop  {r5}                    // Get back r5 
add  sp,#0x04                // Get the un-needed value off the stack

push {r0-r3}

mov  r0,#0
push {r0}
mov  r0,sp

ldr  r1,=#0x6000000
ldr  r2,=#0x800

mov  r3,#1
lsl  r3,r3,#24
orr  r2,r3                   // set the 24th bit of r2 so it'll know to fill instead of copy
swi  #0x0B                   // clear old data out

pop  {r0}
pop  {r0-r3}

mov  r8,r3                   // clobbered code
mov  r9,r4
mov  r10,r5

pop  {pc}                    // time to leave!


















.3line_vwf1:
push {r5,lr}                 // We're going to use r5, so we need to keep it in 
ldr r5,[sp,#0x08]            // Load r5 with our former LR value? 
mov lr,r5                    // Move the former LR value back into LR 
ldr r5,[sp,#0x04]            // Grab the LR value for THIS function 
str r5,[sp,#0x08]            // Store it over the previous one 
pop {r5}                     // Get back r5 
add sp,#0x04                 // Get the un-needed value off the stack

lsl  r1,r1,#1                // this is code we clobbered while linking here
ldr  r0,[r0,#0]
add  r0,r0,r1

push {r5-r6}
ldr  r6,=#0x2014300          // Load r6 with the base address of our custom RAM block
ldr  r5,=#{main_font_width}  // load r5 with the address of the font width table

cmp  r7,#0
bne  +                       // if we're on the first character, init stuff, else do main code

//--------------------------------------------------------------------------------------------
// This initializes our custom RAM block

str  r0,[r6,#0x8]            // store the base address of the string in the RAM block

mov  r0,#0x0
strh r0,[r6,#0xC]            // starting position = 0
strh r0,[r6,#0x10]           // current line = 0
strb r0,[r6,#0x12]           // newline_encountered flag = FALSE

mov  r0,#1
strb r0,[r6,#1]              // init_flag = 1, this makes the game not re-initialize everything

mov  r0,#12
strh r0,[r6,#0x4]            // start x = 12
mov  r0,#6
strh r0,[r6,#0x6]            // start y = 6

mov  r0,r8
ldrb r0,[r0,#0x6]            // [r8 + 6] has the total string length
strb r0,[r6,#0xE]            // store total length in our RAM block

bl   .word_wrap_setup        // add any newlines if text gets too long in the current string

//--------------------------------------------------------------------------------------------
// This is the meat of the code -- this is why we're doing this hack

+
ldr  r0,[r6,#0x8]            // load the base address of the string
ldrh r1,[r6,#0xC]            // load the current position in the string
lsl  r1,r1,#1                // multiply it by 2, since there are two bytes per letter
add  r0,r0,r1                // get the address for the current letter
ldrh r0,[r0,#0]              // load the current character
strh r0,[r6,#0x2]            // store the current character in our RAM block

ldr  r1,=#0xFF02
cmp  r0,r1                   // see if this is a [WAIT] code (0xFF02)
beq  .3l_set_newline
sub  r1,#0x1
cmp  r0,r1                   // see if this is a [BREAK] code (0xFF01)
beq  .3l_set_newline
lsr  r0,r0,#8                // shift right 1 byte
cmp  r0,#0xFF                // is this a control code? 
beq  .3l_move_to_next_char   // if so, manually move to the next char
b    .end_3l_vwf1

//--------------------------------------------------------------------------------------------
// If we're executing this code, we've encountered a code that signifies a line break

.3l_set_newline:
ldrh r0,[r6,#0x10]           // load current line #
add  r0,r0,#0x1
strh r0,[r6,#0x10]           // line_num++

mov  r0,#0x1
strb r0,[r6,#0x12]           // newline_encountered flag = TRUE

.3l_move_to_next_char:
ldrh r0,[r6,#0x0C]           // load current position
add  r0,r0,#0x1              // we need to increment it manually if we're on a control code
strh r0,[r6,#0x0C]

//--------------------------------------------------------------------------------------------
// This is the end area of the code, mostly preparing to leave and doing lines we clobbered

.end_3l_vwf1:
ldrh r1,[r6,#0x2]            // load the current character in r1, the game expects this
ldr  r0,=#0xFF30             // load r0 with FF30, which the game expects to be here

pop  {r5-r6,pc}              // time to leave!











.3line_vwf2:
push {r5,lr}                 // We're going to use r5, so we need to keep it in 
ldr  r5,[sp,#0x08]           // Load r5 with our former LR value? 
mov  lr,r5                   // Move the former LR value back into LR 
ldr  r5,[sp,#0x04]           // Grab the LR value for THIS function 
str  r5,[sp,#0x08]           // Store it over the previous one 
pop  {r5}                    // Get back r5 
add  sp,#0x04                // Get the un-needed value off the stack

push {r5-r6}                 // we really need these registers right now

ldr  r5,=#{main_font_width}  // load r5 with the address of the font width table
ldr  r6,=#0x2014300          // Load r6 with the base address of our custom RAM block

//--------------------------------------------------------------------------------------------

bl   .3l_process_line        // see if we need to move to a new line, and if so, do stuff accordingly

ldr  r1,[r6,#0x4]            // load the x and y coordinates into r1, these were updated by process_line
mov  r0,r4
add  r0,#0x38                // r4 + #0x38 is where the struct's coordinates are
str  r1,[r0,#0]              // store our custom coordinates in the struct

ldrh r0,[r6,#0x2]            // load the current character
add  r0,r0,r5                // get the address of the current character's width
ldrb r0,[r0,#0]              // load the current character's width

ldrh r1,[r6,#0x4]            // load the current x coordinate
add  r0,r0,r1                // x = x + width_of_current_character
strh r0,[r6,#0x4]            // store the new x coordinate into our RAM block, will be used next call
                             // even if the current character is a control code, we'll still catch it
                             // later and correct it, so it's okay if it gets something crazy here

ldr  r1,[r6,#0x4]            // load the x and y coordinates into r1
mov  r0,r4
str  r1,[r0,#0x44]           // store the next char's location in the location where the next erase is

ldrh r0,[r6,#0xC]            // load our current char position
add  r0,#1                   // increment our current char position
strh r0,[r6,#0xC]            // store it back in our RAM block

ldrh r1,[r6,#0xE]            // load r1 with the total length of this string
cmp  r0,r1                   // see if current character count >= the length of this string
bcc  .end_3l_vwf2            // go to the last part of our code if we're under the total length

mov  r0,#0                   // set init_flag to 0 so that things here will get re-initialized next string
strb r0,[r6,#1]

//--------------------------------------------------------------------------------------------
// This stuff basically gets everything ready before leaving this hack

.end_3l_vwf2:
ldrh r1,[r6,#0x2]            // load r1 with the current character, the game expects this

pop  {r5-r6}                 // get the original values back in these registers

mov  r0,#0
strh r0,[r6,#0x2A]           // make the game think we're always on line 0
strh r0,[r6,#0x2C]           // make the game think we're on character 0 always

ldr  r2,[r5,#0x4]            // another clobbered line
mov  r0,r4                   // and another

pop  {pc}                    // time to leave!




//=============================================================================================
//---------------------------------------------------------------------------------------------
// This routine determines if we're on Line 3 or higher, and if we are, recorrect stuff
// and reposition coordinates to be at the proper place
//
//    r0 has the current line # when this function is called

.3l_process_line:
ldrb r1,[r6,#0x12]           // load newline_encountered_flag
cmp  r1,#0                   // compare it to 0
beq  .3l_end_process_line    // don't do any of this code if it's set to FALSE

ldrh r0,[r6,#0x10]           // check current line #
cmp  r0,#3
bcc  +                       // don't scroll if don't need to

mov  r0,#2
strh r0,[r6,#0x10]           // set us back to Line #1
push {lr}
bl   .3l_move_text_up        // hand-coded text scrolling routine to move text up
pop  {r1}
mov  lr,r1

+
mov  r1,#11
mul  r0,r1
add  r0,#6                   // y = line * 11 + init_y (do init_y stuff later)
strh r0,[r6,#0x6]            // store the new y in our RAM block
mov  r0,#12                  // x = 12
strh r0,[r6,#0x4]            // store the new x in our RAM block

mov  r0,#0x0
mov  r1,r4
add  r1,#0x30
strb r0,[r1,#0]              // sets the "display this glyph" flag in the current struct

.3l_end_process_line:
mov  r0,#0
strb r0,[r6,#0x12]           // set newline_encountered flag to FALSE

bx   lr



.3l_move_text_up:
push {r0-r6,lr}

mov  r3,#0                   // r3 = 0 so we can easily clear crap out
mov  r1,#0                   // r1 is gonna be our loop counter

-
ldr  r5,=#0x6000018          // r5 is our address in tile memory for the top line of text
ldr  r6,=#0x6000804          // r6 is our address in tile memory for the bottom line of text
lsl  r0,r1,#5                // r0 = r1 * 0x20, a quick way to multiply rather than use mul
add  r5,r5,r0                // this gets us the tiles to use based on the loop counter #
add  r6,r6,r0

ldr  r0,[r6,#0]              // get first pixel row of bottom line
str  r0,[r5,#0]              // copy the pixel row to the first pixel row of the top line
str  r3,[r6,#0]              // clear out first pixel row of bottom line

ldr  r0,[r6,#0x4]            // get second pixel row of bottom line
str  r0,[r5,#0x4]            // copy the pixel row to the second pixel row of the top line
str  r3,[r6,#0x4]            // clear out second pixel row of bottom line

ldr  r5,=#0x6000400          // now we're doing the next section, which is the bulk of the stuff
ldr  r6,=#0x600080C          // 
lsl  r0,r1,#5                // r0 = r1 * 0x20, a quick way to multiply rather than use mul
add  r5,r5,r0                // this gets us the tiles to use based on the loop counter #
add  r6,r6,r0

ldr  r0,[r6,#0]              // row 3
str  r0,[r5,#0]
str  r3,[r6,#0]

ldr  r0,[r6,#0x4]            // row 4
str  r0,[r5,#0x4]
str  r3,[r6,#0x4]

ldr  r0,[r6,#0x8]            // row 5
str  r0,[r5,#0x8]
str  r3,[r6,#0x8]

ldr  r0,[r6,#0xC]            // row 6
str  r0,[r5,#0xC]
str  r3,[r6,#0xC]

ldr  r0,[r6,#0x10]           // row 7
str  r0,[r5,#0x10]
str  r3,[r6,#0x10]

ldr  r5,=#0x6000414          // now we're doing the next section
ldr  r6,=#0x6000C00
lsl  r0,r1,#5                // r0 = r1 * 0x20, a quick way to multiply rather than use mul
add  r5,r5,r0                // this gets us the tiles to use based on the loop counter #
add  r6,r6,r0

ldr  r0,[r6,#0]              // row 8
str  r0,[r5,#0]
str  r3,[r6,#0]

ldr  r0,[r6,#0x4]            // row 9
str  r0,[r5,#0x4]
str  r3,[r6,#0x4]

ldr  r0,[r6,#0x8]            // row 10
str  r0,[r5,#0x8]
str  r3,[r6,#0x8]

ldr  r5,=#0x6000800          // now we're doing the final section, which is just one row
ldr  r6,=#0x6000C0C
lsl  r0,r1,#5                // r0 = r1 * 0x20, a quick way to multiply rather than use mul
add  r5,r5,r0                // this gets us the tiles to use based on the loop counter #
add  r6,r6,r0

ldr  r0,[r6,#0]              // row 11
str  r0,[r5,#0]
str  r3,[r6,#0]



// third line to second line
ldr  r5,=#0x6000804          // r5 is our address in tile memory for the top line of text
ldr  r6,=#0x6000C10          // r6 is our address in tile memory for the bottom line of text
lsl  r0,r1,#5                // r0 = r1 * 0x20, a quick way to multiply rather than use mul
add  r5,r5,r0                // this gets us the tiles to use based on the loop counter #
add  r6,r6,r0

ldr  r0,[r6,#0]              // get first pixel row of bottom line
str  r0,[r5,#0]              // copy the pixel row to the first pixel row of the top line
str  r3,[r6,#0]              // clear out first pixel row of bottom line

ldr  r0,[r6,#0x4]            // row 2
str  r0,[r5,#0x4]
str  r3,[r6,#0x4]

ldr  r0,[r6,#0x8]            // row 3
str  r0,[r5,#0x8]
str  r3,[r6,#0x8]

ldr  r0,[r6,#0xC]            // row 4
str  r0,[r5,#0xC]
str  r3,[r6,#0xC]

ldr  r6,=#0x6001000
lsl  r0,r1,#5                // r0 = r1 * 0x20, a quick way to multiply rather than use mul
add  r6,r6,r0
ldr  r0,[r6,#0x0]            // row 5
str  r0,[r5,#0x10]
str  r3,[r6,#0x0]

ldr  r0,[r6,#0x4]            // row 6
str  r0,[r5,#0x14]
str  r3,[r6,#0x4]

ldr  r0,[r6,#0x8]            // row 7
str  r0,[r5,#0x18]
str  r3,[r6,#0x8]

ldr  r5,=#0x6000C00
lsl  r0,r1,#5                // r0 = r1 * 0x20, a quick way to multiply rather than use mul
add  r5,r5,r0
ldr  r0,[r6,#0xC]            // row 8
str  r0,[r5,#0x0]
str  r3,[r6,#0xC]

ldr  r0,[r6,#0x10]           // row 9
str  r0,[r5,#0x4]
str  r3,[r6,#0x10]

ldr  r0,[r6,#0x14]           // row 10
str  r0,[r5,#0x8]
str  r3,[r6,#0x14]

ldr  r0,[r6,#0x18]           // row 11
str  r0,[r5,#0xC]
str  r3,[r6,#0x18]

add  r1,#1
cmp  r1,#0x1E
bge  +
b    -                       // r1++, if r1 < 1E (# of tiles wide the screen is) then loop back

+
pop {r0-r6,pc}




.3line_vwf_clear_window:
push {r0-r3}

mov  r0,#0
push {r0}
mov  r0,sp

ldr  r1,=#0x6000000
ldr  r2,=#0x1000

mov  r3,#1
lsl  r3,r3,#24
orr  r2,r3                   // set the 24th bit of r2 so it'll know to fill instead of copy
swi  #0x0B                   // clear old data out

pop  {r0}
pop  {r0-r3}

pop  {r3}                    // clobbered code
mov  r8,r3
bx   lr













.finalbattle_vwf1:
push {r5,lr}                 // We're going to use r5, so we need to keep it in 
ldr r5,[sp,#0x08]            // Load r5 with our former LR value? 
mov lr,r5                    // Move the former LR value back into LR 
ldr r5,[sp,#0x04]            // Grab the LR value for THIS function 
str r5,[sp,#0x08]            // Store it over the previous one 
pop {r5}                     // Get back r5 
add sp,#0x04                 // Get the un-needed value off the stack

lsl  r1,r1,#1                // this is code we clobbered while linking here
ldr  r0,[r0,#0]
add  r0,r0,r1

push {r5-r7}
mov  r7,r6
ldr  r6,=#0x2014300          // Load r6 with the base address of our custom RAM block
ldr  r5,=#{main_font_width}  // load r5 with the address of the font width table

cmp  r7,#0
bne  +                       // if we're on the first character, init stuff, else do main code

//--------------------------------------------------------------------------------------------
// This initializes our custom RAM block

mov  r4,r3
str  r0,[r6,#0x8]            // store the base address of the string in the RAM block

mov  r0,#0x0
strh r0,[r6,#0xC]            // starting position = 0
strh r0,[r6,#0x10]           // current line = 0
strb r0,[r6,#0x12]           // newline_encountered flag = FALSE

mov  r0,#1
strb r0,[r6,#1]              // init_flag = 1, this makes the game not re-initialize everything

ldr  r0,[sp,#0x30]
ldrh r0,[r0,#6]              // r0 now has the total string length
strb r0,[r6,#0xE]            // store total length in our RAM block

lsl  r1,r0,#1                
ldr  r0,[r6,#0x8]            // load the string address
add  r1,r0,r1                // r1 = end of string address
bl   get_special_width
lsr  r0,r0,#1
mov  r1,#120
sub  r0,r1,r0

//ldrh r0,[r4,#0x38]
//mov  r0,#12
strh r0,[r6,#0x4]            // start x
//ldrh r0,[r4,#0x3A]
mov  r0,#46
strh r0,[r6,#0x6]            // start y

ldr  r0,[sp,#0x30]
ldrh r0,[r0,#6]              // r0 now has the total string lengthy
strb r0,[r6,#0xE]            // store total length in our RAM block

//bl   .word_wrap_setup        // add any newlines if text gets too long in the current string

//--------------------------------------------------------------------------------------------
// This is the meat of the code -- this is why we're doing this hack

+
ldr  r0,[r6,#0x8]            // load the base address of the string
ldrh r1,[r6,#0xC]            // load the current position in the string
lsl  r1,r1,#1                // multiply it by 2, since there are two bytes per letter
add  r0,r0,r1                // get the address for the current letter
ldrh r0,[r0,#0]              // load the current character
strh r0,[r6,#0x2]            // store the current character in our RAM block

ldr  r1,=#0xFF02
cmp  r0,r1                   // see if this is a [WAIT] code (0xFF02)
beq  .fb_set_newline
sub  r1,#0x1
cmp  r0,r1                   // see if this is a [BREAK] code (0xFF01)
beq  .fb_set_newline
lsr  r0,r0,#8                // shift right 1 byte
cmp  r0,#0xFF                // is this a control code? 
beq  .fb_move_to_next_char   // if so, manually move to the next char
b    .end_fb_vwf1

//--------------------------------------------------------------------------------------------
// If we're executing this code, we've encountered a code that signifies a line break

.fb_set_newline:
ldrh r0,[r6,#0x10]           // load current line #
add  r0,r0,#0x1
strh r0,[r6,#0x10]           // line_num++

mov  r0,#0x1
strb r0,[r6,#0x12]           // newline_encountered flag = TRUE

.fb_move_to_next_char:
ldrh r0,[r6,#0x0C]           // load current position
add  r0,r0,#0x1              // we need to increment it manually if we're on a control code
strh r0,[r6,#0x0C]

//--------------------------------------------------------------------------------------------
// This is the end area of the code, mostly preparing to leave and doing lines we clobbered

.end_fb_vwf1:
ldr  r1,=#0x5000003
mov  r0,#0x7C
strb r0,[r1,#0]              // turn palette purple for test purposes



ldrh r1,[r6,#0x2]            // load the current character in r1, the game expects this
ldr  r0,=#0xFF30             // load r0 with FF30, which the game expects to be here

pop  {r5-r7,pc}              // time to leave!







.finalbattle_vwf2:
push {r5,lr}                 // We're going to use r5, so we need to keep it in 
ldr r5,[sp,#0x08]            // Load r5 with our former LR value? 
mov lr,r5                    // Move the former LR value back into LR 
ldr r5,[sp,#0x04]            // Grab the LR value for THIS function 
str r5,[sp,#0x08]            // Store it over the previous one 
pop {r5}                     // Get back r5 
add sp,#0x04                 // Get the un-needed value off the stack

push {r5-r6}                 // we really need these registers right now

ldr  r5,=#{main_font_width}  // load r5 with the address of the font width table
ldr  r6,=#0x2014300          // Load r6 with the base address of our custom RAM block

//--------------------------------------------------------------------------------------------

bl   .fb_process_line        // see if we need to move to a new line, and if so, do stuff accordingly

ldr  r1,[r6,#0x4]            // load the x and y coordinates into r1, these were updated by process_line
mov  r0,r4
add  r0,#0x38                // r4 + #0x38 is where the struct's coordinates are
str  r1,[r0,#0]              // store our custom coordinates in the struct

ldrh r0,[r6,#0x2]            // load the current character
add  r0,r0,r5                // get the address of the current character's width
ldrb r0,[r0,#0]              // load the current character's width

ldrh r1,[r6,#0x4]            // load the current x coordinate
add  r0,r0,r1                // x = x + width_of_current_character
strh r0,[r6,#0x4]            // store the new x coordinate into our RAM block, will be used next call
                             // even if the current character is a control code, we'll still catch it
                             // later and correct it, so it's okay if it gets something crazy here

ldr  r1,[r6,#0x4]            // load the x and y coordinates into r1
mov  r0,r4
str  r1,[r0,#0x44]           // store the next char's location in the location where the next erase is

ldrh r0,[r6,#0xC]            // load our current char position
add  r0,#1                   // increment our current char position
strh r0,[r6,#0xC]            // store it back in our RAM block

ldrh r1,[r6,#0xE]            // load r1 with the total length of this string
cmp  r0,r1                   // see if current character count >= the length of this string
bcc  .end_fb_vwf2            // go to the last part of our code if we're under the total length

mov  r0,#0                   // set init_flag to 0 so that things here will get re-initialized next string
strb r0,[r6,#1]

//--------------------------------------------------------------------------------------------
// This stuff basically gets everything ready before leaving this hack

.end_fb_vwf2:
ldrh r1,[r6,#0x2]            // load r1 with the current character, the game expects this

pop  {r5-r6,pc}              // get the original values back in these registers




.fb_process_line:
push {lr}
ldrb r1,[r6,#0x12]           // load newline_encountered_flag
cmp  r1,#0                   // compare it to 0
beq  .fb_end_process_line    // don't do any of this code if it's set to FALSE

ldrh r0,[r6,#0x6]            // load current y, add 11
add  r0,#12
strh r0,[r6,#0x6]            // store the new y in our RAM block

ldr  r0,[r6,#0x8]            // load current string's address
ldrh r1,[r6,#0xC]            // load current position in string
lsl  r1,r1,#1
add  r0,r0,r1

push {r0}
ldr  r0,[r6,#0x8]
ldrh r1,[r6,#0xE]
lsl  r1,r1,#1
add  r1,r0,r1                // r1 has the end address
pop  {r0}                    // r0 has the current address

bl   get_special_width
lsr  r0,r0,#1
mov  r1,#120
sub  r0,r1,r0
strh r0,[r6,#0x4]            // store the new x in our RAM block

mov  r0,#0x0
mov  r1,r4
add  r1,#0x30
strb r0,[r1,#0]              // sets the "display this glyph" flag in the current struct

.fb_end_process_line:
mov  r0,#0
strb r0,[r6,#0x12]           // set newline_encountered flag to FALSE

pop  {pc}




.finalbattle_vwf_clear_window:
push {r0-r3}

mov  r0,#0
push {r0}
mov  r0,sp

ldr  r1,=#0x6000000
ldr  r2,=#0x2800

mov  r3,#1
lsl  r3,r3,#24
orr  r2,r3                   // set the 24th bit of r2 so it'll know to fill instead of copy
swi  #0x0B                   // clear old data out

pop  {r0}
pop  {r0-r3}


add  sp,#0x30                // clobbered code
pop  {r3-r5}
bx   lr


//=============================================================================================
// This is the hard-coded text arrangement for item stealing text. This hack re-arranges it to
// make sense.
//=============================================================================================

.item_steal_text:
// Screwing up the stack pointer here causes major problems, so we need to
// store LR into RAM
push {r1}
ldr  r0,=#0x203FFEC
mov  r1,lr
str  r1,[r0,#0]
pop  {r1}
//-----------------------------------------------
// Mystery stuff
mov     r0,r9
bl      $806E274
ldr     r5,[sp,#0xB8]
//-----------------------------------------------
// Load line 0x372 of the battle text ("In the confusion, ...")
ldr     r3,[r5,#0x1C]
mov     r4,#0xA8
lsl     r4,r4,#0x1
add     r3,r3,r4
mov     r0,#0x0
ldsh    r1,[r3,r0]
ldr     r2,=#0x372
mov     r0,r7
ldr     r3,[r3,#0x4]
add     r1,r5,r1
bl      $8091940
mov     r0,r9
mov     r1,r7
bl      $806E374
mov     r0,r7
mov     r1,#0x2
bl      $806E308
//-----------------------------------------------
// Before we go on, store the item number to 2014324
ldr  r3,=#0x2014324
ldr  r2,[sp,#8]
ldrh r2,[r2,#0]
strh r2,[r3,#0]
//-----------------------------------------------
// Load line 0x373 ("stole a [10 FF]!")
ldr     r3,[r5,#0x1C]
add     r3,r3,r4
mov     r2,#0x0
ldsh    r1,[r3,r2]
ldr     r2,=#0x373
mov     r0,r7
ldr     r3,[r3,#0x4]
add     r1,r5,r1
bl      $8091940
mov     r0,r9
mov     r1,r7
bl      $806E374
mov     r0,r7
mov     r1,#0x2
bl      $806E308
//-----------------------------------------------
// Load the number of the item that gets stolen
ldr     r0,[sp,#0x8]
ldrh    r1,[r0,#0]
//-----------------------------------------------
// Do some stuff stuff with the item number
mov     r0,r10
mov     r2,r8
mov     r3,#0x0
bl      $80649AC
mov     r0,r7
mov     r1,r10
bl      $8064B30
mov     r0,r9
mov     r1,r7
bl      $806E374
mov     r0,r7
mov     r1,#0x2
bl      $806E308
//-----------------------------------------------
// Still related to items?
mov     r0,r10
mov     r1,#0x2
bl      $80649E8
//-----------------------------------------------
// Load line 0x3BC ("!")
ldr     r3,[r5,#0x1C]
add     r3,r3,r4
mov     r2,#0x0
ldsh    r1,[r3,r2]
ldr     r2,=#0x3BC
mov     r0,r7
ldr     r3,[r3,#0x4]
add     r1,r5,r1
bl      $8091940
mov     r0,r9
mov     r1,r7
bl      $806E374
mov     r0,r7
mov     r1,#0x2
bl      $806E308
//-----------------------------------------------
// Done
push {r1}
ldr  r3,=#0x203FFEC
ldr  r1,[r3,#0]
mov  lr,r1
pop  {r1}
mov  pc,lr


//=============================================================================================
// This is the hard-coded item steal text for the Mystery Metal Monkey.
//=============================================================================================

.item_steal_text2:
// Screwing up the stack pointer here causes major problems, so we need to
// store LR into RAM
push {r1}
ldr  r0,=#0x203FFEC
mov  r1,lr
str  r1,[r0,#0]
pop  {r1}
//-----------------------------------------------
// Mystery stuff
mov     r0,r10
bl      $806E274
ldr     r5,[sp,#0xB4]
//-----------------------------------------------
// Load line 0x44F ("[11 FF] attacked, and then...")
ldr     r3,[r5,#0x1C]
mov     r4,#0xA8
lsl     r4,r4,#1
add     r3,r3,r4
mov     r0,#0
ldsh    r1,[r3,r0]
ldr     r2,=#0x44F
mov     r0,r8
ldr     r3,[r3,#4]
add     r1,r5,r1
bl      $8091940
mov     r0,r10
mov     r1,r8
bl      $806E374
mov     r0,r8
mov     r1,#2
bl      $806E308
//-----------------------------------------------
// Before we go on, store the item number to 2014324
ldr  r3,=#0x2014324
ldr  r2,[sp,#8]
ldrh r2,[r2,#0]
strh r2,[r3,#0]
//-----------------------------------------------
// Load line 0x373 ("stole [11 FF]")
ldr     r3,[r5,#0x1C]
add     r3,r3,r4
mov     r2,#0
ldsh    r1,[r3,r2]
ldr     r2,=#0x373
mov     r0,r8
ldr     r3,[r3,#4]
add     r1,r5,r1
bl      $8091940
mov     r0,r10
mov     r1,r8
bl      $806E374
mov     r0,r8
mov     r1,#2
bl      $806E308
//-----------------------------------------------
// Do some stuff stuff with the item number
ldr     r0,[sp,#8]
ldrh    r1,[r0,#0]
mov     r0,r9
mov     r2,r7
mov     r3,#0
bl      $80649AC
mov     r0,r8
mov     r1,r9
bl      $8064B30
mov     r0,r10
mov     r1,r8
bl      $806E374
mov     r0,r8
mov     r1,#2
bl      $806E308
mov     r0,r9
mov     r1,#2
bl      $80649E8
//-----------------------------------------------
// Load line 0x3BC ("!")
ldr     r3,[r5,#0x1C]
add     r3,r3,r4
mov     r2,#0x0
ldsh    r1,[r3,r2]
ldr     r2,=#0x3BC
mov     r0,r8
ldr     r3,[r3,#0x4]
add     r1,r5,r1
bl      $8091940
mov     r0,r10
mov     r1,r8
bl      $806E374
mov     r0,r8
mov     r1,#0x2
bl      $806E308
//-----------------------------------------------
// Done
push {r1}
ldr  r3,=#0x203FFEC
ldr  r1,[r3,#0]
mov  lr,r1
pop  {r1}
mov  pc,lr


//=============================================================================================
// This fixes Duster's attack sound bug.
//=============================================================================================
.duster_fix:
push    {lr}

// Call the normal battle code, should work fine for Duster
push    {r0-r3}
bl      $807C1E4
pop     {r0-r3}

// Clobbered code
bl      $8072628

pop     {pc}

//=============================================================================================
// Checks if enemy could be damaged. If it cannot, it displays total damage as 0. Fix for when Porky inside the absolute safety capsule is comboed.
//=============================================================================================
.fix_total_damage:
push {r0,lr}
push {r1-r3}
ldr  r3,[sp,#0x94]
ldr  r1,[r3,#0x1C]
mov  r0,#0xA8
lsl  r0,r0,#2
add  r1,r1,r0
mov  r2,#0
ldsh r0,[r1,r2]
add  r0,r3,r0
ldr  r2,[r1,#4]
mov  r1,#0x30
bl   $809193C
lsl  r0,r0,#0x18
lsr  r0,r0,#0x18
pop  {r1-r3}
cmp  r0,#1                   // If this is 1, then the enemy takes 0 damage
bne  +
mov  r1,#0
+
strh r5,[r2,#0]
strh r3,[r2,#2]
pop  {r0,pc}

//=============================================================================================
// New current enemy saving hacks. In m3hacks.asm there are descriptions about what is what
//=============================================================================================
.costant_save:               // A piece of code every one of these hacks besides SP shares
push {lr}
push {r2}
mov  r4,#1
lsl  r4,r4,#27               // Is this an enemy? If they are, then they have their identifiers in the ROM
add  r1,#0xFC
ldr  r1,[r1,#0]
ldrb r2,[r1,#0]
cmp  r1,r4
bge  +
ldr  r1,=#0x149
add  r2,r2,r1                // Character's articles are at enemy_extras + 0x149
+
mov  r1,r2                   // Keep this in r1 in case the other functions want to do stuff with it
ldr  r4,=#0x2014320          // this is the address where we'll store the current enemy's value
strh r1,[r4,#0]              // store the value. How easy!
pop  {r2}
pop  {pc}

.costant_save_target:        // A piece of code for the target of the action
push {lr}
push {r2}
mov  r4,#1
lsl  r4,r4,#27               // Is this an enemy? If they are, then they have their identifiers in the ROM
add  r1,#0xFC
ldr  r1,[r1,#0]
ldrb r2,[r1,#0]
cmp  r1,r4
bge  +
ldr  r1,=#0x149
add  r2,r2,r1                // Character's articles are at enemy_extras + 0x149
+
mov  r1,r2                   // Keep this in r1 in case the other functions want to do stuff with it
ldr  r4,=#0x2014360          // this is the address where we'll store the current target's value
strh r1,[r4,#0]              // store the value. How easy!
pop  {r2}
pop  {pc}

.base_saving_enemy:          // Saves the phrase protagonist. r0 has the address
push {lr}
push {r1-r4}
mov  r1,r0                   // r0 has the base address of the main character in the phrase
bl   .costant_save
pop  {r1-r4}
pop  {pc}

.base_saving_target:         // Saves the phrase target. r0 has the address
push {lr}
push {r1-r4}
mov  r1,r0                   // r0 has the base address of the main character in the phrase
bl   .costant_save_target
pop  {r1-r4}
pop  {pc}

.base_saving_enemy_2:        // Saves the phrase protagonist. r1 already has the address
push {lr}
push {r1-r4}
bl   .costant_save
pop  {r1-r4}
pop  {pc}

.base_saving_enemy_3:        // Saves the phrase protagonist. r7 has the address
push {lr}
push {r1-r4}
mov  r1,r7                   // r0 has the base address of the main character in the phrase
bl   .costant_save
pop  {r1-r4}
pop  {pc}

.base_saving_enemy_SP:       // Saves the old phrase protagonist
push {lr}
push {r1-r4}
ldr  r4,=#0x2014320          // this is the address where we'll store the previous current enemy's value
ldrh r1,[r4,#0]              // Load the value. How easy!
add  r4,#0x20                // The new place for the value
strh r1,[r4,#0]              // store the value. How easy!
pop  {r1-r4}
pop  {pc}

.base_saving_enemy_Dual:     // Saves both the new and the old phrase protagonists. r1 already contains the address
push {lr}
push {r1-r4}
mov  r1,r0
bl   .costant_save
add  r4,#0x20
strh r1,[r4,#0]
pop  {r1-r4}
pop  {pc}

.base_saving_enemy_2_Dual:   // Saves both the new and the old phrase protagonists. r1 already contains the address
push {lr}
push {r1-r4}
bl   .costant_save
add  r4,#0x20
strh r1,[r4,#0]
pop  {r1-r4}
pop  {pc}

.base_saving_enemy_3_Dual:   // Saves both the new and the old phrase protagonists. r7 has the address
push {lr}
push {r1-r4}
mov  r1,r7                   // r7 has the base address of the main character in the phrase
bl   .costant_save
add  r4,#0x20
strh r1,[r4,#0]
pop  {r1-r4}
pop  {pc}

.base_saving_enemy_4_Dual:   // Saves both the new and the old phrase protagonists. r5 has the address
push {lr}
push {r1-r4}
mov  r1,r5                   // r5 has the base address of the main character in the phrase
bl   .costant_save
add  r4,#0x20
strh r1,[r4,#0]
pop  {r1-r4}
pop  {pc}

.save_current_enemy_1:
push {lr}
bl   .base_saving_enemy
mov  r4,r0
ldr  r1,[r4,#0x1C]
pop  {pc}

.save_current_enemy_2:
push {lr}
bl   .base_saving_enemy
mov  r5,r0
mov  r4,r1
pop  {pc}

.save_current_enemy_3:
push {lr}
bl   .base_saving_enemy
mov  r7,r0
mov  r6,r1
pop  {pc}

.save_current_enemy_4:
push {lr}
bl   .base_saving_enemy
mov  r4,r0
lsl  r1,r1,#0x10
pop  {pc}

.save_current_enemy_5:
push {lr}
bl   .base_saving_enemy
mov  r6,r0
mov  r4,r1
pop  {pc}

.save_current_enemy_6:
push {lr}
bl   .base_saving_enemy
mov  r7,r0
bl   $8072778
pop  {pc}

.save_current_enemy_7:
push {lr}
bl   .base_saving_enemy_2
mov  r4,r0
mov  r5,r1
pop  {pc}

.save_current_enemy_8:
push {lr}
bl   .base_saving_enemy
mov  r7,r0
mov  r0,#0
pop  {pc}

.save_current_enemy_9:
push {lr}
bl   .base_saving_enemy_SP
mov  r1,r0
ldr  r2,[r1,#0x1C]
pop  {pc}

.save_current_enemy_10:
push {lr}
bl   .base_saving_enemy_2_Dual
mov  r7,r10
mov  r6,r9
pop  {pc}

.save_current_enemy_11:
push {lr}
bl   .base_saving_enemy_2_Dual
mov  r1,r0
ldr  r2,[r1,#0x1C]
pop  {pc}

.save_current_enemy_12:
push {lr}
bl   .base_saving_enemy_2_Dual
mov  r5,r0
mov  r0,r1
pop  {pc}

.save_current_enemy_13:
push {lr}
bl   .base_saving_enemy_3_Dual
mov  r5,r0
ldr  r1,[r5,#0x1C]
pop  {pc}

.save_current_enemy_14:
push {lr}
bl   .base_saving_enemy_3
mov  r7,r0
ldr  r1,[r7,#0x1C]
pop  {pc}

.save_current_enemy_15:
push {lr}
bl   .base_saving_enemy_Dual
mov  r0,r1
ldr  r1,[r0,#0x1C]
pop  {pc}

.save_current_enemy_16:
push {lr}
bl   .base_saving_enemy_2_Dual
mov  r6,r0
mov  r4,r1
pop  {pc}

.save_current_enemy_17:
push {lr}
bl   .base_saving_enemy_2_Dual
mov  r6,r0
mov  r5,r1
pop  {pc}

.save_current_enemy_18:
push {lr}
bl   $80741AC
bl   .base_saving_enemy_3
pop  {pc}

.save_current_enemy_19:
push {lr}
bl   .base_saving_enemy_2_Dual
mov  r4,r0
mov  r6,r1
pop  {pc}

.save_current_enemy_20:
push {lr}
bl   .base_saving_enemy_3
mov  r1,r0
mov  r0,r4
pop  {pc}

.save_current_enemy_21:
push {lr}
bl   $8073F88
bl   .base_saving_enemy_3
pop  {pc}

.save_current_enemy_22:
push {lr}
bl   .base_saving_enemy_4_Dual
ldr  r2,[r4,#0x1C]
mov  r0,#0x94
pop  {pc}

.save_current_enemy_23:
push {lr}
bl   .base_saving_target
ldr  r2,[r0,#0x1C]
add  r2,#0xF0
pop  {pc}

.save_current_enemy_24:
push {lr}
push {r0}
mov  r0,r2
bl   .base_saving_target
mov  r0,r6
bl   .base_saving_enemy_Dual
pop  {r0}
lsl  r0,r0,#0x18
lsr  r0,r0,#0x18
pop  {pc}

//=============================================================================================
// Multiple PK Thunders fix
//=============================================================================================

fix_synchronization:

define thunder_fix_address $2014348

.setup:
push {r0-r1,lr}
mov  r0,#0
ldr  r1,=#{thunder_fix_address}   //Setup the zone so it's not locking
str  r0,[r1,#0]
str  r0,[r1,#4]
pop  {r0-r1,pc}

.setup_action_beginning:
push {lr}
bl   .setup
bl   $8091938
pop  {pc}

//Only this setup is ever going to be really needed. The others are there just as safety measures in case something goes wrong in the game itself and the end of the actual routine is skipped (should never ever really happen)
.setup_battle_beginning:
push {lr}
bl   .setup
bl   $8072B70
pop  {pc}

.setup_turn_beginning:
push {lr}
bl   .setup
mov  r7,r10
mov  r6,r9
pop  {pc}

//------------------------------------------------------------------------------------------------------

.fix_value_beginning_of_action_routine:
push {r3,lr}
mov  r6,r0

ldr  r2,=#{thunder_fix_address}
ldrh r1,[r2,#2]                   //Check if the stack is currently occupied. Happens if this is an HP threshold action.
cmp  r1,#1
bne  +

add  r0,#0x34                     //Inside the chain of action, has an HP threshold been triggered for the original actor?
ldr  r1,[r2,#4]
cmp  r0,r1
bne  .end_end
mov  r0,r6                        //If it did, the old action doesn't exist anymore. Reset the counter and continue normally.

+
add  r0,#0x34
ldr  r1,[r0,#0x14]
ldr  r2,=#0x80CF728               //Battle skills table
cmp  r1,r2
blt  .end

ldr  r2,=#0x80D0D27
cmp  r1,r2
bgt  +

mov  r2,#4
b    .decided

+
ldr  r2,=#0x80D9D28               //Battle actions table
cmp  r1,r2
blt  .end

ldr  r2,=#0x80E1707
cmp  r1,r2
bgt  +

mov  r2,#8
b    .decided

+
ldr  r2,=#0x80E1908               //PSI data
cmp  r1,r2
blt  .end

ldr  r2,=#0x80E5107
cmp  r1,r2
bgt  +

mov  r2,#0x10
b    .decided

+
ldr  r2,=#0x80E5108               //Item data
cmp  r1,r2
blt  .end

ldr  r2,=#0x80EBD07
cmp  r1,r2
bgt  +

mov  r2,#0x40
b    .decided

+
b    .end

.decided:
add  r1,r1,r2
ldr  r1,[r1,#8]                   //Get target of action
mov  r2,#{target_num_table_size}
cmp  r1,r2
bge  .end                         //The target is invalid. Just future-proof this in case it's used in hacks.

ldr  r2,=#{target_num_table}
ldrb r1,[r2,r1]                   //Get number of hits
mov  r3,#0
lsr  r2,r1,#5                     //Check if it's a special case (party-wide hit)
cmp  r2,#0
beq  .got_total_hits

mov  r2,#1
and  r2,r1
cmp  r2,#1
bne  +

ldr  r2,=#0x2002014               //Generic battle data
ldr  r2,[r2,#0]
ldr  r2,[r2,#0x4C]                //Party battle data
ldr  r2,[r2,#0x6C]                //Party counter
add  r3,r3,r2

+
mov  r2,#2
and  r2,r1
cmp  r2,#2
bne +

ldr  r2,=#0x2002014               //Generic battle data
ldr  r2,[r2,#0]
ldr  r2,[r2,#0x54]                //Enemy party battle data
add  r2,#0x80
ldr  r2,[r2,#4]                   //Enemy party counter
add  r3,r3,r2

+
mov  r1,r3                        //Put proper hit count

.got_total_hits:

ldr  r2,[r0,#4]                   //Load in ram hits counter and check whether the normal hits counter is bigger
cmp  r1,r2
bgt  .end                         //This shouldn't happen, however in case it does... Just be safe and don't update the counter, since it means the "action stack" is too little

cmp  r1,#0                        //Skip editing stuff for an ally's action
beq  .end

str  r1,[r0,#4]                   //Save the normal hits counter

.end:

ldr  r2,=#{thunder_fix_address}
ldr  r1,[r0,#4]                   //Load the hits counter and save it elsewhere to check it doesn't get screwed by enemies joining in
strh r1,[r2,#0]                   //Keep both the hits counter and the address of it. Certain actions happen when an enemy dies or reaches a certain HP threshold, so they interrupt the normal flow
mov  r1,#1
strh r1,[r2,#2]                   //Occupied flag
str  r0,[r2,#4]

.end_end:
ldr  r1,[r6,#0x1C]                //Clobbered code
pop  {r3,pc}

//------------------------------------------------------------------------------------------------------

.update_value:
push {lr}
sub  r0,r2,#1
str  r0,[r3,#4]                   //Default update
push {r2,r5}
ldr  r2,=#{thunder_fix_address}
ldr  r5,[r2,#4]                   //Load the address of the action
cmp  r5,r3
bne  .update_end_end              //If the addresses aren't the same, this is an action that happens within another action. Don't worry about it.
ldrh  r5,[r2,#0]                  //Load what's stored
sub  r5,r5,#1
cmp  r5,r0
bgt  .update_end                  //This shouldn't happen, however in case it does... Just be safe and don't update the counter, since it means the "action stack" is too little
str  r5,[r3,#4]

.update_end:
ldr  r5,[r3,#4]                   //Load the final value
strh r5,[r2,#0]                   //Save the final value

.update_end_end:
mov  r5,#1
strh r5,[r2,#2]
pop  {r2,r5}
pop  {pc}

//------------------------------------------------------------------------------------------------------

.end_routine:
ldr  r4,=#{thunder_fix_address}
mov  r3,#0
strh r3,[r4,#2]                   //Reset the occupied flag to 0
pop  {r3,r4}
mov  r8,r3
bx   lr

//=============================================================================================
// Fix issue that happens if someone dies and is revived by a memento while viewing their own inventory
//=============================================================================================
fix_mementos_item_menu:

//Someone died, set the Character's data position to the proper one, so if they die, it's still okay
.initial_setup:
push {lr}

ldr  r6,=#0x2014368
str  r1,[r6,#4]              //Store the actual character's position
mov  r7,r10                  //Clobbered code
mov  r6,r9
pop  {pc}

//Load the area we'll be using with the stuff we need
.setup:
push {lr}

ldr  r0,=#0x2014368
ldr  r3,[r1,#0]
sub  r3,r3,#1
                             //New item count
strb r3,[r0,#1]
                             //Removed item position
strb r5,[r0,#0]
add  r3,r3,#1

mov  r4,r1
pop  {pc}

//------------------------------------------------------------------------------------------------------

//Fix the cursor for the item menu when a Memento is used while in it
.fix:
push {lr}
push {r0-r7}
mov  r1,r0
add  r1,#0x34
ldr  r2,[r1,#0xC]
cmp  r2,#5                   //Is the character's turn ending? (No memento)
beq  .end

                             //Is this the character that was revived?
mov  r3,#0x10
sub  r3,r1,r3
ldr  r3,[r3,#0]
ldr  r0,=#0x2014368
ldr  r2,[r0,#4]
cmp  r3,r2
bne  .end
                             //Was the memento the last item?
ldrb r2,[r0,#1]
cmp  r2,#0
bne  .fix_cursor

                             //Close the menu if the memento was the last item
mov  r2,#4
str  r2,[r1,#0xC]
b    .end

.fix_cursor:
                             // r2 = How many lines from the top the menu currently is
                             // r3 = Y Coord in the current menu
                             // r4 = X Coord in the current menu
ldrb r2,[r1,#0]
ldrb r3,[r1,#1]
ldrb r4,[r1,#2]
                             // r5 = cursor position
add  r5,r2,r3
lsl  r5,r5,#1
add  r5,r5,r4
                             // r6 = disappeared item position
ldrb r6,[r0,#0]
cmp  r5,r6
blt  +
                             //If the cursor position is >= the disappeared item's position, subtract 1 from it
sub  r5,r5,#1
cmp  r5,#0
blt  .end                    //Was the first item a Memento? In that case, don't do a thing
mov  r4,#1
and  r4,r5
strb r4,[r1,#2]
                             //If x == 1
cmp  r4,#1
bne  +
                             //y -= 1
sub  r3,r3,#1
                             //If y < 0
cmp  r3,#0
bge  +
                             //y = 0
mov  r3,#0
                             //lines -= 1
sub  r2,r2,#1
+
                             // r7 = lowest line showed - 2 to get the item menu to properly show the lowest line if it's changed by the new item count
mov  r7,#2
add  r7,r7,r2
lsl  r7,r7,#1
                             // r6 = new item count
ldrb r6,[r0,#1]
                             //The game never leaves a fully empty line at the bottom. We mustn't allow it to happen either
cmp  r7,r6
blt  .next
sub  r2,r2,#1
cmp  r2,#0
bge  +
mov  r2,#0
b    .next
+
add  r3,r3,#1

.next:
strb r2,[r1,#0]
strb r3,[r1,#1]

.end:
pop  {r0-r7}
bl   $8091938                //Clobbered code
pop  {pc}

//=============================================================================================
// Improve battle menus printing
//=============================================================================================
battle_menus_improvement_hacks:

//=============================================================================================
// Call the improved inventory printing routine, A or B were pressed
//=============================================================================================
.inventory_printing_routine_ab_call:
push {lr}
mov  r1,#0
bl   .inventory_printing_routine
pop  {pc}

//=============================================================================================
// Call the improved inventory printing routine, Select/Left/Right were pressed
//=============================================================================================
.inventory_printing_routine_select_lr_call:
push {lr}
mov  r1,#1
bl   .inventory_printing_routine
pop  {pc}

//=============================================================================================
// Call the improved inventory printing routine, Up or Down were pressed
//=============================================================================================
.inventory_printing_routine_up_down_call:
push {lr}
cmp  r1,#1
beq  +
mov  r1,#1
bl   .inventory_printing_routine
b    .inventory_printing_routine_up_down_call_end
+
bl   $807E61C
.inventory_printing_routine_up_down_call_end:
pop  {pc}

//=============================================================================================
// Setup whether the top item's index changed (Scrolling)
//=============================================================================================
.inventory_printing_routine_ud_setup:
push {r5,lr}
mov  r5,r4
add  r5,#0x34
ldrb r5,[r5,#0]
bl   $8091938
mov  r1,r4
add  r1,#0x34
ldrb r1,[r1,#0]
cmp  r1,r5
beq  +
mov  r1,#1
b    .inventory_printing_routine_ud_setup_end
+
mov  r1,#0

.inventory_printing_routine_ud_setup_end:
pop  {r5,pc}

//=============================================================================================
// Improve battle inventory printing - based on 0x807E61C.
// It will print only what it needs to.
// r0 contains the menu's pointer. r1 will contain custom info that will allow understanding
// whether we need to print the select bottom bar or not...
// 0 nothing (A/B were pressed)
// 1 left/right/select/up/down
//=============================================================================================
.inventory_printing_routine:
push {r4-r7,lr}
mov  r7,r10
mov  r6,r9
mov  r5,r8
push {r5-r7}
add  sp,#-0x98
mov  r6,r0
ldr  r0,[r6,#0x40]
cmp  r0,#5
bne  +
b    .inventory_printing_routine_end
+
mov  r5,r1                             //Extra piece of code

mov  r0,#0                             //Base code
str  r0,[sp,#0x74]
mov  r1,r6
add  r1,#0x34
str  r1,[sp,#0x84]
add  r2,sp,#0x50
mov  r8,r2
mov  r3,r6
add  r3,#0x36
str  r3,[sp,#0x8C]
mov  r0,r6
add  r0,#0x35
str  r0,[sp,#0x88]
mov  r1,sp
add  r1,#0x70
str  r1,[sp,#0x90]
add  r7,sp,#0x5C
mov  r2,sp
add  r2,#0x68
str  r2,[sp,#0x80]
add  r3,sp,#0x6C
mov  r10,r3

cmp  r5,#0
bne  +
b    .inventory_printing_routine_end
+

.inventory_printing_routine_after_cycle:
mov  r3,#0xB7
lsl  r3,r3,#2
add  r0,r6,r3
ldr  r1,[sp,#0x8C]
mov  r2,#0
ldsb r2,[r1,r2]
ldr  r3,[sp,#0x88]
mov  r4,#0
ldsb r4,[r3,r4]
mov  r1,#0x6C
mov  r3,r2
mul  r3,r1
add  r3,#3
lsl  r1,r4,#1
add  r1,r1,r4
lsl  r1,r1,#2
sub  r1,#3
add  r2,sp,#0x70
strh r3,[r2,#0]
ldr  r2,[sp,#0x90]
strh r1,[r2,#2]
ldr  r1,[sp,#0x90]
bl   $808B1A8                          //Update cursor's coordinates
mov  r3,#0xDE
lsl  r3,r3,#2
add  r4,r6,r3
ldr  r0,[sp,#0x84]
mov  r1,#0
ldsb r1,[r0,r1]
sub  r1,#1
mov  r0,r6
mov  r2,#0
mov  r3,#0
bl   $807E994                          //Get item above the top one's ID
lsl  r0,r0,#0x10
lsr  r0,r0,#0x10
neg  r1,r0
orr  r1,r0
lsr  r1,r1,#0x1F
mov  r0,r4
bl   $806DB38
ldr  r1,=#0x414
add  r4,r6,r1
ldr  r2,[sp,#0x84]
mov  r1,#0
ldsb r1,[r2,r1]
add  r1,#3
mov  r0,r6
mov  r2,#0
mov  r3,#0
bl   $807E994                          //Get item below the bottom one's ID
lsl  r0,r0,#0x10
lsr  r0,r0,#0x10
neg  r1,r0
orr  r1,r0
lsr  r1,r1,#0x1F
mov  r0,r4
bl   $806DB38
mov  r3,#0x96
lsl  r3,r3,#3
add  r4,r6,r3
ldr  r1,[r6,#0x1C]
add  r1,#0xC0
mov  r2,#0
ldsh r0,[r1,r2]
add  r0,r6,r0
ldr  r1,[r1,#4]
bl   $8091938                          //Is the Select menu open?
mov  r1,r0
mov  r0,r4
bl   $806D7DC
ldr  r3,[sp,#0x84]
mov  r1,#0
ldsb r1,[r3,r1]
ldr  r0,[sp,#0x88]
mov  r2,#0
ldsb r2,[r0,r2]
ldr  r0,[sp,#0x8C]
mov  r3,#0
ldsb r3,[r0,r3]
mov  r0,r6
bl   $807E994                          //Get selected item's ID
mov  r4,r0
lsl  r4,r4,#0x10
lsr  r4,r4,#0x10
ldr  r1,[r6,#0x1C]
add  r1,#0xB8
mov  r2,#0
ldsh r0,[r1,r2]
add  r0,r6,r0
ldr  r1,[r1,#4]
bl   $8091938                          //Get character's data
mov  r2,r0
mov  r0,sp
mov  r1,r4
mov  r3,#0
bl   $80649AC
ldr  r3,=#0x51C
add  r4,r6,r3
ldr  r1,[r6,#0x1C]
add  r1,#0xC0
mov  r2,#0
ldsh r0,[r1,r2]
add  r0,r6,r0
ldr  r1,[r1,#4]
bl   $8091938                          //Is the Select menu open?
mov  r1,r0
mov  r0,r4
bl   $80867D4
mov  r0,sp
bl   $8064B20                          //Get selected item's ID
mov  r1,r0
lsl  r1,r1,#0x10
lsr  r1,r1,#0x10
mov  r0,r4
bl   $80867F8                          //Save item's ID in game's struct
ldr  r3,=#0x54C
add  r4,r6,r3
ldr  r1,[r6,#0x1C]
add  r1,#0xC0
mov  r2,#0
ldsh r0,[r1,r2]
add  r0,r6,r0
ldr  r1,[r1,#4]
bl   $8091938                          //Is the Select menu open?
mov  r1,r0
mov  r0,r4
bl   $806E948
mov  r0,r8
mov  r1,sp
mov  r2,#0
bl   $807A1F4                          //Print Item Description, top line
mov  r0,r4
mov  r1,r8
bl   $8071150
mov  r0,r8
mov  r1,#2
bl   $806E308
mov  r3,#0xB5
lsl  r3,r3,#3
add  r4,r6,r3
ldr  r1,[r6,#0x1C]
add  r1,#0xC0
mov  r2,#0
ldsh r0,[r1,r2]
add  r0,r6,r0
ldr  r1,[r1,#4]
bl   $8091938                          //Is the Select menu open?
mov  r1,r0
mov  r0,r4
bl   $806E948
mov  r0,r8
mov  r1,sp
mov  r2,#1
bl   $807A1F4                          //Print Item Description, bottom line
mov  r0,r4
mov  r1,r8
bl   $8071150
mov  r0,r8
mov  r1,#2
bl   $806E308
ldr  r3,=#0x604
add  r4,r6,r3
ldr  r1,[r6,#0x1C]
add  r1,#0xC0
mov  r2,#0
ldsh r0,[r1,r2]
add  r0,r6,r0
ldr  r1,[r1,#4]
bl   $8091938                          //Is the Select menu open?
mov  r1,r0
mov  r0,r4
bl   $806DB38
mov  r0,sp
mov  r1,#2
bl   $80649E8

.inventory_printing_routine_end:
add  sp,#0x98
pop  {r3-r5}
mov  r8,r3
mov  r9,r4
mov  r10,r5
pop  {r4-r7,pc}

//=============================================================================================
// Setup whether the top psi's index changed (Scrolling)
//=============================================================================================
.psi_printing_routine_ud_setup:
push {r5,lr}
mov  r5,r4
add  r5,#0x4D
ldrb r5,[r5,#0]
bl   $8091938
mov  r1,r4
add  r1,#0x4D
ldrb r1,[r1,#0]
cmp  r1,r5
beq  +
mov  r1,#1
b    .inventory_printing_routine_ud_setup_end
+
mov  r1,#0

.inventory_printing_routine_ud_setup_end:
pop  {r5,pc}

//=============================================================================================
// Call the improved psi printing routine, Up or Down were pressed
//=============================================================================================
.psi_printing_routine_up_down_call:
push {lr}
cmp  r1,#1
beq  +
bl   .psi_printing_routine
b    .psi_printing_routine_up_down_call_end
+
bl   $808C7CC
.psi_printing_routine_up_down_call_end:
pop  {pc}

//=============================================================================================
// Call the psi printing routine, changed the part the cursor is in
//=============================================================================================
.psi_printing_routine_change_layer_call:
push {lr}
mov  r1,#0xC8
add  r1,r0,r1
ldrb r1,[r1,#0]
cmp  r1,#3
beq  +
bl   $808C7CC
+
pop  {pc}

//=============================================================================================
// Improve battle psi menu printing - based on 0x808C7CC.
// It will print only what it needs to.
// r0 contains the menu's pointer
//=============================================================================================
.psi_printing_routine:
push {r4-r7,lr}
mov  r7,r10
mov  r6,r9
mov  r5,r8
push {r5-r7}
add  sp,#-0x78
mov  r5,r0
mov  r0,#0xF0
lsl  r0,r0,#1
add  r6,r5,r0
mov  r1,#0
ldr  r0,[r5,#0x58]
cmp  r0,#1
bne  +
mov  r1,#1
+
mov  r0,r6
bl   $806DB38

mov  r4,r5                             //Base code
add  r4,#0x4C
mov  r2,#0
ldsb r2,[r4,r2]
add  r1,sp,#0x58
mov  r3,#3
lsl  r0,r2,#1
add  r0,r0,r2
lsl  r0,r0,#2
sub  r0,#3
strh r3,[r1,#0]
strh r0,[r1,#2]
mov  r0,r6
bl   $808B1A8
mov  r1,#0
mov  r10,r1
str  r4,[sp,#0x68]
mov  r2,r5
add  r2,#0x4D
str  r2,[sp,#0x6C]
mov  r3,r5
add  r3,#0x4E
str  r3,[sp,#0x70]
mov  r0,sp
add  r0,#0x64
str  r0,[sp,#0x74]
add  r1,sp,#0x5C
mov  r9,r1
add  r2,sp,#0x60
mov  r8,r2

.psi_printing_routine_after_cycle:
mov  r2,#0x99
lsl  r2,r2,#3
add  r4,r5,r2
mov  r1,#0
ldr  r0,[r5,#0x58]
cmp  r0,#2
bne  +
mov  r1,#1
+
mov  r0,r4
bl   $806DB38
ldr  r3,[sp,#0x70]
mov  r1,#0
ldsb r1,[r3,r1]
mov  r2,#0x49
lsl  r0,r1,#1
add  r0,r0,r1
lsl  r0,r0,#2
sub  r0,#3
add  r1,sp,#0x64
strh r2,[r1,#0]
ldr  r1,[sp,#0x74]
strh r0,[r1,#2]
mov  r0,r4
ldr  r1,[sp,#0x74]
bl   $808B1A8
ldr  r2,=#0x564
add  r4,r5,r2
ldr  r3,[sp,#0x68]
mov  r1,#0
ldsb r1,[r3,r1]
ldr  r0,[sp,#0x6C]
mov  r2,#0
ldsb r2,[r0,r2]
sub  r2,#1
mov  r0,r5
mov  r3,#0
bl   $808CB18
lsl  r0,r0,#0x10
lsr  r0,r0,#0x10
neg  r1,r0
orr  r1,r0
lsr  r1,r1,#0x1F
mov  r0,r4
bl   $806DB38
mov  r1,#0xC0
lsl  r1,r1,#3
add  r4,r5,r1
ldr  r2,[sp,#0x68]
mov  r1,#0
ldsb r1,[r2,r1]
ldr  r3,[sp,#0x6C]
mov  r2,#0
ldsb r2,[r3,r2]
add  r2,#3
mov  r0,r5
mov  r3,#0
bl   $808CB18
lsl  r0,r0,#0x10
lsr  r0,r0,#0x10
neg  r1,r0
orr  r1,r0
lsr  r1,r1,#0x1F
mov  r0,r4
bl   $806DB38
ldr  r0,=#0x69C
add  r4,r5,r0
ldr  r1,[r5,#0x1C]
add  r1,#0xD8
mov  r2,#0
ldsh r0,[r1,r2]
add  r0,r5,r0
ldr  r1,[r1,#4]
bl   $8091938
mov  r1,r0
mov  r0,r4
bl   $806D7DC
mov  r3,#0xE1
lsl  r3,r3,#3
add  r6,r5,r3
ldr  r1,[r5,#0x1C]
add  r1,#0xD8
mov  r2,#0
ldsh r0,[r1,r2]
add  r0,r5,r0
ldr  r1,[r1,#4]
bl   $8091938
mov  r1,r0
mov  r0,r6
bl   $806E948
ldr  r3,=#0x764
add  r7,r5,r3
ldr  r1,[r5,#0x1C]
add  r1,#0xD8
mov  r2,#0
ldsh r0,[r1,r2]
add  r0,r5,r0
ldr  r1,[r1,#4]
bl   $8091938
mov  r1,r0
mov  r0,r7
bl   $806E948
ldr  r0,[r5,#0x58]
cmp  r0,#2
bne  .psi_printing_routine_not_inside

ldr  r3,[sp,#0x68]
mov  r1,#0
ldsb r1,[r3,r1]
ldr  r0,[sp,#0x6C]
mov  r2,#0
ldsb r2,[r0,r2]
ldr  r0,[sp,#0x70]
mov  r3,#0
ldsb r3,[r0,r3]
mov  r0,r5
bl   $808CB18
mov  r4,r0
lsl  r4,r4,#0x10
lsr  r4,r4,#0x10
ldr  r1,[r5,#0x1C]
add  r1,#0xD0
mov  r2,#0
ldsh r0,[r1,r2]
add  r0,r5,r0
ldr  r1,[r1,#4]
bl   $8091938
mov  r2,r0
mov  r0,sp
mov  r1,r4
bl   $8082B78
add  r4,sp,#0x4C
mov  r0,r4
mov  r1,sp
mov  r2,#0
bl   $807A1F4
mov  r0,r6
mov  r1,r4
bl   $8071150
mov  r0,r4
mov  r1,#2
bl   $806E308
mov  r0,r4
mov  r1,sp
mov  r2,#1
bl   $807A1F4
mov  r0,r7
mov  r1,r4
bl   $8071150
mov  r0,r4
mov  r1,#2
bl   $806E308
mov  r0,sp
mov  r1,#2
bl   $8082BA8
b    +

.psi_printing_routine_not_inside:
mov  r0,sp
bl   $806E274
mov  r0,r6
mov  r1,sp
bl   $8071150
mov  r0,sp
mov  r1,#2
bl   $806E308
mov  r0,r7
mov  r1,sp
bl   $8071150
mov  r0,sp
mov  r1,#2
bl   $806E308                          //No select text outside

+
mov  r3,#0xF8
lsl  r3,r3,#3
add  r4,r5,r3
ldr  r1,[r5,#0x1C]
add  r1,#0xD8
mov  r2,#0
ldsh r0,[r1,r2]
add  r0,r5,r0
ldr  r1,[r1,#4]
bl   $8091938
mov  r1,r0
mov  r0,r4
bl   $806DB38

.psi_printing_routine_end:
add  sp,#0x78
pop  {r3-r5}
mov  r8,r3
mov  r9,r4
mov  r10,r5
pop  {r4-r7,pc}

//=============================================================================================
// Call the skills printing routine, printing the whole menu
//=============================================================================================
.skills_printing_routine_enter_call:
push {lr}
mov  r1,#0xA4
add  r1,r0,r1
ldrb r1,[r1,#0]
cmp  r1,#0x13
beq  +
bl   $808DBD4
+
pop  {pc}

//=============================================================================================
// Improve battle skills menu printing - based on 0x808DBD4.
// It will print only what it needs to.
// r0 contains the menu's pointer
//=============================================================================================
.skills_printing_routine:
push {r4-r7,lr}
mov  r7,r10
mov  r6,r9
mov  r5,r8
push {r5-r7}
add  sp,#-0x30
mov  r7,r0
mov  r0,#0
mov  r10,r0
mov  r1,sp
add  r1,#0xC
str  r1,[sp,#0x20]
mov  r2,r7
add  r2,#0x29
str  r2,[sp,#0x2C]
mov  r0,r7
add  r0,#0x28
str  r0,[sp,#0x28]

.skills_printing_routine_after_cycle:
mov  r1,#0xB4
lsl  r1,r1,#2
add  r0,r7,r1
ldr  r1,[sp,#0x2C]
ldrb r2,[r1,#0]
ldr  r1,[sp,#0x28]
ldrb r4,[r1,#0]
mov  r1,#0x6C
mov  r3,r2
mul  r3,r1
add  r3,#3
lsl  r1,r4,#1
add  r1,r1,r4
lsl  r1,r1,#2
sub  r1,#3
add  r2,sp,#0xC
strh r3,[r2,#0]
ldr  r2,[sp,#0x20]
strh r1,[r2,#2]
ldr  r1,[sp,#0x20]
bl   $808B1A8
mov  r0,#0xDB
lsl  r0,r0,#2
add  r4,r7,r0
ldr  r1,[r7,#0x1C]
add  r1,#0xC0
mov  r2,#0
ldsh r0,[r1,r2]
add  r0,r7,r0
ldr  r1,[r1,#4]
bl   $8091938
mov  r1,r0
mov  r0,r4
bl   $806D7DC
ldr  r0,[sp,#0x28]
ldrb r1,[r0,#0]
ldr  r0,[sp,#0x2C]
ldrb r2,[r0,#0]
mov  r0,r7
bl   $808DF14
mov  r4,r0
lsl  r4,r4,#0x10
lsr  r4,r4,#0x10
ldr  r1,[r7,#0x1C]
add  r1,#0xB8
mov  r2,#0
ldsh r0,[r1,r2]
add  r0,r7,r0
ldr  r1,[r1,#4]
bl   $8091938
mov  r1,r0
mov  r0,r4
bl   $8073F88
mov  r8,r0
ldr  r1,[r0,#0x1C]
mov  r0,#0xF0
lsl  r0,r0,#1
add  r1,r1,r0
mov  r2,#0
ldsh r0,[r1,r2]
add  r0,r8
ldr  r1,[r1,#4]
bl   $8091938                          //Get item ID, if it's a skill, returns 0
lsl  r0,r0,#0x10
cmp  r0,#0
bne  +
b    .skills_printing_routine_not_item
+

mov  r0,#0xF6
lsl  r0,r0,#2
add  r4,r7,r0
ldr  r1,[r7,#0x1C]
add  r1,#0xC0
mov  r2,#0
ldsh r0,[r1,r2]
add  r0,r7,r0
ldr  r1,[r1,#4]
bl   $8091938
mov  r1,r0
mov  r0,r4
bl   $80867D4
mov  r0,r8
ldr  r1,[r0,#0x1C]
mov  r2,#0xF0
lsl  r2,r2,#1
add  r1,r1,r2
mov  r2,#0
ldsh r0,[r1,r2]
add  r0,r8
ldr  r1,[r1,#4]
bl   $8091938
mov  r1,r0
lsl  r1,r1,#0x10
lsr  r1,r1,#0x10
mov  r0,r4
bl   $80867F8
mov  r0,#0x81
lsl  r0,r0,#3
add  r4,r7,r0
ldr  r1,[r7,#0x1C]
add  r1,#0xC0
mov  r2,#0
ldsh r0,[r1,r2]
add  r0,r7,r0
ldr  r1,[r1,#4]
bl   $8091938
mov  r1,r0
mov  r0,r4
bl   $806E948
mov  r0,r8
ldr  r2,[r0,#0x1C]
mov  r5,#0xEC
lsl  r5,r5,#1
add  r2,r2,r5
mov  r0,#0
ldsh r1,[r2,r0]
mov  r0,sp
ldr  r3,[r2,#4]
add  r1,r8
mov  r2,#0
bl   $8091940
mov  r0,r4
mov  r1,sp
bl   $8071150
mov  r0,sp
mov  r1,#2
bl   $806E308
add  r1,sp,#0x10
mov  r6,#0x24
mov  r0,#0x86
strh r6,[r1,#0]
strh r0,[r1,#2]
mov  r0,r4
bl   $8071194
ldr  r1,=#0x464
add  r4,r7,r1
ldr  r1,[r7,#0x1C]
add  r1,#0xC0
mov  r2,#0
ldsh r0,[r1,r2]
add  r0,r7,r0
ldr  r1,[r1,#4]
bl   $8091938
mov  r1,r0
mov  r0,r4
bl   $806E948
mov  r0,r8
ldr  r2,[r0,#0x1C]
add  r2,r2,r5
mov  r0,#0
ldsh r1,[r2,r0]
mov  r0,sp
ldr  r3,[r2,#4]
add  r1,r8
mov  r2,#1
bl   $8091940
mov  r0,r4
mov  r1,sp
bl   $8071150
mov  r0,sp
mov  r1,#2
bl   $806E308
add  r1,sp,#0x14
mov  r0,#0x92
strh r6,[r1,#0]
strh r0,[r1,#2]
mov  r0,r4
bl   $8071194
b    +

.skills_printing_routine_not_item:
mov  r1,#0xF6
lsl  r1,r1,#2
add  r0,r7,r1
mov  r1,#0
bl   $80867D4
mov  r2,#0x81
lsl  r2,r2,#3
add  r4,r7,r2
ldr  r1,[r7,#0x1C]
add  r1,#0xC0
mov  r2,#0
ldsh r0,[r1,r2]
add  r0,r7,r0
ldr  r1,[r1,#4]
bl   $8091938
mov  r1,r0
mov  r0,r4
bl   $806E948
mov  r0,r8
ldr  r2,[r0,#0x1C]
mov  r5,#0xEC
lsl  r5,r5,#1
add  r2,r2,r5
mov  r0,#0
ldsh r1,[r2,r0]
mov  r0,sp
ldr  r3,[r2,#4]
add  r1,r8
mov  r2,#0
bl   $8091940
mov  r0,r4
mov  r1,sp
bl   $8071150
mov  r0,sp
mov  r1,#2
bl   $806E308
add  r1,sp,#0x18
mov  r6,#0xC
mov  r0,#0x86
strh r6,[r1,#0]
strh r0,[r1,#2]
mov  r0,r4
bl   $8071194
ldr  r1,=#0x464
add  r4,r7,r1
ldr  r1,[r7,#0x1C]
add  r1,#0xC0
mov  r2,#0
ldsh r0,[r1,r2]
add  r0,r7,r0
ldr  r1,[r1,#4]
bl   $8091938
mov  r1,r0
mov  r0,r4
bl   $806E948
mov  r0,r8
ldr  r2,[r0,#0x1C]
add  r2,r2,r5
mov  r0,#0
ldsh r1,[r2,r0]
mov  r0,sp
ldr  r3,[r2,#4]
add  r1,r8
mov  r2,#1
bl   $8091940
mov  r0,r4
mov  r1,sp
bl   $8071150
mov  r0,sp
mov  r1,#2
bl   $806E308
add  r1,sp,#0x1C
mov  r0,#0x92
strh r6,[r1,#0]
strh r0,[r1,#2]
mov  r0,r4
bl   $8071194

+
mov  r1,#0x98
lsl  r1,r1,#3
add  r4,r7,r1
ldr  r1,[r7,#0x1C]
add  r1,#0xC0
mov  r2,#0
ldsh r0,[r1,r2]
add  r0,r7,r0
ldr  r1,[r1,#4]
bl   $8091938
mov  r1,r0
mov  r0,r4
bl   $806DB38
mov  r0,r8
cmp  r0,#0
beq  .skills_printing_routine_end
ldr  r1,[r0,#0x1C]
mov  r2,#8
ldsh r0,[r1,r2]
add  r0,r8
ldr  r2,[r1,#0xC]
mov  r1,#3
bl   $809193C

.skills_printing_routine_end:
add  sp,#0x30
pop  {r3-r5}
mov  r8,r3
mov  r9,r4
mov  r10,r5
pop  {r4-r7,pc}
