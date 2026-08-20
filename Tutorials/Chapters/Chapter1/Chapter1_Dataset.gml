// GMNav Tutorial - Chapter 1 Dataset
// A 16x12 dungeon room, 32px tiles. Solid outer walls, a dividing wall with a
// doorway near the bottom, and two pillars.
//
// 125 of the 192 cells are walkable.
//
// Usage:
//   var _map  = chapter1_get_map();
//   var _grid = gmnav_grid_create(_map.width, _map.height,
//                   gmnav_layout_create(gmnav_layout.ORTHO, _map.tile, _map.tile));
//   chapter1_apply_walls(_grid);

function chapter1_get_map() {
    return {
        width  : 16,
        height : 12,
        tile   : 32,

        // where the tutorial's searches begin and end
        start_col : 2,  start_row : 2,
        goal_col  : 13, goal_row  : 2
    };
}

/// @desc Block every wall cell of the Chapter 1 room on a grid.
function chapter1_apply_walls(_grid) {
    // outer walls
    gmnav_grid_fill_blocked(_grid, 0,  0,  15, 0,  true);   // top
    gmnav_grid_fill_blocked(_grid, 0,  11, 15, 11, true);   // bottom
    gmnav_grid_fill_blocked(_grid, 0,  0,  0,  11, true);   // left
    gmnav_grid_fill_blocked(_grid, 15, 0,  15, 11, true);   // right

    // dividing wall, column 8, with a doorway left open at rows 8 to 10
    gmnav_grid_fill_blocked(_grid, 8, 1, 8, 7, true);

    // pillars
    gmnav_grid_fill_blocked(_grid, 4,  4, 5,  5, true);
    gmnav_grid_fill_blocked(_grid, 11, 7, 12, 8, true);
}

/// @desc The same room as a plain array of rows, for readers who would rather
///       see the shape than a list of rectangles. 1 is wall, 0 is floor.
///       Row 0 is the top.
function chapter1_get_rows() {
    return [
        [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
        [1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,1],
        [1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,1],
        [1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,1],
        [1,0,0,0,1,1,0,0,1,0,0,0,0,0,0,1],
        [1,0,0,0,1,1,0,0,1,0,0,0,0,0,0,1],
        [1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,1],
        [1,0,0,0,0,0,0,0,1,0,0,1,1,0,0,1],
        [1,0,0,0,0,0,0,0,0,0,0,1,1,0,0,1],
        [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
        [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
        [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
    ];
}

/// @desc Build the room from the row array instead of the rectangles above.
///       Both produce an identical grid, this one shows the callback importer.
function chapter1_apply_walls_from_rows(_grid) {
    var _rows = chapter1_get_rows();

    gmnav_grid_import_callback(_grid, function(_col, _row) {
        var _rows = chapter1_get_rows();
        return (_rows[_row][_col] == 1);
    });
}
