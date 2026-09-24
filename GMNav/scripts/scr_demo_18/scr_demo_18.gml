#macro TROOP_W        40
#macro TROOP_H        20
#macro TROOP_TILE     32

#macro TROOP_ROOM_W   1280
#macro TROOP_ROOM_H   768
#macro TROOP_MAP_H    640		// room height minus toolbar

#macro TROOP_TYPE_SCOUT 0
#macro TROOP_TYPE_HEAVY 1

#macro TROOP_FORM_GRID   0
#macro TROOP_FORM_RING   1
#macro TROOP_FORM_COLUMN 2
#macro TROOP_FORM_WEDGE  3
#macro TROOP_FORM_NONE   4
#macro TROOP_FORM_COUNT  5

function troop_make_grid() {
    var _lay = gmnav_layout_create(gmnav_layout.ORTHO, TROOP_TILE, TROOP_TILE);
    var _g   = gmnav_grid_create(TROOP_W, TROOP_H, _lay, 8);

    troop_build_level(_g);
    return _g;
}

function troop_build_level(_grid) {
    // border
    gmnav_grid_fill_blocked(_grid, 0, 0, TROOP_W - 1, 0, true);
    gmnav_grid_fill_blocked(_grid, 0, TROOP_H - 1, TROOP_W - 1, TROOP_H - 1, true);
    gmnav_grid_fill_blocked(_grid, 0, 0, 0, TROOP_H - 1, true);
    gmnav_grid_fill_blocked(_grid, TROOP_W - 1, 0, TROOP_W - 1, TROOP_H - 1, true);

    // river
    for (var _r = 1; _r < TROOP_H - 1; _r++) {
        if (_r == 9 || _r == 10) continue;
        gmnav_grid_set_blocked(_grid, 20, _r, true);
        gmnav_grid_set_blocked(_grid, 21, _r, true);
    }

    // buildings
    gmnav_grid_fill_blocked(_grid,  6,  3,  8,  5, true);   // A, upper left
    gmnav_grid_fill_blocked(_grid, 25,  3, 28,  4, true);   // B, upper right
    gmnav_grid_fill_blocked(_grid,  7, 14,  9, 16, true);   // C, lower left
    gmnav_grid_fill_blocked(_grid, 30, 14, 31, 15, true);   // D, small
    gmnav_grid_fill_blocked(_grid, 13,  7, 14,  8, true);   // pillar, mid left
    gmnav_grid_fill_blocked(_grid, 27, 10, 28, 11, true);   // pillar, mid right
}

function troop_blocked_at(_grid, _x, _y, _rad) { // does a body of this radius overlap a wall
    var _t  = _grid.layout.tile_w;
    var _c1 = floor((_x - _rad) / _t);
    var _c2 = floor((_x + _rad) / _t);
    var _r1 = floor((_y - _rad) / _t);
    var _r2 = floor((_y + _rad) / _t);

    for (var _c = _c1; _c <= _c2; _c++) {
        for (var _r = _r1; _r <= _r2; _r++) {
            var _n = gmnav_grid_node(_grid, _c, _r);
            if (_n == GMNAV_NO_NODE) return true;
            if (gmnav_grid_is_blocked(_grid, _n)) return true;
        }
    }
    return false;
}

function troop_move(_grid, _u) { // apply the agent's proposed velocity with per axis wall stop
    var _a  = _u.ag;
    var _nx = _a.x + _a.vx;

    if (troop_blocked_at(_grid, _nx, _a.y, _a.radius)) _a.vx = 0;
    else                                               _a.x  = _nx;

    var _ny = _a.y + _a.vy;

    if (troop_blocked_at(_grid, _a.x, _ny, _a.radius)) _a.vy = 0;
    else                                               _a.y  = _ny;
}

function troop_make_unit(_sched, _type, _x, _y) {
    var _radius = (_type == TROOP_TYPE_SCOUT) ? 6 : 10;
    var _speed  = (_type == TROOP_TYPE_SCOUT) ? 2.4 : 1.4;

    var _a = gmnav_agent_create(_sched, _x, _y, _radius, _speed);

    _a.avoid_mode   = gmnav_avoid.FOLLOW;
    _a.avoid_str    = 1.0;
    _a.avoid_range  = 2.5;
    _a.follow_gap   = 2.2;
    _a.follow_min   = 1.0;
    _a.follow_sep   = 0.02;
    _a.follow_floor = 0.02;
    _a.follow_cone  = 0.35;
    _a.repath_gap   = 45;

    return {
        ag       : _a,
        type     : _type,
        facing   : 90,		// degrees, default south
        selected : false
    };
}

