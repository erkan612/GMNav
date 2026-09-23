draw_set_alpha(0.85);
draw_set_color(c_black);
draw_rectangle(8, 8, 400, 180, false);
draw_set_alpha(1);

draw_set_color(c_white);
draw_text(20, 16,  "GMNav Demo 17 - one way platforms");
draw_text(20, 40,  "left click   send the hero there");
draw_text(20, 58,  "D            toggle drop");
draw_text(20, 76,  "R            reset to spawn");
draw_text(20, 94,  "P / G        path, graph");

draw_set_color(allow_drop ? #60C075 : #5FC8F0);
draw_text(20, 122, "drop mode    " + (allow_drop ? "ON" : "OFF"));

var _state = hero.failed
             ? "failed"
             : (gmnav_platagent_airborne(hero)
                 ? "in air"
                 : (gmnav_platagent_has_route(hero)
                     ? "walking"
                     : (gmnav_platagent_arrived(hero) ? "arrived" : "idle")));

draw_set_color(c_white);
draw_text(20, 150, "state        " + _state);

if (failed || hero.failed) {
    draw_set_color(#E05A3C);
    draw_text(20, 172, "no route to that spot");
}

// hint
draw_set_alpha(0.75);
draw_set_color(c_black);
draw_rectangle(8, 200, 400, 312, false);
draw_set_alpha(1);

draw_set_color(#A0D0FF);
draw_text(20, 208, "things to try:");
draw_set_color(c_white);
draw_text(20, 232, "1. click the floor below, with");
draw_text(20, 250, "   D off then on");
draw_text(20, 274, "2. click the upper right platform,");
draw_text(20, 292, "   the hero takes the middle route");

draw_set_color(c_white);
draw_set_alpha(1);