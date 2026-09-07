#macro DEMO5_ROAD_R      9    // the sunken road, walkable, running east to west
#macro DEMO5_WALL_N      8    // its retaining walls, which cannot be crossed
#macro DEMO5_WALL_S     10
#macro DEMO5_BRIDGE_A    5    // two crossings, so there is a routing choice
#macro DEMO5_BRIDGE_B   14
#macro DEMO5_LIFT       22    // pixels a deck is drawn above its cell

function demo5_build_level(_grid) {
    var _w = _grid.width;
    var _h = _grid.height;

    if (_w < 20 || _h < 20) {
        show_debug_message("demo5: needs at least a 20x20 grid.");
        return;
    }

    gmnav_grid_fill_blocked(_grid, 0,      0,      _w - 1, 0,      true);
    gmnav_grid_fill_blocked(_grid, 0,      _h - 1, _w - 1, _h - 1, true);
    gmnav_grid_fill_blocked(_grid, 0,      0,      0,      _h - 1, true);
    gmnav_grid_fill_blocked(_grid, _w - 1, 0,      _w - 1, _h - 1, true);

    gmnav_grid_fill_blocked(_grid, 1, DEMO5_WALL_N, _w - 2, DEMO5_WALL_N, true);
    gmnav_grid_fill_blocked(_grid, 1, DEMO5_WALL_S, _w - 2, DEMO5_WALL_S, true);

    var _ov = gmnav_overlay_create(_grid);

    demo5_add_bridge(_grid, _ov, DEMO5_BRIDGE_A);
    demo5_add_bridge(_grid, _ov, DEMO5_BRIDGE_B);

    gmnav_overlay_finish(_ov);
}

function demo5_add_bridge(_grid, _ov, _col) {
    var _a = gmnav_overlay_add(_ov, _col, DEMO5_WALL_N, 1);
    var _b = gmnav_overlay_add(_ov, _col, DEMO5_ROAD_R, 1);
    var _c = gmnav_overlay_add(_ov, _col, DEMO5_WALL_S, 1);

    gmnav_overlay_link(_ov, gmnav_grid_node(_grid, _col, DEMO5_WALL_N - 1), _a,
                       gmnav_link.STAIR, true);
    gmnav_overlay_link(_ov, _c, gmnav_grid_node(_grid, _col, DEMO5_WALL_S + 1),
                       gmnav_link.STAIR, true);
}

function demo5_deck_at(_grid, _col, _row) {
    if (!gmnav_grid_has_overlay(_grid)) return GMNAV_NO_NODE;
    return gmnav_overlay_node_at(_grid.overlay, _col, _row, 1);
}

function demo5_screen(_grid, _col, _row, _layer) {
    return [gmnav_layout_cell_x(_grid.layout, _col, _row),
            gmnav_layout_cell_y(_grid.layout, _col, _row) - _layer * DEMO5_LIFT];
}

function demo5_screen_node(_grid, _node) {
    return demo5_screen(_grid,
                        gmnav_grid_col(_grid, _node),
                        gmnav_grid_row(_grid, _node),
                        gmnav_grid_node_layer(_grid, _node));
}

function demo5_depth(_col, _row, _layer) {
    return (_col + _row) * 4 + _layer;
}

function demo5_diamond(_x, _y, _tw, _th, _col) {
    draw_set_color(_col);
    draw_primitive_begin(pr_trianglestrip);
    draw_vertex(_x, _y - _th * 0.5);
    draw_vertex(_x - _tw * 0.5, _y);
    draw_vertex(_x + _tw * 0.5, _y);
    draw_vertex(_x, _y + _th * 0.5);
    draw_primitive_end();

    draw_set_color(merge_color(_col, c_black, 0.35));
    draw_line(_x, _y - _th * 0.5, _x - _tw * 0.5, _y);
    draw_line(_x, _y - _th * 0.5, _x + _tw * 0.5, _y);
}

enum demo5_pick {
    TOPMOST,      // the surface a player can see, which is usually what a click means
    GROUND,       // layer 0 only, so a click passes under a bridge
    BRIDGES       // layer 1 only
}