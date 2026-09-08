function gmnav_overlay_create(_grid) {
    var _ov = {
        grid  : _grid,
        base  : _grid.count,      // id offset, overlay node 0 is this id
        count : 0,
		max_layer: 0,

        col   : [],
        row   : [],
        layer : [],
        flags : [],
        cost  : [],
        clear : [],
        key   : {},               // "layer,col,row" -> node id
        links : [],               // authored crossings, kept so finish can re-run

        // adjacency out of overlay nodes, built by finish
        tmp_to    : [],
        tmp_cost  : [],
        tmp_type  : [],
        edge_start : [],
        edge_to    : [],
        edge_cost  : [],
        edge_type  : [],

        // authored links out of BASE nodes into the overlay, CSR over the base grid so the expansion can read them in O(1)
        up_tmp   : {},
        up_start : [],
        up_to    : [],
        up_cost  : [],
        up_type  : [],

        ready   : false,
        version : -1
    };

    _grid.overlay = _ov;
    return _ov;
}

function gmnav_grid_has_overlay(_grid) {
    if (!variable_struct_exists(_grid, "overlay")) return false;
    return (_grid.overlay != undefined);
}

function gmnav_overlay_count(_ov) {
    return _ov.count;
}

function gmnav_overlay_layer(_ov, _node) { // layer 0 is the base grid itself, so any id below the offset is layer 0.
    if (_node < 0) return -1;
    if (_node < _ov.base) return 0;

    var _i = _node - _ov.base;
    if (_i >= _ov.count) return -1;

    return _ov.layer[_i];
}

function gmnav_overlay_node_at(_ov, _col, _row, _layer) {
    if (_layer == 0) return gmnav_grid_node(_ov.grid, _col, _row);

    var _k = string(_layer) + "," + string(_col) + "," + string(_row);
    if (!variable_struct_exists(_ov.key, _k)) return GMNAV_NO_NODE;

    return _ov.key[$ _k];
}

function gmnav_overlay_col(_ov, _node) {
    if (_node < _ov.base) return gmnav_grid_col(_ov.grid, _node);
    return _ov.col[_node - _ov.base];
}

function gmnav_overlay_row(_ov, _node) {
    if (_node < _ov.base) return gmnav_grid_row(_ov.grid, _node);
    return _ov.row[_node - _ov.base];
}

function gmnav_overlay_add(_ov, _col, _row, _layer) { // adds one walkable cell on a layer above the base. Returns its node id.
    if (_layer <= 0) return GMNAV_NO_NODE;

    var _k = string(_layer) + "," + string(_col) + "," + string(_row);
    if (variable_struct_exists(_ov.key, _k)) return _ov.key[$ _k];

    var _id = _ov.base + _ov.count;

    array_push(_ov.col,   _col);
    array_push(_ov.row,   _row);
    array_push(_ov.layer, _layer);

    array_push(_ov.tmp_to,   []);
    array_push(_ov.tmp_cost, []);
    array_push(_ov.tmp_type, []);
	
    array_push(_ov.flags, 0);
    array_push(_ov.cost,  1);
    array_push(_ov.clear, 0);

    _ov.key[$ _k] = _id;
    _ov.count++;
    _ov.max_layer = max(_ov.max_layer, _layer);
    _ov.ready = false;

    return _id;
}

function gmnav_overlay_link(_ov, _a, _b, _type = gmnav_link.STAIR, _both = true) { // an authored crossing between layers, a stair or a ramp. Cells on the same layer join automatically, so this is only needed where layers meet.
    if (_a == GMNAV_NO_NODE || _b == GMNAV_NO_NODE || _a == _b) return false;

    var _lay = _ov.grid.layout;

    var _ax = _lay.origin_x + (gmnav_overlay_col(_ov, _a) + 0.5) * _lay.tile_w;
    var _ay = _lay.origin_y + (gmnav_overlay_row(_ov, _a) + 0.5) * _lay.tile_h;
    var _bx = _lay.origin_x + (gmnav_overlay_col(_ov, _b) + 0.5) * _lay.tile_w;
    var _by = _lay.origin_y + (gmnav_overlay_row(_ov, _b) + 0.5) * _lay.tile_h;

    var _cost = max(1, point_distance(_ax, _ay, _bx, _by) / _lay.tile_w);

    array_push(_ov.links, [_a, _b, _type, _both]);

    //__gmnav_ov_add(_ov, _a, _b, _cost, _type);
    //if (_both) __gmnav_ov_add(_ov, _b, _a, _cost, _type);

    _ov.ready = false;
    return true;
}

