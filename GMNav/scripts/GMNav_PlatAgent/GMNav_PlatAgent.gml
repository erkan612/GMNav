function gmnav_platagent_create(_sched, _x, _y) {
    var _pg = _sched.target;
    var _n  = gmnav_platgraph_node_at(_pg, _x, _y);

    var _px = _x;
    var _py = _y;

    if (_n != GMNAV_NO_NODE) {
        _px = _pg.node_x[_n];
        _py = _pg.node_y[_n];
    }

    return {
        sched    : _sched,
        pg       : _pg,

        x        : _px,
        y        : _py,
        vx       : 0,
        vy       : 0,

        node     : _n,
        mode     : gmnav_pmode.GROUND,
        face     : 1,

        armed    : false,
        guard    : 0,

        path     : [],
        links    : [],
        seek     : 0,
        ticket   : undefined,
        link     : undefined,
        tx       : 0,
        ty       : 0,

        arrived  : false,
        failed   : false,
        desync   : 0,

        goal_x   : 0,
        goal_y   : 0,
        has_goal : false
    };
}

function gmnav_platagent_goto(_pa, _x, _y, _priority = gmnav_priority.NORMAL) {
    var _goal = gmnav_platgraph_node_at(_pa.pg, _x, _y);
    if (_goal == GMNAV_NO_NODE) return false;

    if (_pa.node == GMNAV_NO_NODE) return false;

    if (_pa.ticket != undefined) gmnav_scheduler_cancel(_pa.sched, _pa.ticket);

    var _from = _pa.node;
    if (_pa.mode == gmnav_pmode.LINK && gmnav_platagent_has_route(_pa)) {
        _from = _pa.path[_pa.seek + 1];
    }

    _pa.goal_x   = _x;
    _pa.goal_y   = _y;
    _pa.has_goal = true;
    _pa.arrived  = false;
    _pa.failed   = false;

    _pa.ticket = gmnav_scheduler_request(_pa.sched, _from, _goal, _priority);
    return true;
}

function gmnav_platagent_stop(_pa) {
    if (_pa.ticket != undefined) gmnav_scheduler_cancel(_pa.sched, _pa.ticket);

    _pa.ticket   = undefined;
    _pa.path     = [];
    _pa.links    = [];
    _pa.seek     = 0;
    _pa.link     = undefined;
    _pa.has_goal = false;
    _pa.arrived  = false;

    _pa.mode  = gmnav_pmode.GROUND;
    _pa.vx    = 0;
    _pa.vy    = 0;
    _pa.armed = false;

    if (_pa.node != GMNAV_NO_NODE) {
        _pa.x = _pa.pg.node_x[_pa.node];
        _pa.y = _pa.pg.node_y[_pa.node];
    }
}

function gmnav_platagent_arrived(_pa) {
    return _pa.arrived;
}

function gmnav_platagent_airborne(_pa) {
    return (_pa.mode == gmnav_pmode.LINK
         && _pa.link != undefined
         && _pa.link.type != gmnav_link.WALK);
}

function gmnav_platagent_has_route(_pa) {
    return (_pa.seek < array_length(_pa.path) - 1);
}

function gmnav_platagent_update(_pa) {
    var _mv = _pa.pg.move;

    var _pass = 0;
    while (++_pass <= 4) {
        switch (_pa.mode) {
            case gmnav_pmode.GROUND:
                if (!__gmnav_pa_ground(_pa, _mv)) return;
                break;

            case gmnav_pmode.SETTLE:
                if (!__gmnav_pa_settle(_pa, _mv)) return;
                break;

            case gmnav_pmode.LINK:
                __gmnav_pa_link(_pa, _mv);
                return;
        }
    }
}

function __gmnav_pa_ground(_pa, _mv) {
    if (_pa.ticket != undefined) {
        if (_pa.ticket.state == gmnav_state.FOUND) {
            _pa.path   = gmnav_scheduler_get_path(_pa.ticket);
            _pa.links  = gmnav_scheduler_get_links(_pa.ticket);
            _pa.seek   = 0;
            _pa.link   = undefined;
            _pa.ticket = undefined;

            if (array_length(_pa.path) <= 1) {
                _pa.arrived  = true;
                _pa.has_goal = false;
            }
        } else if (_pa.ticket.state == gmnav_state.FAILED) {
            _pa.ticket   = undefined;
            _pa.path     = [];
            _pa.links    = [];
            _pa.has_goal = false;
            _pa.failed   = true;
        }
    }

    if (!gmnav_platagent_has_route(_pa)) return false;

    var _from = _pa.path[_pa.seek];
    var _to   = _pa.path[_pa.seek + 1];
    var _lk   = gmnav_platgraph_link_get(_pa.pg, _from, _to);

    if (_lk == undefined) { // the graph changed under us
        gmnav_platagent_stop(_pa);
        return false;
    }

    _pa.link  = _lk;
    _pa.tx    = _lk.x;
    _pa.ty    = _lk.y;
    _pa.vx    = _lk.vx;
    _pa.vy    = _lk.vy;
    _pa.armed = false;
    _pa.guard = 0;
    _pa.mode  = gmnav_pmode.LINK;

    if (_lk.vx != 0) _pa.face = sign(_lk.vx);
    return true;
}

