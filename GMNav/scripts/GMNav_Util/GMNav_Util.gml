/**********************************************************
                   CONVENIENCE, NOT CORE
-----------------------------------------------------------
Composition of public calls and decides nothing. Every function
here wraps something the framework already does, added because
the these needs often show up in most project setup and writing
it by hand gets tiring.
**********************************************************/

// grid setup
function gmnav_util_grid_for_room(_tile_w, _tile_h = undefined, _mode = gmnav_layout.ORTHO, _neighbours = gmnav_neighbours.EIGHT) { // a grid sized to the room, with a matching layout. square tiles when _tile_h is left out
    if (_tile_h == undefined) _tile_h = _tile_w;

    var _layout = gmnav_layout_create(_mode, _tile_w, _tile_h, _neighbours);

    return gmnav_grid_create(room_width  div _tile_w,
                             room_height div _tile_h,
                             _layout);
}

function gmnav_util_border_blocked(_grid, _thickness = 1) { // walls around the edge of the map. every demo does this by hand. returns whether anything changed
    var _changed = false;
    var _w = _grid.width;
    var _h = _grid.height;

    for (var _k = 0; _k < _thickness; _k++) {
        if (gmnav_grid_fill_blocked(_grid, _k, _k, _w - 1 - _k, _k, true)) _changed = true;
        if (gmnav_grid_fill_blocked(_grid, _k, _h - 1 - _k, _w - 1 - _k, _h - 1 - _k, true)) _changed = true;
        if (gmnav_grid_fill_blocked(_grid, _k, _k, _k, _h - 1 - _k, true)) _changed = true;
        if (gmnav_grid_fill_blocked(_grid, _w - 1 - _k, _k, _w - 1 - _k, _h - 1 - _k, true)) _changed = true;
    }
    return _changed;
}

function gmnav_util_grid_from_tilemap(_tilemap, _tile_w, _tile_h = undefined, _mode = gmnav_layout.ORTHO, _neighbours = gmnav_neighbours.EIGHT, _is_blocked = undefined) { // a grid built from a tilemap layer, sized to the tilemap, with the border blocked. the whole setup for a top down level in one call
    if (_tile_h == undefined) _tile_h = _tile_w;

    var _layout = gmnav_layout_create(_mode, _tile_w, _tile_h, _neighbours);

    var _grid = gmnav_grid_create(tilemap_get_width(_tilemap),
                                  tilemap_get_height(_tilemap),
                                  _layout);

    gmnav_grid_import_tilemap(_grid, _tilemap, _is_blocked);
    gmnav_util_border_blocked(_grid);

    return _grid;
}

// node query and picking
function gmnav_util_node_at(_grid, _x, _y, _layer = 0) { // world position to node, but only if the cell there is walkable. GMNAV_NO_NODE otherwise
    var _n = gmnav_grid_world_to_node(_grid, _x, _y, _layer);
    if (_n == GMNAV_NO_NODE) return GMNAV_NO_NODE;
    if (gmnav_grid_is_blocked(_grid, _n)) return GMNAV_NO_NODE;
    return _n;
}

function gmnav_util_cursor_node(_grid, _mode = 0) { // the node under the cursor, if it is somewhere an agent could stand. _mode 0 asks topmost, which is what a click on a bridge usually means. _mode 1 asks the ground, so a click passes under it
    var _n = (_mode == 0)
           ? gmnav_grid_world_to_node_top(_grid, mouse_x, mouse_y)
           : gmnav_grid_world_to_node(_grid, mouse_x, mouse_y, 0);

    if (_n == GMNAV_NO_NODE) return GMNAV_NO_NODE;
    if (gmnav_grid_is_blocked(_grid, _n)) return GMNAV_NO_NODE;
    return _n;
}

function gmnav_util_snap_open(_grid, _x, _y, _max_rings = 4) { // the nearest open node to a world position, when the exact cell is blocked or off the map. walks outward in rings, no clearance needed. useful for spawn points and forgiving clicks
    var _n = gmnav_util_node_at(_grid, _x, _y);

    if (_n != GMNAV_NO_NODE) return _n;

    var _cr = gmnav_layout_world_to_cell(_grid.layout, _x, _y);
    var _c0 = _cr[0];
    var _r0 = _cr[1];

    for (var _ring = 1; _ring <= _max_rings; _ring++) {
        for (var _dr = -_ring; _dr <= _ring; _dr++) {
            var _rr = _r0 + _dr;

            for (var _dc = -_ring; _dc <= _ring; _dc++) {
                if (abs(_dc) != _ring && abs(_dr) != _ring) continue; // only the ring edge

                var _cc = _c0 + _dc;
                var _nn = gmnav_grid_node(_grid, _cc, _rr);

                if (_nn == GMNAV_NO_NODE) continue;
                if (gmnav_grid_is_blocked(_grid, _nn)) continue;

                return _nn;
            }
        }
    }
    return GMNAV_NO_NODE;
}

