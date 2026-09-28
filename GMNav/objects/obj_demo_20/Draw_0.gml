draw_set_color(#1A1A22);
draw_rectangle(0, 0, room_width, room_height, false);

// base grid
for (var _r = 0; _r < grid.height; _r++) {
    for (var _c = 0; _c < grid.width; _c++) {
        var _n = gmnav_grid_node(grid, _c, _r);

        var _px = _c * DEMO20_TILE;
        var _py = _r * DEMO20_TILE;

        var _is_river = (_c >= DEMO20_RIVER_C1 && _c <= DEMO20_RIVER_C2
                      && _r > 0 && _r < grid.height - 1);

        if (gmnav_grid_is_blocked(grid, _n)) {
            draw_set_color(_is_river ? col_river : col_wall);
        } else {
            draw_set_color(col_floor);
        }
        draw_rectangle(_px, _py, _px + DEMO20_TILE - 1, _py + DEMO20_TILE - 1, false);
    }
}

// overlay cells
if (gmnav_grid_has_overlay(grid)) {
    var _ov = grid.overlay;

    for (var _i = 0; _i < gmnav_overlay_count(_ov); _i++) {
        var _node = _ov.base + _i;

        var _oc = gmnav_grid_col(grid, _node);
        var _orr = gmnav_grid_row(grid, _node);

        var _px = _oc * DEMO20_TILE;
        var _py = _orr * DEMO20_TILE;

        if (gmnav_overlay_is_removed(_ov, _node)) {
            draw_set_color(col_deck_rm);
            draw_rectangle(_px + 4, _py + 4,
                           _px + DEMO20_TILE - 5, _py + DEMO20_TILE - 5, false);
            draw_set_color(#E05A3C);
            draw_rectangle(_px + 4, _py + 4,
                           _px + DEMO20_TILE - 5, _py + DEMO20_TILE - 5, true);
        } else {
            draw_set_color(col_deck);
            draw_rectangle(_px + 2, _py + 2,
                           _px + DEMO20_TILE - 3, _py + DEMO20_TILE - 3, false);
        }
    }
}

if (show_grid) gmnav_debug_draw_grid(grid, cfg);

demo20_draw_path(agent, col_path);

// agent
draw_set_color(col_agent);
draw_circle(agent.x, agent.y, agent.radius, false);

// goal
var _gn = gmnav_grid_world_to_node_top(grid, goal_x, goal_y);
if (_gn != GMNAV_NO_NODE) {
    var _gp = gmnav_grid_node_to_world(grid, _gn);
    draw_set_color(col_goal);
    draw_circle(_gp[0], _gp[1], 6, false);
    draw_set_color(#2E4A6A);
    draw_circle(_gp[0], _gp[1], 6, true);
}

draw_set_color(c_white);
draw_set_alpha(1);