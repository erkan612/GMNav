if (keyboard_check_pressed(ord("P"))) show_paths = !show_paths;
if (keyboard_check_pressed(ord("G"))) show_grid  = !show_grid;
if (keyboard_check_pressed(ord("R"))) demo11_reset(id);

if (mouse_check_button_pressed(mb_left)) {
    var _n = gmnav_grid_world_to_node(grid_free, mouse_x, mouse_y);

    if (_n != GMNAV_NO_NODE && !gmnav_grid_is_blocked(grid_free, _n)) {
        goal_c = gmnav_grid_col(grid_free, _n);
        goal_r = gmnav_grid_row(grid_free, _n);
        demo11_send(id, goal_c, goal_r);
    }
}

gmnav_scheduler_update(sched_free);
gmnav_scheduler_update(sched_four);
gmnav_scheduler_update(sched_oct);

gmnav_agent_update(agent_free);
agent_free.x += agent_free.vx;
agent_free.y += agent_free.vy;

gmnav_agent_update(agent_four);
agent_four.x += agent_four.vx;
agent_four.y += agent_four.vy;

gmnav_agent_update(agent_oct);
agent_oct.x += agent_oct.vx;
agent_oct.y += agent_oct.vy;