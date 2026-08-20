// GMNav Tutorial - Chapter 3 Dataset
// A 40x30 fortress, 32px tiles. Twelve chambers formed by three vertical walls
// and two horizontal ones, each pierced by a pair of two-cell doorways.
//
// 933 of the 1200 cells are walkable. The chamber layout is deliberate, it
// forces long winding routes so a single search costs real work, which is what
// makes the scheduling in this chapter measurable rather than theoretical.
//
// A corner to corner search across this map settles 313 cells and pops 461
// heap entries, at a path cost of 49.455844.
//
// Usage:
//   var _map  = chapter3_get_map();
//   var _grid = gmnav_grid_create(_map.width, _map.height,
//                   gmnav_layout_create(gmnav_layout.ORTHO, _map.tile, _map.tile));
//   chapter3_apply_walls(_grid);

function chapter3_get_map() {
    return {
        width  : 40,
        height : 30,
        tile   : 32,

        start_col : 2,  start_row : 2,
        goal_col  : 37, goal_row  : 27
    };
}

/// @desc Outer walls, three vertical chamber walls, two horizontal ones.
function chapter3_apply_walls(_grid) {
    gmnav_grid_fill_blocked(_grid, 0,  0,  39, 0,  true);
    gmnav_grid_fill_blocked(_grid, 0,  29, 39, 29, true);
    gmnav_grid_fill_blocked(_grid, 0,  0,  0,  29, true);
    gmnav_grid_fill_blocked(_grid, 39, 0,  39, 29, true);

    __chapter3_wall_v(_grid, 10, [4, 5, 17, 18]);
    __chapter3_wall_v(_grid, 20, [11, 12, 24, 25]);
    __chapter3_wall_v(_grid, 30, [6, 7, 20, 21]);

    __chapter3_wall_h(_grid, 10, [4, 5, 15, 16, 26, 27]);
    __chapter3_wall_h(_grid, 20, [7, 8, 23, 24, 35, 36]);
}

/// @desc A vertical wall down _col, leaving the listed rows open as doorways.
function __chapter3_wall_v(_grid, _col, _doors) {
    for (var _r = 1; _r < 29; _r++) {
        var _open = false;
        for (var i = 0; i < array_length(_doors); i++) {
            if (_doors[i] == _r) { _open = true; break; }
        }
        if (!_open) gmnav_grid_set_blocked(_grid, _col, _r, true);
    }
}

/// @desc A horizontal wall along _row, leaving the listed columns open.
function __chapter3_wall_h(_grid, _row, _doors) {
    for (var _c = 1; _c < 39; _c++) {
        var _open = false;
        for (var i = 0; i < array_length(_doors); i++) {
            if (_doors[i] == _c) { _open = true; break; }
        }
        if (!_open) gmnav_grid_set_blocked(_grid, _c, _row, true);
    }
}

/// @desc A crowd of agents with random start and goal cells, for the
///       scheduling experiments. Pass the grid so blocked cells are skipped.
function chapter3_random_pairs(_grid, _count) {
    var _out = [];
    var _guard = 0;

    while (array_length(_out) < _count && _guard < _count * 200) {
        _guard++;

        var _a = gmnav_grid_node(_grid, irandom(_grid.width - 1), irandom(_grid.height - 1));
        var _b = gmnav_grid_node(_grid, irandom(_grid.width - 1), irandom(_grid.height - 1));

        if (_a == gmnav_no_node || _b == gmnav_no_node) continue;
        if (gmnav_grid_is_blocked(_grid, _a)) continue;
        if (gmnav_grid_is_blocked(_grid, _b)) continue;

        array_push(_out, { from: _a, to: _b });
    }
    return _out;
}
