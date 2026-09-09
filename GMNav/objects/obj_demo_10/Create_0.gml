grid   = demo10_make_grid();
layout = grid.layout;
sched  = gmnav_scheduler_create(grid, 3000);

// the toll is built once and switched by weight, so nothing rebakes on a keypress
toll = demo10_toll_layer(grid);

prof_free = gmnav_costprofile_create(grid, "free");
gmnav_costprofile_add(prof_free, toll, 0);
gmnav_costprofile_bake(prof_free);

prof_toll = gmnav_costprofile_create(grid, "tolled");
gmnav_costprofile_add(prof_toll, toll, 1);
gmnav_costprofile_bake(prof_toll);

tolled = false;

var _sp = gmnav_grid_node_to_world(grid, gmnav_grid_node(grid, 10, 3));

small = gmnav_agent_create(sched, _sp[0], _sp[1], 8, 2.0);
small.need_clear = gmnav_clearance_for_radius(grid, 8);
small.profile    = prof_free;

var _bp = gmnav_grid_node_to_world(grid, gmnav_grid_node(grid, 14, 3));

big = gmnav_agent_create(sched, _bp[0], _bp[1], 24, 1.6);
big.need_clear = gmnav_clearance_for_radius(grid, 24);
big.profile    = prof_free;

goal_c = 10;
goal_r = 19;

show_path  = true;
show_clear = false;

small_failed = false; big_failed = false;

col_grass = #6FA24A;
col_wall  = #4E4840;
col_deck  = #9A7B4F;
col_face  = #6E5738;
col_post  = #55432B;
col_ramp  = #A88656;
col_goal  = #E0B84A;
col_small = #E8C46A;
col_big   = #D9605A;