var _tw = DEMO9_TILE_W;
var _th = DEMO9_TILE_H;
var _hw = _tw * 0.5;
var _hh = _th * 0.5;

var _items = [];

for (var _r = 0; _r < DEMO9_H; _r++) {
    for (var _c = 0; _c < DEMO9_W; _c++) {
        var _n = gmnav_grid_node(grid, _c, _r);

        var _k = 0;
        if (demo9_is_chasm(_c) && _r > 0 && _r < DEMO9_H - 1) _k = 1;
        else if (gmnav_grid_is_blocked(grid, _n)) _k = 2;

        array_push(_items, [demo9_depth(_r, 0), _k, _c, _r]);
    }
}

for (var _r = 0; _r < DEMO9_H; _r++) {
    for (var _c = 0; _c < DEMO9_W; _c++) {
        var _dn = demo9_deck_at(grid, _c, _r);
        if (_dn == GMNAV_NO_NODE) continue;

        array_push(_items, [demo9_depth(_r, demo9_height(grid, _dn)), 3, _c, _r]);
    }
}

var _un = array_length(units);
for (var i = 0; i < _un; i++) {
    var _u  = units[i];
    var _un2 = gmnav_grid_world_to_node(grid, _u.x, _u.y, _u.layer);
    if (_un2 == GMNAV_NO_NODE) _un2 = _u.hold;

    var _ur = (_un2 == GMNAV_NO_NODE) ? 0 : gmnav_grid_row(grid, _un2);
    var _uh = demo9_height(grid, _un2);

    array_push(_items, [demo9_depth(_ur, _uh) + 8, 5, i, 0]);
}

array_sort(_items, function(_a, _b) { return sign(_a[0] - _b[0]); });

for (var i = 0; i < array_length(_items); i++) {
    var _it = _items[i];
    var _c = _it[2], _r = _it[3];

    if (_it[1] == 5) {
        var _u = units[_c];

        draw_set_alpha(0.28);
        draw_set_color(c_black);
        draw_ellipse(_u.x - 6, _u.y - 3, _u.x + 6, _u.y + 3, false);
        draw_set_alpha(1);

        draw_set_color(demo9_unit_colour(_u.hue));
        draw_circle(_u.x, _u.y - 7, 5, false);
        draw_set_color(#3A2E1C);
        draw_circle(_u.x, _u.y - 7, 5, true);
        continue;
    }

    var _cx = gmnav_layout_cell_x(grid.layout, _c, _r);
    var _cy = gmnav_layout_cell_y(grid.layout, _c, _r);
    var _px = _cx - _hw;
    var _py = _cy - _hh;

    if (_it[1] == 3) {
        var _n  = demo9_deck_at(grid, _c, _r);
        var _h  = demo9_height(grid, _n);

        var _nn = demo9_deck_at(grid, _c, _r - 1);
        var _sn = demo9_deck_at(grid, _c, _r + 1);
        var _wn = demo9_deck_at(grid, _c - 1, _r);
        var _en = demo9_deck_at(grid, _c + 1, _r);

        var _hn  = (_nn == GMNAV_NO_NODE) ? _h : demo9_height(grid, _nn);
        var _hs  = (_sn == GMNAV_NO_NODE) ? _h : demo9_height(grid, _sn);
        var _hw2 = (_wn == GMNAV_NO_NODE) ? _h : demo9_height(grid, _wn);
        var _he  = (_en == GMNAV_NO_NODE) ? _h : demo9_height(grid, _en);

        var _cnw = (_h + _hn + _hw2) / 3;
        var _cne = (_h + _hn + _he)  / 3;
        var _csw = (_h + _hs + _hw2) / 3;
        var _cse = (_h + _hs + _he)  / 3;

        var _x1 = _px, _x2 = _px + _tw - 1;
        var _yn = _py, _ys = _py + _th - 1;

        var _ramp = demo9_is_ramp(grid, _n);

        // posts, dropping to the ground below the southern corners
        draw_set_color(col_post);
        draw_rectangle(_x1 + 3, _ys - _csw * DEMO9_LIFT,
                       _x1 + 6, _ys, false);
        draw_rectangle(_x2 - 6, _ys - _cse * DEMO9_LIFT,
                       _x2 - 3, _ys, false);

        // the face, from the southern edge down to the ground
        draw_set_color(_ramp ? #5E4A2C : col_face);
        draw_primitive_begin(pr_trianglelist);
        draw_vertex(_x1, _ys - _csw * DEMO9_LIFT);
        draw_vertex(_x2, _ys - _cse * DEMO9_LIFT);
        draw_vertex(_x2, _ys);
        draw_vertex(_x1, _ys - _csw * DEMO9_LIFT);
        draw_vertex(_x2, _ys);
        draw_vertex(_x1, _ys);
        draw_primitive_end();

        // the top
        draw_set_color(_ramp ? col_ramp : col_deck);
        draw_primitive_begin(pr_trianglelist);
        draw_vertex(_x1, _yn - _cnw * DEMO9_LIFT);
        draw_vertex(_x2, _yn - _cne * DEMO9_LIFT);
        draw_vertex(_x2, _ys - _cse * DEMO9_LIFT);
        draw_vertex(_x1, _yn - _cnw * DEMO9_LIFT);
        draw_vertex(_x2, _ys - _cse * DEMO9_LIFT);
        draw_vertex(_x1, _ys - _csw * DEMO9_LIFT);
        draw_primitive_end();

        draw_set_color(#B08F5C);
        draw_line(_x1, _yn - _cnw * DEMO9_LIFT, _x2, _yn - _cne * DEMO9_LIFT);

        if (show_arrows) {
            demo9_draw_arrow(field, _n, _cx,
                             _cy - (_cnw + _cne + _csw + _cse) * 0.25 * DEMO9_LIFT,
                             #3A2E1C);
        }
        continue;
    }

    switch (_it[1]) {
        case 0:
            draw_set_color(col_grass);
            draw_rectangle(_px, _py, _px + _tw - 1, _py + _th - 1, false);

            draw_set_color(#5C8A3C);
            draw_rectangle(_px, _py, _px + _tw - 1, _py + _th - 1, true);

            if (show_arrows) demo9_draw_arrow(field, gmnav_grid_node(grid, _c, _r),
                                              _cx, _cy, #2E4A22);

            if (_c == goal_c && _r == goal_r) {
                draw_set_color(col_goal);
                draw_circle(_cx, _cy, 8, false);
                draw_set_color(#8A6E20);
                draw_circle(_cx, _cy, 8, true);
            }
            break;

        case 1:
            draw_set_color(col_void);
            draw_rectangle(_px, _py, _px + _tw - 1, _py + _th - 1, false);

            if (!demo9_is_chasm(_c - 1)) {
                draw_set_color(#15120F);
                draw_rectangle(_px, _py, _px + 4, _py + _th - 1, false);
            }
            if (!demo9_is_chasm(_c + 1)) {
                draw_set_color(#15120F);
                draw_rectangle(_px + _tw - 5, _py, _px + _tw - 1, _py + _th - 1, false);
            }
            if (_r == 1) {
                draw_set_color(#15120F);
                draw_rectangle(_px, _py, _px + _tw - 1, _py + 5, false);
            }
            break;

        case 2:
            draw_set_color(col_wall);
            draw_rectangle(_px, _py, _px + _tw - 1, _py + _th - 1, false);
            break;
    }
}

if (show_grid) gmnav_debug_draw_grid(grid);

draw_set_color(c_white);
draw_set_alpha(1);