function troop_formation_name(_idx) {
    switch (_idx) {
        case TROOP_FORM_GRID:   return "GRID";
        case TROOP_FORM_RING:   return "RING";
        case TROOP_FORM_COLUMN: return "COLUMN";
        case TROOP_FORM_WEDGE:  return "WEDGE";
        case TROOP_FORM_NONE:   return "NONE";
    }
    return "?";
}

function troop_formation_offsets(_count, _cx, _cy, _formation, _spacing) { // returns an array of [x, y] world positions
    var _out = [];

    switch (_formation) {
        case TROOP_FORM_NONE:
            array_push(_out, [_cx, _cy]);
            return _out;

        case TROOP_FORM_GRID: {
            var _cols = ceil(sqrt(_count));
            var _rows = ceil(_count / _cols);

            var _x0 = _cx - (_cols - 1) * _spacing * 0.5;
            var _y0 = _cy - (_rows - 1) * _spacing * 0.5;

            for (var i = 0; i < _count; i++) {
                var _c = i mod _cols;
                var _r = i div _cols;
                array_push(_out, [_x0 + _c * _spacing, _y0 + _r * _spacing]);
            }
            return _out;
        }

        case TROOP_FORM_RING: {
            var _rad = _spacing * _count / (2 * pi);
            if (_rad < _spacing) _rad = _spacing;

            for (var i = 0; i < _count; i++) {
                var _ang = 360 * i / _count;
                array_push(_out, [_cx + lengthdir_x(_rad, _ang),
                                  _cy + lengthdir_y(_rad, _ang)]);
            }
            return _out;
        }

        case TROOP_FORM_COLUMN: {
            for (var i = 0; i < _count; i++) {
                array_push(_out, [_cx, _cy - i * _spacing]);
            }
            return _out;
        }

        case TROOP_FORM_WEDGE: {
            var _i    = 0;
            var _row  = 0;

            while (_i < _count) {
                var _n = _row + 1;

                for (var j = 0; j < _n; j++) {
                    if (_i >= _count) break;

                    var _off = (j - (_n - 1) * 0.5) * _spacing;
                    array_push(_out, [_cx + _off, _cy + _row * _spacing]);
                    _i++;
                }
                _row++;
            }
            return _out;
        }
    }
    return _out;
}

function troop_sort_by_distance(_arr, _cx, _cy) { // returns a sorted copy, nearest first
    var _w = [];
    array_copy(_w, 0, _arr, 0, array_length(_arr));

    var _n = array_length(_w);

    for (var i = 1; i < _n; i++) {
        var _cur = _w[i];
        var _cd  = sqr(_cur.ag.x - _cx) + sqr(_cur.ag.y - _cy);
        var _j   = i - 1;

        while (_j >= 0) {
            var _od = sqr(_w[_j].ag.x - _cx) + sqr(_w[_j].ag.y - _cy);
            if (_od <= _cd) break;

            _w[_j + 1] = _w[_j];
            _j--;
        }
        _w[_j + 1] = _cur;
    }

    return _w;
}

function troop_sort_slots_by_distance(_arr, _cx, _cy) { // sorts [x, y] pairs, nearest first
    var _w = [];
    array_copy(_w, 0, _arr, 0, array_length(_arr));

    var _n = array_length(_w);

    for (var i = 1; i < _n; i++) {
        var _cur = _w[i];
        var _cd  = sqr(_cur[0] - _cx) + sqr(_cur[1] - _cy);
        var _j   = i - 1;

        while (_j >= 0) {
            var _od = sqr(_w[_j][0] - _cx) + sqr(_w[_j][1] - _cy);
            if (_od <= _cd) break;

            _w[_j + 1] = _w[_j];
            _j--;
        }
        _w[_j + 1] = _cur;
    }

    return _w;
}

function troop_issue_order(_grid, _units, _cx, _cy, _formation, _max_spacing) {
    var _n = array_length(_units);
    if (_n == 0) return;

    if (_formation == TROOP_FORM_NONE) {
		var _maxr = 0;
		for (var i = 0; i < _n; i++) _maxr = max(_maxr, _units[i].ag.radius);
		var _click_snap = troop_snap_for_body(_grid, _cx, _cy, _maxr + 2, 6);
        if (_click_snap == undefined) return;

        for (var i = 0; i < _n; i++) {
            gmnav_agent_goto(_units[i].ag, _click_snap[0], _click_snap[1]);
        }
        return;
    }

    var _local = troop_formation_offsets(_n, 0, 0, _formation, _max_spacing);

    var _maxr = 0;
    for (var i = 0; i < _n; i++) _maxr = max(_maxr, _units[i].ag.radius);

    var _anchor = troop_snap_formation(_grid, _cx, _cy, _local, _maxr + 2, 12);

    if (_anchor == undefined) _anchor = [_cx, _cy];

    var _slots = [];
    for (var i = 0; i < _n; i++) {
        array_push(_slots, [_anchor[0] + _local[i][0],
                            _anchor[1] + _local[i][1]]);
    }

    var _sorted = troop_sort_by_distance(_units, _anchor[0], _anchor[1]);

    var _sorted_slots = troop_sort_slots_by_distance(_slots, _anchor[0], _anchor[1]);

    for (var i = 0; i < _n; i++) {
        gmnav_agent_goto(_sorted[i].ag, _sorted_slots[i][0], _sorted_slots[i][1],
                         gmnav_priority.NORMAL);
    }
}

