if (keyboard_check_pressed(vk_space)) pick_layer = 1 - pick_layer;
if (keyboard_check_pressed(ord("P"))) show_path  = !show_path;

if (keyboard_check_pressed(vk_space)) {
    pick_mode = (pick_mode + 1) mod 3;
}

if (mouse_check_button_pressed(mb_left)) {
    var _n;

    switch (pick_mode) {
        case demo5_pick.TOPMOST: _n = gmnav_grid_world_to_node_top(grid, mouse_x, mouse_y); break;
        case demo5_pick.GROUND:  _n = gmnav_grid_world_to_node(grid, mouse_x, mouse_y, 0);  break;
        default:                 _n = gmnav_grid_world_to_node(grid, mouse_x, mouse_y, 1);  break;
    }

    if (_n == GMNAV_NO_NODE) {
        failed = true;
    } else {
        var _wp = gmnav_grid_node_to_world(grid, _n);
        failed  = !gmnav_agent_goto(agent, _wp[0], _wp[1], gmnav_priority.NORMAL,
                                   gmnav_grid_node_layer(grid, _n));
    }
}

gmnav_scheduler_update(sched);
gmnav_agent_update(agent);

agent.x += agent.vx;
agent.y += agent.vy;