if (keyboard_check_pressed(vk_space)) show_grid = !show_grid;

if (keyboard_check_pressed(ord("R"))) demo21_rebuild(id);

if (keyboard_check_pressed(ord("H"))) demo21_heuristic_probe(id);

if (keyboard_check_pressed(ord("T"))) demo21_fire_ticket(id);

if (keyboard_check_pressed(ord("N"))) demo21_send_red(id, !red_sealed);

if (mouse_check_button_pressed(mb_left)) {
    var _n = gmnav_grid_world_to_node_top(grid, mouse_x, mouse_y);

    if (_n != GMNAV_NO_NODE) {
        var _c = gmnav_grid_col(grid, _n);
        var _r = gmnav_grid_row(grid, _n);
        demo21_send_green(id, _c, _r);
    }
}

gmnav_scheduler_update(sched);

gmnav_agent_update(agent_green);
agent_green.x += agent_green.vx;
agent_green.y += agent_green.vy;

gmnav_agent_update(agent_red);
agent_red.x += agent_red.vx;
agent_red.y += agent_red.vy;

if (agent_green.__arrived_count > pgreen_a) {
    demo21_log(id, "green arrived  @ frame " + string(frames));
    pgreen_a = agent_green.__arrived_count;
}
if (agent_green.__failed_count > pgreen_f) {
    demo21_log(id, "green failed   @ frame " + string(frames));
    pgreen_f = agent_green.__failed_count;
}
if (agent_red.__arrived_count > pred_a) {
    demo21_log(id, "red arrived    @ frame " + string(frames));
    pred_a = agent_red.__arrived_count;
}
if (agent_red.__failed_count > pred_f) {
    demo21_log(id, "red failed     @ frame " + string(frames));
    pred_f = agent_red.__failed_count;
}

frames++;