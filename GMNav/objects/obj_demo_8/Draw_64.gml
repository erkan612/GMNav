draw_set_alpha(0.78);
draw_set_color(c_black);
draw_rectangle(8, 8, 430, 150, false);
draw_set_alpha(1);

draw_set_color(c_white);
draw_text(20, 16, "GMNav Demo 8 - a long, wide ramp");
draw_text(20, 40, "left click   walk there");
draw_text(20, 58, "space        which surface a click means");
draw_text(20, 76, "P            path");

var _pn = ["topmost surface", "the ground, even under a bridge", "raised surfaces only"];
draw_set_color(pick_mode == 0 ? c_white : #F0D060);
draw_text(20, 100, "clicking on   " + _pn[pick_mode]);

draw_set_color(c_white);
draw_text(20, 118, "standing on   layer " + string(gmnav_agent_layer(agent))
                 + (failed ? "     no route" : ""));
draw_text(20, 136, "raised cells are drawn over the row behind them");