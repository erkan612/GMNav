function gmnav_agent_create(_sched, _x, _y, _radius = 8, _speed = 2) {
    return {
        sched      : _sched,
        grid       : _sched.grid,

        profile    : undefined,     // gmnav_costprofile_create(), or undefined
        need_clear : 0,             // minimum clearance, 0 to ignore

        x          : _x,
        y          : _y,
        vx         : 0,
        vy         : 0,

        radius     : _radius,
        speed      : _speed,
        accel      : 0.35,          // 0..1, how fast desired velocity is approached
        arrive_dist: 24,            // start slowing inside this range
        reach_dist : 4,             // considered arrived inside this range

        path       : undefined,
        ticket     : undefined,
        seek_i     : 1,             // index of the waypoint being steered toward

        arrived    : false,

        goal_x     : 0,
        goal_y     : 0,
        has_goal   : false,
        repath_at  : 0,             // guard against repath spam
        repath_gap : 20,

        avoid_str  : 1.0,           // 0 disables local avoidance
        avoid_range: 3.0            // multiples of radius
    };
}

function gmnav_agent_goto(_agent, _gx, _gy, _priority = gmnav_priority.NORMAL) {
    var _grid = _agent.grid;

    var _sn = gmnav_grid_world_to_node(_grid, _agent.x, _agent.y);
    var _gn = gmnav_grid_world_to_node(_grid, _gx, _gy);

    if (_sn == GMNAV_NO_NODE || _gn == GMNAV_NO_NODE) return false;

    if (_agent.ticket != undefined) {
        gmnav_scheduler_cancel(_agent.sched, _agent.ticket);
    }

    _agent.goal_x   = _gx;
    _agent.goal_y   = _gy;
    _agent.has_goal = true;
    _agent.arrived  = false;
    _agent.ticket   = gmnav_scheduler_request(_agent.sched, _sn, _gn, _priority,
                                              false, _agent.profile, _agent.need_clear);

    return true;
}

function gmnav_agent_stop(_agent) {
    if (_agent.ticket != undefined) {
        gmnav_scheduler_cancel(_agent.sched, _agent.ticket);
        _agent.ticket = undefined;
    }
    _agent.path     = undefined;
    _agent.has_goal = false;
    _agent.arrived  = false;
    _agent.seek_i   = 1;
}

function gmnav_agent_has_path(_agent) {
    return (_agent.path != undefined);
}

function gmnav_agent_arrived(_agent) {
    return _agent.arrived;
}

function gmnav_agent_update(_agent, _neighbours = undefined) {
    __gmnav_agent_collect_ticket(_agent);

    if (_agent.path == undefined) {
        _agent.vx = lerp(_agent.vx, 0, _agent.accel);
        _agent.vy = lerp(_agent.vy, 0, _agent.accel);
        return;
    }

    if (_agent.path.stale) {
        __gmnav_agent_try_repath(_agent);
    }

    __gmnav_agent_advance_waypoint(_agent);

    var _p = _agent.path;
    var _n = _p.count;

    if (_agent.seek_i >= _n) {
        _agent.path    = undefined;
        _agent.seek_i  = 1;
        _agent.arrived = true;
        _agent.vx = lerp(_agent.vx, 0, _agent.accel);
        _agent.vy = lerp(_agent.vy, 0, _agent.accel);
        return;
    }

    var _tx = _p.px[_agent.seek_i];
    var _ty = _p.py[_agent.seek_i];

    var _dx = _tx - _agent.x;
    var _dy = _ty - _agent.y;
    var _d  = point_distance(0, 0, _dx, _dy);

    var _spd = _agent.speed;

    if (_agent.seek_i == _n - 1 && _d < _agent.arrive_dist) {
        _spd *= (_d / _agent.arrive_dist);
    }

    var _dvx = 0, _dvy = 0;
    if (_d > 0.0001) {
        _dvx = (_dx / _d) * _spd;
        _dvy = (_dy / _d) * _spd;
    }

    if (_neighbours != undefined && _agent.avoid_str > 0) {
        var _av = __gmnav_agent_avoidance(_agent, _neighbours);
        _dvx += _av[0] * _spd * _agent.avoid_str;
        _dvy += _av[1] * _spd * _agent.avoid_str;

        var _m = point_distance(0, 0, _dvx, _dvy);
        if (_m > _spd) {
            _dvx = (_dvx / _m) * _spd;
            _dvy = (_dvy / _m) * _spd;
        }
    }

    _agent.vx = lerp(_agent.vx, _dvx, _agent.accel);
    _agent.vy = lerp(_agent.vy, _dvy, _agent.accel);
}

