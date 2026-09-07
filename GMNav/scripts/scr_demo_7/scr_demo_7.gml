#macro DEMO7_W        28
#macro DEMO7_H        22
#macro DEMO7_TILE_W   32
#macro DEMO7_TILE_H   24
#macro DEMO7_LIFT     24    // one whole tile, so a raised cell covers the row behind

#macro DEMO7_RIVER_R1 11    // a river across the map, one crossing
#macro DEMO7_RIVER_R2 12
#macro DEMO7_XING_C    8

#macro DEMO7_FLY_R     5    // a bridge over open grass, walk over it or under it
#macro DEMO7_FLY_C1   16
#macro DEMO7_FLY_C2   21

#macro DEMO7_CLIFF_C1  4    // a cliff, layer 1
#macro DEMO7_CLIFF_C2 12
#macro DEMO7_CLIFF_R1 15
#macro DEMO7_CLIFF_R2 19

#macro DEMO7_PEAK_C1   6    // with a second cliff on top of it, layer 2
#macro DEMO7_PEAK_C2   9
#macro DEMO7_PEAK_R1  16
#macro DEMO7_PEAK_R2  17

#macro DEMO7_RAMP_C    8

function demo7_build_level(_grid) {
    gmnav_grid_fill_blocked(_grid, 0, 0, DEMO7_W - 1, 0, true);
    gmnav_grid_fill_blocked(_grid, 0, DEMO7_H - 1, DEMO7_W - 1, DEMO7_H - 1, true);
    gmnav_grid_fill_blocked(_grid, 0, 0, 0, DEMO7_H - 1, true);
    gmnav_grid_fill_blocked(_grid, DEMO7_W - 1, 0, DEMO7_W - 1, DEMO7_H - 1, true);

    gmnav_grid_fill_blocked(_grid, 1, DEMO7_RIVER_R1,
                                   DEMO7_W - 2, DEMO7_RIVER_R2, true);

    var _ov = gmnav_overlay_create(_grid);

    // the river crossing
    var _x1 = gmnav_overlay_add(_ov, DEMO7_XING_C, DEMO7_RIVER_R1, 1);
    var _x2 = gmnav_overlay_add(_ov, DEMO7_XING_C, DEMO7_RIVER_R2, 1);

    gmnav_overlay_link(_ov, gmnav_grid_node(_grid, DEMO7_XING_C, DEMO7_RIVER_R1 - 1),
                       _x1, gmnav_link.STAIR, true);
    gmnav_overlay_link(_ov, _x2,
                       gmnav_grid_node(_grid, DEMO7_XING_C, DEMO7_RIVER_R2 + 1),
                       gmnav_link.STAIR, true);

    // the bridge over nothing, ground below left open
    var _fa = GMNAV_NO_NODE;
    var _fb = GMNAV_NO_NODE;

    for (var _c = DEMO7_FLY_C1; _c <= DEMO7_FLY_C2; _c++) {
        var _n = gmnav_overlay_add(_ov, _c, DEMO7_FLY_R, 1);
        if (_fa == GMNAV_NO_NODE) _fa = _n;
        _fb = _n;
    }

    gmnav_overlay_link(_ov, gmnav_grid_node(_grid, DEMO7_FLY_C1 - 1, DEMO7_FLY_R),
                       _fa, gmnav_link.STAIR, true);
    gmnav_overlay_link(_ov, _fb,
                       gmnav_grid_node(_grid, DEMO7_FLY_C2 + 1, DEMO7_FLY_R),
                       gmnav_link.STAIR, true);

    // the cliff, layer 1 except where the peak sits
    for (var _c = DEMO7_CLIFF_C1; _c <= DEMO7_CLIFF_C2; _c++) {
        for (var _r = DEMO7_CLIFF_R1; _r <= DEMO7_CLIFF_R2; _r++) {

            var _under = (_c >= DEMO7_PEAK_C1 && _c <= DEMO7_PEAK_C2
                       && _r >= DEMO7_PEAK_R1 && _r <= DEMO7_PEAK_R2);
            if (_under) continue;

            gmnav_overlay_add(_ov, _c, _r, 1);
        }
    }

    gmnav_grid_fill_blocked(_grid, DEMO7_CLIFF_C1, DEMO7_CLIFF_R1,
                                   DEMO7_CLIFF_C2, DEMO7_CLIFF_R2, true);

    gmnav_overlay_link(_ov,
        gmnav_grid_node(_grid, DEMO7_RAMP_C, DEMO7_CLIFF_R2 + 1),
        gmnav_overlay_node_at(_ov, DEMO7_RAMP_C, DEMO7_CLIFF_R2, 1),
        gmnav_link.STAIR, true);

    // and the cliff on the cliff
    for (var _c = DEMO7_PEAK_C1; _c <= DEMO7_PEAK_C2; _c++) {
        for (var _r = DEMO7_PEAK_R1; _r <= DEMO7_PEAK_R2; _r++) {
            gmnav_overlay_add(_ov, _c, _r, 2);
        }
    }

    gmnav_overlay_link(_ov,
        gmnav_overlay_node_at(_ov, DEMO7_RAMP_C, DEMO7_PEAK_R2 + 1, 1),
        gmnav_overlay_node_at(_ov, DEMO7_RAMP_C, DEMO7_PEAK_R2,     2),
        gmnav_link.STAIR, true);

    gmnav_overlay_finish(_ov);
}

