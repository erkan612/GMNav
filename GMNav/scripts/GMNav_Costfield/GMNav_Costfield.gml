function gmnav_costlayer_create(_grid, _name = "") {
    return {
        name    : _name,
        grid    : _grid,
        values  : array_create(_grid.count, 0),
        version : 1
    };
}

function gmnav_costlayer_clear(_layer) {
    var _v = _layer.values;
    for (var i = 0; i < array_length(_v); i++) _v[i] = 0;
    _layer.version++;
}

function gmnav_costlayer_set(_layer, _col, _row, _value) {
    var _n = gmnav_grid_node(_layer.grid, _col, _row);
    if (_n == GMNAV_NO_NODE) return false;

    if (_layer.values[_n] != _value) {
        _layer.values[_n] = _value;
        _layer.version++;
    }
    return true;
}

function gmnav_costlayer_get(_layer, _col, _row) {
    var _n = gmnav_grid_node(_layer.grid, _col, _row);
    return (_n == GMNAV_NO_NODE) ? 0 : _layer.values[_n];
}

function gmnav_costlayer_stamp_radial(_layer, _wx, _wy, _radius, _peak, _falloff = 1) {
    var _grid = _layer.grid;
    var _lay  = _grid.layout;

    var _a = gmnav_layout_world_to_cell(_lay, _wx - _radius, _wy - _radius);
    var _b = gmnav_layout_world_to_cell(_lay, _wx + _radius, _wy - _radius);
    var _c = gmnav_layout_world_to_cell(_lay, _wx - _radius, _wy + _radius);
    var _d = gmnav_layout_world_to_cell(_lay, _wx + _radius, _wy + _radius);

    var _c1 = clamp(min(_a[0], _b[0], _c[0], _d[0]) - 1, 0, _grid.width  - 1);
    var _c2 = clamp(max(_a[0], _b[0], _c[0], _d[0]) + 1, 0, _grid.width  - 1);
    var _r1 = clamp(min(_a[1], _b[1], _c[1], _d[1]) - 1, 0, _grid.height - 1);
    var _r2 = clamp(max(_a[1], _b[1], _c[1], _d[1]) + 1, 0, _grid.height - 1);

    var _v  = _layer.values;
    var _w  = _grid.width;
    var _ir = 1 / max(0.0001, _radius);

    for (var _r = _r1; _r <= _r2; _r++) {
        var _base = _r * _w;
        for (var _cc = _c1; _cc <= _c2; _cc++) {
            var _px = gmnav_layout_cell_x(_lay, _cc, _r);
            var _py = gmnav_layout_cell_y(_lay, _cc, _r);
            var _dd = point_distance(_px, _py, _wx, _wy);
            if (_dd > _radius) continue;

            var _t   = 1 - (_dd * _ir);
            var _val = _peak * power(_t, _falloff);
            var _i   = _base + _cc;
            if (_val > _v[_i]) _v[_i] = _val;
        }
    }

    _layer.version++;
    return [_c1, _r1, _c2, _r2];
}

function gmnav_costlayer_clear_region(_layer, _c1, _r1, _c2, _r2) {
    var _grid = _layer.grid;
    var _v    = _layer.values;
    var _w    = _grid.width;

    var _cl = clamp(min(_c1, _c2), 0, _w - 1);
    var _cr = clamp(max(_c1, _c2), 0, _w - 1);
    var _rt = clamp(min(_r1, _r2), 0, _grid.height - 1);
    var _rb = clamp(max(_r1, _r2), 0, _grid.height - 1);

    for (var _r = _rt; _r <= _rb; _r++) {
        var _base = _r * _w;
        for (var _c = _cl; _c <= _cr; _c++) _v[_base + _c] = 0;
    }
    _layer.version++;
}

function gmnav_costprofile_create(_grid, _name = "") {
    return {
        name     : _name,
        grid     : _grid,
        layers   : [],
        weights  : [],
        seen     : [],                          // last baked layer versions
        resolved : array_create(_grid.count, 1),
        gver     : -1,                          // last baked grid version
        baked    : false
    };
}

