draw_set_alpha(0.78);
draw_set_color(c_black);
draw_rectangle(8, 8, 320, 150, false);

draw_set_alpha(1);
draw_set_color(c_white);
draw_text(20, 16, "GMNav Demo 2 - one budget, any crowd");
draw_text(20, 40, "left click   send everyone to that spot");
draw_text(20, 58, "S            scatter to random goals");
draw_text(20, 76, "A / D        add or remove 20 agents");
draw_text(20, 94, "Q / E        budget down or up");
draw_text(20, 112, "P            toggle paths");
draw_text(20, 130, "V / space    avoidance, grid");

gmnav_debug_draw_stats(sched, 20, 172);

draw_set_alpha(0.78);
draw_set_color(c_black);
draw_rectangle(8, 284, 320, 356, false);
draw_set_alpha(1);

draw_set_color(c_white);
draw_text(20, 292, "agents      " + string(array_length(agents)));
draw_text(20, 310, "avoidance   " + (use_avoid ? "on" : "off"));

if (draining) {
    draw_set_color(#4A9BE0);
    draw_text(20, 330, "draining    " + string(order_frames) + " frames");
} else if (last_drain >= 0) {
    draw_set_color(#75C060);
    draw_text(20, 330, "drained in  " + string(last_drain) + " frames");
}

draw_set_color(c_white);
draw_set_alpha(1);