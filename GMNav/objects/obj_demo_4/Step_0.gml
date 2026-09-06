if (mouse_check_button_pressed(mb_left)) {
    failed = !gmnav_agent_goto(agent, mouse_x, mouse_y);
}

// cycle the movement limits and re-ask for the same goal, so the route
// visibly changes without moving the agent
if (keyboard_check_pressed(vk_space)) {
    preset = (preset + 1) mod demo4_preset_count();

    var _p = demo4_preset(preset);
    agent.max_climb = _p.climb;
    agent.max_drop  = _p.drop;

    if (agent.has_goal) {
        failed = !gmnav_agent_goto(agent, agent.goal_x, agent.goal_y);
    }
}

if (keyboard_check_pressed(ord("H"))) show_heights = !show_heights;
if (keyboard_check_pressed(ord("E"))) show_steps   = !show_steps;
if (keyboard_check_pressed(ord("P"))) show_path    = !show_path;

if (keyboard_check_pressed(ord("L"))) {
    show_labels    = !show_labels;
    cfg.show_labels = show_labels;
}

gmnav_scheduler_update(sched);
gmnav_agent_update(agent);

// GMNav never moves anything, that is still your job on the grid side
agent.x += agent.vx;
agent.y += agent.vy;

if (gmnav_agent_has_path(agent)) last_cost = gmnav_path_get_length(agent.path);