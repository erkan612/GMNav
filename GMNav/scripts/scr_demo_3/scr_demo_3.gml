enum demo3_mode {
    GROUND,   // standing on a node, about to take the next link
    LINK,     // mid-link, integrating the stored launch
    SETTLE    // landed, walking to the node's exact x
}

function demo3_build_level(_grid) {
    var _w = _grid.width;
    var _h = _grid.height;

    if (_w < 40 || _h < 20) {
        show_debug_message("demo3: needs at least a 40x20 grid, room is too small.");
    }

    var _s = _h - 5;

    gmnav_grid_fill_blocked(_grid, 0,      0, _w - 1, 0,      true);
    gmnav_grid_fill_blocked(_grid, 0,      0, 0,      _h - 1, true);
    gmnav_grid_fill_blocked(_grid, _w - 1, 0, _w - 1, _h - 1, true);

    // earth runs all the way to the right wall, no void at the edge
    gmnav_grid_fill_blocked(_grid, 1, _s + 1, _w - 2, _h - 1, true);

    // pit A, 3 cells, inside the 4-cell jump limit
    // pit B, 6 cells, over it, so the search has to climb the three steps
    gmnav_grid_fill_blocked(_grid, 8,  _s + 1, 10, _h - 1, false);
    gmnav_grid_fill_blocked(_grid, 21, _s + 1, 26, _h - 1, false);

    gmnav_grid_fill_blocked(_grid, 4,  _s - 2, 7,  _s - 2, true);   // left ledge
    gmnav_grid_fill_blocked(_grid, 12, _s - 2, 15, _s - 2, true);   // centre ledge

    // one-way deck above the centre ledge, jump up through it, stand on top
    for (var _c = 12; _c <= 15; _c++) {
        gmnav_grid_set_flag(_grid, _c, _s - 5, GMNAV_FLAG_ONEWAY, true);
    }

    gmnav_grid_fill_blocked(_grid, 19, _s - 1, 20, _s - 1, true);   // step 1
    gmnav_grid_fill_blocked(_grid, 23, _s - 3, 24, _s - 3, true);   // step 2
    gmnav_grid_fill_blocked(_grid, 27, _s - 1, 28, _s - 1, true);   // step 3

    // out of reach on purpose, tracks the right wall
    gmnav_grid_fill_blocked(_grid, _w - 6, _s - 10, _w - 3, _s - 10, true);
}

function demo3_movement() {
    // gravity, jump_vel, run_speed, max_fall, width, height, air_speed, jump_levels
    return gmnav_movement_create(0.5, 12, 3, 12, 20, 44, 4, 7);
}

function demo3_character_create(_pg, _sched, _pnode) {
    return {
        pg      : _pg,
        sched   : _sched,

        x       : _pg.node_x[_pnode],
        y       : _pg.node_y[_pnode],
        node    : _pnode,

        mode    : demo3_mode.GROUND,
        vx      : 0,
        vy      : 0,
        armed   : false,
        guard   : 0,      // frames spent inside the current link

        path    : [],
        links   : [],
        seek    : 0,
        ticket  : undefined,
        link    : undefined,
        tx      : 0,
        ty      : 0,

        failed  : false,  // last search found nothing
        desync  : 0,      // landed somewhere the graph did not predict
        face    : 1
    };
}

function demo3_goto(_c, _x, _y) {
    var _goal = gmnav_platgraph_node_at(_c.pg, _x, _y);
    if (_goal == GMNAV_NO_NODE) return false;

    if (_c.ticket != undefined) gmnav_scheduler_cancel(_c.sched, _c.ticket);

    var _from = _c.node;
    if (_c.mode == demo3_mode.LINK && demo3_has_route(_c)) {
        _from = _c.path[_c.seek + 1];
    }

    _c.failed = false;
    _c.ticket = gmnav_scheduler_request(_c.sched, _from, _goal,
                                        gmnav_priority.NORMAL);
    return true;
}

function demo3_stop(_c) {
    if (_c.ticket != undefined) gmnav_scheduler_cancel(_c.sched, _c.ticket);
    _c.ticket = undefined;
    _c.path   = [];
    _c.links  = [];
    _c.seek   = 0;
    _c.link   = undefined;
}

