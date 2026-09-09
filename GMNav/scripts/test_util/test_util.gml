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

function gmt_oneway_level() {
    var _g = gmnav_grid_create(24, 14, gmnav_layout_create(gmnav_layout.ORTHO, 16, 16));

    gmnav_grid_fill_blocked(_g, 0,  0,  23, 0,  true);
    gmnav_grid_fill_blocked(_g, 0,  13, 23, 13, true);
    gmnav_grid_fill_blocked(_g, 0,  0,  0,  13, true);
    gmnav_grid_fill_blocked(_g, 23, 0,  23, 13, true);

    gmnav_grid_fill_blocked(_g, 1, 11, 22, 11, true);

    for (var _c = 3; _c < 9; _c++) {
        gmnav_grid_set_flag(_g, _c, 8, GMNAV_FLAG_ONEWAY, true);
    }
    for (var _c = 15; _c < 21; _c++) {
        gmnav_grid_set_flag(_g, _c, 9, GMNAV_FLAG_ONEWAY, true);
    }

    return _g;
}

function gmt_plat_replay(_pg, _from, _vx, _vy, _type) {
    var _grid = _pg.grid;
    var _lay  = _grid.layout;
    var _mv   = _pg.move;

    var _x  = _pg.node_x[_from];
    var _y  = _pg.node_y[_from];
    var _x0 = _x;

    var _frames = 0;
    var _armed  = false;

    if (_type == gmnav_link.FALL) {
        if (_vx == 0) return GMNAV_NO_NODE;

        var _walked = 0;
        var _limit  = _lay.tile_w * global.gmnav.config.PLAT_FALL_WALK_CELLS;

        while (gmnav_platgraph_solid(_pg, _x, _y + 1, 1)) {
            if (_walked > _limit) return GMNAV_NO_NODE;
            if (gmnav_platgraph_solid(_pg, _x + _vx, _y, 0)) return GMNAV_NO_NODE;

            _x += _vx;
            _walked += abs(_vx);
            _frames++;
        }
        _armed = true;
    }

    while (_frames < global.gmnav.config.PLAT_MAX_SIM) {
        _frames++;

        _vy = min(_vy + _mv.gravity, _mv.max_fall);

        var _nx = _x + _vx;
        if (gmnav_platgraph_solid(_pg, _nx, _y, 0)) _vx = 0;
        else                                        _x  = _nx;

        var _ny = _y + _vy;
        if (gmnav_platgraph_solid(_pg, _x, _ny, _vy)) {
            if (_vy < 0) {
                _vy = 0;
                continue;
            }

            if (!_armed) return GMNAV_NO_NODE;

            var _lr = floor((_ny - _lay.origin_y) / _lay.tile_h);
            var _lc = floor((_x  - _lay.origin_x) / _lay.tile_w);

            var _stand = gmnav_grid_node(_grid, _lc, _lr - 1);
            if (_stand == GMNAV_NO_NODE) return GMNAV_NO_NODE;

            return _pg.node_of[_stand];
        }

        _y = _ny;

        if (!_armed && (_vy > 0 || abs(_x - _x0) > _lay.tile_w * 0.75)) {
            _armed = true;
        }

        if (_x < _lay.origin_x || _y < _lay.origin_y) return GMNAV_NO_NODE;
        if (_x > _lay.origin_x + _grid.width  * _lay.tile_w) return GMNAV_NO_NODE;
        if (_y > _lay.origin_y + _grid.height * _lay.tile_h) return GMNAV_NO_NODE;
    }
    return GMNAV_NO_NODE;
}

function gmt_platagent_run(_sched, _pa, _max_frames = 600) {
    for (var _f = 1; _f <= _max_frames; _f++) {
        gmnav_scheduler_update(_sched);
        gmnav_platagent_update(_pa);

        if (gmnav_platagent_arrived(_pa)) return _f;
    }
    return -1;
}

function gmt_platagent_run_watch(_sched, _pa, _out, _max_frames = 600) {
    _out.airborne = false;
    _out.fell     = false;
    _out.jumped   = false;
    _out.frames   = -1;

    for (var _f = 1; _f <= _max_frames; _f++) {
        gmnav_scheduler_update(_sched);
        gmnav_platagent_update(_pa);

        if (gmnav_platagent_airborne(_pa)) _out.airborne = true;

        if (_pa.mode == gmnav_pmode.LINK && _pa.link != undefined) {
            if (_pa.link.type == gmnav_link.FALL) _out.fell   = true;
            if (_pa.link.type == gmnav_link.JUMP) _out.jumped = true;
        }

        if (gmnav_platagent_arrived(_pa)) {
            _out.frames = _f;
            return _f;
        }
    }
    return -1;
}

