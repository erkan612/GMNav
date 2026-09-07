layout = gmnav_layout_create(gmnav_layout.ISO_DIAMOND, 64, 32);
grid   = gmnav_grid_create(20, 20, layout);
demo5_build_level(grid);
gmnav_grid_set_layer_lift(grid, DEMO5_LIFT);

// iso cells run off to the left, so shift the whole map into view
layout.origin_x = room_width * 0.5;
layout.origin_y = 60;

sched = gmnav_scheduler_create(grid, 3000);

var _s = demo5_screen(grid, 3, 4, 0);
agent = gmnav_agent_create(sched, _s[0], _s[1], 7, 2.2);

// which surface a click means. The framework will not guess, so the demo
// decides, and this key is that decision made visible
pick_mode = demo5_pick.TOPMOST; // -1 topmost, 0 ground only, 1 bridges only

show_path = true;
failed    = false;

col_ground = #4E7A38;
col_grass  = #6FA24A;
col_wall   = #6B5540;
col_road   = #5A5248;
col_deck   = #9A7B4F;
col_deck_hi = #B08F5C;
col_post   = #6E5738;