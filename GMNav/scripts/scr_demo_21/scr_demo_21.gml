#macro DEMO21_W        26
#macro DEMO21_H        18
#macro DEMO21_TILE     32

#macro DEMO21_ORIGIN_X 480
#macro DEMO21_ORIGIN_Y  60

function demo21_build_level(_g) {
    gmnav_grid_fill_blocked(_g, 0, 0, DEMO21_W - 1, 0, true);
    gmnav_grid_fill_blocked(_g, 0, DEMO21_H - 1, DEMO21_W - 1, DEMO21_H - 1, true);
    gmnav_grid_fill_blocked(_g, 0, 0, 0, DEMO21_H - 1, true);
    gmnav_grid_fill_blocked(_g, DEMO21_W - 1, 0, DEMO21_W - 1, DEMO21_H - 1, true);

    gmnav_grid_fill_blocked(_g, 13, 1, 13, DEMO21_H - 2, true);
    gmnav_grid_fill_blocked(_g, 13, 8, 13, 9, false);

    gmnav_grid_fill_blocked(_g, 21, 13, 23, 15, true);
    gmnav_grid_set_blocked(_g, 22, 14, false);
}

function demo21_make_grid() {
    var _lay = gmnav_layout_create(gmnav_layout.ORTHO, DEMO21_TILE, DEMO21_TILE,
                                   gmnav_neighbours.EIGHT, gmnav_costmode.LOGICAL,
                                   DEMO21_ORIGIN_X, DEMO21_ORIGIN_Y);

    var _g = gmnav_grid_create(DEMO21_W, DEMO21_H, _lay);
    demo21_build_level(_g);
    return _g;
}

function demo21_world_of(_g, _c, _r) {
    return gmnav_grid_node_to_world(_g, gmnav_grid_node(_g, _c, _r));
}

function demo21_log(_obj, _msg) {
    array_push(_obj.log_lines, _msg);

    while (array_length(_obj.log_lines) > 6) {
        array_delete(_obj.log_lines, 0, 1);
    }
}

function demo21_rebuild(_obj) {
    _obj.grid   = demo21_make_grid();
    _obj.layout = _obj.grid.layout;
    _obj.sched  = gmnav_scheduler_create(_obj.grid, 3000, 4);

    var _green_s = demo21_world_of(_obj.grid, 3, 6);
    var _green_g = demo21_world_of(_obj.grid, 21, 6);
    var _red_s   = demo21_world_of(_obj.grid, 3, 12);
    var _red_g   = demo21_world_of(_obj.grid, 22, 14);

    _obj.agent_green = gmnav_agent_create(_obj.sched, _green_s[0], _green_s[1], 8, 2.2);
    _obj.agent_red   = gmnav_agent_create(_obj.sched, _red_s[0],   _red_s[1],   8, 2.2);

    _obj.agent_green.__arrived_count = 0;
    _obj.agent_green.__failed_count  = 0;
    _obj.agent_green.on_arrived = function(_ag) { _ag.__arrived_count += 1; };
    _obj.agent_green.on_failed  = function(_ag) { _ag.__failed_count  += 1; };

    _obj.agent_red.__arrived_count = 0;
    _obj.agent_red.__failed_count  = 0;
    _obj.agent_red.on_arrived = function(_ag) { _ag.__arrived_count += 1; };
    _obj.agent_red.on_failed  = function(_ag) { _ag.__failed_count  += 1; };

    _obj.green_goal_c = 21;
    _obj.green_goal_r = 6;
    _obj.red_sealed   = true;

    gmnav_agent_goto(_obj.agent_green, _green_g[0], _green_g[1]);
    gmnav_agent_goto(_obj.agent_red,   _red_g[0],   _red_g[1]);

    _obj.pgreen_a = 0;
    _obj.pgreen_f = 0;
    _obj.pred_a   = 0;
    _obj.pred_f   = 0;

    _obj.frames = 0;

    _obj.probe_auto  = -1;
    _obj.probe_zero  = -1;
    _obj.probe_cheb  = -1;
    _obj.probe_ready = false;

    _obj.last_ticket_state = -1;
    _obj.last_ticket_fired = 0;
}

