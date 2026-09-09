function gmnav_flowfield_create(_grid, _profile = undefined,
                                _max_climb = undefined, _max_drop = undefined) {
    var _n = __gmnav_field_capacity(_grid);

    return {
        grid     : _grid,
        profile  : _profile,

        max_climb : _max_climb, // undefined means heights are not consulted, 
        max_drop  : _max_drop,  // so a grid carrying elevation behaves exactly as before until a caller opts in

        dist     : array_create(_n, GMNAV_INF),
        dirx     : array_create(_n, 0),
        diry     : array_create(_n, 0),
        mark     : array_create(_n, 0),
        next     : array_create(_n, GMNAV_NO_NODE),  // the node this cell steps to, so a layer change is a real step and not a guess at a vector

        gen      : 0,
        heap     : gmnav_heap_create(),

        state    : gmnav_state.IDLE,
        goals    : [],
        version  : -1,
        vec_at   : 0,            // vector pass cursor
        max_dist : GMNAV_INF     // stop expanding past this distance
    };
}

function __gmnav_field_capacity(_grid) { // overlay ids continue past grid.count, so the field has to cover both
    var _n = _grid.count;

    if (variable_struct_exists(_grid, "overlay") && _grid.overlay != undefined) {
        _n += _grid.overlay.count;
    }
    return _n;
}

function __gmnav_field_fit(_field) { // an overlay can be attached, or grown, after the field was created
    var _n = __gmnav_field_capacity(_field.grid);
    if (array_length(_field.dist) >= _n) return;

    var _old = array_length(_field.dist);

    array_resize(_field.dist, _n);
    array_resize(_field.dirx, _n);
    array_resize(_field.diry, _n);
    array_resize(_field.mark, _n);
    array_resize(_field.next, _n);

    for (var i = _old; i < _n; i++) {
        _field.dist[i] = GMNAV_INF;
        _field.dirx[i] = 0;
        _field.diry[i] = 0;
        _field.mark[i] = 0;
        _field.next[i] = GMNAV_NO_NODE;
    }
}

function gmnav_flowfield_begin(_field, _goal_nodes, _max_dist = GMNAV_INF) {
    var _grid = _field.grid;

    __gmnav_field_fit(_field);

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
        _field.next[_g] = GMNAV_NO_NODE; // a goal is where the walk ends
        gmnav_heap_push(_field.heap, 0, 0, _g);
        _any = true;
    }

    if (!_any) {
        _field.state = gmnav_state.FAILED;
        return false;
    }
    return true;
}

function gmnav_flowfield_step(_field, _budget = global.gmnav.config.DEFAULT_BUDGET) {
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
        gmnav_flowfield_step(_field, global.gmnav.config.DEFAULT_BUDGET);
        if (++_guard > global.gmnav.config.MAX_STEPS) break;
    }
    return (_field.state == gmnav_state.FOUND);
}

function gmnav_flowfield_is_ready(_field) {
    return (_field.state == gmnav_state.FOUND);
}

function gmnav_flowfield_is_stale(_field) {
    return (_field.grid.version != _field.version);
}

function gmnav_flowfield_sample(_field, _x, _y, _layer = 0) {
    var _n = gmnav_grid_world_to_node(_field.grid, _x, _y, _layer);
    if (_n == GMNAV_NO_NODE) return [0, 0];
    return [_field.dirx[_n], _field.diry[_n]];
}

function gmnav_flowfield_cost_at(_field, _x, _y, _layer = 0) {
    var _n = gmnav_grid_world_to_node(_field.grid, _x, _y, _layer);
    if (_n == GMNAV_NO_NODE) return GMNAV_INF;

    var _m = _field.mark[_n];
    if (_m != _field.gen && _m != -_field.gen) return GMNAV_INF;

    return _field.dist[_n];
}

function gmnav_flowfield_is_reachable(_field, _x, _y, _layer = 0) {
    var _n = gmnav_grid_world_to_node(_field.grid, _x, _y, _layer);
    if (_n == GMNAV_NO_NODE) return false;

    var _m = _field.mark[_n];
    return (_m == _field.gen || _m == -_field.gen);
}

