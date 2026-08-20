function gmnav_movement_create(_gravity, _jump_vel, _run_speed, _max_fall,
                               _width, _height,
                               _air_speed = undefined,
                               _jump_levels = 3,
                               _jump_bias = 1.15) {
    return {
        gravity     : _gravity,
        jump_vel    : _jump_vel,
        run_speed   : _run_speed,
        max_fall    : _max_fall,
        width       : _width,
        height      : _height,

        air_speed   : (_air_speed == undefined) ? _run_speed : _air_speed,

        jump_levels : max(1, _jump_levels),
        jump_min    : 0.5,   // weakest sampled jump, as a fraction of full
		jump_bias   : _jump_bias,
    };
}

function gmnav_platgraph_create(_grid, _movement) {
    if (_grid.layout.mode != gmnav_layout.ORTHO) {
        show_debug_message("GMNav: platformer graphs require an ORTHO layout.");
    }

    return {
        domain    : gmnav_domain.PLATFORM,

        grid      : _grid,
        move      : _movement,

        // node table
        nodes     : [],                              // platform node -> grid node
        node_of   : array_create(_grid.count, -1),   // grid node -> platform node
        count     : 0,

        // CSR adjacency, filled at flatten
        edge_start : [],
        edge_to    : [],
        edge_cost  : [],
        edge_type  : [],

        // scratch during bake
        tmp_to    : [],
        tmp_cost  : [],
        tmp_type  : [],

        phase     : gmnav_bake.IDLE,
        cursor    : 0,
        version   : -1,

        // world position per platform node, filled at flatten
        node_x    : [],
        node_y    : [],

        // longest displacement possible in one frame
        max_step  : point_distance(0, 0,
                                   max(_movement.run_speed, _movement.air_speed),
                                   _movement.max_fall),

        slots     : array_create(2, undefined),
        slot_max  : 2
    };
}

function gmnav_platgraph_bake(_pg) {
    gmnav_platgraph_bake_begin(_pg);

    var _guard = 0;
    while (_pg.phase != gmnav_bake.DONE) {
        gmnav_platgraph_bake_step(_pg, 512);
        if (++_guard > GMNAV_MAX_STEPS) break;
    }
    return (_pg.phase == gmnav_bake.DONE);
}

function gmnav_platgraph_bake_begin(_pg) {
    _pg.nodes    = [];
    _pg.node_of  = array_create(_pg.grid.count, -1);
    _pg.count    = 0;
    _pg.tmp_to   = [];
    _pg.tmp_cost = [];
    _pg.tmp_type = [];
    _pg.cursor   = 0;
    _pg.version  = _pg.grid.version;
    _pg.phase    = gmnav_bake.SURFACES;
    _pg.slots    = array_create(_pg.slot_max, undefined);
}

function gmnav_platgraph_bake_step(_pg, _budget = 256) {
    switch (_pg.phase) {
        case gmnav_bake.SURFACES: __gmnav_plat_scan(_pg, _budget * 8); break;
        case gmnav_bake.LINKS:    __gmnav_plat_link(_pg, _budget);     break;
    }
    return _pg.phase;
}

function gmnav_platgraph_is_ready(_pg) {
    return (_pg.phase == gmnav_bake.DONE);
}

function gmnav_platgraph_is_stale(_pg) {
    return (_pg.grid.version != _pg.version);
}

function gmnav_platgraph_node_at(_pg, _x, _y, _max_drop_cells = 4) {
    var _grid = _pg.grid;
    var _lay  = _grid.layout;
    var _w    = _grid.width;

    var _c = floor((_x - _lay.origin_x) / _lay.tile_w);
    if (_c < 0 || _c >= _w) return GMNAV_NO_NODE;

    var _r = floor((_y - 1 - _lay.origin_y) / _lay.tile_h);

    for (var i = 0; i <= _max_drop_cells; i++) {
        var _rr = _r + i;
        if (_rr < 0) continue;                  // above the map, keep dropping
        if (_rr >= _grid.height) break;         // below it, nothing left

        var _pn = _pg.node_of[_rr * _w + _c];
        if (_pn >= 0) return _pn;
    }
    return GMNAV_NO_NODE;
}

