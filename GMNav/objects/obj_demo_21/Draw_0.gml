draw_set_color(#1A1A22);
draw_rectangle(0, 0, room_width, room_height, false);

// base grid
for (var _r = 0; _r < grid.height; _r++) {
    for (var _c = 0; _c < grid.width; _c++) {
        var _n = gmnav_grid_node(grid, _c, _r);

        var _p = gmnav_layout_cell_to_world(layout, _c, _r);
        var _px = _p[0] - DEMO21_TILE * 0.5;
        var _py = _p[1] - DEMO21_TILE * 0.5;

        draw_set_color(gmnav_grid_is_blocked(grid, _n) ? col_wall : col_floor);
        draw_rectangle(_px, _py, _px + DEMO21_TILE - 1, _py + DEMO21_TILE - 1, false);
    }
}

if (show_grid) gmnav_debug_draw_grid(grid, cfg);

// paths, drawn under the bodies
demo21_draw_path(agent_red,   col_red);
demo21_draw_path(agent_green, col_green);

// goals
var _gg = demo21_world_of(grid, green_goal_c, green_goal_r);
draw_set_color(col_goal);
draw_circle(_gg[0], _gg[1], 5, false);
draw_set_color(#2E4A6A);
draw_circle(_gg[0], _gg[1], 5, true);

var _rc = red_sealed ? 22 : 21;
var _rr = red_sealed ? 14 : 12;
var _rg = demo21_world_of(grid, _rc, _rr);
draw_set_color(#E05A3C);
draw_circle(_rg[0], _rg[1], 5, false);
draw_set_color(#7A2A2A);
draw_circle(_rg[0], _rg[1], 5, true);

// bodies
draw_set_color(col_red);
draw_circle(agent_red.x, agent_red.y, agent_red.radius, false);

draw_set_color(col_green);
draw_circle(agent_green.x, agent_green.y, agent_green.radius, false);

draw_set_color(c_white);
draw_set_alpha(1);