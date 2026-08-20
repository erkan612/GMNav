// GMNav Tutorial - Chapter 2 Dataset
// A 20x14 river valley, 32px tiles. Solid outer walls, two rock outcrops, a
// band of swamp across the middle, and a dry crossing two cells wide.
//
// Terrain costs:
//   grass   1  (the default, nothing to set)
//   swamp   8  rows 5 to 8, every column
//   bridge  1  columns 14 and 15, cut back out of the swamp
//
// Usage:
//   var _map  = chapter2_get_map();
//   var _grid = gmnav_grid_create(_map.width, _map.height,
//                   gmnav_layout_create(gmnav_layout.ORTHO, _map.tile, _map.tile));
//   chapter2_apply_walls(_grid);
//   chapter2_apply_terrain(_grid);

function chapter2_get_map() {
    return {
        width  : 20,
        height : 14,
        tile   : 32,

        swamp_cost : 8,

        // the chapter's main journey, top left to bottom right
        start_col : 2,  start_row : 2,
        goal_col  : 17, goal_row  : 11,

        // the second journey, used for the heuristic section
        alt_goal_col : 3, alt_goal_row : 11
    };
}

/// @desc Block the walls and rock outcrops.
function chapter2_apply_walls(_grid) {
    gmnav_grid_fill_blocked(_grid, 0,  0,  19, 0,  true);   // top
    gmnav_grid_fill_blocked(_grid, 0,  13, 19, 13, true);   // bottom
    gmnav_grid_fill_blocked(_grid, 0,  0,  0,  13, true);   // left
    gmnav_grid_fill_blocked(_grid, 19, 0,  19, 13, true);   // right

    gmnav_grid_fill_blocked(_grid, 5,  2, 8,  2,  true);    // upper rocks
    gmnav_grid_fill_blocked(_grid, 11, 11, 14, 11, true);   // lower rocks
}

/// @desc Paint the swamp, then cut the bridge back out of it.
///       Order matters, the bridge overwrites the swamp it sits in.
function chapter2_apply_terrain(_grid) {
    for (var _r = 5; _r <= 8; _r++) {
        for (var _c = 1; _c <= 18; _c++) {
            gmnav_grid_set_cost(_grid, _c, _r, 8);
        }
    }

    for (var _r = 5; _r <= 8; _r++) {
        gmnav_grid_set_cost(_grid, 14, _r, 1);
        gmnav_grid_set_cost(_grid, 15, _r, 1);
    }
}

/// @desc The corner-cutting demonstration from the end of the chapter.
///       Two wall cells placed diagonally opposite each other, leaving a
///       gap no character could actually fit through.
function chapter2_apply_pinch(_grid) {
    gmnav_grid_set_blocked(_grid, 10, 3, true);
    gmnav_grid_set_blocked(_grid, 11, 4, true);
}
