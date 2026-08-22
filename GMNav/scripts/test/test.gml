function gmt_test_layout() {
    gmt_head("L layout");

    var _o = gmnav_layout_create(gmnav_layout.ORTHO, 32, 32);
    gmt_check_f("ortho step_min_world", _o.step_min_world, 32);
    gmt_check_f("ortho diagonal cost",  _o.nb_cost[4], 1.414214, 0.000001);

    var _i = gmnav_layout_create(gmnav_layout.ISO_DIAMOND, 64, 32);
    gmt_check_f("iso cell(1,0) x", gmnav_layout_cell_x(_i, 1, 0),  32);
    gmt_check_f("iso cell(0,1) x", gmnav_layout_cell_x(_i, 0, 1), -32);
    gmt_check_f("iso step_min_world", _i.step_min_world, 32);

    var _modes = [gmnav_layout.ORTHO, gmnav_layout.ISO_DIAMOND, gmnav_layout.ISO_STAGGERED,
                  gmnav_layout.HEX_POINTY, gmnav_layout.HEX_FLAT];
    var _names = ["ORTHO","ISO_DIAMOND","ISO_STAGGERED","HEX_POINTY","HEX_FLAT"];

    for (var _m = 0; _m < 5; _m++) {
        var _l = gmnav_layout_create(_modes[_m], 64, 32);
        var _bad = 0;
        for (var _c = 0; _c < 12; _c++) {
            for (var _r = 0; _r < 12; _r++) {
                var _w  = gmnav_layout_cell_to_world(_l, _c, _r);
                var _rt = gmnav_layout_world_to_cell(_l, _w[0], _w[1]);
                if (_rt[0] != _c || _rt[1] != _r) _bad++;
            }
        }
        gmt_check(_names[_m] + " roundtrip", _bad, 0);
    }
}

function gmt_test_search() {
    gmt_head("S heap, A* and paths");

    var _hp = gmnav_heap_create();
    gmnav_heap_push(_hp, 5, 3, 10);
    gmnav_heap_push(_hp, 5, 1, 20);
    gmnav_heap_push(_hp, 5, 1, 5);
    gmnav_heap_push(_hp, 3, 0, 99);
    gmnav_heap_push(_hp, 5, 3, 2);

    var _ord = [];
    while (!gmnav_heap_is_empty(_hp)) array_push(_ord, gmnav_heap_pop(_hp));
    gmt_check_arr("heap order", _ord, [99,5,20,2,10]);
    gmt_check("pop on empty", gmnav_heap_pop(_hp), GMNAV_NO_NODE);

    var _mz = gmt_maze();
    var _s  = gmnav_search_create(_mz);
    gmnav_search_begin(_s, 0, 4);
    gmt_check("state", gmnav_search_step(_s, 100000), gmnav_state.FOUND);
    gmt_check_arr("path", gmnav_search_get_path(_s), [0,6,11,16,21,22,23,19,14,9,4]);

    var _p = gmnav_path_create(_mz, gmnav_search_get_path(_s));
    gmt_check_f("world length", _p.length, 346.509666, 0.0001);

    var _s2 = gmnav_search_create(_mz);
    gmt_check("goal in wall refused", gmnav_search_begin(_s2, 0, 2), false);
    gmt_check("state FAILED", _s2.state, gmnav_state.FAILED);

    gmt_check("LOS open row",     gmnav_grid_line_clear(_mz, 0, 4, 4, 4), true);
    gmt_check("LOS through wall", gmnav_grid_line_clear(_mz, 0, 0, 4, 0), false);
    gmt_check("LOS wall corner",  gmnav_grid_line_clear(_mz, 1, 3, 2, 4), false);
    gmt_check("LOS diagonal",     gmnav_grid_line_clear(_mz, 0, 4, 4, 0), false);
	
    var _lg = gmt_open5();
    gmnav_grid_set_blocked(_lg, 0, 0, true);
    gmt_check("diagonal ending beside a wall", gmnav_grid_line_clear(_lg, 2, 2, 1, 1), true);
    gmt_check("reverse direction too",         gmnav_grid_line_clear(_lg, 1, 1, 2, 2), true);
    gmt_check("adjacent cells always clear",   gmnav_grid_line_clear(_lg, 3, 3, 4, 4), true);

    var _op = gmt_open5();
    var _s3 = gmnav_search_create(_op);
    gmnav_search_begin(_s3, 0, 24);
    gmnav_search_step(_s3, 100000);

    var _p2 = gmnav_path_create(_op, gmnav_search_get_path(_s3));
    gmt_check("raw waypoints", _p2.count, 5);
    gmt_check_f("raw length", _p2.length, 181.019333, 0.0001);

    gmnav_path_smooth(_p2);
    gmt_check("smoothed waypoints", _p2.count, 2);
    gmt_check_f("smoothed length", _p2.length, 181.019333, 0.0001);

    var _a = gmnav_search_create(_mz);
    var _b = gmnav_search_create(gmt_maze());
    gmnav_search_begin(_a, 24, 0); gmnav_search_step(_a, 100000);
    gmnav_search_begin(_b, 24, 0); gmnav_search_step(_b, 100000);
    gmt_check("deterministic", gmt_arr_str(gmnav_search_get_path(_a)),
                               gmt_arr_str(gmnav_search_get_path(_b)));
}

function gmt_test_flowfield() {
    gmt_head("F flow field");

    var _mz = gmt_maze();
    var _f  = gmnav_flowfield_create(_mz);

    gmt_check("built", gmnav_flowfield_build(_f, 0), true);
    gmt_check("state", _f.state, gmnav_state.FOUND);

    gmt_check_f("dist (1,0)", gmnav_flowfield_cost_at(_f, 48, 16), 1.0);
    gmt_check_f("dist (0,4)", gmnav_flowfield_cost_at(_f, 16, 144), 4.0);
    gmt_check_f("dist (4,0) matches A*", gmnav_flowfield_cost_at(_f, 144, 16),
                346.509666 / 32, 0.0001);

    gmt_check("wall unreachable", gmnav_flowfield_is_reachable(_f, 80, 16), false);
    gmt_check("corner reachable", gmnav_flowfield_is_reachable(_f, 144, 144), true);

    var _d = gmnav_flowfield_sample(_f, 80, 144);
    gmt_check_f("dir (2,4) x", _d[0], -1.0);
    gmt_check_f("dir (2,4) y", _d[1],  0.0);

    gmt_check("field walk failures", gmt_field_walk_failures(_mz, _f), 0);
}

