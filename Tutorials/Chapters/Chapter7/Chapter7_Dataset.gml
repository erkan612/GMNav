// GMNav Tutorial - Chapter 7 Dataset
// A 34x22 fortress, 32px tiles. One dividing wall pierced by three doorways of
// deliberately different widths, plus two pillars.
//
//   gap A, row 3        1 cell  wide -> clearance 1
//   gap B, rows 7 to 9  3 cells wide -> clearance 2
//   gap C, rows 13 to 17  5 cells wide -> clearance 3
//
// Crossing from (2,10) to (31,10):
//   clearance 1  30 cells, cost 29.828427,  30 settled, crosses at row 9
//   clearance 2  30 cells, cost 30.656854,  61 settled, crosses at row 8
//   clearance 3  36 cells, cost 37.485281, 202 settled, crosses at row 15
//   clearance 4  no route, nothing on this map fits
//
// Usage:
//   var _grid = chapter7_build();
//   gmnav_clearance_build(_grid);

function chapter7_get_map() {
    return {
        width  : 34,
        height : 22,
        tile   : 32,

        wall_col : 17,

        start_col : 2,  start_row : 10,
        goal_col  : 31, goal_row  : 10
    };
}

function chapter7_build() {
    var _m = chapter7_get_map();
    var _g = gmnav_grid_create(_m.width, _m.height,
                 gmnav_layout_create(gmnav_layout.ORTHO, _m.tile, _m.tile));

    gmnav_grid_fill_blocked(_g, 0,  0,  33, 0,  true);
    gmnav_grid_fill_blocked(_g, 0,  21, 33, 21, true);
    gmnav_grid_fill_blocked(_g, 0,  0,  0,  21, true);
    gmnav_grid_fill_blocked(_g, 33, 0,  33, 21, true);

    // the dividing wall, then the three doorways cut back out of it
    gmnav_grid_fill_blocked(_g, 17, 1, 17, 20, true);

    gmnav_grid_set_blocked(_g, 17, 3, false);                  // gap A
    gmnav_grid_fill_blocked(_g, 17, 7,  17, 9,  false);        // gap B
    gmnav_grid_fill_blocked(_g, 17, 13, 17, 17, false);        // gap C

    gmnav_grid_fill_blocked(_g, 6,  5,  8,  7,  true);         // pillar
    gmnav_grid_fill_blocked(_g, 25, 11, 27, 13, true);         // pillar

    return _g;
}

/// @desc Four unit sizes, given as world radii. Convert with
///       gmnav_clearance_for_radius rather than guessing the cell count.
function chapter7_unit_sizes() {
    return [
        { name: "rat",     radius: 10 },   // needs clearance 1
        { name: "soldier", radius: 24 },   // needs clearance 2
        { name: "ogre",    radius: 40 },   // needs clearance 3
        { name: "golem",   radius: 56 }    // needs clearance 4, will not fit
    ];
}
