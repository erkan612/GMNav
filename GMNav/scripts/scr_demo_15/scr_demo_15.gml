#macro DEMO15_W       40
#macro DEMO15_H       22
#macro DEMO15_TILE    32

#macro DEMO15_WALL_A   9    // four cell door, rows 9 to 12
#macro DEMO15_WALL_B  15    // single cell door, row 10
#macro DEMO15_WALL_C  25    // two cell door, rows 9 and 10
#macro DEMO15_WALL_D  30    // five cell opening, rows 7 to 11

#macro DEMO15_N       20

function demo15_build_level(_grid) {
    gmnav_grid_fill_blocked(_grid, 0, 0, DEMO15_W - 1, 0, true);
    gmnav_grid_fill_blocked(_grid, 0, DEMO15_H - 1, DEMO15_W - 1, DEMO15_H - 1, true);
    gmnav_grid_fill_blocked(_grid, 0, 0, 0, DEMO15_H - 1, true);
    gmnav_grid_fill_blocked(_grid, DEMO15_W - 1, 0, DEMO15_W - 1, DEMO15_H - 1, true);

    // spawn room, cols 1 to 8
    gmnav_grid_fill_blocked(_grid, 3, 3, 4, 4, true);
    gmnav_grid_fill_blocked(_grid, 6, 10, 6, 11, true);
    gmnav_grid_fill_blocked(_grid, 6, 17, 7, 18, true);

    // wall A, four cell door at rows 9 to 12
    for (var _r = 1; _r < DEMO15_H - 1; _r++) {
        if (_r >= 9 && _r <= 12) continue;
        gmnav_grid_set_blocked(_grid, DEMO15_WALL_A, _r, true);
    }

    // corridor 1, cols 10 to 14. tall pillar forces top or bottom
    gmnav_grid_fill_blocked(_grid, 12, 4, 13, 17, true);

    // wall B, single cell door at row 10
    for (var _r = 1; _r < DEMO15_H - 1; _r++) {
        if (_r == 10) continue;
        gmnav_grid_set_blocked(_grid, DEMO15_WALL_B, _r, true);
    }

    // zigzag, cols 16 to 24
    gmnav_grid_fill_blocked(_grid, 16, 6,  19, 6,  true);
    gmnav_grid_fill_blocked(_grid, 20, 15, 23, 15, true);
    gmnav_grid_fill_blocked(_grid, 20, 10, 22, 11, true);

    // wall C, two cell door at rows 9 and 10
    for (var _r = 1; _r < DEMO15_H - 1; _r++) {
        if (_r == 9 || _r == 10) continue;
        gmnav_grid_set_blocked(_grid, DEMO15_WALL_C, _r, true);
    }

    // corridor 2, cols 26 to 29. two small pillars
    gmnav_grid_fill_blocked(_grid, 27, 4,  27, 7,  true);
    gmnav_grid_fill_blocked(_grid, 28, 14, 28, 17, true);

    // wall D, five cell opening at rows 7 to 11
    for (var _r = 1; _r < DEMO15_H - 1; _r++) {
        if (_r >= 7 && _r <= 11) continue;
        gmnav_grid_set_blocked(_grid, DEMO15_WALL_D, _r, true);
    }

    // goal room, cols 31 to 38
    gmnav_grid_fill_blocked(_grid, 33, 5,  34, 6,  true);
    gmnav_grid_fill_blocked(_grid, 33, 15, 34, 16, true);
}

function demo15_make_grid() {
    var _lay = gmnav_layout_create(gmnav_layout.ORTHO, DEMO15_TILE, DEMO15_TILE);
    var _g   = gmnav_grid_create(DEMO15_W, DEMO15_H, _lay);

    demo15_build_level(_g);
    return _g;
}

function demo15_spawn_pos(_i) { // a five by four block in the spawn room
    var _c = 2 + (_i mod 5);
    var _r = 5 + (_i div 5);

    return [_c * DEMO15_TILE + DEMO15_TILE * 0.5,
            _r * DEMO15_TILE + DEMO15_TILE * 0.5];
}

function demo15_blocked_at(_grid, _x, _y, _rad) {
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

function demo15_move(_grid, _a) {
    var _nx = _a.x + _a.vx;
    if (demo15_blocked_at(_grid, _nx, _a.y, _a.radius)) _a.vx = 0;
    else _a.x = _nx;

    var _ny = _a.y + _a.vy;
    if (demo15_blocked_at(_grid, _a.x, _ny, _a.radius)) _a.vy = 0;
    else _a.y = _ny;
}

function demo15_apply_mode(_obj) {
    var _n = array_length(_obj.agents);
    for (var i = 0; i < _n; i++) _obj.agents[i].avoid_mode = _obj.mode;
}

function demo15_send_all_to(_obj, _x, _y, _radius) { // send every agent to a world point, spread over a disc so they do not all stack on one cell
    var _n = array_length(_obj.agents);

    for (var i = 0; i < _n; i++) {
        var _ang = i * 137.5;
        var _rad = _radius * sqrt(i / max(1, _n - 1));

        var _tx = _x + lengthdir_x(_rad, _ang);
        var _ty = _y + lengthdir_y(_rad, _ang);

        if (gmnav_util_node_at(_obj.grid, _tx, _ty) == GMNAV_NO_NODE) { // if the offset target is blocked, snap back to the click point
            _tx = _x;
            _ty = _y;
        }

        gmnav_util_send_agent(_obj.agents[i], _obj.grid, _tx, _ty);
    }
}

function demo15_send_all_home(_obj) {
    var _n = array_length(_obj.agents);

    for (var i = 0; i < _n; i++) {
        var _sp = demo15_spawn_pos(i);
        gmnav_util_send_agent(_obj.agents[i], _obj.grid, _sp[0], _sp[1]);
    }
}

function demo15_reset(_obj) {
    var _n = array_length(_obj.agents);

    for (var i = 0; i < _n; i++) {
        var _sp = demo15_spawn_pos(i);
        gmnav_util_reset_agent(_obj.agents[i], _obj.grid, _sp[0], _sp[1]);
    }
}

function demo15_count_arrived(_obj) {
    var _n = array_length(_obj.agents);
    var _c = 0;

    for (var i = 0; i < _n; i++) {
        if (gmnav_agent_arrived(_obj.agents[i])) _c++;
    }
    return _c;
}