function gmnav_graph_scratch_acquire(_pg) {
    for (var i = 0; i < _pg.slot_max; i++) {
        var _s = _pg.slots[i];

        if (_s == undefined) {
            var _n = _pg.count;
            _s = {
                index  : i,
                busy   : true,
                gen    : 1,
                mark   : array_create(_n, 0),
                g      : array_create(_n, 0),
                parent : array_create(_n, GMNAV_NO_NODE),
                via    : array_create(_n, gmnav_link.WALK)
            };
            _pg.slots[i] = _s;
            return _s;
        }

        if (!_s.busy) {
            _s.busy = true;
            _s.gen++;
            return _s;
        }
    }
    return undefined;
}

function gmnav_graph_scratch_release(_pg, _slot) {
    if (_slot != undefined) _slot.busy = false;
}

function gmnav_graphsearch_create(_pg) {
    return {
        pg         : _pg,
        slot       : undefined,
        heap       : gmnav_heap_create(),

        state      : gmnav_state.IDLE,
        start      : GMNAV_NO_NODE,
        goal       : GMNAV_NO_NODE,
        goal_x     : 0,
        goal_y     : 0,

        version    : -1,
        stale      : false,
        expansions : 0,
        pops       : 0,

        result     : [],   // platform node ids, start to goal
        result_via : []    // gmnav_link.* used to ENTER each node;
                           // index 0 is always WALK and means nothing
    };
}

function gmnav_graphsearch_begin(_gs, _start, _goal) {
    var _pg = _gs.pg;

    gmnav_graphsearch_abort(_gs);

    if (_pg.phase != gmnav_bake.DONE
    ||  _start == GMNAV_NO_NODE || _goal == GMNAV_NO_NODE
    ||  _start < 0 || _goal < 0
    ||  _start >= _pg.count || _goal >= _pg.count) {
        _gs.state = gmnav_state.FAILED;
        return false;
    }

    var _slot = gmnav_graph_scratch_acquire(_pg);
    if (_slot == undefined) return false;

    _gs.slot       = _slot;
    _gs.start      = _start;
    _gs.goal       = _goal;
    _gs.goal_x     = _pg.node_x[_goal];
    _gs.goal_y     = _pg.node_y[_goal];
    _gs.version    = _pg.grid.version;
    _gs.stale      = false;
    _gs.expansions = 0;
    _gs.pops       = 0;
    _gs.result     = [];
    _gs.result_via = [];
    _gs.state      = gmnav_state.WORKING;

    gmnav_heap_clear(_gs.heap);

    _slot.g[_start]      = 0;
    _slot.parent[_start] = GMNAV_NO_NODE;
    _slot.via[_start]    = gmnav_link.WALK;
    _slot.mark[_start]   = _slot.gen;

    var _h0 = __gmnav_graph_h(_gs, _start);
    gmnav_heap_push(_gs.heap, _h0, _h0, _start);

    return true;
}

function gmnav_graphsearch_step(_gs, _budget = GMNAV_DEFAULT_BUDGET) {
    if (_gs.state != gmnav_state.WORKING) return _gs.state;

    var _pg   = _gs.pg;
    var _slot = _gs.slot;
    var _heap = _gs.heap;

    var _mark = _slot.mark;
    var _gc   = _slot.g;
    var _par  = _slot.parent;
    var _via  = _slot.via;
    var _gen  = _slot.gen;
    var _cgen = -_gen;

    var _es = _pg.edge_start;
    var _et = _pg.edge_to;
    var _ec = _pg.edge_cost;
    var _ey = _pg.edge_type;

    var _goal = _gs.goal;
    var _left = _budget;

    while (_left > 0) {
        if (_heap.count == 0) {
            _gs.state = gmnav_state.FAILED;
            gmnav_graphsearch_release(_gs);
            return _gs.state;
        }

        _left--;
        _gs.pops++;

        var _cur = gmnav_heap_pop(_heap);
        if (_mark[_cur] == _cgen) continue;
        _mark[_cur] = _cgen;

        if (_cur == _goal) {
            __gmnav_graph_reconstruct(_gs);
            _gs.state = gmnav_state.FOUND;
            gmnav_graphsearch_release(_gs);
            return _gs.state;
        }

        _gs.expansions++;

        var _cg  = _gc[_cur];
        var _e0  = _es[_cur];
        var _e1  = _es[_cur + 1];

        for (var e = _e0; e < _e1; e++) {
            var _nn = _et[e];
            if (_mark[_nn] == _cgen) continue;

            var _ng = _cg + _ec[e];
            if (_mark[_nn] == _gen && _ng >= _gc[_nn]) continue;

            _gc[_nn]   = _ng;
            _par[_nn]  = _cur;
            _via[_nn]  = _ey[e];
            _mark[_nn] = _gen;

            var _hh = __gmnav_graph_h(_gs, _nn);
            gmnav_heap_push(_heap, _ng + _hh, _hh, _nn);
        }
    }

    if (_pg.grid.version != _gs.version) _gs.stale = true;
    return _gs.state;
}

function gmnav_graphsearch_solve(_gs, _start, _goal) {
    if (!gmnav_graphsearch_begin(_gs, _start, _goal)) return false;
    return (gmnav_graphsearch_step(_gs, GMNAV_MAX_STEPS) == gmnav_state.FOUND);
}

function gmnav_graphsearch_get_path(_gs)  { return _gs.result; }
function gmnav_graphsearch_get_links(_gs) { return _gs.result_via; }

function gmnav_graphsearch_is_stale(_gs) {
    return _gs.stale || (_gs.pg.grid.version != _gs.version);
}

function gmnav_graphsearch_release(_gs) {
    if (_gs.slot != undefined) {
        gmnav_graph_scratch_release(_gs.pg, _gs.slot);
        _gs.slot = undefined;
    }
}

function gmnav_graphsearch_abort(_gs) {
    gmnav_graphsearch_release(_gs);
    gmnav_heap_clear(_gs.heap);
    _gs.state      = gmnav_state.IDLE;
    _gs.result     = [];
    _gs.result_via = [];
}

function gmnav_graphsearch_get_points(_gs) {
    var _pg  = _gs.pg;
    var _src = _gs.result;
    var _n   = array_length(_src);
    var _out = array_create(_n, 0);

    for (var i = 0; i < _n; i++) {
        _out[i] = [_pg.node_x[_src[i]], _pg.node_y[_src[i]]];
    }
    return _out;
}

function __gmnav_graph_h(_gs, _node) {
    var _pg = _gs.pg;
    return point_distance(_pg.node_x[_node], _pg.node_y[_node],
                          _gs.goal_x, _gs.goal_y) / _pg.max_step;
}

function __gmnav_graph_reconstruct(_gs) {
    var _par = _gs.slot.parent;
    var _via = _gs.slot.via;

    var _nodes = [];
    var _links = [];
    var _n     = _gs.goal;

    while (_n != GMNAV_NO_NODE) {
        array_push(_nodes, _n);
        array_push(_links, _via[_n]);
        if (_n == _gs.start) break;
        _n = _par[_n];
    }

    var _len  = array_length(_nodes);
    var _half = _len div 2;

    for (var i = 0; i < _half; i++) {
        var _j = _len - 1 - i;

        var _t = _nodes[i]; _nodes[i] = _nodes[_j]; _nodes[_j] = _t;
        var _u = _links[i]; _links[i] = _links[_j]; _links[_j] = _u;
    }

    _gs.result     = _nodes;
    _gs.result_via = _links;
}