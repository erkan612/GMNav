#macro DEMO9_W        28
#macro DEMO9_H        22
#macro DEMO9_TILE_W   32
#macro DEMO9_TILE_H   24
#macro DEMO9_LIFT     24

#macro DEMO9_CHASM_C1 13    // the chasm, running north to south
#macro DEMO9_CHASM_C2 14

#macro DEMO9_NORTH_R   5    // two crossings, so the field has to choose
#macro DEMO9_SOUTH_R  16

#macro DEMO9_RAMP_LEN  4    // cells per approach, so a lift is climbed in quarters

function demo9_build_level(_grid) {
    gmnav_grid_fill_blocked(_grid, 0, 0, DEMO9_W - 1, 0, true);
    gmnav_grid_fill_blocked(_grid, 0, DEMO9_H - 1, DEMO9_W - 1, DEMO9_H - 1, true);
    gmnav_grid_fill_blocked(_grid, 0, 0, 0, DEMO9_H - 1, true);
    gmnav_grid_fill_blocked(_grid, DEMO9_W - 1, 0, DEMO9_W - 1, DEMO9_H - 1, true);

    gmnav_grid_fill_blocked(_grid, DEMO9_CHASM_C1, 1,
                                   DEMO9_CHASM_C2, DEMO9_H - 2, true);

    var _ov = gmnav_overlay_create(_grid);

    demo9_add_crossing(_grid, _ov, DEMO9_NORTH_R);
    demo9_add_crossing(_grid, _ov, DEMO9_SOUTH_R);

    gmnav_overlay_finish(_ov);
}

function demo9_add_crossing(_grid, _ov, _row) {
    // the ground below stays open, so the approach is a trestle rather than an embankment and the bank is still walkable underneath it
    var _wlo = DEMO9_CHASM_C1 - DEMO9_RAMP_LEN;
    var _ehi = DEMO9_CHASM_C2 + DEMO9_RAMP_LEN;

    // west approach, climbing east
    var _west = [];
    for (var _c = _wlo; _c < DEMO9_CHASM_C1; _c++) {
        array_push(_west, gmnav_overlay_add(_ov, _c, _row, 1));
    }
    gmnav_overlay_ramp(_ov, _west);

    // the span itself, flat at a full lift
    gmnav_overlay_add(_ov, DEMO9_CHASM_C1, _row, 1);
    gmnav_overlay_add(_ov, DEMO9_CHASM_C2, _row, 1);

    // east approach, descending east. The ramp helper climbs along the array, so the cells are handed to it from the low end back toward the span
    var _east = [];
    for (var _c2 = _ehi; _c2 > DEMO9_CHASM_C2; _c2--) {
        array_push(_east, gmnav_overlay_add(_ov, _c2, _row, 1));
    }
    gmnav_overlay_ramp(_ov, _east);

    // cells on one layer join by themselves, so one link at each foot is enough
    gmnav_overlay_link(_ov, gmnav_grid_node(_grid, _wlo - 1, _row),
                       _west[0], gmnav_link.STAIR, true);
    gmnav_overlay_link(_ov, _east[0],
                       gmnav_grid_node(_grid, _ehi + 1, _row),
                       gmnav_link.STAIR, true);
}

function demo9_make_grid() {
    var _lay = gmnav_layout_create(gmnav_layout.ORTHO, DEMO9_TILE_W, DEMO9_TILE_H,
                                   gmnav_neighbours.EIGHT, gmnav_costmode.VISUAL);
    var _g = gmnav_grid_create(DEMO9_W, DEMO9_H, _lay);

    demo9_build_level(_g);
    gmnav_grid_set_layer_lift(_g, DEMO9_LIFT);

    return _g;
}

function demo9_is_chasm(_col) {
    return (_col >= DEMO9_CHASM_C1 && _col <= DEMO9_CHASM_C2);
}

function demo9_deck_at(_grid, _col, _row) {
    if (!gmnav_grid_has_overlay(_grid)) return GMNAV_NO_NODE;
    return gmnav_overlay_node_at(_grid.overlay, _col, _row, 1);
}

function demo9_height(_grid, _node) { // layer plus the cell's own fraction of a lift
    if (_node == GMNAV_NO_NODE) return 0;

    var _h = gmnav_grid_node_layer(_grid, _node);
    if (_node >= _grid.count && gmnav_grid_has_overlay(_grid)) {
        _h += gmnav_overlay_offset(_grid.overlay, _node);
    }
    return _h;
}

function demo9_is_ramp(_grid, _node) {
    if (_node == GMNAV_NO_NODE || _node < _grid.count) return false;
    return (gmnav_overlay_offset(_grid.overlay, _node) != 0);
}

