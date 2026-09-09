// one level, three grids. the neighbour set is a property of the grid, so an
// agent that may only walk cardinals needs a grid searched that way. constraining
// smoothing alone would leave the diagonal steps A* already put in the path
grid_free = demo11_make_grid(gmnav_neighbours.EIGHT);
grid_four = demo11_make_grid(gmnav_neighbours.FOUR);
grid_oct  = demo11_make_grid(gmnav_neighbours.EIGHT);

layout = grid_free.layout;

sched_free = gmnav_scheduler_create(grid_free, 3000);
sched_four = gmnav_scheduler_create(grid_four, 3000);
sched_oct  = gmnav_scheduler_create(grid_oct,  3000);

var _sp = gmnav_grid_node_to_world(grid_free,
              gmnav_grid_node(grid_free, DEMO11_START_C, DEMO11_START_R));

agent_free = gmnav_agent_create(sched_free, _sp[0], _sp[1], 7, 2.0);
agent_four = gmnav_agent_create(sched_four, _sp[0], _sp[1], 7, 2.0);
agent_oct  = gmnav_agent_create(sched_oct,  _sp[0], _sp[1], 7, 2.0);

agent_free.headings = 0;   // any angle the corridor allows
agent_four.headings = 4;   // up, down, left, right
agent_oct.headings  = 8;   // and the four diagonals

goal_c = DEMO11_GOAL_C;
goal_r = DEMO11_GOAL_R;

show_paths = true;
show_grid  = false;

col_floor = #3E4A55;
col_wall  = #212A33;
col_edge  = #4C5A67;
col_goal  = #E0B84A;

col_free = #E8C46A;
col_four = #5FB4E0;
col_oct  = #D9605A;

demo11_send(id, goal_c, goal_r);