function gmnav_platgraph_node_world(_pg, _pnode) {
    var _grid = _pg.grid;
    var _lay  = _grid.layout;
    var _gn   = _pg.nodes[_pnode];

    var _c = _gn % _grid.width;
    var _r = _gn div _grid.width;

    return [_lay.origin_x + (_c + 0.5) * _lay.tile_w,
            _lay.origin_y + (_r + 1.0) * _lay.tile_h];
}

function __gmnav_plat_scan(_pg, _budget) {
    var _grid = _pg.grid;
    var _lay  = _grid.layout;
    var _w    = _grid.width;
    var _tot  = _grid.count;
    var _fl   = _grid.flags;

    var _hcells = max(1, ceil(_pg.move.height / _lay.tile_h));
    var _hwidth = _pg.move.width * 0.5;

    var _i   = _pg.cursor;
    var _end = min(_tot, _i + _budget);

    while (_i < _end) {
        var _c = _i % _w;
        var _r = _i div _w;

        if ((_fl[_i] & GMNAV_FLAG_BLOCKED) != 0) { _i++; continue; }

        var _below = gmnav_grid_node(_grid, _c, _r + 1);
        if (_below == GMNAV_NO_NODE) { _i++; continue; }

        var _bf = _fl[_below];
        var _is_ground = ((_bf & GMNAV_FLAG_BLOCKED) != 0)
                      || ((_bf & GMNAV_FLAG_ONEWAY)  != 0);
        if (!_is_ground) { _i++; continue; }

        var _fits = true;
        for (var k = 1; k < _hcells; k++) {
            var _up = gmnav_grid_node(_grid, _c, _r - k);
            if (_up == GMNAV_NO_NODE || (_fl[_up] & GMNAV_FLAG_BLOCKED) != 0) {
                _fits = false;
                break;
            }
        }

        if (_fits && _hwidth > _lay.tile_w * 0.5) {
            var _side = ceil(_hwidth / _lay.tile_w);
            for (var s = -_side; s <= _side && _fits; s++) {
                if (s == 0) continue;
                for (var k = 0; k < _hcells; k++) {
                    var _sn = gmnav_grid_node(_grid, _c + s, _r - k);
                    if (_sn == GMNAV_NO_NODE || (_fl[_sn] & GMNAV_FLAG_BLOCKED) != 0) {
                        _fits = false;
                        break;
                    }
                }
            }
        }

        if (_fits) {
            _pg.node_of[_i] = _pg.count;
            array_push(_pg.nodes, _i);
            array_push(_pg.tmp_to,   []);
            array_push(_pg.tmp_cost, []);
            array_push(_pg.tmp_type, []);
            _pg.count++;
        }

        _i++;
    }

    _pg.cursor = _i;

    if (_i >= _tot) {
        _pg.cursor = 0;
        _pg.phase  = (_pg.count > 0) ? gmnav_bake.LINKS : gmnav_bake.DONE;
    }
}

function __gmnav_plat_link(_pg, _budget) {
    var _i   = _pg.cursor;
    var _end = min(_pg.count, _i + _budget);

    while (_i < _end) {
        __gmnav_plat_links_for(_pg, _i);
        _i++;
    }

    _pg.cursor = _i;

    if (_i >= _pg.count) {
        __gmnav_plat_flatten(_pg);
        _pg.phase = gmnav_bake.DONE;
    }
}