function gmnav_util_random_open(_grid, _max_attempts = 200) { // a random walkable node, or GMNAV_NO_NODE. samples cells rather than walkable cells, so a mostly blocked map wants a higher budget
    repeat (_max_attempts) {
        var _c = irandom(_grid.width  - 1);
        var _r = irandom(_grid.height - 1);
        var _n = gmnav_grid_node(_grid, _c, _r);

        if (_n == GMNAV_NO_NODE) continue;
        if (gmnav_grid_is_blocked(_grid, _n)) continue;

        return _n;
    }
    return GMNAV_NO_NODE;
}

function gmnav_util_random_open_world(_grid, _max_attempts = 200) { // the world position of a random walkable node as [x, y], or undefined
    var _n = gmnav_util_random_open(_grid, _max_attempts);
    if (_n == GMNAV_NO_NODE) return undefined;
    return gmnav_grid_node_to_world(_grid, _n);
}

// inspection
function gmnav_util_probe_node(_grid, _node) { // everything the framework knows about one node, as a struct. for debug messages and overlays
    if (_node == GMNAV_NO_NODE) return undefined;

    var _ov = gmnav_grid_has_overlay(_grid) ? _grid.overlay : undefined;
    var _p  = gmnav_grid_node_to_world(_grid, _node);

    return {
        node      : _node,
        col       : gmnav_grid_col(_grid, _node),
        row       : gmnav_grid_row(_grid, _node),
        layer     : gmnav_grid_node_layer(_grid, _node),
        blocked   : gmnav_grid_is_blocked(_grid, _node),
        cost      : gmnav_grid_cost(_grid, _node),
        clearance : gmnav_clearance_at(_grid, _node),
        height_z  : gmnav_grid_height(_grid, _node),
        offset    : (_ov != undefined && _node >= _grid.count)
                  ? gmnav_overlay_offset(_ov, _node)
                  : 0,
        x         : _p[0],
        y         : _p[1]
    };
}

function gmnav_util_describe_node(_grid, _node) { // a one line string for a debug message. handles GMNAV_NO_NODE and invalid ids
    if (_node == GMNAV_NO_NODE) return "no node";

    var _pr = gmnav_util_probe_node(_grid, _node);
    if (_pr == undefined) return "invalid node " + string(_node);

    return "(" + string(_pr.col) + "," + string(_pr.row) + ")"
         + " layer " + string(_pr.layer)
         + (_pr.blocked ? " blocked" : "")
         + " cost " + string_format(_pr.cost, 1, 2);
}

// agent control
function gmnav_util_send_agent(_agent, _grid, _x, _y, _mode = 0, _priority = gmnav_priority.NORMAL) { // send to a world point, resolving the surface first. _mode 0 topmost, _mode 1 ground. false if the point is not somewhere an agent can stand
    var _n = (_mode == 0)
           ? gmnav_grid_world_to_node_top(_grid, _x, _y)
           : gmnav_grid_world_to_node(_grid, _x, _y, 0);

    if (_n == GMNAV_NO_NODE) return false;
    if (gmnav_grid_is_blocked(_grid, _n)) return false;

    var _p = gmnav_grid_node_to_world(_grid, _n);
    var _l = gmnav_grid_node_layer(_grid, _n);

    return gmnav_agent_goto(_agent, _p[0], _p[1], _priority, _l);
}

function gmnav_util_send_agent_node(_agent, _grid, _node, _priority = gmnav_priority.NORMAL) { // send to a node id the caller already has. useful after a lookup that returned a node rather than a position
    if (_node == GMNAV_NO_NODE) return false;
    if (gmnav_grid_is_blocked(_grid, _node)) return false;

    var _p = gmnav_grid_node_to_world(_grid, _node);
    var _l = gmnav_grid_node_layer(_grid, _node);

    return gmnav_agent_goto(_agent, _p[0], _p[1], _priority, _l);
}

function gmnav_util_send_group(_agents, _grid, _x, _y, _spread = 0, _priority = gmnav_priority.NORMAL) { // send every agent in an array to a point, spread across a disc so they do not stack on one cell. returns the count that accepted the order
    var _n = array_length(_agents);
    var _accepted = 0;

    for (var i = 0; i < _n; i++) {
        var _ang = i * 137.5; // golden angle, gives even coverage
        var _rad = _spread * sqrt(i / max(1, _n - 1));

        var _tx = _x + lengthdir_x(_rad, _ang);
        var _ty = _y + lengthdir_y(_rad, _ang);

        if (gmnav_util_node_at(_grid, _tx, _ty) == GMNAV_NO_NODE) {
            _tx = _x;
            _ty = _y;
        }

        if (gmnav_util_send_agent(_agents[i], _grid, _tx, _ty, 0, _priority)) _accepted++;
    }
    return _accepted;
}

