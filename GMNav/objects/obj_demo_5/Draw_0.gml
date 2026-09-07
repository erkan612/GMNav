var _w = grid.width;
var _h = grid.height;
var _t = layout.tile_w;
var _u = layout.tile_h;

// collect everything drawable, then sort back to front ( abit glitchy but does its job fine as a demonstration)
var _items = [];

for (var _r = 0; _r < _h; _r++) {
    for (var _c = 0; _c < _w; _c++) {
        var _n = gmnav_grid_node(grid, _c, _r);
        if (gmnav_grid_is_blocked(grid, _n)) {
            array_push(_items, [demo5_depth(_c, _r, 0), 1, _c, _r, 0]);   // wall
        } else {
            array_push(_items, [demo5_depth(_c, _r, 0), 0, _c, _r, 0]);   // floor
        }

        var _d = demo5_deck_at(grid, _c, _r);
        if (_d != GMNAV_NO_NODE) {
            array_push(_items, [demo5_depth(_c, _r, 1), 2, _c, _r, 1]);   // deck
        }
    }
}

var _al = gmnav_agent_layer(agent);
var _an = gmnav_grid_world_to_node(grid, agent.x, agent.y, _al);
var _ac = gmnav_grid_col(grid, _an);
var _ar = gmnav_grid_row(grid, _an);
array_push(_items, [demo5_depth(_ac, _ar, _al) + 2, 3, _ac, _ar, _al]);

array_sort(_items, function(_a, _b) { return sign(_a[0] - _b[0]); });

// draw in order
for (var i = 0; i < array_length(_items); i++) {
    var _it = _items[i];
    var _c  = _it[2];
    var _r  = _it[3];
    var _l  = _it[4];

    var _p  = demo5_screen(grid, _c, _r, _l);
    var _px = _p[0];
    var _py = _p[1];

    switch (_it[1]) {
        case 0:
            demo5_diamond(_px, _py, _t, _u,
                          (_r == DEMO5_ROAD_R) ? col_road
                        : ((_r < DEMO5_WALL_N) ? col_grass : col_ground));
            break;

        case 1:
            demo5_diamond(_px, _py, _t, _u, col_wall);
            break;

        case 2:
            // supports first, so the deck reads as standing above the road
            draw_set_color(col_post);
            draw_line_width(_px - _t * 0.25, _py + _u * 0.5,
                            _px - _t * 0.25, _py + DEMO5_LIFT + _u * 0.5, 3);
            draw_line_width(_px + _t * 0.25, _py + _u * 0.5,
                            _px + _t * 0.25, _py + DEMO5_LIFT + _u * 0.5, 3);

            demo5_diamond(_px, _py, _t, _u, col_deck);
            demo5_diamond(_px, _py - 3, _t, _u, col_deck_hi);
            break;

        case 3:
            draw_set_alpha(0.3);
            draw_set_color(c_black);
            draw_ellipse(agent.x - 8, agent.y - 3, agent.x + 8, agent.y + 3, false);
            draw_set_alpha(1);

            draw_set_color(#F0D060);
            draw_circle(agent.x, agent.y - 8, agent.radius, false);
            draw_set_color(c_black);
            draw_circle(agent.x, agent.y - 8, agent.radius, true);
            break;
    }
}

if (show_path && gmnav_agent_has_path(agent)) {
    draw_set_color(#4A9BE0);
    for (var i = 1; i < agent.path.count; i++) {
        draw_line_width(agent.path.px[i - 1], agent.path.py[i - 1],
                        agent.path.px[i],     agent.path.py[i], 2);
    }
}

draw_set_color(c_white);