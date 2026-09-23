//draw_set_alpha(0.78);
//draw_set_color(c_black);
//draw_rectangle(8, 8, 320, 150, false);

//draw_set_alpha(1);
//draw_set_color(c_white);
//draw_text(20, 16, "GMNav Demo 2 - one budget, any crowd");
//draw_text(20, 40, "left click   send everyone to that spot");
//draw_text(20, 58, "S            scatter to random goals");
//draw_text(20, 76, "A / D        add or remove 20 agents");
//draw_text(20, 94, "Q / E        budget down or up");
//draw_text(20, 112, "P            toggle paths");
//draw_text(20, 130, "V / space    avoidance, grid");

//gmnav_debug_draw_stats(sched, 20, 172);

//draw_set_alpha(0.78);
//draw_set_color(c_black);
//draw_rectangle(8, 284, 320, 356, false);
//draw_set_alpha(1);

//draw_set_color(c_white);
//draw_text(20, 292, "agents      " + string(array_length(agents)));
//draw_text(20, 310, "avoidance   " + (use_avoid ? "on" : "off"));

//if (draining) {
//    draw_set_color(#4A9BE0);
//    draw_text(20, 330, "draining    " + string(order_frames) + " frames");
//} else if (last_drain >= 0) {
//    draw_set_color(#75C060);
//    draw_text(20, 330, "drained in  " + string(last_drain) + " frames");
//}

//draw_set_color(c_white);
//draw_set_alpha(1);

// diagnostic: find the first not-arrived agent that is not moving
var _stuck_i = -1;

for (var i = 0; i < array_length(agents); i++) {
    var _a = agents[i];
    if (gmnav_agent_arrived(_a)) continue;

    var _speed = point_distance(0, 0, _a.vx, _a.vy);
    if (_speed < 0.05) { _stuck_i = i; break; }
}

if (_stuck_i >= 0) {
    var _s = agents[_stuck_i];

    draw_set_alpha(0.85);
    draw_set_color(c_black);
    draw_rectangle(20, 200, 440, 380, false);
    draw_set_alpha(1);

    draw_set_color(#E0B84A);
    draw_text(30, 208, "stuck agent #" + string(_stuck_i));

    draw_set_color(c_white);
    draw_text(30, 228, "pos      " + string_format(_s.x, 1, 1) + ", " + string_format(_s.y, 1, 1));
    draw_text(30, 246, "vel      " + string_format(_s.vx, 1, 3) + ", " + string_format(_s.vy, 1, 3));
    draw_text(30, 264, "has path " + string(gmnav_agent_has_path(_s)));
    draw_text(30, 282, "arrived  " + string(gmnav_agent_arrived(_s)));
    draw_text(30, 300, "failed   " + string(gmnav_agent_failed(_s)));

    if (gmnav_agent_has_path(_s)) {
        draw_text(30, 318, "seek     " + string(_s.seek_i) + " / " + string(_s.path.count));

        if (_s.seek_i < _s.path.count) {
            var _tx = _s.path.px[_s.seek_i];
            var _ty = _s.path.py[_s.seek_i];
            var _d  = point_distance(_s.x, _s.y, _tx, _ty);

            draw_text(30, 336, "target   " + string_format(_tx, 1, 1) + ", " + string_format(_ty, 1, 1));
            draw_text(30, 354, "dist     " + string_format(_d, 1, 2) + "  reach " + string(_s.reach_dist));
        }
    }

    // is the agent's current position inside a wall?
    var _node = gmnav_grid_world_to_node(grid, _s.x, _s.y);
    draw_text(30, 372, "cell     " + string(_node) + "  blocked " + string(gmnav_grid_is_blocked(grid, _node)));
}