function gmnav_util_reset_agent(_agent, _grid, _x, _y, _layer = 0) { // stop, move to a position, and drop every trace of the old journey. cleaner than calling stop then setting x, y
    gmnav_agent_stop(_agent);

    _agent.x       = _x;
    _agent.y       = _y;
    _agent.layer   = _layer;
    _agent.vx      = 0;
    _agent.vy      = 0;
    _agent.arrived = false;
    _agent.failed  = false;
}

// agent state, for HUDs and debug
function gmnav_util_agent_state(_agent) { // a single word describing what the agent is doing right now
    if (gmnav_agent_arrived(_agent))    return "arrived";
    if (gmnav_agent_failed(_agent))     return "failed";
    if (gmnav_agent_has_path(_agent))   return "walking";
    if (_agent.ticket != undefined)     return "waiting";
    return "idle";
}

function gmnav_util_agent_summary(_agents) { // tallies a group of agents into walking, waiting, idle, arrived, failed, as a struct. for a HUD counter
    var _n = array_length(_agents);

    var _s = {
        total   : _n,
        walking : 0,
        waiting : 0,
        idle    : 0,
        arrived : 0,
        failed  : 0
    };

    for (var i = 0; i < _n; i++) {
        var _a = _agents[i];
        if (gmnav_agent_arrived(_a))       _s.arrived++;
        else if (gmnav_agent_failed(_a))   _s.failed++;
        else if (gmnav_agent_has_path(_a)) _s.walking++;
        else if (_a.ticket != undefined)   _s.waiting++;
        else                               _s.idle++;
    }
    return _s;
}

function gmnav_util_scheduler_snapshot(_sched) { // the scheduler's state as a struct, for HUDs and overlays. reads the same fields the debug panel uses
    return {
        domain     : _sched.domain,
        budget     : _sched.budget,
        concurrent : _sched.concurrent,
        pending    : gmnav_scheduler_pending(_sched),
        active     : _sched.last_active,
        pops_used  : _sched.last_pops,
        pooled     : array_length(_sched.pool)
    };
}

// synchronous path queries
// run a search to completion inside the cal
// good for tools, level validation, spawn checks and anything outside gameplay
// wrong for anything per frame, which is what the scheduler is for
function gmnav_util_shortest_path(_grid, _from, _to, _profile = undefined, _need_clear = 0, _max_climb = undefined, _max_drop = undefined, _max_steps = 1000000) { // a path object from one node to another, or undefined. does the whole pipeline: search, reconstruct, smooth
    if (_from == GMNAV_NO_NODE || _to == GMNAV_NO_NODE) return undefined;

    var _s = gmnav_search_create(_grid);
    if (!gmnav_search_begin(_s, _from, _to, false, _profile, _need_clear, _max_climb, _max_drop)) return undefined;

    var _guard = 0;
    while (_s.state == gmnav_state.WORKING && _guard++ < _max_steps) {
        gmnav_search_step(_s, 4096);
    }

    if (_s.state != gmnav_state.FOUND) return undefined;

    var _p = gmnav_path_create(_grid, gmnav_search_get_path(_s));
    gmnav_path_smooth(_p, _max_climb, _max_drop);

    return _p;
}

function gmnav_util_is_reachable(_grid, _from, _to, _profile = undefined, _need_clear = 0, _max_climb = undefined, _max_drop = undefined, _max_steps = 1000000) { // whether any route exists. runs a search to completion, so use it for spawn validation and objective checks, not per frame
    if (_from == GMNAV_NO_NODE || _to == GMNAV_NO_NODE) return false;

    var _s = gmnav_search_create(_grid);
    if (!gmnav_search_begin(_s, _from, _to, false, _profile, _need_clear, _max_climb, _max_drop)) return false;

    var _guard = 0;
    while (_s.state == gmnav_state.WORKING && _guard++ < _max_steps) {
        gmnav_search_step(_s, 4096);
    }

    return (_s.state == gmnav_state.FOUND);
}

function gmnav_util_path_cost(_grid, _nodes, _profile = undefined) { // the cost the search would charge for a route, given as nodes. no search runs, it just adds up the resolved costs of each step. for comparing two routes you already have
    var _n = array_length(_nodes);
    if (_n < 2) return 0;

    var _cost = (_profile != undefined) ? _profile.resolved : _grid.cost;
    var _lay  = _grid.layout;
    var _total = 0;

    for (var i = 1; i < _n; i++) {
        var _a    = gmnav_grid_node_to_world(_grid, _nodes[i - 1]);
        var _b    = gmnav_grid_node_to_world(_grid, _nodes[i]);
        var _step = point_distance(_a[0], _a[1], _b[0], _b[1]);

        _total += (_step / _lay.step_min_world) * _cost[_nodes[i]];
    }
    return _total;
}

