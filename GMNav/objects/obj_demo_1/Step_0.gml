// input

if (mouse_check_button_pressed(mb_left)) {
    var _target = demo1_snap_to_open(grid, mouse_x, mouse_y);

    if (_target == undefined) {
        blocked_click = 45;                       // clicked a wall
    } else {
        gmnav_agent_goto(agent, _target.x, _target.y);
    }
}

if (keyboard_check_pressed(vk_space)) show_grid = !show_grid;

if (blocked_click > 0) blocked_click--;

// navigation

// the scheduler advances every in-flight search under its shared budget
gmnav_scheduler_update(sched);

// the agent picks up a finished path and works out where it wants to go
gmnav_agent_update(agent);

// and we do the moving. GMNav never touches x or y.
x += agent.vx;
y += agent.vy;

// keep the agent's own idea of its position in sync with ours
agent.x = x;
agent.y = y;