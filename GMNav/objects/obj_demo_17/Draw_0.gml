draw_set_color(#1A1A22);
draw_rectangle(0, 0, room_width, room_height, false);

demo17_draw_level(grid);

// remaining path
if (show_path && gmnav_platagent_has_route(hero)) {
    draw_set_color(#4A9BE0);

    for (var i = hero.seek; i < array_length(hero.path) - 1; i++) {
        var _a = hero.path[i];
        var _b = hero.path[i + 1];

        draw_line_width(pg.node_x[_a], pg.node_y[_a],
                        pg.node_x[_b], pg.node_y[_b], 2);
    }

    for (var i = hero.seek; i < array_length(hero.path); i++) {
        var _a = hero.path[i];
        draw_circle(pg.node_x[_a], pg.node_y[_a], 3, false);
    }
}

if (show_graph) gmnav_debug_draw_platgraph(pg, cfg, 7);

// hero, feet up
var _hw  = move.width * 0.5;
var _col = hero.failed
             ? #E05A3C
             : (gmnav_platagent_airborne(hero)
                 ? #E0B84A
                 : (allow_drop ? #60C075 : #5FC8F0));

draw_set_color(_col);
draw_rectangle(hero.x - _hw, hero.y - move.height,
               hero.x + _hw, hero.y, false);

draw_set_color(c_black);
draw_rectangle(hero.x + hero.face * 2 - 2, hero.y - move.height + 8,
               hero.x + hero.face * 2 + 2, hero.y - move.height + 12, false);

draw_set_color(c_white);