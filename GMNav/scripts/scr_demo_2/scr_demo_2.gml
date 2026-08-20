function demo2_build_walls(_grid) {
    var _w = _grid.width;
    var _h = _grid.height;

    gmnav_grid_fill_blocked(_grid, 0,      0,      _w - 1, 0,      true);
    gmnav_grid_fill_blocked(_grid, 0,      _h - 1, _w - 1, _h - 1, true);
    gmnav_grid_fill_blocked(_grid, 0,      0,      0,      _h - 1, true);
    gmnav_grid_fill_blocked(_grid, _w - 1, 0,      _w - 1, _h - 1, true);

    gmnav_grid_fill_blocked(_grid, 10, 1,  10, 6,  true);
    gmnav_grid_fill_blocked(_grid, 10, 11, 10, 18, true);

    gmnav_grid_fill_blocked(_grid, 20, 1,  20, 4,  true);
    gmnav_grid_fill_blocked(_grid, 20, 9,  20, 18, true);

    gmnav_grid_fill_blocked(_grid, 4,  8,  6,  10, true);
    gmnav_grid_fill_blocked(_grid, 14, 14, 16, 16, true);
    gmnav_grid_fill_blocked(_grid, 24, 5,  26, 7,  true);
}

function demo2_random_open(_grid) {
    for (var i = 0; i < 400; i++) {
        var _c = irandom(_grid.width  - 1);
        var _r = irandom(_grid.height - 1);
        var _n = gmnav_grid_node(_grid, _c, _r);

        if (_n != GMNAV_NO_NODE && !gmnav_grid_is_blocked(_grid, _n)) {
            var _p = gmnav_grid_node_to_world(_grid, _n);
            return { x: _p[0], y: _p[1] };
        }
    }
    return undefined;
}

function demo2_build_buckets(_agents, _cell) {
    var _b = {};

    for (var i = 0; i < array_length(_agents); i++) {
        var _a = _agents[i];
        var _k = string(floor(_a.x / _cell)) + "," + string(floor(_a.y / _cell));

        if (!variable_struct_exists(_b, _k)) _b[$ _k] = [];
        array_push(_b[$ _k], _a);
    }
    return _b;
}

function demo2_neighbours(_buckets, _agent, _cell) {
    var _cx = floor(_agent.x / _cell);
    var _cy = floor(_agent.y / _cell);
    var _out = [];

    for (var _dx = -1; _dx <= 1; _dx++) {
        for (var _dy = -1; _dy <= 1; _dy++) {
            var _k = string(_cx + _dx) + "," + string(_cy + _dy);
            if (!variable_struct_exists(_buckets, _k)) continue;

            var _list = _buckets[$ _k];
            for (var i = 0; i < array_length(_list); i++) array_push(_out, _list[i]);
        }
    }
    return _out;
}

function demo2_blocked_at(_grid, _x, _y, _rad) {
    var _t = _grid.layout.tile_w;

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

function demo2_resolve_overlap(_grid, _a) {
    if (!demo2_blocked_at(_grid, _a.x, _a.y, _a.radius)) return false;

    var _t = _grid.layout.tile_w;

    for (var _step = 2; _step <= _t * 2; _step += 2) {
        for (var _ang = 0; _ang < 360; _ang += 30) {
            var _nx = _a.x + lengthdir_x(_step, _ang);
            var _ny = _a.y + lengthdir_y(_step, _ang);

            if (!demo2_blocked_at(_grid, _nx, _ny, _a.radius)) {
                _a.x = _nx;
                _a.y = _ny;
                _a.vx = 0;
                _a.vy = 0;
                return true;
            }
        }
    }
    return false;
}

function demo2_move_agent(_grid, _a) {
    var _hit = false;

    var _nx = _a.x + _a.vx;
    if (demo2_blocked_at(_grid, _nx, _a.y, _a.radius)) { _a.vx = 0; _hit = true; }
    else _a.x = _nx;

    var _ny = _a.y + _a.vy;
    if (demo2_blocked_at(_grid, _a.x, _ny, _a.radius)) { _a.vy = 0; _hit = true; }
    else _a.y = _ny;

    if (demo2_resolve_overlap(_grid, _a)) _hit = true;

    return _hit;
}

function demo2_bucket_build(_agents, _cell, _cols, _rows) {
    var _b = array_create(_cols * _rows, undefined);

    for (var i = 0; i < array_length(_agents); i++) {
        var _a = _agents[i];
        var _cx = clamp(floor(_a.x / _cell), 0, _cols - 1);
        var _cy = clamp(floor(_a.y / _cell), 0, _rows - 1);
        var _k  = _cy * _cols + _cx;

        if (_b[_k] == undefined) _b[_k] = [];
        array_push(_b[_k], _a);
    }
    return _b;
}

function demo2_bucket_gather(_b, _out, _a, _cell, _cols, _rows) {
    array_resize(_out, 0);

    var _cx = clamp(floor(_a.x / _cell), 0, _cols - 1);
    var _cy = clamp(floor(_a.y / _cell), 0, _rows - 1);

    for (var _dy = -1; _dy <= 1; _dy++) {
        var _yy = _cy + _dy;
        if (_yy < 0 || _yy >= _rows) continue;

        for (var _dx = -1; _dx <= 1; _dx++) {
            var _xx = _cx + _dx;
            if (_xx < 0 || _xx >= _cols) continue;

            var _list = _b[_yy * _cols + _xx];
            if (_list == undefined) continue;

            for (var i = 0; i < array_length(_list); i++) array_push(_out, _list[i]);
        }
    }
    return _out;
}

function demo2_clamp_velocity(_grid, _a) {
    var _look = _a.radius + 4;

    if (_a.vx != 0) {
        var _px = _a.x + sign(_a.vx) * _look;
        if (demo2_blocked_at(_grid, _px, _a.y, _a.radius * 0.6)) _a.vx = 0;
    }
    if (_a.vy != 0) {
        var _py = _a.y + sign(_a.vy) * _look;
        if (demo2_blocked_at(_grid, _a.x, _py, _a.radius * 0.6)) _a.vy = 0;
    }
}