function gmnav_clearance_supported(_grid) {
    var _m = _grid.layout.mode;
    return (_m == gmnav_layout.ORTHO || _m == gmnav_layout.ISO_DIAMOND);
}


function gmnav_clearance_build(_grid) {
    if (!gmnav_clearance_supported(_grid)) {
        _grid.clear   = undefined;
        _grid.clear_v = -1;
        return false;
    }

    var _w  = _grid.width;
    var _h  = _grid.height;
    var _n  = _grid.count;
    var _fl = _grid.flags;

    var _cl  = (_grid.clear == undefined) ? array_create(_n, 0) : _grid.clear;
    var _cap = GMNAV_CLEARANCE_MAX;

    var _wm = _w - 1;
    var _hm = _h - 1;

    // forward: obstacles above and to the left
    for (var _r = 0; _r < _h; _r++) {
        var _row = _r * _w;

        for (var _c = 0; _c < _w; _c++) {
            var _i = _row + _c;

            if ((_fl[_i] & GMNAV_FLAG_BLOCKED) != 0) {
                _cl[_i] = 0;
                continue;
            }

            var _ul = (_r == 0  || _c == 0)  ? 0 : _cl[_i - _w - 1];
            var _up = (_r == 0)              ? 0 : _cl[_i - _w];
            var _ur = (_r == 0  || _c == _wm)? 0 : _cl[_i - _w + 1];
            var _lf = (_c == 0)              ? 0 : _cl[_i - 1];

            var _v = min(min(_ul, _up), min(_ur, _lf)) + 1;
            _cl[_i] = (_v > _cap) ? _cap : _v;
        }
    }

    // backward: fold in obstacles below and to the right
    for (var _r = _hm; _r >= 0; _r--) {
        var _row = _r * _w;

        for (var _c = _wm; _c >= 0; _c--) {
            var _i = _row + _c;
            if (_cl[_i] == 0) continue;

            var _dr = (_r == _hm || _c == _wm) ? 0 : _cl[_i + _w + 1];
            var _dn = (_r == _hm)              ? 0 : _cl[_i + _w];
            var _dl = (_r == _hm || _c == 0)   ? 0 : _cl[_i + _w - 1];
            var _rt = (_c == _wm)              ? 0 : _cl[_i + 1];

            var _v = min(min(_dr, _dn), min(_dl, _rt)) + 1;
            if (_v < _cl[_i]) _cl[_i] = _v;
        }
    }

    _grid.clear   = _cl;
    _grid.clear_v = _grid.version;
    return true;
}

function gmnav_clearance_is_stale(_grid) {
    return (_grid.clear == undefined) || (_grid.clear_v != _grid.version);
}

function gmnav_clearance_build_if_stale(_grid) {
    if (gmnav_clearance_is_stale(_grid)) return gmnav_clearance_build(_grid);
    return true;
}

function gmnav_clearance_at(_grid, _node) {
    if (_grid.clear == undefined) return 0;
    return _grid.clear[_node];
}

function gmnav_clearance_for_radius(_grid, _radius) {
    var _lay = _grid.layout;
    var _t   = max(_lay.tile_w, _lay.tile_h);
    return max(1, ceil((_radius * 2) / _t));
}

function gmnav_clearance_nearest(_grid, _node, _need, _max_rings = 8) {
    if (_node == GMNAV_NO_NODE) return GMNAV_NO_NODE;
    if (_grid.clear == undefined) return _node;
    if (_grid.clear[_node] >= _need) return _node;

    var _w  = _grid.width;
    var _h  = _grid.height;
    var _cl = _grid.clear;

    var _c0 = _node % _w;
    var _r0 = _node div _w;

    for (var _ring = 1; _ring <= _max_rings; _ring++) {
        var _best  = GMNAV_NO_NODE;
        var _bestd = GMNAV_INF;

        for (var _dr = -_ring; _dr <= _ring; _dr++) {
            var _rr = _r0 + _dr;
            if (_rr < 0 || _rr >= _h) continue;

            var _edge = (abs(_dr) == _ring);
            var _step = _edge ? 1 : (_ring * 2);

            for (var _dc = -_ring; _dc <= _ring; _dc += _step) {
                var _cc = _c0 + _dc;
                if (_cc < 0 || _cc >= _w) continue;

                var _nn = _rr * _w + _cc;
                if (_cl[_nn] < _need) continue;

                var _d = _dc * _dc + _dr * _dr;
                if (_d < _bestd) { _bestd = _d; _best = _nn; }
            }
        }

        if (_best != GMNAV_NO_NODE) return _best;
    }
    return GMNAV_NO_NODE;
}