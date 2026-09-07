#macro DEMO6_W  32
#macro DEMO6_H  32

#macro DEMO6_RIVER_C1   15   // the river, splitting the map north to south
#macro DEMO6_RIVER_C2   16
#macro DEMO6_XING_R     16   // the one crossing

#macro DEMO6_FLY_C1      6   // west: a bridge over nothing at all, so you can
#macro DEMO6_FLY_C2      9   // walk over it or under it
#macro DEMO6_FLY_R       8

#macro DEMO6_CLIFF_C1   20   // east: a cliff, layer 1
#macro DEMO6_CLIFF_C2   26
#macro DEMO6_CLIFF_R1    6
#macro DEMO6_CLIFF_R2   14

#macro DEMO6_PEAK_C1    22   // and a second cliff on top of it, layer 2
#macro DEMO6_PEAK_C2    24
#macro DEMO6_PEAK_R1     8
#macro DEMO6_PEAK_R2    10

#macro DEMO6_LIFT       26

#macro DEMO6_RAMP_C   23

function demo6_build_level(_grid) {
    gmnav_grid_fill_blocked(_grid, 0, 0, DEMO6_W - 1, 0, true);
    gmnav_grid_fill_blocked(_grid, 0, DEMO6_H - 1, DEMO6_W - 1, DEMO6_H - 1, true);
    gmnav_grid_fill_blocked(_grid, 0, 0, 0, DEMO6_H - 1, true);
    gmnav_grid_fill_blocked(_grid, DEMO6_W - 1, 0, DEMO6_W - 1, DEMO6_H - 1, true);

    gmnav_grid_fill_blocked(_grid, DEMO6_RIVER_C1, 1,
                                   DEMO6_RIVER_C2, DEMO6_H - 2, true);

    var _ov = gmnav_overlay_create(_grid);

    // the river crossing
    var _x1 = gmnav_overlay_add(_ov, DEMO6_RIVER_C1, DEMO6_XING_R, 1);
    var _x2 = gmnav_overlay_add(_ov, DEMO6_RIVER_C2, DEMO6_XING_R, 1);

    gmnav_overlay_link(_ov, gmnav_grid_node(_grid, DEMO6_RIVER_C1 - 1, DEMO6_XING_R),
                       _x1, gmnav_link.STAIR, true);
    gmnav_overlay_link(_ov, _x2,
                       gmnav_grid_node(_grid, DEMO6_RIVER_C2 + 1, DEMO6_XING_R),
                       gmnav_link.STAIR, true);

    // west, the bridge over nothing
    // the ground below stays open on purpose. that is the demonstration
    var _fa = GMNAV_NO_NODE;
    var _fb = GMNAV_NO_NODE;

    for (var _c = DEMO6_FLY_C1; _c <= DEMO6_FLY_C2; _c++) {
        var _n = gmnav_overlay_add(_ov, _c, DEMO6_FLY_R, 1);
        if (_fa == GMNAV_NO_NODE) _fa = _n;
        _fb = _n;
    }

    gmnav_overlay_link(_ov, gmnav_grid_node(_grid, DEMO6_FLY_C1 - 1, DEMO6_FLY_R),
                       _fa, gmnav_link.STAIR, true);
    gmnav_overlay_link(_ov, _fb,
                       gmnav_grid_node(_grid, DEMO6_FLY_C2 + 1, DEMO6_FLY_R),
                       gmnav_link.STAIR, true);

    // east, the cliff
    // layer 1 everywhere except under the peak, which is solid there
    for (var _c = DEMO6_CLIFF_C1; _c <= DEMO6_CLIFF_C2; _c++) {
        for (var _r = DEMO6_CLIFF_R1; _r <= DEMO6_CLIFF_R2; _r++) {

            var _under_peak = (_c >= DEMO6_PEAK_C1 && _c <= DEMO6_PEAK_C2
                            && _r >= DEMO6_PEAK_R1 && _r <= DEMO6_PEAK_R2);
            if (_under_peak) continue;

            gmnav_overlay_add(_ov, _c, _r, 1);
        }
    }

    // solid at ground level, with a notch left open where the lower ramp lands
    gmnav_grid_fill_blocked(_grid, DEMO6_CLIFF_C1, DEMO6_CLIFF_R1,
                                   DEMO6_CLIFF_C2, DEMO6_CLIFF_R2, true);
    gmnav_grid_fill_blocked(_grid, DEMO6_RAMP_C, DEMO6_CLIFF_R2,
                                   DEMO6_RAMP_C, DEMO6_CLIFF_R2, false);

    gmnav_overlay_link(_ov,
        gmnav_grid_node(_grid, DEMO6_RAMP_C, DEMO6_CLIFF_R2 + 1),
        gmnav_overlay_node_at(_ov, DEMO6_RAMP_C, DEMO6_CLIFF_R2, 1),
        gmnav_link.STAIR, true);

    // and the cliff on the cliff
    for (var _c = DEMO6_PEAK_C1; _c <= DEMO6_PEAK_C2; _c++) {
        for (var _r = DEMO6_PEAK_R1; _r <= DEMO6_PEAK_R2; _r++) {
            gmnav_overlay_add(_ov, _c, _r, 2);
        }
    }

    
    gmnav_overlay_link(_ov, // the upper ramp lands one row south of the peak, on ordinary layer 1
        gmnav_overlay_node_at(_ov, DEMO6_RAMP_C, DEMO6_PEAK_R2 + 1, 1),
        gmnav_overlay_node_at(_ov, DEMO6_RAMP_C, DEMO6_PEAK_R2,     2),
        gmnav_link.STAIR, true);

    gmnav_overlay_finish(_ov);
}

