var _tw = DEMO10_TILE_W;
var _th = DEMO10_TILE_H;
var _hw = _tw * 0.5;
var _hh = _th * 0.5;

var _items = [];

for (var _r = 0; _r < DEMO10_H; _r++) {
    for (var _c = 0; _c < DEMO10_W; _c++) {
        var _n = gmnav_grid_node(grid, _c, _r);
        var _k = gmnav_grid_is_blocked(grid, _n) ? 1 : 0;

        array_push(_items, [demo10_depth(_r, 0), _k, _c, _r]);
    }
}

for (var _r2 = 0; _r2 < DEMO10_H; _r2++) {
    for (var _c2 = 0; _c2 < DEMO10_W; _c2++) {
        var _dn = demo10_deck_at(grid, _c2, _r2);
        if (_dn == GMNAV_NO_NODE) continue;

        array_push(_items, [demo10_depth(_r2, gmt_node_height(grid, _dn)), 2, _c2, _r2]);
    }
}

array_push(_items, [demo10_agent_depth(grid, small), 3, 0, 0]);
array_push(_items, [demo10_agent_depth(grid, big),   3, 1, 0]);

array_sort(_items, function(_a, _b) { return sign(_a[0] - _b[0]); });

for (var i = 0; i < array_length(_items); i++) {
    var _it = _items[i];
    var _c = _it[2], _r = _it[3];

    if (_it[1] == 3) {
        var _ag = (_c == 0) ? small : big;
        var _cl = (_c == 0) ? col_small : col_big;
        var _rd = (_c == 0) ? 8 : 20;

        draw_set_alpha(0.28);
        draw_set_color(c_black);
        draw_ellipse(_ag.x - _rd, _ag.y - _rd * 0.45,
                     _ag.x + _rd, _ag.y + _rd * 0.45, false);
        draw_set_alpha(1);

        draw_set_color(_cl);
        draw_circle(_ag.x, _ag.y - _rd * 0.5, _rd * 0.8, false);
        draw_set_color(#3A2E1C);
        draw_circle(_ag.x, _ag.y - _rd * 0.5, _rd * 0.8, true);
        continue;
    }

    var _cx = gmnav_layout_cell_x(layout, _c, _r);
    var _cy = gmnav_layout_cell_y(layout, _c, _r);
    var _px = _cx - _hw;
    var _py = _cy - _hh;

    if (_it[1] == 2) {
        var _n2  = demo10_deck_at(grid, _c, _r);
        var _h   = gmt_node_height(grid, _n2);

        var _nn = demo10_deck_at(grid, _c, _r - 1);
        var _sn = demo10_deck_at(grid, _c, _r + 1);
        var _wn = demo10_deck_at(grid, _c - 1, _r);
        var _en = demo10_deck_at(grid, _c + 1, _r);

        var _hn  = (_nn == GMNAV_NO_NODE) ? _h : gmt_node_height(grid, _nn);
        var _hs  = (_sn == GMNAV_NO_NODE) ? _h : gmt_node_height(grid, _sn);
        var _hw2 = (_wn == GMNAV_NO_NODE) ? _h : gmt_node_height(grid, _wn);
        var _he  = (_en == GMNAV_NO_NODE) ? _h : gmt_node_height(grid, _en);

        var _cnw = (_h + _hn + _hw2) / 3;
        var _cne = (_h + _hn + _he)  / 3;
        var _csw = (_h + _hs + _hw2) / 3;
        var _cse = (_h + _hs + _he)  / 3;

        var _x1 = _px, _x2 = _px + _tw - 1;
        var _yn = _py, _ys = _py + _th - 1;

        var _ramp = (gmnav_overlay_offset(grid.overlay, _n2) != 0);
        var _out  = gmnav_overlay_is_blocked(grid.overlay, _n2);

        draw_set_color(col_post);
        draw_rectangle(_x1 + 3, _ys - _csw * DEMO10_LIFT, _x1 + 6, _ys, false);
        draw_rectangle(_x2 - 6, _ys - _cse * DEMO10_LIFT, _x2 - 3, _ys, false);

        draw_set_color(col_face);
        draw_primitive_begin(pr_trianglelist);
        draw_vertex(_x1, _ys - _csw * DEMO10_LIFT);
        draw_vertex(_x2, _ys - _cse * DEMO10_LIFT);
        draw_vertex(_x2, _ys);
        draw_vertex(_x1, _ys - _csw * DEMO10_LIFT);
        draw_vertex(_x2, _ys);
        draw_vertex(_x1, _ys);
        draw_primitive_end();

        draw_set_color(_out ? #6A3030 : (_ramp ? col_ramp : col_deck));
        draw_primitive_begin(pr_trianglelist);
        draw_vertex(_x1, _yn - _cnw * DEMO10_LIFT);
        draw_vertex(_x2, _yn - _cne * DEMO10_LIFT);
        draw_vertex(_x2, _ys - _cse * DEMO10_LIFT);
        draw_vertex(_x1, _yn - _cnw * DEMO10_LIFT);
        draw_vertex(_x2, _ys - _cse * DEMO10_LIFT);
        draw_vertex(_x1, _ys - _csw * DEMO10_LIFT);
        draw_primitive_end();

        if (tolled) {
            draw_set_alpha(0.35);
            draw_set_color(#C03030);
            draw_primitive_begin(pr_trianglelist);
            draw_vertex(_x1, _yn - _cnw * DEMO10_LIFT);
            draw_vertex(_x2, _yn - _cne * DEMO10_LIFT);
            draw_vertex(_x2, _ys - _cse * DEMO10_LIFT);
            draw_vertex(_x1, _yn - _cnw * DEMO10_LIFT);
            draw_vertex(_x2, _ys - _cse * DEMO10_LIFT);
            draw_vertex(_x1, _ys - _csw * DEMO10_LIFT);
            draw_primitive_end();
            draw_set_alpha(1);
        }

        draw_set_color(#B08F5C);
        draw_line(_x1, _yn - _cnw * DEMO10_LIFT, _x2, _yn - _cne * DEMO10_LIFT);

        if (show_clear) {
            draw_set_color(c_white);
            draw_text(_cx - 3, _cy - _h * DEMO10_LIFT - 6,
                      string(gmnav_clearance_at(grid, _n2)));
        }
        continue;
    }

    if (_it[1] == 1) {
        draw_set_color(col_wall);
        draw_rectangle(_px, _py, _px + _tw - 1, _py + _th - 1, false);
        continue;
    }

    draw_set_color(col_grass);
    draw_rectangle(_px, _py, _px + _tw - 1, _py + _th - 1, false);
    draw_set_color(#5C8A3C);
    draw_rectangle(_px, _py, _px + _tw - 1, _py + _th - 1, true);

    if (_c == goal_c && _r == goal_r) {
        draw_set_color(col_goal);
        draw_circle(_cx, _cy, 8, false);
        draw_set_color(#8A6E20);
        draw_circle(_cx, _cy, 8, true);
    }

    if (show_clear) {
        draw_set_color(c_white);
        draw_text(_cx - 3, _cy - 6,
                  string(gmnav_clearance_at(grid, gmnav_grid_node(grid, _c, _r))));
    }
}

if (show_path) {
    demo10_draw_path(small, col_small);
    demo10_draw_path(big,   col_big);
}

draw_set_color(c_white);
draw_set_alpha(1);