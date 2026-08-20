function gmnav_search_create(_grid, _heuristic = gmnav_heuristic.AUTO) {
    return {
        grid        : _grid,
        slot        : undefined,
        heap        : gmnav_heap_create(),

        state       : gmnav_state.IDLE,
        start       : GMNAV_NO_NODE,
        goal        : GMNAV_NO_NODE,
        goal_c      : 0,
        goal_r      : 0,
        goal_x      : 0,
        goal_y      : 0,

        h_mode      : gmnav_heuristic.OCTILE,
        corner_cut  : false,
		
		need_clear  : 0,
        relax       : 2,

        version     : -1,
        stale       : false,
        expansions  : 0,
        pops        : 0,
        result      : [],
        slot_g_final: 0,
        profile     : undefined,
    };
}

function gmnav_search_begin(_srch, _start_node, _goal_node, _corner_cut = false,
                            _profile = undefined, _need_clear = 0) {
    var _grid = _srch.grid;

    gmnav_search_abort(_srch);

    if (_start_node == GMNAV_NO_NODE || _goal_node == GMNAV_NO_NODE
    ||  gmnav_grid_is_blocked(_grid, _goal_node)
    ||  gmnav_grid_is_blocked(_grid, _start_node)) {
        _srch.state = gmnav_state.FAILED;
        return false;
    }

    if (_need_clear > 1 && gmnav_clearance_is_stale(_grid)) {
        gmnav_clearance_build(_grid);
    }

    var _slot = gmnav_grid_scratch_acquire(_grid);
    if (_slot == undefined) return false;   // state stays IDLE - retry later

    var _lay = _grid.layout;
    var _w   = _grid.width;

    _srch.slot       = _slot;
    _srch.start      = _start_node;
    _srch.goal       = _goal_node;
    _srch.goal_c     = _goal_node % _w;
    _srch.goal_r     = _goal_node div _w;
    _srch.goal_x     = gmnav_layout_cell_x(_lay, _srch.goal_c, _srch.goal_r);
    _srch.goal_y     = gmnav_layout_cell_y(_lay, _srch.goal_c, _srch.goal_r);
    _srch.h_mode     = __gmnav_heuristic_resolve(_lay, _srch.h_mode);
    _srch.corner_cut = _corner_cut;
    _srch.profile    = _profile;
    _srch.need_clear = (_grid.clear == undefined) ? 0 : _need_clear;
    _srch.version    = _grid.version;
    _srch.stale      = false;
    _srch.expansions = 0;
    _srch.pops       = 0;
    _srch.result     = [];
    _srch.state      = gmnav_state.WORKING;

    gmnav_heap_clear(_srch.heap);

    _slot.g[_start_node]      = 0;
    _slot.parent[_start_node] = GMNAV_NO_NODE;
    _slot.depth[_start_node]  = 0;
    _slot.mark[_start_node]   = _slot.gen;

    var _h0 = __gmnav_h(_srch, _srch.start % _w, _srch.start div _w);
    gmnav_heap_push(_srch.heap, _h0, _h0, _start_node);

    return true;
}

function gmnav_search_step(_srch, _budget = GMNAV_DEFAULT_BUDGET) {
    if (_srch.state != gmnav_state.WORKING) return _srch.state;

    var _grid = _srch.grid;
    var _lay  = _grid.layout;
    var _slot = _srch.slot;
    var _heap = _srch.heap;

    var _mark = _slot.mark;
    var _gc   = _slot.g;
    var _par  = _slot.parent;
    var _dep  = _slot.depth;
    var _gen  = _slot.gen;
    var _cgen = -_gen;

    var _flags = _grid.flags;
    var _cost  = (_srch.profile != undefined) ? _srch.profile.resolved : _grid.cost;
    var _w     = _grid.width;
    var _h     = _grid.height;

    var _need  = _srch.need_clear;
    var _clr   = (_need > 1) ? _grid.clear : undefined;
    var _relax = _srch.relax;

    var _nbc = _lay.nb_count;
    var _ndc = _lay.nb_dc;
    var _ndr = _lay.nb_dr;
    var _ncs = _lay.nb_cost;
    var _pax = _lay.parity_axis;

    var _goal  = _srch.goal;
    var _check = (!_srch.corner_cut) && (_pax == 0) && (_nbc == 8);
    var _left  = _budget;

    while (_left > 0) {
        if (_heap.count == 0) {
            _srch.state = gmnav_state.FAILED;
            gmnav_search_release(_srch);
            return _srch.state;
        }

        _left--;
        _srch.pops++;

        var _cur = gmnav_heap_pop(_heap);
        if (_mark[_cur] == _cgen) continue;   // already closed, stale entry
        _mark[_cur] = _cgen;

        if (_cur == _goal) {
            _srch.slot_g_final = _gc[_cur];
            __gmnav_search_reconstruct(_srch);
            _srch.state = gmnav_state.FOUND;
            gmnav_search_release(_srch);
            return _srch.state;
        }

        _srch.expansions++;

        var _cc = _cur % _w;
        var _cr = _cur div _w;
        var _cg = _gc[_cur];
        var _cd = _dep[_cur];

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

            if (_clr != undefined && _clr[_nn] < _need) {
                if (_nn != _goal && (_cd + 1) > _relax) continue;
            }

            if (_check && _dc != 0 && _dr != 0) {
                var _f1 = _cr * _w + _nc;
                var _f2 = _nr * _w + _cc;

                if ((_flags[_f1] & GMNAV_FLAG_BLOCKED) != 0) continue;
                if ((_flags[_f2] & GMNAV_FLAG_BLOCKED) != 0) continue;

                if (_clr != undefined && (_cd + 1) > _relax) {
                    if (_clr[_f1] < _need || _clr[_f2] < _need) continue;
                }
            }

            var _ng = _cg + _ncs[_idx] * _cost[_nn];
            if (_mark[_nn] == _gen && _ng >= _gc[_nn]) continue;

            _gc[_nn]   = _ng;
            _par[_nn]  = _cur;
            _dep[_nn]  = _cd + 1;
            _mark[_nn] = _gen;

            var _hh = __gmnav_h(_srch, _nc, _nr);
            gmnav_heap_push(_heap, _ng + _hh, _hh, _nn);
        }
    }

    if (_grid.version != _srch.version) _srch.stale = true;
    return _srch.state;
}

