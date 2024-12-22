//===========================================================================================
//
// General hacks available:
//
// * custom_strcopy: Copies a 0xFFFF-terminatd string from the address in r0 to the address
//                   in r1. Returns the number of bytes copied in r0 upon completion.
//
// * get_string_width: Gets the total width of the string whose address is in r0. The total
//                     width is returned in r0. This routine uses the widths from the main
//                     16x16 width table.
//
// * custom_strlen: Gets the length of a string (in bytes) whose address is in r0. It's
//                  assumed the string ends with 0xFFFF. The result is returned in r0.
//
//===========================================================================================





//===========================================================================================
// This code will be called by a few of our custom hacks. It basically copies a string
// that's terminated with 0xFFFF from one address to the other, then returns the # of
// bytes copied.
//
// r0 has the source address
// r1 has the target address
//
// Upon completion, r0 contains the # of bytes copied.
//===========================================================================================

custom_strcopy:
push {r2-r4,lr}

mov  r3,#0                   // r3 will be our counter, so initialize it to zero
ldr  r4,=#0xFFFF             // r4 now as 0xFFFF, an [END] code

-
ldrh r2,[r0,r3]              // load the current character from the source address
cmp  r2,r4                   // is it an [END] code?
beq  +                       // if so, let's end the routine

strh r2,[r1,r3]              // otherwise, let's store it to the target address
add  r3,#2                   // increment the counter
b    -                       // do the next loop iteration

+
mov  r0,r3                   // r0 now has the # of bytes copied
pop  {r2-r4,pc}

//Party members variant
custom_strcopy_party:
push {r2-r4,lr}

mov  r3,#0                   // r3 will be our counter, so initialize it to zero
ldr  r4,=#0xFFFF             // r4 now as 0xFFFF, an [END] code

-
ldrh r2,[r0,r3]              // load the current character from the source address
cmp  r2,r4                   // is it an [END] code?
beq  +                       // if so, let's end the routine
cmp  r3,#0x10                // Party members can only be 8 letters long, it all 8 are used, there will be no 0xFFFF, so go out
beq  +

strh r2,[r1,r3]              // otherwise, let's store it to the target address
add  r3,#2                   // increment the counter
b    -                       // do the next loop iteration

+
mov  r0,r3                   // r0 now has the # of bytes copied
pop  {r2-r4,pc}



//===========================================================================================
// This function calculates the width of a string whose address is at r0. It's assumed that
// the string is terminated by 0xFFFF. The width is returned in r0, and uses the 16x16 font
// widths.
//===========================================================================================

get_string_width:
push {r1-r4,r7,lr}
ldr  r7,=#0x1FFF             // r7 = maxcount

ldr  r1,=#0x2004F02          // load the address of where the fav. food string is stored
cmp  r0,r1                   // if we just read the fav food, do extra stuff, else leave now
bne  +
mov  r7,#9                   // if this is fav. food, set max length to 9

+
mov  r1,#0                   // r1 = width total
mov  r2,r0                   // r2 = address
mov  r3,#1
neg  r3,r3
lsr  r3,r3,#0x10             // r3 = 0xFFFF, [END] code
ldr  r4,=#{main_font_width}  // address of main width table

