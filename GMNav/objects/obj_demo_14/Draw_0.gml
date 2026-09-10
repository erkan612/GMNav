// no game rendering anywhere in this demo. everything on screen is the debug module drawing what the navigation actually holds
switch (view_mode) {
    case 0: gmnav_debug_draw_grid(grid, cfg);            break;
    case 1: gmnav_debug_draw_clearance(grid, cfg);       break;
    case 2: gmnav_debug_draw_costs(grid, profile, cfg);  break;
    case 3: gmnav_debug_draw_flowfield(field, cfg);      break;
    case 4: gmnav_debug_draw_reach(grid, cfg);           break;
    case 5: gmnav_debug_draw_reach(grid, cfg, 2);        break;

    case 6:
        gmnav_debug_draw_grid(grid, cfg);
        gmnav_debug_draw_search(probe, cfg);
        break;
}

gmnav_debug_draw_agent(agent, cfg);