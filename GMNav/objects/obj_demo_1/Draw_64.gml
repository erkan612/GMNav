draw_set_alpha(0.75);
draw_set_color(c_black);
draw_rectangle(8, 8, 300, 74, false);

draw_set_alpha(1);
draw_set_color(c_white);
draw_text(20, 16, "GMNav Demo 1");
draw_text(20, 36, "left click   send the agent there");
draw_text(20, 54, "space        toggle the grid overlay");

gmnav_debug_draw_stats(sched, 20, 96);

if (blocked_click > 0) {
    draw_set_color(#4A6BE0);
    draw_text(20, 210, "that cell is a wall");
    draw_set_color(c_white);
}

if (gmnav_agent_arrived(agent)) {
    draw_set_color(#75C060);
    draw_text(20, 210, "arrived");
    draw_set_color(c_white);
}

draw_set_alpha(1);