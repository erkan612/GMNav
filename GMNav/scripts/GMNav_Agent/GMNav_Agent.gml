function gmnav_agent_create(_sched, _x, _y, _radius = 8, _speed = 2) {
    return {
        sched      : _sched,
        grid       : _sched.grid,

        profile    : undefined,				// gmnav_costprofile_create(), or undefined
        need_clear : 0,						// minimum clearance, 0 to ignore
											
        layer      : 0,						// the layer that the agent stands on
											
        max_climb  : undefined,				
        max_drop   : undefined,				
											
        x          : _x,					
        y          : _y,					
        vx         : 0,						
        vy         : 0,						
											
        radius     : _radius,				
        headings : 0,						// 0 leaves smoothing unconstrained, 4 or 8 hold it to the movement model
        speed      : _speed,				
        accel      : 0.35,					// 0..1, how fast desired velocity is approached
        arrive_dist: 24,					// start slowing inside this range
        reach_dist : 4,						// considered arrived inside this range
											
        path       : undefined,				
        ticket     : undefined,				
        seek_i     : 1,						// index of the waypoint being steered toward
											
        arrived    : false,					
        failed : false,						// the last goal could not be routed to. cleared by the next goto or stop
											
        goal_x     : 0,						
        goal_y     : 0,						
        goal_layer : 0,						
        has_goal   : false,					
        repath_at  : 0,						// guard against repath spam
        repath_gap : 20,
		
        curve_mode   : gmnav_curve.NONE,
        curve_radius : 16,
        curve_steps  : 4,

        avoid_str  : 1.0,					// 0 disables local avoidance
        avoid_range: 3.0,					// multiples of radius

        avoid_mode : gmnav_avoid.BASIC,		// BASIC, CONTEXT or FOLLOW

        // mode-specific tuning

        // BASIC
        basic_clear_div  : 3.0,				// clearance that produces a full strength push. larger means tight spaces weaken avoidance less
        basic_clear_min  : 0.15,			// floor on the clearance scale, so a corner does not fully mute the push
        basic_open_min   : 0.2,				// the same floor for the fallback when clearance was never built
											
        // CONTEXT							
        cs_probes        : 16,				// direction samples. 8 is coarse, 16 is standard, 24 is smooth
        cs_wall_weight   : 2.0,				// how hard a wall rejects a direction
        cs_wall_range    : 2.5,				// how far ahead a probe looks for a wall, in radius units
        cs_danger_weight : 1.5,				// how much a blocked neighbour penalizes a probe
											
        // FOLLOW							
        follow_gap       : 1.6,				// full speed at this gap, in radius-sum units. larger means a more patient queue
        follow_min       : 0.9,				// hard stop just below this gap, same units. do not push past 1.3
        follow_floor     : 0.15,			// slowest the queue can go. zero deadlocks
        follow_cone      : 0.4,				// half-width of the ahead cone, same units
        follow_sep       : 0.3,				// separation strength when bodies overlap. 0 disables separation entirely
        follow_sep_range : 1.5				// how close before separation kicks in, in radius units
    };
}

function gmnav_agent_goto(_agent, _gx, _gy, _priority = gmnav_priority.NORMAL,
                          _goal_layer = 0) {
    var _grid = _agent.grid;

    var _sn = gmnav_grid_world_to_node(_grid, _agent.x, _agent.y, _agent.layer);
    var _gn = gmnav_grid_world_to_node(_grid, _gx, _gy, _goal_layer);

    if (_sn == GMNAV_NO_NODE && _agent.layer != 0) {
        _sn = gmnav_grid_world_to_node(_grid, _agent.x, _agent.y, 0);
        if (_sn != GMNAV_NO_NODE) _agent.layer = 0;
    }

    if (_sn == GMNAV_NO_NODE || _gn == GMNAV_NO_NODE) return false;

    if (_agent.ticket != undefined) {
        gmnav_scheduler_cancel(_agent.sched, _agent.ticket);
    }

    _agent.goal_x     = _gx;
    _agent.goal_y     = _gy;
    _agent.goal_layer = _goal_layer;   // kept so a repath asks for the same surface
    _agent.has_goal   = true;
    _agent.arrived    = false;
    _agent.failed	  = false;
    _agent.ticket     = gmnav_scheduler_request(_agent.sched, _sn, _gn, _priority,
                                                false, _agent.profile, _agent.need_clear,
                                                _agent.max_climb, _agent.max_drop);

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
    _agent.failed   = false; // how tf did i miss this
    _agent.seek_i   = 1;
}

function gmnav_agent_has_path(_agent) {
    return (_agent.path != undefined);
}