function gmt_cliff_level() {
    var _g = gmnav_grid_create(22, 14, gmnav_layout_create(gmnav_layout.ORTHO, 32, 32));

    gmnav_grid_fill_height(_g, 8, 3, 13, 6, 3);

    gmnav_grid_fill_height(_g, 10, 9, 11, 9, 1);
    gmnav_grid_fill_height(_g, 10, 8, 11, 8, 2);
    gmnav_grid_fill_height(_g, 10, 7, 11, 7, 3);

    return _g;
}

function gmt_solve_z(_grid, _a, _b, _climb = undefined, _drop = undefined) {
    var _s = gmnav_search_create(_grid);

    if (!gmnav_search_begin(_s, _a, _b, false, undefined, 0, _climb, _drop)) {
        return undefined;
    }

    var _guard = 0;
    while (_s.state == gmnav_state.WORKING && _guard++ < global.gmnav.config.MAX_STEPS) {
        gmnav_search_step(_s, 4096);
    }
    return (_s.state == gmnav_state.FOUND) ? gmnav_search_get_path(_s) : undefined;
}

function gmt_path_max_dz(_grid, _path) {
    var _worst = 0;
    for (var i = 1; i < array_length(_path); i++) {
        var _dz = gmnav_grid_height(_grid, _path[i]) - gmnav_grid_height(_grid, _path[i - 1]);
        _worst = max(_worst, abs(_dz));
    }
    return _worst;
}

function gmt_path_uses_ramp(_grid, _path) {
    for (var i = 0; i < array_length(_path); i++) {
        var _c = gmnav_grid_col(_grid, _path[i]);
        var _r = gmnav_grid_row(_grid, _path[i]);
        if ((_c == 10 || _c == 11) && _r >= 7 && _r <= 9) return true;
    }
    return false;
}

function gmt_field_cost_cell(_field, _col, _row) {
    var _n = gmnav_grid_node(_field.grid, _col, _row);
    var _p = gmnav_grid_node_to_world(_field.grid, _n);
    return gmnav_flowfield_cost_at(_field, _p[0], _p[1]);
}

function gmt_field_reach_cell(_field, _col, _row) {
    var _n = gmnav_grid_node(_field.grid, _col, _row);
    var _p = gmnav_grid_node_to_world(_field.grid, _n);
    return gmnav_flowfield_is_reachable(_field, _p[0], _p[1]);
}

function gmt_field_z(_grid, _gc, _gr, _climb = undefined, _drop = undefined) {
    var _f = gmnav_flowfield_create(_grid, undefined, _climb, _drop);
    gmnav_flowfield_build(_f, [gmnav_grid_node(_grid, _gc, _gr)]);
    return _f;
}

function gmt_path_line_max_dz(_grid, _nodes) {
    for (var _lim = 0; _lim <= 32; _lim++) {
        var _ok = true;

        for (var i = 1; i < array_length(_nodes); i++) {
            if (!__gmnav_path_line_z_ok(_grid, _nodes[i - 1], _nodes[i], _lim, _lim)) {
                _ok = false;
                break;
            }
        }
        if (_ok) return _lim;
    }
    return 999;
}

function gmt_path_points_max_dz(_grid, _path) {
    var _lay   = _grid.layout;
    var _step  = _lay.tile_w * 0.5;
    var _worst = 0;

    for (var i = 1; i < _path.count; i++) {
        var _x0 = _path.px[i - 1];
        var _y0 = _path.py[i - 1];
        var _x1 = _path.px[i];
        var _y1 = _path.py[i];

        var _d = point_distance(_x0, _y0, _x1, _y1);
        var _n = max(1, ceil(_d / _step));

        var _pz = gmnav_grid_height(_grid, gmnav_grid_world_to_node(_grid, _x0, _y0));

        for (var s = 1; s <= _n; s++) {
            var _sx = lerp(_x0, _x1, s / _n);
            var _sy = lerp(_y0, _y1, s / _n);

            var _nn = gmnav_grid_world_to_node(_grid, _sx, _sy);
            if (_nn == GMNAV_NO_NODE) continue;

            var _z = gmnav_grid_height(_grid, _nn);
            _worst = max(_worst, abs(_z - _pz));
            _pz = _z;
        }
    }
    return _worst;
}