function __gmnav_plat_links_for(_pg, _pnode) {
    var _grid = _pg.grid;
    var _lay  = _grid.layout;
    var _mv   = _pg.move;
    var _w    = _grid.width;

    var _gn = _pg.nodes[_pnode];
    var _c  = _gn % _w;
    var _r  = _gn div _w;

    var _fx = _lay.origin_x + (_c + 0.5) * _lay.tile_w;
    var _fy = _lay.origin_y + (_r + 1.0) * _lay.tile_h;

    for (var _d = -1; _d <= 1; _d += 2) {
        var _an = gmnav_grid_node(_grid, _c + _d, _r);
        if (_an == GMNAV_NO_NODE) continue;

        var _ap = _pg.node_of[_an];
        if (_ap < 0) continue;

        __gmnav_plat_add(_pg, _pnode, _ap,
                         _lay.tile_w / max(0.0001, _mv.run_speed),
                         gmnav_link.WALK);
    }

    for (var _d = -1; _d <= 1; _d += 2) {
        __gmnav_plat_simulate(_pg, _pnode, _fx, _fy,
                              _d * _mv.air_speed, 0, gmnav_link.FALL);
    }

    var _levels = _mv.jump_levels;
    for (var _l = 0; _l < _levels; _l++) {
        var _t = (_levels == 1) ? 1 : (_l / (_levels - 1));
        var _strength = lerp(_mv.jump_min, 1, _t);
        var _vy = -_mv.jump_vel * _strength;

        for (var _d = -1; _d <= 1; _d++) {
            __gmnav_plat_simulate(_pg, _pnode, _fx, _fy,
                                  _d * _mv.air_speed, _vy, gmnav_link.JUMP);
        }
    }
}

function __gmnav_plat_simulate(_pg, _from, _x0, _y0, _vx, _vy, _type) {
    var _grid = _pg.grid;
    var _lay  = _grid.layout;
    var _mv   = _pg.move;
    var _w    = _grid.width;

    var _x = _x0;
    var _y = _y0;
    var _frames = 0;

    var _armed = false;
	
    if (_type == gmnav_link.FALL) {
        if (_vx == 0) return;

        var _walked = 0;
        var _limit  = _lay.tile_w * 2;

        while (__gmnav_plat_blocked(_pg, _x, _y + 1, 1)) {
            if (_walked > _limit) return;                        // never left the ledge

            var _wx = _x + _vx;
            if (__gmnav_plat_blocked(_pg, _wx, _y, 0)) return;   // walled in

            _x = _wx;
            _walked += abs(_vx);
            _frames++;
        }
        _armed = true;
    }

    while (_frames < GMNAV_PLAT_MAX_SIM) {
        _frames++;

        _vy = min(_vy + _mv.gravity, _mv.max_fall);

        // horizontal
        var _nx = _x + _vx;
        if (__gmnav_plat_blocked(_pg, _nx, _y, 0)) {
            _vx = 0;                      // hit a wall, drop straight down
        } else {
            _x = _nx;
        }

        // vertical
        var _ny = _y + _vy;
        if (__gmnav_plat_blocked(_pg, _x, _ny, _vy)) {
            if (_vy < 0) {
                _vy = 0;                  // ceiling
                continue;
            }

            // landed
            var _lr = floor((_ny - _lay.origin_y) / _lay.tile_h);
            var _lc = floor((_x  - _lay.origin_x) / _lay.tile_w);

            if (!_armed) return;

            var _stand = gmnav_grid_node(_grid, _lc, _lr - 1);
            if (_stand == GMNAV_NO_NODE) return;

            var _to = _pg.node_of[_stand];
            if (_to < 0 || _to == _from) return;

            var _cx   = _lay.origin_x + (_lc + 0.5) * _lay.tile_w;
            var _cost = _frames + abs(_x - _cx) / max(0.0001, _mv.run_speed);

            if (_type == gmnav_link.JUMP) _cost *= _mv.jump_bias;

            __gmnav_plat_add(_pg, _from, _to, _cost, _type);
            return;
        }

        _y = _ny;

        if (!_armed && (_vy > 0 || abs(_x - _x0) > _lay.tile_w * 0.75)) {
            _armed = true;
        }

        if (_x < _lay.origin_x || _y < _lay.origin_y) return;
        if (_x > _lay.origin_x + _w * _lay.tile_w) return;
        if (_y > _lay.origin_y + _grid.height * _lay.tile_h) return;
    }
}