function demo3_has_route(_c) {
    return (_c.seek < array_length(_c.path) - 1);
}

function demo3_update(_c) {
    var _mv = _c.pg.move;

    // GROUND and SETTLE only change state, so they must not eat a frame,
    // otherwise every tile costs two frames of standing still
    var _pass = 0;
    while (++_pass <= 4) {
        switch (_c.mode) {
            case demo3_mode.GROUND:
                if (!__demo3_ground(_c, _mv)) return;
                break;

            case demo3_mode.SETTLE:
                if (!__demo3_settle(_c, _mv)) return;
                break;

            case demo3_mode.LINK:
                __demo3_link(_c, _mv);
                return;
        }
    }
}

function __demo3_ground(_c, _mv) {
    // the character sits exactly on its node here, the only point where a
    // new route can be adopted without throwing off the next launch
    if (_c.ticket != undefined) {
        if (_c.ticket.state == gmnav_state.FOUND) {
            _c.path   = gmnav_scheduler_get_path(_c.ticket);
            _c.links  = gmnav_scheduler_get_links(_c.ticket);
            _c.seek   = 0;
            _c.link   = undefined;
            _c.ticket = undefined;
        } else if (_c.ticket.state == gmnav_state.FAILED) {
            _c.ticket = undefined;
            _c.path   = [];
            _c.links  = [];
            _c.failed = true;
        }
    }

    if (!demo3_has_route(_c)) return false;

    var _from = _c.path[_c.seek];
    var _to   = _c.path[_c.seek + 1];
    var _lk   = gmnav_platgraph_link_get(_c.pg, _from, _to);

    if (_lk == undefined) {
        demo3_stop(_c);
        return false;
    }

    _c.link  = _lk;
    _c.tx    = _lk.x;
    _c.ty    = _lk.y;
    _c.vx    = _lk.vx;
    _c.vy    = _lk.vy;
    _c.armed = false;
    _c.guard = 0;
    _c.mode  = demo3_mode.LINK;

    if (_lk.vx != 0) _c.face = sign(_lk.vx);
    return true;
}

function __demo3_settle(_c, _mv) {
    var _d = _c.tx - _c.x;

    if (abs(_d) <= _mv.run_speed) {
        var _already = (_d == 0);

        _c.x    = _c.tx;
        _c.seek++;
        _c.mode = demo3_mode.GROUND;

        return _already;
    }

    _c.x += sign(_d) * _mv.run_speed;
    return false;
}

function __demo3_link(_c, _mv) {
    var _pg  = _c.pg;
    var _lay = _pg.grid.layout;

    if (++_c.guard > GMNAV_PLAT_MAX_SIM) {   // shouldn;t happen
        __demo3_land(_c, gmnav_platgraph_node_at(_pg, _c.x, _c.y));
        return;
    }

    // walking along a ledge, no arc involved
    if (_c.link.type == gmnav_link.WALK) {
        var _d = _c.tx - _c.x;

        if (abs(_d) <= _mv.run_speed) {
            _c.x = _c.tx;
            _c.y = _c.ty;
            __demo3_land(_c, _c.path[_c.seek + 1]);
        } else {
            _c.x += sign(_d) * _mv.run_speed;
        }
        return;
    }

    // a FALL walks off the ledge first, then gravity takes over
    if (_c.link.type == gmnav_link.FALL && !_c.armed) {
        if (gmnav_platgraph_solid(_pg, _c.x, _c.y + 1, 1)) {
            if (gmnav_platgraph_solid(_pg, _c.x + _c.vx, _c.y, 0)) {
                demo3_stop(_c);
                _c.mode = demo3_mode.GROUND;
                return;
            }
            _c.x += _c.vx;
            return;
        }
        _c.armed = true;
    }

    var _x0 = _pg.node_x[_c.path[_c.seek]];

    _c.vy = min(_c.vy + _mv.gravity, _mv.max_fall);

    var _nx = _c.x + _c.vx;
    if (gmnav_platgraph_solid(_pg, _nx, _c.y, 0)) _c.vx = 0;
    else                                          _c.x  = _nx;

    var _ny = _c.y + _c.vy;
    if (gmnav_platgraph_solid(_pg, _c.x, _ny, _c.vy)) {
        if (_c.vy < 0) {
            _c.vy = 0;                       // ceiling, keep falling next frame
            return;
        }

        var _lr = floor((_ny - _lay.origin_y) / _lay.tile_h);
        var _lc = floor((_c.x - _lay.origin_x) / _lay.tile_w);
        var _st = gmnav_grid_node(_pg.grid, _lc, _lr - 1);

        __demo3_land(_c, (_st == GMNAV_NO_NODE) ? GMNAV_NO_NODE
                                                : _pg.node_of[_st]);
        return;
    }

    _c.y = _ny;

    if (!_c.armed && (_c.vy > 0 || abs(_c.x - _x0) > _lay.tile_w * 0.75)) {
        _c.armed = true;
    }
}

