draw_set_alpha(0.78);
draw_set_color(c_black);
draw_rectangle(8, 8, 470, 208, false);
draw_set_alpha(1);

draw_set_color(c_white);
draw_text(20, 16,  "GMNav Demo 13 - danger along a route, not around a point");
draw_text(20, 40,  "left click   move the goal");
draw_text(20, 58,  "space        danger " + (show_danger ? "on" : "off"));
draw_text(20, 76,  "up / down    look ahead " + string(look) + " cells");
draw_text(20, 94,  "C            cost overlay");

draw_set_color(col_guard);
draw_text(20, 122, "guard walks the lane and stamps where it is about to be");
draw_set_color(col_brute);
draw_text(20, 140, "brute weighs the danger at " + string_format(brute_w, 1, 2)
                 + "   Q / E to change");

draw_set_color(c_white);
draw_text(20, 164, "cells rebaked this frame   " + string(baked_cells)
                 + "   of " + string(grid.count));
draw_text(20, 188, "a full rebake would be every one of them");