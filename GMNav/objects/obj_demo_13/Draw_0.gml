var _t = DEMO13_TILE;

for (var _r = 0; _r < DEMO13_H; _r++) {
    for (var _c = 0; _c < DEMO13_W; _c++) {
        var _n = gmnav_grid_node(grid, _c, _r);
        var _x = _c * _t;
        var _y = _r * _t;

        draw_set_color(gmnav_grid_is_blocked(grid, _n) ? col_wall : col_floor);
        draw_rectangle(_x, _y, _x + _t - 1, _y + _t - 1, false);

        if (show_cost) {
            var _v = gmnav_costlayer_get(danger, _c, _r);
            if (_v > 0) {
                draw_set_alpha(min(0.65, _v / 8));
                draw_set_color(#C03030);
                draw_rectangle(_x, _y, _x + _t - 1, _y + _t - 1, false);
                draw_set_alpha(1);
            }
        }

        draw_set_color(col_edge);
        draw_rectangle(_x, _y, _x + _t - 1, _y + _t - 1, true);
    }
}

// the lane the guard patrols
draw_set_alpha(0.25);
draw_set_color(col_guard);
draw_line_width(DEMO13_LANE_C * _t + _t * 0.5, DEMO13_LANE_R1 * _t,
                DEMO13_LANE_C * _t + _t * 0.5, DEMO13_LANE_R2 * _t + _t, 2);
draw_set_alpha(1);

var _gp = gmnav_grid_node_to_world(grid, gmnav_grid_node(grid, goal_c, goal_r));
draw_set_color(col_goal);
draw_circle(_gp[0], _gp[1], 9, false);

if (agent.path != undefined && agent.path.count > 1) {
    draw_set_color(col_agent);
    for (var i = 0; i < agent.path.count - 1; i++) {
        draw_line_width(agent.path.px[i], agent.path.py[i],
                        agent.path.px[i + 1], agent.path.py[i + 1], 2);
    }
}

var _g = demo13_lane_at(g_row);
draw_set_color(col_guard);
draw_circle(_g[0], _g[1], 10, false);
draw_set_color(#7A2A2A);
draw_circle(_g[0], _g[1], 10, true);

draw_set_color(col_agent);
draw_circle(agent.x, agent.y, 8, false);

if (brute.path != undefined && brute.path.count > 1) {
    draw_set_color(col_brute);
    for (var b = 0; b < brute.path.count - 1; b++) {
        draw_line_width(brute.path.px[b], brute.path.py[b],
                        brute.path.px[b + 1], brute.path.py[b + 1], 2);
    }
}

draw_set_color(col_brute);
draw_circle(brute.x, brute.y, 8, false);

draw_set_color(c_white);
draw_set_alpha(1);