function __gmnav_plat_blocked(_pg, _x, _y, _vy) {
    var _grid = _pg.grid;
    var _lay  = _grid.layout;
    var _fl   = _grid.flags;
    var _w    = _grid.width;
    var _h    = _grid.height;

    var _hw = _pg.move.width * 0.5;

    var _c1 = floor((_x - _hw - _lay.origin_x) / _lay.tile_w);
    var _c2 = floor((_x + _hw - 0.001 - _lay.origin_x) / _lay.tile_w);
    var _r1 = floor((_y - _pg.move.height - _lay.origin_y) / _lay.tile_h);
    var _r2 = floor((_y - 0.001 - _lay.origin_y) / _lay.tile_h);

    for (var _r = _r1; _r <= _r2; _r++) {
        if (_r < 0 || _r >= _h) return true;

        for (var _c = _c1; _c <= _c2; _c++) {
            if (_c < 0 || _c >= _w) return true;

            var _f = _fl[_r * _w + _c];
            if ((_f & GMNAV_FLAG_BLOCKED) != 0) return true;

            if ((_f & GMNAV_FLAG_ONEWAY) != 0 && _vy > 0 && _r == _r2) {
                return true;
            }
        }
    }
    return false;
}

function __gmnav_plat_add(_pg, _from, _to, _cost, _type) {
    var _tos = _pg.tmp_to[_from];

    for (var i = 0; i < array_length(_tos); i++) {
        if (_tos[i] == _to) {
            if (_cost < _pg.tmp_cost[_from][i]) {
                _pg.tmp_cost[_from][i] = _cost;
                _pg.tmp_type[_from][i] = _type;
            }
            return;
        }
    }

    if (array_length(_tos) >= GMNAV_PLAT_MAX_LINKS) return;

    array_push(_pg.tmp_to[_from],   _to);
    array_push(_pg.tmp_cost[_from], _cost);
    array_push(_pg.tmp_type[_from], _type);
}

function __gmnav_plat_flatten(_pg) {
    var _n = _pg.count;

    var _start = array_create(_n + 1, 0);
    var _total = 0;

    for (var i = 0; i < _n; i++) {
        _start[i] = _total;
        _total += array_length(_pg.tmp_to[i]);
    }
    _start[_n] = _total;

    var _to   = array_create(_total, 0);
    var _cost = array_create(_total, 0);
    var _type = array_create(_total, 0);
    var _k    = 0;

    for (var i = 0; i < _n; i++) {
        var _ts = _pg.tmp_to[i];
        var _cs = _pg.tmp_cost[i];
        var _ty = _pg.tmp_type[i];

        for (var j = 0; j < array_length(_ts); j++) {
            _to[_k]   = _ts[j];
            _cost[_k] = _cs[j];
            _type[_k] = _ty[j];
            _k++;
        }
    }

    _pg.edge_start = _start;
    _pg.edge_to    = _to;
    _pg.edge_cost  = _cost;
    _pg.edge_type  = _type;
	
	var _lay = _pg.grid.layout;
    var _gw  = _pg.grid.width;
    var _nx  = array_create(_n, 0);
    var _ny  = array_create(_n, 0);

    for (var i = 0; i < _n; i++) {
        var _gn = _pg.nodes[i];
        _nx[i] = _lay.origin_x + ((_gn % _gw)   + 0.5) * _lay.tile_w;
        _ny[i] = _lay.origin_y + ((_gn div _gw) + 1.0) * _lay.tile_h;
    }

    _pg.node_x = _nx;
    _pg.node_y = _ny;

    _pg.tmp_to   = [];
    _pg.tmp_cost = [];
    _pg.tmp_type = [];
}