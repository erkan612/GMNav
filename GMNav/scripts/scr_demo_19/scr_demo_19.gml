#macro DEMO19_W        14
#macro DEMO19_H        16

#macro DEMO19_START_C   3
#macro DEMO19_START_R   4
#macro DEMO19_GOAL_C   11
#macro DEMO19_GOAL_R    4

#macro DEMO19_MAP_X   480
#macro DEMO19_MAP_Y    30
#macro DEMO19_MAP_W   780
#macro DEMO19_MAP_H   720

#macro DEMO19_VIEW_COUNT 4

function demo19_layout_mode(_i) {
    switch (_i) {
        case 0: return gmnav_layout.ORTHO;
        case 1: return gmnav_layout.ISO_DIAMOND;
        case 2: return gmnav_layout.ISO_STAGGERED;
        case 3: return gmnav_layout.HEX_POINTY;
        default: return gmnav_layout.HEX_FLAT;
    }
}

function demo19_layout_name(_i) {
    switch (_i) {
        case 0: return "ORTHO";
        case 1: return "ISO_DIAMOND";
        case 2: return "ISO_STAGGERED";
        case 3: return "HEX_POINTY";
        default: return "HEX_FLAT";
    }
}

function demo19_view_name(_i) {
    switch (_i) {
        case 0: return "routes";
        case 1: return "clearance";
        case 2: return "field, need_clear 2";
        default: return "field, need_clear 0";
    }
}

function demo19_build_level(_g) {
    // outer walls
    gmnav_grid_fill_blocked(_g, 0, 0, DEMO19_W - 1, 0, true);
    gmnav_grid_fill_blocked(_g, 0, DEMO19_H - 1, DEMO19_W - 1, DEMO19_H - 1, true);
    gmnav_grid_fill_blocked(_g, 0, 0, 0, DEMO19_H - 1, true);
    gmnav_grid_fill_blocked(_g, DEMO19_W - 1, 0, DEMO19_W - 1, DEMO19_H - 1, true);

    gmnav_grid_fill_blocked(_g, 7, 1, 7, DEMO19_H - 2, true);

    gmnav_grid_set_blocked(_g, 7, 3, false);              // gap A, one cell
    gmnav_grid_fill_blocked(_g, 7, 6, 7, 8, false);       // gap B, three cells
    gmnav_grid_fill_blocked(_g, 7, 10, 7, 14, false);     // gap C, five cells
}

function demo19_make_grid(_i) {
    var _mode = demo19_layout_mode(_i);
    var _nb   = (_mode == gmnav_layout.HEX_POINTY
              || _mode == gmnav_layout.HEX_FLAT)
              ? gmnav_neighbours.SIX : gmnav_neighbours.EIGHT;

    var _lay = gmnav_layout_create(_mode, 32, 32, _nb);
    var _g   = gmnav_grid_create(DEMO19_W, DEMO19_H, _lay);

    demo19_build_level(_g);
    gmnav_clearance_build(_g);

    demo19_fit_origin(_g);

    return _g;
}

function demo19_fit_origin(_g) { // every layout has a different world footprint, so shift the origin so the map sits centred in the map area
    var _lay = _g.layout;

    var _min_x =  999999;
    var _max_x = -999999;
    var _min_y =  999999;
    var _max_y = -999999;

    for (var _c = 0; _c < _g.width; _c++) {
        for (var _r = 0; _r < _g.height; _r++) {
            var _cx = gmnav_layout_cell_x(_lay, _c, _r);
            var _cy = gmnav_layout_cell_y(_lay, _c, _r);

            if (_cx < _min_x) _min_x = _cx;
            if (_cx > _max_x) _max_x = _cx;
            if (_cy < _min_y) _min_y = _cy;
            if (_cy > _max_y) _max_y = _cy;
        }
    }

    var _w = _max_x - _min_x;
    var _h = _max_y - _min_y;

    _lay.origin_x += DEMO19_MAP_X + (DEMO19_MAP_W - _w) * 0.5 - _min_x;
    _lay.origin_y += DEMO19_MAP_Y + (DEMO19_MAP_H - _h) * 0.5 - _min_y;
}

function demo19_world_of(_g, _col, _row) {
    return gmnav_grid_node_to_world(_g, gmnav_grid_node(_g, _col, _row));
}

