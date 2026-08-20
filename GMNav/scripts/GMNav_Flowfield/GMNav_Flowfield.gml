function gmnav_flowfield_create(_grid, _profile = undefined) {
    var _n = _grid.count;

    return {
        grid     : _grid,
        profile  : _profile,

        dist     : array_create(_n, GMNAV_INF),
        dirx     : array_create(_n, 0),
        diry     : array_create(_n, 0),
        mark     : array_create(_n, 0),

        gen      : 0,
        heap     : gmnav_heap_create(),

        state    : gmnav_state.IDLE,
        goals    : [],
        version  : -1,
        vec_at   : 0,            // vector pass cursor
        max_dist : GMNAV_INF     // stop expanding past this distance
    };
}

function gmnav_flowfield_begin(_field, _goal_nodes, _max_dist = GMNAV_INF) {
    var _grid = _field.grid;

    if (!is_array(_goal_nodes)) _goal_nodes = [_goal_nodes];

    _field.gen++;
    _field.goals    = _goal_nodes;
    _field.version  = _grid.version;
    _field.max_dist = _max_dist;
    _field.vec_at   = 0;
    _field.state    = gmnav_state.WORKING;

    gmnav_heap_clear(_field.heap);

    var _any = false;

    for (var i = 0; i < array_length(_goal_nodes); i++) {
        var _g = _goal_nodes[i];
        if (_g == GMNAV_NO_NODE) continue;
        if (gmnav_grid_is_blocked(_grid, _g)) continue;

        _field.dist[_g] = 0;
        _field.mark[_g] = _field.gen;
        gmnav_heap_push(_field.heap, 0, 0, _g);
        _any = true;
    }

    if (!_any) {
        _field.state = gmnav_state.FAILED;
        return false;
    }
    return true;
}

function gmnav_flowfield_step(_field, _budget = GMNAV_DEFAULT_BUDGET) {
    if (_field.state != gmnav_state.WORKING) return _field.state;

    var _left = __gmnav_field_expand(_field, _budget);

    if (_field.state == gmnav_state.WORKING && _field.heap.count == 0 && _left > 0) {
        __gmnav_field_vectors(_field, _left);
    }
    return _field.state;
}

function gmnav_flowfield_build(_field, _goal_nodes, _max_dist = GMNAV_INF) {
    if (!gmnav_flowfield_begin(_field, _goal_nodes, _max_dist)) return false;

    var _guard = 0;
    while (_field.state == gmnav_state.WORKING) {
        gmnav_flowfield_step(_field, GMNAV_DEFAULT_BUDGET);
        if (++_guard > GMNAV_MAX_STEPS) break;
    }
    return (_field.state == gmnav_state.FOUND);
}

function gmnav_flowfield_is_ready(_field) {
    return (_field.state == gmnav_state.FOUND);
}

function gmnav_flowfield_is_stale(_field) {
    return (_field.grid.version != _field.version);
}

function gmnav_flowfield_sample(_field, _x, _y) {
    var _n = gmnav_grid_world_to_node(_field.grid, _x, _y);
    if (_n == GMNAV_NO_NODE) return [0, 0];
    return [_field.dirx[_n], _field.diry[_n]];
}

function gmnav_flowfield_cost_at(_field, _x, _y) {
    var _n = gmnav_grid_world_to_node(_field.grid, _x, _y);
    if (_n == GMNAV_NO_NODE) return GMNAV_INF;

    var _m = _field.mark[_n];
    if (_m != _field.gen && _m != -_field.gen) return GMNAV_INF;

    return _field.dist[_n];
}

function gmnav_flowfield_is_reachable(_field, _x, _y) {
    var _n = gmnav_grid_world_to_node(_field.grid, _x, _y);
    if (_n == GMNAV_NO_NODE) return false;

    var _m = _field.mark[_n];
    return (_m == _field.gen || _m == -_field.gen);
}

