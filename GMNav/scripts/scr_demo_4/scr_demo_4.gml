function demo4_build_level(_grid) { // requires room of at least 40x22 cells
    var _w = _grid.width;
    var _h = _grid.height;

    if (_w < 40 || _h < 22) {
        show_debug_message("demo4: needs at least a 40x22 grid, room is too small.");
    }

    gmnav_grid_fill_blocked(_grid, 0,      0,      _w - 1, 0,      true);
    gmnav_grid_fill_blocked(_grid, 0,      _h - 1, _w - 1, _h - 1, true);
    gmnav_grid_fill_blocked(_grid, 0,      0,      0,      _h - 1, true);
    gmnav_grid_fill_blocked(_grid, _w - 1, 0,      _w - 1, _h - 1, true);

    gmnav_grid_fill_height(_grid, 16, 3, _w - 4, _h - 4, 2);   // plateau
    gmnav_grid_fill_height(_grid, 24, 7, _w - 9, _h - 8, 5);   // mesa

    // ramp 1, ground to plateau, one cell of z 1 at the north west corner
    gmnav_grid_fill_height(_grid, 15, 3, 15, 4, 1);

    // ramp 2, plateau to mesa, z 3 then z 4 at the mesa's south east corner
    gmnav_grid_fill_height(_grid, _w - 8, _h - 9, _w - 8, _h - 8, 3);
    gmnav_grid_fill_height(_grid, _w - 9, _h - 9, _w - 9, _h - 8, 4);

    // a couple of rocks, so blocked and elevated are visibly different things
    gmnav_grid_fill_blocked(_grid, 6, 4,      8, 6,      true);
    gmnav_grid_fill_blocked(_grid, 5, _h - 7, 7, _h - 5, true);
}

function demo4_preset(_i) {
    switch (_i) {
        case 0: return { name : "no limits",  climb : undefined, drop : undefined };
        case 1: return { name : "climb 0",    climb : 0, drop : 5 };
        case 2: return { name : "climb 1",    climb : 1, drop : 1 };
        case 3: return { name : "climb 1, drop 5", climb : 1, drop : 5 };
        case 4: return { name : "climb 2",    climb : 2, drop : 5 };
        default: return { name : "climb 3",   climb : 3, drop : 5 };
    }
}

function demo4_preset_count() { return 6; }