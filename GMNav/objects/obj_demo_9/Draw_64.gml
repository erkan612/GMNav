draw_set_alpha(0.78);
draw_set_color(c_black);
draw_rectangle(8, 8, 430, 168, false);
draw_set_alpha(1);

draw_set_color(c_white);
draw_text(20, 16,  "GMNav Demo 9 - one field, two crossings");
draw_text(20, 40,  "left click   move the goal, one rebuild for everyone");
draw_text(20, 58,  "A / D        add or remove 20 units");
draw_text(20, 76,  "space        arrows");
draw_text(20, 94,  "G / P        grid, pause");

draw_text(20, 118, "units       " + string(array_length(units)));
draw_text(20, 136, "goal        " + string(goal_c) + ", " + string(goal_r));
draw_text(20, 154, "no searches run. every unit reads one cell and steps");