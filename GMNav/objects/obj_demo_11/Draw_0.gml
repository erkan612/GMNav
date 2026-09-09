var _t = DEMO11_TILE;

for (var _r = 0; _r < DEMO11_H; _r++) {
    for (var _c = 0; _c < DEMO11_W; _c++) {
        var _n = gmnav_grid_node(grid_free, _c, _r);
        var _x = _c * _t;
        var _y = _r * _t;

        draw_set_color(gmnav_grid_is_blocked(grid_free, _n) ? col_wall : col_floor);
        draw_rectangle(_x, _y, _x + _t - 1, _y + _t - 1, false);

        draw_set_color(col_edge);
        draw_rectangle(_x, _y, _x + _t - 1, _y + _t - 1, true);
    }
}

var _gp = gmnav_grid_node_to_world(grid_free, gmnav_grid_node(grid_free, goal_c, goal_r));
draw_set_color(col_goal);
draw_circle(_gp[0], _gp[1], 9, false);
draw_set_color(#8A6E20);
draw_circle(_gp[0], _gp[1], 9, true);

if (show_paths) {
    demo11_draw_path(agent_free, col_free);
    demo11_draw_path(agent_oct,  col_oct);
    demo11_draw_path(agent_four, col_four);
}

draw_set_color(col_free);
draw_circle(agent_free.x, agent_free.y, 9, false);
draw_set_color(col_oct);
draw_circle(agent_oct.x, agent_oct.y, 6, false);
draw_set_color(col_four);
draw_circle(agent_four.x, agent_four.y, 3, false);

if (show_grid) gmnav_debug_draw_grid(grid_free);

draw_set_color(c_white);
draw_set_alpha(1);