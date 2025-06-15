arch gba.thumb


//============================================================================================
//                                          TEST HACKS
//============================================================================================

// make menu text blue
//org $80C5FFF; db $7C

// EZ Flash sleep fix
org $800188E; db $40
org $80018A9; db $C3

//============================================================================================
//                                          FONT FILES
//============================================================================================
 
// Insert new 16x16 font + cast roll pre-welded font - MUST BE 4 BYTES ALIGNED
//org $8CE39F8; fill $8192,$0
define main_font $8CE39F8 
org {main_font}; incbin font_mainfont_rearranged.bin
org $8CE59F8; incbin font_castroll_rearranged.bin

// Insert new 8x8 font
define small_font $8D0B010 
org {small_font}; incbin font_smallfont.bin

// Insert E symbol's 1bpp version - MUST BE 4 BYTES ALIGNED
define e_symbol_1bpp $9FD40E0
org {e_symbol_1bpp}; incbin font_equip_rearranged.bin

// Insert new font width table
define main_font_width $8D1CE78
org {main_font_width}; incbin font_mainwidths.bin

// insert 8x8 font width table
define small_font_width $8D1CF78
org {small_font_width}; incbin font_smallwidths.bin

// Insert new font usage table
define main_font_usage $9FD4100
org {main_font_usage}; incbin font_mainfont_used.bin

// insert 8x8 font usage table
define small_font_usage $9FD4200
org {small_font_usage}; incbin font_smallfont_used.bin

//============================================================================================
//                                       CAST ROLL HACKS
//============================================================================================

// Relocate to 203FC00
org $8025184; dd $0203FC00
// Cast: called from 250CB
// Non-cast: never called

//org $8024870; dd $0203FC00
// Cast: called once from 1C1F5
// Non-cast: called from 7929
org $802484E; bl credits_hacks.address_check1; nop

org $8024624; dd $00029BD8
// Cast: called from 2334D, 233A3
// Non-cast: never called