function gmt_ramp_path(_grid, _climb = 1, _drop = 1, _smooth = true) {
    var _s = gmnav_search_create(_grid);

    gmnav_search_begin(_s, gmnav_grid_node(_grid, 3, 5),
                           gmnav_grid_node(_grid, 10, 5),
                      false, undefined, 0, _climb, _drop);

    var _guard = 0;
    while (_s.state == gmnav_state.WORKING && _guard++ < global.gmnav.config.MAX_STEPS) {
        gmnav_search_step(_s, 4096);
    }

    var _p = gmnav_path_create(_grid, gmnav_search_get_path(_s));
    if (_smooth) gmnav_path_smooth(_p, _climb, _drop);
    return _p;
}

function gmt_bridge_level() {
    var _g = gmnav_grid_create(12, 12, gmnav_layout_create(gmnav_layout.ORTHO, 32, 32));

    gmnav_grid_fill_blocked(_g, 0, 4, 11, 4, true);
    gmnav_grid_fill_blocked(_g, 0, 6, 11, 6, true);

    var _ov = gmnav_overlay_create(_g);

    var _d1 = gmnav_overlay_add(_ov, 5, 4, 1);
    var _d2 = gmnav_overlay_add(_ov, 5, 5, 1);
    var _d3 = gmnav_overlay_add(_ov, 5, 6, 1);

    gmnav_overlay_link(_ov, gmnav_grid_node(_g, 5, 3), _d1, gmnav_link.STAIR, true);
    gmnav_overlay_link(_ov, _d3, gmnav_grid_node(_g, 5, 7), gmnav_link.STAIR, true);

    gmnav_overlay_finish(_ov);
    return _g;
}

function gmt_agent_run_layers(_sched, _agent, _out, _max_frames = 900) {
    _out.layers = [];
    _out.frames = -1;

    var _last = -1;

    for (var _f = 1; _f <= _max_frames; _f++) {
        gmnav_scheduler_update(_sched);
        gmnav_agent_update(_agent);

        _agent.x += _agent.vx;
        _agent.y += _agent.vy;

        var _l = gmnav_agent_layer(_agent);
        if (_l != _last) {
            array_push(_out.layers, _l);
            _last = _l;
        }

        if (gmnav_agent_arrived(_agent)) {
            _out.frames = _f;
            return _f;
        }
    }
    return -1;
}

function gmt_nb_cost(_lay, _dc, _dr) {
    for (var i = 0; i < _lay.nb_count; i++) {
        if (_lay.nb_dc[i] == _dc && _lay.nb_dr[i] == _dr) return _lay.nb_cost[i];
    }
    return -1;
}

function gmt_solve_cost(_grid, _a, _b, _climb = undefined, _drop = undefined) { // total path cost of a solve, or -1 if there is no route.
    var _s = gmnav_search_create(_grid);

    if (!gmnav_search_begin(_s, _a, _b, false, undefined, 0, _climb, _drop)) return -1;

    var _guard = 0;
    while (_s.state == gmnav_state.WORKING
        && _guard++ < global.gmnav.config.MAX_STEPS) {
        gmnav_search_step(_s, 4096);
    }
    if (_s.state != gmnav_state.FOUND) return -1;

    return _s.slot_g_final;
}

function gmt_node_height(_grid, _node) {
    var _h = gmnav_grid_node_layer(_grid, _node);

    if (_node >= _grid.count && gmnav_grid_has_overlay(_grid)) {
        _h += gmnav_overlay_offset(_grid.overlay, _node);
    }
    return _h;
}

function gmt_field_walks_to_goal(_grid, _field, _from, _goal, _max_hops = 64) { // follows field.next from a node to the goal, so a layer change is a real step rather than a guess at a vector
    var _cur  = _from;
    var _hops = 0;

    while (_hops++ < _max_hops) {
        if (_cur == _goal) return true;
        if (_cur < 0 || _cur >= array_length(_field.next)) return false;

        var _nx = _field.next[_cur];
        if (_nx == GMNAV_NO_NODE || _nx == _cur) return false;
        if (_field.dist[_nx] >= _field.dist[_cur]) return false; // must descend

        _cur = _nx;
    }
    return false;
}