function demo6_deck_at(_grid, _col, _row, _layer = 1) {
    if (!gmnav_grid_has_overlay(_grid)) return GMNAV_NO_NODE;
    return gmnav_overlay_node_at(_grid.overlay, _col, _row, _layer);
}

function demo6_add_bridge(_grid, _ov, _fixed, _a, _b, _across) {
    var _first = GMNAV_NO_NODE;
    var _last  = GMNAV_NO_NODE;

    for (var _i = _a; _i <= _b; _i++) {
        var _c = _across ? _fixed : _i;
        var _r = _across ? _i     : _fixed;

        var _n = gmnav_overlay_add(_ov, _c, _r, 1);
        if (_first == GMNAV_NO_NODE) _first = _n;
        _last = _n;
    }

    var _bc = _across ? _fixed : (_a - 1);
    var _br = _across ? (_a - 1) : _fixed;
    gmnav_overlay_link(_ov, gmnav_grid_node(_grid, _bc, _br), _first,
                       gmnav_link.STAIR, true);

    var _ec = _across ? _fixed : (_b + 1);
    var _er = _across ? (_b + 1) : _fixed;
    gmnav_overlay_link(_ov, _last, gmnav_grid_node(_grid, _ec, _er),
                       gmnav_link.STAIR, true);
}

function demo6_screen(_grid, _col, _row, _layer) {
    return [gmnav_layout_cell_x(_grid.layout, _col, _row),
            gmnav_layout_cell_y(_grid.layout, _col, _row) - _layer * DEMO6_LIFT];
}

function demo6_depth(_col, _row, _layer) {
    return (_col + _row) * 16 + _layer * 4;
}

function demo6_diamond(_x, _y, _tw, _th, _col) {
    draw_set_color(_col);
    draw_primitive_begin(pr_trianglestrip);
    draw_vertex(_x, _y - _th * 0.5);
    draw_vertex(_x - _tw * 0.5, _y);
    draw_vertex(_x + _tw * 0.5, _y);
    draw_vertex(_x, _y + _th * 0.5);
    draw_primitive_end();
}

function demo6_quad(_x1, _y1, _x2, _y2, _x3, _y3, _x4, _y4, _col) {
    draw_set_color(_col);
    draw_primitive_begin(pr_trianglelist);
    draw_vertex(_x1, _y1); draw_vertex(_x2, _y2); draw_vertex(_x3, _y3);
    draw_vertex(_x1, _y1); draw_vertex(_x3, _y3); draw_vertex(_x4, _y4);
    draw_primitive_end();
}