function gmt_test_clearance() {
    gmt_head("C1 regression through begin()");

    var _mz = gmt_maze();
    var _s  = gmnav_search_create(_mz);
    gmnav_search_begin(_s, 0, 4);
    gmt_check("A* unchanged", gmnav_search_step(_s, 100000), gmnav_state.FOUND);
    gmt_check_arr("path unchanged", gmnav_search_get_path(_s), [0,6,11,16,21,22,23,19,14,9,4]);

    var _s2 = gmnav_search_create(_mz);
    gmt_check("need_clear 0 begins", gmnav_search_begin(_s2, 0, 4, false, undefined, 0), true);
    gmt_check("clearance not built when unused", _mz.clear == undefined, true);
    gmnav_search_abort(_s2);

    gmt_head("C2 chamfer values");

    var _d = gmt_doors();
    gmt_check("build", gmnav_clearance_build(_d), true);
    gmt_check("not stale", gmnav_clearance_is_stale(_d), false);

    gmt_check("wall cell",         gmnav_clearance_at(_d, gmnav_grid_node(_d, 5, 0)), 0);
    gmt_check("narrow door",       gmnav_clearance_at(_d, gmnav_grid_node(_d, 5, 2)), 1);
    gmt_check("wide door centre",  gmnav_clearance_at(_d, gmnav_grid_node(_d, 5, 7)), 2);
    gmt_check("wide door edge",    gmnav_clearance_at(_d, gmnav_grid_node(_d, 5, 6)), 1);
    gmt_check("border cell",       gmnav_clearance_at(_d, gmnav_grid_node(_d, 0, 0)), 1);
    gmt_check("open interior",     gmnav_clearance_at(_d, gmnav_grid_node(_d, 2, 5)), 3);
    gmt_check("beside the wall",   gmnav_clearance_at(_d, gmnav_grid_node(_d, 4, 5)), 1);
    gmt_check("one out from wall", gmnav_clearance_at(_d, gmnav_grid_node(_d, 3, 5)), 2);

    gmt_check("up-right blind spot",  gmnav_clearance_at(_d, gmnav_grid_node(_d, 4, 6)), 1);
    gmt_check("down-left blind spot", gmnav_clearance_at(_d, gmnav_grid_node(_d, 6, 8)), 1);

    var _mism = 0;
    for (var _c = 0; _c < 11; _c++) {
        for (var _r = 0; _r < 11; _r++) {
            var _got  = gmnav_clearance_at(_d, gmnav_grid_node(_d, _c, _r));
            var _true = gmt_clearance_bruteforce(_d, _c, _r);
            if (_got != _true) {
                _mism++;
                if (_mism <= 5) gmt_note("mismatch c" + string(_c) + " r" + string(_r)
                                       + " got " + string(_got) + " true " + string(_true));
            }
        }
    }
    gmt_check("brute force audit", _mism, 0);

    gmt_head("C3 radius conversion");
    gmt_check("radius 8 -> 1",  gmnav_clearance_for_radius(_d, 8),  1);
    gmt_check("radius 16 -> 1", gmnav_clearance_for_radius(_d, 16), 1);
    gmt_check("radius 24 -> 2", gmnav_clearance_for_radius(_d, 24), 2);
    gmt_check("radius 40 -> 3", gmnav_clearance_for_radius(_d, 40), 3);
    gmt_check("radius 0 -> 1",  gmnav_clearance_for_radius(_d, 0),  1);

    gmt_head("C4 door selection");

    var _from = gmnav_grid_node(_d, 0, 2);
    var _to   = gmnav_grid_node(_d, 10, 2);

    var _sm = gmnav_search_create(_d);
    gmnav_search_begin(_sm, _from, _to, false, undefined, 1);
    gmt_check("small found", gmnav_search_step(_sm, 100000), gmnav_state.FOUND);
    gmt_check("small uses narrow door", gmt_door_row(_d, gmnav_search_get_path(_sm)), 2);

    var _bg = gmnav_search_create(_d);
    gmnav_search_begin(_bg, _from, _to, false, undefined, 2);
    gmt_check("big found", gmnav_search_step(_bg, 100000), gmnav_state.FOUND);
    gmt_check("big detours to wide door", gmt_door_row(_d, gmnav_search_get_path(_bg)), 7);

    var _bp = gmnav_search_get_path(_bg);
    gmt_note("big path", gmt_arr_str(_bp));

    var _viol = 0;
    for (var i = 1; i < array_length(_bp) - 1; i++) {
        if (gmnav_clearance_at(_d, _bp[i]) < 2) _viol++;
    }
    gmt_check("no under-clearance interior", _viol, 0);

    var _late = 0;
    for (var i = 3; i < array_length(_bp) - 1; i++) {
        if (gmnav_clearance_at(_d, _bp[i]) < 2) _late++;
    }
    gmt_check("no relaxation beyond window", _late, 0);

    var _hg = gmnav_search_create(_d);
    gmnav_search_begin(_hg, _from, _to, false, undefined, 3);
    gmt_check("huge fails", gmnav_search_step(_hg, 100000), gmnav_state.FAILED);

    gmt_head("C5 relaxation");

    var _tg = gmnav_search_create(_d);
    gmt_check("tight goal begins",
              gmnav_search_begin(_tg, _from, gmnav_grid_node(_d, 5, 2), false, undefined, 2), true);
    gmt_check("tight goal unreachable", gmnav_search_step(_tg, 100000), gmnav_state.FAILED);

    var _ts = gmnav_search_create(_d);
    gmt_check("tight start accepted",
              gmnav_search_begin(_ts, gmnav_grid_node(_d, 5, 2),
                                 gmnav_grid_node(_d, 2, 5), false, undefined, 2), true);
    gmt_check("escapes the doorway", gmnav_search_step(_ts, 100000), gmnav_state.FOUND);
    gmt_note("escape path", gmt_arr_str(gmnav_search_get_path(_ts)));

    gmt_check("nearest finds one",
              gmnav_clearance_nearest(_d, gmnav_grid_node(_d, 5, 2), 2) != GMNAV_NO_NODE, true);
    gmt_check("nearest returns self when ok",
              gmnav_clearance_nearest(_d, gmnav_grid_node(_d, 2, 5), 2),
              gmnav_grid_node(_d, 2, 5));
    gmt_check("nearest impossible",
              gmnav_clearance_nearest(_d, gmnav_grid_node(_d, 5, 2), 9, 3), GMNAV_NO_NODE);

    gmt_head("C6 staleness");
    gmt_check("fresh", gmnav_clearance_is_stale(_d), false);
    gmnav_grid_set_blocked(_d, 5, 7, true);
    gmt_check("stale after edit", gmnav_clearance_is_stale(_d), true);

    gmnav_clearance_build(_d);
    gmt_check("door narrowed", gmnav_clearance_at(_d, gmnav_grid_node(_d, 5, 8)), 1);

    var _bg2 = gmnav_search_create(_d);
    gmnav_search_begin(_bg2, _from, _to, false, undefined, 2);
    gmt_check("big now blocked", gmnav_search_step(_bg2, 100000), gmnav_state.FAILED);

    gmt_head("C7 unsupported layouts");
    var _hx = gmnav_grid_create(8, 8, gmnav_layout_create(gmnav_layout.HEX_POINTY, 32, 32));
    gmt_check("hex refuses build", gmnav_clearance_build(_hx), false);
    gmt_check("hex clear undefined", _hx.clear == undefined, true);

    var _hs = gmnav_search_create(_hx);
    gmt_check("hex search begins", gmnav_search_begin(_hs, 0, 63, false, undefined, 3), true);
    gmt_check("hex solves", gmnav_search_step(_hs, 100000), gmnav_state.FOUND);
    gmt_check("need_clear zeroed", _hs.need_clear, 0);
}

