function gmt_reset() {
    global.gmt_pass = 0;
    global.gmt_fail = 0;
}

function gmt_head(_name) {
    show_debug_message("");
    show_debug_message("=== " + _name + " ===");
}

function gmt_note(_label, _v = "") {
    show_debug_message("    . " + _label + (_v == "" ? "" : " = " + string(_v)));
}

function gmt_arr_str(_a) {
    var _s = "";
    for (var i = 0; i < array_length(_a); i++) {
        if (i > 0) _s += ",";
        _s += string(_a[i]);
    }
    return "[" + _s + "]";
}

function gmt_check(_label, _actual, _expected) {
    var _ok = (_actual == _expected);
    if (_ok) global.gmt_pass++; else global.gmt_fail++;
    show_debug_message((_ok ? "  ok   " : "  FAIL ") + _label + " = " + string(_actual)
                     + (_ok ? "" : "   expected " + string(_expected)));
    return _ok;
}

function gmt_check_f(_label, _actual, _expected, _tol = 0.0001) {
    var _ok = (abs(_actual - _expected) <= _tol);
    if (_ok) global.gmt_pass++; else global.gmt_fail++;
    show_debug_message((_ok ? "  ok   " : "  FAIL ") + _label + " = " + string_format(_actual, 1, 6)
                     + (_ok ? "" : "   expected " + string_format(_expected, 1, 6)));
    return _ok;
}

function gmt_check_arr(_label, _actual, _expected) {
    var _as = gmt_arr_str(_actual);
    var _es = gmt_arr_str(_expected);
    var _ok = (_as == _es);
    if (_ok) global.gmt_pass++; else global.gmt_fail++;
    show_debug_message((_ok ? "  ok   " : "  FAIL ") + _label + " = " + _as
                     + (_ok ? "" : "   expected " + _es));
    return _ok;
}

function gmt_summary() {
    show_debug_message("");
    show_debug_message("########## " + string(global.gmt_pass) + " passed, "
                     + string(global.gmt_fail) + " failed ##########");
}

function gmt_open5() {
    return gmnav_grid_create(5, 5, gmnav_layout_create(gmnav_layout.ORTHO, 32, 32));
}

function gmt_maze() {
    var _g = gmnav_grid_create(5, 5, gmnav_layout_create(gmnav_layout.ORTHO, 32, 32));
    for (var _r = 0; _r <= 3; _r++) gmnav_grid_set_blocked(_g, 2, _r, true);
    return _g;
}

function gmt_doors() {
    var _g = gmnav_grid_create(11, 11, gmnav_layout_create(gmnav_layout.ORTHO, 32, 32));
    gmnav_grid_fill_blocked(_g, 5, 0, 5, 10, true);
    gmnav_grid_set_blocked(_g, 5, 2, false);
    for (var _r = 6; _r <= 8; _r++) gmnav_grid_set_blocked(_g, 5, _r, false);
    return _g;
}

function gmt_mover(_bias = 1.15) {
    return gmnav_movement_create(0.5, 6, 3, 8, 12, 24, undefined, 3, _bias);
}

function gmt_gap_level(_w, _gap) {
    var _g = gmnav_grid_create(_w, 8, gmnav_layout_create(gmnav_layout.ORTHO, 16, 16));
    gmnav_grid_fill_blocked(_g, 0, 7, 4, 7, true);
    gmnav_grid_fill_blocked(_g, 5 + _gap, 7, _w - 1, 7, true);
    return _g;
}

function gmt_shelf_level() {
    var _g = gmnav_grid_create(16, 12, gmnav_layout_create(gmnav_layout.ORTHO, 16, 16));
    gmnav_grid_fill_blocked(_g, 0, 4, 5, 4, true);
    gmnav_grid_fill_blocked(_g, 6, 10, 15, 10, true);
    return _g;
}

function gmt_count_links(_pg, _type) {
    var _n = 0;
    for (var i = 0; i < array_length(_pg.edge_type); i++) {
        if (_pg.edge_type[i] == _type) _n++;
    }
    return _n;
}

function gmt_has_link(_links, _type) {
    for (var i = 0; i < array_length(_links); i++) {
        if (_links[i] == _type) return true;
    }
    return false;
}

function gmt_door_row(_grid, _path) {
    var _w = _grid.width;
    for (var i = 0; i < array_length(_path); i++) {
        if (_path[i] % _w == 5) return _path[i] div _w;
    }
    return -1;
}

