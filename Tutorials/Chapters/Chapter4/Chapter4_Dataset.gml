// GMNav Tutorial - Chapter 4 Dataset
// A 30x20 warehouse, 32px tiles. Three double rows of shelving split by a
// central corridor, with clear aisles down both sides.
//
// 396 of the 600 cells are walkable.
//
// The patrol route from (1,1) to (28,18) comes out as 36 raw cells at a cost
// of 38.727922 and a world length of 1239.293506 pixels. String pulling
// reduces that to 6 waypoints and 1179.170493 pixels.
//
// Chapter 9 reuses this exact map and starts knocking holes in it.
//
// Usage:
//   var _map  = chapter4_get_map();
//   var _grid = gmnav_grid_create(_map.width, _map.height,
//                   gmnav_layout_create(gmnav_layout.ORTHO, _map.tile, _map.tile));
//   chapter4_apply_walls(_grid);

function chapter4_get_map() {
    return {
        width  : 30,
        height : 20,
        tile   : 32,

        start_col : 1,  start_row : 1,
        goal_col  : 28, goal_row  : 18
    };
}

/// @desc Outer walls plus three double rows of shelving.
function chapter4_apply_walls(_grid) {
    gmnav_grid_fill_blocked(_grid, 0,  0,  29, 0,  true);
    gmnav_grid_fill_blocked(_grid, 0,  19, 29, 19, true);
    gmnav_grid_fill_blocked(_grid, 0,  0,  0,  19, true);
    gmnav_grid_fill_blocked(_grid, 29, 0,  29, 19, true);

    // each shelf is two rows deep, split by the corridor at columns 12 to 15
    var _rows = [4, 9, 14];

    for (var i = 0; i < 3; i++) {
        var _r = _rows[i];
        gmnav_grid_fill_blocked(_grid, 3,  _r, 11, _r + 1, true);
        gmnav_grid_fill_blocked(_grid, 16, _r, 26, _r + 1, true);
    }
}

/// @desc A four stop patrol circuit around the warehouse floor, for the
///       agent section. Returns world positions, not node ids.
function chapter4_patrol_route(_map) {
    var _t = _map.tile;
    var _p = function(_c, _r, _t) { return { x: _c * _t + _t * 0.5, y: _r * _t + _t * 0.5 }; };

    return [
        _p(1,  1,  _t),   // north west corner
        _p(28, 1,  _t),   // north east corner
        _p(28, 18, _t),   // south east corner
        _p(1,  18, _t)    // south west corner
    ];
}
