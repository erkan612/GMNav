if (show_grid) gmnav_debug_draw_grid(grid, cfg);

var _count = array_length(agents);

if (show_paths) {
    for (var i = 0; i < _count; i++) {
        var _a = agents[i];
        if (gmnav_agent_has_path(_a)) gmnav_debug_draw_path_object(_a.path, cfg);
    }
}

for (var i = 0; i < _count; i++) {
    var _a = agents[i];

    draw_set_color(gmnav_agent_arrived(_a) ? #60C075 : #E05A3C);
    draw_circle(_a.x, _a.y, _a.radius, false);
}

draw_set_color(c_white);