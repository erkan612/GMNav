function gmnav_path_create(_grid, _nodes) {
    var _p = {
        grid   : _grid,
        nodes  : _nodes,
        px     : [],
        py     : [],
        count  : 0,
        length : 0,
        stale  : false,
		version : _grid.version,
    };
    __gmnav_path_rebuild_points(_p);
    return _p;
}

function gmnav_path_get_count(_path)  { return _path.count;  }
function gmnav_path_get_x(_path, _i)  { return _path.px[_i]; }
function gmnav_path_get_y(_path, _i)  { return _path.py[_i]; }
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
    return gmnav_grid_line_clear(_grid,
                                 gmnav_grid_col(_grid, _a), gmnav_grid_row(_grid, _a),
                                 gmnav_grid_col(_grid, _b), gmnav_grid_row(_grid, _b));
}

function __gmnav_path_heading_ok(_grid, _a, _b, _dirs) { // may a unit travel this segment in one straight move
    if (_dirs <= 0) return true;

    var _dc = gmnav_grid_col(_grid, _b) - gmnav_grid_col(_grid, _a);
    var _dr = gmnav_grid_row(_grid, _b) - gmnav_grid_row(_grid, _a);

    if (_dc == 0 && _dr == 0) return true;

    // cardinal is legal under every count
    if (_dc == 0 || _dr == 0) return true;

    // and a true diagonal once diagonals exist at all
    if (_dirs >= 8) return (abs(_dc) == abs(_dr));

    return false;
}

function __gmnav_path_two_leg(_grid, _a, _b, _dirs, _mc, _md, _rad) { // can a to b be walked as two legal legs, and if so where is the corner
    if (_a >= _grid.count || _b >= _grid.count) return GMNAV_NO_NODE;

    var _ac = gmnav_grid_col(_grid, _a), _ar = gmnav_grid_row(_grid, _a);
    var _bc = gmnav_grid_col(_grid, _b), _br = gmnav_grid_row(_grid, _b);

    var _dc = _bc - _ac;
    var _dr = _br - _ar;

    if (_dc == 0 || _dr == 0) return GMNAV_NO_NODE;   // one leg already covers it

    var _try = [];

    if (_dirs >= 8) {
        var _m  = min(abs(_dc), abs(_dr));
        var _sc = sign(_dc);
        var _sr = sign(_dr);

        array_push(_try, gmnav_grid_node(_grid, _ac + _sc * _m, _ar + _sr * _m));
        array_push(_try, gmnav_grid_node(_grid, _bc - _sc * _m, _br - _sr * _m));
    }

    // both orders, since a wall may leave only one of them viable
    array_push(_try, gmnav_grid_node(_grid, _bc, _ar));
    array_push(_try, gmnav_grid_node(_grid, _ac, _br));

    for (var k = 0; k < array_length(_try); k++) {
        var _c = _try[k];

        if (_c == GMNAV_NO_NODE || _c == _a || _c == _b) continue;
        if (gmnav_grid_is_blocked(_grid, _c)) continue;

        if (!__gmnav_path_heading_ok(_grid, _a, _c, _dirs)) continue;
        if (!__gmnav_path_heading_ok(_grid, _c, _b, _dirs)) continue;

        if (!__gmnav_path_corridor_ok(_grid, _a, _c, _mc, _md, _rad)) continue;
        if (!__gmnav_path_corridor_ok(_grid, _c, _b, _mc, _md, _rad)) continue;

        return _c;
    }
    return GMNAV_NO_NODE;
}

