if (keyboard_check_pressed(ord("C"))) show_cost = !show_cost;

if (keyboard_check_pressed(vk_space)) {
    show_danger = !show_danger;
    if (!show_danger) demo13_wipe(id);
    demo13_send_agent(id);
}

if (keyboard_check_pressed(vk_up))   look = min(look + 1, 14);
if (keyboard_check_pressed(vk_down)) look = max(look - 1, 1);

if (mouse_check_button_pressed(mb_left)) {
    var _n = gmnav_grid_world_to_node(grid, mouse_x, mouse_y);

    if (_n != GMNAV_NO_NODE && !gmnav_grid_is_blocked(grid, _n)) {
        goal_c = gmnav_grid_col(grid, _n);
        goal_r = gmnav_grid_row(grid, _n);
        demo13_send_agent(id);
    }
}

demo13_guard_step(id);

// the traveller re-asks periodically, since the danger moves under it and the grid itself never changes, so nothing marks its path stale
frames++;
if (show_danger && frames mod repath_gap_frames == 0) demo13_send_agent(id);

gmnav_scheduler_update(sched);

gmnav_agent_update(agent);
agent.x += agent.vx;
agent.y += agent.vy;

gmnav_agent_update(brute);
brute.x += brute.vx;
brute.y += brute.vy;

if (keyboard_check_pressed(ord("L"))) loop = !loop;

if (loop && gmnav_agent_arrived(agent)) {
    var _sp2 = gmnav_grid_node_to_world(grid, gmnav_grid_node(grid, 2, 10));
    agent.x = _sp2[0];
    agent.y = _sp2[1];
    demo13_send_agent(id);
}

// set_weight, not add. add appends, so repeated presses stack copies of the same layer and the weights sum instead of replacing
if (keyboard_check_pressed(ord("Q")) || keyboard_check_pressed(ord("E"))) {
    brute_w = clamp(brute_w + (keyboard_check_pressed(ord("E")) ? 0.1 : -0.1), 0, 3);

    gmnav_costprofile_set_weight(reckless, danger, brute_w);
    gmnav_costprofile_bake(reckless);
    demo13_send_agent(id);
}