function gmnav_util_path_is_valid(_grid, _nodes, _need_clear = 0) { // does every node on a route still exist and remain walkable. call this after grid edits to decide whether a held path is worth keeping
    var _n = array_length(_nodes);
    if (_n < 2) return false;

    for (var i = 0; i < _n; i++) {
        var _nd = _nodes[i];
        if (_nd == GMNAV_NO_NODE) return false;
        if (gmnav_grid_is_blocked(_grid, _nd)) return false;

        if (_need_clear > 1 && gmnav_clearance_at(_grid, _nd) < _need_clear) return false;
    }
    return true;
}

// cost fields
function gmnav_util_costfield_single(_grid, _name = "cost") { // a layer plus a profile that reads it with weight 1. the common case by far, and two calls that always go together
    var _layer = gmnav_costlayer_create(_grid, _name);
    var _prof  = gmnav_costprofile_create(_grid, _name);

    gmnav_costprofile_add(_prof, _layer, 1);

    return { layer : _layer, profile : _prof };
}

function gmnav_util_move_threat(_layer, _profiles, _old_rect, _new_rect) { // after a threat moves, clear the footprint it left and rebake both rectangles for every profile that reads the layer. both rects, always, which is the pattern the docs warn about
    gmnav_costlayer_clear_region(_layer,
                                 _old_rect[0], _old_rect[1],
                                 _old_rect[2], _old_rect[3]);

    var _n = array_length(_profiles);
    for (var i = 0; i < _n; i++) {
        var _p = _profiles[i];
        gmnav_costprofile_bake_region(_p, _old_rect[0], _old_rect[1],
                                         _old_rect[2], _old_rect[3]);
        gmnav_costprofile_bake_region(_p, _new_rect[0], _new_rect[1],
                                         _new_rect[2], _new_rect[3]);
    }
}

// overlay authoring
function gmnav_util_overlay_room(_ov, _c1, _r1, _c2, _r2, _layer = 1) { // fill a rectangle with overlay cells. returns the count added, which may be less than the rectangle if some cells already existed
    var _lc = min(_c1, _c2), _rc = max(_c1, _c2);
    var _lr = min(_r1, _r2), _rr = max(_r1, _r2);
    var _added = 0;

    for (var _r = _lr; _r <= _rr; _r++) {
        for (var _c = _lc; _c <= _rc; _c++) {
            var _before = gmnav_overlay_count(_ov);
            gmnav_overlay_add(_ov, _c, _r, _layer);
            if (gmnav_overlay_count(_ov) > _before) _added++;
        }
    }
    return _added;
}

function gmnav_util_overlay_bridge(_grid, _ov, _c1, _r1, _c2, _r2, _layer = 1) { // a straight run of overlay cells from one point to the other, with links at each end to the ground below. only handles horizontal, vertical or diagonal runs. returns [first_node, last_node]
    var _dc    = sign(_c2 - _c1);
    var _dr    = sign(_r2 - _r1);
    var _steps = max(abs(_c2 - _c1), abs(_r2 - _r1));

    var _first = GMNAV_NO_NODE;
    var _last  = GMNAV_NO_NODE;

    for (var i = 0; i <= _steps; i++) {
        var _n = gmnav_overlay_add(_ov, _c1 + _dc * i, _r1 + _dr * i, _layer);
        if (_first == GMNAV_NO_NODE) _first = _n;
        _last = _n;
    }

    gmnav_overlay_link(_ov, // one link at each end, to the ground cell one step further along
        gmnav_grid_node(_grid, _c1 - _dc, _r1 - _dr),
        _first, gmnav_link.STAIR, true);

    gmnav_overlay_link(_ov,
        _last,
        gmnav_grid_node(_grid, _c2 + _dc, _r2 + _dr),
        gmnav_link.STAIR, true);

    return [_first, _last];
}

// target selection
// picking a target from a listt is one of the most repeated job in any AI system and every project writes the same three functions by hand
function gmnav_util_nearest_in_array(_x, _y, _items) { // the array entry closest to a point by straight line distance. uses _items[i].x and .y, so it works on agents, structs, anything with those two fields
    var _n = array_length(_items);
    if (_n == 0) return undefined;

    var _best = _items[0];
    var _bd   = sqr(_best.x - _x) + sqr(_best.y - _y);

    for (var i = 1; i < _n; i++) {
        var _o = _items[i];
        var _d = sqr(_o.x - _x) + sqr(_o.y - _y);
        if (_d < _bd) { _bd = _d; _best = _o; }
    }
    return _best;
}