function gmt_field_walk_failures(_grid, _field) {
    var _lay = _grid.layout;
    var _w   = _grid.width;
    var _h   = _grid.height;
    var _fail = 0;

    for (var _c0 = 0; _c0 < _w; _c0++) {
        for (var _r0 = 0; _r0 < _h; _r0++) {
            var _start = gmnav_grid_node(_grid, _c0, _r0);
            if (gmnav_grid_is_blocked(_grid, _start)) continue;
            if (!gmnav_flowfield_is_reachable(_field,
                    gmnav_layout_cell_x(_lay, _c0, _r0),
                    gmnav_layout_cell_y(_lay, _c0, _r0))) continue;

            var _cur  = _start;
            var _hops = 0;
            var _ok   = false;

            while (_hops < 256) {
                var _cc = _cur % _w;
                var _cr = _cur div _w;
                var _cd = _field.dist[_cur];

                if (_cd <= 0) { _ok = true; break; }

                var _fx = gmnav_layout_cell_x(_lay, _cc, _cr);
                var _fy = gmnav_layout_cell_y(_lay, _cc, _cr);
                var _dv = gmnav_flowfield_sample(_field, _fx, _fy);
                if (_dv[0] == 0 && _dv[1] == 0) break;

                var _p     = gmnav_layout_cell_parity(_lay, _cc, _cr);
                var _base  = _p * _lay.nb_count;
                var _check = (_lay.parity_axis == 0) && (_lay.nb_count == 8);

                var _best = GMNAV_NO_NODE;
                var _bdot = -2;

                for (var k = 0; k < _lay.nb_count; k++) {
                    var _dc = _lay.nb_dc[_base + k];
                    var _dr = _lay.nb_dr[_base + k];
                    var _nc = _cc + _dc;
                    var _nr = _cr + _dr;
                    if (_nc < 0 || _nr < 0 || _nc >= _w || _nr >= _h) continue;

                    var _nn = _nr * _w + _nc;
                    if (gmnav_grid_is_blocked(_grid, _nn)) continue;
                    if (_field.dist[_nn] >= _cd) continue;

                    if (_check && _dc != 0 && _dr != 0) {
                        if (gmnav_grid_is_blocked(_grid, _cr * _w + _nc)) continue;
                        if (gmnav_grid_is_blocked(_grid, _nr * _w + _cc)) continue;
                    }

                    var _tx = gmnav_layout_cell_x(_lay, _nc, _nr) - _fx;
                    var _ty = gmnav_layout_cell_y(_lay, _nc, _nr) - _fy;
                    var _m  = point_distance(0, 0, _tx, _ty);
                    if (_m <= 0) continue;

                    var _dot = (_tx / _m) * _dv[0] + (_ty / _m) * _dv[1];
                    if (_dot > _bdot) { _bdot = _dot; _best = _nn; }
                }

                if (_best == GMNAV_NO_NODE) break;   // no descent available
                if (_bdot <= 0) break;               // vector points away from descent

                _cur = _best;
                _hops++;
            }

            if (!_ok) _fail++;
        }
    }
    return _fail;
}

function gmt_clearance_bruteforce(_grid, _col, _row, _cap = 6) {
    var _best = 0;
    for (var _k = 1; _k <= _cap; _k++) {
        var _fits = true;
        for (var _c = _col - (_k - 1); _c <= _col + (_k - 1) && _fits; _c++) {
            for (var _r = _row - (_k - 1); _r <= _row + (_k - 1); _r++) {
                var _n = gmnav_grid_node(_grid, _c, _r);
                if (_n == GMNAV_NO_NODE || gmnav_grid_is_blocked(_grid, _n)) { _fits = false; break; }
            }
        }
        if (!_fits) break;
        _best = _k;
    }
    return _best;
}

function gmt_run_agent(_agent, _max_frames = 600, _neighbours = undefined) {
    var _f = 0;
    var _had = false;

    while (_f < _max_frames) {
        _f++;
        gmnav_agent_update(_agent, _neighbours);
        _agent.x += _agent.vx;
        _agent.y += _agent.vy;

        if (gmnav_agent_has_path(_agent)) _had = true;
        else if (_had) return _f;
    }
    return -1;
}

function gmt_agent_dist(_agent, _x, _y) {
    return point_distance(_agent.x, _agent.y, _x, _y);
}

function gmt_corridor() {
    return gmnav_grid_create(9, 5, gmnav_layout_create(gmnav_layout.ORTHO, 32, 32));
}

function gmt_path_cost(_grid, _profile, _path) {
    var _c = (_profile == undefined) ? _grid.cost : _profile.resolved;
    var _t = 0;
    for (var i = 1; i < array_length(_path); i++) _t += _c[_path[i]];
    return _t;
}