function gmnav_path_smooth(_path, _max_climb = undefined, _max_drop = undefined,
                           _radius = 0, _headings = 0) {
    var _grid = _path.grid;
    var _mode = _grid.layout.mode;

    if (_mode != gmnav_layout.ORTHO && _mode != gmnav_layout.ISO_DIAMOND) return;

    var _n = array_length(_path.nodes);
    if (_n <= 2) return;

    var _src = _path.nodes;
    var _out = [_src[0]];
    var _i   = 0;

    while (_i < _n - 1) {
        var _best   = _i + 1;
        var _corner = GMNAV_NO_NODE;

        for (var _j = _n - 1; _j > _i + 1; _j--) {
            if (!__gmnav_path_same_layer(_grid, _src, _i, _j)) continue;

            if (__gmnav_path_heading_ok(_grid, _src[_i], _src[_j], _headings)
            &&  __gmnav_path_corridor_ok(_grid, _src[_i], _src[_j],
                                         _max_climb, _max_drop, _radius)) {
                _best = _j;
                break;
            }
        }

        if (_headings > 0 && _best == _i + 1) {
            for (var _k = _n - 1; _k > _i + 1; _k--) {
                if (!__gmnav_path_same_layer(_grid, _src, _i, _k)) continue;

                var _c = __gmnav_path_two_leg(_grid, _src[_i], _src[_k], _headings,
                                              _max_climb, _max_drop, _radius);
                if (_c != GMNAV_NO_NODE) {
                    _best   = _k;
                    _corner = _c;
                    break;
                }
            }
        }

        if (_corner != GMNAV_NO_NODE) array_push(_out, _corner);

        array_push(_out, _src[_best]);
        _i = _best;
    }

    _path.nodes = _out;
    __gmnav_path_rebuild_points(_path);
}

