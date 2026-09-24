// background
draw_set_color(#101418);
draw_rectangle(0, 0, TROOP_ROOM_W, TROOP_MAP_H, false);

// map
// floor
draw_set_color(#2A3A2A);
for (var _r = 0; _r < TROOP_H; _r++) {
    for (var _c = 0; _c < TROOP_W; _c++) {
        var _n = gmnav_grid_node(grid, _c, _r);
        if (gmnav_grid_is_blocked(grid, _n)) continue;

        var _cx = gmnav_layout_cell_x(layout, _c, _r);
        var _cy = gmnav_layout_cell_y(layout, _c, _r);

        draw_rectangle(_cx - TROOP_TILE * 0.5, _cy - TROOP_TILE * 0.5,
                       _cx + TROOP_TILE * 0.5 - 1, _cy + TROOP_TILE * 0.5 - 1, false);
    }
}

// river
draw_set_color(#1A2E48);
for (var _r = 0; _r < TROOP_H; _r++) {
    if (_r == 9 || _r == 10) continue;

    for (var _c = 20; _c <= 21; _c++) {
        var _cx = gmnav_layout_cell_x(layout, _c, _r);
        var _cy = gmnav_layout_cell_y(layout, _c, _r);

        draw_rectangle(_cx - TROOP_TILE * 0.5, _cy - TROOP_TILE * 0.5,
                       _cx + TROOP_TILE * 0.5 - 1, _cy + TROOP_TILE * 0.5 - 1, false);
    }
}

// bridge
draw_set_color(#7A5A3A);
for (var _r = 9; _r <= 10; _r++) {
    for (var _c = 20; _c <= 21; _c++) {
        var _cx = gmnav_layout_cell_x(layout, _c, _r);
        var _cy = gmnav_layout_cell_y(layout, _c, _r);

        draw_rectangle(_cx - TROOP_TILE * 0.5, _cy - TROOP_TILE * 0.5,
                       _cx + TROOP_TILE * 0.5 - 1, _cy + TROOP_TILE * 0.5 - 1, false);
    }
}

// buildings
draw_set_color(#4A423A);
for (var _r = 0; _r < TROOP_H; _r++) {
    for (var _c = 0; _c < TROOP_W; _c++) {
        var _n = gmnav_grid_node(grid, _c, _r);
        if (_n == GMNAV_NO_NODE) continue;
        if (!gmnav_grid_is_blocked(grid, _n)) continue;
        if ((_c == 20 || _c == 21) && _r != 0 && _r != TROOP_H - 1
        && _r != 9 && _r != 10) continue; // river handled above
        if (_c == 0 || _c == TROOP_W - 1) continue;
        if (_r == 0 || _r == TROOP_H - 1) continue;

        var _cx = gmnav_layout_cell_x(layout, _c, _r);
        var _cy = gmnav_layout_cell_y(layout, _c, _r);

        draw_rectangle(_cx - TROOP_TILE * 0.5, _cy - TROOP_TILE * 0.5,
                       _cx + TROOP_TILE * 0.5 - 1, _cy + TROOP_TILE * 0.5 - 1, false);
    }
}

// cost layer
if (show_cost) {
    for (var _r = 0; _r < TROOP_H; _r++) {
        for (var _c = 0; _c < TROOP_W; _c++) {
            var _n = gmnav_grid_node(grid, _c, _r);
            if (gmnav_grid_is_blocked(grid, _n)) continue;

            var _v = gmnav_costlayer_get_node(crowd_layer, _n);
            if (_v <= 0) continue;

            var _cx = gmnav_layout_cell_x(layout, _c, _r);
            var _cy = gmnav_layout_cell_y(layout, _c, _r);

            draw_set_alpha(0.45);
            draw_set_color(#C03030);
            draw_rectangle(_cx - TROOP_TILE * 0.5, _cy - TROOP_TILE * 0.5,
                           _cx + TROOP_TILE * 0.5 - 1, _cy + TROOP_TILE * 0.5 - 1, false);
        }
    }
    draw_set_alpha(1);
}

// paths
if (show_paths) {
    draw_set_alpha(0.35);
    draw_set_color(#4A9BE0);

    for (var i = 0; i < array_length(units); i++) {
        var _u = units[i];
        if (!_u.selected) continue;
        if (!gmnav_agent_has_path(_u.ag)) continue;

        for (var j = 1; j < _u.ag.path.count; j++) {
            draw_line(_u.ag.path.px[j - 1], _u.ag.path.py[j - 1],
                      _u.ag.path.px[j],     _u.ag.path.py[j]);
        }
    }
    draw_set_alpha(1);
}

// formation flash
for (var i = 0; i < array_length(formation_flash); i++) {
    var _f = formation_flash[i];
    var _t = _f.ttl / 36;

    draw_set_alpha(0.7 * _t);
    draw_set_color(#40FF80);
    draw_circle(_f.x, _f.y, 6 + (1 - _t) * 10, true);
}
draw_set_alpha(1);

// units
for (var i = 0; i < array_length(units); i++) {
    var _u = units[i];
    var _a = _u.ag;

    var _body = (_u.type == TROOP_TYPE_SCOUT) ? #E8C46A : #5FB4E0;
    var _line = (_u.type == TROOP_TYPE_SCOUT) ? #7A5F1E : #2E4A6A;

    // body
    draw_set_color(_body);
    draw_circle(_a.x, _a.y, _a.radius, false);
    draw_set_color(_line);
    draw_circle(_a.x, _a.y, _a.radius, true);

    // facing, a simple triangle
    var _fx = _a.x + lengthdir_x(_a.radius * 1.15, _u.facing);
    var _fy = _a.y + lengthdir_y(_a.radius * 1.15, _u.facing);
    var _lx = _a.x + lengthdir_x(_a.radius * 0.75, _u.facing + 140);
    var _ly = _a.y + lengthdir_y(_a.radius * 0.75, _u.facing + 140);
    var _rx = _a.x + lengthdir_x(_a.radius * 0.75, _u.facing - 140);
    var _ry = _a.y + lengthdir_y(_a.radius * 0.75, _u.facing - 140);

    draw_set_color(_line);
    draw_triangle(_fx, _fy, _lx, _ly, _rx, _ry, false);

    // hover ring
    if (_u == hover_unit && !_u.selected) {
        draw_set_alpha(0.6);
        draw_set_color(c_white);
        draw_circle(_a.x, _a.y, _a.radius + 3, true);
        draw_set_alpha(1);
    }

    // selection ring
    if (_u.selected) {
        draw_set_alpha(0.9);
        draw_set_color(#FFD040);
        draw_circle(_a.x, _a.y, _a.radius + 4, true);
        draw_set_alpha(1);
    }
}

// marquee
if (marquee_active) {
    var _x1 = min(marquee_x1, marquee_x2);
    var _y1 = min(marquee_y1, marquee_y2);
    var _x2 = max(marquee_x1, marquee_x2);
    var _y2 = max(marquee_y1, marquee_y2);

    draw_set_alpha(0.15);
    draw_set_color(#40FF80);
    draw_rectangle(_x1, _y1, _x2, _y2, false);

    draw_set_alpha(0.8);
    draw_rectangle(_x1, _y1, _x2, _y2, true);
    draw_set_alpha(1);
}

draw_set_color(c_white);
draw_set_alpha(1);