function gmnav_costprofile_add(_profile, _layer, _weight = 1) {
    array_push(_profile.layers,  _layer);
    array_push(_profile.weights, _weight);
    array_push(_profile.seen,    -1);
    _profile.baked = false;
}

function gmnav_costprofile_set_weight(_profile, _layer, _weight) {
    for (var i = 0; i < array_length(_profile.layers); i++) {
        if (_profile.layers[i] == _layer) {
            if (_profile.weights[i] != _weight) {
                _profile.weights[i] = _weight;
                _profile.baked = false;
            }
            return true;
        }
    }
    return false;
}

function gmnav_costprofile_remove(_profile, _layer) {
    for (var i = 0; i < array_length(_profile.layers); i++) {
        if (_profile.layers[i] == _layer) {
            array_delete(_profile.layers,  i, 1);
            array_delete(_profile.weights, i, 1);
            array_delete(_profile.seen,    i, 1);
            _profile.baked = false;
            return true;
        }
    }
    return false;
}

function gmnav_costprofile_is_dirty(_profile) {
    if (!_profile.baked) return true;
    if (_profile.gver != _profile.grid.version) return true;

    for (var i = 0; i < array_length(_profile.layers); i++) {
        if (_profile.seen[i] != _profile.layers[i].version) return true;
    }
    return false;
}

function gmnav_costprofile_bake(_profile) {
    var _grid = _profile.grid;
    var _n    = _grid.count;
    var _base = _grid.cost;
    var _out  = _profile.resolved;
    var _ln   = array_length(_profile.layers);

    if (_ln == 0) {
        for (var i = 0; i < _n; i++) _out[i] = _base[i];
    } else {
        for (var i = 0; i < _n; i++) _out[i] = _base[i];

        for (var _l = 0; _l < _ln; _l++) {
            var _wt = _profile.weights[_l];
            if (_wt == 0) continue;

            var _vals = _profile.layers[_l].values;
            for (var i = 0; i < _n; i++) _out[i] += _vals[i] * _wt;
        }

        for (var i = 0; i < _n; i++) {
            if (_out[i] < 1) _out[i] = 1;
        }
    }

    __gmnav_costprofile_mark_clean(_profile);
}

function gmnav_costprofile_bake_if_dirty(_profile) {
    if (gmnav_costprofile_is_dirty(_profile)) gmnav_costprofile_bake(_profile);
}

function gmnav_costprofile_bake_region(_profile, _c1, _r1, _c2, _r2) {
    var _grid = _profile.grid;
    var _base = _grid.cost;
    var _out  = _profile.resolved;
    var _w    = _grid.width;
    var _ln   = array_length(_profile.layers);

    var _cl = clamp(min(_c1, _c2), 0, _w - 1);
    var _cr = clamp(max(_c1, _c2), 0, _w - 1);
    var _rt = clamp(min(_r1, _r2), 0, _grid.height - 1);
    var _rb = clamp(max(_r1, _r2), 0, _grid.height - 1);

    for (var _r = _rt; _r <= _rb; _r++) {
        var _row = _r * _w;
        for (var _c = _cl; _c <= _cr; _c++) {
            var _i   = _row + _c;
            var _acc = _base[_i];

            for (var _l = 0; _l < _ln; _l++) {
                var _wt = _profile.weights[_l];
                if (_wt != 0) _acc += _profile.layers[_l].values[_i] * _wt;
            }

            _out[_i] = (_acc < 1) ? 1 : _acc;
        }
    }
}

function __gmnav_costprofile_mark_clean(_profile) {
    _profile.gver  = _profile.grid.version;
    _profile.baked = true;
    for (var i = 0; i < array_length(_profile.layers); i++) {
        _profile.seen[i] = _profile.layers[i].version;
    }
}