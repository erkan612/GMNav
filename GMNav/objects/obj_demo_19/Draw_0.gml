draw_set_color(#1A1A22);
draw_rectangle(0, 0, room_width, room_height, false);

if (view_mode == 0) {
    if (show_grid) gmnav_debug_draw_grid(grid, cfg);

    if (last_path_big    != undefined) demo19_draw_path_from(last_path_big,    col_big);
    if (last_path_medium != undefined) demo19_draw_path_from(last_path_medium, col_medium);
    if (last_path_small  != undefined) demo19_draw_path_from(last_path_small,  col_small);

    draw_set_color(col_small);
    draw_circle(agent_small.x, agent_small.y, agent_small.radius, false);

    draw_set_color(col_medium);
    draw_circle(agent_medium.x, agent_medium.y, agent_medium.radius, false);

    draw_set_color(col_big);
    draw_circle(agent_big.x, agent_big.y, agent_big.radius, false);

    var _gn = gmnav_grid_world_to_node_top(grid, goal_x, goal_y);

    if (_gn != GMNAV_NO_NODE) {
        var _gp = gmnav_grid_node_to_world(grid, _gn);
        draw_set_color(col_goal);
        draw_circle(_gp[0], _gp[1], 6, false);
        draw_set_color(#2E4A6A);
        draw_circle(_gp[0], _gp[1], 6, true);
    }
}

if (view_mode == 1) {
    gmnav_debug_draw_clearance(grid, cfg);
    gmnav_debug_draw_grid(grid, cfg);
}

if (view_mode == 2) {
    gmnav_debug_draw_flowfield(field_2, cfg);
    gmnav_debug_draw_grid(grid, cfg);
}

if (view_mode == 3) {
    gmnav_debug_draw_flowfield(field_0, cfg);
    gmnav_debug_draw_grid(grid, cfg);
}

draw_set_color(c_white);
draw_set_alpha(1);