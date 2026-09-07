/// SPIKE. Stage 1 of the layered top-down domain.
///
/// The question this answers is whether gmnav_graphsearch really is agnostic
/// about what a node means, or whether it is quietly a platformer searcher.
/// It touches twelve fields on the graph it is given and none of them is a
/// grid index, so satisfying that list should be enough.
///
/// Deliberately absent: authoring, storage, picking, the scheduler, clearance,
/// cost profiles and flow fields. add_node taking raw world coordinates is not
/// a real API, it is the shortest path to an answer. Throw this away if the
/// answer is no.
function gmnav_layergraph_create(_grid) {
    return {
        grid       : _grid,

        count      : 0,
        node_x     : [],
        node_y     : [],
        node_layer : [],

        // scratch, flattened into CSR by finish
        tmp_to     : [],
        tmp_cost   : [],
        tmp_type   : [],

        edge_start : [],
        edge_to    : [],
        edge_cost  : [],
        edge_type  : [],

        // edge cost is world distance, so a straight line to the goal is an
        // exact lower bound and the heuristic stays admissible
        max_step   : 1,

        slots      : array_create(2, undefined),
        slot_max   : 2,

        phase      : gmnav_bake.IDLE,
        version    : -1
    };
}

/// Returns the new node's index.
function gmnav_layergraph_add_node(_lg, _x, _y, _layer) {
    var _i = _lg.count;

    array_push(_lg.node_x,     _x);
    array_push(_lg.node_y,     _y);
    array_push(_lg.node_layer, _layer);

    array_push(_lg.tmp_to,   []);
    array_push(_lg.tmp_cost, []);
    array_push(_lg.tmp_type, []);

    _lg.count++;
    return _i;
}

function gmnav_layergraph_layer(_lg, _node) {
    if (_node < 0 || _node >= _lg.count) return -1;
    return _lg.node_layer[_node];
}

/// Joins two nodes. _both makes it traversable in either direction, which is
/// what a walk or a stair usually is. Pass false for a one way drop.
function gmnav_layergraph_link(_lg, _a, _b, _type = gmnav_link.WALK, _both = true) {
    if (_a < 0 || _a >= _lg.count) return false;
    if (_b < 0 || _b >= _lg.count) return false;
    if (_a == _b) return false;

    var _cost = point_distance(_lg.node_x[_a], _lg.node_y[_a],
                               _lg.node_x[_b], _lg.node_y[_b]);

    __gmnav_lg_add(_lg, _a, _b, _cost, _type);
    if (_both) __gmnav_lg_add(_lg, _b, _a, _cost, _type);

    return true;
}

function __gmnav_lg_add(_lg, _from, _to, _cost, _type) {
    var _tos = _lg.tmp_to[_from];

    for (var i = 0; i < array_length(_tos); i++) {
        if (_tos[i] == _to) {
            if (_cost < _lg.tmp_cost[_from][i]) {
                _lg.tmp_cost[_from][i] = _cost;
                _lg.tmp_type[_from][i] = _type;
            }
            return;
        }
    }

    array_push(_lg.tmp_to[_from],   _to);
    array_push(_lg.tmp_cost[_from], _cost);
    array_push(_lg.tmp_type[_from], _type);
}

/// Flattens the scratch lists into the CSR arrays gmnav_graphsearch reads,
/// and marks the graph ready.
function gmnav_layergraph_finish(_lg) {
    var _n = _lg.count;

    var _start = array_create(_n + 1, 0);
    var _total = 0;

    for (var i = 0; i < _n; i++) {
        _start[i] = _total;
        _total += array_length(_lg.tmp_to[i]);
    }
    _start[_n] = _total;

    var _to   = array_create(_total, 0);
    var _cost = array_create(_total, 0);
    var _type = array_create(_total, 0);
    var _k    = 0;

    for (var i = 0; i < _n; i++) {
        var _ts = _lg.tmp_to[i];
        var _cs = _lg.tmp_cost[i];
        var _ty = _lg.tmp_type[i];

        for (var j = 0; j < array_length(_ts); j++) {
            _to[_k]   = _ts[j];
            _cost[_k] = _cs[j];
            _type[_k] = _ty[j];
            _k++;
        }
    }

    _lg.edge_start = _start;
    _lg.edge_to    = _to;
    _lg.edge_cost  = _cost;
    _lg.edge_type  = _type;

    _lg.tmp_to   = [];
    _lg.tmp_cost = [];
    _lg.tmp_type = [];

    _lg.version = _lg.grid.version;
    _lg.phase   = gmnav_bake.DONE;

    return true;
}