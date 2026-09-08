#macro DEMO8_W        36
#macro DEMO8_H        30
#macro DEMO8_TILE_W   32
#macro DEMO8_TILE_H   24
#macro DEMO8_LIFT     24

#macro DEMO8_PLAT_C1  12
#macro DEMO8_PLAT_C2  23
#macro DEMO8_PLAT_R1   9
#macro DEMO8_PLAT_R2  20

#macro DEMO8_RAMP_LEN  6

function demo8_build_level(_grid) {
    gmnav_grid_fill_blocked(_grid, 0, 0, DEMO8_W - 1, 0, true);
    gmnav_grid_fill_blocked(_grid, 0, DEMO8_H - 1, DEMO8_W - 1, DEMO8_H - 1, true);
    gmnav_grid_fill_blocked(_grid, 0, 0, 0, DEMO8_H - 1, true);
    gmnav_grid_fill_blocked(_grid, DEMO8_W - 1, 0, DEMO8_W - 1, DEMO8_H - 1, true);

    var _ov = gmnav_overlay_create(_grid);

    for (var _c = DEMO8_PLAT_C1; _c <= DEMO8_PLAT_C2; _c++) {
        for (var _r = DEMO8_PLAT_R1; _r <= DEMO8_PLAT_R2; _r++) {
            gmnav_overlay_add(_ov, _c, _r, 1);
        }
    }

    gmnav_grid_fill_blocked(_grid, DEMO8_PLAT_C1, DEMO8_PLAT_R1,
                                   DEMO8_PLAT_C2, DEMO8_PLAT_R2, true);

    // south, climbing north. west, climbing east. and the two opposites.
    demo8_add_ramp(_grid, _ov, 15, DEMO8_PLAT_R2 + DEMO8_RAMP_LEN,  0, -1);
    demo8_add_ramp(_grid, _ov, 20, DEMO8_PLAT_R1 - DEMO8_RAMP_LEN,  0,  1);
    demo8_add_ramp(_grid, _ov, DEMO8_PLAT_C1 - DEMO8_RAMP_LEN, 12,  1,  0);
    demo8_add_ramp(_grid, _ov, DEMO8_PLAT_C2 + DEMO8_RAMP_LEN, 17, -1,  0);

    gmnav_overlay_finish(_ov);
}

function demo8_add_ramp(_grid, _ov, _c, _r, _dc, _dr) {
    // the two lanes run perpendicular to the climb
    var _pc = (_dc == 0) ? 1 : 0;
    var _pr = (_dc == 0) ? 0 : 1;

    for (var _lane = 0; _lane < 2; _lane++) {
        var _lc = _c + _pc * _lane;
        var _lr = _r + _pr * _lane;

        var _cells = [];

        //for (var _i = 0; _i < DEMO8_RAMP_LEN; _i++) {
        //    var _cc = _lc + _dc * _i;
        //    var _rr = _lr + _dr * _i;

        //    gmnav_grid_set_blocked(_grid, _cc, _rr, false);
        //    array_push(_cells, gmnav_overlay_add(_ov, _cc, _rr, 1));
        //}
        for (var _i = 0; _i < DEMO8_RAMP_LEN; _i++) {
            var _cc = _lc + _dc * _i;
            var _rr = _lr + _dr * _i;

            gmnav_grid_set_blocked(_grid, _cc, _rr, true);

            array_push(_cells, gmnav_overlay_add(_ov, _cc, _rr, 1));
        }

        gmnav_overlay_ramp(_ov, _cells);

        // one link per lane, at the foot
        gmnav_overlay_link(_ov,
            gmnav_grid_node(_grid, _lc - _dc, _lr - _dr),
            _cells[0], gmnav_link.STAIR, true);
    }
}

function demo8_deck_at(_grid, _col, _row, _layer = 1) {
    if (!gmnav_grid_has_overlay(_grid)) return GMNAV_NO_NODE;
    return gmnav_overlay_node_at(_grid.overlay, _col, _row, _layer);
}

function demo8_make_grid() {
    var _lay = gmnav_layout_create(gmnav_layout.ORTHO, DEMO8_TILE_W, DEMO8_TILE_H,
                                   gmnav_neighbours.EIGHT, gmnav_costmode.VISUAL);
    var _g = gmnav_grid_create(DEMO8_W, DEMO8_H, _lay);

    demo8_build_level(_g);
    gmnav_grid_set_layer_lift(_g, DEMO8_LIFT);

    return _g;
}

function demo8_ramp_layer(_row) {
    if (_row >= 10) return 1;
    return 2;
}

function demo8_face_open(_grid, _col, _row, _layer) {
    return (demo8_deck_at(_grid, _col, _row + 1, _layer) == GMNAV_NO_NODE);
}

function demo8_drop(_grid, _col, _row, _layer) {
    for (var _b = _layer - 1; _b >= 1; _b--) {
        if (demo8_deck_at(_grid, _col, _row, _b) != GMNAV_NO_NODE) {
            return (_layer - _b) * DEMO8_LIFT;
        }
    }
    return _layer * DEMO8_LIFT;
}

function demo8_screen(_grid, _node) {
    return gmnav_grid_node_to_world(_grid, _node);
}

function demo8_at(_grid, _col, _row, _height) {
    return [gmnav_layout_cell_x(_grid.layout, _col, _row),
            gmnav_layout_cell_y(_grid.layout, _col, _row) - _height * DEMO8_LIFT];
}

function demo8_height(_grid, _node) {
    var _h = gmnav_grid_node_layer(_grid, _node);
    if (_node >= _grid.count && gmnav_grid_has_overlay(_grid)) {
        _h += gmnav_overlay_offset(_grid.overlay, _node);
    }
    return _h;
}

function demo8_is_ramp(_grid, _node) {
    if (_node == GMNAV_NO_NODE) return false;
    return (gmnav_overlay_offset(_grid.overlay, _node) != 0);
}

function demo8_depth(_row, _height) {
    return _row * 64 + round(_height * 16);
}