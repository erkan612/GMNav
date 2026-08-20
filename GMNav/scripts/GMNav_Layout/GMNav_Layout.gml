function gmnav_parity(_v) {
    var _m = _v % 2;
    return (_m < 0) ? _m + 2 : _m;
}

function gmnav_layout_cell_parity(_lay, _col, _row) {
    switch (_lay.parity_axis) {
        case 1: return gmnav_parity(_row);
        case 2: return gmnav_parity(_col);
    }
    return 0;
}

function gmnav_layout_create(_mode, _tile_w, _tile_h,
                             _neighbours = gmnav_neighbours.EIGHT,
                             _cost_mode  = gmnav_costmode.LOGICAL,
                             _origin_x   = 0,
                             _origin_y   = 0) {
    var _lay = {
        mode			: _mode,
        tile_w			: _tile_w,
        tile_h			: _tile_h,
        neighbours		: _neighbours,
        cost_mode		: _cost_mode,
        origin_x		: _origin_x,
        origin_y		: _origin_y,
        parity_axis		: 0,          // 0 none, 1 row parity, 2 column parity
        nb_count		: 0,
        nb_dc			: [ ],
        nb_dr			: [ ],
        nb_cost			: [ ],
        step_min_world	: 1,
    };

    switch (_mode) {
        case gmnav_layout.ISO_STAGGERED:
        case gmnav_layout.HEX_POINTY:  _lay.parity_axis = 1; break;
        case gmnav_layout.HEX_FLAT:    _lay.parity_axis = 2; break;
        default:                       _lay.parity_axis = 0; break;
    }

    if (_mode == gmnav_layout.HEX_POINTY || _mode == gmnav_layout.HEX_FLAT) {
        _lay.neighbours = gmnav_neighbours.SIX;
    }

    __gmnav_layout_build_neighbours(_lay);
    return _lay;
}

function gmnav_layout_cell_to_world(_lay, _col, _row) {
    var _tw = _lay.tile_w, _th = _lay.tile_h;
    switch (_lay.mode) {
        case gmnav_layout.ORTHO:
            return [_lay.origin_x + (_col + 0.5) * _tw,
                    _lay.origin_y + (_row + 0.5) * _th];

        case gmnav_layout.ISO_DIAMOND:
            return [_lay.origin_x + (_col - _row) * _tw * 0.5,
                    _lay.origin_y + (_col + _row) * _th * 0.5];

        case gmnav_layout.ISO_STAGGERED:
            return [_lay.origin_x + _col * _tw + gmnav_parity(_row) * _tw * 0.5,
                    _lay.origin_y + _row * _th * 0.5];

        case gmnav_layout.HEX_POINTY:
            return [_lay.origin_x + (_col + gmnav_parity(_row) * 0.5) * _tw,
                    _lay.origin_y + _row * _th * 0.75];

        case gmnav_layout.HEX_FLAT:
            return [_lay.origin_x + _col * _tw * 0.75,
                    _lay.origin_y + (_row + gmnav_parity(_col) * 0.5) * _th];
    }
    return [0, 0];
}

function gmnav_layout_world_to_cell(_lay, _x, _y) {
    var _tw = _lay.tile_w, _th = _lay.tile_h;
    var _px = _x - _lay.origin_x;
    var _py = _y - _lay.origin_y;

    switch (_lay.mode) {
        case gmnav_layout.ORTHO:
            return [floor(_px / _tw), floor(_py / _th)];

        case gmnav_layout.ISO_DIAMOND: {
            var _a = _px / (_tw * 0.5);   // col - row
            var _b = _py / (_th * 0.5);   // col + row
            return [round((_a + _b) * 0.5), round((_b - _a) * 0.5)];
        }

        case gmnav_layout.ISO_STAGGERED: {
            var _r = round(_py / (_th * 0.5));
            var _c = round((_px - gmnav_parity(_r) * _tw * 0.5) / _tw);
            return __gmnav_stagger_refine(_lay, _x, _y, _c, _r);
        }

        case gmnav_layout.HEX_POINTY: {
            var _nx = (_px / _tw) * 1.7320508075688772;
            var _ny = (_py / (_th * 0.75)) * 1.5;
            var _ax = __gmnav_hex_round((0.5773502691896258 * _nx) - (_ny / 3.0),
                                        (2.0 / 3.0) * _ny);
            var _rr = _ax[1];
            return [_ax[0] + ((_rr - gmnav_parity(_rr)) div 2), _rr];
        }

        case gmnav_layout.HEX_FLAT: {
            var _nx = (_px / (_tw * 0.75)) * 1.5;
            var _ny = (_py / _th) * 1.7320508075688772;
            var _ax = __gmnav_hex_round((2.0 / 3.0) * _nx,
                                        (-_nx / 3.0) + (0.5773502691896258 * _ny));
            var _qq = _ax[0];
            return [_qq, _ax[1] + ((_qq - gmnav_parity(_qq)) div 2)];
        }
    }
    return [0, 0];
}

