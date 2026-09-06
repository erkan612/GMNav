tile = 32;

layout = gmnav_layout_create(gmnav_layout.ORTHO, tile, tile);
grid   = gmnav_grid_create(room_width div tile, room_height div tile, layout);
demo4_build_level(grid);

sched = gmnav_scheduler_create(grid, 3000);

preset = 2; // climb 1, drop 1
var _p = demo4_preset(preset);

agent = gmnav_agent_create(sched, 3 * tile + 16, (grid.height div 2) * tile + 16, 8, 2.5);
agent.max_climb = _p.climb;
agent.max_drop  = _p.drop;

cfg = gmnav_debug_config();
cfg.cull  = false;
cfg.alpha = 0.35;

show_heights = true;
show_steps   = true;
show_path    = true;
show_labels  = false;

last_cost = 0;
failed    = false;