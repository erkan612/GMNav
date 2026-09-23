// floor
draw_set_color(#2E3A2E);
draw_rectangle(0, 0, DEMO15_W * DEMO15_TILE - 1, DEMO15_H * DEMO15_TILE - 1, false);

// walls
draw_set_color(#4E4840);
for (var _r = 0; _r < DEMO15_H; _r++) {
    for (var _c = 0; _c < DEMO15_W; _c++) {
        if (!gmnav_grid_is_blocked(grid, gmnav_grid_node(grid, _c, _r))) continue;

        draw_rectangle(_c * DEMO15_TILE, _r * DEMO15_TILE,
                       _c * DEMO15_TILE + DEMO15_TILE - 1,
                       _r * DEMO15_TILE + DEMO15_TILE - 1, false);
    }
}

// passage highlights so the door widths are readable at a glance
var _doors = [
    [DEMO15_WALL_A, 9,  12, #A0D0FF],
    [DEMO15_WALL_B, 10, 10, #E05A3C],
    [DEMO15_WALL_C, 9,  10, #E0B84A],
    [DEMO15_WALL_D, 7,  11, #60C075]
];

for (var i = 0; i < 4; i++) {
    var _d  = _doors[i];
    var _dx = _d[0] * DEMO15_TILE;
    var _dy = _d[1] * DEMO15_TILE;
    var _dh = (_d[2] - _d[1] + 1) * DEMO15_TILE;

    draw_set_alpha(0.25);
    draw_set_color(_d[3]);
    draw_rectangle(_dx, _dy, _dx + DEMO15_TILE - 1, _dy + _dh - 1, false);
}
draw_set_alpha(1);

// click target marker
if (click_x >= 0) {
    draw_set_color(#F2D268);
    draw_circle(click_x, click_y, 8, true);
    draw_circle(click_x, click_y, 4, false);
}

// paths
if (show_paths) {
    draw_set_alpha(0.35);
    draw_set_color(#4A9BE0);

    for (var i = 0; i < array_length(agents); i++) {
        var _a = agents[i];
        if (!gmnav_agent_has_path(_a)) continue;

        for (var j = 1; j < _a.path.count; j++) {
            draw_line(_a.path.px[j - 1], _a.path.py[j - 1],
                      _a.path.px[j],     _a.path.py[j]);
        }
    }
    draw_set_alpha(1);
}

// agents. colour by mode so the crowd's mode is visible without the panel
var _mode_cols = [ #E0B84A, #5FC8F0, #60C075 ];
var _n = array_length(agents);

for (var i = 0; i < _n; i++) {
    var _a = agents[i];

    if (gmnav_agent_arrived(_a)) {
        draw_set_color(#75C060);
        draw_circle(_a.x, _a.y, _a.radius, true);
    } else {
        draw_set_color(_mode_cols[mode]);
        draw_circle(_a.x, _a.y, _a.radius, false);
    }
}

if (show_grid) gmnav_debug_draw_grid(grid, cfg);

draw_set_color(c_white);
draw_set_alpha(1);