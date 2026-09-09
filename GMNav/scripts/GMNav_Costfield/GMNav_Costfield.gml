function __gmnav_cost_capacity(_grid) { // overlay ids continue past grid.count, so cost data has to cover both
    var _n = _grid.count;

    if (variable_struct_exists(_grid, "overlay") && _grid.overlay != undefined) {
        _n += _grid.overlay.count;
    }
    return _n;
}

function __gmnav_cost_fit(_arr, _grid, _fill) { // an overlay can be attached, or grown, after the array was made
    var _n = __gmnav_cost_capacity(_grid);
    var _o = array_length(_arr);
    if (_o >= _n) return _arr;

    array_resize(_arr, _n);
    for (var i = _o; i < _n; i++) _arr[i] = _fill;
    return _arr;
}

function gmnav_costlayer_create(_grid, _name = "") {
    return {
        name    : _name,
        grid    : _grid,
        values  : array_create(__gmnav_cost_capacity(_grid), 0),
        version : 1
    };
}

function gmnav_costlayer_clear(_layer) {
    _layer.values = __gmnav_cost_fit(_layer.values, _layer.grid, 0);

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

function gmnav_costlayer_set_node(_layer, _node, _value) { // addresses any node, base or overlay, since an overlay cell has no unique col/row
    _layer.values = __gmnav_cost_fit(_layer.values, _layer.grid, 0);

    if (_node < 0 || _node >= array_length(_layer.values)) return false;

    if (_layer.values[_node] != _value) {
        _layer.values[_node] = _value;
        _layer.version++;
    }
    return true;
}

function gmnav_costlayer_get_node(_layer, _node) {
    if (_node < 0 || _node >= array_length(_layer.values)) return 0;
    return _layer.values[_node];
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
        resolved : array_create(__gmnav_cost_capacity(_grid), 1),
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
    var _ln   = array_length(_profile.layers);

    _profile.resolved = __gmnav_cost_fit(_profile.resolved, _grid, 1);
    var _out = _profile.resolved;

    for (var i = 0; i < _n; i++) _out[i] = _base[i];

    var _ov = undefined;
    if (variable_struct_exists(_grid, "overlay") && _grid.overlay != undefined) {
        _ov = _grid.overlay;
        for (var _k = 0; _k < _ov.count; _k++) _out[_n + _k] = _ov.cost[_k];
    }

    var _total = array_length(_out);

    if (_ln > 0) {
        for (var _l = 0; _l < _ln; _l++) {
            var _wt = _profile.weights[_l];
            if (_wt == 0) continue;

            var _vals = __gmnav_cost_fit(_profile.layers[_l].values, _grid, 0);
            _profile.layers[_l].values = _vals;

            for (var j = 0; j < _total; j++) _out[j] += _vals[j] * _wt;
        }

        for (var m = 0; m < _total; m++) {
            if (_out[m] < 1) _out[m] = 1;
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

function __gmnav_seg_distance(_px, _py, _x1, _y1, _x2, _y2) { // shortest distance from a point to a segment
    var _dx = _x2 - _x1;
    var _dy = _y2 - _y1;
    var _l2 = _dx * _dx + _dy * _dy;

    if (_l2 <= 0.0001) return point_distance(_px, _py, _x1, _y1);

    var _t = clamp(((_px - _x1) * _dx + (_py - _y1) * _dy) / _l2, 0, 1);

    return point_distance(_px, _py, _x1 + _dx * _t, _y1 + _dy * _t);
}

function gmnav_costlayer_stamp_path(_layer, _points, _width, _peak, _falloff = 1) { // paints a band of cost along a polyline, for a road, a patrol route, a spreading fire
    var _n = array_length(_points);
    if (_n == 0) return [0, 0, -1, -1];

    var _grid = _layer.grid;
    var _lay  = _grid.layout;
    var _v    = _layer.values;
    var _w    = _grid.width;
    var _iw   = 1 / max(0.0001, _width);

    var _mc1 = _grid.width, _mr1 = _grid.height, _mc2 = -1, _mr2 = -1;

    var _segs = max(1, _n - 1);

    for (var _s = 0; _s < _segs; _s++) {
        var _x1 = _points[_s][0];
        var _y1 = _points[_s][1];
        var _x2 = (_n == 1) ? _x1 : _points[_s + 1][0];
        var _y2 = (_n == 1) ? _y1 : _points[_s + 1][1];

        var _lo_x = min(_x1, _x2) - _width;
        var _hi_x = max(_x1, _x2) + _width;
        var _lo_y = min(_y1, _y2) - _width;
        var _hi_y = max(_y1, _y2) + _width;

        var _a = gmnav_layout_world_to_cell(_lay, _lo_x, _lo_y);
        var _b = gmnav_layout_world_to_cell(_lay, _hi_x, _lo_y);
        var _c = gmnav_layout_world_to_cell(_lay, _lo_x, _hi_y);
        var _d = gmnav_layout_world_to_cell(_lay, _hi_x, _hi_y);

        var _c1 = clamp(min(_a[0], _b[0], _c[0], _d[0]) - 1, 0, _grid.width  - 1);
        var _c2 = clamp(max(_a[0], _b[0], _c[0], _d[0]) + 1, 0, _grid.width  - 1);
        var _r1 = clamp(min(_a[1], _b[1], _c[1], _d[1]) - 1, 0, _grid.height - 1);
        var _r2 = clamp(max(_a[1], _b[1], _c[1], _d[1]) + 1, 0, _grid.height - 1);

        for (var _r = _r1; _r <= _r2; _r++) {
            var _base = _r * _w;

            for (var _cc = _c1; _cc <= _c2; _cc++) {
                var _cx = gmnav_layout_cell_x(_lay, _cc, _r);
                var _cy = gmnav_layout_cell_y(_lay, _cc, _r);

                var _dd = __gmnav_seg_distance(_cx, _cy, _x1, _y1, _x2, _y2);
                if (_dd > _width) continue;

                var _val = _peak * power(1 - (_dd * _iw), _falloff);
                var _i   = _base + _cc;

                if (_val > _v[_i]) _v[_i] = _val;

                if (_cc < _mc1) _mc1 = _cc;
                if (_cc > _mc2) _mc2 = _cc;
                if (_r  < _mr1) _mr1 = _r;
                if (_r  > _mr2) _mr2 = _r;
            }
        }
    }

    _layer.version++;

    if (_mc2 < 0) return [0, 0, -1, -1];
    return [_mc1, _mr1, _mc2, _mr2];
}