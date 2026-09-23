#macro DEMO16_W        26
#macro DEMO16_H        18
#macro DEMO16_TILE     32

#macro DEMO16_PER_SIDE 10
#macro DEMO16_N        (DEMO16_PER_SIDE * 2)

#macro DEMO16_AHEAD    3
#macro DEMO16_HERE     3
#macro DEMO16_DANGER   40
#macro DEMO16_REPATH   30

function demo16_build_level(_grid) {
    // border
    gmnav_grid_fill_blocked(_grid, 0, 0, DEMO16_W - 1, 0, true);
    gmnav_grid_fill_blocked(_grid, 0, DEMO16_H - 1, DEMO16_W - 1, DEMO16_H - 1, true);
    gmnav_grid_fill_blocked(_grid, 0, 0, 0, DEMO16_H - 1, true);
    gmnav_grid_fill_blocked(_grid, DEMO16_W - 1, 0, DEMO16_W - 1, DEMO16_H - 1, true);

    // central wall
    for (var _r = 1; _r < DEMO16_H - 1; _r++) {
        if (_r >= 6 && _r <= 7) continue;
        if (_r >= 9 && _r <= 10) continue;
        gmnav_grid_set_blocked(_grid, 12, _r, true);
        gmnav_grid_set_blocked(_grid, 13, _r, true);
    }
}

function demo16_make_grid() {
    var _lay = gmnav_layout_create(gmnav_layout.ORTHO, DEMO16_TILE, DEMO16_TILE);

    _lay.origin_x = 420;
    _lay.origin_y = 80;

    var _g = gmnav_grid_create(DEMO16_W, DEMO16_H, _lay);
    demo16_build_level(_g);
    return _g;
}

function demo16_agent_side(_i) { // agents 0 to PER_SIDE-1 spawn left, the rest spawn right
    return (_i < DEMO16_PER_SIDE) ? 0 : 1;
}

function demo16_spawn_cell(_i) {
    var _side = demo16_agent_side(_i);
    var _li   = (_side == 0) ? _i : _i - DEMO16_PER_SIDE;

    var _c = (_side == 0) ? (2 + (_li mod 2))
                          : (DEMO16_W - 3 - (_li mod 2));

    var _r = 4 + (_li div 2);

    return [_c, _r];
}

function demo16_goal_cell(_i) { // goal is the opposite side, mirrored index
    var _side = 1 - demo16_agent_side(_i);
    var _li   = (_side == 0) ? (0 - 1) : 0; // placeholder
    var _index = (_i < DEMO16_PER_SIDE) ? _i : _i - DEMO16_PER_SIDE;

    var _c = (_side == 0) ? (2 + (_index mod 2))
                          : (DEMO16_W - 3 - (_index mod 2));

    var _r = 4 + (_index div 2);

    return [_c, _r];
}

function demo16_world_of_cell(_grid, _cr) {
    var _n = gmnav_grid_node(_grid, _cr[0], _cr[1]);
    return gmnav_grid_node_to_world(_grid, _n);
}

function demo16_blocked_at(_grid, _x, _y, _rad) { // point in a wall
    var _tl = gmnav_layout_world_to_cell(_grid.layout, _x - _rad, _y - _rad);
    var _br = gmnav_layout_world_to_cell(_grid.layout, _x + _rad, _y + _rad);

    for (var _c = _tl[0]; _c <= _br[0]; _c++) {
        for (var _r = _tl[1]; _r <= _br[1]; _r++) {
            var _n = gmnav_grid_node(_grid, _c, _r);
            if (_n == GMNAV_NO_NODE) return true;
            if (gmnav_grid_is_blocked(_grid, _n)) return true;
        }
    }
    return false;
}

function demo16_move(_grid, _a) {
    var _nx = _a.x + _a.vx;
    if (demo16_blocked_at(_grid, _nx, _a.y, _a.radius)) _a.vx = 0;
    else _a.x = _nx;

    var _ny = _a.y + _a.vy;
    if (demo16_blocked_at(_grid, _a.x, _ny, _a.radius)) _a.vy = 0;
    else _a.y = _ny;
}

function demo16_write_cell(_layer, _node, _val) {
    if (_node == GMNAV_NO_NODE) return;
    if (gmnav_costlayer_get_node(_layer, _node) >= _val) return;
    gmnav_costlayer_set_node(_layer, _node, _val);
}

