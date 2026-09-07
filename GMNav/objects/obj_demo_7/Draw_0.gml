var _tw = DEMO7_TILE_W;
var _th = DEMO7_TILE_H;
var _hw = _tw * 0.5;
var _hh = _th * 0.5;

var _items = [];

for (var _r = 0; _r < DEMO7_H; _r++) {
    for (var _c = 0; _c < DEMO7_W; _c++) {
        var _n = gmnav_grid_node(grid, _c, _r);

        var _k = 0;                                       // grass
        if (_r >= DEMO7_RIVER_R1 && _r <= DEMO7_RIVER_R2
        &&  _c > 0 && _c < DEMO7_W - 1) _k = 1;           // water
        else if (gmnav_grid_is_blocked(grid, _n)) _k = 2; // solid

        array_push(_items, [demo7_depth(_r, 0), _k, _c, _r, 0]);
    }
}

for (var _l = 1; _l <= grid.overlay.max_layer; _l++) {
    for (var _r = 0; _r < DEMO7_H; _r++) {
        for (var _c = 0; _c < DEMO7_W; _c++) {
            if (demo7_deck_at(grid, _c, _r, _l) == GMNAV_NO_NODE) continue;

            array_push(_items, [demo7_depth(_r, _l), 3, _c, _r, _l]);

            // the front face hangs into the row below, so it sorts there
            if (demo7_face_open(grid, _c, _r, _l)) {
                array_push(_items, [demo7_depth(_r + 1, 0) + 1, 4, _c, _r, _l]);
            }
        }
    }
}

var _rmp = demo7_ramps();
for (var i = 0; i < array_length(_rmp); i++) {
    var _rp = _rmp[i];
    var _lo = (_rp[2] < _rp[5]) ? 0 : 3;
    array_push(_items, [demo7_depth(_rp[_lo + 1], _rp[_lo + 2]) + 2, 5, i, 0, 0]);
}

var _al = gmnav_agent_layer(agent);
var _an = gmnav_grid_world_to_node(grid, agent.x, agent.y, _al);
array_push(_items, [demo7_depth(gmnav_grid_row(grid, _an), _al) + 3, 6, 0, 0, _al]);

array_sort(_items, function(_a, _b) { return sign(_a[0] - _b[0]); });

for (var i = 0; i < array_length(_items); i++) {
    var _it = _items[i];
    var _c = _it[2], _r = _it[3], _l = _it[4];

    if (_it[1] == 5) {
        var _rp = _rmp[_c];
        var _a  = demo7_screen(grid, _rp[0], _rp[1], _rp[2]);
        var _b  = demo7_screen(grid, _rp[3], _rp[4], _rp[5]);

        draw_set_color(col_ramp);
        draw_primitive_begin(pr_trianglelist);
        draw_vertex(_a[0] - _hw * 0.7, _a[1]);
        draw_vertex(_a[0] + _hw * 0.7, _a[1]);
        draw_vertex(_b[0] + _hw * 0.7, _b[1]);
        draw_vertex(_a[0] - _hw * 0.7, _a[1]);
        draw_vertex(_b[0] + _hw * 0.7, _b[1]);
        draw_vertex(_b[0] - _hw * 0.7, _b[1]);
        draw_primitive_end();
        continue;
    }

    if (_it[1] == 6) {
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

    var _p  = demo7_screen(grid, _c, _r, _l);
    var _px = _p[0] - _hw;
    var _py = _p[1] - _hh;

    switch (_it[1]) {
        case 0:
            draw_set_color(col_grass);
            draw_rectangle(_px, _py, _px + _tw - 1, _py + _th - 1, false);
            break;

        case 1:
            draw_set_color(col_water);
            draw_rectangle(_px, _py, _px + _tw - 1, _py + _th - 1, false);
            break;

        case 2:
            draw_set_color(col_rock_f);
            draw_rectangle(_px, _py, _px + _tw - 1, _py + _th - 1, false);
            break;

        case 3:
            var _dk = demo7_is_deck(_c, _r, _l);

            if (_dk) {
                draw_set_color(col_post);
                draw_line_width(_px + 5,       _py + _th,
                                _px + 5,       _py + _th + DEMO7_LIFT, 3);
                draw_line_width(_px + _tw - 5, _py + _th,
                                _px + _tw - 5, _py + _th + DEMO7_LIFT, 3);
            }

            draw_set_color(_dk ? col_deck : ((_l == 2) ? col_peak : col_rock));
            draw_rectangle(_px, _py, _px + _tw - 1, _py + _th - 1, false);
            break;

        case 4:
            // the front face, filling the gap the lift opened
            var _dp = demo7_drop(grid, _c, _r, _l);
            draw_set_color(demo7_is_deck(_c, _r, _l) ? col_deck_f : col_rock_f);
            draw_rectangle(_px, _py + _th, _px + _tw - 1, _py + _th + _dp - 1, false);
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