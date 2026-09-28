draw_set_alpha(0.88);
draw_set_color(c_black);
draw_rectangle(8, 8, 480, 396, false);
draw_set_alpha(1);

draw_set_color(c_white);
draw_text(20, 16,  "GMNav Demo 19 - layout completeness");
draw_text(20, 40,  "1 to 5       layout");
draw_text(20, 58,  "V            view");
draw_text(20, 76,  "space        grid overlay");
draw_text(20, 94,  "F            toggle staggered pinch refusal");
draw_text(20, 112, "R            rebuild from scratch");
draw_text(20, 130, "K            cycle the medium's need_clear");
draw_text(20, 148, "left click   set a new goal");
draw_text(20, 166, "right click  block / unblock a cell");

draw_set_color(#8A8A8A);
draw_text(20, 194, "layout");

draw_set_color(#F0D060);
draw_text(140, 194, demo19_layout_name(layout_idx));

draw_set_color(#8A8A8A);
draw_text(20, 216, "view");

draw_set_color(#F0D060);
draw_text(140, 216, demo19_view_name(view_mode));

draw_set_color(#8A8A8A);
draw_text(20, 238, "pinch");

var _pinch_note = "";
if (layout_idx != 2) {
    _pinch_note = "  (staggered only, no effect here)";
} else if (avoid_pinch) {
    _pinch_note = "  (visual seals refused)";
} else {
    _pinch_note = "  (visual seals enterable)";
}

draw_set_color(avoid_pinch ? #75C060 : #8A8A8A);
draw_text(140, 238, (avoid_pinch ? "on" : "off") + _pinch_note);

draw_set_color(c_white);
draw_text(20, 268, "three agents, same start, same goal, different sizes");
draw_text(20, 286, "need_clear is derived from radius, not hardcoded");

var _names = ["small ", "medium", "big   "];
var _needs = [agent_small.need_clear, agent_medium.need_clear, agent_big.need_clear];
var _radii = [agent_small.radius, agent_medium.radius, agent_big.radius];
var _cols  = [col_small, col_medium, col_big];
var _ags   = [agent_small, agent_medium, agent_big];

for (var i = 0; i < 3; i++) {
    var _y = 314 + i * 20;
    var _a = _ags[i];

    draw_set_color(_cols[i]);
    draw_text(20, _y, _names[i]);

    draw_set_color(c_white);
    draw_text(100, _y, "r " + string(_radii[i])
                    + "  need_clear " + string(_needs[i]));

    var _an = gmnav_grid_world_to_node(grid, _a.x, _a.y, _a.layer);
    var _ac = (_an == GMNAV_NO_NODE) ? 0 : gmnav_clearance_at(grid, _an);

    draw_set_color((_ac >= _needs[i]) ? #8A8A8A : #E0B84A);
    draw_text(290, _y, "at " + string(_ac));

    var _state = gmnav_agent_failed(_a)  ? "no route"
               : (gmnav_agent_arrived(_a) ? "arrived"
               : (gmnav_agent_has_path(_a) ? "walking"
               : "idle"));

    draw_set_color(gmnav_agent_failed(_a)  ? #E05A3C
                 : (gmnav_agent_arrived(_a) ? #75C060
                 : c_white));
    draw_text(360, _y, _state);
}

draw_set_color(#8A8A8A);
draw_text(20, 376, "on staggered, same column cells two rows apart are direct");

draw_set_color(c_white);
draw_set_alpha(1);