function __gmnav_hex_round(_q, _r) {
    var _cx = _q, _cz = _r, _cy = -_q - _r;
    var _rx = round(_cx), _ry = round(_cy), _rz = round(_cz);
    var _dx = abs(_rx - _cx), _dy = abs(_ry - _cy), _dz = abs(_rz - _cz);

    if (_dx > _dy && _dx > _dz)  _rx = -_ry - _rz;
    else if (_dy > _dz)          _ry = -_rx - _rz;
    else                         _rz = -_rx - _ry;

    return [_rx, _rz];
}

function __gmnav_stagger_refine(_lay, _x, _y, _col, _row) {
    var _p = gmnav_parity(_row);
    var _cands = [ _col,          _row,
                   _col - 1 + _p, _row - 1,
                   _col + _p,     _row - 1,
                   _col - 1 + _p, _row + 1,
                   _col + _p,     _row + 1 ];

    var _bc = _col, _br = _row, _bd = infinity;
    for (var i = 0; i < 10; i += 2) {
        var _c = _cands[i], _r = _cands[i + 1];
        var _w = gmnav_layout_cell_to_world(_lay, _c, _r);
        var _d = sqr(_w[0] - _x) + sqr(_w[1] - _y);
        if (_d < _bd) { _bd = _d; _bc = _c; _br = _r; }
    }
    return [_bc, _br];
}

function __gmnav_layout_build_neighbours(_lay) {
    var _dce = [], _dre = [], _dco = [], _dro = [];

    switch (_lay.mode) {
        case gmnav_layout.ORTHO:
        case gmnav_layout.ISO_DIAMOND:
            if (_lay.neighbours == gmnav_neighbours.EIGHT) {
                _dce = [ 1, -1,  0,  0,  1,  1, -1, -1];
                _dre = [ 0,  0,  1, -1,  1, -1,  1, -1];
            } else {
                _dce = [ 1, -1,  0,  0];
                _dre = [ 0,  0,  1, -1];
            }
            _dco = _dce; _dro = _dre;
            break;

        case gmnav_layout.ISO_STAGGERED:
            if (_lay.neighbours == gmnav_neighbours.EIGHT) {
                _dce = [-1,  0, -1,  0,  1, -1,  0,  0];
                _dre = [-1, -1,  1,  1,  0,  0, -2,  2];
                _dco = [ 0,  1,  0,  1,  1, -1,  0,  0];
                _dro = [-1, -1,  1,  1,  0,  0, -2,  2];
            } else {
                _dce = [-1,  0, -1,  0];
                _dre = [-1, -1,  1,  1];
                _dco = [ 0,  1,  0,  1];
                _dro = [-1, -1,  1,  1];
            }
            break;

        case gmnav_layout.HEX_POINTY:   // odd-r offset
            _dce = [ 1,  0, -1, -1, -1,  0];
            _dre = [ 0, -1, -1,  0,  1,  1];
            _dco = [ 1,  1,  0, -1,  0,  1];
            _dro = [ 0, -1, -1,  0,  1,  1];
            break;

        case gmnav_layout.HEX_FLAT:     // odd-q offset
            _dce = [ 0,  1,  1,  0, -1, -1];
            _dre = [-1, -1,  0,  1,  0, -1];
            _dco = [ 0,  1,  1,  0, -1, -1];
            _dro = [-1,  0,  1,  1,  1,  0];
            break;
    }

    var _n = array_length(_dce);
    _lay.nb_count = _n;
    _lay.nb_dc    = array_create(_n * 2);
    _lay.nb_dr    = array_create(_n * 2);
    _lay.nb_cost  = array_create(_n * 2);

    for (var i = 0; i < _n; i++) {
        _lay.nb_dc[i]      = _dce[i];
        _lay.nb_dr[i]      = _dre[i];
        _lay.nb_dc[_n + i] = _dco[i];
        _lay.nb_dr[_n + i] = _dro[i];
    }

    __gmnav_layout_build_costs(_lay);
}

