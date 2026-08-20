function gmnav_path_create(_grid, _nodes) {
    var _p = {
        grid   : _grid,
        nodes  : _nodes,
        px     : [],
        py     : [],
        count  : 0,
        length : 0,
        stale  : false
    };
    __gmnav_path_rebuild_points(_p);
    return _p;
}

function gmnav_path_get_count(_path) { return _path.count; }
function gmnav_path_get_x(_path, _i) { return _path.px[_i]; }
function gmnav_path_get_y(_path, _i) { return _path.py[_i]; }
function gmnav_path_get_length(_path) { return _path.length; }

function gmnav_path_anchor_start(_path, _x, _y) {
    if (_path.count == 0) return;
    _path.px[0] = _x;
    _path.py[0] = _y;
    __gmnav_path_measure(_path);
}

function gmnav_path_anchor_end(_path, _x, _y) {
    if (_path.count == 0) return;
    _path.px[_path.count - 1] = _x;
    _path.py[_path.count - 1] = _y;
    __gmnav_path_measure(_path);
}

function gmnav_grid_line_clear(_grid, _c0, _r0, _c1, _r1) {
    var _dc = abs(_c1 - _c0);
    var _dr = abs(_r1 - _r0);
    var _sc = (_c1 > _c0) ? 1 : -1;
    var _sr = (_r1 > _r0) ? 1 : -1;

    var _c = _c0, _r = _r0;
    var _n = _dc + _dr;
    var _e = _dc - _dr;

    _dc *= 2;
    _dr *= 2;

    var _fl = _grid.flags;
    var _w  = _grid.width;
    var _h  = _grid.height;

    for (var i = 0; i <= _n; i++) {
        if (_c < 0 || _r < 0 || _c >= _w || _r >= _h) return false;
        if ((_fl[_r * _w + _c] & GMNAV_FLAG_BLOCKED) != 0) return false;

        if (_c == _c1 && _r == _r1) return true;

        if (_e == 0) {
            var _nc = _c + _sc;
            var _nr = _r + _sr;
            if (_nc >= 0 && _nc < _w && (_fl[_r * _w + _nc] & GMNAV_FLAG_BLOCKED) != 0) return false;
            if (_nr >= 0 && _nr < _h && (_fl[_nr * _w + _c] & GMNAV_FLAG_BLOCKED) != 0) return false;

            _c += _sc;
            _r += _sr;
            _e += _dc - _dr;
            i++;
        } else if (_e > 0) {
            _c += _sc;
            _e -= _dr;
        } else {
            _r += _sr;
            _e += _dc;
        }
    }
    return true;
}

function gmnav_grid_node_line_clear(_grid, _a, _b) {
    var _w = _grid.width;
    return gmnav_grid_line_clear(_grid, _a % _w, _a div _w, _b % _w, _b div _w);
}

function gmnav_path_smooth(_path) {
    var _grid = _path.grid;
    var _mode = _grid.layout.mode;

    if (_mode != gmnav_layout.ORTHO && _mode != gmnav_layout.ISO_DIAMOND) return;

    var _n = array_length(_path.nodes);
    if (_n <= 2) return;

    var _src = _path.nodes;
    var _out = [_src[0]];
    var _i   = 0;

    while (_i < _n - 1) {
        var _best = _i + 1;

        for (var _j = _n - 1; _j > _i + 1; _j--) {
            if (gmnav_grid_node_line_clear(_grid, _src[_i], _src[_j])) {
                _best = _j;
                break;
            }
        }

        array_push(_out, _src[_best]);
        _i = _best;
    }

    _path.nodes = _out;
    __gmnav_path_rebuild_points(_path);
}

function gmnav_path_simplify(_path, _tolerance = 0.01) {
    var _n = _path.count;
    if (_n <= 2) return;

    var _px = _path.px;
    var _py = _path.py;

    var _ox = [_px[0]];
    var _oy = [_py[0]];

    for (var i = 1; i < _n - 1; i++) {
        var _ax = _px[i] - _ox[array_length(_ox) - 1];
        var _ay = _py[i] - _oy[array_length(_oy) - 1];
        var _bx = _px[i + 1] - _px[i];
        var _by = _py[i + 1] - _py[i];

        var _la = point_distance(0, 0, _ax, _ay);
        var _lb = point_distance(0, 0, _bx, _by);
        if (_la == 0 || _lb == 0) continue;

        var _cross = abs((_ax * _by - _ay * _bx) / (_la * _lb));
        if (_cross > _tolerance) {
            array_push(_ox, _px[i]);
            array_push(_oy, _py[i]);
        }
    }

    array_push(_ox, _px[_n - 1]);
    array_push(_oy, _py[_n - 1]);

    _path.px    = _ox;
    _path.py    = _oy;
    _path.count = array_length(_ox);
    _path.nodes = [];   // no longer corresponds 1:1 to cells
    __gmnav_path_measure(_path);
}

function gmnav_path_sample(_path, _dist) {
    var _n = _path.count;
    if (_n == 0) return [0, 0];
    if (_n == 1) return [_path.px[0], _path.py[0]];

    if (_dist <= 0) return [_path.px[0], _path.py[0]];
    if (_dist >= _path.length) return [_path.px[_n - 1], _path.py[_n - 1]];

    var _px = _path.px;
    var _py = _path.py;
    var _acc = 0;

    for (var i = 0; i < _n - 1; i++) {
        var _seg = point_distance(_px[i], _py[i], _px[i + 1], _py[i + 1]);
        if (_acc + _seg >= _dist) {
            var _t = (_seg > 0) ? (_dist - _acc) / _seg : 0;
            return [lerp(_px[i], _px[i + 1], _t),
                    lerp(_py[i], _py[i + 1], _t)];
        }
        _acc += _seg;
    }

    return [_px[_n - 1], _py[_n - 1]];
}

function __gmnav_path_rebuild_points(_path) {
    var _grid = _path.grid;
    var _lay  = _grid.layout;
    var _w    = _grid.width;
    var _src  = _path.nodes;
    var _n    = array_length(_src);

    var _px = array_create(_n, 0);
    var _py = array_create(_n, 0);

    for (var i = 0; i < _n; i++) {
        var _nd = _src[i];
        var _c  = _nd % _w;
        var _r  = _nd div _w;
        _px[i] = gmnav_layout_cell_x(_lay, _c, _r);
        _py[i] = gmnav_layout_cell_y(_lay, _c, _r);
    }

    _path.px    = _px;
    _path.py    = _py;
    _path.count = _n;
    __gmnav_path_measure(_path);
}

function __gmnav_path_measure(_path) {
    var _len = 0;
    var _px  = _path.px;
    var _py  = _path.py;

    for (var i = 0; i < _path.count - 1; i++) {
        _len += point_distance(_px[i], _py[i], _px[i + 1], _py[i + 1]);
    }
    _path.length = _len;
}