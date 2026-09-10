#macro DEMO14_W     30
#macro DEMO14_H     22
#macro DEMO14_TILE  32
#macro DEMO14_LIFT  24

function demo14_make_grid() {
    var _g = gmnav_grid_create(DEMO14_W, DEMO14_H,
                 gmnav_layout_create(gmnav_layout.ORTHO, DEMO14_TILE, DEMO14_TILE,
                                     undefined, undefined, 200, 200));

    gmnav_grid_fill_blocked(_g, 0, 0, DEMO14_W - 1, 0, true);
    gmnav_grid_fill_blocked(_g, 0, DEMO14_H - 1, DEMO14_W - 1, DEMO14_H - 1, true);
    gmnav_grid_fill_blocked(_g, 0, 0, 0, DEMO14_H - 1, true);
    gmnav_grid_fill_blocked(_g, DEMO14_W - 1, 0, DEMO14_W - 1, DEMO14_H - 1, true);

    // a dividing wall with a one cell door and a three cell one, so clearance and reachability have something different to say about each
    gmnav_grid_fill_blocked(_g, 15,  1, 16,  5, true);
    gmnav_grid_fill_blocked(_g, 15,  7, 16, 13, true);
    gmnav_grid_fill_blocked(_g, 15, 17, 16, DEMO14_H - 2, true);

    // a sealed room, so the reach view has a second component to colour
    gmnav_grid_fill_blocked(_g, 22,  3, 27,  3, true);
    gmnav_grid_fill_blocked(_g, 22,  9, 27,  9, true);
    gmnav_grid_fill_blocked(_g, 22,  3, 22,  9, true);
    gmnav_grid_fill_blocked(_g, 27,  3, 27,  9, true);

    var _ov = gmnav_overlay_create(_g);

    // two rows wide, so an agent with a radius fits and shortcuts are possible. a deck narrower than the body is walkable but never smoothable
    var _rows = [10, 11];

    for (var _i = 0; _i < 2; _i++) {
        var _r = _rows[_i];

        var _ramp = [];
        for (var _c = 4; _c <= 7; _c++) {
            array_push(_ramp, gmnav_overlay_add(_ov, _c, _r, 1));
        }
        gmnav_overlay_ramp(_ov, _ramp);

        for (var _c2 = 8; _c2 <= 13; _c2++) gmnav_overlay_add(_ov, _c2, _r, 1);

        gmnav_overlay_link(_ov, gmnav_grid_node(_g, 3, _r), _ramp[0],
                           gmnav_link.STAIR, true);
        gmnav_overlay_link(_ov, gmnav_overlay_node_at(_ov, 13, _r, 1),
                           gmnav_grid_node(_g, 14, _r), gmnav_link.STAIR, true);
    }

    gmnav_overlay_finish(_ov);
    gmnav_grid_set_layer_lift(_g, DEMO14_LIFT);
    gmnav_clearance_build(_g);

    return _g;
}

function demo14_view_name(_i) {
    var _n = ["blocked cells", "clearance", "costs", "flow field",
              "reachability", "reachability, clearance 2", "search frontier"];
    return _n[_i];
}

function demo14_send(_obj, _col, _row) {
    var _n = gmnav_grid_node(_obj.grid, _col, _row);
    if (_n == GMNAV_NO_NODE) return;

    var _p = gmnav_grid_node_to_world(_obj.grid, _n);
    gmnav_agent_goto(_obj.agent, _p[0], _p[1]);
}

function demo14_probe(_obj) { // restarts the hand driven search the frontier view draws
    gmnav_search_begin(_obj.probe,
                       gmnav_grid_node(_obj.grid, 2, 20),
                       gmnav_grid_node(_obj.grid, 27, 2),
                       false, _obj.profile);
    _obj.probe_on = true;
}