function gmt_field_exits_via(_grid, _field, _from, _deck, _max_hops = 128) { // walks the field and reports whether it passes through a given node
    var _cur  = _from;
    var _hops = 0;

    while (_hops++ < _max_hops) {
        if (_cur == _deck) return true;
        if (_cur < 0 || _cur >= array_length(_field.next)) return false;

        var _nx = _field.next[_cur];
        if (_nx == GMNAV_NO_NODE || _nx == _cur) return false;

        _cur = _nx;
    }
    return false;
}

function gmt_ov_clearance_brute(_ov, _index) { // the definition, checked the slow way
    var _cap = global.gmnav.config.CLEARANCE_MAX;

    if ((_ov.flags[_index] & GMNAV_FLAG_BLOCKED) != 0) return 0;

    var _c = _ov.col[_index];
    var _r = _ov.row[_index];
    var _l = _ov.layer[_index];

    for (var _rad = 1; _rad <= _cap; _rad++) {
        for (var _dr = -(_rad - 1); _dr <= (_rad - 1); _dr++) {
            for (var _dc = -(_rad - 1); _dc <= (_rad - 1); _dc++) {
                var _nb = gmnav_overlay_node_at(_ov, _c + _dc, _r + _dr, _l);

                if (_nb == GMNAV_NO_NODE) return _rad - 1;
                if (gmnav_overlay_is_blocked(_ov, _nb)) return _rad - 1;
            }
        }
    }
    return _cap;
}

function gmt_path_keeps_layers(_grid, _path, _nodes) { // does the simplified path still touch every layer the route did
    var _want = {};
    for (var i = 0; i < array_length(_nodes); i++) {
        _want[$ string(gmnav_grid_node_layer(_grid, _nodes[i]))] = true;
    }

    var _got = {};
    for (var j = 0; j < _path.count; j++) {
        var _n = gmnav_grid_world_to_node_top(_grid, _path.px[j], _path.py[j]);
        if (_n == GMNAV_NO_NODE) continue;
        _got[$ string(gmnav_grid_node_layer(_grid, _n))] = true;
    }

    var _keys = variable_struct_get_names(_want);
    for (var k = 0; k < array_length(_keys); k++) {
        if (!variable_struct_exists(_got, _keys[k])) return false;
    }
    return true;
}

function gmt_path_visits_row(_grid, _path, _row, _c1, _c2) { // does a path cross a given row anywhere between two columns
    for (var i = 0; i < array_length(_path); i++) {
        var _n = _path[i];
        if (_n >= _grid.count) continue;

        if (gmnav_grid_row(_grid, _n) != _row) continue;

        var _c = gmnav_grid_col(_grid, _n);
        if (_c >= _c1 && _c <= _c2) return true;
    }
    return false;
}

function gmt_solve_cost_p(_grid, _a, _b, _profile) { // total path cost under a profile, or -1 if there is no route
    var _s = gmnav_search_create(_grid);

    if (!gmnav_search_begin(_s, _a, _b, false, _profile)) return -1;

    var _guard = 0;
    while (_s.state == gmnav_state.WORKING
        && _guard++ < global.gmnav.config.MAX_STEPS) {
        gmnav_search_step(_s, 4096);
    }
    if (_s.state != gmnav_state.FOUND) return -1;

    return _s.slot_g_final;
}

function gmt_solve_profile(_grid, _a, _b, _profile) { // a route under a cost profile, or undefined
    var _s = gmnav_search_create(_grid);
    if (!gmnav_search_begin(_s, _a, _b, false, _profile)) return undefined;

    var _guard = 0;
    while (_s.state == gmnav_state.WORKING
        && _guard++ < global.gmnav.config.MAX_STEPS) {
        gmnav_search_step(_s, 4096);
    }
    return (_s.state == gmnav_state.FOUND) ? gmnav_search_get_path(_s) : undefined;
}

function gmt_solve_clear(_grid, _a, _b, _need) { // a route for a unit of a given clearance, or undefined
    var _s = gmnav_search_create(_grid);
    if (!gmnav_search_begin(_s, _a, _b, false, undefined, _need)) return undefined;

    var _guard = 0;
    while (_s.state == gmnav_state.WORKING
        && _guard++ < global.gmnav.config.MAX_STEPS) {
        gmnav_search_step(_s, 4096);
    }
    return (_s.state == gmnav_state.FOUND) ? gmnav_search_get_path(_s) : undefined;
}

