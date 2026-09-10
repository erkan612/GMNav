draw_set_alpha(0.78);
draw_set_color(c_black);
draw_rectangle(8, 8, 440, 172, false);
draw_set_alpha(1);

draw_set_color(c_white);
draw_text(20, 16, "GMNav Demo 14 - the debug renderer");
draw_text(20, 40, "1 to 7       view");
draw_text(20, 58, "R            restart the frontier search");
draw_text(20, 76, "C            culling " + (cfg.cull ? "on" : "off"));
draw_text(20, 94, "left click   send the agent");

draw_text(20, 122, "showing   " + demo14_view_name(view_mode));
draw_text(20, 146, "every view covers the deck as well as the ground");

gmnav_debug_draw_stats(sched, 20, 190);