// input
if (keyboard_check_pressed(ord("H"))) {
    urgency_base = min(1.0, urgency_base + 0.25);
    demo16_apply_urgency(id);
}

if (keyboard_check_pressed(ord("L"))) {
    urgency_base = max(0.0, urgency_base - 0.25);
    demo16_apply_urgency(id);
}

if (keyboard_check_pressed(ord("B"))) {
    avoid_mode_idx = (avoid_mode_idx + 1) mod 3;
    demo16_apply_avoid(id);
}

if (keyboard_check_pressed(ord("K"))) {
    avoid_on = !avoid_on;
    demo16_apply_avoid(id);
}

if (keyboard_check_pressed(ord("D"))) {
    var _dn = gmnav_util_cursor_node(grid, 0);

    if (_dn != GMNAV_NO_NODE) array_push(danger_cells, _dn);
}

if (keyboard_check_pressed(ord("X"))) {
    danger_cells = [];
}

if (keyboard_check_pressed(ord("R"))) {
    danger_cells = [];
    stamp_rect   = [0, 0, -1, -1];
    arrivals_total = 0;
    frames       = 0;

    gmnav_costlayer_clear(crowd_layer);
    gmnav_costprofile_bake(prof_patient);
    gmnav_costprofile_bake(prof_normal);
    gmnav_costprofile_bake(prof_rush);

    demo16_reset_all(id);
}

if (keyboard_check_pressed(ord("P"))) show_paths = !show_paths;
if (keyboard_check_pressed(ord("V"))) show_layer = !show_layer;
if (keyboard_check_pressed(ord("G"))) show_grid  = !show_grid;

// update
gmnav_scheduler_update(sched);

var _n = array_length(agents);

for (var i = 0; i < _n; i++) {
    gmnav_agent_update(agents[i], agents);
    demo16_move(grid, agents[i]);
}

// respawn on arrival
for (var i = 0; i < _n; i++) {
    var _a = agents[i];

    if (!gmnav_agent_arrived(_a)) continue;

    var _sc = demo16_spawn_cell(i);
    var _sp = demo16_world_of_cell(grid, _sc);

    gmnav_util_reset_agent(_a, grid, _sp[0], _sp[1]);

    _a.urgency = clamp(urgency_base + random_range(-0.35, 0.35), 0, 1);
    demo16_send(id, i);

    arrivals_total++;
}

// periodic rebuild and re-path
if (frames mod DEMO16_REPATH == 0) {
    demo16_rebuild_crowd(id);

    var _limit = DEMO16_HERE * 2;

    for (var i = 0; i < _n; i++) {
        var _a = agents[i];
        if (!_a.has_goal) continue;

        _a.profile = demo16_urgency_profile(id, _a);

        if (demo16_path_is_crowded(_a, crowd_layer, _limit)) {
            gmnav_agent_goto(_a, _a.goal_x, _a.goal_y,
                             gmnav_priority.NORMAL, _a.goal_layer);
        }
    }
}

frames++;