grid   = demo8_make_grid();
layout = grid.layout;
sched  = gmnav_scheduler_create(grid, 3000);

var _s = gmnav_grid_node_to_world(grid, gmnav_grid_node(grid, 6, 4));
agent  = gmnav_agent_create(sched, _s[0], _s[1], 7, 2.4);

pick_mode = 0;
show_path = true;
failed    = false;

col_grass = #6FA24A;
col_wall  = #4E4840;
col_top   = #8F8779;
col_face  = #5E5A52;
col_ramp  = #A88656;
col_rface = #6E5738;