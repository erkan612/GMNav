tile = 32;

layout = gmnav_layout_create(gmnav_layout.ORTHO, tile, tile);
grid   = gmnav_grid_create(room_width div tile, room_height div tile, layout);
demo2_build_walls(grid);

budget = 1500;
sched  = gmnav_scheduler_create(grid, budget, 4);

// agents are plain structs, so no second object is needed
agents      = [];
avoid_cell = 32;
avoid_cols = ceil(room_width  / avoid_cell);
avoid_rows = ceil(room_height / avoid_cell);
near_buf   = [];
use_avoid  = true;

// live readout of how long the last order took to drain
order_frames = 0;
last_drain   = -1;
draining     = false;

cfg = gmnav_debug_config();
cfg.cull  = false;
cfg.alpha = 0.3;

show_grid  = true;
show_paths = false;

// start with a modest crowd
repeat (20) {
    var _p = demo2_random_open(grid);
    if (_p == undefined) continue;

    var _a = gmnav_agent_create(sched, _p.x, _p.y, 9, random_range(1.8, 3.0));
    _a.avoid_str = 1.0;
    array_push(agents, _a);
}