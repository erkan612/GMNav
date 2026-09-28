draw_set_alpha(0.88);
draw_set_color(c_black);
draw_rectangle(8, 8, 460, 520, false);
draw_set_alpha(1);

draw_set_color(c_white);
draw_text(20, 16,  "GMNav Demo 21 - custom heuristics and callbacks");
draw_text(20, 40,  "left click   set a new green goal");
draw_text(20, 58,  "N            toggle red between sealed and open");
draw_text(20, 76,  "H            run the heuristic probe");
draw_text(20, 94,  "T            fire a manual ticket request");
draw_text(20, 112, "R            rebuild");
draw_text(20, 130, "space        grid overlay");

// green panel
draw_set_color(col_green);
draw_text(20, 162, "green");

var _gs = gmnav_agent_failed(agent_green)  ? "no route"
        : (gmnav_agent_arrived(agent_green) ? "arrived"
        : (gmnav_agent_has_path(agent_green) ? "walking"
        : "idle"));

draw_set_color(c_white);
draw_text(100, 162, _gs);
draw_text(260, 162, "arrived " + string(agent_green.__arrived_count)
                  + "  failed " + string(agent_green.__failed_count));

// red panel
draw_set_color(col_red);
draw_text(20, 184, "red");

var _rs = gmnav_agent_failed(agent_red)  ? "no route"
        : (gmnav_agent_arrived(agent_red) ? "arrived"
        : (gmnav_agent_has_path(agent_red) ? "walking"
        : "idle"));

draw_set_color(c_white);
draw_text(100, 184, _rs);
draw_text(260, 184, "arrived " + string(agent_red.__arrived_count)
                  + "  failed " + string(agent_red.__failed_count));

// heuristic probe
draw_set_color(#8A8A8A);
draw_text(20, 218, "heuristic probe   same start, same goal, three heuristics");

if (probe_ready) {
    draw_set_color(c_white);
    draw_text(20, 240, "auto   octile  " + string(probe_auto) + "  expansions");
    draw_text(20, 258, "zero   dijkstra " + string(probe_zero) + "  expansions");
    draw_text(20, 276, "cheb   custom   " + string(probe_cheb) + "  expansions");
    draw_text(20, 294, "press H again to re-run");
} else {
    draw_set_color(#5A5A6A);
    draw_text(20, 240, "press H to run");
}

// ticket
draw_set_color(#8A8A8A);
draw_text(20, 326, "manual ticket");

if (last_ticket_state == -1) {
    draw_set_color(#5A5A6A);
    draw_text(180, 326, "press T to fire one");
} else {
    draw_set_color(c_white);
    draw_text(180, 326, "state " + string(last_ticket_state)
                       + "  callback " + string(last_ticket_fired) + "x");
}

// log
draw_set_color(#8A8A8A);
draw_text(20, 358, "event log");

for (var _i = 0; _i < array_length(log_lines); _i++) {
    draw_set_color(c_white);
    draw_text(20, 378 + _i * 20, log_lines[_i]);
}

draw_set_color(c_white);
draw_set_alpha(1);