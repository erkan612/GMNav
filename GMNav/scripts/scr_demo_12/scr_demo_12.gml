#macro DEMO12_W      30
#macro DEMO12_H      20
#macro DEMO12_TILE   32

#macro DEMO12_START_C  2
#macro DEMO12_START_R 10
#macro DEMO12_GOAL_C  27
#macro DEMO12_GOAL_R  10

function demo12_build_level(_grid) {
    gmnav_grid_fill_blocked(_grid, 0, 0, DEMO12_W - 1, 0, true);
    gmnav_grid_fill_blocked(_grid, 0, DEMO12_H - 1, DEMO12_W - 1, DEMO12_H - 1, true);
    gmnav_grid_fill_blocked(_grid, 0, 0, 0, DEMO12_H - 1, true);
    gmnav_grid_fill_blocked(_grid, DEMO12_W - 1, 0, DEMO12_W - 1, DEMO12_H - 1, true);

	/*
    * a slalom, so the route is all corners and the curve modes have something
    * to work on. The pinch at the end is deliberately tight enough that a wide
    * curve cannot fit and has to fall back to the sharp turn
	*/
    gmnav_grid_fill_blocked(_grid,  7,  0,  9, 11, true);
    gmnav_grid_fill_blocked(_grid, 14,  8, 16, 19, true);
    gmnav_grid_fill_blocked(_grid, 21,  0, 23,  8, true);
    gmnav_grid_fill_blocked(_grid, 21, 12, 23, 19, true);
}

function demo12_make_grid() {
    var _g = gmnav_grid_create(DEMO12_W, DEMO12_H,
                 gmnav_layout_create(gmnav_layout.ORTHO, DEMO12_TILE, DEMO12_TILE));

    demo12_build_level(_g);
    return _g;
}

function demo12_send(_obj, _col, _row) {
    var _p = gmnav_grid_node_to_world(_obj.grid, gmnav_grid_node(_obj.grid, _col, _row));

    gmnav_agent_goto(_obj.agent_sharp,  _p[0], _p[1]);
    gmnav_agent_goto(_obj.agent_corner, _p[0], _p[1]);
    gmnav_agent_goto(_obj.agent_spline, _p[0], _p[1]);
}

function demo12_reset(_obj) {
    var _p = gmnav_grid_node_to_world(_obj.grid,
                 gmnav_grid_node(_obj.grid, DEMO12_START_C, DEMO12_START_R));

    var _a = [_obj.agent_sharp, _obj.agent_corner, _obj.agent_spline];

    for (var i = 0; i < 3; i++) {
        gmnav_agent_stop(_a[i]);
        _a[i].x = _p[0];
        _a[i].y = _p[1];
    }
}

function demo12_retune(_obj) { // the curve settings changed, so the paths are rebuilt from the same goal
    _obj.agent_corner.curve_radius = _obj.radius;
    _obj.agent_corner.curve_steps  = _obj.steps;
    _obj.agent_spline.curve_radius = _obj.radius;
    _obj.agent_spline.curve_steps  = _obj.steps;

    demo12_send(_obj, _obj.goal_c, _obj.goal_r);
}

function demo12_draw_path(_agent, _col, _dots) {
    var _p = _agent.path;
    if (_p == undefined || _p.count < 2) return;

    draw_set_color(_col);

    for (var i = 0; i < _p.count - 1; i++) {
        draw_line_width(_p.px[i], _p.py[i], _p.px[i + 1], _p.py[i + 1], 2);
    }

    if (!_dots) return;

    for (var j = 0; j < _p.count; j++) {
        draw_circle(_p.px[j], _p.py[j], 2, false);
    }
}

function demo12_points(_agent) {
    return (_agent.path == undefined) ? 0 : _agent.path.count;
}