-
ldrh r0,[r2,#0x0]
cmp  r0,r3
beq  +

ldrb r0,[r4,r0]              // load the width
add  r1,r1,r0                // total_width += curr_width
add  r2,#0x2                 // read_address += 2

sub  r7,#1                   // max_length--
cmp  r7,#0                   // if we still haven't counted down to 0, do the loop again
bgt  -


+
mov  r0,r1                   // r0 has the return value
pop  {r1-r4,r7,pc}


//===========================================================================================
// This code counts the length of the string (in bytes) whose address is in r0. String must
// end in FFFF. The result is returned in r0.
//===========================================================================================

custom_strlen:
push {r2-r4,lr}

mov  r3,#0                   // r3 will be our counter, so initialize it to zero
ldr  r4,=#0xFFFF             // r4 now has 0xFFFF, an [END] code

-
ldrh r2,[r0,r3]              // load the current character from the source address
cmp  r2,r4                   // is it an [END] code?
beq  +                       // if so, let's end the routine

add  r3,#2                   // increment the counter
b    -                       // do the next loop iteration

+
lsr  r0,r3,#1                // r0 now has the # of bytes in the string
pop  {r2-r4,pc}

//Party member variant
custom_strlen_party:
push {r2-r4,lr}

mov  r3,#0                   // r3 will be our counter, so initialize it to zero
ldr  r4,=#0xFFFF             // r4 now has 0xFFFF, an [END] code

-
ldrh r2,[r0,r3]              // load the current character from the source address
cmp  r2,r4                   // is it an [END] code?
beq  +                       // if so, let's end the routine
cmp  r3,#0x10                // Party members can have names up to 8 characters long. Not more
beq  +

add  r3,#2                   // increment the counter
b    -                       // do the next loop iteration

+
lsr  r0,r3,#1                // r0 now has the # of bytes in the string
pop  {r2-r4,pc}



// r0 = value
// r1 = address
// r2 = # of halfwords

fill_mem:
push {r0-r4,lr}

push {r0}
mov  r0,sp

mov  r3,#1
lsl  r3,r3,#24
orr  r2,r3                   // set the 24th bit of r2 so it'll know to fill instead of copy
swi  #0x0B                   // clear old data out

pop  {r0}
pop  {r0-r4,pc}




//===========================================================================================
// This code calculates the width of a string. It'll stop if it hits FF01 or FF02.
// It assumes the string doesn't end with FFFF. This code is mainly for the final battle VWF.
//
// r0 should contain the address of the string/substring to be processed
// r1 should contain the end address of the string, since FFFF isn't at the end
//
// the final width result will be returned in r0
//===========================================================================================
get_special_width:
push {r1-r7,lr}

mov  r7,r1                   // r7 has the end address
mov  r1,#0                   // r1 = width total

mov  r2,r0                   // r2 = address
ldr  r4,=#{main_font_width}  // address of main width table

-
ldrh r0,[r2,#0x0]

ldr  r3,=#0xFF01             // check for [BREAK] code
cmp  r0,r3
beq  .gsw_end

add  r3,#1                   // check for [WAIT] code
cmp  r0,r3
beq  .gsw_end

cmp  r2,r7                   // see if we're past the end address
bge  .gsw_end

ldr  r3,=#0xFF00
cmp  r0,r3
bge  +

ldrb r0,[r4,r0]              // load the width
add  r1,r1,r0                // total_width += curr_width

+
add  r2,#0x2                 // read_address += 2
b    -                       // loop back

.gsw_end:
mov  r0,r1                   // r0 has the return value
pop  {r1-r7,pc}

//============================================================================================
// This routine converts tiles from 1bpp to 4bpp.
// We want to go VERY FAST.
// r5 is the tile's address, r6 is the conversion table's address and
// r0 is the amount of tiles to convert
//============================================================================================
convert_1bpp_4bpp_tiles:
push {r4-r5}
mov  r4,r0
ldrb r0,[r5,#9]              // Get the colour
lsl  r0,r0,#0x10
lsr  r0,r0,#0x6
add  r3,r6,r0                // Get the conversion table

-

ldr  r1,[r5,#0]
ldr  r2,[r5,#4]              // Load the tile

// FIRST ROW
lsl  r0,r1,#0x18             // Get only one byte
lsr  r0,r0,#0x18

lsl  r0,r0,#2                // now multiply by four
ldr  r0,[r3,r0]              // r0 now has the converted 4bpp version
str  r0,[r5,#0]              // store to the buffer

// SECOND ROW
lsl  r0,r1,#0x10             // Get only one byte
lsr  r0,r0,#0x18

lsl  r0,r0,#2                // now multiply by four
ldr  r0,[r3,r0]              // r0 now has the converted 4bpp version
str  r0,[r5,#4]              // store to the buffer

// THIRD ROW
lsl  r0,r1,#0x8              // Get only one byte
lsr  r0,r0,#0x18

lsl  r0,r0,#2                // now multiply by four
ldr  r0,[r3,r0]              // r0 now has the converted 4bpp version
str  r0,[r5,#8]              // store to the buffer

// FOURTH ROW
lsr  r0,r1,#0x18             // Get only one byte

lsl  r0,r0,#2                // now multiply by four
ldr  r0,[r3,r0]              // r0 now has the converted 4bpp version
str  r0,[r5,#0xC]            // store to the buffer

// FIFTH ROW
lsl  r0,r2,#0x18             // Get only one byte
lsr  r0,r0,#0x18

lsl  r0,r0,#2                // now multiply by four
ldr  r0,[r3,r0]              // r0 now has the converted 4bpp version
str  r0,[r5,#0x10]           // store to the buffer

// SIXTH ROW
lsl  r0,r2,#0x10             // Get only one byte
lsr  r0,r0,#0x18

lsl  r0,r0,#2                // now multiply by four
ldr  r0,[r3,r0]              // r0 now has the converted 4bpp version
str  r0,[r5,#0x14]           // store to the buffer

// SEVENTH ROW
lsl  r0,r2,#0x8              // Get only one byte
lsr  r0,r0,#0x18

lsl  r0,r0,#2                // now multiply by four
ldr  r0,[r3,r0]              // r0 now has the converted 4bpp version
str  r0,[r5,#0x18]           // store to the buffer

// EIGHT ROW
lsr  r0,r2,#0x18             // Get only one byte

lsl  r0,r0,#2                // now multiply by four
ldr  r0,[r3,r0]              // r0 now has the converted 4bpp version
str  r0,[r5,#0x1C]           // store to the buffer

add  r5,#0x20

sub  r4,#1                   // have we done all the tiles?
cmp  r4,#0
bgt  -

pop  {r4-r5}
bx   lr

//===========================================================================================
//This checks if the address in r0 points to a special 8- or 9-letter custom name.
//If it does, it will return the correct length in r0.
//If it doesn't, it will return r0 == 0.
//===========================================================================================

check_name:
push {r1,r5,lr}
mov  r5,#8
ldr  r1,=#0x200417E          // Flint's name in RAM = $200417E
cmp  r1,r0
beq  .fix_count

add  r1,#0x6C                // Lucas' name in RAM = $20041EA
cmp  r1,r0
beq  .fix_count

add  r1,#0x6C                // Duster's name in RAM = $2004256
cmp  r1,r0
beq  .fix_count

add  r1,#0x6C                // Kumatora's name in RAM = $20042C2
cmp  r1,r0
beq  .fix_count

add  r1,#0x6C                // Boney's name in RAM = $200432E
cmp  r1,r0
beq  .fix_count

add  r1,#0x6C                // Salsa's name in RAM = $200439A
cmp  r1,r0
beq  .fix_count

add  r1,#0xFC
add  r1,#0xFC
add  r1,#0xFC                // Claus's name in RAM = $200468E
cmp  r1,r0
beq  .fix_count

ldr  r1,=#0x2004EE2          // Hinawa's name in RAM = $2004EE2
cmp  r1,r0
beq  .fix_count

mov  r5,#8
add  r1,#0x10                // Claus' name #2 in RAM = $2004EF2
cmp  r1,r0                   // added in for v1.2, courtesy of Jeff
beq  .fix_count

mov  r5,#9
add  r1,#0x10                // Favorite Food in RAM = $2004F02
cmp  r1,r0
beq  .fix_count

mov  r5,#8
add  r1,#0x12                // Favorite Thing in RAM = $2004F14
cmp  r1,r0
beq  .fix_count

mov  r5,#16
add  r1,#0x12                // Player name in RAM = $2004F26
cmp  r1,r0
beq  .fix_count

mov  r5,#8
add  r1,#0xEC                // Slot 1 active name in RAM = $20050FE
add  r1,#0xEC
cmp  r1,r0
beq  .fix_count

add  r1,#0x64                // Slot 2 active name in RAM = $2005162
cmp  r1,r0
beq  .fix_count

b    +                       // if none of these, do the original code and leave

.fix_count:
mov  r0,r5
pop  {r1,r5,pc}

+
mov  r0,#0
pop  {r1,r5,pc}
