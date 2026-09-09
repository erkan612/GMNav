draw_set_alpha(0.78);
draw_set_color(c_black);
draw_rectangle(8, 8, 460, 186, false);
draw_set_alpha(1);

draw_set_color(c_white);
draw_text(20, 16,  "GMNav Demo 10 - one bridge, two sizes");
draw_text(20, 40,  "left click   send both agents there");
draw_text(20, 58,  "space        toll the bridge");
draw_text(20, 76,  "B            collapse the middle span");
draw_text(20, 94,  "P / C        paths, clearance numbers");

draw_set_color(col_small);
draw_text(20, 122, "small   layer " + string(gmnav_agent_layer(small))
                 + (gmnav_agent_failed(small)  ? "   no route"
                 : (gmnav_agent_arrived(small) ? "   arrived" : "")));

draw_set_color(col_big);
draw_text(20, 140, "big     layer " + string(gmnav_agent_layer(big))
                 + (gmnav_agent_failed(big)  ? "   no route"
                 : (gmnav_agent_arrived(big) ? "   arrived" : "")));

draw_set_color(tolled ? #E08050 : c_white);
draw_text(20, 168, tolled ? "bridge tolled, both route around"
                          : "bridge free, the small one crosses it");