function gmt_test_platformer() {
    gmt_head("P1 clearable 2-tile gap");

    var _g1  = gmt_gap_level(16, 2);
    var _pg1 = gmnav_platgraph_create(_g1, gmt_mover());
    gmt_check("baked", gmnav_platgraph_bake(_pg1), true);
    gmt_check("node count", _pg1.count, 14);
    gmt_check("node 4 at col 4", _pg1.nodes[4] % 16, 4);
    gmt_check("node 5 at col 7", _pg1.nodes[5] % 16, 7);
    gmt_check("bottomless pit yields no falls", gmt_count_links(_pg1, gmnav_link.FALL), 0);

    gmt_note("WALK/FALL/JUMP", string(gmt_count_links(_pg1, gmnav_link.WALK)) + "/"
                             + string(gmt_count_links(_pg1, gmnav_link.FALL)) + "/"
                             + string(gmt_count_links(_pg1, gmnav_link.JUMP)));

    var _s1 = gmnav_graphsearch_create(_pg1);
    gmt_check("crosses the gap", gmnav_graphsearch_solve(_s1, 0, 13), true);
    gmt_check("by jumping", gmt_has_link(gmnav_graphsearch_get_links(_s1), gmnav_link.JUMP), true);
    gmt_note("path", gmt_arr_str(gmnav_graphsearch_get_path(_s1)));

    gmt_head("P2 impassable 8-tile gap");

    var _pg2 = gmnav_platgraph_create(gmt_gap_level(24, 8), gmt_mover());
    gmnav_platgraph_bake(_pg2);
    gmt_check("node count", _pg2.count, 16);

    var _s2 = gmnav_graphsearch_create(_pg2);
    gmt_check("refused", gmnav_graphsearch_solve(_s2, 0, 15), false);
    gmt_check("state FAILED", _s2.state, gmnav_state.FAILED);
    gmt_check("reverse refused", gmnav_graphsearch_solve(_s2, 15, 0), false);
    gmt_check("near side works", gmnav_graphsearch_solve(_s2, 0, 4), true);

    gmt_head("P3 one-way drop");

    var _pg3 = gmnav_platgraph_create(gmt_shelf_level(), gmt_mover());
    gmnav_platgraph_bake(_pg3);
    gmt_check("node count", _pg3.count, 16);
    gmt_check("node 5 on shelf", _pg3.nodes[5] div 16, 3);
    gmt_check("node 6 on floor", _pg3.nodes[6] div 16, 9);
    gmt_check("fall links exist", gmt_count_links(_pg3, gmnav_link.FALL) > 0, true);

    gmt_note("WALK/FALL/JUMP", string(gmt_count_links(_pg3, gmnav_link.WALK)) + "/"
                             + string(gmt_count_links(_pg3, gmnav_link.FALL)) + "/"
                             + string(gmt_count_links(_pg3, gmnav_link.JUMP)));

    var _s3 = gmnav_graphsearch_create(_pg3);
    gmt_check("descends", gmnav_graphsearch_solve(_s3, 0, 15), true);
    gmt_check("by falling", gmt_has_link(gmnav_graphsearch_get_links(_s3), gmnav_link.FALL), true);
    gmt_note("path", gmt_arr_str(gmnav_graphsearch_get_path(_s3)));

    gmt_check("no way back up", gmnav_graphsearch_solve(_s3, 15, 0), false);
    gmt_check("cannot climb the shelf", gmnav_graphsearch_solve(_s3, 6, 5), false);

    var _w = gmnav_platgraph_node_world(_pg3, 4);
    gmt_check("node_world round trip", gmnav_platgraph_node_at(_pg3, _w[0], _w[1]), 4);
    gmt_check("airborne finds ledge below", gmnav_platgraph_node_at(_pg3, _w[0], _w[1] - 30), 4);

    gmt_head("P4 determinism");

    var _da = gmnav_graphsearch_create(_pg1);
    gmnav_graphsearch_solve(_da, 0, 13);

    var _pgr = gmnav_platgraph_create(gmt_gap_level(16, 2), gmt_mover());
    gmnav_platgraph_bake(_pgr);
    var _db = gmnav_graphsearch_create(_pgr);
    gmnav_graphsearch_solve(_db, 0, 13);

    gmt_check("rebaked graph matches",
              gmt_arr_str(gmnav_graphsearch_get_path(_da)),
              gmt_arr_str(gmnav_graphsearch_get_path(_db)));
	
	gmt_head("P6 jump links respect the movement model");

	var _jg = gmnav_platgraph_create(gmt_shelf_level(), gmt_mover());
	gmnav_platgraph_bake(_jg);

	var _mv = _jg.move;
	var _rise = 0;
	var _v = _mv.jump_vel;
	while (_v > 0) { _v -= _mv.gravity; _rise += max(0, _v); }
	gmt_note("max jump rise px", string_format(_rise, 1, 2));

	var _bad = 0;
	for (var _i = 0; _i < _jg.count; _i++) {
	    var _e0 = _jg.edge_start[_i];
	    var _e1 = _jg.edge_start[_i + 1];

	    for (var e = _e0; e < _e1; e++) {
	        if (_jg.edge_type[e] != gmnav_link.JUMP) continue;

	        var _gain = _jg.node_y[_i] - _jg.node_y[_jg.edge_to[e]];
	        if (_gain > _rise + 0.001) {
	            _bad++;
	            if (_bad <= 5) gmt_note("impossible jump " + string(_i) + "->"
	                                  + string(_jg.edge_to[e])
	                                  + " rise " + string_format(_gain, 1, 1));
	        }
	    }
	}
	gmt_check("no jump exceeds max rise", _bad, 0);
	
    gmt_head("P7 one-way platforms");

    var _ow = gmt_oneway_level();
    var _og = gmnav_platgraph_create(_ow, gmt_mover());
    gmnav_platgraph_bake(_og);

    var _omv   = _og.move;
    var _orise = 0;
    var _ov    = _omv.jump_vel;
    while (_ov > 0) { _ov -= _omv.gravity; _orise += max(0, _ov); }
    gmt_note("max jump rise px", string_format(_orise, 1, 2));

    var _high = 0;   // upward links onto the out-of-reach one-way, row 8
    var _low  = 0;   // upward links onto the in-reach one-way, row 9
    var _obad = 0;   // links that exceed the model's rise

    for (var _i = 0; _i < _og.count; _i++) {
        var _e0 = _og.edge_start[_i];
        var _e1 = _og.edge_start[_i + 1];

        for (var e = _e0; e < _e1; e++) {
            var _to = _og.edge_to[e];
            var _gn = _og.nodes[_to];
            var _sr = (_gn div _ow.width) + 1;
            var _sn = gmnav_grid_node(_ow, _gn % _ow.width, _sr);

            if (_sn != GMNAV_NO_NODE
            && (_ow.flags[_sn] & GMNAV_FLAG_ONEWAY) != 0
            &&  _og.node_y[_to] < _og.node_y[_i]) {
                if      (_sr == 8) _high++;
                else if (_sr == 9) _low++;
            }

            if (_og.edge_type[e] == gmnav_link.JUMP
            && (_og.node_y[_i] - _og.node_y[_to]) > _orise + 0.001) {
                _obad++;
            }
        }
    }

    gmt_note("in-reach one-way links", _low);
    gmt_check("out-of-reach one-way produces no links", _high, 0);
    gmt_check("in-reach one-way still linked", _low > 0, true);
    gmt_check("no one-way jump exceeds max rise", _obad, 0);
    gmt_check("one-way cells are still standable",
              _og.node_of[gmnav_grid_node(_ow, 17, 8)] >= 0, true);

    gmt_head("P8 links carry a replayable launch");

    var _rbad = 0;   // stored launch lands on the wrong node
    var _wbad = 0;   // WALK edge whose launch does not face its target
    var _non  = 0;

    for (var _i = 0; _i < _og.count; _i++) {
        var _e0 = _og.edge_start[_i];
        var _e1 = _og.edge_start[_i + 1];

        for (var e = _e0; e < _e1; e++) {
            var _to = _og.edge_to[e];

            if (_og.edge_type[e] == gmnav_link.WALK) {
                var _want = (_og.node_x[_to] > _og.node_x[_i]) ? 1 : -1;
                if (_og.edge_vx[e] * _want <= 0 || _og.edge_vy[e] != 0) _wbad++;
                continue;
            }

            _non++;
            var _land = gmt_plat_replay(_og, _i, _og.edge_vx[e], _og.edge_vy[e],
                                        _og.edge_type[e]);
            if (_land != _to) _rbad++;
        }
    }

    gmt_note("non-walk edges replayed", _non);
    gmt_check("every stored launch reproduces its link", _rbad, 0);
    gmt_check("walk launches face their target", _wbad, 0);

    var _lk = gmnav_platgraph_link_get(_og, 0, _og.edge_to[_og.edge_start[0]]);
    gmt_check("link_get returns a struct", is_struct(_lk), true);
    gmt_check("link_get on a missing edge returns undefined",
              gmnav_platgraph_link_get(_og, 0, -99), undefined);
}

