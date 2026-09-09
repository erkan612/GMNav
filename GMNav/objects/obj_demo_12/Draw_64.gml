draw_set_alpha(0.78);
draw_set_color(c_black);
draw_rectangle(8, 8, 440, 206, false);
draw_set_alpha(1);

draw_set_color(c_white);
draw_text(20, 16,  "GMNav Demo 12 - turning corners");
draw_text(20, 40,  "left click   send all three");
draw_text(20, 58,  "up / down    radius " + string(radius));
draw_text(20, 76,  "left / right steps  " + string(steps));
draw_text(20, 94,  "R / P / O    reset, paths, points");

draw_set_color(col_sharp);
draw_text(20, 122, "none      " + string(demo12_points(agent_sharp))  + " points");

draw_set_color(col_corner);
draw_text(20, 140, "corner    " + string(demo12_points(agent_corner)) + " points");

draw_set_color(col_spline);
draw_text(20, 158, "spline    " + string(demo12_points(agent_spline)) + " points");

draw_set_color(c_white);
draw_text(20, 186, "a curve that would clip keeps its sharp corner");