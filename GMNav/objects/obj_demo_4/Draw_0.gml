if (show_heights) gmnav_debug_draw_heights(grid, cfg);

gmnav_debug_draw_grid(grid, cfg);

// the barrier view: every boundary the current limits refuse to cross
if (show_steps) {
    gmnav_debug_draw_steps(grid, agent.max_climb, agent.max_drop, cfg);
}

if (show_path) gmnav_debug_draw_path(grid, agent.path, cfg);

gmnav_debug_draw_agent(agent, cfg);