function gmnav_util_agents_within_radius(_x, _y, _agents, _radius) { // every entry closer than the radius. the array to pass is usually the one you gathered for avoidance
    var _out = [];
    var _r2  = _radius * _radius;
    var _n   = array_length(_agents);

    for (var i = 0; i < _n; i++) {
        var _a = _agents[i];
        var _d = sqr(_a.x - _x) + sqr(_a.y - _y);
        if (_d <= _r2) array_push(_out, _a);
    }
    return _out;
}

function gmnav_util_agents_sorted_by_distance(_x, _y, _agents) { // a copy of the array sorted nearest first. handy for threat priority and for picking the closest target with an early break
    var _work = [];
	array_copy(_work, 0, _agents, 0, array_length(_agents));

    array_sort(_work, function(_a, _b) {
        var _da = sqr(_a.x - _x) + sqr(_a.y - _y);
        var _db = sqr(_b.x - _x) + sqr(_b.y - _y);
        return sign(_da - _db);
    });

    return _work;
}

function gmnav_util_reachable_nearest(_grid, _from_node, _candidates, _profile = undefined, _max_steps = 1000000) { // the candidate the search can actually reach, and among those, the one with the lowest path cost. unlike nearest_in_array this respects walls, so a target twenty pixels away on the other side of a river does not win. costs one search per candidate, so keep the list short
    if (_from_node == GMNAV_NO_NODE) return GMNAV_NO_NODE;

    var _n = array_length(_candidates);
    var _best = GMNAV_NO_NODE;
    var _bestc = GMNAV_INF;

    for (var i = 0; i < _n; i++) {
        var _to = _candidates[i];
        if (_to == GMNAV_NO_NODE) continue;

        var _s = gmnav_search_create(_grid);
        if (!gmnav_search_begin(_s, _from_node, _to, false, _profile)) continue;

        var _guard = 0;
        while (_s.state == gmnav_state.WORKING && _guard++ < _max_steps) {
            gmnav_search_step(_s, 4096);
        }

        if (_s.state != gmnav_state.FOUND) continue;
        if (_s.slot_g_final < _bestc) {
            _bestc = _s.slot_g_final;
            _best  = _to;
        }
    }
    return _best;
}

// world space queries into cost and clearance
// costlayer_get and clearance_at take cells. callers almost always have a world position. these bridge the two
function gmnav_util_cost_at_world(_layer, _x, _y) { // the layer value under a world position. zero if the position is off the map
    var _n = gmnav_grid_world_to_node(_layer.grid, _x, _y);
    if (_n == GMNAV_NO_NODE) return 0;
    return gmnav_costlayer_get_node(_layer, _n);
}

function gmnav_util_clearance_at_world(_grid, _x, _y, _layer = 0) { // the clearance at a world position. zero if there is nothing there
    var _n = gmnav_grid_world_to_node(_grid, _x, _y, _layer);
    if (_n == GMNAV_NO_NODE) return 0;
    return gmnav_clearance_at(_grid, _n);
}

function gmnav_util_danger_around(_layer, _x, _y, _radius) { // the highest layer value in a disc around a point. "how bad is it here" without committing to a specific cell
    var _grid = _layer.grid;
    var _r2   = _radius * _radius;
    var _best = 0;

    var _tl = gmnav_layout_world_to_cell(_grid.layout, _x - _radius, _y - _radius);
    var _br = gmnav_layout_world_to_cell(_grid.layout, _x + _radius, _y + _radius);

    for (var _r = _tl[1]; _r <= _br[1]; _r++) {
        for (var _c = _tl[0]; _c <= _br[0]; _c++) {
            var _n = gmnav_grid_node(_grid, _c, _r);
            if (_n == GMNAV_NO_NODE) continue;

            var _p = gmnav_grid_node_to_world(_grid, _n);
            if (sqr(_p[0] - _x) + sqr(_p[1] - _y) > _r2) continue;

            var _v = gmnav_costlayer_get_node(_layer, _n);
            if (_v > _best) _best = _v;
        }
    }
    return _best;
}

// path following
// the path object gives you a list of waypoints/nodes and a total length. it doesnt give you 'where will i be in n pixels' which every moving agent eventually asks
function gmnav_util_path_waypoint_index(_path, _distance) { // the waypoint index the path has reached at a given distance along it. the inverse of gmnav_path_sample, roughly
    if (_path.count <= 1) return 0;

    var _acc = 0;
    for (var i = 0; i < _path.count - 1; i++) {
        var _seg = point_distance(_path.px[i],     _path.py[i],
                                  _path.px[i + 1], _path.py[i + 1]);
        if (_acc + _seg >= _distance) return i;
        _acc += _seg;
    }
    return _path.count - 1;
}