function __gmnav_pa_settle(_pa, _mv) {
    var _d = _pa.tx - _pa.x;

    if (abs(_d) <= _mv.run_speed) {
        var _already = (_d == 0);

        _pa.x    = _pa.tx;
        _pa.seek++;
        _pa.mode = gmnav_pmode.GROUND;

        if (!gmnav_platagent_has_route(_pa)) {
            _pa.arrived  = true;
            _pa.has_goal = false;
        }

        return _already;
    }

    _pa.x += sign(_d) * _mv.run_speed;
    return false;
}

function __gmnav_pa_link(_pa, _mv) {
    var _pg  = _pa.pg;
    var _lay = _pg.grid.layout;

    if (++_pa.guard > GMNAV_PLAT_MAX_SIM) { // should never happen
        __gmnav_pa_land(_pa, gmnav_platgraph_node_at(_pg, _pa.x, _pa.y));
        return;
    }

    // walking along a ledge, no arc involved
    if (_pa.link.type == gmnav_link.WALK) {
        var _d = _pa.tx - _pa.x;

        if (abs(_d) <= _mv.run_speed) {
            _pa.x = _pa.tx;
            _pa.y = _pa.ty;
            __gmnav_pa_land(_pa, _pa.path[_pa.seek + 1]);
        } else {
            _pa.x += sign(_d) * _mv.run_speed;
        }
        return;
    }

    // a FALL walks off the ledge first, then gravity takes over
    if (_pa.link.type == gmnav_link.FALL && !_pa.armed) {
        if (gmnav_platgraph_solid(_pg, _pa.x, _pa.y + 1, 1)) {
            if (gmnav_platgraph_solid(_pg, _pa.x + _pa.vx, _pa.y, 0)) {
                gmnav_platagent_stop(_pa);
                _pa.mode = gmnav_pmode.GROUND;
                return;
            }
            _pa.x += _pa.vx;
            return;
        }
        _pa.armed = true;
    }

    var _x0 = _pg.node_x[_pa.path[_pa.seek]];

    _pa.vy = min(_pa.vy + _mv.gravity, _mv.max_fall);

    var _nx = _pa.x + _pa.vx;
    if (gmnav_platgraph_solid(_pg, _nx, _pa.y, 0)) _pa.vx = 0;
    else                                           _pa.x  = _nx;

    var _ny = _pa.y + _pa.vy;
    if (gmnav_platgraph_solid(_pg, _pa.x, _ny, _pa.vy)) {
        if (_pa.vy < 0) {
            _pa.vy = 0; // ceiling, keep falling next frame
            return;
        }

        var _lr = floor((_ny - _lay.origin_y) / _lay.tile_h);
        var _lc = floor((_pa.x - _lay.origin_x) / _lay.tile_w);
        var _st = gmnav_grid_node(_pg.grid, _lc, _lr - 1);

        __gmnav_pa_land(_pa, (_st == GMNAV_NO_NODE) ? GMNAV_NO_NODE
                                                    : _pg.node_of[_st]);
        return;
    }

    _pa.y = _ny;

    if (!_pa.armed && (_pa.vy > 0 || abs(_pa.x - _x0) > _lay.tile_w * 0.75)) {
        _pa.armed = true;
    }
}

function __gmnav_pa_land(_pa, _landed) {
    var _want = _pa.path[_pa.seek + 1];

    _pa.vx = 0;
    _pa.vy = 0;

    if (_landed != _want) {
        _pa.desync++;
        if (_landed != GMNAV_NO_NODE) _pa.node = _landed;
        gmnav_platagent_stop(_pa); // resets mode and snaps x, y to node
        return;
    }

    _pa.node = _want;
    _pa.y    = _pa.ty;

    if (_pa.seek + 2 < array_length(_pa.path)) {
        var _nxt = gmnav_platgraph_link_get(_pa.pg, _want, _pa.path[_pa.seek + 2]);

        if (_nxt != undefined && _nxt.type == gmnav_link.WALK) {
            _pa.seek++;
            _pa.mode = gmnav_pmode.GROUND;
            return;
        }
    }

    _pa.mode = gmnav_pmode.SETTLE;
}