function __gmnav_ov_add(_ov, _from, _to, _cost, _type) {
    if (_from >= _ov.base) {
        var _i = _from - _ov.base;
        array_push(_ov.tmp_to[_i],   _to);
        array_push(_ov.tmp_cost[_i], _cost);
        array_push(_ov.tmp_type[_i], _type);
        return;
    }

    // out of a base node, so it lives in the sparse up table
    var _k = string(_from);
    if (!variable_struct_exists(_ov.up_tmp, _k)) _ov.up_tmp[$ _k] = [];

    array_push(_ov.up_tmp[$ _k], [_to, _cost, _type]);
}

function gmnav_overlay_finish(_ov) { // joins same layer neighbours automatically, then flattens everything into the CSR arrays the search reads.
    _ov.tmp_to   = array_create(_ov.count, undefined);
    _ov.tmp_cost = array_create(_ov.count, undefined);
    _ov.tmp_type = array_create(_ov.count, undefined);

    for (var _i = 0; _i < _ov.count; _i++) {
        _ov.tmp_to[_i]   = [];
        _ov.tmp_cost[_i] = [];
        _ov.tmp_type[_i] = [];
    }

    _ov.up_tmp = {};

    for (var _i = 0; _i < array_length(_ov.links); _i++) {
        var _lk = _ov.links[_i];
        var _a  = _lk[0];
        var _b  = _lk[1];

        if (gmnav_grid_is_blocked(_ov.grid, _a)) continue;
        if (gmnav_grid_is_blocked(_ov.grid, _b)) continue;

        var _lay = _ov.grid.layout;
        var _ax = _lay.origin_x + (gmnav_grid_col(_ov.grid, _a) + 0.5) * _lay.tile_w;
        var _ay = _lay.origin_y + (gmnav_grid_row(_ov.grid, _a) + 0.5) * _lay.tile_h;
        var _bx = _lay.origin_x + (gmnav_grid_col(_ov.grid, _b) + 0.5) * _lay.tile_w;
        var _by = _lay.origin_y + (gmnav_grid_row(_ov.grid, _b) + 0.5) * _lay.tile_h;

        var _cost = max(1, point_distance(_ax, _ay, _bx, _by) / _lay.tile_w);

        __gmnav_ov_add(_ov, _a, _b, _cost, _lk[2]);
        if (_lk[3]) __gmnav_ov_add(_ov, _b, _a, _cost, _lk[2]);
    }
	
    var _grid = _ov.grid;
    var _lay  = _grid.layout;
    var _nbc  = _lay.nb_count;
    var _ndc  = _lay.nb_dc;
    var _ndr  = _lay.nb_dr;
    var _ncs  = _lay.nb_cost;
    var _pax  = _lay.parity_axis;

    for (var _i = 0; _i < _ov.count; _i++) {
        if ((_ov.flags[_i] & GMNAV_FLAG_BLOCKED) != 0) continue;

        var _c = _ov.col[_i];
        var _r = _ov.row[_i];
        var _l = _ov.layer[_i];

        var _p = 0;
        if (_pax == 1)      _p = gmnav_parity(_r);
        else if (_pax == 2) _p = gmnav_parity(_c);
        var _basei = _p * _nbc;

        for (var _n = 0; _n < _nbc; _n++) {
            var _idx = _basei + _n;
            var _nb  = gmnav_overlay_node_at(_ov, _c + _ndc[_idx], _r + _ndr[_idx], _l);
            if (_nb == GMNAV_NO_NODE) continue;

            if (_nb >= _ov.base && gmnav_overlay_is_blocked(_ov, _nb)) continue;
            __gmnav_ov_add(_ov, _ov.base + _i, _nb, _ncs[_idx], gmnav_link.WALK);
        }
    }

    // overlay adjacency
    var _n2 = _ov.count;
    var _st = array_create(_n2 + 1, 0);
    var _tot = 0;

    for (var _i = 0; _i < _n2; _i++) {
        _st[_i] = _tot;
        _tot += array_length(_ov.tmp_to[_i]);
    }
    _st[_n2] = _tot;

    var _to = array_create(_tot, 0);
    var _cs = array_create(_tot, 0);
    var _ty = array_create(_tot, 0);
    var _k2 = 0;

    for (var _i = 0; _i < _n2; _i++) {
        var _a = _ov.tmp_to[_i], _b = _ov.tmp_cost[_i], _c2 = _ov.tmp_type[_i];

        for (var _j = 0; _j < array_length(_a); _j++) {
            _to[_k2] = _a[_j];  _cs[_k2] = _b[_j];  _ty[_k2] = _c2[_j];  _k2++;
        }
    }

    _ov.edge_start = _st;
    _ov.edge_to    = _to;
    _ov.edge_cost  = _cs;
    _ov.edge_type  = _ty;

    // base to overlay links, CSR over the base grid
    var _bn  = _grid.count;
    var _ust = array_create(_bn + 1, 0);
    var _utot = 0;

    for (var _i = 0; _i < _bn; _i++) {
        _ust[_i] = _utot;
        var _kk = string(_i);
        if (variable_struct_exists(_ov.up_tmp, _kk)) {
            _utot += array_length(_ov.up_tmp[$ _kk]);
        }
    }
    _ust[_bn] = _utot;

    var _uto = array_create(_utot, 0);
    var _ucs = array_create(_utot, 0);
    var _uty = array_create(_utot, 0);
    var _k3  = 0;

    for (var _i = 0; _i < _bn; _i++) {
        var _kk = string(_i);
        if (!variable_struct_exists(_ov.up_tmp, _kk)) continue;

        var _list = _ov.up_tmp[$ _kk];
        for (var _j = 0; _j < array_length(_list); _j++) {
            _uto[_k3] = _list[_j][0];
            _ucs[_k3] = _list[_j][1];
            _uty[_k3] = _list[_j][2];
            _k3++;
        }
    }

    _ov.up_start = _ust;
    _ov.up_to    = _uto;
    _ov.up_cost  = _ucs;
    _ov.up_type  = _uty;

    _ov.tmp_to   = [];
    _ov.tmp_cost = [];
    _ov.tmp_type = [];
    _ov.up_tmp   = {};

    _ov.version = _grid.version;
    __gmnav_ov_clearance(_ov);
    _ov.ready   = true;

    return true;
}