function gmnav_util_path_direction_at(_path, _distance) { // the heading of the path at a distance along it, in degrees. aim a turret, orient a sprite, angle a trail
    var _s = gmnav_path_sample(_path, _distance);
    var _e = gmnav_path_sample(_path, _distance + 4);

    if (_s[0] == _e[0] && _s[1] == _e[1]) {
        var _i = gmnav_util_path_waypoint_index(_path, _distance);
        if (_i < _path.count - 1) {
            return point_direction(_path.px[_i], _path.py[_i],
                                   _path.px[_i + 1], _path.py[_i + 1]);
        }
        return 0;
    }
    return point_direction(_s[0], _s[1], _e[0], _e[1]);
}

function gmnav_util_path_lookahead(_path, _distance, _ahead) { // a point N pixels further along the path than a given distance. clamped at the ends. the "follow the road ahead" position for anticipation
    return gmnav_path_sample(_path, _distance + _ahead);
}

function gmnav_util_path_length_between(_path, _from, _to) { // the distance along the path between two distance values. for "how much is left" style readouts
    var _len = gmnav_path_get_length(_path);
    var _a = clamp(_from, 0, _len);
    var _b = clamp(_to,   0, _len);
    return _b - _a;
}

// grid validation
// level design questions: is the map connected? can anything actually reach the objective? where are the dead zones?
// should be used in a tool, on level load or from a debug key. not per frame.
function gmnav_util_reachable_set(_grid, _from_node, _need_clear = 0) { // every node reachable from a starting point, as an array. flood fill, no cost involved, no search budget
    var _n = _grid.count;
    var _total = _n;

    if (gmnav_grid_has_overlay(_grid)) _total += gmnav_overlay_count(_grid.overlay);

    if (_from_node == GMNAV_NO_NODE) return [];
    if (gmnav_grid_is_blocked(_grid, _from_node)) return [];

    var _seen  = array_create(_total, false);
    var _stack = [_from_node];
    var _out   = [];

    _seen[_from_node] = true;

    while (array_length(_stack) > 0) {
        var _cur = array_pop(_stack);
        array_push(_out, _cur);

        var _c = gmnav_grid_col(_grid, _cur);
        var _r = gmnav_grid_row(_grid, _cur);
        if (_c < 0) continue;

        // 4 neighbours is enough for a connectivity check on any layout, and avoids needing the layout's parity logic here
        var _offs = [[-1,0],[1,0],[0,-1],[0,1]];

        for (var k = 0; k < 4; k++) {
            var _nc = _c + _offs[k][0];
            var _nr = _r + _offs[k][1];
            var _nn = gmnav_grid_node(_grid, _nc, _nr);

            if (_nn == GMNAV_NO_NODE) continue;
            if (_seen[_nn]) continue;
            if (gmnav_grid_is_blocked(_grid, _nn)) continue;
            if (_need_clear > 1 && gmnav_clearance_at(_grid, _nn) < _need_clear) continue;

            _seen[_nn] = true;
            array_push(_stack, _nn);
        }

        // and follow authored links, so a bridge reads as part of the floor
        if (gmnav_grid_has_overlay(_grid)) {
            var _ov = _grid.overlay;

            if (_cur < _grid.count) {
                for (var _u = _ov.up_start[_cur]; _u < _ov.up_start[_cur + 1]; _u++) {
                    var _un = _ov.up_to[_u];
                    if (_seen[_un]) continue;
                    if (gmnav_grid_is_blocked(_grid, _un)) continue;
                    _seen[_un] = true;
                    array_push(_stack, _un);
                }
            } else {
                var _oi = _cur - _ov.base;
                for (var _e = _ov.edge_start[_oi]; _e < _ov.edge_start[_oi + 1]; _e++) {
                    var _en = _ov.edge_to[_e];
                    if (_seen[_en]) continue;
                    if (gmnav_grid_is_blocked(_grid, _en)) continue;
                    _seen[_en] = true;
                    array_push(_stack, _en);
                }
            }
        }
    }
    return _out;
}

function gmnav_util_is_connected(_grid, _need_clear = 0) { // true when every walkable cell can be reached from every other. false means the map has islands, which is usually a level design bug rather than a feature
    var _first = GMNAV_NO_NODE;
    var _total = _grid.count + (gmnav_grid_has_overlay(_grid) ? gmnav_overlay_count(_grid.overlay) : 0);
    var _walkable = 0;

    for (var i = 0; i < _total; i++) {
        if (gmnav_grid_is_blocked(_grid, i)) continue;
        if (_need_clear > 1 && gmnav_clearance_at(_grid, i) < _need_clear) continue;
        _walkable++;
        if (_first == GMNAV_NO_NODE) _first = i;
    }

    if (_first == GMNAV_NO_NODE) return true;   // nothing walkable, vacuously connected
    return (array_length(gmnav_util_reachable_set(_grid, _first, _need_clear)) == _walkable);
}