function gmnav_search_is_stale(_srch) {
    return _srch.stale || (_srch.grid.version != _srch.version);
}

function gmnav_search_get_path(_srch) {
    return _srch.result;
}

function gmnav_search_release(_srch) {
    if (_srch.slot != undefined) {
        gmnav_grid_scratch_release(_srch.grid, _srch.slot);
        _srch.slot = undefined;
    }
}

function gmnav_search_abort(_srch) {
    gmnav_search_release(_srch);
    gmnav_heap_clear(_srch.heap);
    _srch.state  = gmnav_state.IDLE;
    _srch.result = [];
}

function __gmnav_search_reconstruct(_srch) {
    var _par = _srch.slot.parent;
    var _out = [];
    var _n   = _srch.goal;

    while (_n != GMNAV_NO_NODE) {
        array_push(_out, _n);
        if (_n == _srch.start) break;
        _n = _par[_n];
    }

    var _len  = array_length(_out);
    var _half = _len div 2;
    for (var i = 0; i < _half; i++) {
        var _t = _out[i];
        _out[i] = _out[_len - 1 - i];
        _out[_len - 1 - i] = _t;
    }

    _srch.result = _out;
}

function __gmnav_heuristic_resolve(_lay, _requested) {
    if (_requested != gmnav_heuristic.AUTO) return _requested;

    switch (_lay.mode) {
        case gmnav_layout.HEX_POINTY:
        case gmnav_layout.HEX_FLAT:
            return gmnav_heuristic.HEX;

        case gmnav_layout.ORTHO:
        case gmnav_layout.ISO_DIAMOND:
            if (_lay.cost_mode == gmnav_costmode.VISUAL) return gmnav_heuristic.EUCLIDEAN;
            return (_lay.neighbours == gmnav_neighbours.FOUR)
                 ? gmnav_heuristic.MANHATTAN
                 : gmnav_heuristic.OCTILE;
    }
    return gmnav_heuristic.EUCLIDEAN;
}

function __gmnav_h(_srch, _col, _row) {
    var _dx = abs(_col - _srch.goal_c);
    var _dy = abs(_row - _srch.goal_r);

    switch (_srch.h_mode) {
        case gmnav_heuristic.MANHATTAN:
            return _dx + _dy;

        case gmnav_heuristic.CHEBYSHEV:
            return max(_dx, _dy);

        case gmnav_heuristic.OCTILE: {
            var _lo = min(_dx, _dy);
            return (_dx + _dy) + (GMNAV_SQRT2 - 2) * _lo;
        }

        case gmnav_heuristic.HEX: {
            var _lay = _srch.grid.layout;
            var _q1, _r1, _q2, _r2;

            if (_lay.mode == gmnav_layout.HEX_POINTY) {
                _r1 = _row;  _q1 = _col - ((_row - gmnav_parity(_row)) div 2);
                _r2 = _srch.goal_r;
                _q2 = _srch.goal_c - ((_srch.goal_r - gmnav_parity(_srch.goal_r)) div 2);
            } else {
                _q1 = _col;  _r1 = _row - ((_col - gmnav_parity(_col)) div 2);
                _q2 = _srch.goal_c;
                _r2 = _srch.goal_r - ((_srch.goal_c - gmnav_parity(_srch.goal_c)) div 2);
            }

            return (abs(_q1 - _q2) + abs(_q1 + _r1 - _q2 - _r2) + abs(_r1 - _r2)) * 0.5;
        }

        case gmnav_heuristic.EUCLIDEAN: {
            var _lay = _srch.grid.layout;
            var _x = gmnav_layout_cell_x(_lay, _col, _row);
            var _y = gmnav_layout_cell_y(_lay, _col, _row);
            return point_distance(_x, _y, _srch.goal_x, _srch.goal_y) / _lay.step_min_world;
        }
    }
    return 0;
}