// Expand from 12 letters to 21 (20 + custom control bytes)
org $8025172; add r0,#0x32
org $802518E; add r2,#0x36
//org $80251A0; mov r1,#0xD8
//org $80251B8; add r3,#0x32
//org $80251C8; mov r1,#0x36
org $80250E0; add r6,#0x32
org $80250EC; strh r0,[r5,#0x30]
org $8025106; mov r1,#0x2A
//org $8025140; mov r2,#0x28 // included in .name_fix
//org $8025148; add r1,#0x2C // included in .preweld1
org $8024594; bl credits_hacks.range_fix1
org $80245B8; bl credits_hacks.range_fix2
org $80245E0; bl credits_hacks.range_fix3; nop
org $80245F2; bl credits_hacks.range_fix3; nop
org $80245E6; ldrh r0,[r4,#0x2C]
org $80245EA; strh r0,[r4,#0x2C]
org $80245FE; add r4,#0x36
org $8024600; add r5,#0x36

// Fix player names
org $802511C; b $8025142
//org $8025148; mov r0,r4; bl get_string_width; nop
org $802513E; bl credits_hacks.name_fix; bl credits_hacks.preweld1; b $802515A

// Disable Saturn text
org $8025138; nop

//============================================================================================
//                                  SPRITE TEXT WELDING HACKS
//============================================================================================

org $80487DA; bl sprite_text_weld.main_routine  // link to new sprite routine
org $80492D0; bl $8000000                       // break old sprite routine on purpose

// make sprite text be spaced out by 16 pixels
org $8049CB4; db $10         
org $8049CEE; db $10

org $80496A4; bl sprite_text_weld.get_icon_coord; nop
org $80496C2; bl sprite_text_weld.get_icon_coord; nop
org $80496D6; db 1
org $803EA6C; bl sprite_text_weld.fix_sprite_total

// these are used by the 16x16 sprite text routine
org $804974A
  mov  r6,r5
  add  r6,#0x85
  mov  r1,sp
  bl   sprite_text_weld.fast_prepare_main_font
  cmp  r4,#0                 // skip printing if the tiles are empty
  beq  $80497C6
  cmp  r4,#2                 // partially skip printing if the first tile is empty
  beq  $80497B6
  b    $80497A4
org $80497A6
  ldrb r2,[r6,#0]
  lsr  r2,r2,#4
  mov  r1,sp
  mov  r3,#2
  bl   text_weld
  cmp  r4,#2                 // do we want to print the bottom tiles?
  blt  $80497C6
org $80497BE; add r1,sp,#0x10
org $80497C2; bl text_weld

// these are used by the 8x8 sprite text routine
org $80497DA
  mov  r1,sp
  bl   sprite_text_weld.fast_prepare_small_font
  cmp  r0,#0                 // skip printing if the tile is empty
  beq  $804982E
  b    $804980C
org $8049818; mov r3,#1; bl text_weld; b $804982E

org $803E170; bl sprite_text_weld.set_fadeout_flag
org $803E24C; bl sprite_text_weld.clear_table

//============================================================================================
//                                   MAIN MENU HACKS
//============================================================================================

// Modifies GetAddressOfGlyphBitmap for main menu item descriptions
org $8049916; mov r0,#0x20
org $804991E; b $8049944

// change the way menus print to make it faster
org $8048CE4; push {lr}; mov r1,#0; bl main_menu_hacks.print_vram; pop {pc}
org $8048828; nop; nop

// makes items print all rows
org $8048FFA
  bl   main_script_hacks.fast_prepare_main_font
  add  r5,sp,#0x18
  b    $8049074

// applies a VWF to item names and other non-sprite text in the main menus
org $8049996; bl main_menu_hacks.item_vwf

// Fix map name alignment on file select screen
org $8044B6C; mov r0,#0x89; nop
org $8044B94; mov r1,#0x89
org $8044974; db $89
org $804497E; db $19
org $8044980; bl main_menu_hacks.chap_end_text; nop
org $8044C4E; db $D0
org $8044BB8; db $0B

// Fix map name string-overwriting bug
org $8044C1C; add r0,r0,r5

// Allow map names to be 50 letters total
org $8044BC0
  mov r0,#100
  mul r0,r7
  nop

// Centers "No Data" on the file select menus
org $804276A; db $67
org $80427AE; db $67

// make the text speed menu box one tile bigger and move the text over a few pixels
org $80C67C8; db $5E
org $80C67CC; db $40

// centers Press the A Button for skill info thing
org $80445B4; db $32

// centers the "------" in various main menu screens
org $80407CE; db $6C
org $80405EE; db $6C
org $8040936; db $6C
org $8040F02; db $6C
org $804113A; db $6C
org $8040B42; db $6C
org $804212A; db $6C
org $8042498; db $6C
org $8041506; db $6C
org $80413F0; db $6C
org $8040FCE; db $6C
org $8041D8C; db $97
org $8041D8E; db $49

// move stuff in the sub menus to the right 2 pixels
// NOTE! There's still a TON of other variations of this that
// need to be repositioned, blech :(
// menu/use/give/drop
org $8045E1A; db $1A
org $8045E3A; db $1A
org $8045E4E; db $1A
org $8045E62; db $1A
// when in Use submenu
org $8045EC2; db $1A
org $8045ED6; db $1A
org $8045EEA; db $1A
org $8045EFE; db $1A
// when in Give submenu
org $8045FB0; db $1A
org $8045FCE; db $1A
org $8045FE2; db $1A
org $8045FF6; db $1A
// when in Drop submenu
org $80460E6; db $1A
org $80460FA; db $1A
org $804610E; db $1A
org $8046122; db $1A
// ‘On whom’ X coord
org $8045F12; db $5A
org $8045F56; db $5A
// ‘To whom’ X coord
org $8046042; db $5A
// Lucas & Boney
org $8046084; db $5A
// Give/Drop in another submenu
org $8046012; db $1A
org $8046026; db $1A

// makes the game use "On whom" for the Use and PSI submenus
org $8045F08; db $3B
org $80461E4; db $3B

// Shop menu realignments
// Move the upper cursor left by four pixels in main shop menu
org $804184C; db $01
// Move the character cursor left by four pixels in the Buy/Sell shop submenus
org $80418BA; db $01
// Move the upper cursor left by four pixels in the Buy/Sell shop submenus
org $80418DE; db $01
// Move the cursors left in Buy submenu
org $8041B90; db $4F
org $8041BE2; db $01
org $8041C0A; db $01
// Move the cursors left in Sell submenu
org $8041DE2; db $57
org $8041E98; db $01
org $8041EC0; db $01
// Move the cursors left when inventory is full
org $8041A6A; db $01
org $8041A92; db $01
// 'Buy' X coord when in main shop menu
org $80446FE; db $12
// 'Sell' X coord when in main shop menu
org $8044712; db $12
// 'End' X coord when in main shop menu
org $8044726; db $12
// Character names X coord when in Buy/Sell shop submenus
org $8044774; db $12
// Item dude realignments
// Fix the cursor alignment
org $8041F68; db $01
org $8041FD6; db $01
org $8041FFA; db $01
// 'Deposit' X coord when in main item dude menu
org $80447BA; db $12
// 'Withdraw' X coord when in main item dude menu
org $80447CE; db $12
// 'End' X coord when in main item dude menu
org $80447E2; db $12
// Character names X coord when in Deposit/Withdraw item dude submenus
org $8044830; db $12 
// Saving/loading menu realignments
// Fix the cursor alignment when selecting a file in the saving menu
org $80427EE; db $0B
// Fix the cursor alignment when overwriting a file in the saving menu
org $80C6800; db $4B
org $80C6804; db $7F
// Fix the cursor alignment when choosing to delete/copy a file in the loading menu
org $80C6830; db $4B
org $80C6834; db $7F
// Fix the cursor alignment when a file is selected in the loading menu
org $80425FE; db $3F
// Fix the cursor alignment when choosing a window colour in the loading menu
org $804270E; db $47
// Fix the cursor alignment when choosing a text speed in the loading menu
org $8042686; db $57

// apply a VWF to the non-sprite text on the Battle Memory screen
org $8049966; push {lr}; bl main_menu_hacks.battle_mem_vwf

// moves battle memory text to the left a little bit
org $8041744; db $77

// make the game load abbreviated names on the battle memory menu, fixed item descs in battle
org $800289C; push {lr}; bl main_menu_hacks.load_alternate_text; nop; nop

// makes numbers print correctly inside the main menus
org $8049CC4; db $10

// allow for extra-long item descriptions instead of just 42 letters or whatever
org $8047E64; bl main_menu_hacks.load_desc_address1
org $8047E78; bl main_menu_hacks.load_desc_address2
org $8047E70; bl main_menu_hacks.load_desc_clear_length

// replaces the sell item text routine
org $80463F8
  push {lr}
  bl main_menu_hacks.sell_text
  pop  {pc}

// replaces the sell equipped item text routine
org $80464A8
  push {lr}
  bl main_menu_hacks.sell_equipped_text
  pop  {pc}

// replaces the buy item text routine
org $804626C
  push {lr}
  bl main_menu_hacks.buy_text
  pop {pc}

// fixes the first frame when use is pressed
//org $8044E36; bl main_menu_hacks.use_frame1; nop
//org $8045E30; bl main_menu_hacks.print_normal_use_frame1; nop
//org $8040446; bl main_menu_hacks.block_frame1_goods; nop
//org $804FBAC; bl main_menu_hacks.setup_block_use_frame1
//org $8045E14; bl main_menu_hacks.prevent_printing_maybe; nop

// replaces the drop item text routine
org $80460C8
  push {lr}
  bl main_menu_hacks.drop_text
  pop {pc}
  
// replaces the equip bought item text routine
org $804631C
  push {lr}
  bl main_menu_hacks.equip_text
  pop {pc}

// replaces the sell old equipped item text routine
org $8046510
  push {lr}
  bl main_menu_hacks.sell_old_equip_text
  pop {pc}
// Fix the Yes/No cursor coords in the sell old equipment text
org $8045A50; db $CC
  
// Step into the menu text alternate shitpiler to record the parsed text address
org $8047F96; bl main_menu_hacks.parser_stepin

// Another parser step in
 org $804810A; bl main_menu_hacks.parser_stepin2

// Final address thinger
org $8047D14; bl main_menu_hacks.parser_stepin3

// fix main menu message issues, allow for 200+ letters per message instead of 16
org $8047F42; bl main_menu_hacks.init_menu_msg_address
org $8047F80; bl main_menu_hacks.load_menu_msg_address
org $8048150; bl main_menu_hacks.save_menu_msg_address
org $8047F64; bl main_menu_hacks.change_menu_msg_address1
org $8047F8E; bl main_menu_hacks.change_menu_msg_address2
org $8047F86; bl main_menu_hacks.change_menu_msg_clear_amt
org $8047F78; nop
org $8048144; bl main_menu_hacks.execute_custom_cc; nop

// move some menu messages to the left to allow for more space
org $8044E72; db $08
org $8044EF2; db $08
org $80453C6; db $08
org $8044572; db $08
org $8045564; db $08
org $8041A36; db $08
org $80445EE; db $08

// make character names only go 8 letters in shop menus instead of 9
org $8044776; db $08

// fix the string-counting routine so that character names don't go over 8 letters
org $8048798; bl main_menu_hacks.counter_fix1
// fix a menu message routine so the game will think fav. food is max 9 letters instead of 22
org $8048462; bl main_menu_hacks.counter_fix2

// Make character names only go 8 letters on the main file load screen (and possibly elsewhere)
org $8047A4C; bl main_menu_hacks.filechoose_lengthfix;

// Stretch out the battle memory names list
org $80446B0; bl extra_hacks.battlemem_stretch
org $8041778; mov r2,#3 // move the cursor left one pixel
org $804175E; lsl r3,r0,#0x14; nop; nop // stretch cursor coords vertically

// Make the battle memory list use the large font
org $8048F88; b $8048FB4

// This clears out non sprite text fully since the game doesn't always
// Note that this is kind of buggy so mess with it later maybe sometime
//org $803EC5A; bl main_menu_hacks.clear_non_sprite_text;

// Other cursor coord fixes. Gives everything a consistent one pixel of space minimum
// between the edge of the cursor and the edge of the text.
// These change the position of the cursor, not the text, as most of these are
// non sprite-text and thus much harder to move.
org $804155A; db $01                             // Memo, X, left column
org $8041560; db $79                             // Memo, X, right column
org $8040624; db $03                             // Goods, X, left column
org $804062A; db $7B                             // Goods, X, right column
org $804081C; bl extra_hacks.keygoods_cursorfix1 // Key goods, X, left column
org $8040824; db $77                             // Key goods, X, right column
org $80424D6; bl extra_hacks.withdraw_cursorfix1 // Withdraw, X, left column
org $80424DE; db $6D                             // Withdraw, X, right column
org $8042164; db $03                             // Deposit, X, left column
org $804216A; db $7B                             // Deposit, X, right column
org $8040B04; db $7F                             // Equip, X, main menu
org $8043064; db $7F                             // Equip, X, sub menu
org $8040F24; bl extra_hacks.psi_cursorfix1      // PSI, X, left column
org $8040F2C; db $69                             // PSI, X, right column
org $8045ACE; db $07                             // PSI, X, 'On whom' submenu
org $804141E; bl extra_hacks.psi_cursorfix1      // Skills (PSI), X, left column
org $8041426; db $69                             // Skills (PSI), X, right column
org $8041460; bl extra_hacks.skills_cursorfix1   // Skills (other), X, left column
org $8041468; db $73                             // Skills (other), X, right column
org $8045BDA; db $CC                             // Selling confirmation prompt
org $8045BBE; db $CC                             // Buying confirmation prompt

org $807A8DA; db $08    // fix Hinawa's name in final battle
org $8040742; nop; nop // Fix issue that made it so certain submenus didn't show the last item's E icon even when they should (odd positions in inventory)
org $8052648; dd $000F423F // Make it so you can sell items up to 999999 DP (previously it was up to 999998 DP)
//org $804BC90; db $F0    // Increase size of cleared lines in menus so it fully covers the screen

//These hacks fix the "scrolling menus" bug and improve the responsiveness of menus

//804CA9C tells each menu where to go
//804E374 if it's a submenu
//804CA6C for "specific submenus"
//804E104 for "specific submenus" submenus. B is not an option anymore.

//Inventory
//org $804CAE0; bl refreshes.inv_spec_a
org $804CB52; bl refreshes.lr
org $804CC24; bl refreshes.up_and_down

//Inventory submenu
org $804E7E0; bl refreshes.inv_submenu_a
org $804FD6A; bl refreshes.inv_use_throw; nop; nop //use
org $804FBA4; bl refreshes.inv_use_throw; nop; nop //use, chicken/chick case
org $804FEF4; bl refreshes.inv_use_throw; nop; nop //throw
org $804FE64; bl refreshes.inv_give; nop; nop //give

//Block A press if too soon
org $804CAD4; bl refreshes.inv_block_a
org $803E064; bl refreshes.inv_submenu_block_a

//Equip
org $804CC64; bl refreshes.equip_a; nop
org $804CCA0; bl refreshes.equip_block_input_lr
org $804CCAA; bl refreshes.lr
org $804CCBE; bl main_menu_hacks.move_and_print

//Inner Equip / "specific submenus"
org $804E092; bl refreshes.b; nop //"specific submenus" wide
org $804E14A; bl refreshes.up_and_down
org $804F704; bl refreshes.inner_equip_a

//Battle Memoes
org $804D1CC; bl refreshes.b; nop; bl main_menu_hacks.delete_vram_battle_memory_to_inv
org $804D2F6; bl refreshes.up_and_down_battle_memoes; nop; nop

//PSI
org $804CD22; bl refreshes.psi_prevent_input_a_select
org $804CD5E; bl refreshes.psi_select; nop
org $804CDB0; bl refreshes.lr
org $804CE30; bl refreshes.withdraw_psi_memo_block_input_up_and_down
org $804CE3C; bl refreshes.up_and_down
org $804EDE6; bl refreshes.psi_used //Party-wide PSI, also fixes a bug in the base game
org $804FFC2; bl refreshes.psi_used; nop; nop //Single-target PSI

//Status
org $804EE46; bl refreshes.status_a
org $804CEB2; bl refreshes.status_block_input_lr; nop
org $804CEBE; bl refreshes.status_lr
org $804CEF4; bl main_menu_hacks.move_and_print
org $804CF0A; bl main_menu_hacks.move_and_print

//Skills
org $804CF4C; bl refreshes.skills_b; nop
org $804CFA0; bl refreshes.lr
org $804D050; bl refreshes.up_and_down

//Memo
org $804D096; bl refreshes.memo_a; nop
org $804D0EA; bl refreshes.withdraw_psi_memo_block_input_up_and_down
org $804D0F6; bl refreshes.up_and_down

//Inner Memoes
org $804D138; bl refreshes.inner_memo_scroll; nop
org $804D150; bl refreshes.b; nop

//Buy
org $804D4BA; bl refreshes.buy_block_lr
org $804D4DC; bl refreshes.buy_lr; nop; nop
org $804D516; bl refreshes.b; nop
org $804D556; bl refreshes.buy_block_up_down
org $804D562; bl refreshes.up_and_down
org $804D5A8; bl refreshes.buy_block_lr
org $804D5C8; bl refreshes.buy_lr; nop; nop
org $804E358; bl refreshes.shop_block_b_update
org $804E944; bl refreshes.buy_block_a
org $805007A; bl refreshes.buy_a; nop; nop
org $8050440; bl refreshes.sell_after_buy_a; nop; nop

//Sell
org $804D602; bl refreshes.sell_a; nop
org $804D61C; bl refreshes.b; nop
org $804D660; bl refreshes.sell_block_input_up_and_down
org $804D66C; bl refreshes.up_and_down
org $804D6BE; bl refreshes.switch_lr; nop
org $804E9A4; bl refreshes.sell_confirmed_a
org $80502FC; bl refreshes.sell_confirmed_printing_pressed_a
org $804E9D4; bl refreshes.sell_confirmed_equipment_a
org $80503CC; bl refreshes.sell_equipment_confirmed_printing_pressed_a

//Deposit
org $804D800; bl refreshes.deposit_a; nop
org $804D818; bl refreshes.b; nop
org $804D86E; bl refreshes.up_and_down
org $804D8BC; bl refreshes.deposit_lr
org $804F284; bl refreshes.deposit_printing_pressed_a

//Withdraw
org $804D8F8; bl refreshes.withdraw_a; nop
org $804D910; bl refreshes.b; nop
org $804D988; bl refreshes.withdraw_psi_memo_block_input_up_and_down
org $804D994; bl refreshes.up_and_down
org $804D9C0; bl refreshes.withdraw_block_input_lr
org $804D9E0; bl refreshes.withdraw_lr; nop; nop
org $804F328; bl refreshes.withdraw_printing_pressed_a

//Remove text issue when going from inventory to battle memory
org $804EB26; bl main_menu_hacks.delete_vram_inv_to_battle_memory

//Fix issue with equipment when removing items from the inventory
org $802A560; bl extra_hacks.position_equipment_item_removal

//Make cheese consistent inside and outside of battle (Salsa is the default case)
org $805CB84; bhi $805CBC2

//============================================================================================
//                                  NAMING SCREEN HACKS
//============================================================================================

org $804594E; bl naming_screen_hacks.bullets1
org $8045912; b $804591C
org $804591C; bl naming_screen_hacks.bullets2
org $804C652; bl naming_screen_hacks.factload1
org $804C674; bl naming_screen_hacks.factload2
org $8059220; push {lr}; bl naming_screen_hacks.credits1
org $8059246; push {lr}; bl naming_screen_hacks.credits2
org $80591EC; push {lr}; bl naming_screen_hacks.credits3

// Insert new letter selection screen
org $9BA2DBC; incbin ./gráficos/gfx_namingscreen.bin

// Insert new coordinate tables
org $9B8FF74; incbin data_namingscreen1.bin
org $80C6AAC; incbin data_namingscreen2.bin

// Fully covers/erases "Don't Care" on the player naming screens
org $804A3C4; db $06

// Fix the coordinate table stuff
org $8053E6C; db $64
org $8053E78; db $64
//org $8053DFC; db $67
org $804DD00; db $67
org $804F544; db $74
org $804F548; db $74
org $804F54C; db $2C,$F6
org $804F550; db $2C,$F6
org $804F554; db $2C,$F6
org $804F558; db $2C,$F6
org $804F55C; db $2C,$F6
org $804F56C; db $32,$F6
//org $8053D1C; db $09
//org $8053D8C; db $09

// Make the game reprint stuff only when needed
org $804DC7A; bl naming_screen_hacks.pressed_a_check_print
org $804DCEC; bl naming_screen_hacks.pressed_b_check_print
org $8042968; bl naming_screen_hacks.compare_currently_displayed_entry
org $8042B90; bl naming_screen_hacks.compare_currently_displayed_entry
org $804C77E; bl naming_screen_hacks.reprint_invalid_duplicated
org $804E560; bl naming_screen_hacks.reprint_after_invalid_duplicated

// If you use OAM for "Is this okay? Yes No", uncomment the line below
//org $8042EFC; bl naming_screen_hacks.compare_currently_displayed_entry

// Disable L and R alphabet switching
org $803E79F; db $E0

// Enable L and R alphabet switching on the factory screen
//org $804DD16; db $0E // L
//org $804DD60; db $0E // R

// Cycle through two alphabets instead of three (all screens)
//org $804DD34; db $20 // L
//org $804DD76; db $20 // R

// Allow characters to use more than one "Don't Care" name - From Jumpman
org $8050562; nop; nop

// Alter namable characters' name lengths
org $80C69D4; db $08
org $80C69E0; db $08
org $80C69EC; db $08
org $80C69F8; db $08
org $80C6A04; db $08
org $80C6A10; db $09
org $80C6A1C; db $08
org $80C6A4C; db $08
org $80C6A58; db $08
org $80C6A64; db $08

// Alter sanctuary/factory name lengths
org $80C6A70; db $10
org $80C6A7C; db $10

// Fix fav. food alignment on naming summary screen
org $8042E12; db $94,$21

// Fix fav. thing alignment on naming summary screen
org $8042E58; db $94,$24

// Fix text speed alignment on naming summary screen
org $8042EA8; db $94

// reposition text on the main naming screens to look better
org $8042924; db $78
org $804297A; db $78
org $804297C; db $1B
org $8045D0E; db $26       // Invalid/duplicate name

// Super sanctuary factory combination power
org $8042902; db $68
org $8042912; db $68
org $8042934; db $78
org $804C634; db $10
org $804C63E; db $10
org $8045902; db $10
org $8055BB8; db $10
org $804DCB2; db $10

// Change the sanctuary screen arrangement to match the factory screen one
org $804A0F8; db $48
org $9BBB7BC; incbin ./gráficos/gfx_factory_arrangement.bin
org $9BBEFBC; incbin ./gráficos/gfx_summary_arrangement.bin
org $9BBFFBC; incbin ./gráficos/gfx_flavours_arrangement.bin

// Change the sanctuary graphics to include the custom window border tiles
org $9BB69FC; incbin ./gráficos/gfx_sanctuaryborders.bin
org $9BB89FC; incbin ./gráficos/gfx_sanctuaryborders.bin
org $9BAD5BC; incbin ./gráficos/gfx_namingscreen.bin

// Make the factory screen write its name to 2004F26
org $8055BD8; dd $2004F26

// New credits tileset
org $9C5FE60; dd $00326614
//org $9C8D24E; db $00,$00,$00,$00,$00,$00
org $9F86340; incbin ./gráficos/gfx_credits_[c].bin
org $9C86E98; incbin ./gráficos/gfx_credits_arrangement.bin
org $9F86140; incbin data_creditstable.bin
//org $9F86340; incbin font_creditsfont_[c].bin

// This fixes something with the naming screens
org $80428FE
  cmp r0,#0xD
  blt $8042924

// Treat the factory screen’s cursor-moving as the sanctuary screen’s
//org $8053C6C; b $8053C70

// Naming screen coordinate fixes
org $8053C34
push {lr}
bl   naming_screen_hacks.cursor_megafix
pop  {pc}

// fixes sanctuary name length weirdness
org $804C9D2; db $10

//============================================================================================
//                                  ITEM LENGTH HACKS
//============================================================================================

org $80488C2; bl main_menu_hacks.write_item_text
org $803E9FC; bl main_menu_hacks.clear_data
org $80489CE; bl main_menu_hacks.write_item_eos
org $80492B2; bl main_menu_hacks.check_special_bit
org $804889C; bl main_menu_hacks.store_total_strings
org $8048932; nop; nop; nop
org $8048C78; bl main_menu_hacks.reset_processed_strings; b $8048CD4
org $80487FE; bl main_menu_hacks.load_remaining_strings_external; nop; nop; nop; nop; nop
org $803E996; bl main_menu_hacks.group_add_check

// these changes make the game load all 22 letters of items names in various menus
org $8046F7C; db $16       // Goods screen
org $8046F92; db $16
org $8046FC2; db $16
org $804704C; db $16       // Key Goods screen
org $8047062; db $16
org $8047092; db $16
org $8047AF0; db $16       // Equip screen
org $8047102; db $16
org $8047310; db $16       // Status screen
org $8047512; db $16       // Skills screen
org $8047528; db $16
org $80474F0; db $16
org $804758E; db $16
org $80474A2; db $16       // PSI screen
org $80474B8; db $16
org $8047572; db $16
org $8047238; db $16
org $8047262; db $16
org $80472AE; db $16
org $80477A0; db $16       // Shop screens
org $8047810; db $16
org $80478A4; db $16       // Item storage screens
org $80478BA; db $16
org $8047972; db $16
org $8047988; db $16
org $80479C2; db $16
org $80478EA; db $16

//============================================================================================
//                                  MAIN SCRIPT HACKS
//============================================================================================

// modifies GetAddressofGlyphBitmap()
org $8009D9E; mov r0,#0x20
org $8009DA6; b $8009DCC

// modifies the VCount handler to move text up
org $80055FE; cmp r0,#0x7F
org $8005602; cmp r0,#0x7F
org $8005622; mov r0,#0x7F
org $8005638; add r0,#0xC

// modifies Create10x10GlyphForCharacter for main dialog font
org $8008C7A
  mov  r1,sp
  bl   main_script_hacks.fast_prepare_main_font
  add  r7,sp,#0x18
  b    $8008CC0

// modifies the width calculation routines
org $8009DEA
  mov  r0,#0x3
  and  r0,r2
  cmp  r0,#0
  beq  $8009E08
org $8002260
  nop
  b    $8002284
  nop
  nop
org $8002284                 // calculate the width
  cmp  r1,#0xFF              // Jeff credits hack: if r1 > 0xFF, use fullwidth of 16
  bls  +
  mov  r0,#16
  b    $800239e
  
  +
  ldr  r3,=#{main_font_width} // r3 has the main width table
  mov  r0,#0x02              // if the second bit of r2 is set, we're doing the 8x8 font
  and  r0,r2                 // and should update the address for the 8x8 width table
  cmp  r0,#0x02 
  bne  +

  add  r3,#0x80              // add 0x100 to get 8D1CF78, our 8x8 width table
  add  r3,#0x80              // add 0x100 to get 08D1CF78, our 8x8 width table

  +
  lsl  r1,r1,#0x18
  lsr  r1,r1,#0x18           // make r1 into a byte
  ldrb r0,[r3,r1]            // load the width
  b    $800239e              // return to our regularly scheduled programming

// makes numbers print correctly in the main script
org $800A108; db $10

// byuu's 8-bit script conversion + Jeff's menu stuff + Mato's custom control code stuff
org $8021B18; bl main_script_hacks.script_convert

// Modify the main script auto-line wrap counter. CHANGING THIS CAUSES MAJOR PROBLEMS!
org $800A100; db $FF

// Jeff's [BREAK]-overwrite bug fix
org $8009C54
  mov  r2,#0xFF
  mul  r2,r1
  nop
org $8008EDC; db $FF
org $8008EEC; db $FF
org $8009C70
  mov  r2,#0xFF
  mul  r2,r1
  nop

// fixes the Japanese Greek letters
org $8CDB8B4; dw $003B,$003C,$003D,$003E
// Fix the display of PK [FAVTHING] and related issues
org $8001CAA
  mov  r0,#0xEA
  strh r0,[r4,#0]
  add  r0,r2,#2
  b    $8001CB4
org $8001CD6
  strh r0,[r1,#2]
org $8001CF2
  bl   main_script_hacks.pk_fav_fix
  mov  r0,r4
  b    $8001D22
  
// implement custom item control codes in the main script
org $802A9B8; bl main_script_hacks.current_item_save1
org $801BA7E; bl main_script_hacks.current_item_save2

// Paul's chapter end/Block 0 8-bit text conversion stuff
org $8027F68; bl main_script_hacks.chapter_end_convert

// Fixes the strange Hinawa->Thomas, Flint->Reconstructed Caribou bug
// See the thread "Programming IV" for details if interested
org $80230FA; nop

// change scrolly text text limit to 50 letters per line
org $80223D0; db $32

// move all scrolling text to the left a tiny bit
org $80207FE; db $02

// Scrolly text sprite flashing fix
org $80060F6; bl extra_hacks.scrolly_sprite_fix; b $8006100
org $8027F8A; bl extra_hacks.scrolly_sprite_fix2

// fixes text speed issues, allows infinite # of glyphs
org $80088CA; bl main_script_hacks.insert_extra_letter1
org $80229C4; bl main_script_hacks.insert_extra_letter2
org $8008B56; bl main_script_hacks.move_to_next_glyph; nop

// changes the letter per line limit from 22 to 255
org $8008A0A; lsl r2,r2,#4
org $8006B6A; lsl r4,r4,#4
org $8006CE2; lsl r4,r4,#4
org $8008B66; lsl r2,r2,#4
org $8008BB2; lsl r0,r0,#4
org $8006C30; dw $0D8A
org $8006DA4; dw $0D8A
org $800A09A; bl main_script_hacks.change_clear_amount
org $8008A22
  mov r1,#0xC8
  bl  main_script_hacks.optimized_character_search_overworld
  
// saves data used in order to print overworld text faster
org $8008B18; bl main_script_hacks.save_data_optimized_printing

// fixes the flyover text, only 50 letters per line allowed
org $8024F76; bl main_script_hacks.prepare_info_zone
org $80098F0; bl main_script_hacks.flyover_fix1
org $800959A; bl main_script_hacks.flyover_fix2

// fixes Block 0 display stuff, mostly with the Bug Memory and Pig Notebook
org $8009730; bl main_script_hacks.block0_text_fix2
org $8009428; bl main_script_hacks.improve_notebook_printing; b $8009452
org $80071D2; bl main_script_hacks.remove_tiles_showing_notebook
org $80071DC; bl main_script_hacks.remove_tiles_cleaning_notebook

// make Block 0 cut scenes work properly
org $80244F8; dd $02014340       // block 0 text will be handled here
org $8024FE2; bl main_script_hacks.blockzero_address
org $80244E0; db $68             // set the size (in bytes) of each block of text per line
org $8024502; db $6C             // let the game know how far apart the blocks are (with header)
org $8022382; db $68             // let the game know how many letters to clear before writing
org $8024FF0; db $68             // let the game know how many letters to clear
org $8024FFC; db $68             // let the game know where end of current block is
org $802500A; db $6C             // let game know how far apart each block is

// make the [CENTER] codes allow for longer text with Block 0 stuff
org $8021BE6; add sp,#-0x64
org $8021DB2; add sp,#0x64
org $8021C0A; db $64
org $8021CC6; db $64

// make Block 0 scrolly text not repeat and act weird after 11 lines
org $8024548; dd $02014340
org $8024520; db $68
org $802453C; db $6C

// make the Block 0 key items work properly
// there are still various limitations to the text, but this
// makes it work
org $802507A; bl main_script_hacks.blockzero_address
org $8025088; db $68
org $8025094; db $68
org $80250A2; db $6C

// Make [PLAYERNAME] display all 16 characters in dialogue
 org $8022000; db $10

// Fix [42 FF F0 FF] display gitch
org $8021FD0; mov r2,#8

// Fix [FAVFOOD]
org $8021FFE; bl main_script_hacks.favfood_fix

// Fix standard character display; located code that seems to use a length
// of 6, this changes it to 8, don't know if it's ever used or how
org $8021FCA; db $08

// set a special flag when 4+ menu option line is being processed
org $802269C; bl main_script_hacks.set_specialmenuflag

//Change where multi-break menus are stored and how they work
org $80226F8; dd $203F800-$201B7A0
org $80226A8; b $80226BA
org $80226C0; bl main_script_hacks.end_line_multi_menu

//============================================================================================
//                                  MISC OUTSIDE HACKS
//============================================================================================

// Re-center various main menu labels. Note that some rare labels may be missing still.
org $8040456; db $BD       // Goods
org $8040902; db $BD
org $8040A82; db $C0       // Equip
org $8043016; db $C0
org $804121E; db $BB       // Skills
org $8040C26; db $C5       // PSI
org $80410AE; db $BF       // Status
org $804167E; db $AF       // Battle Memory
org $8041886; db $BE       // Shop
org $8041990; db $BE
org $8041D00; db $BE
org $804181A; db $BE
org $8041F36; db $B6       // Item Dude
org $80420AC; db $B6
org $8042348; db $B6
org $8041FA2; db $B6

// re-center various menu labels using these new x-coordinates
org $80C20E8; db $BD         // Goods
org $80C20EA; db $C0         // Equip
org $80C20EC; db $C5         // PSI
org $80C20EE; db $BE         // Status
org $80C20F0; db $B7         // Sleep

// centers all the Sleep Mode confirm text better
org $8038564; db $29
org $8038578; db $55
org $803858C; db $91

// centers all the Sleep Mode confirm text cursors better
org $80C20D8; db $44
org $80C20DC; db $80

// move the names in outside nameboxes up 1 pixel to look nicer
org $8038B1A; add r2,r5,#3

// centers names in the outside nameboxes
org $8038AF0; bl outside_hacks.center_names; nop

// adds custom stuff to string counting routines, allows nameable names to be longer
org $8022F6C
  push {lr}
  bl   outside_hacks.string_length_count
  pop  {pc}

// Modifies the routine that loads the 16x16 font data for outside menu box labels
org $80092BA
  mov  r4,r6
  add  r4,#0x85
  mov  r1,sp
  bl   outside_hacks.fast_prepare_main_castroll_font
  cmp  r5,#0                 // skip printing if the tiles are empty
  beq  $8009322
  cmp  r5,#2                 // partially skip printing if the first tile is empty
  beq  $8009312
  b    $8009300
  
org $8009302
  ldrb r2,[r4,#0]
  lsr  r2,r2,#4
  mov  r1,sp
  mov  r3,#2
  bl   $8001EA4
  cmp  r5,#2                 // skip printing if the bottom tiles are empty
  blt  $8009322

org $800931A; add r1,sp,#0x10

// Speed up the routine that loads the 8x8 font data for outside
org $8009336
  mov  r1,sp
  bl   sprite_text_weld.fast_prepare_small_font
  cmp  r0,#0                 // skip printing if the tile is empty
  beq  $800938A
  b    $8009368

org $8009374; mov r3,#1; bl $8001EA4; b $800938A

// moves gray name box text up one pixel
org $8023576; db $71
org $8023DDE; db $FB
org $8023D32; db $03
org $8023AFE; db $FB
org $8023A76; db $03
org $8023C5E; db $FB
org $8023E42; db $FB
org $8023C2A; db $FB
org $8023B98; db $03

// makes the gray name boxes fit the names better
org $8023A10; bl outside_hacks.gray_box_resize; cmp r7,#0x31
org $8023A50; bl outside_hacks.gray_box_number
org $8023B32; bl outside_hacks.gray_box_resize; cmp r7,#0x31
org $8023B72; bl outside_hacks.gray_box_number
org $8023CCC; bl outside_hacks.gray_box_resize; cmp r7,#0x31
org $8023D0C; bl outside_hacks.gray_box_number

// makes it so names occupy less obj tiles
org $8009070; bl outside_hacks.different_oam_size
org $800912C; bl outside_hacks.different_tiles_storage; nop; nop; nop; nop; nop; nop; nop
org $80091B8; bl outside_hacks.different_tiles_add
org $80091C2; bl outside_hacks.different_tiles_print

//============================================================================================
//                              SOUND PLAYER & BATTLE HACKS
//============================================================================================

// modifies GetAddressofGlyphBitmap for sound player and battle text
org $8088E80; bl battle_hacks.get_glyph_address; b $8088E90

// loads 11 rows of the 16x16 font instead of 10, affects sound player and battle text
// It's important that only 11 rows be loaded instead of the full 16
org $808948C; bl battle_hacks.fast_printing; b $80894AC

// loads a different address for the e symbol's 1bpp version
org $8088EC4; dd {e_symbol_1bpp}

// this hack lets the game clear out 11 rows of a font letter when erasing stuff
org $8089156; mov r0,#0xB; nop

// This fixes the problem where names and other stuff would get cut off by long descriptions
org $806EBB6; bl battle_hacks.get_number_of_tiles_to_clear

// Makes various battle menu text use a VWF
org $806EB9E; bl battle_hacks.menu_vwf

// Implements the little hack we did where battle text pointers need to be multiplied by 2
org $8088DF8; push {lr}; bl battle_hacks.text_pointer_fix

// this centers some sound player text and also parses custom control codes in battle
org $8088E00; push {lr}; bl battle_hacks.prepare_custom_cc; nop
org $806EA4E
  ldr  r0,=#0x2014300
  ldrh r0,[r0,#0]
  b    $806EA62

// make numbers print correctly in battle
org $806E20C; db $10

// moves battle namebox names up 1 pixel to look better
org $807CD5E; db $0D

// apply a VWF to the main battle text, pretty complicated stuff
org $80840D2; nop; push {lr}; bl battle_hacks.main_vwf1
org $808418E; push {lr}; bl battle_hacks.main_vwf2
org $8083FE2; push {lr}; bl battle_hacks.clear_battle_window
org $80841C6; mov r0,#0             // always be on line 0
org $80841DC; mov r0,#0             // always be on char 0
org $80841DE; nop; nop              // always be on the same letter
org $80841EE; nop                   // make the game stay on char 0
org $80841F6; b $8084200            // make the game not insert lines breaks every few letters
org $8083EA4                        // changes the text's vertical spacing from 12 pixels to 11
  mov r1,#0xB
  mul r1,r2 
org $8084340; mov r0,#0              // makes [WAIT] codes work as they should in battle
org $806EB1A; nop                   // make the battle text erase correctly

// final battle vwf
org $8085592; db $00          // always stay on line 0
org $808559C; nop; b $80855AC // disable line scrolling-up stuff
org $80855BA; db $00          // always stay on letter 0
org $808545C; push {lr}; bl battle_hacks.finalbattle_vwf1
org $8085514; push {lr}; bl battle_hacks.finalbattle_vwf2
org $808557A; bl battle_hacks.finalbattle_vwf_clear_window

// 3-line battle VWF
org $8085AFA; db $00          // always stay on line 0
org $8085B04; nop; b $8085B14 // disable line scrolling-up stuff
org $8085B22; db $00          // always stay on letter 0
org $8085A06; push {lr}; bl battle_hacks.3line_vwf1
org $8085ABE; push {lr}; bl battle_hacks.3line_vwf2
org $8085AEA; bl battle_hacks.3line_vwf_clear_window

// throw away items battle VWF
org $8084848; push {lr}; bl battle_hacks.toomany_vwf1
org $8084A84; push {lr}; bl battle_hacks.toomany_vwf2
org $8084AEE; db $00          // always stay on line 0
org $8084B2A; db $00          // always stay on character 0
org $8084B32; nop; b $8084B46 // get rid of scrolling-up stuff
org $808495E; mov r0,r1; nop
org $8084AD2; push {lr}; bl battle_hacks.toomany_vwf_clear_window


// re-center char names on HP boxes in battle
org $807D2D8;
  push {lr};
  bl   battle_hacks.center_name;
  nop
  nop
  nop
org $807D31E
  mov  r7,r9
  ldrb r2,[r7,#2]
  add  r2,#0x20
  mov  r1,r2
  nop

// these hacks save/clear data for the custom CC hacks
org $807A746; bl battle_hacks.clear_current_enemy        // clears current enemy #, fixes "The Flint"
org $80809FC; bl battle_hacks.save_current_enemy         // saves current enemy #, needs improvement
org $8062C26; bl battle_hacks.save_total_enemies         // saves total # of enemies
org $8064984; bl battle_hacks.save_current_item          // saves current item #
org $807B16C; bl battle_hacks.save_current_enemy_1       //General menus
org $8073E40; bl battle_hacks.save_current_enemy_2
org $8073740; bl battle_hacks.save_current_enemy_3       //Damage
org $8073EEC; bl battle_hacks.save_current_enemy_4       //Shields - Refresh
org $8074CE8; bl battle_hacks.save_current_enemy_1       //Paralysis - Sleep - Solidification
//org $80BABD4; bl battle_hacks.save_current_enemy_5       //Called by stat decrease/increase - Problem, evil
org $807B52C; bl battle_hacks.save_current_enemy_6; nop  //Death
org $80BC068; bl battle_hacks.save_current_enemy_7       //Poison
org $809D2A4; bl battle_hacks.save_current_enemy_8       //Feeling Strange
org $80BBF5C; bl battle_hacks.save_current_enemy_7       //Fire
org $8078704; bl battle_hacks.save_current_enemy_9       //Generic action
org $80BC4D2; bl battle_hacks.save_current_enemy_10      //No effect
org $8078C40; bl battle_hacks.save_current_enemy_11      //No visible effect
org $8079A4E; bl battle_hacks.save_current_enemy_10      //It didn't work
org $80B3640; bl battle_hacks.save_current_enemy_12      //There was no effect (PK Flash on party)
//org $808208C; bl battle_hacks.save_current_enemy_13      //Can't act (No PP left)
//org $8074238; bl battle_hacks.save_current_enemy_14      //Feeling strange enemy
org $8075012; bl battle_hacks.save_current_enemy_15      //No PPs
org $80B2E24; bl battle_hacks.save_current_enemy_16      //Shield Killer
org $80BEFEC; bl battle_hacks.save_current_enemy_17      //Shield Snatcher
org $80AF0EC; bl battle_hacks.save_current_enemy_18      //Feeling strange enemy (group)
org $80AF102; bl battle_hacks.save_current_enemy_18      //Feeling strange enemy (alone)
org $80755A4; bl battle_hacks.save_current_enemy_4       //Status affliction
org $809E3A8; bl battle_hacks.save_current_enemy_19      //Dancing
org $809D47E; bl battle_hacks.save_current_enemy_20      //Feeling strange character (eating)
org $809D48C; bl battle_hacks.save_current_enemy_21      //Feeling strange character (acting)
org $80BB916; bl battle_hacks.save_current_enemy_22      //Time bomb explodes
org $8078602; bl battle_hacks.save_current_enemy_23      //Target
org $809C670; bl battle_hacks.save_current_enemy_24      //Salsa's Mimic
//org $806074C; //Getting revived from items

// this code actually executes the custom control codes
org $806E464; push {lr}; bl battle_hacks.execute_custom_cc; b $806E47A

org $8064998; bl battle_hacks.favfood_9letters

// re-arrange the item-stealing text in-battle
org $80B1B02; bl battle_hacks.item_steal_text; b $80B1B84
org $80B3F66; bl battle_hacks.item_steal_text2; b $80B3FE8

//============================================================================================
//                                    GRAPHICS HACKS
//============================================================================================

// Insert Osohe Sketch
org $9B1F45C; incbin ./gráficos/gfx_sketch_osohe_1.bin
org $9B81B5C; incbin ./gráficos/gfx_sketch_osohe_2.bin

// Insert Thunder Tower Sketch
org $9B5E8DC; incbin ./gráficos/gfx_sketch_tower.bin

// Insert Highway Sketch
org $9B73A7C; incbin ./gráficos/gfx_sketch_highway.bin

// Insert Laboratory Sketch
org $9B6595C; incbin ./gráficos/gfx_sketch_lab.bin
org $9B6A9DC; incbin ./gráficos/gfx_sketch_lab_arrangement.bin

// insert ATM graphics
org $9AFD8D0; incbin ./gráficos/gfx_frogatm.bin

// insert pencil sprite graphics
org $98BBCD0; incbin ./gráficos/gfx_pencil_sprites.bin

// insert nostalgia room statue graphics and new palette
org $8F09C94; incbin ./gráficos/gfx_statues_[c].bin
org $8F7C4BC; incbin ./gráficos/gfx_statues_pal.bin

// Insert new chapter title screen graphics
org $9AF3844; dd $0049C870
org $9F90000; incbin ./gráficos/gfx_chaptertitles_[c].bin
org $9B03580; incbin ./gráficos/gfx_chapt1-4_arrangement.bin
org $9B05580; incbin ./gráficos/gfx_chapt5-8_arrangement.bin

// Insert the special graphics for the start of Chapter 4
org $98AA8D0; incbin ./gráficos/gfx_3yearslater.bin

// Insert YOU WON! graphics to replace YOU WIN!
org $9C98A28; incbin ./gráficos/gfx_youwon.bin
org $9CFB00C; incbin ./gráficos/gfx_youwon_arrangement.bin

// Insert text speed/window flavor graphics
org $9BA0D9C; incbin ./gráficos/gfx_flavours.bin

// Insert new Health Screen graphics
org $9C8F332; db $E8 // Move the flashy text up by 8 pixels
org $9C8F338; db $E8
org $9C8F33E; db $E8
org $9C8F344; db $E8
org $9C8F34A; db $E8
org $9C8F350; db $E8
org $9C8F356; db $E8
org $9C8DEB4; incbin ./gráficos/gfx_healthscreen_[c].bin
org $9C8EC48; incbin ./gráficos/gfx_healthscreen_arrangement_[c].bin
org $9C8DEA8; dd $9F87A20-$9C8DE98
org $9F87A20; incbin ./gráficos/gfx_healthtext_[c].bin

// insert new "LAB" graphics to replace "LABO"
org $8F0E670; incbin ./gráficos/gfx_lab1_[c].bin
org $8F0E9E0; incbin ./gráficos/gfx_lab2_[c].bin

// Change OFE/DFE to OFF/DEF in Goods > Give screen
org $9B8FFC4; dd $9FDB000-$9B8FFC0
org $9FDB000; incbin ./gráficos/gfx_offdef_[c].bin

// Change MONOTOLY to MONOTOLI in the theater
org $8D3E09C; dd $01256D20
org $9F92200; incbin ./gráficos/gfx_monotoli_[c].bin

// silver star sprite for the battle memory star hack
define star_sprite_address $9F86120
org {star_sprite_address}; incbin ./gráficos/gfx_starsprite.bin

//Ver 1.3 stuff after this

//Fixes TaneTane Island's glitched tileset

org $9FAA450; incbin ./gráficos/gfx_tanetane_layer1_arrangement_[c].bin
org $8F904B4; dd $0101A414 //Layer 1's pointer
org $8FC9004; incbin ./gráficos/gfx_tanetane_layer2_arrangement_[c].bin
org $9FAA7B0; incbin ./gráficos/gfx_tanetane_layer3_arrangement_[c].bin
org $8F904BC; dd $0101A774 //Layer 3's pointer

//Fixes the unused cutscene's tileset

org $8FF423C; incbin ./gráficos/gfx_cutscene_layer2_arrangement_[c].bin
org $8FF44CC; incbin ./gráficos/gfx_cutscene_layer3_arrangement_[c].bin
org $90A596C; incbin ./gráficos/gfx_cutscene_[c].bin

//Changes Bom to Boom
org $98202D0; incbin ./gráficos/gfx_bom.bin
org $8E8ECEC; incbin ./gráficos/gfx_bom_npc_[c].bin

//Stuff for other translations

// - Chimera Lab
org $8D5CC7C; incbin ./gráficos/gfx_lab_movie_[c].bin
org $8D5D0A8; incbin ./gráficos/gfx_lab_elevator1_[c].bin
org $8D5E7E4; incbin ./gráficos/gfx_lab_elevator_animation_[c].bin
org $8D70DCC; incbin ./gráficos/gfx_lab_elevator_animation2_[c].bin
org $8D85B00; incbin ./gráficos/gfx_lab_elevator_floors_[c].bin
org $8E7D800; incbin ./gráficos/gfx_lab_box1_[c].bin
org $8D767F0; incbin ./gráficos/gfx_lab_box2_[c].bin
org $8E79DA8; incbin ./gráficos/gfx_lab_box3_[c].bin
org $8D70764; incbin ./gráficos/gfx_lab_elevator2_[c].bin
//These are just in case you really need them
org $90B9198; incbin ./gráficos/gfx_lab_arrangement_b1f_[c].bin
org $90C16DC; incbin ./gráficos/gfx_lab_arrangement_2f_room2_[c].bin
org $90BCF68; incbin ./gráficos/gfx_lab_arrangement_1f_[c].bin
org $90BE970; incbin ./gráficos/gfx_lab_arrangement_1f_room_[c].bin
org $90C0078; incbin ./gráficos/gfx_lab_arrangement_2f_[c].bin
org $90C2A54; incbin ./gráficos/gfx_lab_arrangement_2f_room_[c].bin
org $90C4768; incbin ./gráficos/gfx_lab_arrangement_3f_room1_[c].bin
org $90C4DC8; incbin ./gráficos/gfx_lab_arrangement_3f_room2_[c].bin

// - Thunder Tower
org $8D3B870; dd $12A0D20
org $9FDC200; incbin ./gráficos/gfx_thunder_elevator_extern_[c].bin
org $8D3B720; dd $12A1020
org $9FDC500; incbin ./gráficos/gfx_thunder_elevator_intern_[c].bin

// - Club Titiboo
org $8D50A00; incbin ./gráficos/gfx_club_keepout_[c].bin
org $8D3BF2C; dd $12A0320
org $9FDB800; incbin ./gráficos/gfx_ropeway_bottom_[c].bin
org $8D3C5D4; dd $12A0720
org $9FDBC00; incbin ./gráficos/gfx_ropeway_top_[c].bin
org $8D5A2A8; incbin ./gráficos/gfx_titiboo_oil_[c].bin

// - Debug Room
org $8DB555C; incbin ./gráficos/gfx_debug_[c].bin

// - Tazmily
org $8D3C0F0; dd $8F92A70-$8D3B4E0
org $8F92A70; incbin ./gráficos/gfx_bazar1_[c].bin
org $8D3C0F4; dd $915BA30-$8D3B4E0
org $915BA30; incbin ./gráficos/gfx_bazar2_[c].bin
org $9C68724; incbin ./gráficos/gfx_bazar_credits.bin
org $8D3C134; dd $91602A0-$8D3B4E0
org $91602A0; incbin ./gráficos/gfx_sheriff1_[c].bin
org $8DD5D60; incbin ./gráficos/gfx_sheriff2_[c].bin
org $9640AD0; incbin ./gráficos/gfx_knock.bin
org $9692350; incbin ./gráficos/gfx_ice.bin

// Insert graphic for the CAST sprite
org $9659AB0; incbin ./gráficos/gfx_castleft.bin
org $9658CB0; incbin ./gráficos/gfx_castright.bin
org $1A87871; db $00 // right part position
org $1A87875; db $E0,$70,$61 // left part position, tile id and size respectively
org $143710E; db $30 // collision

// - General
org $8E5D270; incbin ./gráficos/gfx_end0_[c].bin
org $8EEDE28; incbin ./gráficos/gfx_end1_[c].bin
org $8EEE358; incbin ./gráficos/gfx_end2_[c].bin
org $9AF4EA0; incbin ./gráficos/gfx_currency.bin
org $9AF6480; incbin ./gráficos/gfx_hp_pp_battle.bin
org $9C9B108; incbin ./gráficos/gfx_hp_pp.bin
org $9B9C364; incbin ./gráficos/gfx_various_menu1.bin
org $9B9D564; incbin ./gráficos/gfx_various_menu2_[c].bin
org $9B90030; dd $0044C040
org $9FDC000; incbin ./gráficos/gfx_start_battle_[c].bin
org $9C97CE8; incbin ./gráficos/gfx_exit_battle.bin
org $9CA6928; incbin ./gráficos/gfx_music.bin
org $967A0D0; incbin ./gráficos/gfx_happy_end.bin
org $993F270; incbin ./gráficos/gfx_sprays.bin

//Insert hit and total damage graphics
org $9C926C8; incbin ./gráficos/gfx_combo.bin
org $9CFA738; db $FD // 2nd line, up 3 pixels (part 1)
org $9CFA740; db $FD // 2nd line, up 3 pixels (part 2)
org $9CFA748; db $FD // 2nd line, up 3 pixels (part 3)
org $9CFA750; db $FD // 2nd line, up 3 pixels (part 4)
org $9CFAB1C; db $FD // 1st line, up 3 pixels (part 1)
org $9CFAB24; db $FD // 1st line, up 3 pixels (part 2)
org $9CFA73A; db $FE,$81 // 2nd line, left 2 pixels (part 1)
org $9CFA742; db $1E // 2nd line, left 2 pixels (part 2)
org $9CFA74A; db $3E // 2nd line, left 2 pixels (part 3)
org $9CFA752; db $5E // 2nd line, left 2 pixels (part 4)
org $9CFAB1E; db $05 // 1st line, right 5 pixels (part 1)
org $9CFAB26; db $25 // 1st line, right 5 pixels (part 2)
org $8065658; db $3F // full 1st line, left 9 pixels back
org $9CFAB30; db $FD // "MISS" text, up 3 pixels (part 2)
org $9CFAB38; db $FD // "MISS" text, up 3 pixels (part 2)
org $9CFAB32; db $F8,$81 // "MISS" text, left 8 pixels (part 1)
org $9CFAB3A; db $18 // "MISS" text, left 8 pixels (part 2)

// - Titlescreen
org $9BCDE60; dd $2EB4
org $9BD0C40; incbin ./gráficos/gfx_main_menu_[c].bin
org $9C5F838; db $F7,$C0,$00 // NEW GAME, part 1 ($00,$40,$00 => $FC,$C0,$00) position, size, zone
org $9C5F83E; db $37,$40,$60 // NEW GAME, part 2 ($20,$40,$04 => $3C,$40,$60)
org $9C5F848; db $00,$C0,$6F // make LOAD sprite larger + centered ($10,$40,$08 => $00,$C0,$6F)
org $9C5F852; db $FA,$41,$64 // SOUND PLAYER part 1
org $9C5F858; db $1A,$40,$68 // SOUND PLAYER part 2
org $9C5F85E; db $3A,$40,$6C // SOUND PLAYER part 3
org $9C5F81C; db $C0,$C1,$1D // mini credits part 1
org $9C5F822; db $00,$C0,$3D // mini credits part 2
org $9C5F826; db $F5,$10,$40,$00,$5E,$00,$F5,$00,$B8,$01,$5D // mini credits part 3 (put start and end of the sound credits)


// - New Pork City
org $8D3CF34; dd $9FDC800-$8D3B4E0
org $9FDC800; incbin ./gráficos/gfx_ticket_[c].bin
org $8D3D33C; dd $9FDA810-$8D3B4E0
org $9FDA810; incbin ./gráficos/gfx_beauty_intern1_[c].bin
org $8E9CEF0; incbin ./gráficos/gfx_beauty_intern2_[c].bin
org $8D3DE48; dd $9FDABF0-$8D3B4E0
org $9FDABF0; incbin ./gráficos/gfx_beauty_extern_[c].bin
org $8F0A464; incbin ./gráficos/gfx_heli_[c].bin
org $8F0CE20; incbin ./gráficos/gfx_arcade_top_[c].bin
org $8F0D144; incbin ./gráficos/gfx_arcade_bottom_[c].bin
org $8F0D480; incbin ./gráficos/gfx_welcome_[c].bin
org $8F1E0BC; incbin ./gráficos/gfx_vikings_[c].bin
org $8F1EA7C; incbin ./gráficos/gfx_park_[c].bin
org $8F15360; incbin ./gráficos/gfx_amusement_[c].bin
org $8F17844; incbin ./gráficos/gfx_theater_[c].bin
org $98EDAD0; incbin ./gráficos/gfx_police.bin
org $8F217FC; incbin ./gráficos/gfx_porky_empire_[c].bin

// - Highway
org $8E748D0; incbin ./gráficos/gfx_charge0_[c].bin
org $8D3C724; dd $9FDD200-$8D3B4E0
org $9FDD200; incbin ./gráficos/gfx_charge1_[c].bin
org $8EEC604; incbin ./gráficos/gfx_charge2_[c].bin
org $8ED4C38; incbin ./gráficos/gfx_cafe_top_[c].bin
org $8ED4930; incbin ./gráficos/gfx_cafe_bottom_[c].bin

//Put in a swapped version of the menu text palettes
define alternate_menu_text_palette $9FABFC0
org {alternate_menu_text_palette}; incbin ./gráficos/gfx_menu_text_swapped_palette.bin
org $803FAA2; bl main_menu_hacks.add_extra_menu_palette

//============================================================================================
//                                    SOUND HACKS
//============================================================================================

incsrc sound_hacks.asm

// makes sound player song #1 play "look-over-there"
//org $80ECD4E; dw $0451

//============================================================================================
//                                     DATA FILES
//============================================================================================

// insert translated item names
org $8D1EE84; dd $0126D588
org $9F8C400; incbin text_itemnames.bin

// insert translated NPC/speaker names
org $8D1EE90; dd $00FE4F6E
org $9D03DE6; incbin text_charnames.bin

// insert translated enemy names
define enemynames_address $9CFFDA0
org $8D1EE98; dd $00FE0F28
org {enemynames_address}; incbin text_enemynames.bin

// insert the abbreviated enemy names
org $8D23494; incbin text_enemynames_short.bin

// insert music titles
org $8086CF4; dd $09FD7FF0
org $9C8F38C; dd $09FD7FF0
org $9FD7FF0; incbin text_musicnames.bin

// inserts misc. sound player menu text
org $9C926A0; dd $FF06D298
org $8CFDBF8; incbin text_miscmenus.bin

// insert PSI names
org $8D1EE9C; dd $0000A1D8
org $8D29050; incbin text_psinames.bin

// insert special text (includes special skill names)
org $8D1EEB0; dd $00FE84D6
org $9D0734E; incbin text_specialtext.bin

// insert default names
org $8D2C708; incbin text_defaultnames.bin

// insert party character names
org $8D28F30; incbin text_pcharnames.bin

// insert skill descriptions
org $8D1EEB4; dd $FFFDEF80
org $8D1EEB8; dd $FFFDEFE4
org $8CFDDF8; incbin text_skilldescriptions.bin

// insert PSI descriptions
org $8D1EEA0; dd $FFFDAB40
org $8D1EEA4; dd $FFFDAC08
org $8CF99B8; incbin text_psidescriptions.bin

// insert item descriptions
org $8D1EE88; dd $FFFDF430
org $8D1EE8C; dd $FFFDF630
org $8CFE2A8; incbin text_itemdescriptions.bin

// insert special item descriptions (for descs with status icons in battle)
org $9F8F004; incbin text_special_itemdescriptions.bin

// insert battle text
org $9C92698; dd $0031F9F0
org $9FB0350; incbin text_battletext.bin

// insert special text used by custom control codes
define custom_text_address $8D0829C
org {custom_text_address}; incbin text_custom_text.bin

// insert a custom enemy data table, used by our custom control codes Prev=8D08A6C
define enemy_extras_address $9FD4930
org {enemy_extras_address}; incbin data_enemy_extras.bin

// insert a custom item data table, used by our custom control codes
define item_extras_address $8D090D9
org {item_extras_address}; incbin data_item_extras.bin

// insert menu text
org $9B90124; dd $FF175818
org $9B90128; dd $FF175A58
org $8D057D8; incbin text_menus1.bin

// insert menus2.txt (mostly seems to be debug stuff/stuff that got cut out)
org $8D0BA10; incbin text_menus2.bin
org $9B9012C; dd $FF17BA50
org $9B90130; dd $FF17BB9A

// insert menus3.txt (outside menu box titles and debug stuff mostly)
org $9AF3824; dd $FF214758
org $9AF3828; dd $FF2147AE
org $8D07EE8; incbin text_menus3.bin

// inserts status-related text
org $8D1EEA8; dd $00FE7E52
org $9D06CCA; incbin text_statuses.bin

// inserts enemy description text
org $9B90134; dd $00032686
org $9B90138; dd $00032886
org $9BC2644; incbin text_enemydescriptions.bin

// inserts map names
org $8D1EEBE; incbin text_mapnames.bin

// insert main text DUN DUN DUN
org $936A6F4; incbin text_mainscript.bin

// relocate the big sound clip to the end of the ROM, freeing up hack space for us
org $8119C64; dd $9F92600
org $811B734; dd $9F92600
org $811F6DC; dd $9F92600
org $811FA90; dd $9F92600
org $812030C; dd $9F92600
org $9F92600; incbin sound_relocate_dump.bin

// Data table for cast roll hack
org $9FB0000; incbin data_castroll_table.bin

// tiny table/data for the sleep mode text
org $9FB0300; incbin text_sleep.bin

// was planning to make an alternate sound player someday, but decided not to for now
//org $8138000; incbin alt_sound_table.bin
//org $8086CF0; dd $8138000
//org $8086D64; dd $8138000


//============================================================================================
//                                  NEW, EXTRA GOODIES
//============================================================================================

// Big cool battle memory star sprite hack
org $804565C; bl extra_hacks.allenemies

// New icon for bell ringer item
org $8036E90; push {r4,lr}; bl extra_hacks.bellringer; pop {r4,pc}
//org $8036EAC; bl extra_hacks.bellringer
org $993DE30; incbin ./gráficos/gfx_bellicon.bin
org $9FABFE0; incbin ./gráficos/gfx_bellicon_pal.bin

// intro screen
define disclaimer_address $9C9C800
define disclaimer_pal_address $9CA1100
define disclaimer_map_address $9CA2000
org $805AD14; bl extra_hacks.intro_screen
org {disclaimer_address}; incbin ./gráficos/gfx_disclaimer_[c].bin
org {disclaimer_pal_address}; incbin ./gráficos/gfx_disclaimer_pal.bin
org {disclaimer_map_address}; incbin ./gráficos/gfx_disclaimer_map.bin

// enables hard mode when player name is "HARD MODE"
org $8080A9A; bl extra_hacks.double_hp1
org $8080B90; bl extra_hacks.double_hp2
org $8080BA8; bl extra_hacks.double_hp2
org $8080C5A; bl extra_hacks.quadruple_speed

// string used to compare against when enabling hard mode ("HARD MODE")
org $813C700
hardmodestring:
dw $0028,$0021,$0032,$0024,$0040,$002D,$002F,$0024,$0025,$FFFF

// Binfile copy of the intro screen hack
org $813C5D8
introhackcode:
incbin data_introcode.bin

// fixes a bug in the original game - makes the Dr. A empty trash can print the right line
// and it fixes the Murasaki hot spring sign
org $91F9109; db $17
org $9121834; db $0C
org $91F911D; db $16

// Fixes Duster attack sound bug in the original game
org $809C8F0; bl battle_hacks.duster_fix

// Fixes the Chauffeur bug
// In case you can't get it to occur, it happens if you start playing from froggie save 7Y (first slot).
org $9284CEA; db $04

// Fixes the "wrong map displays in the wrong place" bug
org $80C4148; db $00 // Theater projector room
org $80C4178; db $00 // Upstairs hallway (outside Leder's room)
org $80C4184; db $00 // Leder's room  

//After this line is v1.3 stuff!

//Changes the text of Jumbo Shrimp Soup and Rich Kid Pork Stew to "eat"
org $80E8548; db $46
org $80E8914; db $46

//Changes sheep's position in scene F6
org $914DEF7; db $1D

//Fixes Thunder Tower's Frog
org $9157CE9; dd $E0001450
org $9157CF2; db $1B

//Fixes Lucas talking in chapter 5
org $92F561C; dd $FFFFFF01

//Fix issue in which Lucas' sprite would become Boney's because of missing ifs, we're also shuffling other stuff to save space
org $934E4A4; incbin logic_pointer_36C.bin
org $934E4B4; incbin logic_code_36C.bin
org $919A784; dd $001B8338
org $919A788; dd $001B8354
org $919A78C; dd $00E383F0
org $919A790; dd $00E38400
org $9350F48; incbin logic_36D.bin
org $9FD1000; incbin logic_36E.bin

//Fix wrong collision data for man in bathroom: http://archivededamien.blogspot.com/2019/02/petit-glitch-decouvert-recemment.html#links
org $9163DD8; db $01
org $9163DE4; db $70
org $9163DE7; db $00

//Fix gift boxes issues in room 025, optimizing sprite usage
org $913E1D4; incbin object_table_4_025_segment.bin

//Fix gift boxes issues in room 1D9 and 058 using room 346 as a reference - 346's sprite table = 1162428

//Insert new sprites
org $9FD2000; incbin object_table_1_058.bin
org $9FD21E0; incbin object_table_4_058.bin
org $9FD23C0; incbin object_table_1_1D9.bin
org $913323C; dd $00E9F4A8
org $9133248; dd $00E9F688
org $9135050; dd $00E9F868

//Insert new game logic for 058, we'll also move the one after it, since it's much smaller
org $921DE88; incbin logic_pointer_058.bin
org $921DEB4; incbin logic_code_058.bin
org $9198EE4; dd $00E39948
org $9198EE8; dd $00E3995C
org $9FD2558; incbin logic_059.bin

//Remove original gift box's collision of 058
org $8FC547C; incbin ./gráficos/gfx_forest_layer3_[c].bin

//Remove overflows from 1D9
org $8F77A3C; incbin ./gráficos/gfx_ice_highroad_palette.bin
//Tileset graphics
org $8D3CD38; dd $01297290
org $9FD2770; incbin ./gráficos/gfx_highroad_ice_1_[c].bin
org $8D3D92C; dd $01297520
org $9FD2A00; incbin ./gráficos/gfx_highroad_ice_2_[c].bin
org $8D3D934; dd $01297860
org $9FD2D40; incbin ./gráficos/gfx_highroad_ice_3_[c].bin
org $8D3D938; dd $01297D90
org $9FD3270; incbin ./gráficos/gfx_highroad_ice_4_[c].bin

//Map Tile Data
org $904E134; dd $00F85BB4
org $9FD3580; incbin ./gráficos/gfx_highroad_ice_tiledata_[c].bin

//Layers info
//org $8F91670; dd $01043E24
//org $9FD3E60; incbin ./gráficos/gfx_highroad_layer2_[c].bin
org $8F91674; dd $010442C4
org $9FD4300; incbin ./gráficos/gfx_highroad_layer3_[c].bin

//Insert new game logic for 1D9, we'll also move the one after it, since it's much smaller
org $9199AE8; dd $0016DFEC
org $9306BC0; incbin logic_pointer_1D9.bin
org $9306BFC; incbin logic_code_1D9.bin
org $9199AEC; dd $00E373F0
org $9199AF0; dd $00E37420
org $9FD0000; incbin logic_1DA.bin

//Remove High Road's entry
org $916612C; dd $00000000
org $9166130; dd $00000000
org $9166134; dd $00000000
org $9166138; dd $00000000

//Remove Forest's entry
org $916638C; dd $00000000
org $9166390; dd $00000000
org $9166394; dd $00000000
org $9166398; dd $00000000

//Fix issue with sound at Lydia's House (Map 0x4F), the Mechorilla's sounds are all late normally
org $8C9505A; db $A2

//Add Multi Debug room: selected table = money on hand - 1'000'000 | money on hand address: 0x02004868
org $9364430; incbin logic_multi_debug.bin
org $9360076; db $EC //Change pointer to another script that does the exact same thing.

//Update K9000's battle sprites
org $9CDF638; incbin ./gráficos/gfx_k4n1n0_battle_[c].bin
org $9C90EE0; dd $0004ECD8 //Repoint the sprite graphics

//Update Nuclear Reactor Robot's battle and overworld sprites
org $97690D0; incbin ./gráficos/gfx_nuclear_sprite.bin
org $9CDFE84; incbin ./gráficos/gfx_nuclear_battle_[c].bin
org $9C90DE0; dd $0004F524 //Repoint the sprite graphics
org $9C90DE4; dd $000004B0 //Update the length of the graphics

//Update Lovewalker's battle sprites
org $9CE0340; incbin ./gráficos/gfx_rompecorazones_battle_[c].bin
org $9C90DC8; dd $0004F9E0
org $9C90DCC; dd $000004CC
//Fix trades of the ghost
org $93285C0; incbin data_ghost_fix.bin
//org $80D3594; dw $0268
//org $80D6204; dw $0268

//Fix "Multiple PK Thunders" bug
define target_num_table $9FD5F80
define target_num_table_size $1C
org {target_num_table}; incbin data_target_table.bin
org $8075024; bl fix_synchronization.setup_action_beginning
org $805DE2C; bl fix_synchronization.setup_battle_beginning
org $805F47A; bl fix_synchronization.setup_turn_beginning
org $8078418; bl fix_synchronization.fix_value_beginning_of_action_routine
org $8078502; bl fix_synchronization.update_value
org $8078582; bl fix_synchronization.end_routine

//Fix flickering in Fassad's low voice talk with Lucas. (Script: 32-21)
org $91E0FD8; dd $000DA801 //Make it so this text box doesn't display its speaker
org $801D74C; bl main_script_hacks.speaker_different_unused_val_setup
org $80239B8; bl main_script_hacks.speaker_different_unused_val_block

//Fix Debug Room's Staff roll
org $91C6880; incbin logic_00E.bin
org $91C457C; db $15 //Add a new entry to 00E's logic
org $91C45A6; dw $08B6 //Add the new entry's pointer
org $91C46B1; db $0F //Replace old entry loader with this one
org $9FD6000; incbin logic_00F.bin //Move this logic that's smaller
org $9198C94; dd $00E3D3F0
org $9198C98; dd $00E3D400

//Fix wrong text being displayed for train money in Chapter 4-5
//Block 38 - Tazmily station
org $91E9249; db $55 //Two people
org $91E925D; db $56 //Three people
org $91E9271; db $57 //Four people
//Block 47 - Factory station
org $91F2B49; db $05 //Two people
org $91F2B5D; db $06 //Three people
org $91F2B71; db $07 //Four people

//Fix issue with mirrors at Flint's house and Alec's house. Didn't do it in the end, seems to be hardcoded how the mirrors don't spawn if there's only one character and that's what makes it impossible to fix the issue
//Pointers to Alec's house logic
//org $9199084;
//org $9199088;
//Logic of Alec's house
//org $92496A4;

//Alec's house object table pointer
//org $9133660;
//Alec's house object table
//org $9146EB0;

//Fix issue where losing in the prologue removes all Claus' PPs.
org $8001D5A; bl claus_pp_fix.main; pop {r1}; bx r1

//Manage gender for status ailments in status menu //De momento no funciona
org $8044356; bl main_menu_hacks.status_gender

//Fix issue with mouse in block 632 always displaying "Talking to Salsa/Boney"'s line when it can never be interacted with as Salsa
org $9199FD4; dd $00E3CBF0
org $9199FD8; dd $00E3CC04
org $9FD5800; incbin logic_pointer_277.bin
org $9FD5814; incbin logic_code_277.bin

//Fix issue with Thomas in block 91 disappearing if the pigmask notebook is collected and the sprite table is reloaded
org $9222696; db $93 //Jump to next instruction set
org $92226B4; dd $0093000C //Jump to next instruction set

//New control codes for Game Logic
org $8D2DCC8; dd extra_hacks.push_battle_memo_status+1 //04 00 9C 00
org $8D2DCCC; dd $8005B35 //04 00 9D 00 - Resets the drawing mode
org $8D2DCD0; dd extra_hacks.set_money_on_hand+1 //04 00 9E 00
org $8D2DCD4; dd extra_hacks.push_money_on_hand+1 //04 00 9F 00
org $8D2D8C8; dd $0
org $8D2D8CC; dd $0
org $8D2D8D0; dd $1
org $8D2D8D4; dd $0

//Add new npc to swap table in debug room
org $93699D4; incbin logic_new_npc_debug.bin
org $9360070; db $19
org $93600A2; dw $264C
org $9368049; db $0D
org $9FD6B98; incbin object_tables_debug.bin
org $9137120; dd $00EA4040; dd $00EA4220; dd $00EA42E0; dd $00EA4388; dd $00EA4430
org $9FD7078; incbin logic_blocks_37F_380_381_382.bin
org $919A80C; dd $00E3E468; dd $00E3E474; dd $00E3E4DC; dd $00E3E4EC
org $919A81C; dd $00E3E77C; dd $00E3E788; dd $00E3E820; dd $00E3E82C

//Fix pigmask in debug room changing sprite
org $9369CD0; incbin logic_fix_debug_pigmask.bin
org $93682E8; dd $270B000C
org $93683F4; dd $270E000C

//Fix Boney not having the right sprite if chapter 4 is accessed via the debug room option "Violet's Room"
org $9366519; db $05
org $9366601; db $05

//Change missing mice lines to have a "One" mouse missing and a "X" mice missing
org $92EA6D9; db $06
org $92EA6E0; dd $00B9000D; dd $00A7000C
org $92EA8E1; db $06
org $92EA8E8; dd $0133000D; dd $0129000C
org $92EA949; db $00
org $92EA94D; db $0B
org $92EA952; db $67

//Make it so Boney's minimum level at the beginning of Chapter 4 is standardized
org $91DF29D; db $0A
org $91DF2AD; db $0A

//Add back Leder's memo unlocking system
org $91EA604; incbin logic_leder_memo.bin

//Fix 16x16 wall tile being walkable on in Tanetane's cliff
org $90778E8; incbin ./gráficos/gfx_tanetane_cliff_tilemap_[c].bin

//Fix swapped gift box flags in tanetane
org $91669E8; db $A8
org $9168758; db $AA

//Fix item menu after memento is used
org $80604CE; bl fix_mementos_item_menu.initial_setup
org $807C056; bl fix_mementos_item_menu.setup
org $807EB96; bl fix_mementos_item_menu.fix

//Fix Leder's song issue in late chapter 2 and late chapter 3
org $91A778C; incbin logic_leder_fix_song.bin

//Fix the counter for Leder being active or inactive at wrong times
org $91E84C4; dd $0000130E; dd $0000130E //Crossroad when Salsa's escaping
org $931BD20; dd $04B0000C //Dropping from the fireplace in Lord passion's room
org $931C194; incbin logic_leder_fix_counter_fireplace.bin
org $9FD5F00; incbin logic_pointer_283.bin //Move ther pointers of the table next to that one in order to make room for the code
org $919A02C; dd $00E3D2F0 //Point to the pointers

//Fix issue in highway with slope that can be walked on
org $9013AB4; incbin ./gráficos/gfx_highway_layer3_[c].bin
org $90D0140; incbin ./gráficos/gfx_highway_graphics_[c].bin
org $8D3D91C; dd $00394C60
org $9FD74D4; incbin ./gráficos/gfx_highway_tilemap_[c].bin
org $904E01C; dd $00F89B08

//Fix issue with Porky in Absolutely Safe Capsule when comboed
org $809F45A; bl battle_hacks.fix_total_damage

//Fix issue with equip and status showing old data when going from a non-valid character to a valid character
org $80470B4; bl main_menu_hacks.delete_vram_equip; nop //Equip
org $80472C8; bl main_menu_hacks.delete_vram_status; nop //Status

//Fix Nana's age at the NPC's concert
org $91649B4; db $41

//Put code for "battle memo completeness" frog text in game logic
//Shuffle other stuff to save space
define logic_0EA_new_address $9FD5700
org $9285D70; incbin logic_code_0E9.bin
org {logic_0EA_new_address}; incbin logic_0EA.bin
org $9199364; dd {logic_0EA_new_address}-$9198C10; dd {logic_0EA_new_address}+$10-$9198C10;

//Improve performance for equip menu
org $8047112; bl improve_performances_menus.equipment_vram_equip_descriptors //Load OAM entries in VRAM
org $8043832; b $8043888 //Remove OAM entries
org $804E0C8; bl improve_performances_menus.equip_avoid_left_reprint //Don't reprint left column
org $804F780; bl improve_performances_menus.equip_avoid_left_reprint //Don't reprint left column

//Improve performances for status menu
org $80473D8; bl improve_performances_menus.status_vram_equip_descriptors //Load OAM entries in VRAM
org $8044130; b $80441A2 //Remove OAM entries

//Improve the in-battle inventory menu
org $807E46E; bl battle_menus_improvement_hacks.inventory_printing_routine_ud_setup
org $807E47C; bl battle_menus_improvement_hacks.inventory_printing_routine_up_down_call
org $807E4AE; bl battle_menus_improvement_hacks.inventory_printing_routine_ud_setup
org $807E4BC; bl battle_menus_improvement_hacks.inventory_printing_routine_up_down_call
org $807E4FC; bl battle_menus_improvement_hacks.inventory_printing_routine_select_lr_call
org $807E53C; bl battle_menus_improvement_hacks.inventory_printing_routine_select_lr_call
org $807E57C; bl battle_menus_improvement_hacks.inventory_printing_routine_select_lr_call
org $807E5BC; bl battle_menus_improvement_hacks.inventory_printing_routine_ab_call
org $807E60C; bl battle_menus_improvement_hacks.inventory_printing_routine_ab_call

//Improve the in-battle psi menu
org $808C5FA; bl battle_menus_improvement_hacks.psi_printing_routine_ud_setup
org $808C608; bl battle_menus_improvement_hacks.psi_printing_routine_up_down_call
org $808C676; bl battle_menus_improvement_hacks.psi_printing_routine_ud_setup
org $808C684; bl battle_menus_improvement_hacks.psi_printing_routine_up_down_call
org $808C6C6; bl battle_menus_improvement_hacks.psi_printing_routine
org $808C73A; bl battle_menus_improvement_hacks.psi_printing_routine
org $808C794; bl battle_menus_improvement_hacks.psi_printing_routine
org $808C7BA; bl battle_menus_improvement_hacks.psi_printing_routine
org $808BFFC; bl battle_menus_improvement_hacks.psi_printing_routine_change_layer_call
org $808C0B0; bl battle_menus_improvement_hacks.psi_printing_routine_change_layer_call

//Improve the in-battle skills menu
org $808DA34; bl battle_menus_improvement_hacks.skills_printing_routine
org $808DA74; bl battle_menus_improvement_hacks.skills_printing_routine
org $808DAB4; bl battle_menus_improvement_hacks.skills_printing_routine
org $808DAF4; bl battle_menus_improvement_hacks.skills_printing_routine
org $808DB34; bl battle_menus_improvement_hacks.skills_printing_routine
org $808D5EC; bl battle_menus_improvement_hacks.skills_printing_routine_enter_call
org $808DB74; nop; nop
org $808DBC4; nop; nop

//Prevent the map-lowering volume issue
org $800B01A; bl outside_hacks.decrement_block_map
org $801A1A4; bl outside_hacks.block_loading_map
org $8026E4A; bl outside_hacks.decrement_block_map_inside
org $802704C; bl outside_hacks.block_loading_map_inside

//Fix option "Clay Factory" of Chapter 5's NPC in the Debug Room
org $9362AC8; dd $00000A01

//Fix Chapter 7's Kumatora when warping from Debug entries
org $9369CE8; incbin logic_fix_debug_chapter7_kumatora.bin
org $93676CC; dd $2730000C
org $93676F8; dd $2733000C
org $9367724; dd $2736000C
org $9367750; dd $2739000C
org $936777C; dd $273C000C

//Change priority of top text in the naming screens to allow better caching
org $80428FC; bl naming_screen_hacks.change_printing_order; b $8042988

//Re-enable Caroline's Wess line - The Game Logic's pattern
//suggests this line was mistakenly removed
org $923F525; db $13

//Fix Wess' house Area song being set to 74, which is Yado Inn's song
org $919C538; dd $00004001

//============================================================================================
//                                  MEMO SCREEN STUFF
//============================================================================================

// Enable memo menu; hold Sel+L+R while loading the Status menu
org $804BE16; bl extra_hacks.memo_check

// Memo name counter fixes
org $8001DB0; push {lr}; bl extra_hacks.memo_counterfix1; pop {pc}
org $8048500; bl extra_hacks.memo_counterfix2

// Expand memo text
org $804BFD4; bl extra_hacks.memo_stretch

// Make printing work properly in the memo menu
// Also changes the position of the right column in the withdrawing menu to be 4 pixels more to the right
org $8048B98; bl extra_hacks.memo_printfix_storage; nop; nop; nop
org $8049298; bl extra_hacks.memo_printfix_withdraw_positionfix; nop; nop
org $80492A4; bl extra_hacks.memo_printfix_vertical

// Expand buffer size for a memo page
org $804807A; bl extra_hacks.memo_expand_buffer_start_routine
org $80480DA; bl extra_hacks.memo_expand_buffer_middle_routine
org $80480F0; bl extra_hacks.memo_expand_buffer_end_routine
org $80488BE; bl extra_hacks.memo_expand_writing_buffer
org $8048C34; bl extra_hacks.memo_expand_writing_buffer
org $8048100; dw $4284
org $80476BC; dd $0201A2AC

// Make memo use strings terminated by 0xFFFFFFFF after every BREAK
org $80488F9; db $49; nop
org $8048904; bl extra_hacks.memo_eos

// Make the pigmask not set the null memo flag
//org $9369245; db $00

// Fix the memo lookup table, now it's bigger!
org $9FAA9F0; incbin data_memo_flags.bin
org $8052AF0; dd $09FAA9F0 //Table's beginning
org $8052AF4; dd $09FAAA96 //Table's second pointer, A6 bytes after the beginning
org $8052AF8; dd $09FAAB3A //Table's third pointer, 14A bytes after the beginning
org $804EF30; dd $09FAAB3A //Same thing as before

org $8052ADA; db $52 //Increments the number of loaded memos, so the last one is loaded too

//============================================================================================
//                                   DELETE ALL SAVES FIXING
//============================================================================================

//Hacks for the lag in the delete all saves screen

org $80479DE; bl fix_lag_delete_all.add_extra_vram
org $8045D5C; bl fix_lag_delete_all.change_background_priority_remove_oam
org $804E7A4; bl fix_lag_delete_all.hide_background //Remove the window when "No" is pressed
org $804E67A; bl fix_lag_delete_all.hide_background //Remove the window when "Yes" is pressed

org $8044BAE; mov r0,#2 //Make it so the "Chapter" text has priority 2
org $80448C4; bl fix_lag_delete_all.change_level_priority

org $80427F8; bl fix_lag_delete_all.change_bg1_coords; bne $804280A
org $803DDA0; mov r0,#4; nop  //Remove the window at startup
org $8046780; bl fix_lag_delete_all.remove_starting_cursor //Remove cursor at startup
org $804CA42; bl fix_lag_delete_all.hack //Set it back once we can read the input

//============================================================================================
//                                   SUMMARY FIXING
//============================================================================================

//OAM hacks for the summary

//Set/Reset the flag, so everything works
org $804A2EA; bl naming_screen_hacks.flag_reset

//Stop the refreshing of the OAM if the flag is set
org $803E6F0; bl naming_screen_hacks.impede_refresh_oam

//If you want to use OAM for the entries below instead, comment them.
//Also remember to uncomment the "Is this okay? Yes No" line in
//the NAMING SCREEN HACKS section (the one for 8042EFC)

//Remove the OAM entry for Favorite Food. Use graphics
org $8042DDC; mov r1,#1; neg r1,r1; mov r9,r1; add r2,#0x14; b $8042DFF

//Remove the OAM entry for Favorite Thing. Use graphics
org $8042E2E; add r2,#0x14; b $8042E4B

//Remove the OAM entry for Text Speed. Use graphics
org $8042E76; b $8042E93

//Improve performances: use graphics for "Is This Okay? Yes No"
//org $8042EEC; bl naming_screen_hacks.change_is_this_okay; b $8042F17

//============================================================================================
//                                   8 LETTERS FAKE NAMES
//============================================================================================

//Makes it so Lucky's name can be properly matched if 8 letters long
org $802164A; mov r2,#8; bl main_script_hacks.compare_strings_edited

//Makes it so Violet's name can be properly matched if 8 letters long
org $8021676; mov r2,#8; bl main_script_hacks.compare_strings_edited

//============================================================================================
//                                    NEW HACK CODE
//============================================================================================

// Clear out data for our hacks first
org $8124C18
fill $179C0

// Now insert the hack code
org $8124C18
incsrc general_hacks.asm
incsrc main_script_hacks.asm
incsrc main_menu_hacks.asm
incsrc sprite_text_hacks.asm
incsrc naming_screen_hacks.asm
incsrc outside_hacks.asm
incsrc extra_hacks.asm
incsrc battle_hacks.asm
incsrc credits_hacks.asm

// Insert disclaimer graphics
//disclaimer_graphics:
//incbin ./gráficos/gfx_disclaimer.bin

//disclaimer_palette:
//incbin ./gráficos/gfx_disclaimer_pal.bin

org $904E0E8; dd $F8F234
org $9FDCC00; incbin ./gráficos/gfx_theater_arrangement_[c].bin
org $8DEE9F8; incbin ./gráficos/gfx_titiboo_sign_[c].bin
org $8E24C70; incbin ./gráficos/gfx_club_titiboo_sign_[c].bin
org $8D4FFC8; incbin ./gráficos/gfx_titiboo_rug_[c].bin
org $9C70DA4; incbin ./gráficos/gfx_titiboo_credits.bin
org $8D44A84; incbin ./gráficos/gfx_dcmc_posters_[c].bin
org $9FDD500; incbin ./gráficos/gfx_highway_sign_[c].bin
org $8D3D924; dd $12A2020

print "End of Current Hacks: ",pc
print "Max:                  0x813C743"
