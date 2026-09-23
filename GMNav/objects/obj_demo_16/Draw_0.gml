// crowd layer overlay
if (show_layer) {
    for (var _r = 0; _r < DEMO16_H; _r++) {
        for (var _c = 0; _c < DEMO16_W; _c++) {
            var _n = gmnav_grid_node(grid, _c, _r);
            if (_n == GMNAV_NO_NODE) continue;
            if (gmnav_grid_is_blocked(grid, _n)) continue;

            var _v = gmnav_costlayer_get_node(crowd_layer, _n);
            if (_v <= 0) continue;

            var _t  = clamp(_v / DEMO16_DANGER, 0, 1);
            var _cx = gmnav_layout_cell_x(layout, _c, _r);
            var _cy = gmnav_layout_cell_y(layout, _c, _r);

            draw_set_alpha(0.5 * (0.3 + 0.7 * _t));
            draw_set_color(merge_color(#C03030, #F08050, _t));
            draw_rectangle(_cx - DEMO16_TILE * 0.5, _cy - DEMO16_TILE * 0.5,
                           _cx + DEMO16_TILE * 0.5 - 1,
                           _cy + DEMO16_TILE * 0.5 - 1, false);
        }
    }
    draw_set_alpha(1);
}

// danger spots
for (var i = 0; i < array_length(danger_cells); i++) {
    var _dp = gmnav_grid_node_to_world(grid, danger_cells[i]);

    draw_set_color(#F04040);
    draw_circle(_dp[0], _dp[1], 12, true);
    draw_circle(_dp[0], _dp[1], 6,  true);
}

// walls
draw_set_color(#4E4840);
for (var _r = 0; _r < DEMO16_H; _r++) {
    for (var _c = 0; _c < DEMO16_W; _c++) {
        if (!gmnav_grid_is_blocked(grid, gmnav_grid_node(grid, _c, _r))) continue;

        var _cx = gmnav_layout_cell_x(layout, _c, _r);
        var _cy = gmnav_layout_cell_y(layout, _c, _r);

        draw_rectangle(_cx - DEMO16_TILE * 0.5, _cy - DEMO16_TILE * 0.5,
                       _cx + DEMO16_TILE * 0.5 - 1,
                       _cy + DEMO16_TILE * 0.5 - 1, false);
    }
}

// gate highlights
var _gates = [[6, 7], [9, 10]];
var _gc    = [ #A0D0FF, #E0B84A ];

for (var i = 0; i < 2; i++) {
    var _g = _gates[i];
    var _cl = _gc[i];

    for (var _r = _g[0]; _r <= _g[1]; _r++) {
        for (var _c = 12; _c <= 13; _c++) {
            var _cx = gmnav_layout_cell_x(layout, _c, _r);
            var _cy = gmnav_layout_cell_y(layout, _c, _r);

            draw_set_alpha(0.2);
            draw_set_color(_cl);
            draw_rectangle(_cx - DEMO16_TILE * 0.5, _cy - DEMO16_TILE * 0.5,
                           _cx + DEMO16_TILE * 0.5 - 1,
                           _cy + DEMO16_TILE * 0.5 - 1, false);
        }
    }
}
draw_set_alpha(1);

// paths
if (show_paths) {
    draw_set_alpha(0.3);
    draw_set_color(#4A9BE0);

    var _n = array_length(agents);

    for (var i = 0; i < _n; i++) {
        var _a = agents[i];
        if (!gmnav_agent_has_path(_a)) continue;

        for (var j = 1; j < _a.path.count; j++) {
            draw_line(_a.path.px[j - 1], _a.path.py[j - 1],
                      _a.path.px[j],     _a.path.py[j]);
        }
    }
    draw_set_alpha(1);
}

// agents
var _n = array_length(agents);

for (var i = 0; i < _n; i++) {
    var _a = agents[i];

    // inner fill: urgency colour
    if      (_a.urgency < 0.33) draw_set_color(#5FC8F0);
    else if (_a.urgency > 0.66) draw_set_color(#E05A3C);
    else                        draw_set_color(#E0B84A);

    draw_circle(_a.x, _a.y, _a.radius - 2, false);

    // outer ring: side colour
    draw_set_color((demo16_agent_side(i) == 0) ? #E8C46A : #4AA0B0);
    draw_circle(_a.x, _a.y, _a.radius, true);
}

if (show_grid) gmnav_debug_draw_grid(grid, cfg);

draw_set_color(c_white);
draw_set_alpha(1);