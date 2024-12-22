naming_screen_hacks:

// ==============================================
// These hacks align the bullets correctly
// on the naming screens.
// ==============================================

.bullets1:
cmp  r4,#0
bne  +
mov  r1,#4
add  r1,r8
bx   lr
+
mov  r1,#3
add  r1,r1,r2
bx   lr

.bullets2:
ldr  r1,=#{small_font_width}
add  r3,#1
lsl  r3,r3,#1
sub  r2,r2,r3
-
ldrh r3,[r2,#0]
add  r2,#2
cmp  r3,#0xFF
bgt  +
ldrb r3,[r1,r3]
add  r7,r7,r3
b    -
+
sub  r1,r7,#1
bx   lr


// ==============================================
// These hacks make the factory screen load the
// sanctuary name.
// ==============================================

.factload1:

mov  r1,#0x00
//orr  r0,r1  // no longer needed

// Check the naming screen type
ldr  r4,=#0x201AA58
ldrb r4,[r4,#0]
cmp  r4,#0xE
bne  +
ldr  r1,=#0x2004F26
-
ldrb r4,[r1,#0]
add  r1,r1,#2
cmp  r4,#0xFF
beq  +
add  r0,r0,#1
b    -
+
bx   lr

.factload2:
// Check the naming screen type
ldr  r4,=#0x201AA58
ldrb r4,[r4,#0]
cmp  r4,#0xE
bne  .factload2_end
ldr  r3,=#0x2004F26
mov  r4,#0
-
ldrb r6,[r3,#0]
add  r3,r3,#2
cmp  r6,#0xFF
beq  +
strh r6,[r5,r4]
add  r4,r4,#2
b    -
+
lsr  r4,r4,#1
//ldrb r6,[r7,#0]
//add  r6,r6,r4
//strb r6,[r7,#0]
strb r4,[r7,#0]
.factload2_end:
pop  {r3-r5}
mov  r8,r3
bx   lr


// ==============================================
// These hacks display the player name properly
// in the staff credits.
// ==============================================

// This one loads the correct upper letter tile
.credits1:
push {r5,lr}
ldr  r5,[sp,#8]
mov  lr,r5
ldr  r5,[sp,#4]
str  r5,[sp,#8]
pop  {r5}
add  sp,#4
//
ldr  r1,=#0x9F86140
lsl  r0,r0,#1
ldrh r1,[r1,r0]
pop  {pc}

// This one loads the correct lower letter tile
.credits2:
push {r5,lr}
ldr  r5,[sp,#8]
mov  lr,r5
ldr  r5,[sp,#4]
str  r5,[sp,#8]
pop  {r5}
add  sp,#4
//
ldr  r1,=#0x9F86140
lsl  r2,r5,#1
ldrh r1,[r1,r2]
add  r1,#0x20
pop  {pc}

// This one makes it read from the correct address
.credits3:
push {r5,lr}
ldr  r5,[sp,#8]
mov  lr,r5
ldr  r5,[sp,#4]
str  r5,[sp,#8]
pop  {r5}
add  sp,#4
//
mov  r1,#0x1B
lsl  r1,r1,#6
add  r1,r1,#6
add  r2,r1,r0
pop  {pc}


//=====================================================================================
// This function completely fixes up the cursor coord crap on naming screens.
//=====================================================================================

.cursor_lookup_tables:
incbin data_namingcursors.bin

.cursor_megafix:
push {r3-r7,lr}

// ---------------------------------------
// Get the current value
ldrb r7,[r0,#0]            // r7 = current cursor value
// ---------------------------------------
// Get the layout type
ldr  r6,=#0x201AA58
ldrb r6,[r6,#0]
cmp  r6,#0xD
beq  +
cmp  r6,#0xE
beq  +
mov  r6,#0
b    .cursor_megafix_jump1
+
mov  r6,#1
.cursor_megafix_jump1:     // r6 = layout type (0 = normal, 1 = sans dont care)
// ---------------------------------------
// Get the arrow direction
ldrh r5,[r1,#2]
mov  r4,#0xF0
and  r5,r4
cmp  r5,#0
beq  .cursorfix_end        // Return only if no arrow keys are pressed whatsoever
lsr  r5,r5,#5              // {10, 20, 40, 80} is now {0, 1, 2, 4}
cmp  r5,#4
blt  +
mov  r5,#3                 // {0, 1, 2, 4} is now {0, 1, 2, 3}
+                          // r5 = arrow direction (0 = right, 1 = left, 2 = up, 3 = down)
// ---------------------------------------
// Play the sound effect
push {r0-r3}
lsr  r0,r5,#1              // r3 = 0 for right,left; 1 for up,down
mov  r2,#1
eor  r0,r2                 // r3 = 1 for right,left; 0 for up,down
add  r0,#0xD0
bl   $800399C
pop  {r0-r3}
// ---------------------------------------
// Get table address
mov  r3,#0x69
ldr  r4,=#.cursor_lookup_tables
mul  r6,r3
lsl  r6,r6,#2              // r6 *= 0x1A4
mul  r5,r3                 // r5 *= 0x69
add  r4,r4,r5
add  r4,r4,r6
// ---------------------------------------
// Load the new value and store it
ldrb r4,[r4,r7]
// If r4 == #0xFF, something went wrong, let jeffmeister know
strb r4,[r0,#0]
// ---------------------------------------
// Finished
.cursorfix_end:
pop  {r3-r7,pc}


//--------------------------------------------------------
//                 New summary & naming screen hacks!
//--------------------------------------------------------
//First part of the new hacks

.impede_refresh_oam:
push {r4-r5,lr}
mov  r5,r1
ldr  r1,=#0x2003F04                 //Let's check in our flag what's happening
ldrb r0,[r1,#0]
cmp  r0,#1                          //If the value is one, then we need to print the text ONE time and set it to - not printing
bne  .keep_going
mov  r0,#2
strb r0,[r1,#0]                     //Sets the flag to - not printing
b    .keep_keep


.keep_going:
cmp  r0,#2                          //Is this 2? If it is, we don't print, but we need to make some checks to avoid some stuff...
bne  .keep_keep
ldr  r0,=#0x201A288
ldrb r0,[r0,#0]
cmp  r0,#0x11                       //Is this the naming screen? If not, keep going!
beq  .partially
mov  r0,#0
strb r0,[r1,#0]

.keep_keep:
bl   $8050EEC                       //This is the standard OAM refreshing routine, call it in case it's 1 or 0, since we need to print

.rest:
pop  {r4-r5,pc}

.partially:
bl   .special_restore_objs

b    .keep_keep

//--------------------------------------------------------
//Picks the text's old OAM entries and adds them back to the new OAM
//--------------------------------------------------------
.special_restore_objs:
push {r4-r6,lr}
mov  r6,#2
lsl  r6,r6,#8
ldr  r4,=#0x7000000
ldr  r0,=#0x2022648
ldr  r5,[r0,#0]                        //Where the new OAM entries are
mov  r2,r5
sub  r2,#8

-
add  r2,#8
ldrh r1,[r2,#0]
and  r1,r6                             //Is this entry enabled?
cmp  r1,#0
beq  -

mov  r5,r2                             //Get the address the first blank is at

.special_restore_objs_cycle:
mov  r0,r4
bl   .find_oam_text                    //Find the closest text oam

ldrh r1,[r0,#0]
and  r1,r6
cmp  r1,#0                             //End search if the end of the entries has been found instead
bne  .special_restore_objs_end

mov  r4,r0                             //This is the address of the first text oam entry found
bl   .find_oam_end_of_text             //Find the end of the text oam entry

ldr  r1,=#0x40000D4
sub  r3,r0,r4
lsr  r3,r3,#1                          //How many 16-bit units we must copy
mov  r0,#8
lsl  r2,r0,#28                         //Enable DMA Transfer
orr  r3,r2

str  r4,[r1,#0]
str  r5,[r1,#4]
str  r3,[r1,#8]                        //Start the actual transfer
ldr  r0,[r1,#8]

cmp  r0,#0
bge  +
-
ldr  r0,[r1,#8]                        //Make sure the transfer happens properly
and  r0,r2
cmp  r0,#0
bne  -
+

lsl  r3,r3,#1
add  r5,r5,r3
add  r4,r4,r3
b    .special_restore_objs_cycle

.special_restore_objs_end:
pop  {r4-r6,pc}

//--------------------------------------------------------------------------------------------------
//This function returns the address of the nearest text entry to the address in r0
//--------------------------------------------------------------------------------------------------
.find_oam_text:
lsl  r3,r6,#1
sub  r3,r3,#1
mov  r2,r0
sub  r2,#8
mov  r0,#0x18
lsl  r0,r0,#4

-
add  r2,#8
ldrh r1,[r2,#0]
and  r1,r6
cmp  r1,#0                             //End search if the end of the entries has been found
bne  +
ldrh r1,[r2,#4]
and  r1,r3                             //Is this entry a text one? If it is, we found one!
cmp  r1,r0
bge  -

+
mov  r0,r2
bx   lr

//--------------------------------------------------------------------------------------------------
//This function returns the address of the end of the sequence of text entries after r0
//--------------------------------------------------------------------------------------------------
.find_oam_end_of_text:
lsl  r3,r6,#1
sub  r3,r3,#1
mov  r2,r0
mov  r0,#0x18
lsl  r0,r0,#4

-
add  r2,#8
ldrh r1,[r2,#0]
and  r1,r6
cmp  r1,#0                             //End text if the end of the entries has been found
bne  +
ldrh r1,[r2,#4]
and  r1,r3                             //Is this entry a text one? Check if we're at the end
cmp  r1,r0
blt  -

+
mov  r0,r2
bx   lr

//--------------------------------------------------------------------------------------------------
//This function manually fixes the save copying bug (New Game Plus)
//--------------------------------------------------------------------------------------------------
.fix_copy_bug:
ldr  r1,=#0x2004F80
mov  r5,#0
str  r5,[r1,#0]
str  r5,[r1,#4]
str  r5,[r1,#0x1C]
strh r5,[r1,#0x20]
ldr  r5,=#0x880                     //Reset PSI flags
add  r1,#0x1A
strh r5,[r1,#0]
//ldr  r1,=#0x2004947
//mov  r5,#0
//strb r5,[r1,#0]
//str  r5,[r1,#4]                     //Reset Duster's items
ldr  r1,=#0x20041B0                 //Reset Equipments, Flint
ldr  r5,=#0x0410000
str  r5,[r1,#0]
add  r1,#0x6C                       //Next character, Lucas
mov  r5,#0
str  r5,[r1,#0]
add  r1,#0x6C                       //Next character, Duster
ldr  r5,=#0x4E002516
str  r5,[r1,#0]
add  r1,#0x6C                       //Next character, Kumatora
ldr  r5,=#0x4F46B50D
str  r5,[r1,#0]
add  r1,#0x6C                       //Next character, Boney
ldr  r5,=#0x2E00
str  r5,[r1,#0]
add  r1,#0x6C                       //Next character, Salsa
mov  r5,#0
str  r5,[r1,#0]
bx   lr

//--------------------------------------------------------------------------------------------------
//Second part of the new hacks
//--------------------------------------------------------------------------------------------------
.flag_reset:
push {lr}
cmp  r0,#0x4F                       //Summary's arrangement is being loaded?
bne  .CheckOtherArrangements

bl   .fix_copy_bug
b    .Flag_Stuff

.CheckOtherArrangements:
cmp  r0,#0x51                       //Text Speed/Window flavour arrangement
beq  .Flag_Stuff
cmp  r0,#0x48                       //Naming screen arrangements for the player's name are at 0x48
beq  .Flag_Stuff
cmp  r0,#0x47                       //Naming screen arrangements are at 0x47
bne  .NotCycle

.Flag_Stuff:
ldr  r1,=#0x2003F04                 //Flag
mov  r5,#1
strb r5,[r1,#0]                     //Set the flag
mov  r5,#0
strb r5,[r1,#8]
b    .ending

.NotCycle:
ldr  r1,=#0x2003F04                 //Reset the Flag
mov  r5,#0
strb r5,[r1,#0]
b    .ending

.ending:
mov  r1,r0
lsl  r1,r1,#0x10                    //Stuff the game does
pop  {pc}                           //Return to the cycle

//--------------------------------------------------------------------------------------------------
//Make the game print the naming screen only when the name changes - "A" version
//--------------------------------------------------------------------------------------------------
.pressed_a_check_print:
push {lr}
add  sp,#-0x24
mov  r0,sp
bl   .save_name                     //Save the current name to stack

mov  r0,r6
bl   $804F51C                       //Default code which can change the name

mov  r0,sp
bl   .reprint_if_updated

add  sp,#0x24
pop  {pc}

//--------------------------------------------------------------------------------------------------
//Make the game print the naming screen only when the name changes - "B" version
//--------------------------------------------------------------------------------------------------
.pressed_b_check_print:
push {lr}
add  sp,#-0x24
mov  r0,sp
bl   .save_name                     //Save the current name to stack

bl   $8050628                       //Default code which can change the name

mov  r0,sp
bl   .reprint_if_updated

add  sp,#0x24
pop  {pc}

//--------------------------------------------------------------------------------------------------
//If the name changed from the one in r0, it sets the flag for re-printing
//--------------------------------------------------------------------------------------------------
.reprint_if_updated:
push  {lr}
bl   .has_name_changed              //Has the name changed?
cmp  r0,#1
bne  +
ldr  r0,=#0x2003F04                 //Flag
mov  r1,#1
strb r1,[r0,#0]                     //Set it to 1, so it prints
+
pop  {pc}

//--------------------------------------------------------------------------------------------------
//Save the currently selected name to stack
//--------------------------------------------------------------------------------------------------
.save_name:
push {lr}
mov  r1,r0                          //r0 has the address of the stack
ldr  r0,=#0x201AE1C                 //The currently selected name's address is here
ldr  r0,[r0,#0]
str  r0,[r1,#0]                     //Save the current name's address as well
add  r1,#4
mov  r2,#0x10                       //How many halfwords
swi  #0xB                           //Copy to stack
pop  {pc}

//--------------------------------------------------------------------------------------------------
//Compare the currently selected name to the one saved in the stack
//--------------------------------------------------------------------------------------------------
.has_name_changed:
push {r4,lr}
mov  r4,r0                          //r0 has the address of the stack
ldr  r0,=#0x201AE1C                 //The currently selected name's address is here
mov  r3,#0
ldr  r0,[r0,#0]
ldr  r1,[r4,#0]                     //Check if the currently loaded name changed
cmp  r1,r0
bne  +
add  r4,#4
-
ldrh r1,[r0,#0]
ldrh r2,[r4,#0]
cmp  r1,r2
bne  +
add  r0,#2
add  r4,#2
add  r3,#1
cmp  r3,#0x10
blt  -

mov  r0,#0
b    .has_name_changed_end          //Name hasn't changed

+
mov  r0,#1                          //Name has changed

.has_name_changed_end:
pop  {r4,pc}

//--------------------------------------------------------------------------------------------------
//Compare the currently diplayed entry to the one saved.
//If they don't match, set re-printing
//--------------------------------------------------------------------------------------------------
.compare_currently_displayed_entry:
push {lr}
ldr  r1,=#0x2003F04
ldrb r2,[r1,#4]
cmp  r2,r0                          //Is the entry that has to be displayed the same?
beq  +
strb r0,[r1,#4]                     //If it isn't, re-print and update the value
mov  r2,#1
strb r2,[r1,#0]
+
bl   $80486A0                       //Default code
pop  {pc}

//--------------------------------------------------------------------------------------------------
//Set the flag for reprinting, the Invalid/Duplicated name window popped up
//--------------------------------------------------------------------------------------------------
.reprint_invalid_duplicated:
push {lr}
ldr  r0,=#0x2003F04
mov  r1,#1                          //Set to printing
strb r1,[r0,#0]

mov  r0,#0                          //Default code
mov  r1,#4
pop  {pc}

//--------------------------------------------------------------------------------------------------
//Set the flag for reprinting, the Invalid/Duplicated name window has been closed
//--------------------------------------------------------------------------------------------------
.reprint_after_invalid_duplicated:
push {lr}
ldr  r1,=#0x41CC
ldr  r4,=#0x2016028                 //Default code
add  r0,r4,r1
ldrh r0,[r0,#0]
cmp  r0,#0x33                       //Is this the right window? If it is, the displayed entry is 0x33
bne  +

ldr  r0,=#0x201A288
ldrb r0,[r0,#0]
cmp  r0,#0x11                       //Make sure this is the naming menu
bne  +

ldr  r0,=#0x2003F04
mov  r1,#1                          //Set to printing
strb r1,[r0,#0]
ldr  r1,=#0x41CC                    //Set this back to what it should be

+
pop  {pc}

//--------------------------------------------------------------------------------------------------
//Changes the printing order of text in the naming screen so the game caches stuff better
//--------------------------------------------------------------------------------------------------
.change_printing_order:
push {lr}
push {r3}
add  sp,#-8
ldr  r2,=#0x80C69CC
ldr  r1,=#0x4A30
ldr  r4,=#0x2016028
add  r0,r4,r1
ldrb r1,[r0,#0]
lsl  r0,r1,#1
add  r0,r0,r1
lsl  r0,r0,#2
add  r0,r0,r2
ldrh r0,[r0,#6]
bl   .compare_currently_displayed_entry
mov  r3,#1
neg  r3,r3
mov  r1,#0xF
str  r1,[sp,#0]
mov  r2,#1
mov  r8,r2
str  r2,[sp,#4]
mov  r1,#0x78
mov  r2,#0x1B
bl   $8047CDC
mov  r0,#1
bl   $8047E04
ldr  r3,[sp,#8]
ldrb r0,[r3,#0]
ldr  r1,=#0x4DF4
cmp  r0,#0xD
blt  .change_printing_order_normal_names
add  r0,r6,r1
ldr  r0,[r0,#0]
mov  r1,#0xF
str  r1,[sp,#0]
mov  r1,#1
str  r1,[sp,#4]
mov  r1,#0x68
mov  r6,r1
mov  r3,#0x10
b    +

.change_printing_order_normal_names:
add  r0,r6,r1
ldr  r0,[r0,#0]
mov  r1,#0xF
str  r1,[sp,#0]
mov  r1,#1
str  r1,[sp,#4]
mov  r1,#0x78
mov  r6,r1
mov  r3,#9

+
mov  r2,#6
bl   $8047CDC
mov  r0,#1
bl   $8047E04
mov  r0,r6
ldr  r2,=#0x4ECA
add  r1,r4,r2
ldrh r3,[r1,#0]
mov  r1,#6
mov  r2,#8
bl   $80458B8

add  sp,#8
pop  {r3}
pop  {pc}
