//============================================================================================
define current_font_menu $20225C4
define sprite_text_weld_stack_size $F8
define wbuf_stk $50          // writing buffer, 0x2014320
define letter_stk $54        // letters data address, ldr[sp,#8] + 0x76D9
define numstr_stk $58        // num strings address, ldr[sp,#8] + 0x6C44
define ctrl_stk $5C          // control code base value, 0xFEFF
define coord_stk $60         // x_coord address, 0x20225C8
define cfm_stk $64           // current_font_menu
define mfont_stk $68         // main_font address
define mfontw_stk $6C        // main_font_width address
define sfontw_stk $70        // small_font_width address
define ocbuf_stk $74         // oam coords buffer, 0x2014240
define olbuf_stk $78         // oam length buffer, 0x2014260
define ohbuf_stk $7C         // oam hash buffer, 0x2014270
define oabuf_stk $80         // oam address buffer, 0x20142B0
define oslbuf_stk $84        // oam strlen buffer, 0x20142F0
define dbuf_stk $88          // data buffer, 0x2014300
define hprime_stk $8C        // hash's prime value, 0x1000193
define hoffset_stk $90       // hash's offset value, 0x811C9DC5
define empty_stk $94         // empty_tile+2 address
define oam_tiles_stack_buffer {sprite_text_weld_stack_size}-$60

//============================================================================================
// This hack does text "welding" within the game's glyph buffer structs. This particular
// routine affects sprite text.
//
// This hack replaces existing code. The original routine was at 8001EA4, and was shared
// by other routines, namely item name text and the main script text.
//
// We're going to need to store some stuff in a RAM block temporarily. We'll use good old
// 2014320. The layout will be as follows:
//
//    2014320  word  scratch stuff for the 1bpp glyph data and other stuff
//    2014321  ...
//    2014322  ...
//    2014323  ...
//    2014324  byte  total # of tiles/sprites allocated
//    2014325  byte  current x position within the current target glyph
//    2014326  byte  current letter's width
//    2014327  byte  new_tile_flag -- if non-zero, signal later hack to move to next struct
//    2014328  hword current letter
//    2014329  ...
//    201432A  byte  new_line_flag -- if non-zero, signal later hack to move to next line
//    201432B  byte  redraw_flag -- if non-zero, signals the game to redraw subsequent tiles
//    201432C  byte  table_loc -- used to traverse the address/len/etc. tables
//    201432D  byte  fadeout_flag -- if this is set, we're fading out, useful for speedups
//
//============================================================================================

// THIS CODE AND THE ONE IN write_Glyph_1bpp INSIDE main_menu_hacks ARE BASICALLY THE SAME!
// THEY'RE SEPARATED IN ORDER TO MAXIMIZE PERFORMANCES, BUT IF A BUG IS IN ONE OF THEM,
// IT'S PROBABLY IN THE OTHER ONE AS WELL

text_weld:
push {r4-r7,lr}          // This is an efficient version of the printing routine
mov  r5,r0
mov  r6,r0
add  r6,#0x20
mov  r4,r1
mov  r1,r3