function gmnav_util_unreachable_from(_grid, _from_node, _need_clear = 0) { // every walkable node that cannot be reached from a point. the complement of reachable_set, which is what you actually want to draw when a level has islands
    var _total = _grid.count + (gmnav_grid_has_overlay(_grid) ? gmnav_overlay_count(_grid.overlay) : 0);

    var _reach = gmnav_util_reachable_set(_grid, _from_node, _need_clear);
    var _seen  = array_create(_total, false);

    for (var i = 0; i < array_length(_reach); i++) _seen[_reach[i]] = true;

    var _out = [];
    for (var j = 0; j < _total; j++) {
        if (_seen[j]) continue;
        if (gmnav_grid_is_blocked(_grid, j)) continue;
        if (_need_clear > 1 && gmnav_clearance_at(_grid, j) < _need_clear) continue;
        array_push(_out, j);
    }
    return _out;
}

//flow field to path
// fields and paths are two different answers to the same question. when you have a field but need something that walks like a path, this converts.
// useful for previews, tooling and for handing a field route to code that expects a path object.
function gmnav_util_flowfield_to_path(_grid, _field, _from_node, _max_hops = 1024) { // walk the field's next chain from a start, return a path object or undefined if the chain loops or does not reach a goal. no search runs, the field already knows the route
    if (_from_node == GMNAV_NO_NODE) return undefined;
    if (!gmnav_flowfield_is_ready(_field)) return undefined;

    var _chain = [];
    var _cur   = _from_node;
    var _hops  = 0;

    while (_hops++ < _max_hops) {
        array_push(_chain, _cur);

        var _nx = gmnav_flowfield_next(_field, _cur);
        if (_nx == GMNAV_NO_NODE) break;              // reached a goal
        if (_nx == _cur)         return undefined;    // self loop
        _cur = _nx;
    }

    if (_hops >= _max_hops) return undefined;         // gave up

    return gmnav_path_create(_grid, _chain);
}

// line of sight
// gmnav_grid_line_clear answers "is the line clear for a point'.
// stealth, snipers and vision cones usualy need a body width.
function gmnav_util_has_line_of_sight(_grid, _x1, _y1, _x2, _y2, _radius = 0) { // whether a straight line from one world point to another is unobstructed for a body of a given radius. radius 0 is the point test the framework already does
    var _a = gmnav_grid_world_to_node(_grid, _x1, _y1);
    var _b = gmnav_grid_world_to_node(_grid, _x2, _y2);

    if (_a == GMNAV_NO_NODE || _b == GMNAV_NO_NODE) return false;
    if (gmnav_grid_is_blocked(_grid, _a)) return false;
    if (gmnav_grid_is_blocked(_grid, _b)) return false;

    if (_radius <= 0) {
        return gmnav_grid_node_line_clear(_grid, _a, _b);
    }

    // sample along the line and check the body at each sample
    var _d    = point_distance(_x1, _y1, _x2, _y2);
    var _step = max(4, _grid.layout.tile_w * 0.25);
    var _n    = max(1, ceil(_d / _step));

    for (var i = 0; i <= _n; i++) {
        var _t = i / _n;
        var _sx = lerp(_x1, _x2, _t);
        var _sy = lerp(_y1, _y2, _t);

        // four corners of the body at this sample
        var _offs = [[-_radius,-_radius],[_radius,-_radius],
                     [-_radius, _radius],[_radius, _radius]];

        for (var k = 0; k < 4; k++) {
            var _cn = gmnav_util_node_at(_grid, _sx + _offs[k][0], _sy + _offs[k][1]);
            if (_cn == GMNAV_NO_NODE) return false;
        }
    }
    return true;
}

// repath staggering
// when a group of agents share a repath trigger, they all ask on the same frame and the queue fills. giving each a slightly different gap and offset spreads them across the frame.
function gmnav_util_stagger_repath_gaps(_agents, _base_gap, _jitter = 5) { // give each agent a repath_gap spread around a base value. cheap way to stop a crowd synchronising
    var _n = array_length(_agents);
    for (var i = 0; i < _n; i++) {
        _agents[i].repath_gap = _base_gap + irandom_range(-_jitter, _jitter);
    }
}