function gmt_test_agent() {
    gmt_head("A1 construction and contract");

    var _sc = gmnav_scheduler_create(gmt_open5(), 5000, 2);
    var _ag = gmnav_agent_create(_sc, 16, 16, 8, 2);

    gmt_check("no path at rest", gmnav_agent_has_path(_ag), false);
    gmt_check("no goal at rest", _ag.has_goal, false);
    gmt_check("velocity zero", _ag.vx == 0 && _ag.vy == 0, true);

    gmnav_agent_update(_ag);
    gmt_check_f("idle x unchanged", _ag.x, 16);
    gmt_check_f("idle y unchanged", _ag.y, 16);

    gmt_check("goto out of bounds refused", gmnav_agent_goto(_ag, -500, -500), false);
    gmt_check("goto accepted", gmnav_agent_goto(_ag, 144, 144, gmnav_priority.IMMEDIATE), true);
    gmt_check("has goal", _ag.has_goal, true);
    gmt_check("resolved immediately", _ag.ticket.state, gmnav_state.FOUND);

    var _px = _ag.x, _py = _ag.y;
    gmnav_agent_update(_ag);
    gmt_check_f("update does not move x", _ag.x, _px);
    gmt_check_f("update does not move y", _ag.y, _py);
    gmt_check("path collected", gmnav_agent_has_path(_ag), true);
    gmt_check("velocity proposed", (_ag.vx != 0 || _ag.vy != 0), true);

    gmt_head("A2 traversal");

    var _t = gmnav_agent_create(gmnav_scheduler_create(gmt_open5(), 5000, 2), 16, 16, 8, 2);
    gmnav_agent_goto(_t, 144, 144, gmnav_priority.IMMEDIATE);
    var _tf = gmt_run_agent(_t, 600);

    gmt_check("finished", _tf > 0, true);
    gmt_check("reached goal", gmt_agent_dist(_t, 144, 144) < 8, true);
    gmt_check("path released", gmnav_agent_has_path(_t), false);
    gmt_note("frames", _tf);

    var _m = gmnav_agent_create(gmnav_scheduler_create(gmt_maze(), 5000, 2), 16, 16, 8, 2);
    gmnav_agent_goto(_m, 144, 16, gmnav_priority.IMMEDIATE);
    var _mf = gmt_run_agent(_m, 900);
    gmt_check("navigates the maze", _mf > 0, true);
    gmt_check("reached goal", gmt_agent_dist(_m, 144, 16) < 8, true);
    gmt_note("frames", _mf);

    var _f = gmnav_agent_create(gmnav_scheduler_create(gmt_open5(), 5000, 2), 16, 16, 8, 12);
    _f.accel = 1.0;
    gmnav_agent_goto(_f, 144, 144, gmnav_priority.IMMEDIATE);
    var _ff = gmt_run_agent(_f, 300);
    gmt_check("fast agent finishes", _ff > 0, true);
    gmt_check("fast agent lands", gmt_agent_dist(_f, 144, 144) < 16, true);
    gmt_note("frames", _ff);

    gmt_head("A3 stop and failure");

    var _s = gmnav_agent_create(gmnav_scheduler_create(gmt_open5(), 5000, 2), 16, 16, 8, 2);
    gmnav_agent_goto(_s, 144, 144, gmnav_priority.IMMEDIATE);
    gmnav_agent_update(_s);
    gmt_check("has path", gmnav_agent_has_path(_s), true);

    gmnav_agent_stop(_s);
    gmt_check("path cleared", gmnav_agent_has_path(_s), false);
    gmt_check("goal cleared", _s.has_goal, false);
    gmt_check("ticket cleared", _s.ticket == undefined, true);

    gmnav_agent_update(_s);
    var _v1 = point_distance(0, 0, _s.vx, _s.vy);
    gmnav_agent_update(_s);
    var _v2 = point_distance(0, 0, _s.vx, _s.vy);
    gmt_check("velocity decaying", _v2 < _v1, true);

    var _w = gmnav_agent_create(gmnav_scheduler_create(gmt_maze(), 5000, 2), 16, 16, 8, 2);
    gmnav_agent_goto(_w, 80, 16, gmnav_priority.IMMEDIATE);
    gmt_check("ticket failed", _w.ticket.state, gmnav_state.FAILED);

    gmnav_agent_update(_w);
    gmt_check("no path after failure", gmnav_agent_has_path(_w), false);
    gmt_check("goal dropped", _w.has_goal, false);
    gmt_check("ticket released", _w.ticket == undefined, true);

    gmt_head("A4 avoidance");

    var _vs = gmnav_scheduler_create(gmt_open5(), 5000, 4);
    var _a1 = gmnav_agent_create(_vs, 70, 80, 8, 2);
    var _a2 = gmnav_agent_create(_vs, 75, 80, 8, 2);
    var _crowd = [_a1, _a2];

    gmnav_agent_goto(_a1, 144, 80, gmnav_priority.IMMEDIATE);
    gmnav_agent_goto(_a2, 144, 80, gmnav_priority.IMMEDIATE);

    var _d0 = point_distance(_a1.x, _a1.y, _a2.x, _a2.y);
    for (var i = 0; i < 20; i++) {
        gmnav_agent_update(_a1, _crowd);
        gmnav_agent_update(_a2, _crowd);
        _a1.x += _a1.vx; _a1.y += _a1.vy;
        _a2.x += _a2.vx; _a2.y += _a2.vy;
    }
    gmt_check("separated", point_distance(_a1.x, _a1.y, _a2.x, _a2.y) > _d0, true);
    gmt_check("speed cap respected", point_distance(0, 0, _a1.vx, _a1.vy) <= 2.001, true);

    var _n = gmnav_agent_create(gmnav_scheduler_create(gmt_open5(), 5000, 2), 16, 80, 8, 2);
    gmnav_agent_goto(_n, 144, 80, gmnav_priority.IMMEDIATE);
    for (var i = 0; i < 10; i++) {
        gmnav_agent_update(_n);
        _n.x += _n.vx; _n.y += _n.vy;
    }
    gmt_check_f("no drift without neighbours", _n.y, 80, 0.001);

    gmt_head("A5 repath on stale");

    var _rg = gmt_open5();
    var _rs = gmnav_scheduler_create(_rg, 5000, 2);
    var _r  = gmnav_agent_create(_rs, 16, 80, 8, 2);

    gmnav_agent_goto(_r, 144, 80, gmnav_priority.IMMEDIATE);
    gmnav_agent_update(_r);
    gmt_check("has path", gmnav_agent_has_path(_r), true);
    gmt_check("not stale yet", _r.path.stale, false);

    gmnav_grid_fill_blocked(_rg, 2, 0, 2, 3, true);
    _r.path.stale = true;

    gmnav_agent_update(_r);
    gmt_check("repath requested", _r.ticket != undefined, true);
    gmt_check("old path kept meanwhile", gmnav_agent_has_path(_r), true);

    gmnav_scheduler_update(_rs);
    gmnav_agent_update(_r);
    gmt_check("new path collected", _r.ticket == undefined, true);
    gmt_check("fresh path not stale", _r.path.stale, false);

    var _rf = gmt_run_agent(_r, 900);
    gmt_check("still reaches goal", _rf > 0, true);
    gmt_check("reached goal", gmt_agent_dist(_r, 144, 80) < 8, true);
    gmt_note("frames", _rf);

    gmt_head("A6 arrival latch");

    var _l = gmnav_agent_create(gmnav_scheduler_create(gmt_open5(), 5000, 2), 16, 16, 8, 2);
    gmt_check("not arrived at rest", gmnav_agent_arrived(_l), false);

    gmnav_agent_goto(_l, 144, 144, gmnav_priority.IMMEDIATE);
    gmnav_agent_update(_l);
    gmt_check("not arrived while travelling", gmnav_agent_arrived(_l), false);

    gmt_run_agent(_l, 600);
    gmt_check("arrived after journey", gmnav_agent_arrived(_l), true);

    gmnav_agent_update(_l);
    gmnav_agent_update(_l);
    gmt_check("latch holds", gmnav_agent_arrived(_l), true);

    gmnav_agent_goto(_l, 16, 16, gmnav_priority.IMMEDIATE);
    gmt_check("cleared by goto", gmnav_agent_arrived(_l), false);
    gmt_run_agent(_l, 600);
    gmt_check("arrived again", gmnav_agent_arrived(_l), true);

    gmnav_agent_stop(_l);
    gmt_check("cleared by stop", gmnav_agent_arrived(_l), false);

    var _fz = gmnav_agent_create(gmnav_scheduler_create(gmt_maze(), 5000, 2), 16, 16, 8, 2);
    gmnav_agent_goto(_fz, 80, 16, gmnav_priority.IMMEDIATE);
    gmnav_agent_update(_fz);
    gmt_check("failure does not latch", gmnav_agent_arrived(_fz), false);
}

