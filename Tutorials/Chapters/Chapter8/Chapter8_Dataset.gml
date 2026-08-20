// GMNav Tutorial - Chapter 8 Dataset
// A 48x32 fortress under siege, 32px tiles. An inner keep with three gates,
// plus rubble in two corners. 1300 of the 1536 cells are walkable.
//
// Measured on this map:
//   one A* from (2,29) to (44,4)   cost 53.526912, 394 pops
//   500 agents, one A* each        34707 pops
//   one flow field to that goal    1300 Dijkstra pops + 1300 vector cells
//
// The crossover sits around thirty agents. Below it, searches are cheaper.
//
// Usage:
//   var _grid = chapter8_build();
//   var _field = gmnav_flowfield_create(_grid);
//   gmnav_flowfield_build(_field, gmnav_grid_node(_grid, 44, 4));

function chapter8_get_map() {
    return {
        width  : 48,
        height : 32,
        tile   : 32,

        muster_col : 2,  muster_row : 29,
        goal_col   : 44, goal_row   : 4
    };
}

function chapter8_build() {
    var _m = chapter8_get_map();
    var _g = gmnav_grid_create(_m.width, _m.height,
                 gmnav_layout_create(gmnav_layout.ORTHO, _m.tile, _m.tile));

    gmnav_grid_fill_blocked(_g, 0,  0,  47, 0,  true);
    gmnav_grid_fill_blocked(_g, 0,  31, 47, 31, true);
    gmnav_grid_fill_blocked(_g, 0,  0,  0,  31, true);
    gmnav_grid_fill_blocked(_g, 47, 0,  47, 31, true);

    // the keep walls, then the gates cut back out of them
    gmnav_grid_fill_blocked(_g, 14, 10, 34, 10, true);
    gmnav_grid_fill_blocked(_g, 14, 22, 34, 22, true);
    gmnav_grid_fill_blocked(_g, 14, 10, 14, 22, true);
    gmnav_grid_fill_blocked(_g, 34, 10, 34, 22, true);

    gmnav_grid_fill_blocked(_g, 18, 10, 19, 10, false);   // north gate
    gmnav_grid_fill_blocked(_g, 26, 10, 27, 10, false);
    gmnav_grid_fill_blocked(_g, 32, 10, 33, 10, false);
    gmnav_grid_fill_blocked(_g, 18, 22, 19, 22, false);   // south gate
    gmnav_grid_fill_blocked(_g, 26, 22, 27, 22, false);
    gmnav_grid_fill_blocked(_g, 32, 22, 33, 22, false);
    gmnav_grid_fill_blocked(_g, 14, 15, 14, 16, false);   // west gate
    gmnav_grid_fill_blocked(_g, 34, 15, 34, 16, false);   // east gate

    gmnav_grid_fill_blocked(_g, 6,  4,  9,  7,  true);    // rubble
    gmnav_grid_fill_blocked(_g, 40, 24, 43, 27, true);

    return _g;
}

/// @desc Three escape points, for the multiple goal section. Every agent
///       flows to whichever is cheapest for it, from a single pass.
function chapter8_exits(_grid) {
    return [
        gmnav_grid_node(_grid, 2,  2),
        gmnav_grid_node(_grid, 45, 29),
        gmnav_grid_node(_grid, 24, 16)
    ];
}