mov  r0,#1
strb r0,[r5,#8]          // This tile is used
strb r2,[r5,#9]          // Store the palette

ldr  r7,=#0x2014320
ldrb r3,[r7,#0x6]        // load the current letter's width
ldrb r7,[r7,#0x5]        // r7 = curr_x

cmp  r7,#8
blt  +
lsl  r7,r7,#0x1D         // r7 = r7 and 7
lsr  r7,r7,#0x1D
add  r5,#0x20
add  r6,#0x6C
add  r0,r7,r3
cmp  r0,#8
blt  +
mov  r0,#1
strb r0,[r6,#8]          // This tile is used
strb r2,[r6,#9]          // Store the palette
+

add  r2,r3,#7            //If this isn't a multiple of 8, it will go over a multiple of 8 now
lsr  r2,r2,#3            //Get total tiles number
cmp  r2,r1
blt  +
mov  r2,r1               //Prevent bad stuff
+

//---------------------------------------------------------------------------------------------

mov  r0,r8
push {r0}
mov  r8,r2
mov  r2,#0xFF            //If we had access to the stack, using a precompiled
lsr  r2,r7               //array would be faster... Probably
lsl  r0,r2,#8
orr  r2,r0
lsl  r0,r2,#0x10
orr  r2,r0

.loop_start:
push {r3}
ldr  r3,[r4,#0]          //Load the first 4 rows
mov  r1,r3
lsr  r3,r7               //Shift them by curr_x
mov  r0,#8
sub  r0,r0,r7
lsl  r1,r0
and  r3,r2               //Left side
mvn  r2,r2               //Get the inverted version
and  r1,r2               //Right side

// TOP FOUR - LEFT
ldr  r0,[r5,#0]          // load what's in the current row
orr  r0,r3               // OR them together
str  r0,[r5,#0]          // and now store it back

// TOP FOUR - RIGHT
str  r1,[r6,#0]          // and now store it back

// Now we do the bottom four!

ldr  r3,[r4,#4]          //Load the last 4 rows
mov  r1,r3
lsr  r3,r7               //Shift them by curr_x
mov  r0,#8
sub  r0,r0,r7
lsl  r1,r0
and  r1,r2               //Right side
mvn  r2,r2               //Get the inverted version
and  r3,r2               //Left side

// BOTTOM FOUR - LEFT
ldr  r0,[r5,#4]          // load what's in the current row
orr  r0,r3               // OR them together
str  r0,[r5,#4]          // and now store it back

// BOTTOM FOUR - RIGHT
str  r1,[r6,#4]          // and now store it back

pop  {r3}

mov  r0,r8               // increment counter
cmp  r0,#1               // see if we're still under the # of tiles we need to process
ble  .routine_end
sub  r0,#1
mov  r8,r0
mov  r0,r5
sub  r1,r6,r5
mov  r5,r6
add  r6,#0x20
cmp  r1,#0x20
bne  +
add  r6,#0x4C
sub  r3,#8
add  r1,r7,r3
cmp  r1,#8
blt  +
ldrb r1,[r0,#9]          // Grab the colour
mov  r0,#1
strb r0,[r6,#8]          // This tile is used
strb r1,[r6,#9]          // Store the palette
+
add  r4,#8
b    .loop_start

//---------------------------------------------------------------------------------------------
.routine_end:
pop  {r0}

mov  r8,r0
pop  {r4-r7,pc}


//============================================================================================
// This section of code is for initialization before a string is printed into OBJ memory.
// It mostly sets a bunch of stuff to 0. This should be called from 80492E2.
//============================================================================================

sprite_text_weld:
.init:
push {lr}
ldr  r3,=#0x2014320
mov  r0,#1
strb r0,[r3,#0x7]         // new_tile_flag = TRUE
mov  r0,#0
strh r0,[r3,#0x4]         // curr_tile_num = 0, curr_x = 0
strb r0,[r3,#0xA]         // new_line_flag = FALSE
strb r0,[r3,#0xB]         // redraw_flag = FALSE
strb r0,[r3,#0xC]         // table_loc = 0

mov  r0,#0
strb r0,[r1,#0x0]         // code we clobbered
pop  {pc}


//============================================================================================
// This routine changes the loaded tiles accordingly to fix when the first line that's printed
// starts with a BREAK or a STATUSICON
//============================================================================================
.empty_tile:
  dw $00EB

.replace_BREAK_first_line:
ldr  r0,[sp,#0]
ldr  r1,[sp,#{empty_stk}]
sub  r1,#2
str  r0,[sp,#0x44]        // the engine cannot properly process the first line starting with
str  r1,[sp,#0]           // a BREAK or a STATUSICON, so we add an empty letter before it
ldrh r0,[r6,#0xE]
add  r0,#1
strh r0,[r6,#0xE]         // the string we need to print is now 1 letter longer
bx   lr

.restore_old_first_line:
ldr  r0,[sp,#0]
ldr  r1,[sp,#{empty_stk}]
cmp  r0,r1
bne  +
ldr  r0,[sp,#0x44]
str  r0,[sp,#0]
+
bx   lr


//============================================================================================
// This section of code is for caching certain addresses and values we'll use multiple
// times in the stack
//============================================================================================

.init_stack:

str  r3,[sp,#{wbuf_stk}]  // save these value to stack in order to avoid needless jumps

str  r1,[sp,#{letter_stk}]

ldr  r2,[sp,#0x8]
ldr  r0,=#0x6C44
add  r0,r2,r0
str  r0,[sp,#{numstr_stk}]

ldr  r0,=#0xFEFF
str  r0,[sp,#{ctrl_stk}]

ldr  r0,=#0x20225C8
str  r0,[sp,#{coord_stk}]

ldr  r0,=#{current_font_menu}
str  r0,[sp,#{cfm_stk}]

ldr  r0,=#{main_font}
str  r0,[sp,#{mfont_stk}]

ldr  r0,=#{main_font_width}
str  r0,[sp,#{mfontw_stk}]

ldr  r0,=#{small_font_width}
str  r0,[sp,#{sfontw_stk}]

ldr  r0,=#0x2014240
str  r0,[sp,#{ocbuf_stk}]

add  r0,#0x20
str  r0,[sp,#{olbuf_stk}]

add  r0,#0x10
str  r0,[sp,#{ohbuf_stk}]

add  r1,sp,#0x24          

add  r0,#0x40
str  r0,[sp,#{oabuf_stk}]

add  r0,#0x40
str  r0,[sp,#{oslbuf_stk}]

mov  r0,#0x20
sub  r0,r3,r0
str  r0,[sp,#{dbuf_stk}]

ldr  r0,=#0x1000193
str  r0,[sp,#{hprime_stk}]

ldr  r0,=#0x811C9DC5
str  r0,[sp,#{hoffset_stk}]

ldr  r0,=#.empty_tile+2
str  r0,[sp,#{empty_stk}]

bx   lr


//============================================================================================
// This section of code stores the letter from the font's data to the stack.
// Small font version. Returns if there is data to print or not.
// r0 is the letter. r1 is the stack pointer
//============================================================================================

.fast_prepare_small_font:
mov  r4,r0
ldr  r2,=#{small_font}+2  // we already know we're loading small font
lsl  r3,r0,#2
add  r0,r0,r3
lsl  r0,r0,#1             // multiply by 0xA
add  r0,r2,r0             // get the address
mov  r1,sp
mov  r2,#4
swi  #0xB                 // CpuSet for 8 bytes
ldr  r0,=#{small_font_usage}
add  r0,r0,r4
ldrb r0,[r0,#0]           // Load tile usage for the letter
bx   lr


//============================================================================================
// This section of code stores the letter from the font's data to the stack.
// Main font version. Returns if there is data to print or not.
// r0 is the letter. r1 is the stack pointer
//============================================================================================

.fast_prepare_main_font:
mov  r4,r0
ldr  r2,=#{main_font}     // we already know we're loading main font
lsl  r0,r0,#5
add  r0,r2,r0             // get the address
mov  r1,sp
mov  r2,#0x10
swi  #0xB                 // CpuSet for 0x20 bytes
ldr  r0,=#{main_font_usage}
add  r0,r0,r4
ldrb r4,[r0,#0]           // Load tile usage for the letter
bx   lr


//============================================================================================
// This section of code stores the current letter to be printed into our RAM block.
// Call from 8049466.
//============================================================================================

.store_letter:
push {r4,r7,lr}
mov  r7,r2
ldr  r1,[r7,#{wbuf_stk}] // r1 has RAM block address

lsl  r0,r0,#0x18
lsr  r0,r0,#0x18
strh r0,[r1,#0x8]        // store r0 (current letter value) in RAM block

lsl  r3,r0,#0x18
lsr  r3,r3,#0x18


// 20225C4 holds a pointer to the current font
// It can be either 8CE39F8 (main) or 8D0B010 (small)
// From that we want to get the widths pointer, which is 8D1CE78 (main) or 8D1CF78 (small)
// I'm assuming we only ever use this for main and small fonts...
ldr  r2,[r7,#{cfm_stk}]
ldr  r4,[r2,#0]
ldr  r2,[r7,#{mfont_stk}]
cmp  r2,r4
bne  +
// We're using main font
ldr  r2,[r7,#{mfontw_stk}]
b    .store_letter_next
+
ldr  r2,[r7,#{sfontw_stk}]



.store_letter_next:
ldrb r2,[r2,r3]          // get the current letter's width
strb r2,[r1,#0x6]        // store the current letter's width in the RAM block

ldrb r1,[r6,#0x10]       // code we clobbered
mov  r0,#0x80
lsl  r1,r1,#0x1C
pop  {r4,r7,pc}

//============================================================================================
// This section of code signals the game to start from a new sprite after certain control
// codes, like FF01 ([BREAK]) codes are encountered. Call from 8049374.
//============================================================================================

.cc_check:
push {lr}
add  r7,sp,#0x4

ldr  r0,=#0xFF01         // [BREAK] check
cmp  r1,r0
beq  .break_found

ldr  r0,=#0xFFE1         // [STATUSICON] check
cmp  r1,r0
beq  .icon_found

b    .cc_check_end

//--------------------------------------------------------------------------------------------

.break_found:
ldr  r1,[r7,#{wbuf_stk}]
ldrb r0,[r1,#0x7]        // load new_tile_flag
cmp  r0,#0               // if this == TRUE, then we need to move the tile, allocate the sprite
beq  +                   // and all that stuff ourselves

bl   .sprite_snip
bl   .update_x_coord
bl   .custom_create_sprite
//b    .cc_set_stuff

//--------------------------------------------------------------------------------------------

+
//ldr  r1,[r7,#{wbuf_stk}]
//ldrb r0,[r1,#0xB]        // load redraw_flag
//cmp  r0,#0               // if this == FALSE, skip the obj update
//beq  .cc_set_stuff
//bl   .update_obj_tile

//--------------------------------------------------------------------------------------------

.cc_set_stuff:
ldr  r1,[r7,#{wbuf_stk}]
mov  r0,#0
strb r0,[r1,#0x5]        // curr_x = 0
mov  r0,#1
strb r0,[r1,#0x7]        // new_tile_flag = TRUE
strb r0,[r1,#0xA]        // new_line_flag = TRUE

//--------------------------------------------------------------------------------------------

.cc_check_end:
ldrb r0,[r4,#0x3]
mov  r1,#0x8
pop  {pc}

//--------------------------------------------------------------------------------------------

.icon_found:
mov  r0,#1
str  r0,[r7,#0x48]       // set "has_icon" to true
ldr  r1,[r7,#{wbuf_stk}]
ldrb r0,[r1,#0x5]
cmp  r0,#3
bgt  +

bl   .sprite_snip

+
ldr  r1,[r7,#{wbuf_stk}]
ldrb r0,[r1,#0x7]        // load new_tile_flag
cmp  r0,#0               // if this == TRUE, we 
beq  +

bl   .update_x_coord

+
ldr  r1,[r7,#{wbuf_stk}]
ldrb r0,[r1,#0x7]        // load new_tile_flag
cmp  r0,#0               // if this == TRUE, we need to mess with this sprite and the next one
beq  .icon_end

bl   .custom_create_sprite

.icon_end:
ldr  r1,[r7,#{wbuf_stk}]
mov  r0,#1
strb r0,[r1,#0x7]        // new_tile_flag = TRUE

b    .cc_check_end


//============================================================================================
// This section of code makes the game allocate a new sprite if necessary. This is one of
// the most important parts of the whole sprite text welding stuff. Call from 80493B4.
//============================================================================================
//
// PSEUDOCODE:
//
//if new_tile == TRUE
//
//   if (newline == FALSE && firstletter == FALSE)
//      add tile width
//
//   if veryfirsttile == FALSE
//      move to next tile()
//   create sprite()
//
//   if firstletter == TRUE || newline == TRUE
//      clear current tile
//
//new_tile = FALSE
//newline  = FALSE
//
//jump to proper location
//--------------------------------------------------------------------------------------------

.create_sprite:
push {lr}
add  r7,sp,#4             // we'll need this value for the subroutine calls later

ldr  r2,[r7,#{wbuf_stk}]
ldrb r0,[r2,#0x7]         // load new_tile_flag
cmp  r0,#0
beq  .create_sprite_end   // if FALSE, don't need to move to next tile or create a new sprite

//--------------------------------------------------------------------------------------------

ldrb r0,[r2,#0xA]        
cmp  r0,#0                // if new_line_flag == FALSE, we want to add the sprite width
bne  +                    // so jump over the adding code if it's TRUE and we ARE on a new line

ldr  r0,[r7,#0x14]        // load r0 with the current letter # we're on
cmp  r0,#0                // if it's 0, we don't want to add the sprite width
beq  +

bl   .update_x_coord

//--------------------------------------------------------------------------------------------
+
ldr  r0,[r7,#{letter_stk}]// now to see what tile # we're on
ldrb r0,[r0,#0]
cmp  r0,#0                // r0 now has the tile # we're on
beq  +                    // if it's 0, we don't need to move to the next tile

//bl   .update_obj_tile
bl   .move_to_next_tile   // move to the next tile over

+
bl   .custom_create_sprite

//--------------------------------------------------------------------------------------------

.clear_glyph_check:
ldr  r2,[r7,#{wbuf_stk}]
ldrb r0,[r2,#0xA]         // if we're doing a newline, we need to clear out the glyph
cmp  r0,#0
bne  +

ldrb r0,[r2,#0x5]         // load curr_x
cmp  r0,#0                // if curr_x == 0, we need to clear out the current tile
beq  +

ldr  r0,[r7,#0x14]        // load r0 with the current letter # we're on
cmp  r0,#0                // if it's 0, we want to clear the current glyph
bne  .create_sprite_end

+
ldrb r0,[r2,#0xB]         // load redraw_flag
cmp  r0,#0                // if redraw_flag == FALSE, don't clear out the glyph
beq  +

add  r0,r5,#4             // give r0 the address of the current glyph data
bl   .clear_glyph         // call our function to clear out the current glyph

+
mov  r0,#0
strb r0,[r2,#0x5]         // curr_x = 0

//--------------------------------------------------------------------------------------------

.create_sprite_end:
mov  r0,#0
strb r0,[r2,#0x7]         // new_tile_flag = FALSE
strb r0,[r2,#0xA]         // new_line_flag = FALSE

//ldr r0,=#.mr_aftercreatesprite
//ldr  r0,=#0x80493E6       // jump to the correct place back in the main code
//mov  pc,r0
//bx   lr
pop    {pc}


//============================================================================================
// This section of code adds the current width and does width checking and all that.
// It'll also tell the game to move to the next tile if width > 16. Call from 8049512.
//============================================================================================

.add_width:
push {lr}
// load r0 with the custom RAM block's address
ldr  r0,[sp,#4+{wbuf_stk}]
ldrb r2,[r0,#0x5]        // load curr_x
ldrb r3,[r0,#0x6]        // load curr_width
add  r2,r2,r3            // curr_x += curr_width
strb r2,[r0,#0x5]        // store the new curr_x back

cmp  r2,#16              // if the new x is >= 16, we need to update stuff
blt  .add_width_end      // else just skip to the end

//-------------------------------------------------------------------------------------------

cmp  r2,#0x20
blt  +
push {r7}                // handle exceptionally long letters (> 16 pixels long)
add  r7,sp,#8
push {r2}
bl   .move_to_next_tile
bl   .update_x_coord     // finish printing them
bl   .custom_create_sprite
pop  {r2}
ldrh r0,[r7,#4]
lsr  r1,r2,#4
lsl  r1,r1,#4            // properly place the next double tile's X coordinate
sub  r1,#0x20
add  r0,r1,r0
strh r0,[r7,#4]
pop  {r7}
+

// load r0 with the custom RAM block's address
ldr  r0,[sp,#4+{wbuf_stk}]
lsl  r2,r2,#0x1C         // calculate the new curr_x for the new sprite tile
lsr  r2,r2,#0x1C
strb r2,[r0,#0x5]        // store the new curr_x
mov  r2,#1
strb r2,[r0,#0x7]        // new_tile_flag = TRUE

//-------------------------------------------------------------------------------------------

.add_width_end:
pop  {pc}

//============================================================================================
// This section of code is called when a string has just finished being processed. We need
// to do a few last things to ensure the full string gets displayed. Called from 8049558.
//============================================================================================

.eos_stuff:
push {r7,lr}
add  r7,sp,#0x8

//ldr  r3,[r7,#{wbuf_stk}] // load r3 with the custom RAM block's address
//ldrb r0,[r3,#0xB]        // r0 = redraw_flag
//cmp  r0,#0
//beq  +
//bl   .update_obj_tile

//+
ldr  r3,[r7,#{wbuf_stk}] // load r3 with the custom RAM block's address
ldrb r0,[r3,#0x7]        // r0 = new_tile_flag
cmp  r0,#0               // if we didn't just move to a new tile, no problem, skip ahead
beq  +

ldrb r0,[r3,#0x5]        // load r0 with curr_x
cmp  r0,#1               // if we started a new tile and our curr_x < 1, we don't really
blt  +                   // need to allocate a new tile and sprite, it'd be a complete waste

bl   .sprite_snip
bl   .update_x_coord
bl   .custom_create_sprite

+
ldr  r3,[r7,#{wbuf_stk}] // load r3 with the custom RAM block's address
mov  r1,#1
strb r1,[r3,#0x7]        // new_tile_flag = TRUE
pop  {r7,pc}


//============================================================================================
// This section of code clears out the glyph whose address starts at r0. It's assumed that
// there are 0x80 bytes in the glyph. Called by a custom hack.
//============================================================================================

.clear_glyph:
push {r0-r3,lr}
mov  r1,r0               // give r0 to r1, since r1 needs to contain the target address
mov  r0,#0
str  r0,[r2,#0]          // store 0x00000000 in our RAM block
mov  r0,r2
mov  r2,#0x40            // give r2 the number of halfwords to clear
mov  r3,#1
lsl  r3,r3,#24
orr  r2,r3               // set the 24th bit of r2 so it'll know to fill instead of copy
swi  #0x0B               // clear the next glyph out
pop  {r0-r3,pc}

//============================================================================================
// This section of code makes the game move to the next tile area in OBJ memory.
// Called by custom hacks. r7 needs to have the SP + push offset caused by calling this.
//============================================================================================

.move_to_next_tile:
push {r0-r3,lr}

add  r4,#0x8C            // this is the original code, it's used to increment to the
ldr  r1,[r7,#0x24]       // next struct glyph. r5 points to the actual glyph data itself
add  r1,#0x8C            // within the struct, not sure what the others are but oh well
str  r1,[r7,#0x24]
add  r5,#0x8C

ldr  r0,[r7,#0x18]       // original code, not sure what it does
add  r0,#4
str  r0,[r7,#0x18]

ldr  r2,[r7,#0x0C]       // original code, calculates the next target address in OBJ memory
add  r2,#0x80            // we're going to need to do this at EOS, will figure out later
str  r2,[r7,#0x0C]

//ldr  r1,[sp,#0xC]
str  r2,[r5,#0]          // store the target OBJ address in struct header

//ldr  r1,=#0x2014320       // increment the total # of sprites used
//ldrb r0,[r1,#0x4]
//add  r0,#1
//strb r0,[r1,#0x4]

pop  {r0-r3,pc}

//============================================================================================
// This section of code allocates a new sprite. It's called by a custom hack.
//============================================================================================

.custom_create_sprite:
push {r0,r7,lr}

mov  r2,r7
mov  r7,#6
ldsh r1,[r2,r7]
mov  r7,#4
ldsh r0,[r2,r7]
lsl  r0,r0,#0x10
orr  r1,r0

// 20225C4 holds a pointer to the current font
// It can be either 8CE39F8 (main) or 8D0B010 (small)
// From that we want to use different sizes for the sprites
// I'm assuming we only ever use this for main and small fonts...
ldr  r0,[r2,#{cfm_stk}]
ldr  r7,[r0,#0]
ldr  r0,[r2,#{mfont_stk}]
cmp  r0,r7
bne  +
mov  r0,#0x80
lsl  r0,r0,#0x17                       //16x16 if the font is the main one
b    .custom_create_sprite_oam_create 

+
mov  r0,#0x40
lsl  r0,r0,#8                          //16x8 if the font is the small one

.custom_create_sprite_oam_create:
orr  r1,r0
ldr  r0,[r2,#0x1C]
str  r1,[r0,#0]
ldrb r0,[r6,#0x10]
lsl  r0,r0,#0x1A
lsr  r0,r0,#0x1E
lsl  r0,r0,#0x0A
ldr  r1,[r2,#0x18]
orr  r0,r1
mov  r1,#0xE0
lsl  r1,r1,#8
orr  r0,r1
ldr  r1,[r2,#0x1C]
strh r0,[r1,#0x4]
add  r1,#8
str  r1,[r2,#0x1C]

ldr  r7,[r2,#{wbuf_stk}]               // increment the total # of sprites used
ldrb r0,[r7,#0x4]
add  r0,#1
strb r0,[r7,#0x4]

pop  {r0,r7,pc}

//============================================================================================
// This section of code manually updates the current tile in OBJ memory.
//============================================================================================

.update_obj_tile:
push {lr}

mov  r0,r5
add  r0,#4
ldr  r1,[r7,#0x0C]       // get current OBJ memory address to write to
mov  r2,#0x80            // number of bytes to transfer
bl   $8001A14            // call a built-in subroutine to DMA r0 to r1 for r2 bytes

pop  {pc}

//============================================================================================
// This section of code manually updates the current sprite's x coordinate.
//============================================================================================

.update_x_coord:
push {lr}

ldr  r0,[r7,#{coord_stk}]// this code adds to the sprite's x coordinate.
ldrb r0,[r0,#0]          // it'll almost always be 16 pixels
ldrh r1,[r7,#0x4]
add  r1,r1,r0
strh r1,[r7,#0x4]

pop  {pc}


//============================================================================================
// This section of code is called by custom hacks in the rare instances of a partial letter
// in a new tile right before an [END] code or a control code.
// r7 needs to have the proper location on the stack
//============================================================================================

.sprite_snip:
push {r0-r1,lr}

bl   .move_to_next_tile
//bl   .write_struct_info
//bl   .update_obj_tile

pop  {r0-r1,pc}

//============================================================================================
// This hack is called to save a letter's width to the stack
//============================================================================================

.save_letters_width:
push {r4-r5}

// r5 has RAM block address
ldr  r5,[sp,#{wbuf_stk}+0x8]

ldr  r0,[sp,#0x8]
ldrh r0,[r0,#0x0]
strh r0,[r5,#0x8]        // store r0 (current letter value) in RAM block


// 20225C4 holds a pointer to the current font
// It can be either 8CE39F8 (main) or 8D0B010 (small)
// From that we want to get the widths pointer, which is 8D1CE78 (main) or 8D1CF78 (small)
// I'm assuming we only ever use this for main and small fonts...
ldr  r2,[sp,#{cfm_stk}+0x8]
ldr  r4,[r2,#0]
ldr  r2,[sp,#{mfont_stk}+0x8]
cmp  r2,r4
bne  +
// We're using main font
ldr  r2,[sp,#{mfontw_stk}+0x8]
b    .save_letters_width_next
+
ldr  r2,[sp,#{sfontw_stk}+0x8]


.save_letters_width_next:
ldrb r2,[r2,r0]          // get the current letter's width
strb r2,[r5,#0x6]        // store the current letter's width in the RAM block
pop  {r4-r5}
bx   lr

//============================================================================================
// This hack is called to give the game's OAM clearer an accurate count of the # of sprites
// used. This fixes some garbage sprite bugs we had. This is called from 803EA6C.
//============================================================================================

.fix_sprite_total:
ldr  r5,=#0x2014320
ldrb r5,[r5,#0x4]
bx   lr

//============================================================================================
// This hack is used to fix the x-coord of status icons within sprite text.
// Called from 80496A4.
//============================================================================================

.get_icon_coord:
mov  r1,sp
ldrb r1,[r1,#0x1C]     // load the x coord of the current text sprite

push {r0,r2}
ldr  r2,=#0x2014320    // we need to load curr_x so we know how many pixels in the current
ldrb r0,[r2,#0x5]      // text sprite we've gone
add  r1,r1,r0
mov  r0,#0
strb r0,[r2,#0x5]      // curr_x = 0

add  r2,sp,#8
strb r1,[r2,#0x1C]     // store the icon's x as the current x
pop  {r0,r2}

bx   lr


//============================================================================================
// This part is where we do our efficiency checks, the pseudocode is as follows:
//
//   if curr_letter == 0
//   {
//      if redraw_flag == FALSE
//      {
//         if curr_address != address[tableptr * 4]
//            redraw_flag = TRUE
//         else if curr_str_len != strlen[tableptr]
//            redraw_flag = TRUE
//         else if curr_hash != hash[tableptr * 4]
//            redraw_flag = TRUE
//      }
//
//      address[tableptr * 4] = curr_address
//      strlen[tableptr] = curr_str_len
//      hash[tableptr] = curr_hash
//
//      tableptr++
//   }
//
//============================================================================================

.efficiency_check:
push {r0-r7,lr}

add  r7,sp,#0x24         // make r7 be the pretend sp

//-------------------------------------------------------------------------------------------

ldr  r6,[sp,#{dbuf_stk}+0x24] // if fadeout_flag = TRUE, then don't bother with these checks
mov  r1,#0x2D
ldrb r0,[r6,r1]
cmp  r0,#0
beq  +
add  r6,#0x20
b    .inc_table_loc
+

ldr  r1,[sp,#0x18]       // at [[sp,#0x18],#0x0] is the address of the current string
ldr  r0,[r1,#0x0]        // r0 now has the current string's address
ldrh r1,[r1,#0xE]        // at [[sp,#0x18],#0xE] is the string length
bl   .get_hash           // get the hash value for the current string, return value in r0
str  r0,[r6,#0x0]        // store our hash temporarily for easy access

add  r6,#0x20            // r6 = address of our RAM block
ldrb r0,[r6,#0xB]        // load redraw_flag
cmp  r0,#0               // if already TRUE, then skip the following checks
bne  .update_tables

//-------------------------------------------------------------------------------------------

.address_check:
ldr  r5,[sp,#{oabuf_stk}+0x24]// r5 = base address of address table
ldrb r0,[r6,#0xC]
lsl  r0,r0,#2            // r0 = table_loc * 4
mov  r2,r0
ldr  r0,[r5,r0]          // r0 = last address

//ldr  r3,=#0x203FFA0
//ldr  r4,[r3,r2]
ldr  r4,[sp,#0x18]       // at [[sp,#0x18],#0x0] is the address of the current string
ldr  r4,[r4,#0x0]        // r4 now has the current string's address

cmp  r4,r0
beq  .length_check
//beq  .inc_table_loc       // if curr_address == last_address, move to the string length test

mov  r0,#1
strb r0,[r6,#0xB]        // else redraw_flag = TRUE
ldr  r0,[r7,#0x24]       // r0 = address of current glyph now
bl   .clear_glyphs
b    .update_tables

//-------------------------------------------------------------------------------------------

.length_check:

// r5 = base address of string length table
ldr  r5,[sp,#{oslbuf_stk}+0x24]
ldrb r0,[r6,#0xC]        // load table_loc
ldrb r0,[r5,r0]          // r0 = last_str_len

ldr  r4,[sp,#0x18]       // at [[sp,#0x18],#0xE] is the string length
ldrh r4,[r4,#0xE]        // r4 now has the string length

cmp  r4,r0               // if curr_len == last_str_len, move on ahead
beq  .hash_check

mov  r0,#1
strb r0,[r6,#0xB]        // else redraw_flag = TRUE
ldr  r0,[r7,#0x24]       // r0 = address of current glyph now
bl   .clear_glyphs
b    .update_tables

//-------------------------------------------------------------------------------------------

.hash_check:
ldr  r5,[sp,#{ohbuf_stk}+0x24]// r5 = base address of hash table
ldrb r0,[r6,#0xC]
lsl  r0,r0,#2            // r0 = table_loc * 4
ldr  r0,[r5,r0]          // r0 = last hash

sub  r6,#0x20
ldr  r1,[r6,#0x0]        // r1 = current hash
add  r6,#0x20

cmp  r0,r1
beq  .inc_table_loc      // if curr_hash == last_hash, no need to redraw stuff

mov  r0,#1
strb r0,[r6,#0xB]        // else redraw_flag = TRUE
ldr  r0,[r7,#0x24]       // r0 = address of current glyph now
bl   .clear_glyphs

//-------------------------------------------------------------------------------------------

.update_tables:
ldrb r0,[r6,#0xC]        // load table_loc

// r5 = base address of string length table
ldr  r5,[sp,#{oslbuf_stk}+0x24]
ldr  r4,[sp,#0x18]       // at [[sp,#0x18],#0xE] is the string length
ldrh r4,[r4,#0xE]        // r4 now has the string length
strb r4,[r5,r0]          // store the current string length in the proper table spot

sub  r5,#0x40            // r5 = base address of address table
lsl  r0,r0,#2            // r0 = table_loc * 4
ldr  r4,[r3,r0]
ldr  r4,[sp,#0x18]       // at [[sp,#0x18],#0x0] is the address of the current string
ldr  r4,[r4,#0x0]        // r4 now has the current string's address
str  r4,[r5,r0]          // store the current address in the proper table spot

sub  r5,#0x40            // r5 = base address of hash table
sub  r6,#0x20
ldr  r4,[r6,#0x0]        // load current hash
add  r6,#0x20
str  r4,[r5,r0]          // store current hash in the proper table spot

//-------------------------------------------------------------------------------------------

.inc_table_loc:

ldrb r0,[r6,#0xC]        // table_loc++
add  r0,#1
strb r0,[r6,#0xC]

//-------------------------------------------------------------------------------------------

.eff_check_end:
pop  {r0-r7}          // restore registers and return


pop  {pc}


//============================================================================================
// This is the code that tells the game if it needs to re-prepare the OAM entries or not
//============================================================================================

.recycle_branch:
push {lr}
ldr  r0,[sp,#{wbuf_stk}+4]
ldrb r2,[r0,#0xB]         // load redraw_flag
cmp  r2,#0
bne  .recycle_branch_unsuccessful
ldr  r2,[sp,#{ocbuf_stk}+4]
ldrb r0,[r0,#0xC]         // current entry + 1
sub  r0,#1
lsl  r0,r0,#1
add  r0,r2,r0             // get its previous X and Y
ldrh r0,[r0,#0]
lsr  r1,r0,#8
lsl  r1,r1,#0x10
lsl  r0,r0,#0x18
lsr  r0,r0,#0x18
orr  r0,r1
ldr  r1,[r6,#8]           //If they're not the same, reprint the entry
cmp  r0,r1
bne  .recycle_branch_unsuccessful

mov  r0,#1
b    +

.recycle_branch_unsuccessful:
mov  r0,#0

+
pop  {pc}


//============================================================================================
// This is the code that tells the game if it needs to re-prepare the OAM entries or not.
// r0 will be the stack pointer
//============================================================================================

.recycle_old_oam:
push {r4-r7,lr}
mov  r4,r0
ldr  r5,[r4,#{wbuf_stk}]
ldr  r7,[r4,#{olbuf_stk}]
ldrb r0,[r5,#0xC]         // current entry + 1
sub  r0,#1
add  r7,r7,r0             // get its previous length
ldrb r3,[r7,#0]
lsl  r3,r3,#0x19
lsr  r3,r3,#0x19         // ignore "has_icon" in length
cmp  r3,#0
beq  .recycle_old_oam_success
ldr  r0,[r4,#0x18]
ldr  r6,[r4,#{letter_stk}]// now to see if this is the first letter or not
ldrb r2,[r6,#0]
cmp  r2,#0                // r2 now has the letter # we're on
beq  +
add  r0,#4
+
lsr  r0,r0,#2
mov  r2,#7
lsl  r2,r2,#0x18
mov  r1,#{oam_tiles_stack_buffer}
add  r1,r1,r4             // get to the tiles buffer
add  r0,r1,r0             // get to the tiles entry in the buffer
ldrb r0,[r0,#0]
cmp  r0,#0xFF             // signal we failed finding the tile if this is 0xFF
beq  .recycle_old_oam_failure
lsl  r0,r0,#3
add  r0,r2,r0             // get to the proper starting OAM entry

push {r3}
ldr  r1,[r4,#0x1C]
lsl  r2,r3,#2
swi  #0xB

pop  {r3}
ldr  r0,[r4,#0x1C]
lsl  r1,r3,#3
add  r0,r0,r1             // increase the oam pile address
str  r0,[r4,#0x1C]
ldr  r0,[r4,#0x18]
lsl  r1,r3,#2
add  r0,r0,r1             // increase the number of the next target tile
str  r0,[r4,#0x18]
ldr  r0,[r4,#0xC]
lsl  r1,r3,#7
add  r0,r0,r1             // increase the address
str  r0,[r4,#0xC]
ldrb r0,[r5,#4]
add  r0,r0,r3             // increase the number of used sprites
strb r0,[r5,#4]
mov  r1,#1
strb r1,[r5,#0x7]         // new_tile_flag = TRUE
mov  r1,#0
strb r1,[r5,#0xA]         // new_line_flag = FALSE
ldrb r3,[r7,#0]           // get its previous length
lsr  r3,r3,#7             // get "has_icon"
str  r3,[r4,#0x48]        // save "has_icon"
cmp  r3,#0
beq  +
mov  r0,r5
bl   .handle_icons_recycled_oam
+

.recycle_old_oam_success:
mov  r0,#1

.recycle_old_oam_end:
pop  {r4-r7,pc}

.recycle_old_oam_failure:
mov  r0,#0
b    .recycle_old_oam_end


//============================================================================================
// Sets the icon's OAM entry to printing by loading it from our cache
//============================================================================================

.handle_icons_recycled_oam:
push {lr}
ldr  r0,=#0x2016028+0x41E0
ldr  r1,=#0x2014240-4
ldrb r2,[r1,#0]
strh r2,[r0,#0]
ldrb r2,[r1,#1]
strh r2,[r0,#2]
ldrb r2,[r1,#2]
strh r2,[r0,#4]
ldrb r2,[r1,#3]
strb r2,[r0,#6]
pop  {pc}


//============================================================================================
// Read the icon's OAM entry and save it in our cache
//============================================================================================

.save_icons:
push {lr}
ldr  r0,=#0x2016028+0x41E0
ldr  r1,=#0x2014240-4
ldrh r2,[r0,#0]
strb r2,[r1,#0]
ldrh r2,[r0,#2]
strb r2,[r1,#1]
ldrh r2,[r0,#4]
strb r2,[r1,#2]
ldrb r2,[r0,#6]
strb r2,[r1,#3]
pop  {pc}


//============================================================================================
// This is the code that prepares some data used in order to avoid re-preparing OAM entries
// when it's not needed. r0 is the stack pointer
//============================================================================================

.save_entry_info:
push {r0-r5,lr}
mov  r5,r0                // stack pointer
ldr  r1,[r5,#{wbuf_stk}]
ldr  r2,[r5,#{ocbuf_stk}]
ldrb r4,[r1,#0xC]         // current entry + 1
sub  r4,#1
lsl  r3,r4,#1
add  r3,r3,r2
ldrh r0,[r6,#8]
strb r0,[r3,#0]
ldrh r0,[r6,#0xA]         // save X and Y coords
strb r0,[r3,#1]
add  r2,#0x20
ldrb r3,[r1,#4]           // current sprite total
ldr  r0,[r5,#0x40]        // old sprite total
sub  r3,r3,r0             // entry's sprite length
add  r2,r2,r4
ldr  r0,[r5,#0x48]        // get "has_icon" from stack
lsl  r0,r0,#7             // max length = 0x5F
orr  r3,r0                // orr them together so we use the length byte for other things
strb r3,[r2,#0]           // save it here
cmp  r0,#0                // if "has_icon" is true, save it
beq  +
bl   .save_icons
+

pop  {r0-r5,pc}


//============================================================================================
// This code resets some data when redraw_flag is FALSE, since we're not actually
// printing entries. r0 is the stack pointer
//============================================================================================

.reset_data_redrawing:
push {lr}
ldr  r1,[r0,#{wbuf_stk}]
ldrb r2,[r1,#0xB]         // load redraw_flag
cmp  r2,#0
bne  .reset_data_redrawing_end
strb r2,[r1,#4]           // we're not printing entries, put this back to 0!
ldr  r3,[r0,#{letter_stk}]
ldrb r2,[r3,#0]           // is this 0?
cmp  r2,#0
beq  +

mov  r2,#0
strb r2,[r3,#0]           // if not, reset the letters counter
ldr  r2,[r0,#0x18]
add  r2,#4                // increase the number of the next target tile
str  r2,[r0,#0x18]
ldr  r2,[r0,#0xC]
add  r2,#0x80             // increase the address
str  r2,[r0,#0xC]

+
mov  r2,#0x98             // reset this to the first entry
lsl  r2,r2,#0x6
ldr  r1,[r0,#8]
add  r5,r1,r2

.reset_data_redrawing_end:
pop  {pc}


//============================================================================================
// This code saves to the stack the current amount of OAM entries. r0 is the stack pointer
//============================================================================================

.save_current_sprite_total:
push {r1,lr}
ldr  r1,[r0,#{wbuf_stk}]
ldrb r1,[r1,#4]           // current sprite total
str  r1,[r0,#0x40]        // save to stack
pop  {r1,pc}


//============================================================================================
// This routine is called by our custom hack. It clears out all glyphs from the current one.
//============================================================================================

.clear_glyphs:
push {r0-r5,lr}
mov  r1,r0
mov  r2,#0
str  r2,[r6,#0]          // store 0x00000000 in our RAM block
mov  r0,r6

ldr  r5,=#0x201F994
sub  r5,r5,r1
lsr  r2,r5,#1            // r2 has the number of halfwords to clear

mov  r3,#1
lsl  r3,r3,#24
orr  r2,r3               // set the 24th bit of r2 so it'll know to fill instead of copy
swi  #0x0B               // clear the next glyph out

pop  {r0-r5,pc}


//============================================================================================
// This routine is called right after all a fadeout starts. This code sets a flag that tells
// the sprite welding hack to skip some CPU intensive stuff since we can assume text won't
// change during a fadeout. Called from 803E170.
//============================================================================================

.set_fadeout_flag:
push {r1,lr}

ldr  r1,=#0x2014320
mov  r0,#0x1
strb r0,[r1,#0xD]        // fadeout_flag = TRUE

ldr  r0,=#0x20051E8      // clobbered code
ldrb r0,[r0,#0]

pop  {r1,pc}


//============================================================================================
// This code "breaks" the "last loop table", and is called between screen transitions.
// This fixes a bug with the sprite text. Called from 803E24C.
//============================================================================================

.clear_table:
push {lr}

mov  r0,#1
neg  r0,r0

ldr  r1,=#0x2014240-4    // r1 = base address of icon cache
str  r0,[r1,#0]          // void the icon cache

add  r1,#4               // r1 = base address of position table
str  r0,[r1,#0]          // store FFFF as the first two positions

add  r1,#0x20            // r1 = base address of OAM size table
str  r0,[r1,#0]          // store FF as the first four OAM sizes

add  r1,#0x10            // r1 = base address of hash table
str  r0,[r1,#0]          // store FFFFFFFF as the current hash

add  r1,#0x40            // r1 = base address of address table
str  r0,[r1,#0]          // store FFFFFFFF as the address

add  r1,#0x40            // r1 = base address of string length table
str  r0,[r1,#0]          // store FF as the first four string lengths in the table

//add  r1,#0x10            // r1 = base address of our RAM block



ldr  r1,=#0x2014320
mov  r0,#0
strb r0,[r1,#0xD]        // fadeout_flag = FALSE
mov  r0,#0xFF
strb r0,[r1,#0xE]        // set last number of strings = FF

pop  {r0}

add  sp,#0x10
pop  {r4-r6}
bx   r0


//============================================================================================
// This code gets a hash for the string in r0 with length r1. Used by our sprite text hack
// so it can tell when text has changed.
//============================================================================================

.get_hash:
push {r2-r7,lr}
// r0 = source address
// r1 = length
ldr  r2,[sp,#{hprime_stk}+0x24+0x1C] // FNV_prime
ldr  r3,[sp,#{hoffset_stk}+0x24+0x1C]// offset_basis/hash
mov  r4,#0                 // counter
cmp  r1,#0
bne  +
mov  r5,#0
b    .get_hash_element
+
-
ldrh r5,[r0,#0]
add  r0,#2
add  r4,#1
.get_hash_element:
eor  r3,r5                 // hash ^= data
mul  r3,r2                 // hash *= FNV_prime
cmp  r4,r1
blt  -
// r0 = resulting hash
mov  r0,r3
pop  {r2-r7,pc}            // restore registers and leave


//============================================================================================
// This code understands if an entry is from a character or not
//============================================================================================

define first_char_name $200417E
define char_data_size $6C

.is_entry_character_name:
push {lr}
ldr  r1,=#{first_char_name}
sub  r0,r0,r1
mov  r1,#{char_data_size}
swi  #6
mov  r2,#0
cmp  r1,#0
bne  +
cmp  r0,#0xC
bgt  +
mov  r2,#1                             //This is a character's name
+
mov  r0,r2
pop  {pc}


//============================================================================================
// This code sets caches addresses of certain entries' addresses in order to make
// the checking process in .special_checks_move_zone faster later
//============================================================================================

define on_whom_entry $3B
define on_whom_address $30
define menu_entry $3C
define menu_address $34
define to_whom_entry $3D
define to_whom_address $38
define give_entry $3F
define give_address $3C

.special_checks_setup:
push {r4,lr}
mov  r4,r0
ldr  r2,[r0,#0x2C]                     //Which menu is this?
cmp  r2,#3
bgt  .special_checks_setup_end
cmp  r2,#0
beq  .special_checks_setup_inventory
cmp  r2,#2
beq  .special_checks_setup_psi

.special_checks_setup_status_equip:
mov  r0,#0
str  r0,[r4,#0x30]                     //OAM Address
str  r0,[r4,#0x34]                     //Tile
b    .special_checks_setup_end

.special_checks_setup_psi:
mov  r0,#{on_whom_entry}
bl   $80486A0                          //Get the address for this entry
str  r0,[r4,#{on_whom_address}]        //Cache the address for later
b    .special_checks_setup_end

.special_checks_setup_inventory:
mov  r0,#{on_whom_entry}
bl   $80486A0                          //Get the address for this entry
str  r0,[r4,#{on_whom_address}]        //Cache the address for later
mov  r0,#{menu_entry}
bl   $80486A0                          //Get the address for this entry
str  r0,[r4,#{menu_address}]           //Cache the address for later
mov  r0,#{to_whom_entry}
bl   $80486A0                          //Get the address for this entry
str  r0,[r4,#{to_whom_address}]        //Cache the address for later
mov  r0,#{give_entry}
bl   $80486A0                          //Get the address for this entry
str  r0,[r4,#{give_address}]           //Cache the address for later

.special_checks_setup_end:
pop  {r4,pc}


//============================================================================================
// This code sets specific entries in certain menus to an OAM zone in order to prevent
// issues with flickering.
// r0 = Stack pointer of the main function
//============================================================================================

define new_pos_base $6011800
define new_pos_tile $C0
define new_pos_base_alternative $6011C00
define new_pos_tile_alternative $E0
define new_pos_base_alternative2 $6012000
define new_pos_tile_alternative2 $100

.special_checks_move_zone:
push {r4-r5,r7,lr}
mov  r4,r0
ldr  r2,[r4,#0x2C]         //Which menu is this?
cmp  r2,#3
bgt  .special_checks_move_zone_end
cmp  r2,#0
beq  .special_checks_move_zone_inventory
cmp  r2,#2
beq  .special_checks_move_zone_psi

.special_checks_move_zone_status_equip:
ldr  r0,[r4,#0]
bl   .is_entry_character_name
cmp  r0,#1
bne  +
ldr  r0,[r4,#0xC]
ldr  r1,[r4,#0x18]
mov  r3,#1
bl   .handle_changing_tile_special_checks
str  r0,[r4,#0x30]         //Temp store the tile and address that should normally be next
str  r1,[r4,#0x34]
ldr  r0,=#{new_pos_base_alternative2}
ldr  r1,=#{new_pos_tile_alternative2}
b    .special_checks_move_zone_change_place

+
ldr  r0,[r4,#0x30]         //Did we temp store the next tile and address it should have been?
cmp  r0,#0
beq  .special_checks_move_zone_end
mov  r2,#0
ldr  r0,[r4,#0x30]         //If we did, get them and reset them
ldr  r1,[r4,#0x34]
str  r2,[r4,#0x30]
str  r2,[r4,#0x34]
b    .special_checks_move_zone_change_place

.special_checks_move_zone_psi:
ldr  r0,[r4,#{on_whom_address}]
ldr  r1,[r4,#0]
cmp  r0,r1
bne  .special_checks_move_zone_end
ldr  r0,=#{new_pos_base_alternative2}
ldr  r1,=#{new_pos_tile_alternative2}
b    .special_checks_move_zone_change_place

.special_checks_move_zone_inventory:
ldr  r0,[r4,#{menu_address}]
ldr  r1,[r4,#0]
cmp  r0,r1
bne  +
ldr  r0,=#{new_pos_base}
ldr  r1,=#{new_pos_tile}
b    .special_checks_move_zone_change_place

+
ldr  r0,[r4,#{give_address}]
ldr  r1,[r4,#0]
cmp  r0,r1
bne  +
ldr  r0,=#{new_pos_base_alternative}
ldr  r1,=#{new_pos_tile_alternative}
b    .special_checks_move_zone_change_place

+
ldr  r0,[r4,#{on_whom_address}]
ldr  r1,[r4,#0]
cmp  r0,r1
beq  +

ldr  r0,[r4,#{to_whom_address}]
ldr  r1,[r4,#0]
cmp  r0,r1
bne  .special_checks_move_zone_end

+
ldr  r0,=#{new_pos_base_alternative2}
ldr  r1,=#{new_pos_tile_alternative2}

.special_checks_move_zone_change_place:
mov  r3,#0
bl   .handle_changing_tile_special_checks
str  r0,[r4,#0xC]         // change the OAM address this will go to
str  r1,[r4,#0x18]        // change the OAM tile this will go to

.special_checks_move_zone_end:
pop  {r4-r5,r7,pc}


//============================================================================================
// This routine changes the loaded tiles accordingly for special_checks_move_zone
//============================================================================================

.handle_changing_tile_special_checks:
ldr  r2,[r4,#{wbuf_stk}]
ldrb r2,[r2,#0x7]         // load new_tile_flag
cmp  r2,#0
beq  +                    // if FALSE, don't need to move to next tile or create a new sprite
ldr  r2,[r4,#{letter_stk}]// now to see what tile # we're on
ldrb r2,[r2,#0]
cmp  r2,#0                // r2 now has the tile # we're on
beq  +                    // if it's 0, we don't need to move to the next tile
mov  r2,#0x80             // if it's 1, we'll need to move 1 tile later on, prepare for it
cmp  r3,#0
beq  .handle_changing_tile_special_checks_negative
add  r0,r0,r2             // go forward
add  r1,#4
b    +

.handle_changing_tile_special_checks_negative:
neg  r2,r2
add  r0,r0,r2             // go backwards
sub  r1,#4

+
bx   lr


//============================================================================================
// This routine loads the oam tiles buffer if it's not already loaded.
// r0 has the stack pointer
//============================================================================================

.ready_buffer:
push {r4-r5}
mov  r5,r0                // r5 is now the stack pointer
ldr  r0,[r5,#0x4C]
cmp  r0,#0                // check "is_buffer_initialized"
bne  .ready_buffer_end

// first we set the zone in the stack to a certain set of bytes
mov  r0,#1
str  r0,[r5,#0x4C]        // set "is_buffer_initialized" to true
mov  r1,#{oam_tiles_stack_buffer}
mov  r0,r5
add  r1,r0,r1
mov  r0,#0
sub  r0,#1                // set this zone to 0xFFFFFFFF
push {r0}
mov  r0,sp
mov  r3,#1
lsl  r3,r3,#24
mov  r2,#0x18             // 0x60 bytes
orr  r2,r3                // fill with 0xFFFFFFFF
swi  #0xC                 // cpufastset
pop  {r0}

// now we search the OAM for the used tiles
mov  r2,#{oam_tiles_stack_buffer}
mov  r0,r5
add  r2,r0,r2
mov  r3,#7
lsl  r3,r3,#0x18          // load the oam
mov  r4,#0
mov  r5,#2

-
ldrh r1,[r3,#4]
lsl  r1,r1,#0x16
lsr  r1,r1,#0x18
cmp  r1,#0x5F
bgt  +
ldrb r0,[r3,#1]
and  r0,r5
cmp  r0,#0
bne  .ready_buffer_end
add  r1,r2,r1             // get to the buffer's oam entry byte
strb r4,[r1,#0]           // save which entry these tiles are in
+
add  r3,#8
add  r4,#1
cmp  r4,#0x80             // the OAM entries are 0x80
bne  -


.ready_buffer_end:
pop  {r4-r5}
bx   lr


//============================================================================================
// This routine converts the OAM VRAM entries from 1bpp to 4bpp.
// We want to go VERY FAST.
//============================================================================================
.convert_1bpp_4bpp:
push {r2,r4-r6,lr}
ldr  r0,[sp,#{wbuf_stk}+0x14]
ldrb r4,[r0,#4]           // Sprite total
cmp  r4,#0
beq  .convert_1bpp_4bpp_end

ldr  r6,=#0x8CDF9F8
ldr  r2,[sp,#8+0x14]
mov  r1,#0x98
lsl  r1,r1,#0x6
add  r5,r2,r1
add  r5,#4                // Starting tiles

.convert_1bpp_4bpp_loop_start:

ldrb r0,[r5,#8]
cmp  r0,#0
beq  +
mov  r0,#2
bl   convert_1bpp_4bpp_tiles
+

.convert_1bpp_4bpp_loop_bottom:

add  r5,#0x40
ldrb r0,[r5,#8]
cmp  r0,#0
beq  +
mov  r0,#2
bl   convert_1bpp_4bpp_tiles
+

.convert_1bpp_4bpp_loop_end:
sub  r4,#1                // One entry is done
cmp  r4,#0
ble  .convert_1bpp_4bpp_end
add  r5,#0x4C
b    .convert_1bpp_4bpp_loop_start

.convert_1bpp_4bpp_end:
pop  {r2,r4-r6,pc}


//============================================================================================
// This routine is called right after all sprite strings have been processed. It clears out
// any unused portions of the "last time" tables to prevent any weirdness later.
// Called from 804957E.
//============================================================================================

.clear_unused_table_stuff:
push {r0-r7,lr}

ldr  r5,[sp,#0x34]      // r6 = total # of strings we just processed
mov  r1,#1
neg  r1,r1              // r1 = FFFFFFFF
ldr  r3,=#0x2014240     // r4 = base address of the positions table

-
cmp  r5,#16
bge  +

lsl  r2,r5,#2           // r2 = counter * 4 (used for convenience's sake)
lsl  r0,r5,#1           // r0 = counter * 2 (used for convenience's sake)
mov  r4,r3
strh r1,[r4,r0]         // store FFFF at positions table entry

add  r4,#0x20
strb r1,[r4,r5]         // store FF at oam length table entry

add  r4,#0x10
str  r1,[r4,r2]         // store FFFFFFFF at hash table entry

add  r4,#0x40           // r4 = base address of address table
str  r1,[r4,r2]         // store FFFFFFFF at address table entry

add  r4,#0x40           // r4 = base address of string length table
strb r1,[r4,r5]         // store FF at string length table entry

add  r5,#1              // increment counter and loop back
b    -

+
pop  {r0-r7}
ldr  r2,=#0x2018CC0     // code we clobbered
pop  {pc}

.way_out:
ldr  r2,=#0x2014320
mov  r0,#0
strb r0,[r2,#4]         //We're not printing anything. Skip the storing to OAM VRAM
pop  {r4-r7}
pop  {r0}               //We're hard skipping many things!
bx   r0


















.main_routine:
push {r4-r7,lr}
ldr  r4,=#0x201A288
ldrb r2,[r4,#0]
cmp  r2,#0x11
bne  +
ldr  r7,=#0x2003F04                       //If this is the naming screen, then stop printing if the flag is active.
ldrb r7,[r7,#0]
cmp  r7,#2
beq  .way_out
+
mov  r7,r10
mov  r6,r9
mov  r5,r8
push {r5-r7}
add  sp,#-{sprite_text_weld_stack_size}   // currently -0xF8
str  r2,[sp,#0x2C]                        //We'll use this later - Save which menu this is
str  r0,[sp,#0x8]
ldr  r2,=#0x76D9
add  r1,r0,r2
bl   sprite_text_weld.init                // init
bl   .init_stack
mov  r0,sp
bl   .special_checks_setup

ldr  r0,=#0x2016028
ldr  r3,=#0xC620
add  r1,r0,r3
ldr  r7,=#0x2C98
add  r0,r0,r7
ldrh r0,[r0,#0]
lsl  r0,r0,#0x3
ldr  r1,[r1,#0]
add  r1,r1,r0
str  r1,[sp,#0x1C]
str  r1,[sp,#0x20]
ldr  r1,[sp,#0x8]
ldr  r0,[sp,#{numstr_stk}]
ldr  r0,[r0,#0]
ldr  r6,[r0,#0x4]
mov  r3,#0x98
lsl  r3,r3,#0x6
add  r5,r1,r3
ldr  r7,=#0x6010000
str  r7,[sp,#0xC]
mov  r2,#0
str  r2,[sp,#0x4C]                        // set "is_buffer_initialized" to false
str  r2,[sp,#0x18]
str  r2,[sp,#0x10]
ldrb r0,[r0,#0x9]
cmp  r2,r0
bcc  .mr_outerloop
b    .mr_exit

//-------------------------------------------------------------------------------------------

.mr_outerloop:                            // start of big loop to do all lines
ldrb r1,[r6,#0x10]
mov  r0,#0x80
and  r0,r1
cmp  r0,#0
beq  +

ldr  r0,[sp,#0x8]
mov  r1,#1
bl   $8049C70

+
ldrh r0,[r6,#0x8]
mov  r3,#2
lsl  r3,r3,#8
sub  r1,r3,#1                             // ldr r1,=#0x1FF
and  r1,r0
mov  r0,sp
ldrh r0,[r0,#0x6]
lsl  r0,r0,#0x10                          // and 0xFFFF0000
and  r0,r2
orr  r0,r1
str  r0,[sp,#0x4]
ldrb r2,[r6,#0xA]
lsl  r2,r2,#0x10
lsl  r0,r0,#0x10                          // and 0xFFFF
lsr  r0,r0,#0x10
orr  r0,r2
str  r0,[sp,#0x4]
ldr  r0,[r6,#0]
str  r0,[sp,#0]
mov  r7,#0
str  r7,[sp,#0x14]
str  r7,[sp,#0x48]                        // set "has_icon" to false
mov  r0,sp
bl   .special_checks_move_zone
mov  r4,r5
add  r4,#0x84
mov  r1,r5
add  r1,#0x88
str  r1,[sp,#0x24]
mov  r0,sp
bl   sprite_text_weld.save_current_sprite_total
bl   sprite_text_weld.efficiency_check
bl   sprite_text_weld.recycle_branch
cmp  r0,#0
beq  +
mov  r0,sp
bl   .ready_buffer                        // prepare the tiles buffer we're about to use (if we didn't beforehand)
mov  r0,sp
bl   .recycle_old_oam                     // try recycling the oam entries
cmp  r0,#0                                // check if we failed finding the tiles
beq  +
b    .after_eos
+
mov  r0,sp
ldrh r0,[r6,#0xE]
cmp  r7,r0
bcc  +
b    .after_eos

+

ldr  r3,[sp,#0]                           // get the string
ldrh r1,[r3,#0x0]                         // first letter
ldr  r0,[sp,#{ctrl_stk}]                  // if it's a BREAK and we just recycled the previous OAM, we need to account for a special case
cmp  r1,r0
bls  .mr_createsprite
ldr  r3,[sp,#{letter_stk}]
ldrb r0,[r3,#0]
cmp  r0,#0
bne  +
bl   .replace_BREAK_first_line
b    .mr_createsprite

//-------------------------------------------------------------------------------------------

.mr_innerloop:
ldr  r3,[sp,#0]                           // start of big inner loop, does all letters in curr line
ldrh r1,[r3,#0x0]                         // code we clobbered
ldr  r0,[sp,#{ctrl_stk}]

cmp  r1,r0
bls  .mr_createsprite
+
bl   sprite_text_weld.cc_check

//orr  r0,r1
//strb r0,[r4,#0x3]                       // this causes trouble with weird letter for some reason
ldr  r0,[sp,#0x8]
mov  r1,r6
mov  r2,sp
add  r3,sp,#4
bl   $80495C8
b    .mr_nextletter                     // move to the next letter of the current line

//-------------------------------------------------------------------------------------------

.mr_createsprite:
bl   sprite_text_weld.create_sprite     //  (a bunch of code is manually skipped after this)

.mr_aftercreatesprite:
ldrh r1,[r3,#0]
ldrh r0,[r4,#0x4]
lsl  r0,r0,#0x14
lsr  r0,r0,#0x14
ldr  r3,[sp,#0x24]
mov  r7,r5
add  r7,#0x85
mov  r2,#0x89
add  r2,r2,r5
mov  r8,r2
mov  r2,#0x8B
add  r2,r2,r5
mov  r10,r2
mov  r2,#0x8A
add  r2,r2,r5             // original code
mov  r9,r2
ldr  r2,[sp,#{wbuf_stk}]
ldrb r2,[r2,#0xB]         // load redraw_flag
cmp  r2,#0
bne  +
b    .mr_incrementstuff

//-------------------------------------------------------------------------------------------

+
str  r3,[sp,#0x28]                      // took out some code after this line

ldr  r0,[sp,#0]                         // this stuff sets up the glyph header/footer info
ldr  r1,[r0,#0]
lsl  r1,r1,#0x14
lsr  r1,r1,#0x14                        // and 0xFFF
ldr  r2,[r4,#0]
lsr  r2,r2,#0xC
lsl  r0,r2,#0xC                         // and 0xFFFFF000
orr  r0,r1
str  r0,[r4,#0]
mov  r2,sp
bl   sprite_text_weld.store_letter

lsr  r1,r1,#0x18
ldrb r2,[r7,#0]
mov  r0,#0xF
and  r0,r2
orr  r0,r1
strb r0,[r7,#0]
ldrb r0,[r4,#0x3]
mov  r2,#0x9
neg  r2,r2
mov  r1,r2
and  r0,r1
strb r0,[r4,#0x3]
ldr  r1,[sp,#0x18]
lsl  r1,r1,#0x16
lsr  r1,r1,#0x16                        // and 0x3FF
ldrh r2,[r4,#0x2]
lsr  r2,r2,#0xA
lsl  r0,r2,#0xA                         // and 0xFFFFFC00
orr  r0,r1
strh r0,[r4,#0x2]
ldr  r1,[sp,#0xC]
str  r1,[r5,#0]                         // store the target OBJ address in struct header
ldrb r1,[r4,#0x3]
mov  r0,#0x5
neg  r0,r0
and  r0,r1
strb r0,[r4,#0x3]
ldrh r1,[r4,#0]
lsl  r1,r1,#0x14
lsr  r1,r1,#0x14                        // and 0xFFF
ldr  r3,[sp,#0x28]
ldrh r2,[r3,#0]
lsr  r2,r2,#0xC
lsl  r0,r2,#0xC                         // and 0xFFFFF000
orr  r0,r1
strh r0,[r3,#0]
ldrb r1,[r7,#0]
lsr  r1,r1,#0x4
lsl  r1,r1,#0x4
mov  r3,r8
ldrb r2,[r3,#0]
mov  r0,#0xF
and  r0,r2
orr  r0,r1
strb r0,[r3,#0]
ldrh r1,[r4,#0x2]
lsl  r1,r1,#0x16
lsr  r1,r1,#0x16                        // and 0x3FF
mov  r2,r9
ldrh r0,[r2,#0]
lsr  r0,r0,#0xA
lsl  r0,r0,#0xA                         // and 0xFFFFFC00
orr  r0,r1
strh r0,[r2,#0]
ldrb r1,[r6,#0x10]
lsr  r1,r1,#0x7
lsl  r1,r1,#0x2
mov  r3,r10
ldrb r2,[r3,#0]
mov  r0,#0x5
neg  r0,r0
and  r0,r2
orr  r0,r1
strb r0,[r3,#0]
ldr  r0,[sp,#0]
ldrh r1,[r0,#0]
mov  r0,r5
bl   $80496F8                           // eventually calls routine to draw font, copy to struct

//-------------------------------------------------------------------------------------------

.mr_incrementstuff:
ldr  r1,[sp,#{letter_stk}]
ldrb r0,[r1,#0]
add  r0,#1
strb r0,[r1,#0]
bl   sprite_text_weld.save_letters_width
bl   sprite_text_weld.add_width         // took out some code after here
ldr  r0,[sp,#{wbuf_stk}]                // get the sprite total
ldrb r0,[r0,#0x4]
cmp  r0,#0x5F
bhi  .mr_exit

.mr_nextletter:
ldr  r0,[sp,#0x14]
add  r0,#1
lsl  r0,r0,#0x10
lsr  r0,r0,#0x10
str  r0,[sp,#0x14]
ldr  r0,[sp,#0]
add  r0,#2
str  r0,[sp,#0]
bl   .restore_old_first_line
ldr  r0,[sp,#0x14]
ldrh r1,[r6,#0xE]
cmp  r0,r1
bcs  .mr_eos
b    .mr_innerloop

//-------------------------------------------------------------------------------------------

.mr_eos:
bl   sprite_text_weld.eos_stuff

.after_eos:
ldr  r0,[sp,#8]
mov  r1,#0
bl   $8049C70                           // setup the end of printing an oam entry
mov  r0,sp
bl   .save_entry_info
mov  r0,sp
bl   .reset_data_redrawing
ldr  r0,[sp,#0x10]
add  r0,#1
lsl  r0,r0,#0x10
lsr  r0,r0,#0x10
str  r0,[sp,#0x10]
add  r6,#0x14
ldr  r0,[sp,#{numstr_stk}]
ldr  r0,[r0,#0]
ldr  r7,[sp,#0x10]
ldrb r0,[r0,#0x9]
cmp  r7,r0
bcs  .mr_exit
b    .mr_outerloop                      // loop back if not done with all the lines yet

//-------------------------------------------------------------------------------------------

.mr_exit:
ldr  r2,=#0x2016028
bl   sprite_text_weld.clear_unused_table_stuff

bl   .convert_1bpp_4bpp
ldr  r1,[sp,#0x1C]
ldr  r3,[sp,#0x20]
sub  r0,r1,r3
lsr  r0,r0,#3
ldrh r1,[r2,#0]
add  r1,r1,r0
ldrh r0,[r2,#0]
strh r1,[r2,#0]

add  sp,#{sprite_text_weld_stack_size}    // currently 0xF8
pop  {r3-r5}
mov  r8,r3
mov  r9,r4
mov  r10,r5
pop  {r4-r7}
pop  {r0}
bx   r0
