grid   = demo15_make_grid();
layout = grid.layout;
sched  = gmnav_scheduler_create(grid, 3000);

agents = [];

for (var i = 0; i < DEMO15_N; i++) {
    var _sp = demo15_spawn_pos(i);
    var _a  = gmnav_agent_create(sched, _sp[0], _sp[1], 8, 1.8);

    _a.avoid_str   = 1.0;
    _a.avoid_range = 3.0;

    _a.follow_gap   = 2.8;
    _a.follow_min   = 1.1;
    _a.follow_sep   = 0.01;
    _a.follow_floor = 0.01;

    array_push(agents, _a);
}

mode         = 2; // 0 BASIC, 1 CONTEXT, 2 FOLLOW
mode_changed = 0;

// where the last click sent them. used by the R key and the panel
click_x = -1;
click_y = -1;

frames     = 0;
arrived_at = -1; // frame the last wave fully arrived, or -1

cfg = gmnav_debug_config();
cfg.cull  = false;
cfg.alpha = 0.4;

show_paths = true;
show_grid  = false;

demo15_apply_mode(id);