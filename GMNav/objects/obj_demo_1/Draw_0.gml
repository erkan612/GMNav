if (show_grid) gmnav_debug_draw_grid(grid, cfg);

// path, target waypoint, velocity and goal marker
gmnav_debug_draw_agent(agent, cfg);

// the character itself
draw_set_color(c_white);
draw_circle(x, y, agent.radius, false);
draw_set_color(#3C3489);
draw_circle(x, y, agent.radius, true);
draw_set_color(c_white);