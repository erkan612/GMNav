var _tw = DEMO8_TILE_W;
var _th = DEMO8_TILE_H;
var _hw = _tw * 0.5;
var _hh = _th * 0.5;

var _items = [];

for (var _r = 0; _r < DEMO8_H; _r++) {
    for (var _c = 0; _c < DEMO8_W; _c++) {
        var _n = gmnav_grid_node(grid, _c, _r);
        array_push(_items, [demo8_depth(_r, 0),
                            gmnav_grid_is_blocked(grid, _n) ? 1 : 0, _c, _r]);
    }
}

for (var _r = 0; _r < DEMO8_H; _r++) {
    for (var _c = 0; _c < DEMO8_W; _c++) {
        var _n = demo8_deck_at(grid, _c, _r);
        if (_n == GMNAV_NO_NODE) continue;

        array_push(_items, [demo8_depth(_r, demo8_height(grid, _n)), 2, _c, _r]);
    }
}

var _al = gmnav_agent_layer(agent);
var _an = gmnav_grid_world_to_node(grid, agent.x, agent.y, _al);
array_push(_items, [demo8_depth(gmnav_grid_row(grid, _an),
                                demo8_height(grid, _an)) + 8, 3, 0, 0]);

array_sort(_items, function(_a, _b) { return sign(_a[0] - _b[0]); });

for (var i = 0; i < array_length(_items); i++) {
    var _it = _items[i];
    var _c = _it[2], _r = _it[3];

    if (_it[1] == 3) {
        draw_set_alpha(0.3);
        draw_set_color(c_black);
        draw_ellipse(agent.x - 8, agent.y - 3, agent.x + 8, agent.y + 3, false);
        draw_set_alpha(1);

        draw_set_color(#F2D268);
        draw_circle(agent.x, agent.y - 8, agent.radius, false);
        draw_set_color(#7A5F1E);
        draw_circle(agent.x, agent.y - 8, agent.radius, true);
        continue;
    }

    if (_it[1] < 2) {
        var _p  = demo8_at(grid, _c, _r, 0);
        var _px = _p[0] - _hw;
        var _py = _p[1] - _hh;

        draw_set_color((_it[1] == 1) ? col_wall : col_grass);
        draw_rectangle(_px, _py, _px + _tw - 1, _py + _th - 1, false);
        continue;
    }

    var _n  = demo8_deck_at(grid, _c, _r);
    var _h  = demo8_height(grid, _n);
    var _nn = demo8_deck_at(grid, _c, _r - 1);
    var _sn = demo8_deck_at(grid, _c, _r + 1);
    var _wn = demo8_deck_at(grid, _c - 1, _r);
    var _en = demo8_deck_at(grid, _c + 1, _r);

    var _hn = (_nn == GMNAV_NO_NODE) ? _h : demo8_height(grid, _nn);
    var _hs = (_sn == GMNAV_NO_NODE) ? _h : demo8_height(grid, _sn);
    var _hw2 = (_wn == GMNAV_NO_NODE) ? _h : demo8_height(grid, _wn);
    var _he = (_en == GMNAV_NO_NODE) ? _h : demo8_height(grid, _en);

    // corner heights, averaged from the cell and the two neighbours meeting there
    var _nw = (_h + _hn + _hw2) / 3;
    var _ne = (_h + _hn + _he)  / 3;
    var _sw = (_h + _hs + _hw2) / 3;
    var _se = (_h + _hs + _he)  / 3;

    var _cx = gmnav_layout_cell_x(grid.layout, _c, _r);
    var _cy = gmnav_layout_cell_y(grid.layout, _c, _r);

    var _x1 = _cx - _hw, _x2 = _cx + _hw;
    var _yn = _cy - _hh, _ys = _cy + _hh;

    var _ramp = demo8_is_ramp(grid, _n);

    // the face, from the southern edge down to the ground
    if (_sn == GMNAV_NO_NODE || _hs < _h - 0.001) {
        var _drop = (_sn == GMNAV_NO_NODE) ? _h : (_h - _hs);

        draw_set_color(_ramp ? col_rface : col_face);
        draw_primitive_begin(pr_trianglelist);
        draw_vertex(_x1, _ys - _sw * DEMO8_LIFT);
        draw_vertex(_x2, _ys - _se * DEMO8_LIFT);
        draw_vertex(_x2, _ys - (_se - _drop) * DEMO8_LIFT);
        draw_vertex(_x1, _ys - _sw * DEMO8_LIFT);
        draw_vertex(_x2, _ys - (_se - _drop) * DEMO8_LIFT);
        draw_vertex(_x1, _ys - (_sw - _drop) * DEMO8_LIFT);
        draw_primitive_end();
    }

    // the top, as a quad with four independent corner heights
    draw_set_color(_ramp ? col_ramp : col_top);
    draw_primitive_begin(pr_trianglelist);
    draw_vertex(_x1, _yn - _nw * DEMO8_LIFT);
    draw_vertex(_x2, _yn - _ne * DEMO8_LIFT);
    draw_vertex(_x2, _ys - _se * DEMO8_LIFT);
    draw_vertex(_x1, _yn - _nw * DEMO8_LIFT);
    draw_vertex(_x2, _ys - _se * DEMO8_LIFT);
    draw_vertex(_x1, _ys - _sw * DEMO8_LIFT);
    draw_primitive_end();
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