function demo7_deck_at(_grid, _col, _row, _layer = 1) {
    if (!gmnav_grid_has_overlay(_grid)) return GMNAV_NO_NODE;
    return gmnav_overlay_node_at(_grid.overlay, _col, _row, _layer);
}

function demo7_make_grid() {
    var _lay = gmnav_layout_create(gmnav_layout.ORTHO, DEMO7_TILE_W, DEMO7_TILE_H,
                                   gmnav_neighbours.EIGHT, gmnav_costmode.VISUAL);
    var _g = gmnav_grid_create(DEMO7_W, DEMO7_H, _lay);

    demo7_build_level(_g);
    gmnav_grid_set_layer_lift(_g, DEMO7_LIFT);

    return _g;
}

function demo7_screen(_grid, _col, _row, _layer) {
    return [gmnav_layout_cell_x(_grid.layout, _col, _row),
            gmnav_layout_cell_y(_grid.layout, _col, _row) - _layer * DEMO7_LIFT];
}

function demo7_depth(_row, _layer) {
    return _row * 16 + _layer * 4;
}

function demo7_face_open(_grid, _col, _row, _layer) {
    return (demo7_deck_at(_grid, _col, _row + 1, _layer) == GMNAV_NO_NODE);
}

function demo7_drop(_grid, _col, _row, _layer) {
    for (var _b = _layer - 1; _b >= 1; _b--) {
        if (demo7_deck_at(_grid, _col, _row, _b) != GMNAV_NO_NODE) {
            return (_layer - _b) * DEMO7_LIFT;
        }
    }
    return _layer * DEMO7_LIFT;
}

function demo7_is_deck(_col, _row, _layer) {
    if (_layer != 1) return false;

    if (_col == DEMO7_XING_C
    && (_row == DEMO7_RIVER_R1 || _row == DEMO7_RIVER_R2)) return true;

    return (_row == DEMO7_FLY_R && _col >= DEMO7_FLY_C1 && _col <= DEMO7_FLY_C2);
}

function demo7_ramps() {
    return [
        [DEMO7_XING_C, DEMO7_RIVER_R1 - 1, 0, DEMO7_XING_C, DEMO7_RIVER_R1, 1],
        [DEMO7_XING_C, DEMO7_RIVER_R2 + 1, 0, DEMO7_XING_C, DEMO7_RIVER_R2, 1],

        [DEMO7_FLY_C1 - 1, DEMO7_FLY_R, 0, DEMO7_FLY_C1, DEMO7_FLY_R, 1],
        [DEMO7_FLY_C2 + 1, DEMO7_FLY_R, 0, DEMO7_FLY_C2, DEMO7_FLY_R, 1],

        [DEMO7_RAMP_C, DEMO7_CLIFF_R2 + 1, 0, DEMO7_RAMP_C, DEMO7_CLIFF_R2, 1],
        [DEMO7_RAMP_C, DEMO7_PEAK_R2 + 1,  1, DEMO7_RAMP_C, DEMO7_PEAK_R2,  2]
    ];
}