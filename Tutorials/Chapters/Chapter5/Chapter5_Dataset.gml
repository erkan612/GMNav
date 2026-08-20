// GMNav Tutorial - Chapter 5 Dataset
// One 16x16 logical map, rendered through five different layouts.
//
// The cells never change. Only the layout descriptor does, which is the
// entire point of the chapter.
//
// A search from (2,2) to (13,3) on this map:
//   ORTHO          12 cells, cost 12.242641, 21 settled
//   ISO_DIAMOND    12 cells, cost 12.242641, 21 settled   (identical, same graph)
//   ISO_STAGGERED  14 cells, cost 23.354102, 30 settled
//   HEX_POINTY     14 cells, cost 13.196048, 35 settled
//   HEX_FLAT       12 cells, cost 11.000000, 11 settled
//
// Usage:
//   var _grid = chapter5_build(gmnav_layout.ISO_DIAMOND);

function chapter5_get_map() {
    return {
        width  : 16,
        height : 16,
        start_col : 2,  start_row : 2,
        goal_col  : 13, goal_row  : 3
    };
}

/// @desc Tile dimensions that suit each layout. Isometric wants wide, flat
///       tiles; hex wants the two dimensions close but not equal.
function chapter5_tile_size(_mode) {
    switch (_mode) {
        case gmnav_layout.ORTHO:         return { w: 32, h: 32 };
        case gmnav_layout.ISO_DIAMOND:   return { w: 64, h: 32 };
        case gmnav_layout.ISO_STAGGERED: return { w: 64, h: 32 };
        case gmnav_layout.HEX_POINTY:    return { w: 32, h: 36 };
        case gmnav_layout.HEX_FLAT:      return { w: 36, h: 32 };
    }
    return { w: 32, h: 32 };
}

/// @desc Build the same logical map under any layout.
function chapter5_build(_mode, _origin_x = 0, _origin_y = 0) {
    var _map = chapter5_get_map();
    var _t   = chapter5_tile_size(_mode);

    var _nb = (_mode == gmnav_layout.HEX_POINTY || _mode == gmnav_layout.HEX_FLAT)
            ? gmnav_neighbours.SIX
            : gmnav_neighbours.EIGHT;

    var _lay  = gmnav_layout_create(_mode, _t.w, _t.h, _nb,
                                    gmnav_costmode.LOGICAL, _origin_x, _origin_y);
    var _grid = gmnav_grid_create(_map.width, _map.height, _lay);

    chapter5_apply_walls(_grid);
    return _grid;
}

/// @desc Outer walls, one long wall with a gap near the bottom, and a spur.
function chapter5_apply_walls(_grid) {
    gmnav_grid_fill_blocked(_grid, 0,  0,  15, 0,  true);
    gmnav_grid_fill_blocked(_grid, 0,  15, 15, 15, true);
    gmnav_grid_fill_blocked(_grid, 0,  0,  0,  15, true);
    gmnav_grid_fill_blocked(_grid, 15, 0,  15, 15, true);

    gmnav_grid_fill_blocked(_grid, 7, 2, 7, 11, true);    // gap at rows 12 to 14
    gmnav_grid_fill_blocked(_grid, 9, 9, 13, 9, true);    // spur
}

/// @desc A plain room with a wall of _rows blocked rows across the middle,
///       for the staggered adjacency demonstration.
function chapter5_build_barrier(_mode, _rows) {
    var _t = chapter5_tile_size(_mode);

    var _nb = (_mode == gmnav_layout.HEX_POINTY || _mode == gmnav_layout.HEX_FLAT)
            ? gmnav_neighbours.SIX
            : gmnav_neighbours.EIGHT;

    var _grid = gmnav_grid_create(16, 16,
                    gmnav_layout_create(_mode, _t.w, _t.h, _nb));

    gmnav_grid_fill_blocked(_grid, 0,  0,  15, 0,  true);
    gmnav_grid_fill_blocked(_grid, 0,  15, 15, 15, true);
    gmnav_grid_fill_blocked(_grid, 0,  0,  0,  15, true);
    gmnav_grid_fill_blocked(_grid, 15, 0,  15, 15, true);

    for (var _k = 0; _k < _rows; _k++) {
        gmnav_grid_fill_blocked(_grid, 1, 7 + _k, 14, 7 + _k, true);
    }
    return _grid;
}