function demo21_send_green(_obj, _c, _r) {
    _obj.green_goal_c = _c;
    _obj.green_goal_r = _r;

    var _p = demo21_world_of(_obj.grid, _c, _r);
    gmnav_agent_goto(_obj.agent_green, _p[0], _p[1]);
}

function demo21_send_red(_obj, _sealed) {
    _obj.red_sealed = _sealed;

    var _p = _sealed ? demo21_world_of(_obj.grid, 22, 14)
                     : demo21_world_of(_obj.grid, 21, 12);

    gmnav_agent_goto(_obj.agent_red, _p[0], _p[1]);
}

function demo21_heuristic_probe(_obj) {
    var _from = gmnav_grid_node(_obj.grid, 3, 6);
    var _to   = gmnav_grid_node(_obj.grid, 21, 6);

    var _s1 = gmnav_search_create(_obj.grid, gmnav_heuristic.AUTO);
    gmnav_search_begin(_s1, _from, _to);
    var _g1 = 0;
    while (_s1.state == gmnav_state.WORKING && _g1++ < 4000) {
        gmnav_search_step(_s1, 2000);
    }

    var _s2 = gmnav_search_create(_obj.grid, gmnav_heuristic.ZERO);
    gmnav_search_begin(_s2, _from, _to);
    var _g2 = 0;
    while (_s2.state == gmnav_state.WORKING && _g2++ < 4000) {
        gmnav_search_step(_s2, 2000);
    }

    var _cheb = function(_c, _r, _gc, _gr, _grid) {
        return max(abs(_c - _gc), abs(_r - _gr));
    };

    var _s3 = gmnav_search_create(_obj.grid, _cheb);
    gmnav_search_begin(_s3, _from, _to);
    var _g3 = 0;
    while (_s3.state == gmnav_state.WORKING && _g3++ < 4000) {
        gmnav_search_step(_s3, 2000);
    }

    _obj.probe_auto = _s1.expansions;
    _obj.probe_zero = _s2.expansions;
    _obj.probe_cheb = _s3.expansions;
    _obj.probe_ready = true;

    demo21_log(_obj, "probe  auto " + string(_s1.expansions)
                    + "   zero " + string(_s2.expansions)
                    + "   cheb " + string(_s3.expansions));
}

function demo21_fire_ticket(_obj) {
    var _from = gmnav_grid_node(_obj.grid, 3, 6);
    var _to   = gmnav_grid_node(_obj.grid, 21, 6);

    var _tk = gmnav_scheduler_request(_obj.sched, _from, _to,
                                      gmnav_priority.IMMEDIATE,
                                      false, undefined, 0,
                                      undefined, undefined, false,
                                      false,
                                      function(_t) {
                                          if (!variable_struct_exists(_t, "__fired")) _t.__fired = 0;
                                          _t.__fired += 1;
                                      });

    _obj.last_ticket_state = _tk.state;
    _obj.last_ticket_fired = _tk.__fired;

    demo21_log(_obj, "ticket  state " + string(_tk.state)
                    + "   callback " + string(_tk.__fired) + "x");
}

function demo21_draw_path(_agent, _col) {
    var _p = _agent.path;
    if (_p == undefined || _p.count < 2) return;

    draw_set_color(_col);

    for (var _i = 0; _i < _p.count - 1; _i++) {
        draw_line_width(_p.px[_i], _p.py[_i], _p.px[_i + 1], _p.py[_i + 1], 3);
    }

    for (var _j = 0; _j < _p.count; _j++) {
        draw_circle(_p.px[_j], _p.py[_j], 3, false);
    }
}