function __gmnav_agent_collect_ticket(_agent) {
    var _t = _agent.ticket;
    if (_t == undefined) return;

    if (_t.state == gmnav_state.FOUND) {
        var _p = gmnav_path_create(_agent.grid, gmnav_scheduler_get_path(_t));

        gmnav_path_smooth(_p);
        gmnav_path_anchor_start(_p, _agent.x, _agent.y);
        gmnav_path_anchor_end(_p, _agent.goal_x, _agent.goal_y);
        _p.stale = _t.stale;

        _agent.path   = _p;
        _agent.seek_i = min(1, _p.count - 1);
        _agent.ticket = undefined;

    } else if (_t.state == gmnav_state.FAILED) {
        _agent.ticket   = undefined;
        _agent.has_goal = false;
    }
}

function __gmnav_agent_advance_waypoint(_agent) {
    var _p = _agent.path;
    var _n = _p.count;
    var _r = max(_agent.reach_dist, _agent.speed);

    while (_agent.seek_i < _n - 1) {
        var _d = point_distance(_agent.x, _agent.y,
                                _p.px[_agent.seek_i],
                                _p.py[_agent.seek_i]);
        if (_d > _r) break;
        _agent.seek_i++;
    }

    if (_agent.seek_i == _n - 1) {
        var _dl = point_distance(_agent.x, _agent.y, _p.px[_n - 1], _p.py[_n - 1]);
        if (_dl <= _agent.reach_dist) _agent.seek_i = _n;
    }
}

function __gmnav_agent_try_repath(_agent) {
    if (!_agent.has_goal) return;
    if (_agent.ticket != undefined) return;
    if (current_time < _agent.repath_at) return;

    _agent.repath_at = current_time + _agent.repath_gap * (1000 / max(1, game_get_speed(gamespeed_fps)));

    var _sn = gmnav_grid_world_to_node(_agent.grid, _agent.x, _agent.y);
    var _gn = gmnav_grid_world_to_node(_agent.grid, _agent.goal_x, _agent.goal_y);
    if (_sn == GMNAV_NO_NODE || _gn == GMNAV_NO_NODE) return;

    _agent.ticket = gmnav_scheduler_request(_agent.sched, _sn, _gn,
                                            gmnav_priority.HIGH, false,
                                            _agent.profile, _agent.need_clear);
}

function __gmnav_agent_avoidance(_agent, _neighbours) {
    var _sx = 0, _sy = 0;
    var _cnt = 0;
    var _range = _agent.radius * _agent.avoid_range;

    for (var i = 0; i < array_length(_neighbours); i++) {
        var _o = _neighbours[i];
        if (_o == _agent) continue;

        var _dx = _agent.x - _o.x;
        var _dy = _agent.y - _o.y;
        var _d  = point_distance(0, 0, _dx, _dy);

        var _min_d = _agent.radius + _o.radius;
        if (_d > _range || _d > _min_d * 2) continue;

        if (_d < 0.0001) {
            var _ang = (_agent.seek_i * 73 + i * 137) % 360;
            _sx += dcos(_ang);
            _sy -= dsin(_ang);
            _cnt++;
            continue;
        }

        var _w = 1 - (_d / (_min_d * 2));
        _sx += (_dx / _d) * _w;
        _sy += (_dy / _d) * _w;
        _cnt++;
    }

    if (_cnt == 0) return [0, 0];

    var _m = point_distance(0, 0, _sx, _sy);
    if (_m < 0.0001) return [0, 0];

    return [_sx / _m, _sy / _m];
}