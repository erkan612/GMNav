if (keyboard_check_pressed(ord("P"))) show_path  = !show_path;
if (keyboard_check_pressed(ord("C"))) show_clear = !show_clear;

// the toll is a weight change, so both agents notice on their next request
if (keyboard_check_pressed(vk_space)) {
    tolled = !tolled;

    small.profile = tolled ? prof_toll : prof_free;
    big.profile   = tolled ? prof_toll : prof_free;

    gmnav_agent_goto(small, small.goal_x, small.goal_y);
    gmnav_agent_goto(big,   big.goal_x,   big.goal_y);
}

// collapse a deck cell under whichever agent is on it, which is the repath case
if (keyboard_check_pressed(ord("B"))) {
    var _ov = grid.overlay;
    var _dn = demo10_deck_at(grid, 10, DEMO10_WALL_R);

    if (_dn != GMNAV_NO_NODE) {
        gmnav_overlay_set_blocked(_ov, _dn, !gmnav_overlay_is_blocked(_ov, _dn));
        gmnav_overlay_finish(_ov);
    }
}

if (mouse_check_button_pressed(mb_left)) {
    var _n = gmnav_grid_world_to_node_top(grid, mouse_x, mouse_y);

    if (_n == GMNAV_NO_NODE || gmnav_grid_is_blocked(grid, _n)) {
        small.failed = true;
        big.failed   = true;
    } else {
        goal_c = gmnav_grid_col(grid, _n);
        goal_r = gmnav_grid_row(grid, _n);

        var _gl = gmnav_grid_node_layer(grid, _n);
        var _gp = gmnav_grid_node_to_world(grid, _n);

        gmnav_agent_goto(small, _gp[0], _gp[1], gmnav_priority.NORMAL, _gl);
        gmnav_agent_goto(big,   _gp[0], _gp[1], gmnav_priority.NORMAL, _gl);
    }
}

gmnav_scheduler_update(sched);

gmnav_agent_update(small);
small.x += small.vx;
small.y += small.vy;

gmnav_agent_update(big);
big.x += big.vx;
big.y += big.vy;