function gmt_test_costfield() {
    gmt_head("K1 layer authoring");

    var _g = gmt_corridor();
    var _l = gmnav_costlayer_create(_g, "danger");

    gmt_check("starts empty", gmnav_costlayer_get(_l, 3, 2), 0);
    gmt_check("set accepted", gmnav_costlayer_set(_l, 3, 2, 7), true);
    gmt_check("reads back", gmnav_costlayer_get(_l, 3, 2), 7);
    gmt_check("out of bounds refused", gmnav_costlayer_set(_l, 99, 99, 5), false);

    var _v0 = _l.version;
    gmnav_costlayer_set(_l, 3, 2, 7);
    gmt_check("no-op does not bump version", _l.version, _v0);
    gmnav_costlayer_set(_l, 3, 2, 9);
    gmt_check("real change bumps version", _l.version > _v0, true);

    gmnav_costlayer_clear(_l);
    gmt_check("cleared", gmnav_costlayer_get(_l, 3, 2), 0);

    gmt_head("K2 profile baking");

    var _p = gmnav_costprofile_create(_g, "grunt");
    gmt_check("dirty before first bake", gmnav_costprofile_is_dirty(_p), true);

    gmnav_costprofile_bake(_p);
    gmt_check("clean after bake", gmnav_costprofile_is_dirty(_p), false);
    gmt_check_f("empty profile is base cost", _p.resolved[0], 1);

    gmnav_costlayer_set(_l, 4, 2, 5);
    gmnav_costprofile_add(_p, _l, 2);
    gmt_check("dirty after add", gmnav_costprofile_is_dirty(_p), true);

    gmnav_costprofile_bake(_p);
    gmt_check_f("1 + 5*2", _p.resolved[gmnav_grid_node(_g, 4, 2)], 11);
    gmt_check_f("untouched cell", _p.resolved[gmnav_grid_node(_g, 0, 0)], 1);

    gmnav_costprofile_set_weight(_p, _l, 4);
    gmt_check("weight change dirties", gmnav_costprofile_is_dirty(_p), true);
    gmnav_costprofile_bake(_p);
    gmt_check_f("1 + 5*4", _p.resolved[gmnav_grid_node(_g, 4, 2)], 21);

    gmnav_costprofile_set_weight(_p, _l, -1);
    gmnav_costprofile_bake(_p);
    gmt_check_f("clamped at 1", _p.resolved[gmnav_grid_node(_g, 4, 2)], 1);

    gmnav_costprofile_set_weight(_p, _l, 2);
    gmnav_costprofile_bake(_p);

    gmnav_costlayer_set(_l, 4, 2, 6);
    gmt_check("layer edit dirties profile", gmnav_costprofile_is_dirty(_p), true);
    gmnav_costprofile_bake_if_dirty(_p);
    gmt_check_f("rebaked", _p.resolved[gmnav_grid_node(_g, 4, 2)], 13);

    gmnav_grid_set_cost(_g, 0, 0, 3);
    gmt_check("grid edit dirties profile", gmnav_costprofile_is_dirty(_p), true);
    gmnav_costprofile_bake(_p);
    gmt_check_f("base cost folded in", _p.resolved[gmnav_grid_node(_g, 0, 0)], 3);

    gmnav_costprofile_remove(_p, _l);
    gmnav_costprofile_bake(_p);
    gmt_check_f("removed layer gone", _p.resolved[gmnav_grid_node(_g, 4, 2)], 1);

    gmt_head("K3 a profile bends a real path");

    var _cg = gmt_corridor();
    var _dl = gmnav_costlayer_create(_cg, "danger");
    for (var _c = 0; _c < 9; _c++) gmnav_costlayer_set(_dl, _c, 2, 10);

    var _from = gmnav_grid_node(_cg, 0, 2);
    var _to   = gmnav_grid_node(_cg, 8, 2);

    var _plain = gmnav_search_create(_cg);
    gmnav_search_begin(_plain, _from, _to);
    gmt_check("plain found", gmnav_search_step(_plain, 100000), gmnav_state.FOUND);
    var _pp = gmnav_search_get_path(_plain);
    gmt_check("plain goes straight", gmt_path_visits(_cg, _pp, 4, 2), true);
    gmt_check("plain length", array_length(_pp), 9);
    gmt_check_f("plain cost", gmt_path_cost(_cg, undefined, _pp), 8);

    var _pf = gmnav_costprofile_create(_cg, "cautious");
    gmnav_costprofile_add(_pf, _dl, 1);
    gmnav_costprofile_bake(_pf);

    var _avoid = gmnav_search_create(_cg);
    gmnav_search_begin(_avoid, _from, _to, false, _pf);
    gmt_check("avoid found", gmnav_search_step(_avoid, 100000), gmnav_state.FOUND);
    var _ap = gmnav_search_get_path(_avoid);

    gmt_check("route changed", gmt_arr_str(_ap) != gmt_arr_str(_pp), true);
    gmt_check("leaves the danger row", gmt_path_visits(_cg, _ap, 4, 2), false);
    gmt_note("plain path", gmt_arr_str(_pp));
    gmt_note("avoid path", gmt_arr_str(_ap));
    gmt_note("avoid cost", string_format(gmt_path_cost(_cg, _pf, _ap), 1, 2));

    gmt_check("detour beats straight line",
              gmt_path_cost(_cg, _pf, _ap) < gmt_path_cost(_cg, _pf, _pp), true);

    gmt_head("K4 weight drives the decision");

    var _wp = gmnav_costprofile_create(_cg, "reckless");
    gmnav_costprofile_add(_wp, _dl, 0);
    gmnav_costprofile_bake(_wp);

    var _rk = gmnav_search_create(_cg);
    gmnav_search_begin(_rk, _from, _to, false, _wp);
    gmnav_search_step(_rk, 100000);
    gmt_check("weight 0 ignores the layer",
              gmt_arr_str(gmnav_search_get_path(_rk)), gmt_arr_str(_pp));

    gmt_check("same layer, different routes",
              gmt_arr_str(gmnav_search_get_path(_rk)) != gmt_arr_str(_ap), true);
    gmt_check_f("cautious resolved", _pf.resolved[gmnav_grid_node(_cg, 4, 2)], 11);
    gmt_check_f("reckless resolved", _wp.resolved[gmnav_grid_node(_cg, 4, 2)], 1);

    gmt_head("K5 region baking");

    var _rg = gmt_corridor();
    var _rl = gmnav_costlayer_create(_rg, "moving");
    var _rp = gmnav_costprofile_create(_rg, "tracker");
    gmnav_costprofile_add(_rp, _rl, 1);
    gmnav_costprofile_bake(_rp);

    var _r1 = gmnav_costlayer_stamp_radial(_rl, 80, 80, 40, 10, 1);
    gmnav_costprofile_bake_region(_rp, _r1[0], _r1[1], _r1[2], _r1[3]);

    gmt_check_f("stamp peak", _rl.values[gmnav_grid_node(_rg, 2, 2)], 10);
    gmt_check_f("stamp resolved", _rp.resolved[gmnav_grid_node(_rg, 2, 2)], 11);
    gmt_check_f("outside stamp", _rp.resolved[gmnav_grid_node(_rg, 6, 2)], 1);
    gmt_note("stamp rect", gmt_arr_str(_r1));

    gmnav_costlayer_clear_region(_rl, _r1[0], _r1[1], _r1[2], _r1[3]);
    var _r2 = gmnav_costlayer_stamp_radial(_rl, 176, 80, 40, 10, 1);

    gmnav_costprofile_bake_region(_rp, _r1[0], _r1[1], _r1[2], _r1[3]);
    gmnav_costprofile_bake_region(_rp, _r2[0], _r2[1], _r2[2], _r2[3]);

    gmt_check_f("old footprint cleared", _rp.resolved[gmnav_grid_node(_rg, 2, 2)], 1);
    gmt_check_f("new peak", _rp.resolved[gmnav_grid_node(_rg, 5, 2)], 11);

    var _spot = _rp.resolved[gmnav_grid_node(_rg, 5, 2)];
    gmnav_costprofile_bake(_rp);
    gmt_check_f("region bake matches full bake",
                _rp.resolved[gmnav_grid_node(_rg, 5, 2)], _spot);

    gmt_head("K6 flow field honours the profile");

    var _ff = gmnav_flowfield_create(_cg, _pf);
    gmt_check("built", gmnav_flowfield_build(_ff, _to), true);

    var _plainff = gmnav_flowfield_create(_cg);
    gmnav_flowfield_build(_plainff, _to);

    var _cost_prof  = gmnav_flowfield_cost_at(_ff,      16, 80);
    var _cost_plain = gmnav_flowfield_cost_at(_plainff, 16, 80);

    gmt_check("profile raises the cost", _cost_prof > _cost_plain, true);
    gmt_check_f("plain field cost", _cost_plain, 8);
    gmt_note("profile field cost", string_format(_cost_prof, 1, 4));
    gmt_check("field still walkable", gmt_field_walk_failures(_cg, _ff), 0);
}

