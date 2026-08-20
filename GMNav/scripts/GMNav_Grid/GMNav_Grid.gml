function gmnav_grid_create(_w, _h, _layout, _slots = 4) {
    var _n = _w * _h;

    return {
        domain   : gmnav_domain.GRID,

        width    : _w,
        height   : _h,
        count    : _n,
        layout   : _layout,

        flags    : array_create(_n, 0),
        cost     : array_create(_n, 1),

        clear    : undefined,   // clearance values, built on demand
        clear_v  : -1,          // grid version the clearance was built at

        version  : 0,

        slots    : array_create(_slots, undefined),
        slot_max : _slots
    };
}

function gmnav_grid_in_bounds(_grid, _col, _row) {
    return (_col >= 0 && _row >= 0 && _col < _grid.width && _row < _grid.height);
}

function gmnav_grid_node(_grid, _col, _row) {
    if (_col < 0 || _row < 0 || _col >= _grid.width || _row >= _grid.height) {
        return GMNAV_NO_NODE;
    }
    return _row * _grid.width + _col;
}

function gmnav_grid_col(_grid, _node) { return _node % _grid.width; }
function gmnav_grid_row(_grid, _node) { return _node div _grid.width; }

function gmnav_grid_world_to_node(_grid, _x, _y) {
    var _cr = gmnav_layout_world_to_cell(_grid.layout, _x, _y);
    return gmnav_grid_node(_grid, _cr[0], _cr[1]);
}

function gmnav_grid_node_to_world(_grid, _node) {
    return gmnav_layout_cell_to_world(_grid.layout,
                                      _node % _grid.width,
                                      _node div _grid.width);
}

function gmnav_grid_is_blocked(_grid, _node) {
    return (_grid.flags[_node] & GMNAV_FLAG_BLOCKED) != 0;
}

function gmnav_grid_has_flag(_grid, _node, _flag) {
    return (_grid.flags[_node] & _flag) != 0;
}

function gmnav_grid_get_cost(_grid, _node) {
    return _grid.cost[_node];
}

function gmnav_grid_set_blocked(_grid, _col, _row, _blocked) {
    var _n = gmnav_grid_node(_grid, _col, _row);
    if (_n == GMNAV_NO_NODE) return false;

    var _f  = _grid.flags[_n];
    var _nf = _blocked ? (_f | GMNAV_FLAG_BLOCKED) : (_f & ~GMNAV_FLAG_BLOCKED);

    if (_nf != _f) {
        _grid.flags[_n] = _nf;
        _grid.version++;
    }
    return true;
}

function gmnav_grid_set_cost(_grid, _col, _row, _cost) {
    var _n = gmnav_grid_node(_grid, _col, _row);
    if (_n == GMNAV_NO_NODE) return false;

    var _c = max(1, _cost);
    if (_grid.cost[_n] != _c) {
        _grid.cost[_n] = _c;
        _grid.version++;
    }
    return true;
}

function gmnav_grid_set_flag(_grid, _col, _row, _flag, _on) {
    var _n = gmnav_grid_node(_grid, _col, _row);
    if (_n == GMNAV_NO_NODE) return false;

    var _f  = _grid.flags[_n];
    var _nf = _on ? (_f | _flag) : (_f & ~_flag);

    if (_nf != _f) {
        _grid.flags[_n] = _nf;
        _grid.version++;
    }
    return true;
}

function gmnav_grid_fill_blocked(_grid, _c1, _r1, _c2, _r2, _blocked) {
    var _cl = clamp(min(_c1, _c2), 0, _grid.width  - 1);
    var _cr = clamp(max(_c1, _c2), 0, _grid.width  - 1);
    var _rt = clamp(min(_r1, _r2), 0, _grid.height - 1);
    var _rb = clamp(max(_r1, _r2), 0, _grid.height - 1);

    var _fl = _grid.flags;
    var _w  = _grid.width;

    for (var _r = _rt; _r <= _rb; _r++) {
        var _base = _r * _w;
        for (var _c = _cl; _c <= _cr; _c++) {
            var _i = _base + _c;
            _fl[_i] = _blocked ? (_fl[_i] | GMNAV_FLAG_BLOCKED)
                               : (_fl[_i] & ~GMNAV_FLAG_BLOCKED);
        }
    }
    _grid.version++;
}

