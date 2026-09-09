draw_set_alpha(0.78);
draw_set_color(c_black);
draw_rectangle(8, 8, 430, 190, false);
draw_set_alpha(1);

draw_set_color(c_white);
draw_text(20, 16,  "GMNav Demo 11 - what a unit is allowed to walk");
draw_text(20, 40,  "left click   send all three");
draw_text(20, 58,  "R            back to the start");
draw_text(20, 76,  "P / G        paths, grid");

draw_set_color(col_free);
draw_text(20, 104, "free      any angle          "
                 + string(demo11_waypoints(agent_free)) + " waypoints");

draw_set_color(col_oct);
draw_text(20, 122, "eight way  cardinals and 45  "
                 + string(demo11_waypoints(agent_oct)) + " waypoints");

draw_set_color(col_four);
draw_text(20, 140, "four way   cardinals only    "
                 + string(demo11_waypoints(agent_four)) + " waypoints");

draw_set_color(c_white);
draw_text(20, 168, "each has its own grid, since the model is the neighbour set");