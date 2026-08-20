// GMNav Tutorial - Chapter 10 Dataset
// A 44x34 platformer level, 16px tiles. Ground floor with one clearable gap
// and one bottomless chasm, a low ledge, a mid ledge, and a high shelf that
// can only be dropped from.
//
// Movement model: gravity 0.5, jump 8, run 3, terminal fall 9, box 12 by 24.
// Peak jump rise 60.00 px, which is 3.75 tiles.
//
// Baked with three jump strengths:
//   90 standing positions
//   166 WALK links, 19 FALL links, 376 JUMP links, 561 total
//   990 arcs simulated during the bake
//
// Verified routes:
//   floor left to floor right   15 nodes, 100.00 frames, crosses the gap by jumping
//   high shelf to mid ledge     FOUND in 133.97 frames
//   mid ledge to high shelf     no route, the shelf is 64px up and the rise is 60
//   either side of the chasm    no route in either direction
//
// Usage:
//   var _grid  = chapter10_build();
//   var _move  = chapter10_movement();
//   var _graph = gmnav_platgraph_create(_grid, _move);
//   gmnav_platgraph_bake(_graph);

function chapter10_get_map() {
    return { width: 44, height: 34, tile: 16 };
}

/// @desc These must be YOUR player controller's real numbers. See the chapter.
function chapter10_movement() {
    return gmnav_movement_create(
        0.5,   // gravity per frame
        8,     // jump velocity, positive
        3,     // run speed
        9,     // terminal fall speed
        12,    // character width
        24,    // character height
        undefined,
        3      // jump strengths sampled
    );
}

function chapter10_build() {
    var _m = chapter10_get_map();
    var _g = gmnav_grid_create(_m.width, _m.height,
                 gmnav_layout_create(gmnav_layout.ORTHO, _m.tile, _m.tile));

    gmnav_grid_fill_blocked(_g, 0,  0,  43, 0,  true);
    gmnav_grid_fill_blocked(_g, 0,  33, 43, 33, true);
    gmnav_grid_fill_blocked(_g, 0,  0,  0,  33, true);
    gmnav_grid_fill_blocked(_g, 43, 0,  43, 33, true);

    gmnav_grid_fill_blocked(_g, 1,  24, 11, 24, true);   // left ground
    gmnav_grid_fill_blocked(_g, 16, 24, 27, 24, true);   // right ground, gap at 12 to 15
    gmnav_grid_fill_blocked(_g, 38, 24, 42, 24, true);   // far island, chasm at 28 to 37

    gmnav_grid_fill_blocked(_g, 4,  21, 9,  21, true);   // low ledge
    gmnav_grid_fill_blocked(_g, 20, 21, 25, 21, true);   // mid ledge
    gmnav_grid_fill_blocked(_g, 18, 17, 25, 17, true);   // high shelf

    return _g;
}

/// @desc Named standing positions used throughout the chapter.
function chapter10_landmarks() {
    return {
        floor_left  : { col: 2,  row: 23 },
        floor_right : { col: 20, row: 23 },
        low_ledge   : { col: 6,  row: 20 },
        mid_ledge   : { col: 22, row: 20 },
        high_shelf  : { col: 22, row: 16 },
        far_island  : { col: 40, row: 23 }
    };
}
