#macro DEMO10_W        30
#macro DEMO10_H        22
#macro DEMO10_TILE_W   32
#macro DEMO10_TILE_H   24
#macro DEMO10_LIFT     24

#macro DEMO10_WALL_R   11   // one wall, two ways through it

#macro DEMO10_BR_C1     9   // the bridge, three lanes wide
#macro DEMO10_BR_C2    11
#macro DEMO10_RAMP_LEN  4

#macro DEMO10_GAP_C1   24   // the ground gap, five wide so a big unit fits
#macro DEMO10_GAP_C2   28

function demo10_build_level(_grid) {
    gmnav_grid_fill_blocked(_grid, 0, 0, DEMO10_W - 1, 0, true);
    gmnav_grid_fill_blocked(_grid, 0, DEMO10_H - 1, DEMO10_W - 1, DEMO10_H - 1, true);
    gmnav_grid_fill_blocked(_grid, 0, 0, 0, DEMO10_H - 1, true);
    gmnav_grid_fill_blocked(_grid, DEMO10_W - 1, 0, DEMO10_W - 1, DEMO10_H - 1, true);

    gmnav_grid_fill_blocked(_grid, 1, DEMO10_WALL_R,
                                   DEMO10_GAP_C1 - 1, DEMO10_WALL_R, true);

    var _ov = gmnav_overlay_create(_grid);

    for (var _c = DEMO10_BR_C1; _c <= DEMO10_BR_C2; _c++) {
        demo10_add_lane(_grid, _ov, _c);
    }

    gmnav_overlay_finish(_ov);
}

function demo10_add_lane(_grid, _ov, _col) {
    var _ntop = DEMO10_WALL_R - 1;
    var _nlo  = _ntop - DEMO10_RAMP_LEN + 1;

    var _north = [];
    for (var _r = _nlo; _r <= _ntop; _r++) {
        gmnav_grid_set_blocked(_grid, _col, _r, true);
        array_push(_north, gmnav_overlay_add(_ov, _col, _r, 1));
    }
    gmnav_overlay_ramp(_ov, _north);

    gmnav_overlay_add(_ov, _col, DEMO10_WALL_R, 1);

    var _stop = DEMO10_WALL_R + 1;
    var _shi  = _stop + DEMO10_RAMP_LEN - 1;

    var _south = [];
    for (var _r2 = _shi; _r2 >= _stop; _r2--) {
        gmnav_grid_set_blocked(_grid, _col, _r2, true);
        array_push(_south, gmnav_overlay_add(_ov, _col, _r2, 1));
    }
    gmnav_overlay_ramp(_ov, _south);

    gmnav_overlay_link(_ov, gmnav_grid_node(_grid, _col, _nlo - 1),
                       _north[0], gmnav_link.STAIR, true);
    gmnav_overlay_link(_ov, _south[0],
                       gmnav_grid_node(_grid, _col, _shi + 1),
                       gmnav_link.STAIR, true);
}

function demo10_make_grid() {
    var _lay = gmnav_layout_create(gmnav_layout.ORTHO, DEMO10_TILE_W, DEMO10_TILE_H,
                                   gmnav_neighbours.EIGHT, gmnav_costmode.VISUAL);
    var _g = gmnav_grid_create(DEMO10_W, DEMO10_H, _lay);

    demo10_build_level(_g);
    gmnav_grid_set_layer_lift(_g, DEMO10_LIFT);
    gmnav_clearance_build(_g);

    return _g;
}

function demo10_deck_at(_grid, _col, _row) {
    if (!gmnav_grid_has_overlay(_grid)) return GMNAV_NO_NODE;
    return gmnav_overlay_node_at(_grid.overlay, _col, _row, 1);
}

function demo10_toll_layer(_grid) { // a toll on every deck cell, so the shortcut can be priced out
    var _lay = gmnav_costlayer_create(_grid, "toll");
    var _ov  = _grid.overlay;

    for (var _i = 0; _i < gmnav_overlay_count(_ov); _i++) {
        gmnav_costlayer_set_node(_lay, _ov.base + _i, 12);
    }
    return _lay;
}

function demo10_depth(_row, _height) { // a raised cell is drawn over the row behind it, so height joins the key
    return _row * 64 + round(_height * 16);
}

function demo10_agent_depth(_grid, _agent) {
    var _n = gmnav_grid_world_to_node(_grid, _agent.x, _agent.y, _agent.layer);
    if (_n == GMNAV_NO_NODE) _n = gmnav_grid_world_to_node(_grid, _agent.x, _agent.y, 0);
    if (_n == GMNAV_NO_NODE) return 0;

    return demo10_depth(gmnav_grid_row(_grid, _n), gmt_node_height(_grid, _n)) + 8;
}

function demo10_draw_path(_agent, _col) {
    var _p = _agent.path;
    if (_p == undefined || _p.count < 2) return;

    draw_set_color(_col);
    for (var i = 0; i < _p.count - 1; i++) {
        draw_line_width(_p.px[i], _p.py[i], _p.px[i + 1], _p.py[i + 1], 2);
    }
}