function gmt_test_nonortho() {
    var _modes = [gmnav_layout.ORTHO, gmnav_layout.ISO_DIAMOND, gmnav_layout.ISO_STAGGERED,
                  gmnav_layout.HEX_POINTY, gmnav_layout.HEX_FLAT];
    var _names = ["ORTHO", "ISO_DIAMOND", "ISO_STAGGERED", "HEX_POINTY", "HEX_FLAT"];

    gmt_head("N1 neighbour table integrity");

    for (var _m = 0; _m < 5; _m++) {
        var _g = gmt_layout_grid(_modes[_m]);
        gmt_check(_names[_m] + " symmetric", gmt_neighbour_symmetry_breaks(_g), 0);

        var _span = gmt_neighbour_span(_g);
        gmt_check(_names[_m] + " span sane", _span < 100, true);
        gmt_note(_names[_m] + " max span", string_format(_span, 1, 2));
    }

    gmt_head("N2 search on every layout");

    for (var _m = 0; _m < 5; _m++) {
        var _g = gmt_layout_grid(_modes[_m]);
        var _s = gmnav_search_create(_g);

        var _from = gmnav_grid_node(_g, 1, 1);
        var _to   = gmnav_grid_node(_g, 8, 8);

        gmt_check(_names[_m] + " begins", gmnav_search_begin(_s, _from, _to), true);
        gmt_check(_names[_m] + " found", gmnav_search_step(_s, 100000), gmnav_state.FOUND);

        var _p = gmnav_search_get_path(_s);
        gmt_check(_names[_m] + " path ends correct",
                  (_p[0] == _from) && (_p[array_length(_p) - 1] == _to), true);
        gmt_check(_names[_m] + " every step adjacent", gmt_path_adjacency_breaks(_g, _p), 0);
        gmt_note(_names[_m] + " path length", array_length(_p));
    }

    gmt_head("N3 search around obstacles");

    for (var _m = 0; _m < 5; _m++) {
        var _g = gmt_layout_grid(_modes[_m], 11, 11);

        gmnav_grid_fill_blocked(_g, 0, 5, 8, 5, true);

        var _s = gmnav_search_create(_g);
        var _from = gmnav_grid_node(_g, 2, 1);
        var _to   = gmnav_grid_node(_g, 2, 9);

        gmnav_search_begin(_s, _from, _to);
        gmt_check(_names[_m] + " routes around", gmnav_search_step(_s, 100000), gmnav_state.FOUND);

        var _p = gmnav_search_get_path(_s);
        gmt_check(_names[_m] + " no blocked nodes", gmt_path_blocked_count(_g, _p), 0);
        gmt_check(_names[_m] + " still adjacent", gmt_path_adjacency_breaks(_g, _p), 0);
        gmt_note(_names[_m] + " detour length", array_length(_p));

        var _g2 = gmt_layout_grid(_modes[_m], 11, 11);
        gmnav_grid_fill_blocked(_g2, 0, 5, 10, 5, true);
        gmnav_grid_fill_blocked(_g2, 0, 6, 10, 6, true);

        var _s2 = gmnav_search_create(_g2);
        gmnav_search_begin(_s2, gmnav_grid_node(_g2, 2, 1), gmnav_grid_node(_g2, 2, 9));
        gmt_check(_names[_m] + " sealed refuses", gmnav_search_step(_s2, 100000), gmnav_state.FAILED);
    }
	
    gmt_head("N3b staggered row-skip is intentional");

    var _sg = gmt_layout_grid(gmnav_layout.ISO_STAGGERED, 11, 11);
    gmnav_grid_fill_blocked(_sg, 0, 5, 10, 5, true);

    var _ss = gmnav_search_create(_sg);
    gmnav_search_begin(_ss, gmnav_grid_node(_sg, 2, 1), gmnav_grid_node(_sg, 2, 9));
    gmt_check("one row does not seal staggered",
              gmnav_search_step(_ss, 100000), gmnav_state.FOUND);
    gmt_note("crosses in", array_length(gmnav_search_get_path(_ss)));

    var _og = gmt_layout_grid(gmnav_layout.ORTHO, 11, 11);
    gmnav_grid_fill_blocked(_og, 0, 5, 10, 5, true);
    var _os = gmnav_search_create(_og);
    gmnav_search_begin(_os, gmnav_grid_node(_og, 2, 1), gmnav_grid_node(_og, 2, 9));
    gmt_check("one row does seal ortho", gmnav_search_step(_os, 100000), gmnav_state.FAILED);

    gmt_head("N4 A* optimality against Dijkstra");

    for (var _m = 0; _m < 5; _m++) {
        var _g = gmt_layout_grid(_modes[_m], 11, 11);
        gmnav_grid_fill_blocked(_g, 4, 2, 4, 8, true);
        gmnav_grid_fill_blocked(_g, 7, 0, 7, 6, true);

        var _from = gmnav_grid_node(_g, 1, 5);
        var _to   = gmnav_grid_node(_g, 9, 5);

        var _astar = gmnav_search_create(_g);
        gmnav_search_begin(_astar, _from, _to);
        gmnav_search_step(_astar, 100000);
        var _ac = _astar.slot_g_final;

        var _dij = gmnav_search_create(_g);
        _dij.h_mode = gmnav_heuristic.ZERO;
        gmnav_search_begin(_dij, _from, _to);
        gmnav_search_step(_dij, 100000);
        var _dc = _dij.slot_g_final;

        gmt_check_f(_names[_m] + " optimal cost", _ac, _dc, 0.0001);
        gmt_note(_names[_m] + " cost / expansions",
                 string_format(_ac, 1, 4) + " / " + string(_astar.expansions)
                 + " vs dijkstra " + string(_dij.expansions));
    }

    gmt_head("N5 flow fields on every layout");

    for (var _m = 0; _m < 5; _m++) {
        var _g = gmt_layout_grid(_modes[_m], 11, 11);
        gmnav_grid_fill_blocked(_g, 0, 5, 8, 5, true);

        var _f = gmnav_flowfield_create(_g);
        gmt_check(_names[_m] + " field builds",
                  gmnav_flowfield_build(_f, gmnav_grid_node(_g, 2, 9)), true);
        gmt_check(_names[_m] + " field walkable", gmt_field_walk_failures(_g, _f), 0);
    }
}