function gmnav_agent_arrived(_agent) {
    return _agent.arrived;
}

function gmnav_agent_failed(_agent) { // the last goal could not be routed to, latched like arrived
    return _agent.failed;
}

function gmnav_agent_update(_agent, _neighbours = undefined) {
    __gmnav_agent_collect_ticket(_agent);

    if (_agent.path == undefined) {
        _agent.vx = lerp(_agent.vx, 0, _agent.accel);
        _agent.vy = lerp(_agent.vy, 0, _agent.accel);
        return;
    }

    //if (_agent.path.stale || _agent.path.version != _agent.grid.version) {
    //    __gmnav_agent_try_repath(_agent);
    //}
    if (_agent.path.stale || __gmnav_agent_path_disturbed(_agent)) {
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

    //if (_neighbours != undefined && _agent.avoid_str > 0) { // how tf can i keep missing this?
    //    var _av = __gmnav_agent_avoid(_agent, _neighbours, _dvx, _dvy);

    //    var _scl = _av[2];

    //    _dvx = _dvx * _scl + _av[0] * _spd * _agent.avoid_str;
    //    _dvy = _dvy * _scl + _av[1] * _spd * _agent.avoid_str;

    //    var _m = point_distance(0, 0, _dvx, _dvy);
    //    if (_m > _spd) {
    //        _dvx = (_dvx / _m) * _spd;
    //        _dvy = (_dvy / _m) * _spd;
    //    }
    //}

    if (_neighbours != undefined && _agent.avoid_str > 0) {
        var _av = __gmnav_agent_avoid(_agent, _neighbours, _dvx, _dvy);

        var _px = _av[0] * _spd * _agent.avoid_str;
        var _py = _av[1] * _spd * _agent.avoid_str;

        if (_d > 0.0001) {
            var _ux  = _dx / _d;
            var _uy  = _dy / _d;
            var _dot = _px * _ux + _py * _uy;

            if (_dot < 0) {
                _px -= _dot * _ux;
                _py -= _dot * _uy;
            }
        }

        _dvx += _px;
        _dvy += _py;

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

        gmnav_path_smooth(_p, _agent.max_climb, _agent.max_drop,
                          _agent.radius, _agent.headings, _agent.profile);
        gmnav_path_anchor_start(_p, _agent.x, _agent.y);
        gmnav_path_anchor_end(_p, _agent.goal_x, _agent.goal_y);
        gmnav_path_curve(_p, _agent.curve_mode, _agent.curve_radius,
                         _agent.curve_steps, _agent.radius);
        _p.stale = _t.stale;

        _agent.path   = _p;
        _agent.seek_i = min(1, _p.count - 1);
        _agent.ticket = undefined;

    } else if (_t.state == gmnav_state.FAILED) {
        _agent.ticket   = undefined;
        _agent.has_goal = false;
        _agent.failed   = true;
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

    var _nodes = _p.nodes;
    var _cnt   = array_length(_nodes);

    if (_cnt > 0) {
        var _idx = clamp(_agent.seek_i - 1, 0, _cnt - 1);
        var _l   = gmnav_grid_node_layer(_agent.grid, _nodes[_idx]);

        if (_l >= 0) _agent.layer = _l;
    }
}

function __gmnav_agent_try_repath(_agent) {
    if (!_agent.has_goal) return;
    if (_agent.ticket != undefined) return;
    if (current_time < _agent.repath_at) return;

    _agent.repath_at = current_time + _agent.repath_gap * (1000 / max(1, game_get_speed(gamespeed_fps)));

    var _grid = _agent.grid;

    var _sn = gmnav_grid_world_to_node(_grid, _agent.x, _agent.y, _agent.layer);

    if (_sn == GMNAV_NO_NODE && _agent.layer != 0) {
        _sn = gmnav_grid_world_to_node(_grid, _agent.x, _agent.y, 0);
        if (_sn != GMNAV_NO_NODE) _agent.layer = 0;
    }

    var _gn = gmnav_grid_world_to_node(_grid, _agent.goal_x, _agent.goal_y,
                                       _agent.goal_layer);
    if (_sn == GMNAV_NO_NODE || _gn == GMNAV_NO_NODE) return;

    _agent.ticket = gmnav_scheduler_request(_agent.sched, _sn, _gn,
                                            gmnav_priority.HIGH, false,
                                            _agent.profile, _agent.need_clear,
                                            _agent.max_climb, _agent.max_drop);
}

function __gmnav_agent_avoid(_agent, _neighbours, _desired_x, _desired_y) { // dispatch on the agent's mode. every mode returns [push_x, push_y, speed_scale]
    switch (_agent.avoid_mode) {
        case gmnav_avoid.CONTEXT:
            return __gmnav_agent_avoid_context(_agent, _neighbours, _desired_x, _desired_y);

        case gmnav_avoid.FOLLOW:
            return __gmnav_agent_avoid_follow(_agent, _neighbours, _desired_x, _desired_y);
    }
    return __gmnav_agent_avoid_basic(_agent, _neighbours);
}

function __gmnav_agent_avoid_basic(_agent, _neighbours) { // the pre-1.2 model, plus a clearance scale
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

    if (_cnt == 0) return [0, 0, 1.0];

    var _m = point_distance(0, 0, _sx, _sy);
    if (_m < 0.0001) return [0, 0, 1.0];

    var _sc = __gmnav_agent_room_scale(_agent);

    return [(_sx / _m) * _sc, (_sy / _m) * _sc, 1.0];
}

function __gmnav_agent_room_scale(_agent) { // 1.0 in the open, down to basic_clear_min in the tightest space
    var _grid = _agent.grid;

    if (_grid.clear != undefined) {
        var _node = gmnav_grid_world_to_node(_grid, _agent.x, _agent.y, _agent.layer);

        if (_node != GMNAV_NO_NODE && _node < _grid.count) {
            var _c = _grid.clear[_node];
            if (_c > 0) return clamp(_c / _agent.basic_clear_div,
                                     _agent.basic_clear_min, 1.0);
        }
        return 1.0;
    }

    // no clearance built, so probe the four cardinals directly
    var _open = 0;
    var _r    = _agent.radius * 1.5;

    for (var d = 0; d < 4; d++) {
        var _wx = _agent.x + lengthdir_x(_r, d * 90);
        var _wy = _agent.y + lengthdir_y(_r, d * 90);
        var _n  = gmnav_grid_world_to_node(_grid, _wx, _wy, _agent.layer);

        if (_n != GMNAV_NO_NODE && !gmnav_grid_is_blocked(_grid, _n)) _open++;
    }
    return clamp(_open / 4, _agent.basic_open_min, 1.0);
}

function __gmnav_agent_avoid_context(_agent, _neighbours, _desired_x, _desired_y) { // probe based steering
    var _probes = max(4, _agent.cs_probes);
    var _step   = 360 / _probes;
    var _range  = _agent.radius * _agent.avoid_range;
    var _wall_r = _agent.radius * _agent.cs_wall_range;
    var _ww     = _agent.cs_wall_weight;
    var _dw     = _agent.cs_danger_weight;
    var _grid   = _agent.grid;

    var _dm = point_distance(0, 0, _desired_x, _desired_y); // desired direction, unit length. zero means no preference
    var _dx = 0, _dy = 0;
    if (_dm > 0.0001) {
        _dx = _desired_x / _dm;
        _dy = _desired_y / _dm;
    }

    var _n_src = gmnav_grid_world_to_node(_grid, _agent.x, _agent.y, _agent.layer);

    var _best_score = -infinity;
    var _best_px = 0, _best_py = 0;

    for (var p = 0; p < _probes; p++) {
        var _ang = p * _step;
        var _px  = lengthdir_x(1, _ang);
        var _py  = lengthdir_y(1, _ang);

        // 1. interest
        var _interest = (_dx != 0 || _dy != 0) ? (_px * _dx + _py * _dy) : 0;

        // 2. neighbour danger
        var _danger = 0;
        for (var i = 0; i < array_length(_neighbours); i++) {
            var _o = _neighbours[i];
            if (_o == _agent) continue;

            var _ox = _o.x - _agent.x;
            var _oy = _o.y - _agent.y;
            var _od = point_distance(0, 0, _ox, _oy);

            var _min_d = _agent.radius + _o.radius;
            if (_od > _range || _od > _min_d * 2) continue;

            var _align = (_od > 0.0001) ? (_ox * _px + _oy * _py) / _od : 0;
            if (_align <= 0) continue;

            _danger += _align * (1 - (_od / (_min_d * 2)));
        }

        // 3. wall reach
        var _wall = 0;
        if (_n_src != GMNAV_NO_NODE) {
            var _wx = _agent.x + _px * _wall_r;
            var _wy = _agent.y + _py * _wall_r;
            var _n_dst = gmnav_grid_world_to_node(_grid, _wx, _wy, _agent.layer);

            if (_n_dst == GMNAV_NO_NODE) {
                _wall = _ww;
            } else if (!gmnav_grid_node_line_clear(_grid, _n_src, _n_dst)) {
                _wall = _ww;
            }
        }

        var _score = _interest - _danger * _dw - _wall;

        if (_score > _best_score) {
            _best_score = _score;
            _best_px    = _px;
            _best_py    = _py;
        }
    }

    return [_best_px - _dx, _best_py - _dy, 1.0];
}

function __gmnav_agent_avoid_follow(_agent, _neighbours, _desired_x, _desired_y) { // queue formation. nobody gets pushed off the path. agents slow down when someone is ahead in their direction of travel, and a small damped separation keeps bodies from overlapping
    var _dm = point_distance(0, 0, _desired_x, _desired_y);

    // no desired direction means no path to follow. nothing to do
    if (_dm < 0.0001) return [0, 0, 1.0];

    var _ux = _desired_x / _dm;
    var _uy = _desired_y / _dm;

    var _safe_gap = _agent.follow_gap;   // full speed at this gap
    var _min_gap  = _agent.follow_min;   // hard stop at this gap
    var _floor    = _agent.follow_floor; // slowest the queue can go
    var _cone     = _agent.follow_cone;  // ahead cone half-width
    var _scale    = 1.0;

    // speed scale from the tightest blocker ahead
    for (var i = 0; i < array_length(_neighbours); i++) {
        var _o = _neighbours[i];
        if (_o == _agent) continue;

        var _dx = _o.x - _agent.x;
        var _dy = _o.y - _agent.y;

        // forward component. behind us means no concern
        var _fwd = _dx * _ux + _dy * _uy;
        if (_fwd <= 0) continue;

        // lateral component. outside a narrow cone ahead, not in our lane
        var _lat = abs(_dx * (-_uy) + _dy * _ux);

        var _sum_r = _agent.radius + _o.radius;
        if (_lat > _sum_r * _cone) continue;

        // gap in units of radius-sum. 1.0 means touching, 3.0 means comfortable
        var _gap = _fwd / _sum_r;

        if (_gap < _safe_gap) {
            var _k = clamp((_gap - _min_gap) / (_safe_gap - _min_gap), 0, 1);

            if (_k < _floor) _k = _floor;

            if (_k < _scale) _scale = _k;
        }
    }

    // damped separation
    var _px = 0, _py = 0;

    if (_scale > _floor * 2 && _agent.follow_sep > 0) {
        var _sx = 0, _sy = 0, _cnt = 0;
        var _range = _agent.radius * _agent.follow_sep_range;

        for (var i = 0; i < array_length(_neighbours); i++) {
            var _o = _neighbours[i];
            if (_o == _agent) continue;

            var _dx = _agent.x - _o.x;
            var _dy = _agent.y - _o.y;
            var _d  = point_distance(0, 0, _dx, _dy);
            var _min_d = _agent.radius + _o.radius;

            if (_d > _range || _d > _min_d) continue;

            if (_d < 0.0001) {
                var _ang = (_agent.seek_i * 73 + i * 137) % 360;
                _sx += dcos(_ang);
                _sy -= dsin(_ang);
                _cnt++;
                continue;
            }

            var _w = 1 - (_d / _min_d);
            _sx += (_dx / _d) * _w;
            _sy += (_dy / _d) * _w;
            _cnt++;
        }

        if (_cnt > 0) {
            var _m = point_distance(0, 0, _sx, _sy);
            if (_m > 0.0001) {
                _px = (_sx / _m) * _agent.follow_sep;
                _py = (_sy / _m) * _agent.follow_sep;
            }
        }
    }

    return [_px, _py, _scale];
}

function gmnav_agent_layer(_agent) { // 0 is the base grid
    return _agent.layer;
}

function __gmnav_agent_path_disturbed(_agent) { // did any edit since this path was built land on the part of it still to walk
    var _p    = _agent.path;
    var _grid = _agent.grid;

    if (_p.version == _grid.version) return false;

    var _nd = _p.nodes;
    var _n  = array_length(_nd);

    if (_n < 2) return true;

    var _from = max(0, _agent.seek_i - 1);

    for (var i = _from; i < _n - 1; i++) {
        var _ac = gmnav_grid_col(_grid, _nd[i]);
        var _ar = gmnav_grid_row(_grid, _nd[i]);
        var _bc = gmnav_grid_col(_grid, _nd[i + 1]);
        var _br = gmnav_grid_row(_grid, _nd[i + 1]);

        if (_ac < 0 || _bc < 0) return true;

        if (gmnav_grid_changed_since(_grid, _p.version,
                                     min(_ac, _bc), min(_ar, _br),
                                     max(_ac, _bc), max(_ar, _br))) {
            return true;
        }
    }

    _p.version = _grid.version;
    return false;
}