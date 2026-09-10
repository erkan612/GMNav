/*
nothing fancy, just improving debug rendering. i'd push it toward 
something that would be a replacement as 'level' rendering but 
its none of the framework's work. its best as keep the debug module 
as to show 'what does framework know' to help diagnose issues.
*/

grid   = demo14_make_grid();
layout = grid.layout;
sched  = gmnav_scheduler_create(grid, 600); // small, so the frontier view has time to show

danger = gmnav_costlayer_create(grid, "danger");
gmnav_costlayer_stamp_radial(danger, 20 * 32 + 200, 16 * 32 + 200, 150, 9, 2);
gmnav_costlayer_stamp_path(danger, [[5 * 32 + 200, 4 * 32 + 200],
                                    [12 * 32 + 200, 4 * 32 + 200]], 56, 7, 1);

profile = gmnav_costprofile_create(grid, "unit");
gmnav_costprofile_add(profile, danger, 1);
gmnav_costprofile_bake(profile);

field = gmnav_flowfield_create(grid, profile);
gmnav_flowfield_build(field, gmnav_grid_node(grid, 25, 19));

var _sp = gmnav_grid_node_to_world(grid, gmnav_grid_node(grid, 2, 6));
agent = gmnav_agent_create(sched, _sp[0], _sp[1], 8, 2);
agent.profile = profile;

// a second search driven by hand, purely so the frontier view has something in flight to draw. Nothing else in the demo uses it
probe = gmnav_search_create(grid);
probe_on = false;

view_mode = 0;
cfg = gmnav_debug_config();

demo14_send(id, 25, 19);