function __demo3_land(_c, _landed) {
    var _want = _c.path[_c.seek + 1];

    _c.vx = 0;
    _c.vy = 0;

    if (_landed != _want) {
        _c.desync++;
        _c.node = (_landed == GMNAV_NO_NODE) ? _c.node : _landed;
        _c.y    = _c.pg.node_y[_c.node];
        _c.x    = _c.pg.node_x[_c.node];
        demo3_stop(_c);
        _c.mode = demo3_mode.GROUND;
        return;
    }

    _c.node = _want;
    _c.y    = _c.ty;

    if (_c.seek + 2 < array_length(_c.path)) {
        var _nxt = gmnav_platgraph_link_get(_c.pg, _want, _c.path[_c.seek + 2]);

        if (_nxt != undefined && _nxt.type == gmnav_link.WALK) {
            _c.seek++;
            _c.mode = demo3_mode.GROUND;
            return;
        }
    }

    _c.mode = demo3_mode.SETTLE;
}

function demo3_arc_points(_pg, _from, _to) {
    var _lk = gmnav_platgraph_link_get(_pg, _from, _to);
    if (_lk == undefined || _lk.type == gmnav_link.WALK) return [];

    var _lay = _pg.grid.layout;
    var _mv  = _pg.move;

    var _x  = _pg.node_x[_from];
    var _y  = _pg.node_y[_from];
    var _x0 = _x;
    var _vx = _lk.vx;
    var _vy = _lk.vy;

    var _out   = [[_x, _y]];
    var _armed = false;
    var _f     = 0;

    if (_lk.type == gmnav_link.FALL) {
        while (gmnav_platgraph_solid(_pg, _x, _y + 1, 1)) {
            if (_f++ > GMNAV_PLAT_MAX_SIM) return _out;
            if (gmnav_platgraph_solid(_pg, _x + _vx, _y, 0)) return _out;
            _x += _vx;
            array_push(_out, [_x, _y]);
        }
        _armed = true;
    }

    while (_f++ < GMNAV_PLAT_MAX_SIM) {
        _vy = min(_vy + _mv.gravity, _mv.max_fall);

        var _nx = _x + _vx;
        if (gmnav_platgraph_solid(_pg, _nx, _y, 0)) _vx = 0;
        else                                        _x  = _nx;

        var _ny = _y + _vy;
        if (gmnav_platgraph_solid(_pg, _x, _ny, _vy)) {
            if (_vy < 0) { _vy = 0; continue; }
            array_push(_out, [_x, _ny]);
            return _out;
        }

        _y = _ny;
        array_push(_out, [_x, _y]);

        if (!_armed && (_vy > 0 || abs(_x - _x0) > _lay.tile_w * 0.75)) {
            _armed = true;
        }
    }
    return _out;
}

function demo3_airborne(_c) {
    return (_c.mode == demo3_mode.LINK
         && _c.link != undefined
         && _c.link.type != gmnav_link.WALK);
}

function demo3_arc_apex(_pg, _from, _to) {
    var _pts = demo3_arc_points(_pg, _from, _to);
    var _n   = array_length(_pts);
    if (_n == 0) return 0;

    var _top = _pg.node_y[_from];
    for (var i = 0; i < _n; i++) _top = min(_top, _pts[i][1]);

    return round(_pg.node_y[_from] - _top);
}