function gmt_test_dynamic() {
    gmt_head("Y1 version tracking");

    var _g = gmt_big_open();
    var _v0 = _g.version;

    gmnav_grid_set_blocked(_g, 5, 5, true);
    gmt_check("block bumps version", _g.version > _v0, true);

    var _v1 = _g.version;
    gmnav_grid_set_blocked(_g, 5, 5, true);
    gmt_check("redundant block does not bump", _g.version, _v1);

    gmnav_grid_set_cost(_g, 6, 6, 4);
    gmt_check("cost change bumps", _g.version > _v1, true);

    var _v2 = _g.version;
    gmnav_grid_set_cost(_g, 6, 6, 4);
    gmt_check("redundant cost does not bump", _g.version, _v2);

    gmnav_grid_set_flag(_g, 7, 7, GMNAV_FLAG_DANGER, true);
    gmt_check("flag change bumps", _g.version > _v2, true);

    var _v3 = _g.version;
    gmnav_grid_fill_blocked(_g, 1, 1, 3, 3, true);
    gmt_check("fill bumps exactly once", _g.version, _v3 + 1);

    gmt_head("Y2 a completed search is not stale");

    var _cg = gmt_big_open();
    var _cs = gmnav_search_create(_cg);
    gmnav_search_begin(_cs, gmnav_grid_node(_cg, 0, 0), gmnav_grid_node(_cg, 14, 14));
    gmnav_search_step(_cs, 100000);

    gmt_check("found", _cs.state, gmnav_state.FOUND);
    gmt_check("not stale", gmnav_search_is_stale(_cs), false);

    gmnav_grid_set_blocked(_cg, 7, 7, true);
    gmt_check("stale after the world changes", gmnav_search_is_stale(_cs), true);
    gmt_check("path is still returned", array_length(gmnav_search_get_path(_cs)) > 0, true);

    gmt_head("Y3 the world changes mid-search");

    var _mg = gmt_big_open();
    var _ms = gmnav_search_create(_mg);
    gmnav_search_begin(_ms, gmnav_grid_node(_mg, 0, 7), gmnav_grid_node(_mg, 14, 7));

    gmt_check("suspended after slice 1", gmnav_search_step(_ms, 4), gmnav_state.WORKING);
    gmt_check("suspended after slice 2", gmnav_search_step(_ms, 4), gmnav_state.WORKING);
    gmt_check("not yet stale", _ms.stale, false);
    gmt_note("expansions so far", _ms.expansions);

    gmnav_grid_fill_blocked(_mg, 7, 0, 7, 14, true);

    var _steps = gmt_step_until_done(_ms, 4);
    gmt_check("terminates rather than hanging", _steps > 0, true);
    gmt_check("reports stale", gmnav_search_is_stale(_ms), true);
    gmt_note("slices to finish", _steps);
    gmt_note("outcome", _ms.state);

    if (_ms.state == gmnav_state.FOUND) {
        var _mp = gmnav_search_get_path(_ms);
        gmt_note("path length", array_length(_mp));
        gmt_note("blocked nodes on path", gmt_path_blocked_count(_mg, _mp));
    }

    var _cs2 = gmnav_search_create(_mg);
    gmnav_search_begin(_cs2, gmnav_grid_node(_mg, 0, 7), gmnav_grid_node(_mg, 14, 7));
    gmt_check("post-edit search is not stale", gmnav_search_is_stale(_cs2), false);

    gmt_head("Y4 a fresh search sees the new world");

    var _fs = gmnav_search_create(_mg);
    gmnav_search_begin(_fs, gmnav_grid_node(_mg, 0, 7), gmnav_grid_node(_mg, 14, 7));
    gmt_check("sealed wall refuses", gmnav_search_step(_fs, 100000), gmnav_state.FAILED);

    gmnav_grid_set_blocked(_mg, 7, 7, false);

    var _ds = gmnav_search_create(_mg);
    gmnav_search_begin(_ds, gmnav_grid_node(_mg, 0, 7), gmnav_grid_node(_mg, 14, 7));
    gmt_check("door reopens the route", gmnav_search_step(_ds, 100000), gmnav_state.FOUND);
    gmt_check("no blocked nodes", gmt_path_blocked_count(_mg, gmnav_search_get_path(_ds)), 0);
    gmt_check("goes through the door",
              gmt_path_visits(_mg, gmnav_search_get_path(_ds), 7, 7), true);

    gmt_head("Y5 staleness reaches tickets");

    var _sg = gmt_big_open();
    var _sc = gmnav_scheduler_create(_sg, 10, 2);

    var _t1 = gmnav_scheduler_request(_sc, gmnav_grid_node(_sg, 0, 0),
                                           gmnav_grid_node(_sg, 14, 14));
    gmnav_scheduler_update(_sc);
    gmt_check("still working", _t1.state, gmnav_state.WORKING);

    gmnav_grid_set_blocked(_sg, 6, 6, true);

    var _f = gmt_drain_scheduler(_sc, [_t1]);
    gmt_check("ticket resolves", _f > 0, true);
    gmt_note("frames", _f);
    gmt_check("ticket found", _t1.state, gmnav_state.FOUND);
    gmt_check("ticket flagged stale", _t1.stale, true);

    var _t2 = gmnav_scheduler_request(_sc, gmnav_grid_node(_sg, 0, 0),
                                           gmnav_grid_node(_sg, 14, 14));
    gmt_drain_scheduler(_sc, [_t2]);
    gmt_check("later ticket found", _t2.state, gmnav_state.FOUND);
    gmt_check("later ticket not stale", _t2.stale, false);

    gmt_head("Y6 clearance rebuild after edits");

    var _kg = gmt_big_open();
    gmnav_clearance_build(_kg);
    gmt_check("fresh", gmnav_clearance_is_stale(_kg), false);
    gmt_check("open interior", gmnav_clearance_at(_kg, gmnav_grid_node(_kg, 7, 7)), 8);

    gmnav_grid_set_blocked(_kg, 7, 5, true);
    gmt_check("stale after edit", gmnav_clearance_is_stale(_kg), true);

    gmnav_clearance_build_if_stale(_kg);
    gmt_check("rebuilt", gmnav_clearance_is_stale(_kg), false);
    gmt_check("clearance dropped", gmnav_clearance_at(_kg, gmnav_grid_node(_kg, 7, 7)), 2);

    var _mism = 0;
    for (var _c = 0; _c < 15; _c++) {
        for (var _r = 0; _r < 15; _r++) {
            if (gmnav_clearance_at(_kg, gmnav_grid_node(_kg, _c, _r))
             != gmt_clearance_bruteforce(_kg, _c, _r, 8)) _mism++;
        }
    }
    gmt_check("rebuild matches brute force", _mism, 0);

    gmnav_grid_set_blocked(_kg, 7, 9, true);
    var _ks = gmnav_search_create(_kg);
    gmnav_search_begin(_ks, gmnav_grid_node(_kg, 0, 7),
                            gmnav_grid_node(_kg, 14, 7), false, undefined, 2);
    gmt_check("clearance auto-rebuilt by begin", gmnav_clearance_is_stale(_kg), false);
    gmt_check("solves", gmnav_search_step(_ks, 100000), gmnav_state.FOUND);

    gmt_head("Y7 agent survives a moving world");

    var _ag_grid  = gmt_big_open();
    var _ag_sched = gmnav_scheduler_create(_ag_grid, 5000, 2);
    var _ag = gmnav_agent_create(_ag_sched, 16, 240, 8, 2);

    gmnav_agent_goto(_ag, 464, 240, gmnav_priority.IMMEDIATE);
    gmnav_agent_update(_ag);
    gmt_check("has path", gmnav_agent_has_path(_ag), true);

    for (var i = 0; i < 30; i++) {
        gmnav_agent_update(_ag);
        _ag.x += _ag.vx;
        _ag.y += _ag.vy;
    }
    var _mid_x = _ag.x;
    gmt_check("agent has moved", _mid_x > 16, true);

    gmnav_grid_fill_blocked(_ag_grid, 8, 0, 8, 12, true);
    _ag.path.stale = true;

    var _rf = gmt_run_agent(_ag, 1200);
    gmt_check("still arrives", _rf > 0, true);
    gmt_note("frames after replan", _rf);
    gmt_check("reached goal", gmt_agent_dist(_ag, 464, 240) < 8, true);
    gmt_check("arrived latched", gmnav_agent_arrived(_ag), true);
}

