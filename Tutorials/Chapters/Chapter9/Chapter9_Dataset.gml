// GMNav Tutorial - Chapter 9 Dataset
// Chapter 4's warehouse, unchanged, plus the things that break it.
//
// Baseline patrol (1,1) to (28,18): 36 cells, 305 pops.
//
// With the barricade dropped across the central corridor:
//   a fresh search        37 cells, 231 pops, 0 blocked cells on the path
//   a search suspended at 120 pops, then resumed after the edit
//                         FOUND, but 5 blocked cells on the path
//
// A full height barricade at column 13 seals the warehouse: FAILED after 251 pops.
//
// Usage:
//   var _grid = chapter9_build();
//   chapter9_drop_barricade(_grid);

function chapter9_get_map() {
    return {
        width  : 30,
        height : 20,
        tile   : 32,

        start_col : 1,  start_row : 1,
        goal_col  : 28, goal_row  : 18
    };
}

/// @desc The Chapter 4 warehouse, unchanged.
function chapter9_build() {
    var _m = chapter9_get_map();
    var _g = gmnav_grid_create(_m.width, _m.height,
                 gmnav_layout_create(gmnav_layout.ORTHO, _m.tile, _m.tile));

    gmnav_grid_fill_blocked(_g, 0,  0,  29, 0,  true);
    gmnav_grid_fill_blocked(_g, 0,  19, 29, 19, true);
    gmnav_grid_fill_blocked(_g, 0,  0,  0,  19, true);
    gmnav_grid_fill_blocked(_g, 29, 0,  29, 19, true);

    var _rows = [4, 9, 14];
    for (var i = 0; i < 3; i++) {
        var _r = _rows[i];
        gmnav_grid_fill_blocked(_g, 3,  _r, 11, _r + 1, true);
        gmnav_grid_fill_blocked(_g, 16, _r, 26, _r + 1, true);
    }
    return _g;
}

/// @desc Crates collapse across the central corridor. Passable routes remain.
function chapter9_drop_barricade(_grid) {
    gmnav_grid_fill_blocked(_grid, 12, 7, 15, 12, true);
}

/// @desc A full height barricade. Nothing gets through after this.
function chapter9_seal(_grid) {
    gmnav_grid_fill_blocked(_grid, 13, 1, 13, 18, true);
}

/// @desc A door you can open and close. Returns whether anything changed,
///       which is also whether the grid version moved.
function chapter9_set_door(_grid, _open) {
    var _before = _grid.version;
    gmnav_grid_fill_blocked(_grid, 13, 8, 13, 11, !_open);
    return (_grid.version != _before);
}