function gmnav_util_stagger_repath_offsets(_agents, _frame_span = 30) { // give each agent a different repath_at offset, so their first repath lands on different frames. call once at setup, not per frame
    var _n = array_length(_agents);
    var _step = _frame_span * (1000 / max(1, game_get_speed(gamespeed_fps)));

    for (var i = 0; i < _n; i++) {
        _agents[i].repath_at = current_time + (i mod _frame_span) * _step;
    }
}

// motion tracker
// an agent that has not moved for a while is stuck. detection needs history and history needs state the framework does not carry. this is a tiny companion struct rather than a field.
function gmnav_util_motion_tracker_create(_frames = 30, _min_dist = 4) { // watch for N frames and report stuck if the agent moved less than a distance in that time
    return {
        frames   : _frames,
        min_dist : _min_dist,
        sx       : 0,
        sy       : 0,
        count    : 0,
        started  : false
    };
}

function gmnav_util_motion_tracker_update(_tracker, _x, _y) { // push a position, get back whether the agent has been stationary for the window. resets automatically on movement
    if (!_tracker.started) {
        _tracker.sx = _x;
        _tracker.sy = _y;
        _tracker.started = true;
        _tracker.count = 0;
        return false;
    }

    _tracker.count++;

    if (_tracker.count < _tracker.frames) return false;

    var _d = point_distance(_tracker.sx, _tracker.sy, _x, _y);
    var _stuck = (_d < _tracker.min_dist);

    _tracker.sx = _x;
    _tracker.sy = _y;
    _tracker.count = 0;

    return _stuck;
}

// spawning
function gmnav_util_spawn_points_around(_grid, _x, _y, _count, _radius, _max_attempts = 40) { // positions evenly spaced on a circle around a point, each snapped to the nearest open cell. returns an array of [x, y], possibly shorter than _count if some snap failed
    var _out = [];

    for (var i = 0; i < _count; i++) {
        var _ang = (i / _count) * 360;
        var _tx  = _x + lengthdir_x(_radius, _ang);
        var _ty  = _y + lengthdir_y(_radius, _ang);

        var _n = gmnav_util_snap_open(_grid, _tx, _ty, _max_attempts);
        if (_n == GMNAV_NO_NODE) continue;

        array_push(_out, gmnav_grid_node_to_world(_grid, _n));
    }
    return _out;
}

function gmnav_util_spawn_points_in_rect(_grid, _c1, _r1, _c2, _r2, _count, _max_attempts = 400) { // _count random open positions inside a cell rectangle, world space. duplicate cells are allowed, so pass a count smaller than the rectangle if you want them distinct
    var _out = [];
    var _lc = min(_c1, _c2), _rc = max(_c1, _c2);
    var _lr = min(_r1, _r2), _rr = max(_r1, _r2);

    if (_rc < _lc || _rr < _lr) return _out;

    var _tries = 0;
    while (array_length(_out) < _count && _tries++ < _max_attempts) {
        var _c = irandom_range(_lc, _rc);
        var _r = irandom_range(_lr, _rr);
        var _n = gmnav_grid_node(_grid, _c, _r);

        if (_n == GMNAV_NO_NODE) continue;
        if (gmnav_grid_is_blocked(_grid, _n)) continue;

        array_push(_out, gmnav_grid_node_to_world(_grid, _n));
    }
    return _out;
}

// formations
function gmnav_util_formation_grid_offsets(_count, _cols, _spacing) { // offsets for a rectangular block formation, centred on 0. returns an array of [dx, dy], one per slot
    var _rows = ceil(_count / _cols);
    var _out  = [];

    var _x0 = -(_cols - 1) * 0.5 * _spacing;
    var _y0 = -(_rows - 1) * 0.5 * _spacing;

    for (var i = 0; i < _count; i++) {
        var _cx = i mod _cols;
        var _cy = i div _cols;
        array_push(_out, [_x0 + _cx * _spacing, _y0 + _cy * _spacing]);
    }
    return _out;
}

function gmnav_util_formation_ring_offsets(_count, _radius, _phase = 0) { // offsets on a circle, centred on 0, in order around the ring
    var _out = [];
    for (var i = 0; i < _count; i++) {
        var _ang = _phase + (i / _count) * 360;
        array_push(_out, [lengthdir_x(_radius, _ang), lengthdir_y(_radius, _ang)]);
    }
    return _out;
}

function gmnav_util_send_group_formation(_agents, _grid, _cx, _cy, _offsets, _priority = gmnav_priority.NORMAL) { // send a group to a formation centred on a world point. pairs with the two offset builders above. returns how many accepted
    var _n = min(array_length(_agents), array_length(_offsets));
    var _accepted = 0;

    for (var i = 0; i < _n; i++) {
        var _o = _offsets[i];
        if (gmnav_util_send_agent(_agents[i], _grid, _cx + _o[0], _cy + _o[1], 0, _priority)) _accepted++;
    }
    return _accepted;
}