function gmnav_grid_import_tilemap(_grid, _tilemap, _is_blocked = undefined) {
    var _w  = min(_grid.width,  tilemap_get_width(_tilemap));
    var _h  = min(_grid.height, tilemap_get_height(_tilemap));
    var _fl = _grid.flags;
    var _gw = _grid.width;

    for (var _r = 0; _r < _h; _r++) {
        var _base = _r * _gw;
        for (var _c = 0; _c < _w; _c++) {
            var _tile = tile_get_index(tilemap_get(_tilemap, _c, _r));

            var _b = (_is_blocked == undefined) ? (_tile != 0)
                                                : _is_blocked(_tile);

            var _i = _base + _c;
            _fl[_i] = _b ? (_fl[_i] | GMNAV_FLAG_BLOCKED)
                         : (_fl[_i] & ~GMNAV_FLAG_BLOCKED);
        }
    }
    _grid.version++;
}

function gmnav_grid_import_dsgrid(_grid, _ds, _is_blocked = undefined) {
    var _w  = min(_grid.width,  ds_grid_width(_ds));
    var _h  = min(_grid.height, ds_grid_height(_ds));
    var _fl = _grid.flags;
    var _gw = _grid.width;

    for (var _r = 0; _r < _h; _r++) {
        var _base = _r * _gw;
        for (var _c = 0; _c < _w; _c++) {
            var _v = _ds[# _c, _r];

            var _b = (_is_blocked == undefined) ? (_v != 0)
                                                : _is_blocked(_v);

            var _i = _base + _c;
            _fl[_i] = _b ? (_fl[_i] | GMNAV_FLAG_BLOCKED)
                         : (_fl[_i] & ~GMNAV_FLAG_BLOCKED);
        }
    }
    _grid.version++;
}

function gmnav_grid_import_callback(_grid, _fn) {
    var _fl = _grid.flags;
    var _cs = _grid.cost;
    var _gw = _grid.width;

    for (var _r = 0; _r < _grid.height; _r++) {
        var _base = _r * _gw;
        for (var _c = 0; _c < _gw; _c++) {
            var _res = _fn(_c, _r);
            var _i   = _base + _c;

            if (is_struct(_res)) {
                var _b = _res[$ "blocked"] ?? false;
                _fl[_i] = _b ? (_fl[_i] | GMNAV_FLAG_BLOCKED)
                             : (_fl[_i] & ~GMNAV_FLAG_BLOCKED);
                _fl[_i] |= (_res[$ "flags"] ?? 0);
                _cs[_i]  = max(1, _res[$ "cost"] ?? 1);
            } else {
                _fl[_i] = _res ? (_fl[_i] | GMNAV_FLAG_BLOCKED)
                               : (_fl[_i] & ~GMNAV_FLAG_BLOCKED);
            }
        }
    }
    _grid.version++;
}

function gmnav_grid_scratch_acquire(_grid) {
    for (var i = 0; i < _grid.slot_max; i++) {
        var _s = _grid.slots[i];

        if (_s == undefined) {
            var _n = _grid.count;
            _s = {
                index  : i,
                busy   : true,
                gen    : 1,
                mark   : array_create(_n, 0),
                g      : array_create(_n, 0),
                parent : array_create(_n, GMNAV_NO_NODE),
                depth  : array_create(_n, 0)
            };
            _grid.slots[i] = _s;
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

function gmnav_grid_scratch_release(_grid, _slot) {
    if (_slot != undefined) _slot.busy = false;
}

function gmnav_grid_scratch_flush(_grid) {
    for (var i = 0; i < _grid.slot_max; i++) {
        if (_grid.slots[i] != undefined && !_grid.slots[i].busy) {
            _grid.slots[i] = undefined;
        }
    }
}