function demo9_screen(_grid, _col, _row, _height) {
    return [gmnav_layout_cell_x(_grid.layout, _col, _row),
            gmnav_layout_cell_y(_grid.layout, _col, _row) - _height * DEMO9_LIFT];
}

function demo9_depth(_row, _height) { // a raised cell is drawn over the row behind it, so height joins the key
    return _row * 64 + round(_height * 16);
}

function demo9_spawn(_grid, _units) {
    repeat (200) {
        var _c = irandom_range(1, DEMO9_CHASM_C1 - 1);
        var _r = irandom_range(1, DEMO9_H - 2);
        var _n = gmnav_grid_node(_grid, _c, _r);

        if (_n == GMNAV_NO_NODE || gmnav_grid_is_blocked(_grid, _n)) continue;

        var _p = gmnav_grid_node_to_world(_grid, _n);

        array_push(_units, {
            x     : _p[0] + irandom_range(-6, 6),
            y     : _p[1] + irandom_range(-4, 4),
            layer : 0,
            hold  : GMNAV_NO_NODE,
            spd   : random_range(0.7, 1.3),
            hue   : irandom_range(0, 3)
        });
        return true;
    }
    return false;
}

//function demo9_unit_step(_grid, _field, _u) { // wiggle wiggle da fuq
//    var _n = gmnav_grid_world_to_node(_grid, _u.x, _u.y, _u.layer);

//    if (_n == GMNAV_NO_NODE) {
//        if (_u.hold == GMNAV_NO_NODE) return false;
//        return demo9_unit_seek(_grid, _u, _u.hold);
//    }

//    if (_field.dist[_n] <= 0) { _u.hold = GMNAV_NO_NODE; return true; }

//    var _nx = gmnav_flowfield_next(_field, _n);
//    if (_nx == GMNAV_NO_NODE) { _u.hold = GMNAV_NO_NODE; return false; }

//    _u.hold  = _nx;
//    _u.layer = gmnav_grid_node_layer(_grid, _nx);

//    return demo9_unit_seek(_grid, _u, _nx);
//}

function demo9_unit_step(_grid, _field, _u) {
    if (_u.hold != GMNAV_NO_NODE) return demo9_unit_seek(_grid, _u, _u.hold);

    var _n = gmnav_grid_world_to_node(_grid, _u.x, _u.y, _u.layer);

    if (_n == GMNAV_NO_NODE && _u.layer != 0) {
        _n = gmnav_grid_world_to_node(_grid, _u.x, _u.y, 0);
        if (_n != GMNAV_NO_NODE) _u.layer = 0;
    }
    if (_n == GMNAV_NO_NODE) return false;

    if (_field.dist[_n] <= 0) return true;

    var _nx = gmnav_flowfield_next(_field, _n);
    if (_nx == GMNAV_NO_NODE) return false;

    var _nl = gmnav_grid_node_layer(_grid, _nx);

    if (_nl != _u.layer || _n >= _grid.count) {
        _u.hold  = _nx;
        _u.layer = _nl;
        return demo9_unit_seek(_grid, _u, _nx);
    }

    _u.x += _field.dirx[_n] * _u.spd;
    _u.y += _field.diry[_n] * _u.spd;
    return false;
}

function demo9_unit_seek(_grid, _u, _node) {
    var _tp = gmnav_grid_node_to_world(_grid, _node);

    var _dx = _tp[0] - _u.x;
    var _dy = _tp[1] - _u.y;
    var _d  = point_distance(0, 0, _dx, _dy);

    if (_d <= _u.spd) {
        _u.x    = _tp[0];
        _u.y    = _tp[1];
        _u.hold = GMNAV_NO_NODE;
        return false;
    }

    _u.x += (_dx / _d) * _u.spd;
    _u.y += (_dy / _d) * _u.spd;
    return false;
}

function demo9_unit_colour(_hue) {
    switch (_hue) {
        case 0:  return #E8C46A;
        case 1:  return #D98A5A;
        case 2:  return #C8D96A;
        default: return #E0A0C0;
    }
}

function demo9_draw_arrow(_field, _node, _cx, _cy, _col) {
    if (_node == GMNAV_NO_NODE) return;

    var _dx = _field.dirx[_node];
    var _dy = _field.diry[_node];
    if (_dx == 0 && _dy == 0) return;

    draw_set_color(_col);
    draw_line(_cx - _dx * 7, _cy - _dy * 7, _cx + _dx * 7, _cy + _dy * 7);
    draw_circle(_cx + _dx * 7, _cy + _dy * 7, 2, false);
}