function demo19_rebuild(_obj) { // fresh grid, scheduler, three agents, two fields
    _obj.grid   = demo19_make_grid(_obj.layout_idx);
    _obj.layout = _obj.grid.layout;

    _obj.sched = gmnav_scheduler_create(_obj.grid, 3000);

    var _sp = demo19_world_of(_obj.grid, DEMO19_START_C, DEMO19_START_R);
    var _gp = demo19_world_of(_obj.grid, DEMO19_GOAL_C,  DEMO19_GOAL_R);

    _obj.agent_small  = gmnav_agent_create(_obj.sched, _sp[0] - 14, _sp[1] - 14, 8,  2.2);
    _obj.agent_medium = gmnav_agent_create(_obj.sched, _sp[0],      _sp[1],      24, 2.0);
    _obj.agent_big    = gmnav_agent_create(_obj.sched, _sp[0] + 14, _sp[1] + 14, 40, 1.8);

    _obj.agent_small.need_clear  = gmnav_clearance_for_radius(_obj.grid, _obj.agent_small.radius);
    _obj.agent_medium.need_clear = gmnav_clearance_for_radius(_obj.grid, _obj.agent_medium.radius);
    _obj.agent_big.need_clear    = gmnav_clearance_for_radius(_obj.grid, _obj.agent_big.radius);

    _obj.agent_small.avoid_pinch  = _obj.avoid_pinch;
    _obj.agent_medium.avoid_pinch = _obj.avoid_pinch;
    _obj.agent_big.avoid_pinch    = _obj.avoid_pinch;

    demo19_place(_obj, _obj.agent_small,  _sp[0] - 14, _sp[1] - 14);
    demo19_place(_obj, _obj.agent_medium, _sp[0],      _sp[1]);
    demo19_place(_obj, _obj.agent_big,    _sp[0] + 14, _sp[1] + 14);

    _obj.goal_x = _gp[0];
    _obj.goal_y = _gp[1];

    _obj.field_2 = gmnav_flowfield_create(_obj.grid, undefined, undefined, undefined, 2, _obj.avoid_pinch);
    _obj.field_0 = gmnav_flowfield_create(_obj.grid, undefined, undefined, undefined, 0, _obj.avoid_pinch);

    demo19_rebuild_fields(_obj);
    demo19_send(_obj);

    _obj.last_path_small  = undefined;
    _obj.last_path_medium = undefined;
    _obj.last_path_big    = undefined;
}

function demo19_place(_obj, _agent, _x, _y) {
    var _n = gmnav_grid_world_to_node(_obj.grid, _x, _y, 0);
    if (_n == GMNAV_NO_NODE) return;

    var _snap = _n;

    if (_agent.need_clear > 1) {
        var _near = gmnav_clearance_nearest(_obj.grid, _n, _agent.need_clear, 20);
        if (_near != GMNAV_NO_NODE) _snap = _near;
    }

    var _p = gmnav_grid_node_to_world(_obj.grid, _snap);
    _agent.x = _p[0];
    _agent.y = _p[1];
}

function demo19_rebuild_fields(_obj) { // both fields seed on the current goal, so a left click moves the arrows too
    var _goal_node = gmnav_grid_world_to_node_top(_obj.grid, _obj.goal_x, _obj.goal_y);
    if (_goal_node == GMNAV_NO_NODE) return;
    if (gmnav_grid_is_blocked(_obj.grid, _goal_node)) return;

    gmnav_flowfield_build(_obj.field_2, _goal_node);
    gmnav_flowfield_build(_obj.field_0, _goal_node);
}

function demo19_send(_obj) {
    gmnav_agent_goto(_obj.agent_small,  _obj.goal_x, _obj.goal_y);
    gmnav_agent_goto(_obj.agent_medium, _obj.goal_x, _obj.goal_y);
    gmnav_agent_goto(_obj.agent_big,    _obj.goal_x, _obj.goal_y);
}

function demo19_set_goal(_obj, _x, _y) {
    _obj.goal_x = _x;
    _obj.goal_y = _y;

    demo19_rebuild_fields(_obj);
    demo19_send(_obj);
}

function demo19_toggle_blocked(_obj, _node) {
    var _c = gmnav_grid_col(_obj.grid, _node);
    var _r = gmnav_grid_row(_obj.grid, _node);

    var _gn = gmnav_grid_world_to_node_top(_obj.grid, _obj.goal_x, _obj.goal_y);
    if (_node == _gn) return;

    var _b = !gmnav_grid_is_blocked(_obj.grid, _node);

    gmnav_grid_set_blocked(_obj.grid, _c, _r, _b);

    // if an agent now stands on a blocked cell, push it to the nearest open
    var _a = [_obj.agent_small, _obj.agent_medium, _obj.agent_big];

    for (var i = 0; i < 3; i++) {
        var _an = gmnav_grid_world_to_node(_obj.grid, _a[i].x, _a[i].y, _a[i].layer);
        if (_an != _node) continue;

        var _snap = gmnav_util_snap_open(_obj.grid, _a[i].x, _a[i].y, 6);
        if (_snap == GMNAV_NO_NODE) continue;

        var _p = gmnav_grid_node_to_world(_obj.grid, _snap);
        _a[i].x = _p[0];
        _a[i].y = _p[1];
    }

    gmnav_clearance_build_if_stale(_obj.grid);

    demo19_rebuild_fields(_obj);
    demo19_send(_obj);
}

function demo19_draw_path_from(_p, _col) {
    if (_p == undefined || _p.count < 2) return;

    draw_set_color(_col);

    for (var i = 0; i < _p.count - 1; i++) {
        draw_line_width(_p.px[i], _p.py[i], _p.px[i + 1], _p.py[i + 1], 3);
    }

    for (var j = 0; j < _p.count; j++) {
        draw_circle(_p.px[j], _p.py[j], 3, false);
    }
}