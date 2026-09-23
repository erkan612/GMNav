#macro DEMO17_W        26
#macro DEMO17_H        19
#macro DEMO17_TILE     32
#macro DEMO17_ORIGIN_X 440
#macro DEMO17_ORIGIN_Y 30

function demo17_build_level(_grid) {
    // border
    gmnav_grid_fill_blocked(_grid, 0, 0, DEMO17_W - 1, 0, true);
    gmnav_grid_fill_blocked(_grid, 0, 0, 0, DEMO17_H - 1, true);
    gmnav_grid_fill_blocked(_grid, DEMO17_W - 1, 0, DEMO17_W - 1, DEMO17_H - 1, true);

    // floor
    gmnav_grid_fill_blocked(_grid, 1, 16, DEMO17_W - 2, DEMO17_H - 1, true);

    // lower solids, three ledges with staggered gaps
    gmnav_grid_fill_blocked(_grid, 2,  13, 7,  13, true);
    gmnav_grid_fill_blocked(_grid, 12, 13, 16, 13, true);
    gmnav_grid_fill_blocked(_grid, 18, 13, 23, 13, true);

    // middle one-way, spans both lower gaps
    for (var _c = 5; _c <= 20; _c++) {
        gmnav_grid_set_flag(_grid, _c, 10, GMNAV_FLAG_ONEWAY, true);
    }

    // upper one-ways, split by a gap in the middle
    for (var _c = 3; _c <= 8; _c++) {
        gmnav_grid_set_flag(_grid, _c, 7, GMNAV_FLAG_ONEWAY, true);
    }
    for (var _c = 14; _c <= 19; _c++) {
        gmnav_grid_set_flag(_grid, _c, 7, GMNAV_FLAG_ONEWAY, true);
    }
}

function demo17_make_grid() {
    var _lay = gmnav_layout_create(gmnav_layout.ORTHO, DEMO17_TILE, DEMO17_TILE);

    _lay.origin_x = DEMO17_ORIGIN_X;
    _lay.origin_y = DEMO17_ORIGIN_Y;

    var _g = gmnav_grid_create(DEMO17_W, DEMO17_H, _lay);
    demo17_build_level(_g);
    return _g;
}

function demo17_movement() {
    // gravity, jump, run, max_fall, width, height, air, levels, bias, can_drop jump 11 gives a 126px peak rise on gravity 0.5, enough for a 96px tier
    return gmnav_movement_create(0.5, 11, 3, 9, 12, 24, 3.2, 5, 1.5, true);
}

function demo17_spawn_cell() {
    return [5, 6]; // standing on the left upper one-way
}

function demo17_spawn_node(_grid, _pg) {
    var _cell = demo17_spawn_cell();
    var _n    = gmnav_grid_node(_grid, _cell[0], _cell[1]);

    if (_n == GMNAV_NO_NODE) return GMNAV_NO_NODE;
    return _pg.node_of[_n];
}

function demo17_draw_level(_grid) {
    var _t = DEMO17_TILE;

    for (var _r = 0; _r < DEMO17_H; _r++) {
        for (var _c = 0; _c < DEMO17_W; _c++) {
            var _n  = gmnav_grid_node(_grid, _c, _r);
            var _ow = gmnav_grid_has_flag(_grid, _n, GMNAV_FLAG_ONEWAY);
            var _bl = gmnav_grid_is_blocked(_grid, _n);

            if (!_ow && !_bl) continue;

            var _cx = gmnav_layout_cell_x(_grid.layout, _c, _r);
            var _cy = gmnav_layout_cell_y(_grid.layout, _c, _r);
            var _x1 = _cx - _t * 0.5;
            var _y1 = _cy - _t * 0.5;

            if (_ow) {
                draw_set_color(#7A5AC0);
                draw_rectangle(_x1, _y1, _x1 + _t - 1, _y1 + 5, false);

                draw_set_color(#4A2E80);
                draw_rectangle(_x1, _y1 + 5, _x1 + _t - 1, _y1 + 6, false);
            } else {
                draw_set_color(#4E4840);
                draw_rectangle(_x1, _y1, _x1 + _t - 1, _y1 + _t - 1, false);

                draw_set_color(#3A3530);
                draw_rectangle(_x1, _y1, _x1 + _t - 1, _y1 + _t - 1, true);
            }
        }
    }
}

function demo17_node_near(_pg, _grid, _x, _y) { // a click on a one way should mean the one way, not the platform below it. try the click row, then walk upward
    var _lay = _grid.layout;
    var _c   = floor((_x - _lay.origin_x) / _lay.tile_w);

    var _r0 = floor((_y - 1 - _lay.origin_y) / _lay.tile_h);
	
	//show_debug_message("click at (" + string(_x) + "," + string(_y)
    //             + ") -> col " + string(_c) + " r0 " + string(_r0));

    // first, try the row of the click and a few rows above it
    for (var _i = 0; _i <= 6; _i++) {
        var _r  = _r0 - _i;
        var _n  = gmnav_grid_node(_grid, _c, _r);
        if (_n == GMNAV_NO_NODE) continue;

        var _pn = _pg.node_of[_n];
        if (_pn >= 0) return _pn;
    }

    // nothing above the click, fall back to the framework's downward search
    return gmnav_platgraph_node_at(_pg, _x, _y);
}