function gmnav_flowfield_next(_field, _node) { // the node a cell steps to, GMNAV_NO_NODE at a goal or an unreached cell. Read this rather than the vector when a step may cross layers
    if (_node < 0 || _node >= array_length(_field.next)) return GMNAV_NO_NODE;
    return _field.next[_node];
}

function __gmnav_field_expand(_field, _budget) {
    var _grid = _field.grid;
    var _lay  = _grid.layout;
    var _heap = _field.heap;

    var _dist = _field.dist;
    var _mark = _field.mark;
    var _next = _field.next;
    var _gen  = _field.gen;
    var _cgen = -_gen;

    var _flags = _grid.flags;
    var _cost  = (_field.profile != undefined) ? _field.profile.resolved : _grid.cost;
    var _w     = _grid.width;
    var _h     = _grid.height;

    var _ov = undefined;
    if (variable_struct_exists(_grid, "overlay") && _grid.overlay != undefined) {
        if (array_length(_grid.overlay.edge_start) > 0) _ov = _grid.overlay;
    }
    var _obase = (_ov != undefined) ? _ov.base : infinity;

    var _nbc = _lay.nb_count;
    var _ndc = _lay.nb_dc;
    var _ndr = _lay.nb_dr;
    var _ncs = _lay.nb_cost;
    var _pax = _lay.parity_axis;

    var _cap   = _field.max_dist;
    var _check = (_pax == 0) && (_nbc == 8);
    var _hz    = (_field.max_climb == undefined) ? undefined : _grid.height_z;
    var _climb = _field.max_climb;
    var _drop  = _field.max_drop;
    var _left  = _budget;

    while (_left > 0) {
        if (_heap.count == 0) return _left;

        _left--;

        var _cur = gmnav_heap_pop(_heap);
        if (_mark[_cur] == _cgen) continue;
        _mark[_cur] = _cgen;

        var _cd = _dist[_cur];
        if (_cd >= _cap) continue;

        // an overlay node walks its own adjacency, not the neighbour table
        if (_cur >= _obase) {
            var _oi = _cur - _obase;
            var _oe = _ov.edge_start[_oi + 1];

            for (var e = _ov.edge_start[_oi]; e < _oe; e++) {
                var _on = _ov.edge_to[e];
                if (_mark[_on] == _cgen) continue;

                if (_on < _obase && (_flags[_on] & GMNAV_FLAG_BLOCKED) != 0) continue;
                if (_on >= _obase && gmnav_overlay_is_blocked(_ov, _on)) continue;

                var _ocost = (_on >= _obase) ? _ov.cost[_on - _obase] : _cost[_on];
                var _od    = _cd + _ov.edge_cost[e] * _ocost;

                if (_od > _cap) continue;
                if (_mark[_on] == _gen && _od >= _dist[_on]) continue;

                _dist[_on] = _od;
                _mark[_on] = _gen;
                _next[_on] = _cur; // the field is built outward, so the step home is back the way we came
                gmnav_heap_push(_heap, _od, 0, _on);
            }
            continue;
        }

        var _cc = _cur % _w;
        var _cr = _cur div _w;

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

            if (_hz != undefined) {
                var _dz = _hz[_cur] - _hz[_nn];
                if (_dz > _climb || -_dz > _drop) continue;
            }

            if (_check && _dc != 0 && _dr != 0) {
                var _f1 = _cr * _w + _nc;
                var _f2 = _nr * _w + _cc;

                if ((_flags[_f1] & GMNAV_FLAG_BLOCKED) != 0) continue;
                if ((_flags[_f2] & GMNAV_FLAG_BLOCKED) != 0) continue;

                if (_hz != undefined) {
                    var _zn  = _hz[_nn];
                    var _dz1 = _hz[_f1] - _zn;
                    var _dz2 = _hz[_f2] - _zn;

                    if (_dz1 > _climb || -_dz1 > _drop) continue;
                    if (_dz2 > _climb || -_dz2 > _drop) continue;
                }
            }

            var _nd = _cd + _ncs[_idx] * _cost[_nn];
            if (_nd > _cap) continue;
            if (_mark[_nn] == _gen && _nd >= _dist[_nn]) continue;

            _dist[_nn] = _nd;
            _mark[_nn] = _gen;
            _next[_nn] = _cur;
            gmnav_heap_push(_heap, _nd, 0, _nn);
        }

        // authored links climbing out of this base cell
        if (_ov != undefined) {
            var _ue = _ov.up_start[_cur + 1];

            for (var u = _ov.up_start[_cur]; u < _ue; u++) {
                var _un = _ov.up_to[u];
                if (_mark[_un] == _cgen) continue;

                if (_un >= _obase && gmnav_overlay_is_blocked(_ov, _un)) continue;

                var _ucost = (_un >= _obase) ? _ov.cost[_un - _obase] : _cost[_un];
                var _ud    = _cd + _ov.up_cost[u] * _ucost;

                if (_ud > _cap) continue;
                if (_mark[_un] == _gen && _ud >= _dist[_un]) continue;

                _dist[_un] = _ud;
                _mark[_un] = _gen;
                _next[_un] = _cur;
                gmnav_heap_push(_heap, _ud, 0, _un);
            }
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
    var _next = _field.next;
    var _gen  = _field.gen;
    var _cgen = -_gen;

    var _flags = _grid.flags;
    var _w     = _grid.width;
    var _h     = _grid.height;
    var _cells = _grid.count;

    var _ov = undefined;
    if (variable_struct_exists(_grid, "overlay") && _grid.overlay != undefined) {
        if (array_length(_grid.overlay.edge_start) > 0) _ov = _grid.overlay;
    }
    var _obase = (_ov != undefined) ? _ov.base : _cells;
    var _total = (_ov != undefined) ? (_cells + _ov.count) : _cells;

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
            _next[_i] = GMNAV_NO_NODE;
            _i++;
            continue;
        }

        var _best = _dist[_i];
        var _bn   = GMNAV_NO_NODE;

        if (_i >= _obase) {
            // an overlay cell chooses among its own edges
            var _oi = _i - _obase;
            var _oe = _ov.edge_start[_oi + 1];

            for (var e = _ov.edge_start[_oi]; e < _oe; e++) {
                var _on = _ov.edge_to[e];

                if (_mark[_on] != _gen && _mark[_on] != _cgen) continue;
                if (_on < _obase && (_flags[_on] & GMNAV_FLAG_BLOCKED) != 0) continue;
                if (_on >= _obase && gmnav_overlay_is_blocked(_ov, _on)) continue;

                if (_dist[_on] < _best) {
                    _best = _dist[_on];
                    _bn   = _on;
                }
            }
        } else {
            var _cc = _i % _w;
            var _cr = _i div _w;

            var _p = 0;
            if (_pax == 1)      _p = gmnav_parity(_cr);
            else if (_pax == 2) _p = gmnav_parity(_cc);
            var _base = _p * _nbc;

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
                    _bn   = _nn;
                }
            }

            // an authored link out of this cell may beat every neighbour
            if (_ov != undefined) {
                var _ue = _ov.up_start[_i + 1];

                for (var u = _ov.up_start[_i]; u < _ue; u++) {
                    var _un = _ov.up_to[u];

                    if (_mark[_un] != _gen && _mark[_un] != _cgen) continue;
                    if (_un >= _obase && gmnav_overlay_is_blocked(_ov, _un)) continue;

                    if (_dist[_un] < _best) {
                        _best = _dist[_un];
                        _bn   = _un;
                    }
                }
            }
        }

        _next[_i] = _bn;

        if (_bn == GMNAV_NO_NODE) {
            _dirx[_i] = 0;
            _diry[_i] = 0;
        } else {
            var _fp = gmnav_grid_node_to_world(_grid, _i); // through the accessor, so a lifted deck reports where it is drawn
            var _tp = gmnav_grid_node_to_world(_grid, _bn);

            var _dx = _tp[0] - _fp[0];
            var _dy = _tp[1] - _fp[1];
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