function troop_units_in_rect(_units, _x1, _y1, _x2, _y2) { // every unit whose centre is inside the rectangle
    var _out = [];
    var _lo_x = min(_x1, _x2);
    var _hi_x = max(_x1, _x2);
    var _lo_y = min(_y1, _y2);
    var _hi_y = max(_y1, _y2);

    for (var i = 0; i < array_length(_units); i++) {
        var _u = _units[i];
        if (_u.ag.x < _lo_x || _u.ag.x > _hi_x) continue;
        if (_u.ag.y < _lo_y || _u.ag.y > _hi_y) continue;
        array_push(_out, _u);
    }
    return _out;
}

function troop_unit_under_cursor(_units, _x, _y) { // the closest unit within its own radius of the cursor, or undefined
    var _best = undefined;
    var _bd   = 0;

    for (var i = 0; i < array_length(_units); i++) {
        var _u = _units[i];
        var _d = point_distance(_u.ag.x, _u.ag.y, _x, _y);
        var _r = _u.ag.radius * 1.8;

        if (_d > _r) continue;
        if (_best == undefined || _d < _bd) {
            _best = _u;
            _bd   = _d;
        }
    }
    return _best;
}

function troop_selected_list(_units) { // helper for anything that wants only the selected ones
    var _out = [];
    for (var i = 0; i < array_length(_units); i++) {
        if (_units[i].selected) array_push(_out, _units[i]);
    }
    return _out;
}

function troop_update_costfield(_layer, _prof, _units, _old_rect) {
    if (_old_rect[2] >= 0) {
        gmnav_costlayer_clear_region(_layer, _old_rect[0], _old_rect[1],
                                             _old_rect[2], _old_rect[3]);
    }

    var _mc1 = 99999, _mr1 = 99999, _mc2 = -99999, _mr2 = -99999;

    for (var i = 0; i < array_length(_units); i++) {
        var _u = _units[i];
        var _n = gmnav_grid_world_to_node(_layer.grid, _u.ag.x, _u.ag.y);

        if (_n == GMNAV_NO_NODE) continue;

        gmnav_costlayer_set_node(_layer, _n, 3);

        var _c = gmnav_grid_col(_layer.grid, _n);
        var _r = gmnav_grid_row(_layer.grid, _n);
        if (_c < _mc1) _mc1 = _c;
        if (_c > _mc2) _mc2 = _c;
        if (_r < _mr1) _mr1 = _r;
        if (_r > _mr2) _mr2 = _r;
    }

    if (_mc2 < 0) return [0, 0, -1, -1];

    var _uc1 = _mc1, _ur1 = _mr1, _uc2 = _mc2, _ur2 = _mr2;

    if (_old_rect[2] >= 0) {
        _uc1 = min(_uc1, _old_rect[0]);
        _ur1 = min(_ur1, _old_rect[1]);
        _uc2 = max(_uc2, _old_rect[2]);
        _ur2 = max(_ur2, _old_rect[3]);
    }

    gmnav_costprofile_bake_region(_prof, _uc1, _ur1, _uc2, _ur2);

    return [_mc1, _mr1, _mc2, _mr2];
}

function troop_snap_for_body(_grid, _x, _y, _radius, _max_rings) {
    if (!troop_blocked_at(_grid, _x, _y, _radius)) return [_x, _y];

    var _step = max(4, _radius * 0.7);

    for (var _ring = 1; _ring <= _max_rings; _ring++) {
        var _r  = _ring * _step;
        var _samples = max(8, _ring * 8);

        for (var _i = 0; _i < _samples; _i++) {
            var _ang = 360 * _i / _samples;
            var _tx  = _x + lengthdir_x(_r, _ang);
            var _ty  = _y + lengthdir_y(_r, _ang);

            if (!troop_blocked_at(_grid, _tx, _ty, _radius)) return [_tx, _ty];
        }
    }
    return undefined;
}

