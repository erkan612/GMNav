/// Room must be at least 40x20 cells. _s is the walking surface row; the earth
/// fills from _s+1 to the bottom of the grid, so both pits are genuine holes.
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

    gmnav_grid_fill_blocked(_grid, _w - 6, _s - 10, _w - 3, _s - 10, true);
}

function demo3_movement() {
    // gravity, jump_vel, run_speed, max_fall, width, height, air_speed, jump_levels, jump_bias
    // bias must exceed air_speed / run_speed, here 4/3 = 1.333, or a jump
    // across flat ground costs less than walking it and the agent hops
    return gmnav_movement_create(0.5, 12, 3, 12, 20, 44, 4, 7, 1.5);
}

/// Replays a link's stored launch and returns the arc as [[x,y],...].
/// This is the trajectory the agent will actually fly, not the cosmetic bow
/// gmnav_debug_draw_platgraph draws.
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

function demo3_arc_apex(_pg, _from, _to) {
    var _pts = demo3_arc_points(_pg, _from, _to);
    var _n   = array_length(_pts);
    if (_n == 0) return 0;

    var _top = _pg.node_y[_from];
    for (var i = 0; i < _n; i++) _top = min(_top, _pts[i][1]);

    return round(_pg.node_y[_from] - _top);
}