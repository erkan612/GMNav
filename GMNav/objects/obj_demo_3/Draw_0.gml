if (show_grid) gmnav_debug_draw_grid(grid, cfg);

// one-way decks carry no BLOCKED flag, so the grid overlay skips them.
// Draw a bar along the top edge, which is the actual collision surface.
draw_set_color(#7A5AC0);
for (var _r = 0; _r < grid.height; _r++) {
    for (var _c = 0; _c < grid.width; _c++) {
        var _n = gmnav_grid_node(grid, _c, _r);
        if (_n == GMNAV_NO_NODE) continue;
        if (!gmnav_grid_has_flag(grid, _n, GMNAV_FLAG_ONEWAY)) continue;

        var _px = _c * tile;
        var _py = _r * tile;
        draw_rectangle(_px, _py, _px + tile - 1, _py + 4, false);
    }
}
draw_set_color(c_white);

if (show_graph) gmnav_debug_draw_platgraph(pg, cfg, link_mask);

// the remaining route, node to node
if (show_path && gmnav_platagent_has_route(hero)) {
    draw_set_color(#4A9BE0);

    for (var i = hero.seek; i < array_length(hero.path) - 1; i++) {
        var _a = hero.path[i];
        var _b = hero.path[i + 1];
        draw_line_width(pg.node_x[_a], pg.node_y[_a],
                        pg.node_x[_b], pg.node_y[_b], 2);
    }

    var _g = hero.path[array_length(hero.path) - 1];
    draw_circle(pg.node_x[_g], pg.node_y[_g], 6, true);
}

// the real arc of the link being flown, replayed from its stored launch
if (show_arc && gmnav_platagent_has_route(hero)) {
    var _pts = demo3_arc_points(pg, hero.path[hero.seek],
                                    hero.path[hero.seek + 1]);

    draw_set_color(#E0B84A);
    for (var i = 1; i < array_length(_pts); i++) {
        draw_line(_pts[i - 1][0], _pts[i - 1][1], _pts[i][0], _pts[i][1]);
    }
}

// character, drawn from the feet up
var _hw = move.width * 0.5;
draw_set_color(hero.failed                  ? #E05A3C
             : (gmnav_platagent_airborne(hero) ? #E0B84A
             :                                #60C075));
draw_rectangle(hero.x - _hw, hero.y - move.height, hero.x + _hw, hero.y, false);

draw_set_color(c_black);
draw_rectangle(hero.x + hero.face * 2 - 2, hero.y - move.height + 8,
               hero.x + hero.face * 2 + 2, hero.y - move.height + 12, false);

draw_set_color(c_white);