function troop_settings_apply(_units, _rows, _row_idx, _dir, _only_selected) {
    var _row   = _rows[_row_idx];
    var _param = _row.key;
    var _step  = _row.step * _dir;

    for (var i = 0; i < array_length(_units); i++) {
        var _u = _units[i];
        if (_only_selected && !_u.selected) continue;

        var _old = variable_struct_get(_u.ag, _param);
        var _new = clamp(_old + _step, _row.min, _row.max);
        variable_struct_set(_u.ag, _param, _new);
    }
}

function troop_settings_read(_units, _param, _only_selected) {
    for (var i = 0; i < array_length(_units); i++) {
        if (_only_selected && !_units[i].selected) continue;
        return variable_struct_get(_units[i].ag, _param);
    }
    return 0;
}

function troop_settings_reset(_units, _rows, _only_selected) {
    for (var i = 0; i < array_length(_units); i++) {
        var _u = _units[i];
        if (_only_selected && !_u.selected) continue;

        for (var j = 0; j < array_length(_rows); j++) {
            variable_struct_set(_u.ag, _rows[j].key, _rows[j].def);
        }
    }
}

function troop_formation_fits(_grid, _cx, _cy, _offsets, _radius) {
    for (var i = 0; i < array_length(_offsets); i++) {
        var _o = _offsets[i];
        if (troop_blocked_at(_grid, _cx + _o[0], _cy + _o[1], _radius)) return false;
    }
    return true;
}

function troop_snap_formation(_grid, _cx, _cy, _offsets, _radius, _max_rings) {
    if (troop_formation_fits(_grid, _cx, _cy, _offsets, _radius)) return [_cx, _cy];

	var _step = max(20, _radius * 2.5); // wider rings, fewer samples

    for (var _ring = 1; _ring <= _max_rings; _ring++) {
        var _r       = _ring * _step;
        var _samples = max(8, _ring * 5);

        for (var _i = 0; _i < _samples; _i++) {
            var _ang = 360 * _i / _samples;
            var _tx  = _cx + lengthdir_x(_r, _ang);
            var _ty  = _cy + lengthdir_y(_r, _ang);

            if (troop_formation_fits(_grid, _tx, _ty, _offsets, _radius)) {
                return [_tx, _ty];
            }
        }
    }
    return undefined;
}

function troop_plan_order(_grid, _units, _cx, _cy, _formation, _max_spacing, _queue) {
    var _n = array_length(_units);
    if (_n == 0) return;

    if (_formation == TROOP_FORM_NONE) {
        var _maxr0 = 0;
        for (var i = 0; i < _n; i++) _maxr0 = max(_maxr0, _units[i].ag.radius);

        var _click_snap = troop_snap_for_body(_grid, _cx, _cy, _maxr0 + 2, 6);
        if (_click_snap == undefined) return;

        for (var i = 0; i < _n; i++) {
            array_push(_queue, { u : _units[i], x : _click_snap[0], y : _click_snap[1] });
        }
        return;
    }

    var _maxr = 0;
    for (var i = 0; i < _n; i++) _maxr = max(_maxr, _units[i].ag.radius);

    var _try_spacing = _max_spacing;
    var _min_spacing = _maxr * 2 + 6;
    var _local  = undefined;
    var _anchor = undefined;

    for (var _attempt = 0; _attempt < 4; _attempt++) {
        _local = troop_formation_offsets(_n, 0, 0, _formation, _try_spacing);
        _anchor = troop_snap_formation(_grid, _cx, _cy, _local, _maxr + 2, 12);

        if (_anchor != undefined) break;

        _try_spacing = max(_min_spacing, _try_spacing * 0.85);

        if (_try_spacing <= _min_spacing) break;
    }

    if (_anchor == undefined || _local == undefined) {
        var _click_snap = troop_snap_for_body(_grid, _cx, _cy, _maxr + 2, 8);
        if (_click_snap == undefined) return;

        for (var i = 0; i < _n; i++) {
            array_push(_queue, { u : _units[i], x : _click_snap[0], y : _click_snap[1] });
        }
        return;
    }

    var _slots = [];
    for (var i = 0; i < _n; i++) {
        array_push(_slots, [_anchor[0] + _local[i][0], _anchor[1] + _local[i][1]]);
    }

    var _sorted       = troop_sort_by_distance(_units, _anchor[0], _anchor[1]);
    var _sorted_slots = troop_sort_slots_by_distance(_slots, _anchor[0], _anchor[1]);

    for (var i = 0; i < _n; i++) {
        array_push(_queue, { u : _sorted[i],
                             x : _sorted_slots[i][0],
                             y : _sorted_slots[i][1] });
    }
}