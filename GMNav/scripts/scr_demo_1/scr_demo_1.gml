function demo1_build_walls(_grid) {
    var _w = _grid.width;
    var _h = _grid.height;

    gmnav_grid_fill_blocked(_grid, 0,      0,      _w - 1, 0,      true);
    gmnav_grid_fill_blocked(_grid, 0,      _h - 1, _w - 1, _h - 1, true);
    gmnav_grid_fill_blocked(_grid, 0,      0,      0,      _h - 1, true);
    gmnav_grid_fill_blocked(_grid, _w - 1, 0,      _w - 1, _h - 1, true);

    gmnav_grid_fill_blocked(_grid, 8, 1, 8, 12, true);

    gmnav_grid_fill_blocked(_grid, 16, 5, 16, _h - 2, true);

    gmnav_grid_fill_blocked(_grid, 17, 9, 23, 9, true);

    gmnav_grid_fill_blocked(_grid, 4,  5,  5,  6,  true);
    gmnav_grid_fill_blocked(_grid, 11, 13, 12, 14, true);
}

function demo1_snap_to_open(_grid, _x, _y) {
    var _n = gmnav_grid_world_to_node(_grid, _x, _y);

    if (_n == GMNAV_NO_NODE)          return undefined;
    if (gmnav_grid_is_blocked(_grid, _n)) return undefined;

    var _p = gmnav_grid_node_to_world(_grid, _n);
    return { x: _p[0], y: _p[1] };
}