function gmnav_path_simplify(_path, _tolerance = 0.01,
                             _max_climb = undefined, _max_drop = undefined) {
    var _n = _path.count;
    if (_n <= 2) return;

    var _grid = _path.grid;
    var _px   = _path.px;
    var _py   = _path.py;
    var _nd   = _path.nodes;

    var _has_nodes = (array_length(_nd) == _n);

    var _ox = [_px[0]];
    var _oy = [_py[0]];

    for (var i = 1; i < _n - 1; i++) {
        var _lx = _ox[array_length(_ox) - 1];
        var _ly = _oy[array_length(_oy) - 1];

        var _ax = _px[i] - _lx;
        var _ay = _py[i] - _ly;
        var _bx = _px[i + 1] - _px[i];
        var _by = _py[i + 1] - _py[i];

        var _la = point_distance(0, 0, _ax, _ay);
        var _lb = point_distance(0, 0, _bx, _by);
        if (_la == 0 || _lb == 0) continue;

        var _cross = abs((_ax * _by - _ay * _bx) / (_la * _lb));
        var _keep  = (_cross > _tolerance);

        if (!_keep && _has_nodes) {
            var _lp = gmnav_grid_node_layer(_grid, _nd[i - 1]);
            var _lc = gmnav_grid_node_layer(_grid, _nd[i]);
            var _lx2 = gmnav_grid_node_layer(_grid, _nd[i + 1]);

            if (_lc != _lp || _lc != _lx2) _keep = true;
        }

        if (!_keep && !__gmnav_path_seg_z_ok(_grid, _lx, _ly,
                                             _px[i + 1], _py[i + 1],
                                             _max_climb, _max_drop)) {
            _keep = true;
        }

        if (_keep) {
            array_push(_ox, _px[i]);
            array_push(_oy, _py[i]);
        }
    }

    array_push(_ox, _px[_n - 1]);
    array_push(_oy, _py[_n - 1]);

    _path.px    = _ox;
    _path.py    = _oy;
    _path.count = array_length(_ox);
    _path.nodes = []; // no longer corresponds 1:1 to cells
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
    var _src  = _path.nodes;
    var _n    = array_length(_src);

    var _px = array_create(_n, 0);
    var _py = array_create(_n, 0);

    //var _lift = gmnav_grid_layer_lift(_grid);

    //for (var i = 0; i < _n; i++) { // through the accessors, not a modulo, so overlay ids resolve
    //    var _c = gmnav_grid_col(_grid, _src[i]);
    //    var _r = gmnav_grid_row(_grid, _src[i]);
    //    var _l = gmnav_grid_node_layer(_grid, _src[i]);

    //    _px[i] = gmnav_layout_cell_x(_lay, _c, _r);
    //    _py[i] = gmnav_layout_cell_y(_lay, _c, _r) - _l * _lift;
    //}
	
    for (var i = 0; i < _n; i++) {
        var _p = gmnav_grid_node_to_world(_grid, _src[i]);
        _px[i] = _p[0];
        _py[i] = _p[1];
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

function __gmnav_path_line_z_ok(_grid, _a, _b, _climb, _drop) {
    if (_climb == undefined) return true;
    if (!gmnav_grid_has_heights(_grid)) return true;

    var _w  = _grid.width;
    var _h  = _grid.height;
    var _hz = _grid.height_z;

    var _c0 = _a % _w, _r0 = _a div _w;
    var _c1 = _b % _w, _r1 = _b div _w;

    var _dc = abs(_c1 - _c0);
    var _dr = abs(_r1 - _r0);
    var _sc = (_c1 > _c0) ? 1 : -1;
    var _sr = (_r1 > _r0) ? 1 : -1;

    var _c = _c0, _r = _r0;
    var _n = _dc + _dr;
    var _e = _dc - _dr;

    _dc *= 2;
    _dr *= 2;

    var _pz = _hz[_r0 * _w + _c0];

    for (var i = 0; i <= _n; i++) {
        if (_c < 0 || _r < 0 || _c >= _w || _r >= _h) return false;

        var _z  = _hz[_r * _w + _c];
        var _dz = _z - _pz;
        if (_dz > _climb || -_dz > _drop) return false;
        _pz = _z;

        if (_c == _c1 && _r == _r1) return true;

        if (_e == 0) {
            var _nc = _c + _sc;
            var _nr = _r + _sr;

            if (_nc >= 0 && _nc < _w) {
                var _fz = _hz[_r * _w + _nc] - _pz;
                if (_fz > _climb || -_fz > _drop) return false;
            }
            if (_nr >= 0 && _nr < _h) {
                var _gz = _hz[_nr * _w + _c] - _pz;
                if (_gz > _climb || -_gz > _drop) return false;
            }

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

function __gmnav_path_seg_z_ok(_grid, _x0, _y0, _x1, _y1, _climb, _drop) {
    if (_climb == undefined) return true;
    if (!gmnav_grid_has_heights(_grid)) return true;

    var _a = gmnav_grid_world_to_node(_grid, _x0, _y0);
    var _b = gmnav_grid_world_to_node(_grid, _x1, _y1);

    if (_a == GMNAV_NO_NODE || _b == GMNAV_NO_NODE) return false;

    return __gmnav_path_line_z_ok(_grid, _a, _b, _climb, _drop);
}

function __gmnav_path_corridor_ok(_grid, _a, _b, _climb, _drop, _radius) {
    if (!gmnav_grid_node_line_clear(_grid, _a, _b)) return false;

    var _uses_z = (_climb != undefined) && gmnav_grid_has_heights(_grid);

    if (_uses_z && !__gmnav_path_line_z_ok(_grid, _a, _b, _climb, _drop)) return false;
    if (_radius <= 0) return true;

    var _lay = _grid.layout;
    var _w   = _grid.width;
    var _h   = _grid.height;
    var _fl  = _grid.flags;
    var _hz  = _uses_z ? _grid.height_z : undefined;

    var _x0 = _lay.origin_x + ((_a % _w)   + 0.5) * _lay.tile_w;
    var _y0 = _lay.origin_y + ((_a div _w) + 0.5) * _lay.tile_h;
    var _x1 = _lay.origin_x + ((_b % _w)   + 0.5) * _lay.tile_w;
    var _y1 = _lay.origin_y + ((_b div _w) + 0.5) * _lay.tile_h;

    var _step = min(_lay.tile_w, _lay.tile_h) * 0.25;
    var _n    = max(1, ceil(point_distance(_x0, _y0, _x1, _y1) / _step));

    for (var s = 0; s <= _n; s++) {
        var _t = s / _n;
        var _sx = lerp(_x0, _x1, _t);
        var _sy = lerp(_y0, _y1, _t);

        var _cc = floor((_sx - _lay.origin_x) / _lay.tile_w);
        var _cr = floor((_sy - _lay.origin_y) / _lay.tile_h);
        if (_cc < 0 || _cr < 0 || _cc >= _w || _cr >= _h) return false;

        var _here = _uses_z ? _hz[_cr * _w + _cc] : 0;

        var _fc1 = floor((_sx - _radius - _lay.origin_x) / _lay.tile_w);
        var _fc2 = floor((_sx + _radius - 0.001 - _lay.origin_x) / _lay.tile_w);
        var _fr1 = floor((_sy - _radius - _lay.origin_y) / _lay.tile_h);
        var _fr2 = floor((_sy + _radius - 0.001 - _lay.origin_y) / _lay.tile_h);

        for (var _fr = _fr1; _fr <= _fr2; _fr++) {
            if (_fr < 0 || _fr >= _h) return false;

            for (var _fc = _fc1; _fc <= _fc2; _fc++) {
                if (_fc < 0 || _fc >= _w) return false;

                var _fn = _fr * _w + _fc;
                if ((_fl[_fn] & GMNAV_FLAG_BLOCKED) != 0) return false;

                if (_uses_z) {
                    var _dz = _hz[_fn] - _here;
                    if (_dz > _climb || -_dz > _drop) return false;
                }
            }
        }
    }
    return true;
}

function __gmnav_path_same_layer(_grid, _nodes, _i, _j) {
    if (!gmnav_grid_has_overlay(_grid)) return true;

    var _l = gmnav_grid_node_layer(_grid, _nodes[_i]);

    for (var k = _i + 1; k <= _j; k++) {
        if (gmnav_grid_node_layer(_grid, _nodes[k]) != _l) return false;
    }
    return true;
}

function __gmnav_curve_clear(_grid, _x1, _y1, _x2, _y2, _layer, _body) { // is this world segment walkable, body included
    var _a = gmnav_grid_world_to_node(_grid, _x1, _y1, _layer);
    var _b = gmnav_grid_world_to_node(_grid, _x2, _y2, _layer);

    if (_a == GMNAV_NO_NODE || _b == GMNAV_NO_NODE) return false;
    if (gmnav_grid_is_blocked(_grid, _a) || gmnav_grid_is_blocked(_grid, _b)) return false;

    if (!gmnav_grid_line_clear(_grid,
            gmnav_grid_col(_grid, _a), gmnav_grid_row(_grid, _a),
            gmnav_grid_col(_grid, _b), gmnav_grid_row(_grid, _b))) return false;

    if (_body <= 0) return true;

    // the body sweeps wider than the line, so the flanks are tested too
    var _dx = _x2 - _x1;
    var _dy = _y2 - _y1;
    var _d  = point_distance(0, 0, _dx, _dy);
    if (_d <= 0) return true;

    var _nx = (-_dy / _d) * _body;
    var _ny = ( _dx / _d) * _body;

    for (var _s = -1; _s <= 1; _s += 2) {
        var _p1 = gmnav_grid_world_to_node(_grid, _x1 + _nx * _s, _y1 + _ny * _s, _layer);
        var _p2 = gmnav_grid_world_to_node(_grid, _x2 + _nx * _s, _y2 + _ny * _s, _layer);

        if (_p1 == GMNAV_NO_NODE || _p2 == GMNAV_NO_NODE) return false;
        if (gmnav_grid_is_blocked(_grid, _p1) || gmnav_grid_is_blocked(_grid, _p2)) return false;
    }
    return true;
}

function gmnav_path_curve(_path, _mode = gmnav_curve.NONE, _radius = 16,
                          _samples = 4, _body = 0, _min_turn = 5) {
    if (_mode == gmnav_curve.NONE) return;
    if (_path.count < 3) return;

    var _grid = _path.grid;
    var _m    = _grid.layout.mode;

    // the validator walks cells, so the same layouts smoothing refuses are refused here rather than returning a confidently wrong curve
    if (_m != gmnav_layout.ORTHO && _m != gmnav_layout.ISO_DIAMOND) return;

    var _layer = 0;
    if (array_length(_path.nodes) > 0) {
        _layer = max(0, gmnav_grid_node_layer(_grid, _path.nodes[0]));
    }

    var _px = _path.px;
    var _py = _path.py;
    var _n  = _path.count;

    var _ox = [_px[0]];
    var _oy = [_py[0]];

    if (_mode == gmnav_curve.CORNER) {
        for (var i = 1; i < _n - 1; i++) {
            var _ax = _px[i] - _px[i - 1], _ay = _py[i] - _py[i - 1];
            var _bx = _px[i + 1] - _px[i], _by = _py[i + 1] - _py[i];

            var _la = point_distance(0, 0, _ax, _ay);
            var _lb = point_distance(0, 0, _bx, _by);

            if (_la <= 0 || _lb <= 0) continue;

            var _turn = abs(angle_difference(point_direction(0, 0, _bx, _by),
                                             point_direction(0, 0, _ax, _ay)));

            // a joint that is nearly straight is not a corner worth rounding
            if (_turn < _min_turn) {
                array_push(_ox, _px[i]);
                array_push(_oy, _py[i]);
                continue;
            }

            // clamped to half a leg, so two corners never eat the same segment
            var _r = min(_radius, _la * 0.5, _lb * 0.5);

            var _sx = _px[i] - (_ax / _la) * _r;
            var _sy = _py[i] - (_ay / _la) * _r;
            var _ex = _px[i] + (_bx / _lb) * _r;
            var _ey = _py[i] + (_by / _lb) * _r;

            var _arc = [];
            var _ok  = true;

            for (var s = 0; s <= _samples; s++) {
                var _t = s / _samples;
                var _u = 1 - _t;

                var _qx = _u * _u * _sx + 2 * _u * _t * _px[i] + _t * _t * _ex;
                var _qy = _u * _u * _sy + 2 * _u * _t * _py[i] + _t * _t * _ey;

                array_push(_arc, [_qx, _qy]);
            }

            for (var k = 0; k < array_length(_arc) - 1 && _ok; k++) {
                if (!__gmnav_curve_clear(_grid, _arc[k][0], _arc[k][1],
                                                _arc[k + 1][0], _arc[k + 1][1],
                                                _layer, _body)) _ok = false;
            }

            if (!_ok) { // a curve that clips is worse than a corner, so the corner stands
                array_push(_ox, _px[i]);
                array_push(_oy, _py[i]);
                continue;
            }

            for (var q = 0; q < array_length(_arc); q++) {
                array_push(_ox, _arc[q][0]);
                array_push(_oy, _arc[q][1]);
            }
        }
    } else {
        for (var j = 0; j < _n - 1; j++) {
            var _p0 = max(0, j - 1);
            var _p3 = min(_n - 1, j + 2);

            var _seg = [];
            var _fine = true;

            for (var t2 = 1; t2 <= _samples; t2++) {
                var _tt = t2 / _samples;
                var _t2 = _tt * _tt;
                var _t3 = _t2 * _tt;

                // Catmull-Rom
                var _cx = 0.5 * ((2 * _px[j])
                        + (-_px[_p0] + _px[j + 1]) * _tt
                        + (2 * _px[_p0] - 5 * _px[j] + 4 * _px[j + 1] - _px[_p3]) * _t2
                        + (-_px[_p0] + 3 * _px[j] - 3 * _px[j + 1] + _px[_p3]) * _t3);

                var _cy = 0.5 * ((2 * _py[j])
                        + (-_py[_p0] + _py[j + 1]) * _tt
                        + (2 * _py[_p0] - 5 * _py[j] + 4 * _py[j + 1] - _py[_p3]) * _t2
                        + (-_py[_p0] + 3 * _py[j] - 3 * _py[j + 1] + _py[_p3]) * _t3);

                array_push(_seg, [_cx, _cy]);
            }

            var _lx = _px[j], _ly = _py[j];
            for (var w = 0; w < array_length(_seg) && _fine; w++) {
                if (!__gmnav_curve_clear(_grid, _lx, _ly, _seg[w][0], _seg[w][1],
                                         _layer, _body)) _fine = false;
                _lx = _seg[w][0];
                _ly = _seg[w][1];
            }

            if (_fine) {
                for (var v = 0; v < array_length(_seg); v++) {
                    array_push(_ox, _seg[v][0]);
                    array_push(_oy, _seg[v][1]);
                }
            } else {
                array_push(_ox, _px[j + 1]);
                array_push(_oy, _py[j + 1]);
            }
        }
    }

    if (_mode == gmnav_curve.CORNER) {
        array_push(_ox, _px[_n - 1]);
        array_push(_oy, _py[_n - 1]);
    }

    _path.px    = _ox;
    _path.py    = _oy;
    _path.count = array_length(_ox);

    __gmnav_path_measure(_path);
}