function gmt_agent_grid() { // a plain open room with a clear row 1 to walk along
    var _g = gmnav_grid_create(20, 16, gmnav_layout_create(gmnav_layout.ORTHO, 32, 32));
    gmnav_grid_fill_blocked(_g, 0, 0, 19, 0, true);
    gmnav_grid_fill_blocked(_g, 0, 15, 19, 15, true);
    gmnav_grid_fill_blocked(_g, 0, 0, 0, 15, true);
    gmnav_grid_fill_blocked(_g, 19, 0, 19, 15, true);
    return _g;
}

function gmt_room_grid(_w, _h, _dirs = gmnav_neighbours.EIGHT) { // an open room with square tiles, walled at the border
    var _g = gmnav_grid_create(_w, _h,
                 gmnav_layout_create(gmnav_layout.ORTHO, 32, 32, _dirs));

    gmnav_grid_fill_blocked(_g, 0, 0, _w - 1, 0, true);
    gmnav_grid_fill_blocked(_g, 0, _h - 1, _w - 1, _h - 1, true);
    gmnav_grid_fill_blocked(_g, 0, 0, 0, _h - 1, true);
    gmnav_grid_fill_blocked(_g, _w - 1, 0, _w - 1, _h - 1, true);

    return _g;
}

function gmt_path_headings_ok(_path, _dirs, _eps = 0.001) { // does every segment lie on a heading the model allows. Square tiles only, so a cell diagonal is a true 45
    for (var i = 0; i < _path.count - 1; i++) {
        var _dx = abs(_path.px[i + 1] - _path.px[i]);
        var _dy = abs(_path.py[i + 1] - _path.py[i]);

        if (_dx < _eps && _dy < _eps) continue;

        if (_dirs == 4) {
            if (_dx >= _eps && _dy >= _eps) return false;
        } else {
            if (_dx >= _eps && _dy >= _eps && abs(_dx - _dy) >= _eps) return false;
        }
    }
    return true;
}

function gmt_path_points_clear(_grid, _path, _layer = 0) { // is every point on this path standing somewhere walkable
    for (var i = 0; i < _path.count; i++) {
        var _n = gmnav_grid_world_to_node(_grid, _path.px[i], _path.py[i], _layer);
        if (_n == GMNAV_NO_NODE) return false;
        if (gmnav_grid_is_blocked(_grid, _n)) return false;
    }
    return true;
}

function gmt_path_has_point(_path, _x, _y, _eps = 0.5) {
    for (var i = 0; i < _path.count; i++) {
        if (abs(_path.px[i] - _x) < _eps && abs(_path.py[i] - _y) < _eps) return true;
    }
    return false;
}

function gmt_layer_all_inside(_layer, _rect) { // is every non zero cell inside the rect the stamp reported
    var _g = _layer.grid;
    var _v = _layer.values;

    for (var _r = 0; _r < _g.height; _r++) {
        for (var _c = 0; _c < _g.width; _c++) {
            if (_v[_r * _g.width + _c] == 0) continue;

            if (_c < _rect[0] || _c > _rect[2]) return false;
            if (_r < _rect[1] || _r > _rect[3]) return false;
        }
    }
    return true;
}

function gmt_path_cross_row(_grid, _path, _col) { // the row at which a path first reaches a column, or -1
    for (var i = 0; i < array_length(_path); i++) {
        var _n = _path[i];
        if (_n >= _grid.count) continue;

        if (gmnav_grid_col(_grid, _n) == _col) return gmnav_grid_row(_grid, _n);
    }
    return -1;
}

function gmt_arr_same(_a, _b) {
    if (!is_array(_a) || !is_array(_b)) return false;
    if (array_length(_a) != array_length(_b)) return false;

    for (var i = 0; i < array_length(_a); i++) {
        if (_a[i] != _b[i]) return false;
    }
    return true;
}

function gmt_path_line_cost(_grid, _layer, _path, _step = 8) { // what a path picks up along its drawn line, not its waypoints
    var _sum = 0;

    for (var i = 0; i < _path.count - 1; i++) {
        var _n = ceil(point_distance(_path.px[i], _path.py[i],
                                     _path.px[i + 1], _path.py[i + 1]) / _step);

        for (var s = 0; s <= _n; s++) {
            var _t  = s / max(1, _n);
            var _nx = gmnav_grid_world_to_node(_grid,
                          lerp(_path.px[i], _path.px[i + 1], _t),
                          lerp(_path.py[i], _path.py[i + 1], _t));

            if (_nx != GMNAV_NO_NODE) _sum = max(_sum, gmnav_costlayer_get_node(_layer, _nx));
        }
    }
    return _sum;
}