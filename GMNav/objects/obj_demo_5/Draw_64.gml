draw_set_alpha(0.78);
draw_set_color(c_black);
draw_rectangle(8, 8, 372, 132, false);
draw_set_alpha(1);

draw_set_color(c_white);
draw_text(20, 16, "GMNav Demo 5 - bridges over a road");
draw_text(20, 40, "left click   walk there");
draw_text(20, 58, "space        which layer a click means");
draw_text(20, 76, "P            path");

var _pn = ["topmost surface", "the road and grass", "the bridges only"];
draw_text(20, 100, "clicking on   " + _pn[pick_mode]);
draw_text(20, 118, "standing on   layer " + string(gmnav_agent_layer(agent))
                 + (failed ? "     no route" : ""));

draw_set_alpha(1);