function __gmnav_field_expand(_field, _budget) {
    var _grid = _field.grid;
    var _lay  = _grid.layout;
    var _heap = _field.heap;

    var _dist = _field.dist;
    var _mark = _field.mark;
    var _gen  = _field.gen;
    var _cgen = -_gen;

    var _flags = _grid.flags;
    var _cost  = (_field.profile != undefined) ? _field.profile.resolved : _grid.cost;
    var _w     = _grid.width;
    var _h     = _grid.height;

    var _nbc = _lay.nb_count;
    var _ndc = _lay.nb_dc;
    var _ndr = _lay.nb_dr;
    var _ncs = _lay.nb_cost;
    var _pax = _lay.parity_axis;

    var _cap   = _field.max_dist;
    var _check = (_pax == 0) && (_nbc == 8);
    var _left  = _budget;

    while (_left > 0) {
        if (_heap.count == 0) return _left;

        _left--;

        var _cur = gmnav_heap_pop(_heap);
        if (_mark[_cur] == _cgen) continue;
        _mark[_cur] = _cgen;

        var _cc = _cur % _w;
        var _cr = _cur div _w;
        var _cd = _dist[_cur];

        if (_cd >= _cap) continue;

        var _p = 0;
        if (_pax == 1)      _p = gmnav_parity(_cr);
        else if (_pax == 2) _p = gmnav_parity(_cc);
        var _base = _p * _nbc;

        for (var i = 0; i < _nbc; i++) {
            var _idx = _base + i;
            var _dc  = _ndc[_idx];
            var _dr  = _ndr[_idx];
            var _nc  = _cc + _dc;
            var _nr  = _cr + _dr;

            if (_nc < 0 || _nr < 0 || _nc >= _w || _nr >= _h) continue;

            var _nn = _nr * _w + _nc;
            if (_mark[_nn] == _cgen) continue;
            if ((_flags[_nn] & GMNAV_FLAG_BLOCKED) != 0) continue;

            if (_check && _dc != 0 && _dr != 0) {
                if ((_flags[_cr * _w + _nc] & GMNAV_FLAG_BLOCKED) != 0) continue;
                if ((_flags[_nr * _w + _cc] & GMNAV_FLAG_BLOCKED) != 0) continue;
            }

            var _nd = _cd + _ncs[_idx] * _cost[_nn];
            if (_nd > _cap) continue;
            if (_mark[_nn] == _gen && _nd >= _dist[_nn]) continue;

            _dist[_nn] = _nd;
            _mark[_nn] = _gen;
            gmnav_heap_push(_heap, _nd, 0, _nn);
        }
    }
    return 0;
}

function __gmnav_field_vectors(_field, _budget) {
    var _grid = _field.grid;
    var _lay  = _grid.layout;

    var _dist = _field.dist;
    var _mark = _field.mark;
    var _dirx = _field.dirx;
    var _diry = _field.diry;
    var _gen  = _field.gen;
    var _cgen = -_gen;

    var _flags = _grid.flags;
    var _w     = _grid.width;
    var _h     = _grid.height;
    var _total = _grid.count;

    var _nbc = _lay.nb_count;
    var _ndc = _lay.nb_dc;
    var _ndr = _lay.nb_dr;
    var _pax = _lay.parity_axis;
    var _check = (_pax == 0) && (_nbc == 8);

    var _i   = _field.vec_at;
    var _end = min(_total, _i + _budget);

    while (_i < _end) {
        if (_mark[_i] != _gen && _mark[_i] != _cgen) {
            _dirx[_i] = 0;
            _diry[_i] = 0;
            _i++;
            continue;
        }

        var _cc = _i % _w;
        var _cr = _i div _w;

        var _p = 0;
        if (_pax == 1)      _p = gmnav_parity(_cr);
        else if (_pax == 2) _p = gmnav_parity(_cc);
        var _base = _p * _nbc;

        var _best  = _dist[_i];
        var _bc    = -1;
        var _br    = -1;

        for (var k = 0; k < _nbc; k++) {
            var _idx = _base + k;
            var _dc  = _ndc[_idx];
            var _dr  = _ndr[_idx];
            var _nc  = _cc + _dc;
            var _nr  = _cr + _dr;

            if (_nc < 0 || _nr < 0 || _nc >= _w || _nr >= _h) continue;

            var _nn = _nr * _w + _nc;
            if (_mark[_nn] != _gen && _mark[_nn] != _cgen) continue;
            if ((_flags[_nn] & GMNAV_FLAG_BLOCKED) != 0) continue;

            if (_check && _dc != 0 && _dr != 0) {
                if ((_flags[_cr * _w + _nc] & GMNAV_FLAG_BLOCKED) != 0) continue;
                if ((_flags[_nr * _w + _cc] & GMNAV_FLAG_BLOCKED) != 0) continue;
            }

            if (_dist[_nn] < _best) {
                _best = _dist[_nn];
                _bc   = _nc;
                _br   = _nr;
            }
        }

        if (_bc < 0) {
            _dirx[_i] = 0;
            _diry[_i] = 0;
        } else {
            var _fx = gmnav_layout_cell_x(_lay, _cc, _cr);
            var _fy = gmnav_layout_cell_y(_lay, _cc, _cr);
            var _tx = gmnav_layout_cell_x(_lay, _bc, _br);
            var _ty = gmnav_layout_cell_y(_lay, _bc, _br);

            var _dx = _tx - _fx;
            var _dy = _ty - _fy;
            var _m  = point_distance(0, 0, _dx, _dy);

            if (_m > 0.0001) {
                _dirx[_i] = _dx / _m;
                _diry[_i] = _dy / _m;
            } else {
                _dirx[_i] = 0;
                _diry[_i] = 0;
            }
        }

        _i++;
    }

    _field.vec_at = _i;
    if (_i >= _total) _field.state = gmnav_state.FOUND;
}