function demo16_stamp_crowd(_obj) { // write each agent's current cell, plus the stored danger spots
    var _layer = _obj.crowd_layer;
    var _grid  = _obj.grid;
    var _n     = array_length(_obj.agents);

    var _mc1 = 99999, _mr1 = 99999, _mc2 = -99999, _mr2 = -99999;

    for (var i = 0; i < _n; i++) {
        var _a  = _obj.agents[i];
        var _cn = gmnav_grid_world_to_node(_grid, _a.x, _a.y);

        if (_cn == GMNAV_NO_NODE) continue;

        demo16_write_cell(_layer, _cn, DEMO16_HERE);

        var _c = gmnav_grid_col(_grid, _cn);
        var _r = gmnav_grid_row(_grid, _cn);
        if (_c < _mc1) _mc1 = _c;
        if (_c > _mc2) _mc2 = _c;
        if (_r < _mr1) _mr1 = _r;
        if (_r > _mr2) _mr2 = _r;
    }

    var _d = _obj.danger_cells;

    for (var i = 0; i < array_length(_d); i++) {
        demo16_write_cell(_layer, _d[i], DEMO16_DANGER);

        var _dc = gmnav_grid_col(_grid, _d[i]);
        var _dr = gmnav_grid_row(_grid, _d[i]);
        if (_dc < _mc1) _mc1 = _dc;
        if (_dc > _mc2) _mc2 = _dc;
        if (_dr < _mr1) _mr1 = _dr;
        if (_dr > _mr2) _mr2 = _dr;
    }

    if (_mc2 < 0) return [0, 0, -1, -1];
    return [_mc1, _mr1, _mc2, _mr2];
}

function demo16_urgency_profile(_obj, _a) {
    if (_a.urgency < 0.33) return _obj.prof_patient;
    if (_a.urgency > 0.66) return _obj.prof_rush;
    return _obj.prof_normal;
}

function demo16_rebuild_crowd(_obj) { // clear old footprint, stamp new, bake union region
    var _layer = _obj.crowd_layer;
    var _old   = _obj.stamp_rect;

    if (_old[2] >= 0) {
        gmnav_costlayer_clear_region(_layer, _old[0], _old[1], _old[2], _old[3]);
    }

    var _new = demo16_stamp_crowd(_obj);
    _obj.stamp_rect = _new;

    if (_new[2] < 0) return;

    var _u_c1, _u_r1, _u_c2, _u_r2;

    if (_old[2] >= 0) {
        _u_c1 = min(_old[0], _new[0]);
        _u_r1 = min(_old[1], _new[1]);
        _u_c2 = max(_old[2], _new[2]);
        _u_r2 = max(_old[3], _new[3]);
    } else {
        _u_c1 = _new[0]; _u_r1 = _new[1];
        _u_c2 = _new[2]; _u_r2 = _new[3];
    }

    gmnav_costprofile_bake_region(_obj.prof_patient, _u_c1, _u_r1, _u_c2, _u_r2);
    gmnav_costprofile_bake_region(_obj.prof_normal,  _u_c1, _u_r1, _u_c2, _u_r2);
    gmnav_costprofile_bake_region(_obj.prof_rush,    _u_c1, _u_r1, _u_c2, _u_r2);
}

function demo16_path_is_crowded(_a, _layer, _limit) { // is the remaining path picking up enough crowd cost to be worth re-planning
    if (!gmnav_agent_has_path(_a)) return true;

    var _grid = _a.grid;
    var _path = _a.path;
    var _n    = _path.count;

    var _sum = 0;

    for (var i = _a.seek_i; i < _n; i++) {
        var _nn = gmnav_grid_world_to_node(_grid, _path.px[i], _path.py[i]);
        if (_nn == GMNAV_NO_NODE) continue;

        _sum += gmnav_costlayer_get_node(_layer, _nn);
        if (_sum >= _limit) return true;
    }
    return false;
}

function demo16_apply_avoid(_obj) {
    var _n = array_length(_obj.agents);

    for (var i = 0; i < _n; i++) {
        _obj.agents[i].avoid_mode = _obj.avoid_mode_idx;
        _obj.agents[i].avoid_str  = _obj.avoid_on ? 1.0 : 0.0;
    }
}

function demo16_send(_obj, _i) { // (re)send one agent to its goal
    var _a  = _obj.agents[_i];
    var _gc = demo16_goal_cell(_i);
    var _gp = demo16_world_of_cell(_obj.grid, _gc);

    _a.profile = demo16_urgency_profile(_obj, _a);

    gmnav_util_send_agent(_a, _obj.grid, _gp[0], _gp[1]);
}

function demo16_reset_all(_obj) { // everyone back to their spawn and re-sent
    var _n = array_length(_obj.agents);

    for (var i = 0; i < _n; i++) {
        var _sc = demo16_spawn_cell(i);
        var _sp = demo16_world_of_cell(_obj.grid, _sc);

        gmnav_util_reset_agent(_obj.agents[i], _obj.grid, _sp[0], _sp[1]);

        _obj.agents[i].urgency = clamp(_obj.urgency_base + random_range(-0.35, 0.35), 0, 1);
    }

    for (var i = 0; i < _n; i++) demo16_send(_obj, i);
}

function demo16_apply_urgency(_obj) { // new urgency on every agent, re-request in flight
    var _n = array_length(_obj.agents);

    for (var i = 0; i < _n; i++) {
        var _a = _obj.agents[i];
        _a.urgency = clamp(_obj.urgency_base + random_range(-0.35, 0.35), 0, 1);
        _a.profile = demo16_urgency_profile(_obj, _a);

        if (_a.has_goal) {
            gmnav_agent_goto(_a, _a.goal_x, _a.goal_y,
                             gmnav_priority.NORMAL, _a.goal_layer);
        }
    }
}