function demo6_open_sw(_grid, _c, _r, _l) {
    if (_l == 0) return false;
    return (demo6_deck_at(_grid, _c, _r + 1, _l) == GMNAV_NO_NODE);
}

function demo6_open_se(_grid, _c, _r, _l) {
    if (_l == 0) return false;
    return (demo6_deck_at(_grid, _c + 1, _r, _l) == GMNAV_NO_NODE);
}

function demo6_drop_to(_grid, _c, _r, _l) {
    for (var _b = _l - 1; _b >= 1; _b--) {
        if (demo6_deck_at(_grid, _c, _r, _b) != GMNAV_NO_NODE) {
            return (_l - _b) * DEMO6_LIFT;
        }
    }
    return _l * DEMO6_LIFT;
}

function demo6_is_river(_col) {
    return (_col >= DEMO6_RIVER_C1 && _col <= DEMO6_RIVER_C2);
}

function demo6_ramps() {
    return [
        [DEMO6_RIVER_C1 - 1, DEMO6_XING_R, 0, DEMO6_RIVER_C1, DEMO6_XING_R, 1],
        [DEMO6_RIVER_C2 + 1, DEMO6_XING_R, 0, DEMO6_RIVER_C2, DEMO6_XING_R, 1],

        [DEMO6_FLY_C1 - 1, DEMO6_FLY_R, 0, DEMO6_FLY_C1, DEMO6_FLY_R, 1],
        [DEMO6_FLY_C2 + 1, DEMO6_FLY_R, 0, DEMO6_FLY_C2, DEMO6_FLY_R, 1],

        [DEMO6_RAMP_C, DEMO6_CLIFF_R2 + 1, 0, DEMO6_RAMP_C, DEMO6_CLIFF_R2, 1],
        [DEMO6_RAMP_C, DEMO6_PEAK_R2 + 1,  1, DEMO6_RAMP_C, DEMO6_PEAK_R2,  2]
    ];
}

function demo6_skirt(_x, _y, _tw, _th, _drop, _sw, _se, _col_l, _col_r) {
    var _hw = _tw * 0.5;
    var _hh = _th * 0.5;

    if (_sw && _se) { // one hexagon: left corner, bottom vertex, right corner, then down
        draw_set_color(_col_l);
        draw_primitive_begin(pr_trianglelist);

        draw_vertex(_x - _hw, _y);
        draw_vertex(_x, _y + _hh);
        draw_vertex(_x, _y + _hh + _drop);

        draw_vertex(_x - _hw, _y);
        draw_vertex(_x, _y + _hh + _drop);
        draw_vertex(_x - _hw, _y + _drop);

        draw_primitive_end();

        draw_set_color(_col_r);
        draw_primitive_begin(pr_trianglelist);

        draw_vertex(_x, _y + _hh);
        draw_vertex(_x + _hw, _y);
        draw_vertex(_x + _hw, _y + _drop);

        draw_vertex(_x, _y + _hh);
        draw_vertex(_x + _hw, _y + _drop);
        draw_vertex(_x, _y + _hh + _drop);

        draw_primitive_end();
        return;
    }

    if (_sw) {
        demo6_quad(_x - _hw, _y, _x, _y + _hh,
                   _x, _y + _hh + _drop, _x - _hw, _y + _drop, _col_l);
    }

    if (_se) {
        demo6_quad(_x, _y + _hh, _x + _hw, _y,
                   _x + _hw, _y + _drop, _x, _y + _hh + _drop, _col_r);
    }
}

function demo6_is_deck(_col, _row, _layer) {
    if (_layer != 1) return false;

    if (demo6_is_river(_col) && _row == DEMO6_XING_R) return true;

    if (_row == DEMO6_FLY_R && _col >= DEMO6_FLY_C1 && _col <= DEMO6_FLY_C2) {
        return true;
    }
    return false;
}