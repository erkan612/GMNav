var _count = array_length(agents);

// input

// send everyone to the same place, all on the same frame
if (mouse_check_button_pressed(mb_left)) {
    var _n = gmnav_grid_world_to_node(grid, mouse_x, mouse_y);

    if (_n != GMNAV_NO_NODE && !gmnav_grid_is_blocked(grid, _n)) {
        var _p = gmnav_grid_node_to_world(grid, _n);

        // Spread the crowd over a disc instead of stacking it on one cell.
        // Twenty bodies of radius 9 do not fit in a 32px cell, so the ones
        // that cannot fit never register arrival and shove forever.
        for (var i = 0; i < _count; i++) {
            var _ang = i * 137.5; // golden angle
            var _rad = 14 * sqrt(i);

            var _tx = _p[0] + lengthdir_x(_rad, _ang);
            var _ty = _p[1] + lengthdir_y(_rad, _ang);

            var _n2 = gmnav_grid_world_to_node(grid, _tx, _ty);
            if (_n2 == GMNAV_NO_NODE || gmnav_grid_is_blocked(grid, _n2)) {
                _tx = _p[0];
                _ty = _p[1];
            }

            gmnav_agent_goto(agents[i], _tx, _ty);
        }

        order_frames = 0;
        draining     = true;
    }
}

// scatter, everyone gets their own destination
if (keyboard_check_pressed(ord("S"))) {
    for (var i = 0; i < _count; i++) {
        var _p = demo2_random_open(grid);
        if (_p != undefined) gmnav_agent_goto(agents[i], _p.x, _p.y);
    }
    order_frames = 0;
    draining     = true;
}

if (keyboard_check_pressed(ord("A"))) {
    repeat (20) {
        var _p = demo2_random_open(grid);
        if (_p == undefined) continue;

        var _a = gmnav_agent_create(sched, _p.x, _p.y, 9, random_range(1.8, 3.0));
        array_push(agents, _a);
    }
}

if (keyboard_check_pressed(ord("D"))) {
    repeat (20) {
        if (array_length(agents) == 0) break;
        var _a = array_pop(agents);
        gmnav_agent_stop(_a); // release any workspace it was holding
    }
}

if (keyboard_check_pressed(vk_add)      || keyboard_check_pressed(ord("E"))) budget = min(budget + 500, 20000);
if (keyboard_check_pressed(vk_subtract) || keyboard_check_pressed(ord("Q"))) budget = max(budget - 500, 100);
sched.budget = budget;

if (keyboard_check_pressed(vk_space)) show_grid  = !show_grid;
if (keyboard_check_pressed(ord("P"))) show_paths = !show_paths;
if (keyboard_check_pressed(ord("V"))) use_avoid  = !use_avoid;

// navigation

gmnav_scheduler_update(sched);

_count = array_length(agents);

var _buckets = use_avoid
             ? demo2_bucket_build(agents, avoid_cell, avoid_cols, avoid_rows)
             : undefined;

var _waiting = false;

for (var i = 0; i < _count; i++) {
    var _a = agents[i];

    var _near = undefined;
    if (use_avoid) _near = demo2_bucket_gather(_buckets, near_buf, _a, avoid_cell, avoid_cols, avoid_rows);

    gmnav_agent_update(_a, _near);

    demo2_clamp_velocity(grid, _a);          // do not steer into walls
    var _hit = demo2_move_agent(grid, _a);   // move, collide, resolve overlap

    // shoved off its route and jammed against geometry, so ask again
    // from where it actually is
    if (_hit && _a.has_goal && _a.ticket == undefined) {
        _a.stuck = (_a[$ "stuck"] ?? 0) + 1;

        if (_a.stuck > 30) {
            gmnav_agent_goto(_a, _a.goal_x, _a.goal_y, gmnav_priority.HIGH);
            _a.stuck = 0;
        }
    } else {
        _a.stuck = 0;
    }

    if (_a.ticket != undefined) _waiting = true;
}

// how long did that order take to drain

if (draining) {
    order_frames++;

    if (!_waiting && gmnav_scheduler_pending(sched) == 0) {
        last_drain = order_frames;
        draining   = false;
    }
}