function gmt_test_sched_domains() {
    gmt_head("Z1 domain detection");

    var _grid = gmt_maze();
    var _gs   = gmnav_scheduler_create(_grid, 100, 2);
    gmt_check("grid domain", _gs.domain, gmnav_domain.GRID);
    gmt_check("grid target", _gs.target == _grid, true);
    gmt_check("grid alias", _gs.grid == _grid, true);

    var _pgd = gmt_gap_level(16, 2);
    var _pg  = gmnav_platgraph_create(_pgd, gmt_mover());
    gmnav_platgraph_bake(_pg);

    var _ps = gmnav_scheduler_create(_pg, 100, 4);
    gmt_check("platform domain", _ps.domain, gmnav_domain.PLATFORM);
    gmt_check("platform target", _ps.target == _pg, true);
    gmt_check("underlying grid exposed", _ps.grid == _pgd, true);
    gmt_check("concurrency capped by slots", _ps.concurrent, 2);

    gmt_head("Z2 platformer request, immediate");

    var _t = gmnav_scheduler_request(_ps, 0, 13, gmnav_priority.IMMEDIATE);
    gmt_check("resolved", _t.state, gmnav_state.FOUND);
    gmt_check("path returned", array_length(gmnav_scheduler_get_path(_t)) > 0, true);
    gmt_check("links returned",
              array_length(gmnav_scheduler_get_links(_t)),
              array_length(gmnav_scheduler_get_path(_t)));
    gmt_check("crosses by jumping",
              gmt_has_link(gmnav_scheduler_get_links(_t), gmnav_link.JUMP), true);
    gmt_check("not stale", _t.stale, false);
    gmt_note("path", gmt_arr_str(gmnav_scheduler_get_path(_t)));

    var _bare = gmnav_graphsearch_create(_pg);
    gmnav_graphsearch_solve(_bare, 0, 13);
    gmt_check("matches bare search",
              gmt_arr_str(gmnav_scheduler_get_path(_t)),
              gmt_arr_str(gmnav_graphsearch_get_path(_bare)));

    gmt_head("Z3 platformer under budget");

    var _bs = gmnav_scheduler_create(_pg, 3, 2);
    var _q1 = gmnav_scheduler_request(_bs, 0, 13);
    var _q2 = gmnav_scheduler_request(_bs, 13, 0);
    var _q3 = gmnav_scheduler_request(_bs, 0, 9);

    gmt_check("three pending", gmnav_scheduler_pending(_bs), 3);

    var _f = gmt_drain_scheduler(_bs, [_q1, _q2, _q3]);
    gmt_check("drains", _f > 0, true);
    gmt_note("frames", _f);
    gmt_check("q1 found", _q1.state, gmnav_state.FOUND);
    gmt_check("q2 found", _q2.state, gmnav_state.FOUND);
    gmt_check("q3 found", _q3.state, gmnav_state.FOUND);
    gmt_check("q1 has links", array_length(_q2.links) > 0, true);

    gmt_head("Z4 impossible and cancelled requests");

    var _far = gmnav_platgraph_create(gmt_gap_level(24, 8), gmt_mover());
    gmnav_platgraph_bake(_far);
    var _fs = gmnav_scheduler_create(_far, 100, 2);

    var _imp = gmnav_scheduler_request(_fs, 0, 15, gmnav_priority.IMMEDIATE);
    gmt_check("impossible fails", _imp.state, gmnav_state.FAILED);
    gmt_check("no path", array_length(gmnav_scheduler_get_path(_imp)), 0);

    var _oob = gmnav_scheduler_request(_fs, 0, 9999, gmnav_priority.IMMEDIATE);
    gmt_check("out of range fails", _oob.state, gmnav_state.FAILED);

    var _cs = gmnav_scheduler_create(_pg, 2, 2);
    var _c1 = gmnav_scheduler_request(_cs, 0, 13);
    var _c2 = gmnav_scheduler_request(_cs, 13, 0);
    gmnav_scheduler_update(_cs);
    gmnav_scheduler_cancel(_cs, _c1);

    var _cf = gmt_drain_scheduler(_cs, [_c2]);
    gmt_check("survivor resolves", _c2.state, gmnav_state.FOUND);
    gmt_note("frames after cancel", _cf);

    gmt_head("Z5 grid domain unaffected");

    var _rg = gmt_maze();
    var _rs = gmnav_scheduler_create(_rg, 5, 2);
    var _r1 = gmnav_scheduler_request(_rs, 0, 4);
    var _r2 = gmnav_scheduler_request(_rs, 20, 4);
    var _r3 = gmnav_scheduler_request(_rs, 24, 0);

    var _rf = gmt_drain_scheduler(_rs, [_r1, _r2, _r3]);
    gmt_check("drains in ten frames", _rf, 10);
    gmt_check_arr("path unchanged", gmnav_scheduler_get_path(_r1),
                  [0,6,11,16,21,22,23,19,14,9,4]);
    gmt_check("no links on grid domain", array_length(gmnav_scheduler_get_links(_r1)), 0);
    gmt_check("none stale", _r1.stale || _r2.stale || _r3.stale, false);
}