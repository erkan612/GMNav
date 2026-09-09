#macro DEMO13_W       30
#macro DEMO13_H       20
#macro DEMO13_TILE    32

#macro DEMO13_LANE_C  15   // the guard walks this column, up and down
#macro DEMO13_LANE_R1  2
#macro DEMO13_LANE_R2 17

function demo13_build_level(_grid) {
    gmnav_grid_fill_blocked(_grid, 0, 0, DEMO13_W - 1, 0, true);
    gmnav_grid_fill_blocked(_grid, 0, DEMO13_H - 1, DEMO13_W - 1, DEMO13_H - 1, true);
    gmnav_grid_fill_blocked(_grid, 0, 0, 0, DEMO13_H - 1, true);
    gmnav_grid_fill_blocked(_grid, DEMO13_W - 1, 0, DEMO13_W - 1, DEMO13_H - 1, true);

    // structure either side of the lane, so the crossing is a decision rather than an open field
    gmnav_grid_fill_blocked(_grid,  8,  5, 11,  8, true);
    gmnav_grid_fill_blocked(_grid, 19, 12, 22, 15, true);
}

function demo13_make_grid() {
    var _g = gmnav_grid_create(DEMO13_W, DEMO13_H,
                 gmnav_layout_create(gmnav_layout.ORTHO, DEMO13_TILE, DEMO13_TILE));

    demo13_build_level(_g);
    return _g;
}

function demo13_lane_at(_row) { // a world point on the guard's lane
    return [DEMO13_LANE_C * DEMO13_TILE + DEMO13_TILE * 0.5,
            _row * DEMO13_TILE + DEMO13_TILE * 0.5];
}

function demo13_ahead(_row, _dir, _len) { // the stretch of lane the guard is about to walk
    var _to = clamp(_row + _dir * _len, DEMO13_LANE_R1, DEMO13_LANE_R2);
    return [demo13_lane_at(_row), demo13_lane_at(_to)];
}

function demo13_guard_step(_obj) { // walks the lane, and re-stamps only where it is about to be
    _obj.g_row += _obj.g_dir * _obj.g_speed;

    if (_obj.g_row >= DEMO13_LANE_R2) { _obj.g_row = DEMO13_LANE_R2; _obj.g_dir = -1; }
    if (_obj.g_row <= DEMO13_LANE_R1) { _obj.g_row = DEMO13_LANE_R1; _obj.g_dir =  1; }

    if (!_obj.show_danger) return;

    var _old = _obj.stamp_rect;

    // both rectangles, always. skip the old one and the guard leaves a trail of danger behind it that nothing ever clears
    gmnav_costlayer_clear_region(_obj.danger, _old[0], _old[1], _old[2], _old[3]);

    var _new = gmnav_costlayer_stamp_path(_obj.danger,
                   demo13_ahead(_obj.g_row, _obj.g_dir, _obj.look), 56, 8, 1);

    // every profile over this layer needs the same rectangles, not just the one that happens to be in front of you
    gmnav_costprofile_bake_region(_obj.profile,  _old[0], _old[1], _old[2], _old[3]);
    gmnav_costprofile_bake_region(_obj.profile,  _new[0], _new[1], _new[2], _new[3]);
    gmnav_costprofile_bake_region(_obj.reckless, _old[0], _old[1], _old[2], _old[3]);
    gmnav_costprofile_bake_region(_obj.reckless, _new[0], _new[1], _new[2], _new[3]);

    _obj.stamp_rect  = _new;
    _obj.baked_cells = ((_old[2] - _old[0] + 1) * (_old[3] - _old[1] + 1))
                     + ((_new[2] - _new[0] + 1) * (_new[3] - _new[1] + 1));
}

function demo13_wipe(_obj) {
    var _r = _obj.stamp_rect;
    gmnav_costlayer_clear_region(_obj.danger, _r[0], _r[1], _r[2], _r[3]);
    gmnav_costprofile_bake_region(_obj.profile,  _r[0], _r[1], _r[2], _r[3]);
    gmnav_costprofile_bake_region(_obj.reckless, _r[0], _r[1], _r[2], _r[3]);
    _obj.stamp_rect = [0, 0, -1, -1];
}

function demo13_send_agent(_obj) {
    var _p = gmnav_grid_node_to_world(_obj.grid,
                 gmnav_grid_node(_obj.grid, _obj.goal_c, _obj.goal_r));

    gmnav_agent_goto(_obj.agent, _p[0], _p[1]);
    gmnav_agent_goto(_obj.brute, _p[0], _p[1]);
}