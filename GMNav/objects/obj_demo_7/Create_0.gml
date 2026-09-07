grid   = demo7_make_grid();
layout = grid.layout;
sched  = gmnav_scheduler_create(grid, 3000);

var _s = gmnav_grid_node_to_world(grid, gmnav_grid_node(grid, 20, 18));
agent  = gmnav_agent_create(sched, _s[0], _s[1], 7, 2.2);

pick_mode = 0;                    // 0 topmost, 1 ground, 2 raised
show_path = true;
failed    = false;

col_grass  = #6FA24A;
col_water  = #387AB0;
col_rock   = #7A7268;
col_rock_f = #4E4840;
col_peak   = #8F8779;
col_deck   = #9A7B4F;
col_deck_f = #6E5738;
col_post   = #55432B;
col_ramp   = #A88656;