function __gmnav_layout_build_costs(_lay) {
    var _n = _lay.nb_count;

    var _geo = (_lay.cost_mode == gmnav_costmode.VISUAL)
            || (_lay.mode == gmnav_layout.ISO_STAGGERED)
            || (_lay.mode == gmnav_layout.HEX_POINTY)
            || (_lay.mode == gmnav_layout.HEX_FLAT);

    var _min_world = infinity;

    for (var _p = 0; _p < 2; _p++) {
        var _bc = 4, _br = 4;
        if (_lay.parity_axis == 1) _br = 4 + _p;
        if (_lay.parity_axis == 2) _bc = 4 + _p;

        var _fx = gmnav_layout_cell_x(_lay, _bc, _br);
        var _fy = gmnav_layout_cell_y(_lay, _bc, _br);

        for (var i = 0; i < _n; i++) {
            var _idx = _p * _n + i;
            var _dc  = _lay.nb_dc[_idx];
            var _dr  = _lay.nb_dr[_idx];

            var _tx = gmnav_layout_cell_x(_lay, _bc + _dc, _br + _dr);
            var _ty = gmnav_layout_cell_y(_lay, _bc + _dc, _br + _dr);
            var _wd = point_distance(_fx, _fy, _tx, _ty);

            _min_world = min(_min_world, _wd);
            _lay.nb_cost[_idx] = _geo ? _wd : sqrt(_dc * _dc + _dr * _dr);
        }
    }

    _lay.step_min_world = _min_world;

    var _min = infinity;
    for (var i = 0; i < _n * 2; i++) _min = min(_min, _lay.nb_cost[i]);
    if (_min > 0) {
        for (var i = 0; i < _n * 2; i++) _lay.nb_cost[i] /= _min;
    }
}

function gmnav_layout_cell_x(_lay, _col, _row) {
    switch (_lay.mode) {
        case gmnav_layout.ORTHO:
            return _lay.origin_x + (_col + 0.5) * _lay.tile_w;
        case gmnav_layout.ISO_DIAMOND:
            return _lay.origin_x + (_col - _row) * _lay.tile_w * 0.5;
        case gmnav_layout.ISO_STAGGERED:
            return _lay.origin_x + _col * _lay.tile_w + gmnav_parity(_row) * _lay.tile_w * 0.5;
        case gmnav_layout.HEX_POINTY:
            return _lay.origin_x + (_col + gmnav_parity(_row) * 0.5) * _lay.tile_w;
        case gmnav_layout.HEX_FLAT:
            return _lay.origin_x + _col * _lay.tile_w * 0.75;
    }
    return 0;
}

function gmnav_layout_cell_y(_lay, _col, _row) {
    switch (_lay.mode) {
        case gmnav_layout.ORTHO:
            return _lay.origin_y + (_row + 0.5) * _lay.tile_h;
        case gmnav_layout.ISO_DIAMOND:
            return _lay.origin_y + (_col + _row) * _lay.tile_h * 0.5;
        case gmnav_layout.ISO_STAGGERED:
            return _lay.origin_y + _row * _lay.tile_h * 0.5;
        case gmnav_layout.HEX_POINTY:
            return _lay.origin_y + _row * _lay.tile_h * 0.75;
        case gmnav_layout.HEX_FLAT:
            return _lay.origin_y + (_row + gmnav_parity(_col) * 0.5) * _lay.tile_h;
    }
    return 0;
}