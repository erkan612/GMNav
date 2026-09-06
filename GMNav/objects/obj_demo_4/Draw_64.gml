draw_set_alpha(0.78);
draw_set_color(c_black);
draw_rectangle(8, 8, 336, 200, false);
draw_set_alpha(1);

draw_set_color(c_white);
draw_text(20, 16,  "GMNav Demo 4 - elevation");
draw_text(20, 40,  "left click   walk there");
draw_text(20, 58,  "space        cycle climb and drop");
draw_text(20, 76,  "H / E        heights, blocked steps");
draw_text(20, 94,  "P / L        path, height numbers");

var _p = demo4_preset(preset);
draw_text(20, 118, "limits      " + _p.name);

draw_text(20, 142, "ground z 0, plateau z 2, mesa z 5");

if (failed) {
    draw_set_color(#E05A3C);
    draw_text(20, 166, "no route with these limits");
    draw_set_color(c_white);
} else if (gmnav_agent_has_path(agent)) {
    draw_text(20, 166, "route       "
            + string(gmnav_path_get_count(agent.path)) + " points, "
            + string_format(last_cost, 1, 1) + " px");
} else {
    draw_text(20, 166, "click somewhere");
}

draw_text(20, 184, "standing on z "
        + string(gmnav_grid_height(grid, gmnav_grid_world_to_node(grid, x, y))));

draw_set_alpha(1);