layout = gmnav_layout_create(gmnav_layout.ISO_DIAMOND, 64, 32);
grid   = gmnav_grid_create(DEMO6_W, DEMO6_H, layout);
demo6_build_level(grid);
gmnav_grid_set_layer_lift(grid, DEMO6_LIFT);

layout.origin_x = room_width * 0.5;
layout.origin_y = 40;

sched = gmnav_scheduler_create(grid, 3000);

var _s = gmnav_grid_node_to_world(grid, gmnav_grid_node(grid, 3, 20));
agent  = gmnav_agent_create(sched, _s[0], _s[1], 7, 2.4);

pick_mode = demo5_pick.TOPMOST;
show_path = true;
failed    = false;

ramps = demo6_ramps();

col_grass   = #6FA24A;
col_stone   = #8A8478;
col_water   = #387AB0;
col_deck    = #9A7B4F;
col_deck_l  = #6E5738;
col_deck_r  = #55432B;
col_rock    = #7A7268;
col_rock_hi = #8F8779;
col_rock_l  = #4E4840;
col_rock_r  = #3C3832;
col_ramp    = #7E6542;
col_ramp_hi = #A88656;