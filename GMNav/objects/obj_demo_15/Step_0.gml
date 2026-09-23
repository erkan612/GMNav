// input
if (mouse_check_button_pressed(mb_left)) {
    var _n = gmnav_grid_world_to_node_top(grid, mouse_x, mouse_y);

    if (_n != GMNAV_NO_NODE && !gmnav_grid_is_blocked(grid, _n)) {
        click_x    = mouse_x;
        click_y    = mouse_y;
        arrived_at = -1;

        demo15_send_all_to(id, click_x, click_y, 40);
    }
}

if (keyboard_check_pressed(ord("B"))) {
    mode = (mode + 1) mod 3;

    demo15_apply_mode(id);
    mode_changed = frames;
}

if (keyboard_check_pressed(ord("R"))) {
    demo15_reset(id);

    click_x    = -1;
    click_y    = -1;
    arrived_at = -1;
    frames     = 0;
}

if (keyboard_check_pressed(ord("P"))) show_paths = !show_paths;
if (keyboard_check_pressed(ord("G"))) show_grid  = !show_grid;

// update
gmnav_scheduler_update(sched);

var _n = array_length(agents);

for (var i = 0; i < _n; i++) {
    var _a = agents[i];

    gmnav_agent_update(_a, agents);
    demo15_move(grid, _a);
}

frames++;

if (arrived_at < 0 && click_x >= 0) { // one-shot arrival latch. fires once per wave
    if (demo15_count_arrived(id) == _n) arrived_at = frames;
}