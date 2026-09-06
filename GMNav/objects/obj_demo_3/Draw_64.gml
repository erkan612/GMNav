draw_set_alpha(0.78);
draw_set_color(c_black);
draw_rectangle(8, 8, 340, 176, false);
draw_set_alpha(1);

draw_set_color(c_white);
draw_text(20, 16,  "GMNav Demo 3 - baked jump links");
draw_text(20, 40,  "left click   walk and jump there");
draw_text(20, 58,  "G / L        graph overlay, cycle link type");
draw_text(20, 76,  "P / J        route, real arc");
draw_text(20, 94,  "F / N        freeze, advance one frame");
draw_text(20, 112, "R / B        rebake, jump bias");
draw_text(20, 130, "space        grid");

var _names = ["", "walk", "fall", "", "jump"];
draw_text(20, 154, "overlay     " + (link_mask == 7 ? "all" : _names[link_mask]));

draw_set_alpha(0.78);
draw_set_color(c_black);
draw_rectangle(8, 188, 340, 340, false);
draw_set_alpha(1);

draw_set_color(c_white);
draw_text(20, 196, "surfaces    " + string(pg.count));
draw_text(20, 214, "links       " + string(array_length(pg.edge_to)));

var _state = gmnav_platagent_airborne(hero) ? "in air"
           : (gmnav_platagent_has_route(hero) ? "walking" : "standing");
draw_text(20, 232, "state       " + _state);

if (gmnav_platagent_has_route(hero)) {
    var _t  = ["walk", "fall", "jump"];
    var _a  = hero.path[hero.seek];
    var _b  = hero.path[hero.seek + 1];
    var _gw = grid.width;

    draw_text(20, 250, "taking      " + _t[hero.link.type]
                     + "  (" + string(pg.nodes[_a] % _gw)
                     + "," + string(pg.nodes[_a] div _gw) + ") -> ("
                     + string(pg.nodes[_b] % _gw)
                     + "," + string(pg.nodes[_b] div _gw) + ")");

    draw_text(20, 268, "launch      vy " + string_format(hero.link.vy, 1, 2)
                     + "  cost " + string_format(hero.link.cost, 1, 1)
                     + "  apex " + string(demo3_arc_apex(pg, _a, _b)) + "px");

    draw_text(20, 286, "remaining   "
            + string(array_length(hero.path) - 1 - hero.seek) + " links");
} else if (hero.failed) {
    draw_set_color(#E05A3C);
    draw_text(20, 250, "no route to that surface");
    draw_set_color(c_white);
}

if (hero.desync > 0) {
    draw_set_color(#E05A3C);
    draw_text(20, 304, "desyncs     " + string(hero.desync) + "  (expected 0)");
    draw_set_color(c_white);
}

draw_text(20, 322, "jump bias   " + string_format(move.jump_bias, 1, 2));

if (bake_ms > 0) draw_text(20, 340, "last bake   "
                                  + string_format(bake_ms, 1, 2) + " ms");

draw_set_alpha(1);