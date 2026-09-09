grid   = demo9_make_grid();
layout = grid.layout;

goal_c = 24;
goal_r = 10;

field = gmnav_flowfield_create(grid);
gmnav_flowfield_build(field, gmnav_grid_node(grid, goal_c, goal_r));

units = [];
repeat (60) demo9_spawn(grid, units);

show_arrows = true;
show_grid   = false;
paused      = false;

col_grass = #6FA24A;
col_void  = #24201C;
col_wall  = #4E4840;
col_deck  = #9A7B4F;
col_face  = #6E5738;
col_post  = #55432B;
col_ramp  = #A88656;
col_goal  = #E0B84A;