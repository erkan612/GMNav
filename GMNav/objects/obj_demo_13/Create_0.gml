/*
this is my favourite scenario to explain costfields!
imagine a monster and hero fighting, our hero is losing and is on low hp
makes a fire spell to cast fire between him and monster
monster is weak to fire!
but fire doesnt cover long distance, what our monster needs to calculate
is; should i go through fire to land the last hit on the hero, or 
should i go around the fire? this is a pure calculation that 
depends on how much the monster is weak to that fire, its health and 
is it worth taking the risk? brute_w value can be calculated by 
including all those parameters and more depending on the scenario! this is pure gradient!!
*/

grid   = demo13_make_grid();
layout = grid.layout;
sched  = gmnav_scheduler_create(grid, 3000);

danger  = gmnav_costlayer_create(grid, "guard"); // layer
profile = gmnav_costprofile_create(grid, "traveller");
gmnav_costprofile_add(profile, danger, 1);
gmnav_costprofile_bake(profile);

// the same fire, weighed differently. zero is blind, which is not the same as brave.
// a small weight is what makes it take the cheap detour and accept the  expensive one.
brute_w  = 0.25;
reckless = gmnav_costprofile_create(grid, "reckless");
gmnav_costprofile_add(reckless, danger, brute_w);
gmnav_costprofile_bake(reckless);

var _rp = gmnav_grid_node_to_world(grid, gmnav_grid_node(grid, 2, 13));
brute = gmnav_agent_create(sched, _rp[0], _rp[1], 7, 1.8);
brute.profile = reckless;

col_brute = #C8196A;

g_row   = DEMO13_LANE_R1;
g_dir   = 1;
g_speed = 0.06;
look    = 6; // how far ahead the guard's route is treated as dangerous
loop    = false;

stamp_rect  = [0, 0, -1, -1];
baked_cells = 0;

var _sp = gmnav_grid_node_to_world(grid, gmnav_grid_node(grid, 2, 10));
agent = gmnav_agent_create(sched, _sp[0], _sp[1], 7, 1.8);
agent.profile = profile;

goal_c = 27;
goal_r = 10;

show_danger = true;
show_cost = true;
repath_gap_frames = 20;
frames = 0;

col_floor = #3E4A55;
col_wall  = #212A33;
col_edge  = #4C5A67;
col_goal  = #E0B84A;
col_agent = #E8C46A;
col_guard = #D9605A;

gmnav_agent_goto(agent, _sp[0] + 0, _sp[1] + 0);
demo13_send_agent(id);