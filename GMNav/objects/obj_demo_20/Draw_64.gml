draw_set_alpha(0.88);
draw_set_color(c_black);
draw_rectangle(8, 8, 460, 308, false);
draw_set_alpha(1);

draw_set_color(c_white);
draw_text(20, 16,  "GMNav Demo 20 - overlay lifecycle");
draw_text(20, 40,  "left click   set a new goal");
draw_text(20, 58,  "right click  remove / re-add a bridge cell");
draw_text(20, 76,  "A            restore every removed cell");
draw_text(20, 94,  "C            compact, drop tombstones");
draw_text(20, 112, "R            rebuild from scratch");
draw_text(20, 130, "space        grid overlay");

draw_set_color(#8A8A8A);
draw_text(20, 158, "bridge cells");

var _cols = demo20_bridge_cells();
var _ov   = grid.overlay;

for (var _i = 0; _i < array_length(_cols); _i++) {
    var _c = _cols[_i];
    var _n = gmnav_overlay_node_at(_ov, _c, DEMO20_BRIDGE_R, 1);

    var _y = 178 + _i * 20;

    draw_set_color(#8A8A8A);
    draw_text(20, _y, "(" + string(_c) + ", " + string(DEMO20_BRIDGE_R) + ")");

    if (_n == GMNAV_NO_NODE) {
        draw_set_color(#5A4A38);
        draw_text(110, _y, "gone (tombstoned or compacted)");
    } else {
        draw_set_color(c_white);
        draw_text(110, _y, "node " + string(_n)
                        + (gmnav_overlay_is_removed(_ov, _n) ? "  removed" : ""));
    }
}

draw_set_color(#8A8A8A);
draw_text(20, 268, "overlay slots");

draw_set_color(c_white);
draw_text(180, 268, string(gmnav_overlay_count(_ov)));

var _an = gmnav_grid_world_to_node(grid, agent.x, agent.y, agent.layer);

var _state = gmnav_agent_failed(agent)  ? "no route"
           : (gmnav_agent_arrived(agent) ? "arrived"
           : (gmnav_agent_has_path(agent) ? "walking"
           : "idle"));

draw_set_color(#8A8A8A);
draw_text(20, 288, "agent state");

draw_set_color(gmnav_agent_failed(agent)  ? #E05A3C
             : (gmnav_agent_arrived(agent) ? #75C060
             : c_white));
draw_text(180, 288, _state);

draw_set_color(c_white);
draw_set_alpha(1);