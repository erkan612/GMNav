var _t = DEMO12_TILE;

for (var _r = 0; _r < DEMO12_H; _r++) {
    for (var _c = 0; _c < DEMO12_W; _c++) {
        var _n = gmnav_grid_node(grid, _c, _r);
        var _x = _c * _t;
        var _y = _r * _t;

        draw_set_color(gmnav_grid_is_blocked(grid, _n) ? col_wall : col_floor);
        draw_rectangle(_x, _y, _x + _t - 1, _y + _t - 1, false);

        draw_set_color(col_edge);
        draw_rectangle(_x, _y, _x + _t - 1, _y + _t - 1, true);
    }
}

var _gp = gmnav_grid_node_to_world(grid, gmnav_grid_node(grid, goal_c, goal_r));
draw_set_color(col_goal);
draw_circle(_gp[0], _gp[1], 9, false);
draw_set_color(#8A6E20);
draw_circle(_gp[0], _gp[1], 9, true);

if (show_paths) {
    demo12_draw_path(agent_sharp,  col_sharp,  show_points);
    demo12_draw_path(agent_spline, col_spline, show_points);
    demo12_draw_path(agent_corner, col_corner, show_points);
}

draw_set_color(col_sharp);
draw_circle(agent_sharp.x, agent_sharp.y, 9, false);
draw_set_color(col_spline);
draw_circle(agent_spline.x, agent_spline.y, 6, false);
draw_set_color(col_corner);
draw_circle(agent_corner.x, agent_corner.y, 3, false);

draw_set_color(c_white);
draw_set_alpha(1);