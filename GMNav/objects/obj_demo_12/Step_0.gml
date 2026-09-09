if (keyboard_check_pressed(ord("P"))) show_paths  = !show_paths;
if (keyboard_check_pressed(ord("O"))) show_points = !show_points;
if (keyboard_check_pressed(ord("R"))) demo12_reset(id);

if (keyboard_check_pressed(vk_up))    { radius = min(radius + 8, 120); demo12_retune(id); }
if (keyboard_check_pressed(vk_down))  { radius = max(radius - 8, 8);   demo12_retune(id); }
if (keyboard_check_pressed(vk_right)) { steps  = min(steps + 1, 12);   demo12_retune(id); }
if (keyboard_check_pressed(vk_left))  { steps  = max(steps - 1, 1);    demo12_retune(id); }

if (mouse_check_button_pressed(mb_left)) {
    var _n = gmnav_grid_world_to_node(grid, mouse_x, mouse_y);

    if (_n != GMNAV_NO_NODE && !gmnav_grid_is_blocked(grid, _n)) {
        goal_c = gmnav_grid_col(grid, _n);
        goal_r = gmnav_grid_row(grid, _n);
        demo12_send(id, goal_c, goal_r);
    }
}

gmnav_scheduler_update(sched);

gmnav_agent_update(agent_sharp);
agent_sharp.x += agent_sharp.vx;
agent_sharp.y += agent_sharp.vy;

gmnav_agent_update(agent_corner);
agent_corner.x += agent_corner.vx;
agent_corner.y += agent_corner.vy;

gmnav_agent_update(agent_spline);
agent_spline.x += agent_spline.vx;
agent_spline.y += agent_spline.vy;