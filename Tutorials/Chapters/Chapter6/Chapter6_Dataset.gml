// GMNav Tutorial - Chapter 6 Dataset
// A 32x20 battlefield, 32px tiles. Open ground with three ruins for cover and
// one turret covering the centre.
//
// The turret stamp: centre of cell (16,10), radius 200px, peak 20, quadratic
// falloff. It touches 121 cells, rect (9,3) to (23,17).
//
// Crossing from (1,10) to (30,10):
//   berserker, weight 0 : 30 cells, cost 30.656854, danger crossed 80.13
//   soldier,   weight 1 : 30 cells, cost 34.031202, danger crossed  0.06
//
// Same cells, same length, one route walks through the turret's field and the
// other does not.
//
// Usage:
//   var _grid = chapter6_build();
//   var _danger = chapter6_danger_layer(_grid);

function chapter6_get_map() {
    return {
        width  : 32,
        height : 20,
        tile   : 32,

        turret_col : 16, turret_row : 10,
        turret_radius : 200,
        turret_peak   : 20,

        start_col : 1,  start_row : 10,
        goal_col  : 30, goal_row  : 10
    };
}

function chapter6_build() {
    var _m = chapter6_get_map();
    var _g = gmnav_grid_create(_m.width, _m.height,
                 gmnav_layout_create(gmnav_layout.ORTHO, _m.tile, _m.tile));

    gmnav_grid_fill_blocked(_g, 0,  0,  31, 0,  true);
    gmnav_grid_fill_blocked(_g, 0,  19, 31, 19, true);
    gmnav_grid_fill_blocked(_g, 0,  0,  0,  19, true);
    gmnav_grid_fill_blocked(_g, 31, 0,  31, 19, true);

    gmnav_grid_fill_blocked(_g, 7,  3,  10, 5,  true);   // north ruin
    gmnav_grid_fill_blocked(_g, 7,  14, 10, 16, true);   // south ruin
    gmnav_grid_fill_blocked(_g, 20, 8,  23, 11, true);   // central ruin

    return _g;
}

/// @desc The turret's threat, as a standalone layer. Returns the layer and
///       the cell rect the stamp touched, which you need for region baking.
function chapter6_danger_layer(_grid) {
    var _m = chapter6_get_map();
    var _t = _m.tile;

    var _layer = gmnav_costlayer_create(_grid, "turret");

    var _wx = _m.turret_col * _t + _t * 0.5;
    var _wy = _m.turret_row * _t + _t * 0.5;

    var _rect = gmnav_costlayer_stamp_radial(_layer, _wx, _wy,
                                             _m.turret_radius, _m.turret_peak, 2);

    return { layer: _layer, rect: _rect };
}

/// @desc Enemy-held ground on the right of the map, as a second layer, to
///       show two independent influences stacking.
function chapter6_territory_layer(_grid) {
    var _layer = gmnav_costlayer_create(_grid, "enemy_territory");

    for (var _c = 21; _c <= 30; _c++) {
        for (var _r = 1; _r <= 18; _r++) {
            gmnav_costlayer_set(_layer, _c, _r, 4);
        }
    }
    return _layer;
}

/// @desc Three agent types reading the same danger layer with different
///       weights. This is the whole point of profiles.
function chapter6_profiles(_grid, _danger) {
    var _berserker = gmnav_costprofile_create(_grid, "berserker");
    gmnav_costprofile_add(_berserker, _danger, 0);

    var _soldier = gmnav_costprofile_create(_grid, "soldier");
    gmnav_costprofile_add(_soldier, _danger, 1);

    var _scout = gmnav_costprofile_create(_grid, "scout");
    gmnav_costprofile_add(_scout, _danger, 4);

    gmnav_costprofile_bake(_berserker);
    gmnav_costprofile_bake(_soldier);
    gmnav_costprofile_bake(_scout);

    return { berserker: _berserker, soldier: _soldier, scout: _scout };
}
