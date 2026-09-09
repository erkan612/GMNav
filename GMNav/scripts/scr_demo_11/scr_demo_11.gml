#macro DEMO11_W      30
#macro DEMO11_H      20
#macro DEMO11_TILE   32

#macro DEMO11_START_C  2
#macro DEMO11_START_R 16
#macro DEMO11_GOAL_C  27
#macro DEMO11_GOAL_R   2

function demo11_build_level(_grid) {
    gmnav_grid_fill_blocked(_grid, 0, 0, DEMO11_W - 1, 0, true);
    gmnav_grid_fill_blocked(_grid, 0, DEMO11_H - 1, DEMO11_W - 1, DEMO11_H - 1, true);
    gmnav_grid_fill_blocked(_grid, 0, 0, 0, DEMO11_H - 1, true);
    gmnav_grid_fill_blocked(_grid, DEMO11_W - 1, 0, DEMO11_W - 1, DEMO11_H - 1, true);

    // three blocks off the direct line, so every model has to bend and the difference between them is visible rather than academic
    gmnav_grid_fill_blocked(_grid,  8,  8, 11, 11, true);
    gmnav_grid_fill_blocked(_grid, 16, 11, 19, 14, true);
    gmnav_grid_fill_blocked(_grid, 20,  4, 23,  7, true);
}

function demo11_make_grid(_dirs) { // square tiles, so a cell diagonal is a true 45 on screen
    var _g = gmnav_grid_create(DEMO11_W, DEMO11_H,
                 gmnav_layout_create(gmnav_layout.ORTHO, DEMO11_TILE, DEMO11_TILE, _dirs));

    demo11_build_level(_g);
    return _g;
}

function demo11_send(_obj, _col, _row) { // all three to the same cell, so the routes can be compared
    var _p = gmnav_grid_node_to_world(_obj.grid_free,
                 gmnav_grid_node(_obj.grid_free, _col, _row));

    gmnav_agent_goto(_obj.agent_free, _p[0], _p[1]);
    gmnav_agent_goto(_obj.agent_four, _p[0], _p[1]);
    gmnav_agent_goto(_obj.agent_oct,  _p[0], _p[1]);
}

function demo11_reset(_obj) {
    var _p = gmnav_grid_node_to_world(_obj.grid_free,
                 gmnav_grid_node(_obj.grid_free, DEMO11_START_C, DEMO11_START_R));

    var _a = [_obj.agent_free, _obj.agent_four, _obj.agent_oct];

    for (var i = 0; i < 3; i++) {
        gmnav_agent_stop(_a[i]);
        _a[i].x = _p[0];
        _a[i].y = _p[1];
    }
}

function demo11_draw_path(_agent, _col) {
    var _p = _agent.path;
    if (_p == undefined || _p.count < 2) return;

    draw_set_color(_col);

    for (var i = 0; i < _p.count - 1; i++) {
        draw_line_width(_p.px[i], _p.py[i], _p.px[i + 1], _p.py[i + 1], 2);
    }

    for (var j = 0; j < _p.count; j++) {
        draw_circle(_p.px[j], _p.py[j], 3, false);
    }
}

function demo11_waypoints(_agent) {
    return (_agent.path == undefined) ? 0 : _agent.path.count;
}