function gmnav_overlay_set_blocked(_ov, _node, _on) {
    var _i = _node - _ov.base;
    if (_i < 0 || _i >= _ov.count) return false;

    var _f = _on ? (_ov.flags[_i] | GMNAV_FLAG_BLOCKED)
                 : (_ov.flags[_i] & ~GMNAV_FLAG_BLOCKED);

    if (_f != _ov.flags[_i]) {
        _ov.flags[_i] = _f;
        _ov.ready = false;
        _ov.grid.version++;
    }
    return true;
}

function gmnav_overlay_set_cost(_ov, _node, _cost) {
    var _i = _node - _ov.base;
    if (_i < 0 || _i >= _ov.count) return false;

    if (_ov.cost[_i] != _cost) {
        _ov.cost[_i] = max(1, _cost);
        _ov.grid.version++;
    }
    return true;
}

function gmnav_overlay_is_blocked(_ov, _node) {
    var _i = _node - _ov.base;
    if (_i < 0 || _i >= _ov.count) return true;
    return ((_ov.flags[_i] & GMNAV_FLAG_BLOCKED) != 0);
}

function __gmnav_ov_clearance(_ov) {
    var _n = _ov.count;
    var _cap = global.gmnav.config.CLEARANCE_MAX;

    for (var _i = 0; _i < _n; _i++) {
        _ov.clear[_i] = ((_ov.flags[_i] & GMNAV_FLAG_BLOCKED) != 0) ? 0 : _cap;
    }

    var _changed = true;
    var _guard   = 0;

    while (_changed && _guard++ <= _cap) {
        _changed = false;

        for (var _i = 0; _i < _n; _i++) {
            if (_ov.clear[_i] == 0) continue;

            var _c = _ov.col[_i];
            var _r = _ov.row[_i];
            var _l = _ov.layer[_i];
            var _lo = _cap;

            for (var _dr = -1; _dr <= 1; _dr++) {
                for (var _dc = -1; _dc <= 1; _dc++) {
                    if (_dc == 0 && _dr == 0) continue;

                    var _nb = gmnav_overlay_node_at(_ov, _c + _dc, _r + _dr, _l);
                    var _v  = 0;

                    if (_nb != GMNAV_NO_NODE) _v = _ov.clear[_nb - _ov.base];

                    _lo = min(_lo, _v);
                }
            }

            var _want = min(_cap, _lo + 1);
            if (_want < _ov.clear[_i]) {
                _ov.clear[_i] = _want;
                _changed = true;
            }
        }
    }
}