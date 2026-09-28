#macro DEMO20_W        32
#macro DEMO20_H        20
#macro DEMO20_TILE     32

#macro DEMO20_RIVER_C1 15
#macro DEMO20_RIVER_C2 16
#macro DEMO20_BRIDGE_R 10

#macro DEMO20_START_C   5
#macro DEMO20_START_R  10
#macro DEMO20_GOAL_C   26
#macro DEMO20_GOAL_R   10

function demo20_build_level(_g) {
    gmnav_grid_fill_blocked(_g, 0, 0, DEMO20_W - 1, 0, true);
    gmnav_grid_fill_blocked(_g, 0, DEMO20_H - 1, DEMO20_W - 1, DEMO20_H - 1, true);
    gmnav_grid_fill_blocked(_g, 0, 0, 0, DEMO20_H - 1, true);
    gmnav_grid_fill_blocked(_g, DEMO20_W - 1, 0, DEMO20_W - 1, DEMO20_H - 1, true);

    // the river, impassable. the only way across is the bridge
    gmnav_grid_fill_blocked(_g, DEMO20_RIVER_C1, 1, DEMO20_RIVER_C2, DEMO20_H - 2, true);

    // the bridge, four overlay cells at row 10, layer 1
    var _ov = gmnav_overlay_create(_g);

    for (var _c = DEMO20_RIVER_C1 - 1; _c <= DEMO20_RIVER_C2 + 1; _c++) {
        gmnav_overlay_add(_ov, _c, DEMO20_BRIDGE_R, 1);
    }

    var _first = gmnav_overlay_node_at(_ov, DEMO20_RIVER_C1 - 1, DEMO20_BRIDGE_R, 1);
    var _last  = gmnav_overlay_node_at(_ov, DEMO20_RIVER_C2 + 1, DEMO20_BRIDGE_R, 1);

    gmnav_overlay_link(_ov, gmnav_grid_node(_g, DEMO20_RIVER_C1 - 2, DEMO20_BRIDGE_R),
                       _first, gmnav_link.STAIR, true);
    gmnav_overlay_link(_ov, _last,
                       gmnav_grid_node(_g, DEMO20_RIVER_C2 + 2, DEMO20_BRIDGE_R),
                       gmnav_link.STAIR, true);

    gmnav_overlay_finish(_ov);
}

function demo20_make_grid() {
    var _lay = gmnav_layout_create(gmnav_layout.ORTHO, DEMO20_TILE, DEMO20_TILE);
    var _g   = gmnav_grid_create(DEMO20_W, DEMO20_H, _lay);

    demo20_build_level(_g);
    return _g;
}

function demo20_world_of(_g, _c, _r) {
    return gmnav_grid_node_to_world(_g, gmnav_grid_node(_g, _c, _r));
}

function demo20_bridge_cells() { // every column the bridge occupies, in order
    var _out = [];
    for (var _c = DEMO20_RIVER_C1 - 1; _c <= DEMO20_RIVER_C2 + 1; _c++) {
        array_push(_out, _c);
    }
    return _out;
}

function demo20_rebuild(_obj) {
    _obj.grid = demo20_make_grid();
    _obj.sched = gmnav_scheduler_create(_obj.grid, 3000);

    var _sp = demo20_world_of(_obj.grid, DEMO20_START_C, DEMO20_START_R);
    var _gp = demo20_world_of(_obj.grid, DEMO20_GOAL_C,  DEMO20_GOAL_R);

    _obj.agent = gmnav_agent_create(_obj.sched, _sp[0], _sp[1], 8, 2.2);
    _obj.goal_x = _gp[0];
    _obj.goal_y = _gp[1];

    gmnav_agent_goto(_obj.agent, _gp[0], _gp[1]);
}

function demo20_send(_obj) {
    gmnav_agent_goto(_obj.agent, _obj.goal_x, _obj.goal_y);
}

function demo20_set_goal(_obj, _x, _y) {
    _obj.goal_x = _x;
    _obj.goal_y = _y;
    demo20_send(_obj);
}

function demo20_toggle_remove(_obj, _node) {
    var _ov = _obj.grid.overlay;
    if (_node == GMNAV_NO_NODE) return false;
    if (_node < _ov.base) return false;

    var _c = gmnav_grid_col(_obj.grid, _node);
    var _r = gmnav_grid_row(_obj.grid, _node);

    var _an = gmnav_grid_world_to_node(_obj.grid, _obj.agent.x, _obj.agent.y, _obj.agent.layer);
    if (_an == _node) return false;

    if (gmnav_overlay_is_removed(_ov, _node)) {
        gmnav_overlay_add(_ov, _c, _r, 1);
    } else {
        gmnav_overlay_remove(_ov, _node);
    }

    demo20_send(_obj);
    return true;
}

function demo20_restore_all(_obj) {
    var _ov = _obj.grid.overlay;

    for (var _i = 0; _i < gmnav_overlay_count(_ov); _i++) {
        var _n = _ov.base + _i;
        if (!gmnav_overlay_is_removed(_ov, _n)) continue;

        gmnav_overlay_add(_ov, gmnav_grid_col(_obj.grid, _n),
                               gmnav_grid_row(_obj.grid, _n), 1);
    }

    demo20_send(_obj);
}

function demo20_compact(_obj) {
    if (!gmnav_grid_has_overlay(_obj.grid)) return;

    gmnav_overlay_compact(_obj.grid.overlay);
    demo20_send(_obj);
}

function demo20_draw_path(_agent, _col) {
    var _p = _agent.path;
    if (_p == undefined || _p.count < 2) return;

    draw_set_color(_col);

    for (var _i = 0; _i < _p.count - 1; _i++) {
        draw_line_width(_p.px[_i], _p.py[_i], _p.px[_i + 1], _p.py[_i + 1], 3);
    }

    for (var _j = 0; _j < _p.count; _j++) {
        draw_circle(_p.px[_j], _p.py[_j], 3, false);
    }
}