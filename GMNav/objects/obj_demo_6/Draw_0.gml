var _t = layout.tile_w;
var _u = layout.tile_h;
var _items = [];

// VISUAL HELL, CANT GET OUT OF IT!@@!!!!!!!!!!!!!!!!!!!

// ground, flat diamonds only
for (var _r = 0; _r < DEMO6_H; _r++) {
    for (var _c = 0; _c < DEMO6_W; _c++) {
        var _k = demo6_is_river(_c) ? 1 : 0;
        if (_k == 0 && gmnav_grid_is_blocked(grid, gmnav_grid_node(grid, _c, _r))) _k = 2;

        array_push(_items, [demo6_depth(_c, _r, 0), _k, _c, _r, 0]);
    }
}

// raised surfaces
for (var _l = 1; _l <= grid.overlay.max_layer; _l++) {
    for (var _r = 0; _r < DEMO6_H; _r++) {
        for (var _c = 0; _c < DEMO6_W; _c++) {
            if (demo6_deck_at(grid, _c, _r, _l) == GMNAV_NO_NODE) continue;
            array_push(_items, [demo6_depth(_c, _r, _l), 3, _c, _r, _l]);

            if (!demo6_is_deck(_c, _r, _l)) {
                array_push(_items, [demo6_depth(_c, _r + 1, 0) + 1, 7, _c, _r, _l]);
            }
        }
    }
}

// ramps, sorted by their LOWER end so they never paint over the deck
var _ramps = demo6_ramps();
for (var i = 0; i < array_length(_ramps); i++) {
    var _rp = _ramps[i];
    var _lo = (_rp[2] < _rp[5]) ? 0 : 3;
    var _d  = demo6_depth(_rp[_lo], _rp[_lo + 1], _rp[_lo + 2]);

    array_push(_items, [_d + 2, 4, i, 0, 0]);
}

var _al = gmnav_agent_layer(agent);
var _an = gmnav_grid_world_to_node(grid, agent.x, agent.y, _al);
array_push(_items, [demo6_depth(gmnav_grid_col(grid, _an),
                                gmnav_grid_row(grid, _an), _al) + 2, 5, 0, 0, _al]);

array_sort(_items, function(_a, _b) { return sign(_a[0] - _b[0]); });

for (var i = 0; i < array_length(_items); i++) {
    var _it = _items[i];
    var _c = _it[2], _r = _it[3], _l = _it[4];

    if (_it[1] == 4) {
        var _rp = _ramps[_c];
        var _a  = demo6_screen(grid, _rp[0], _rp[1], _rp[2]);
        var _b  = demo6_screen(grid, _rp[3], _rp[4], _rp[5]);

        // width perpendiccular to the ramp, not a fixed horizontal offset
        var _dx = _b[0] - _a[0];
        var _dy = _b[1] - _a[1];
        var _ln = max(1, point_distance(0, 0, _dx, _dy));
        var _nx = -_dy / _ln * 15;
        var _ny =  _dx / _ln * 15;

        demo6_quad(_a[0] + _nx, _a[1] + _ny, _b[0] + _nx, _b[1] + _ny,
                   _b[0] - _nx, _b[1] - _ny, _a[0] - _nx, _a[1] - _ny, col_ramp);
        demo6_quad(_a[0] + _nx * 0.72, _a[1] + _ny * 0.72 - 3,
                   _b[0] + _nx * 0.72, _b[1] + _ny * 0.72 - 3,
                   _b[0] - _nx * 0.72, _b[1] - _ny * 0.72 - 3,
                   _a[0] - _nx * 0.72, _a[1] - _ny * 0.72 - 3, col_ramp_hi);
        continue;
    }

    if (_it[1] == 5) {
        draw_set_alpha(0.3);
        draw_set_color(c_black);
        draw_ellipse(agent.x - 9, agent.y - 4, agent.x + 9, agent.y + 4, false);
        draw_set_alpha(1);

        draw_set_color(#F2D268);
        draw_circle(agent.x, agent.y - 9, agent.radius, false);
        draw_set_color(#7A5F1E);
        draw_circle(agent.x, agent.y - 9, agent.radius, true);
        continue;
    }

    var _p = demo6_screen(grid, _c, _r, _l);
    var _px = _p[0], _py = _p[1];
    var _hw = _t * 0.5, _hh = _u * 0.5;

    switch (_it[1]) {
        case 0: demo6_diamond(_px, _py, _t, _u, col_grass); break;

        case 1:
            demo6_diamond(_px, _py + 7, _t, _u, col_water);
            demo6_diamond(_px, _py + 7, _t * 0.5, _u * 0.5,
                          merge_color(col_water, c_white, 0.15));
            break;

        case 2: demo6_diamond(_px, _py, _t, _u, col_stone); break;

        case 3:
            var _dk = demo6_is_deck(_c, _r, _l);

            if (_dk) {
                draw_set_color(col_deck_r);
                draw_line_width(_px - _t * 0.22, _py + _u * 0.4,
                                _px - _t * 0.22, _py + DEMO6_LIFT + _u * 0.4, 3);
                draw_line_width(_px + _t * 0.22, _py + _u * 0.4,
                                _px + _t * 0.22, _py + DEMO6_LIFT + _u * 0.4, 3);
            }

            demo6_diamond(_px, _py, _t, _u,
                          _dk ? col_deck : ((_l == 2) ? col_rock_hi : col_rock));
            break;

        case 7:
            demo6_skirt(_px, _py, _t, _u, demo6_drop_to(grid, _c, _r, _l),
                        demo6_open_sw(grid, _c, _r, _l),
                        demo6_open_se(grid, _c, _r, _l),
                        col_rock_l, col_rock_r);
            break;
    }
}

if (show_path && gmnav_agent_has_path(agent)) {
    draw_set_color(#5FC8F0);
    for (var i = 1; i < agent.path.count; i++) {
        draw_line_width(agent.path.px[i - 1], agent.path.py[i - 1],
                        agent.path.px[i],     agent.path.py[i], 2);
    }
}

draw_set_color(c_white);
draw_set_alpha(1);