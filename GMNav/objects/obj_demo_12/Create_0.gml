grid   = demo12_make_grid();
layout = grid.layout;
sched  = gmnav_scheduler_create(grid, 3000);

var _sp = gmnav_grid_node_to_world(grid,
              gmnav_grid_node(grid, DEMO12_START_C, DEMO12_START_R));

// one grid and one scheduler, since the curve is a property of the path rather
// than of the search. all three ask for the same route and shape it differently
agent_sharp  = gmnav_agent_create(sched, _sp[0], _sp[1], 7, 2.2);
agent_corner = gmnav_agent_create(sched, _sp[0], _sp[1], 7, 2.2);
agent_spline = gmnav_agent_create(sched, _sp[0], _sp[1], 7, 2.2);

agent_sharp.curve_mode  = gmnav_curve.NONE;

agent_corner.curve_mode   = gmnav_curve.CORNER;
agent_corner.curve_radius = 40;
agent_corner.curve_steps  = 5;

agent_spline.curve_mode   = gmnav_curve.SPLINE;
agent_spline.curve_radius = 40;
agent_spline.curve_steps  = 5;

goal_c = DEMO12_GOAL_C;
goal_r = DEMO12_GOAL_R;

radius = 40;
steps  = 5;

show_paths  = true;
show_points = false;

col_floor = #3E4A55;
col_wall  = #212A33;
col_edge  = #4C5A67;
col_goal  = #E0B84A;

col_sharp  = #E8C46A;
col_corner = #5FB4E0;
col_spline = #D9605A;

demo12_send(id, goal_c, goal_r);