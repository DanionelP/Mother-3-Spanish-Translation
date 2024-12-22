credits_hacks:

// ==============================================
// These hacks relocate the credits structs to 203FC00.
// ==============================================

.address_check1:
push {r1,lr}
ldr  r1,[sp,#0x18]
ldr  r0,=#0x801C1F5
cmp  r0,r1
pop  {r1}
bne  +

// Credits
ldr  r0,=#0x203FC00
// Copy of the 2519C function
push {r4,r5}
mov  r5,r0
mov  r1,#0xD8
lsl  r1,r1,#1
add  r3,r5,r1
ldrb r2,[r3,#0]
mov  r4,#2
neg  r4,r4
mov  r1,r4
and  r1,r2
strb r1,[r3,#0]
mov  r12,r5
mov  r5,#0
-
mov  r3,r12
add  r3,#0x32
ldrb r1,[r3,#0]
mov  r2,r4
and  r2,r1
strb r2,[r3,#0]
add  r1,r5,#1
lsl  r1,r1,#0x10
lsr  r5,r1,#0x10
mov  r1,#0x36
add  r12,r1
cmp  r5,#7
bls  -
pop  {r4,r5,pc}

+
// Non-credits
ldr  r0,=#0x201B574
bl   $802519C
pop  {pc}

// ==============================================
// The following hacks fix the ldrb/strb ranges.
// There are certain lines that were changed that
// are now out of range due to the letter expansion.
// ==============================================

define val1 0x2E

.range_fix1:
push {lr}
add  r4,#{val1}
ldrb r1,[r4,#0]
sub  r4,#{val1}
mov  r0,#1 // clobbered code
pop  {pc}

.range_fix2:
push {lr}
add  r4,#{val1}
ldrb r1,[r4,#0]
sub  r4,#{val1}
mov  r0,#2 // clobbered code
pop  {pc}

.range_fix3:
push {lr}
add  r4,#{val1}
ldrb r0,[r4,#0]
and  r0,r7
strb r0,[r4,#0]
sub  r4,#{val1}
pop  {pc}

// ==============================================
// This hack delimits named characters to 8 letters.
// ==============================================

.name_fix:
push {r0,lr}
mov  r2,#0x28
bl   check_name
cmp  r0,#0
beq  +
lsl  r2,r0,#1 // need length in bytes, not letters
+
mov  r1,r4 // clobbered code
pop  {r0,pc}

// ==============================================
// This hack takes care of all the pre-welding workarounds in
// the credits text.
// ==============================================

.preweld1:
push {r0-r4,lr}

// Get the name index & increase it
ldr  r0,=#0x203FFF6
ldrb r1,[r0,#0]
mov  r3,r1 // back up the ID
add  r1,#1
strb r1,[r0,#0] // We increase it right away so that future code is able to tell when credits are rolling
sub  r0,r1,#1

// Get the table address
ldr  r1,=#0x9FB0000
lsl  r0,r0,#3
add  r1,r1,r0

// Check the header
ldrh r0,[r1,#0]
cmp  r0,#0
beq  .custom

// Preweld mode

	// Get the tile start
	ldrh r0,[r1,#2]

	// Get the tile length
	ldrh r2,[r1,#4]

	// Write values from tile_start to (tile_start + tile_length - 1) at r4
	-
	strh r0,[r4,#0]
	add  r4,#2
	add  r0,#1
	sub  r2,#1
	cmp  r2,#0
	bne  -

	// Write the X coord
	cmp  r3,#0x2C // Item Guy
	bne  +
	ldrh r0,[r1,#6] // absolute position
	strh r0,[r5,#0]
	pop  {r0-r4,pc}
	
	+
	ldrh r0,[r5,#0] // center of string
	ldrh r2,[r1,#6] // width, in pixels
	lsr  r2,r2,#1
	sub  r0,r0,r2   // X = center - (width / 2)
	strh r0,[r5,#0]

	// Done
	pop  {r0-r4,pc}

.custom:
// Custom mode

	// Check if we already did the FF23 crap
	ldrh r0,[r7,#0]
	push {r1}
	ldr  r1,=#0xFF23
	cmp  r0,r1
	pop  {r1}
	beq  +
	
	// Copy the string into the 203FC00 struct
	ldr  r0,[r1,#4] // get the custom address
	add  sp,#4
	pop  {r1-r4}
	bl   $8001B18 // clobbered code/transfer the string
	b    .jump1
	+
	pop  {r0-r4}
	
	.jump1:
	// Calculate the X coord
	mov  r1,r5
	add  r1,#0x2C
	mov  r0,r4
	bl   get_string_width
	lsl  r0,r0,#0x10
	lsr  r0,r0,#0x11
	ldrh r1,[r5,#0]
	sub  r1,r1,r0
	strh r1,[r5,#0] // X = center - (width / 2)
	
	// Done
	pop  {pc}