// layout selection, 1 through 5
var _picked = -1;

if (keyboard_check_pressed(ord("1"))) _picked = 0;
if (keyboard_check_pressed(ord("2"))) _picked = 1;
if (keyboard_check_pressed(ord("3"))) _picked = 2;
if (keyboard_check_pressed(ord("4"))) _picked = 3;
if (keyboard_check_pressed(ord("5"))) _picked = 4;

if (_picked >= 0 && _picked != layout_idx) {
    layout_idx = _picked;
    demo19_rebuild(id);
}

// view cycle
if (keyboard_check_pressed(ord("V"))) {
    view_mode = (view_mode + 1) mod DEMO19_VIEW_COUNT;
}

if (keyboard_check_pressed(vk_space)) show_grid = !show_grid;

if (keyboard_check_pressed(ord("F"))) {
    avoid_pinch = !avoid_pinch;

    agent_small.avoid_pinch  = avoid_pinch;
    agent_medium.avoid_pinch = avoid_pinch;
    agent_big.avoid_pinch    = avoid_pinch;

    field_2 = gmnav_flowfield_create(grid, undefined, undefined, undefined, 2, avoid_pinch);
    field_0 = gmnav_flowfield_create(grid, undefined, undefined, undefined, 0, avoid_pinch);

    demo19_rebuild_fields(id);
    demo19_send(id);
}

if (keyboard_check_pressed(ord("R"))) demo19_rebuild(id);

if (keyboard_check_pressed(ord("K"))) {
    agent_medium.need_clear = (agent_medium.need_clear + 1) mod 4;
    gmnav_agent_goto(agent_medium, goal_x, goal_y);
}

if (mouse_check_button_pressed(mb_left)) {
    var _n = gmnav_grid_world_to_node_top(grid, mouse_x, mouse_y);

    if (_n != GMNAV_NO_NODE) {
        var _p = gmnav_grid_node_to_world(grid, _n);
        demo19_set_goal(id, _p[0], _p[1]);
    }
}

if (mouse_check_button_pressed(mb_right)) {
    var _bn = gmnav_grid_world_to_node_top(grid, mouse_x, mouse_y);

    if (_bn != GMNAV_NO_NODE) demo19_toggle_blocked(id, _bn);
}

// navigation
gmnav_scheduler_update(sched);

gmnav_agent_update(agent_small);
agent_small.x += agent_small.vx;
agent_small.y += agent_small.vy;

gmnav_agent_update(agent_medium);
agent_medium.x += agent_medium.vx;
agent_medium.y += agent_medium.vy;

gmnav_agent_update(agent_big);
agent_big.x += agent_big.vx;
agent_big.y += agent_big.vy;

if (gmnav_agent_has_path(agent_small))  last_path_small  = agent_small.path;
if (gmnav_agent_has_path(agent_medium)) last_path_medium = agent_medium.path;
if (gmnav_agent_has_path(agent_big))    last_path_big    = agent_big.path;