function gmt_path_visits(_grid, _path, _col, _row) {
    var _n = gmnav_grid_node(_grid, _col, _row);
    for (var i = 0; i < array_length(_path); i++) {
        if (_path[i] == _n) return true;
    }
    return false;
}

function gmt_layout_grid(_mode, _w = 10, _h = 10) {
    return gmnav_grid_create(_w, _h, gmnav_layout_create(_mode, 64, 32));
}

function gmt_path_adjacency_breaks(_grid, _path) {
    var _lay = _grid.layout;
    var _w   = _grid.width;
    var _bad = 0;

    for (var i = 0; i < array_length(_path) - 1; i++) {
        var _a = _path[i], _b = _path[i + 1];
        var _ac = _a % _w, _ar = _a div _w;

        var _p = gmnav_layout_cell_parity(_lay, _ac, _ar);
        var _base = _p * _lay.nb_count;
        var _hit = false;

        for (var k = 0; k < _lay.nb_count; k++) {
            var _nc = _ac + _lay.nb_dc[_base + k];
            var _nr = _ar + _lay.nb_dr[_base + k];
            if (_nr * _w + _nc == _b) { _hit = true; break; }
        }
        if (!_hit) _bad++;
    }
    return _bad;
}

function gmt_path_blocked_count(_grid, _path) {
    var _n = 0;
    for (var i = 0; i < array_length(_path); i++) {
        if (gmnav_grid_is_blocked(_grid, _path[i])) _n++;
    }
    return _n;
}

function gmt_neighbour_symmetry_breaks(_grid) {
    var _lay = _grid.layout;
    var _w   = _grid.width;
    var _h   = _grid.height;
    var _bad = 0;

    for (var _c = 1; _c < _w - 1; _c++) {
        for (var _r = 1; _r < _h - 1; _r++) {
            var _p    = gmnav_layout_cell_parity(_lay, _c, _r);
            var _base = _p * _lay.nb_count;

            for (var k = 0; k < _lay.nb_count; k++) {
                var _nc = _c + _lay.nb_dc[_base + k];
                var _nr = _r + _lay.nb_dr[_base + k];
                if (_nc < 0 || _nr < 0 || _nc >= _w || _nr >= _h) continue;

                var _np = gmnav_layout_cell_parity(_lay, _nc, _nr);
                var _nb = _np * _lay.nb_count;
                var _back = false;

                for (var j = 0; j < _lay.nb_count; j++) {
                    if (_nc + _lay.nb_dc[_nb + j] == _c
                    &&  _nr + _lay.nb_dr[_nb + j] == _r) { _back = true; break; }
                }
                if (!_back) _bad++;
            }
        }
    }
    return _bad;
}

function gmt_neighbour_span(_grid) {
    var _lay = _grid.layout;
    var _max = 0;

    for (var _c = 2; _c < _grid.width - 2; _c++) {
        for (var _r = 2; _r < _grid.height - 2; _r++) {
            var _p    = gmnav_layout_cell_parity(_lay, _c, _r);
            var _base = _p * _lay.nb_count;

            var _fx = gmnav_layout_cell_x(_lay, _c, _r);
            var _fy = gmnav_layout_cell_y(_lay, _c, _r);

            for (var k = 0; k < _lay.nb_count; k++) {
                var _nc = _c + _lay.nb_dc[_base + k];
                var _nr = _r + _lay.nb_dr[_base + k];
                var _d  = point_distance(_fx, _fy,
                                         gmnav_layout_cell_x(_lay, _nc, _nr),
                                         gmnav_layout_cell_y(_lay, _nc, _nr));
                if (_d > _max) _max = _d;
            }
        }
    }
    return _max;
}

function gmt_dijkstra_costs(_grid) {
    var _n = _grid.count;
    var _c = array_create(_n, GMNAV_INF);
    return _c;
}

function gmt_big_open() {
    return gmnav_grid_create(15, 15, gmnav_layout_create(gmnav_layout.ORTHO, 32, 32));
}

function gmt_step_until_done(_srch, _budget = 20, _max_steps = 500) {
    for (var i = 1; i <= _max_steps; i++) {
        if (gmnav_search_step(_srch, _budget) != gmnav_state.WORKING) return i;
    }
    return -1;
}

function gmt_drain_scheduler(_sched, _tickets, _max_frames = 500) {
    for (var _f = 1; _f <= _max_frames; _f++) {
        gmnav_scheduler_update(_sched);

        var _all = true;
        for (var i = 0; i < array_length(_tickets); i++) {
            var _s = _tickets[i].state;
            if (_s == gmnav_state.IDLE || _s == gmnav_state.WORKING) { _all = false; break; }
        }
        if (_all) return _f;
    }
    return -1;
}