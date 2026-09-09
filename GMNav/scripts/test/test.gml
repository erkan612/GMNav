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

function gmt_test_platagent() {
    gmt_head("P9 platform agent");

    var _g  = gmt_gap_level(16, 2);
    var _pg = gmnav_platgraph_create(_g, gmt_mover());
    gmnav_platgraph_bake(_pg);

    var _sc = gmnav_scheduler_create(_pg, 4000);

    var _w0 = gmnav_platgraph_node_world(_pg, 0);
    var _pa = gmnav_platagent_create(_sc, _w0[0], _w0[1]);

    // construction and contract
    gmt_check("snapped to a node",        _pa.node, 0);
    gmt_check("no goal at rest",          _pa.has_goal, false);
    gmt_check("not arrived at rest",      gmnav_platagent_arrived(_pa), false);
    gmt_check("not airborne at rest",     gmnav_platagent_airborne(_pa), false);
    gmt_check("desync starts at zero",    _pa.desync, 0);

    var _ix = _pa.x;
    var _iy = _pa.y;
    repeat (5) gmnav_platagent_update(_pa);
    gmt_check("idle agent does not drift", (_pa.x == _ix && _pa.y == _iy), true);

    gmt_check("goto off the map refused",
              gmnav_platagent_goto(_pa, -9999, -9999), false);

    // a route that is walking only
    var _w3 = gmnav_platgraph_node_world(_pg, 3);
    gmt_check("goto accepted", gmnav_platagent_goto(_pa, _w3[0], _w3[1]), true);
    gmt_check("has goal", _pa.has_goal, true);

    var _r = { airborne : false, frames : -1 };
    var _f = gmt_platagent_run_watch(_sc, _pa, _r);
    gmt_note("walk route frames", _f);

    gmt_check("walk route arrives",       (_f > 0), true);
    gmt_check("landed on the goal node",  _pa.node, 3);
    gmt_check("never airborne walking",   _r.airborne, false);
    gmt_check("arrival latch holds",      gmnav_platagent_arrived(_pa), true);

    // a route that needs a jump
    var _w13 = gmnav_platgraph_node_world(_pg, 13);
    gmnav_platagent_goto(_pa, _w13[0], _w13[1]);
    gmt_check("goto clears the latch", gmnav_platagent_arrived(_pa), false);

    _r = { airborne : false, frames : -1 };
    _f = gmt_platagent_run_watch(_sc, _pa, _r);
    gmt_note("jump route frames", _f);

    gmt_check("jump route arrives",     (_f > 0), true);
    gmt_check("reached the far side",   _pa.node, 13);
    gmt_check("went airborne crossing", _r.airborne, true);
    gmt_check("no desyncs",             _pa.desync, 0);

    // stop clears everything
    gmnav_platagent_goto(_pa, _w0[0], _w0[1]);
    gmnav_platagent_stop(_pa);
    gmt_check("stop clears the goal",  _pa.has_goal, false);
    gmt_check("stop clears the latch", gmnav_platagent_arrived(_pa), false);

    // retargeting mid arc must not desync
    gmnav_platagent_goto(_pa, _w0[0], _w0[1]);

    var _guard = 0;
    while (!gmnav_platagent_airborne(_pa) && _guard++ < 200) {
        gmnav_scheduler_update(_sc);
        gmnav_platagent_update(_pa);
    }
    gmt_check("got airborne to retarget from", gmnav_platagent_airborne(_pa), true);

    gmnav_platagent_goto(_pa, _w3[0], _w3[1]);
    _f = gmt_platagent_run(_sc, _pa);
    gmt_note("mid arc retarget frames", _f);

    gmt_check("mid arc retarget arrives", (_f > 0), true);
    gmt_check("mid arc retarget lands right", _pa.node, 3);
    gmt_check("still no desyncs", _pa.desync, 0);
	
	gmt_head("P9b platform agent, falls and failures");

    var _sg  = gmt_shelf_level();
    var _spg = gmnav_platgraph_create(_sg, gmt_mover());
    gmnav_platgraph_bake(_spg);

    var _ssc = gmnav_scheduler_create(_spg, 4000);

    var _s0  = gmnav_platgraph_node_world(_spg, 0);
    var _sa  = gmnav_platagent_create(_ssc, _s0[0], _s0[1]);

    var _s15 = gmnav_platgraph_node_world(_spg, 15);
    gmt_check("goto down accepted",
              gmnav_platagent_goto(_sa, _s15[0], _s15[1]), true);

    var _sr = { airborne : false, fell : false, jumped : false, frames : -1 };
    var _sf = gmt_platagent_run_watch(_ssc, _sa, _sr);
    gmt_note("descent frames", _sf);

    gmt_check("descent arrives",           (_sf > 0), true);
    gmt_check("descent reaches the floor",  _sa.node, 15);
    gmt_check("traversed a FALL link",      _sr.fell, true);
    gmt_check("descent has no desyncs",     _sa.desync, 0);

    gmnav_platagent_goto(_sa, _s0[0], _s0[1]);
    repeat (60) {
        gmnav_scheduler_update(_ssc);
        gmnav_platagent_update(_sa);
    }

    gmt_check("unreachable goal fails",        _sa.failed, true);
    gmt_check("failure clears the goal",       _sa.has_goal, false);
    gmt_check("failure does not latch",        gmnav_platagent_arrived(_sa), false);
    gmt_check("agent stayed where it was",     _sa.node, 15);
	
    gmt_head("P9c stopping mid arc");

    var _c0  = gmnav_platgraph_node_world(_pg, 0);
    var _c13 = gmnav_platgraph_node_world(_pg, 13);
    var _c3  = gmnav_platgraph_node_world(_pg, 3);
    var _cp  = gmnav_platagent_create(_sc, _c0[0], _c0[1]);

    gmnav_platagent_goto(_cp, _c13[0], _c13[1]);

    var _cg = 0;
    while (!gmnav_platagent_airborne(_cp) && _cg++ < 200) {
        gmnav_scheduler_update(_sc);
        gmnav_platagent_update(_cp);
    }
    gmt_check("airborne before stop", gmnav_platagent_airborne(_cp), true);

    gmnav_platagent_stop(_cp);

    gmt_check("stop leaves ground mode", _cp.mode, gmnav_pmode.GROUND);
    gmt_check("stop clears the link",    is_undefined(_cp.link), true);
    gmt_check("stop is not airborne",    gmnav_platagent_airborne(_cp), false);
    gmt_check("x agrees with node",      _cp.x, _pg.node_x[_cp.node]);
    gmt_check("y agrees with node",      _cp.y, _pg.node_y[_cp.node]);

    repeat (10) gmnav_platagent_update(_cp);
    gmt_check("survives updates after stop", _cp.mode, gmnav_pmode.GROUND);

    gmt_check("goto after stop accepted",
              gmnav_platagent_goto(_cp, _c3[0], _c3[1]), true);

    var _cf = gmt_platagent_run(_sc, _cp);
    gmt_note("frames after a mid arc stop", _cf);
    gmt_check("arrives after a mid arc stop", (_cf > 0), true);
    gmt_check("no desyncs after a mid arc stop", _cp.desync, 0);
}

function gmt_test_elevation() {
    gmt_head("E1 height authoring");

    var _g = gmnav_grid_create(10, 10, gmnav_layout_create(gmnav_layout.ORTHO, 32, 32));

    gmt_check("no heights on a fresh grid", gmnav_grid_has_heights(_g), false);
    gmt_check("height reads zero anyway",   gmnav_grid_height(_g, gmnav_grid_node(_g, 4, 4)), 0);

    var _v = _g.version;
    gmnav_grid_set_height(_g, 4, 4, 3);

    gmt_check("heights now present",  gmnav_grid_has_heights(_g), true);
    gmt_check("reads back",           gmnav_grid_height(_g, gmnav_grid_node(_g, 4, 4)), 3);
    gmt_check("neighbour untouched",  gmnav_grid_height(_g, gmnav_grid_node(_g, 5, 4)), 0);
    gmt_check("edit bumps version",   (_g.version > _v), true);

    var _v2 = _g.version;
    gmnav_grid_set_height(_g, 4, 4, 3);
    gmt_check("no-op does not bump", _g.version, _v2);

    gmnav_grid_set_height(_g, 99, 99, 5);
    gmt_check("out of bounds refused", gmnav_grid_has_heights(_g), true);

    gmnav_grid_fill_height(_g, 0, 0, 2, 2, 7);
    gmt_check("fill corner",  gmnav_grid_height(_g, gmnav_grid_node(_g, 0, 0)), 7);
    gmt_check("fill far end", gmnav_grid_height(_g, gmnav_grid_node(_g, 2, 2)), 7);
    gmt_check("fill stops",   gmnav_grid_height(_g, gmnav_grid_node(_g, 3, 3)), 0);

    gmt_head("E2 heights are ignored unless asked for");

    var _c = gmt_cliff_level();
    var _low  = gmnav_grid_node(_c, 3,  5);
    var _high = gmnav_grid_node(_c, 10, 5);

    var _p = gmt_solve_z(_c, _low, _high); // no limits passed
    gmt_check("solves with no limits", is_array(_p), true);
    gmt_check("walks straight up the cliff", gmt_path_max_dz(_c, _p), 3);
    gmt_check("ignores the ramp", gmt_path_uses_ramp(_c, _p), false);

    gmt_head("E3 climb and drop gate the cliff");

    _p = gmt_solve_z(_c, _low, _high, 1, 1);
    gmt_check("climb 1 still solves",    is_array(_p), true);
    gmt_check("climb 1 never steps >1",  gmt_path_max_dz(_c, _p), 1);
    gmt_check("climb 1 uses the ramp",   gmt_path_uses_ramp(_c, _p), true);

    _p = gmt_solve_z(_c, _high, _low, 1, 1);
    gmt_check("coming down uses the ramp too", gmt_path_uses_ramp(_c, _p), true);

    // asymmetric: can leap off a cliff it cannot climb
    _p = gmt_solve_z(_c, _high, _low, 1, 3);
    gmt_check("drop 3 skips the ramp", gmt_path_uses_ramp(_c, _p), false);
    gmt_check("drop 3 takes a 3 step", gmt_path_max_dz(_c, _p), 3);

    _p = gmt_solve_z(_c, _low, _high, 1, 3);
    gmt_check("climb 1 still needs the ramp going up", gmt_path_uses_ramp(_c, _p), true);

    // climb 0 cannot use the ramp either, so the top is sealed
    _p = gmt_solve_z(_c, _low, _high, 0, 3);
    gmt_check("climb 0 seals the plateau", is_undefined(_p), true);

    gmt_head("E4 walking around a cliff is unaffected");

    var _wl = gmnav_grid_node(_c, 3,  5);
    var _wr = gmnav_grid_node(_c, 18, 5);
    _p = gmt_solve_z(_c, _wl, _wr, 1, 1);
    gmt_check("ground route exists",   is_array(_p), true);
    gmt_check("ground route stays flat", gmt_path_max_dz(_c, _p), 0);

    var _tl = gmnav_grid_node(_c, 9,  4);
    var _tr = gmnav_grid_node(_c, 12, 4);
    _p = gmt_solve_z(_c, _tl, _tr, 1, 1);
    gmt_check("plateau route exists",   is_array(_p), true);
    gmt_check("plateau route stays flat", gmt_path_max_dz(_c, _p), 0);

    gmt_head("E5 a flat grid is unchanged by limits");

    var _f  = gmt_big_open();
    var _fa = gmnav_grid_node(_f, 1,  1);
    var _fb = gmnav_grid_node(_f, 13, 13);

    var _pa = gmt_solve_z(_f, _fa, _fb);
    var _pb = gmt_solve_z(_f, _fa, _fb, 0, 0);
    gmt_check("limits change nothing on flat ground",
              gmt_arr_str(_pa), gmt_arr_str(_pb));
	
    gmt_head("E6 flow fields honour climb and drop");

    var _z = gmt_cliff_level();

    var _down = gmt_field_z(_z, 7, 5, 1, 3);    // goal on the ground
    var _up   = gmt_field_z(_z, 8, 3, 1, 3);    // goal on the plateau

    gmt_check("down field builds", gmnav_flowfield_is_ready(_down), true);
    gmt_check("up field builds",   gmnav_flowfield_is_ready(_up),   true);

    gmt_check("plateau reachable coming down", gmt_field_reach_cell(_down, 8, 3), true);
    gmt_check("ground reachable going up",     gmt_field_reach_cell(_up,   7, 5), true);

    var _cd = gmt_field_cost_cell(_down, 8, 3);
    var _cu = gmt_field_cost_cell(_up,   7, 5);
    gmt_note("descend cost", string_format(_cd, 1, 2));
    gmt_note("ascend cost",  string_format(_cu, 1, 2));

    gmt_check("descending is cheaper than ascending", (_cd < _cu), true);

    var _down1 = gmt_field_z(_z, 7, 5, 1, 1);
    gmt_check("drop 1 still reaches the plateau", gmt_field_reach_cell(_down1, 8, 3), true);
    gmt_check("drop 1 makes the descent dearer",
              (gmt_field_cost_cell(_down1, 8, 3) > _cd), true);

    var _up0 = gmt_field_z(_z, 8, 3, 0, 3);
    gmt_check("climb 0 seals the plateau field", gmt_field_reach_cell(_up0, 7, 5), false);

    gmt_head("E7 fields ignore heights unless asked");

    var _pd = gmt_field_z(_z, 7, 5);
    var _pu = gmt_field_z(_z, 8, 3);

    gmt_check("no limits, plateau reachable", gmt_field_reach_cell(_pd, 8, 3), true);
    gmt_check("no limits, ground reachable",  gmt_field_reach_cell(_pu, 7, 5), true);
    gmt_check("no limits, the cliff is symmetric",
              gmt_field_cost_cell(_pd, 8, 3), gmt_field_cost_cell(_pu, 7, 5));

    gmt_head("E8 a flat field is unchanged by limits");

    var _fg = gmt_big_open();
    var _f1 = gmt_field_z(_fg, 2, 2);
    var _f2 = gmt_field_z(_fg, 2, 2, 0, 0);

    gmt_check("flat field cost unchanged",
              gmt_field_cost_cell(_f1, 12, 12), gmt_field_cost_cell(_f2, 12, 12));
    gmt_check("flat field walkable either way",
              gmt_field_walk_failures(_fg, _f2), 0);
			  
    gmt_head("E9 scheduler and agent carry the limits");

    var _eg = gmt_cliff_level();
    var _es = gmnav_scheduler_create(_eg, 8000);

    var _e_low  = gmnav_grid_node(_eg, 3,  5);
    var _e_high = gmnav_grid_node(_eg, 10, 5);

    var _t1 = gmnav_scheduler_request(_es, _e_low, _e_high,
                                      gmnav_priority.IMMEDIATE, false, undefined, 0, 1, 1);
    gmnav_scheduler_update(_es);

    gmt_check("scheduler with limits found", _t1.state, gmnav_state.FOUND);

    var _sp = gmnav_scheduler_get_path(_t1);
    gmt_check("scheduler route never steps >1", gmt_path_max_dz(_eg, _sp), 1);
    gmt_check("scheduler route uses the ramp",  gmt_path_uses_ramp(_eg, _sp), true);

    var _t2 = gmnav_scheduler_request(_es, _e_low, _e_high, gmnav_priority.IMMEDIATE);
    gmnav_scheduler_update(_es);

    var _sp2 = gmnav_scheduler_get_path(_t2);
    gmt_check("scheduler without limits ignores the cliff",
              gmt_path_uses_ramp(_eg, _sp2), false);

    var _wl2 = gmnav_grid_node_to_world(_eg, _e_low);
    var _wh2 = gmnav_grid_node_to_world(_eg, _e_high);

    var _ag = gmnav_agent_create(_es, _wl2[0], _wl2[1], 8, 2);
    _ag.max_climb = 1;
    _ag.max_drop  = 1;

    gmnav_agent_goto(_ag, _wh2[0], _wh2[1], gmnav_priority.IMMEDIATE);
    gmnav_scheduler_update(_es);

    gmt_check("agent ticket found", _ag.ticket.state, gmnav_state.FOUND);

    var _ap = gmnav_scheduler_get_path(_ag.ticket);
    gmt_check("agent route never steps >1", gmt_path_max_dz(_eg, _ap), 1);
    gmt_check("agent route uses the ramp",  gmt_path_uses_ramp(_eg, _ap), true);

    var _ag2 = gmnav_agent_create(_es, _wl2[0], _wl2[1], 8, 2);
    gmnav_agent_goto(_ag2, _wh2[0], _wh2[1], gmnav_priority.IMMEDIATE);
    gmnav_scheduler_update(_es);

    gmt_check("agent without limits walks up the cliff",
              gmt_path_uses_ramp(_eg, gmnav_scheduler_get_path(_ag2.ticket)), false);
	
    gmt_head("E10 smoothing must not undo the limits");

    var _mg = gmt_cliff_level();
    var _ms = gmnav_search_create(_mg);

    gmnav_search_begin(_ms, gmnav_grid_node(_mg, 3, 5),
                            gmnav_grid_node(_mg, 10, 5),
                       false, undefined, 0, 1, 1);

    var _mguard = 0;
    while (_ms.state == gmnav_state.WORKING && _mguard++ < global.gmnav.config.MAX_STEPS) {
        gmnav_search_step(_ms, 4096);
    }
    gmt_check("route found before smoothing", _ms.state, gmnav_state.FOUND);

    var _raw = gmnav_search_get_path(_ms);
    gmt_check("raw route respects climb 1", gmt_path_max_dz(_mg, _raw), 1);
    gmt_note("raw waypoints", array_length(_raw));

    var _mp = gmnav_path_create(_mg, _raw);
    gmnav_path_smooth(_mp, 1, 1);
    gmt_note("smoothed with limits", array_length(_mp.nodes));

    gmt_check("smoothed route respects climb 1",
              gmt_path_line_max_dz(_mg, _mp.nodes), 1);
    gmt_check("smoothed route keeps the ramp",
              gmt_path_uses_ramp(_mg, _mp.nodes), true);

    var _mp2 = gmnav_path_create(_mg, _raw);
    gmnav_path_smooth(_mp2);
    gmt_note("smoothed without limits", array_length(_mp2.nodes));
    gmt_check("no limits still shortcuts the cliff",
              (array_length(_mp2.nodes) < array_length(_mp.nodes)), true);

    var _sg  = gmnav_scheduler_create(_mg, 8000);
    var _sw  = gmnav_grid_node_to_world(_mg, gmnav_grid_node(_mg, 3,  5));
    var _gw2 = gmnav_grid_node_to_world(_mg, gmnav_grid_node(_mg, 10, 5));

    var _sa = gmnav_agent_create(_sg, _sw[0], _sw[1], 8, 2);
    _sa.max_climb = 1;
    _sa.max_drop  = 1;

    gmnav_agent_goto(_sa, _gw2[0], _gw2[1], gmnav_priority.IMMEDIATE);
    gmnav_scheduler_update(_sg);
    gmnav_agent_update(_sa);

    gmt_check("agent smoothed path respects climb 1",
              gmt_path_line_max_dz(_mg, _sa.path.nodes), 1);
	
    gmt_head("E11 simplify on a raw route");

    var _qg = gmt_cliff_level();

    var _qc     = gmt_ramp_path(_qg, 1, 1, false);
    var _before = _qc.count;
    gmnav_path_simplify(_qc, 0.5);
    gmt_note("raw points", _before);
    gmt_note("after simplify at 0.5", _qc.count);
    gmt_check("simplify actually removes points", (_qc.count < _before), true);

    var _tols = [0.01, 0.1, 0.25, 0.5, 0.75, 0.99];
    var _qbad = 0;

    for (var q = 0; q < array_length(_tols); q++) {
        var _qp = gmt_ramp_path(_qg, 1, 1, false);
        gmnav_path_simplify(_qp, _tols[q], 1, 1);

        var _qdz = gmt_path_points_max_dz(_qg, _qp);
        gmt_note("tolerance " + string(_tols[q]),
                 string(_qp.count) + " pts, max dz " + string(_qdz));

        if (_qdz > 1) _qbad++;
    }

    gmt_check("no tolerance breaks climb 1 when limits are passed", _qbad, 0);

    var _qn = gmt_ramp_path(_qg, 1, 1, false);
    gmnav_path_simplify(_qn, 0.99);
    gmt_note("no limits at 0.99", string(_qn.count) + " pts");
    gmt_check("no limits still cuts the cliff",
              (gmt_path_points_max_dz(_qg, _qn) > 1), true);
    
    gmt_head("E12 the step predicate");

    var _pg2 = gmt_cliff_level();

    var _ground = gmnav_grid_node(_pg2, 7,  5);   // foot of the cliff
    var _top    = gmnav_grid_node(_pg2, 8,  5);   // plateau, 3 above
    var _r_low  = gmnav_grid_node(_pg2, 10, 9);   // ramp, z 1
    var _r_mid  = gmnav_grid_node(_pg2, 10, 8);   // ramp, z 2

    gmt_check("no limits, nothing is blocked",
              gmnav_grid_step_blocked(_pg2, _ground, _top, undefined, undefined), false);

    gmt_check("climb 1 refuses the cliff",
              gmnav_grid_step_blocked(_pg2, _ground, _top, 1, 1), true);
    gmt_check("drop 1 refuses it downward too",
              gmnav_grid_step_blocked(_pg2, _top, _ground, 1, 1), true);
    gmt_check("drop 3 allows the descent",
              gmnav_grid_step_blocked(_pg2, _top, _ground, 1, 3), false);
    gmt_check("climb 3 allows the ascent",
              gmnav_grid_step_blocked(_pg2, _ground, _top, 3, 3), false);

    gmt_check("a ramp step is allowed",
              gmnav_grid_step_blocked(_pg2, _r_low, _r_mid, 1, 1), false);
    gmt_check("climb 0 refuses even a ramp",
              gmnav_grid_step_blocked(_pg2, _r_low, _r_mid, 0, 3), true);

    gmt_check("flat ground is never blocked",
              gmnav_grid_step_blocked(_pg2, _ground, gmnav_grid_node(_pg2, 6, 5), 0, 0), false);

    gmt_check("a grid with no heights is never blocked",
              gmnav_grid_step_blocked(gmt_big_open(), 0, 1, 0, 0), false);
	
    gmt_head("E13 smoothing must not clip a corner diagonally");

    var _kg = gmnav_grid_create(12, 12, gmnav_layout_create(gmnav_layout.ORTHO, 32, 32));
    gmnav_grid_fill_height(_kg, 5, 5, 9, 9, 3);       // a plateau block

    var _ka = gmnav_grid_node(_kg, 3, 7);
    var _kb = gmnav_grid_node(_kg, 7, 3);

    gmt_check("the diagonal grazes the corner and is refused",
              __gmnav_path_line_z_ok(_kg, _ka, _kb, 1, 1), false);

    gmt_check("a line well clear of it is allowed",
              __gmnav_path_line_z_ok(_kg, gmnav_grid_node(_kg, 1, 1),
                                          gmnav_grid_node(_kg, 3, 3), 1, 1), true);

    gmt_check("with no limits the corner is fine",
              __gmnav_path_line_z_ok(_kg, _ka, _kb, undefined, undefined), true);
	
    gmt_head("E14 smoothing must respect the agent's body");

    var _bg = gmnav_grid_create(14, 14, gmnav_layout_create(gmnav_layout.ORTHO, 32, 32));
    gmnav_grid_fill_height(_bg, 4, 5, 10, 9, 3);

    var _ba = gmnav_grid_node(_bg, 2,  4);
    var _bb = gmnav_grid_node(_bg, 11, 4);

    gmt_check("zero radius hugs the edge happily",
              __gmnav_path_corridor_ok(_bg, _ba, _bb, 1, 1, 0), true);
    gmt_check("a small body still fits",
              __gmnav_path_corridor_ok(_bg, _ba, _bb, 1, 1, 10), true);
    gmt_check("a large body overlaps the plateau",
              __gmnav_path_corridor_ok(_bg, _ba, _bb, 1, 1, 20), false);

    var _wg = gmnav_grid_create(14, 14, gmnav_layout_create(gmnav_layout.ORTHO, 32, 32));
    gmnav_grid_fill_blocked(_wg, 4, 5, 10, 9, true);

    gmt_check("zero radius clears the wall corner",
              __gmnav_path_corridor_ok(_wg, _ba, _bb, undefined, undefined, 0), true);
    gmt_check("a large body clips the wall",
              __gmnav_path_corridor_ok(_wg, _ba, _bb, undefined, undefined, 20), false);
	
    gmt_head("E15 the body follows the line, not the cell centres");

    var _yg = gmnav_grid_create(14, 14, gmnav_layout_create(gmnav_layout.ORTHO, 32, 32));
    gmnav_grid_fill_height(_yg, 5, 5, 10, 10, 3);

    var _ya = gmnav_grid_node(_yg, 1, 6);
    var _yb = gmnav_grid_node(_yg, 7, 3);

    gmt_check("the bare line is clear",
              __gmnav_path_line_z_ok(_yg, _ya, _yb, 1, 1), true);
    gmt_check("a point sized agent may take it",
              __gmnav_path_corridor_ok(_yg, _ya, _yb, 1, 1, 0), true);
    gmt_check("a radius 10 body clips the corner",
              __gmnav_path_corridor_ok(_yg, _ya, _yb, 1, 1, 10), false);
    gmt_check("radius 4 is narrow enough to pass",
              __gmnav_path_corridor_ok(_yg, _ya, _yb, 1, 1, 4), true);
	
    gmt_head("E16 diagonals must not squeeze past a cliff corner");

    var _dg = gmnav_grid_create(14, 14, gmnav_layout_create(gmnav_layout.ORTHO, 32, 32));
    gmnav_grid_fill_height(_dg, 6, 6, 11, 11, 3);

    var _da = gmnav_grid_node(_dg, 5, 6);
    var _db = gmnav_grid_node(_dg, 6, 5);

    var _dp = gmt_solve_z(_dg, _da, _db, 1, 1);
    gmt_check("a route still exists", is_array(_dp), true);
    gmt_check("but not the one step diagonal", (array_length(_dp) > 2), true);
    gmt_check("and the detour never changes height",
              gmt_path_line_max_dz(_dg, _dp), 0);

    var _dn = gmt_solve_z(_dg, _da, _db);
    gmt_check("with no limits the diagonal is fine", array_length(_dn), 2);
}

function gmt_test_layers() {
    var _mk = function() {
        var _lg = gmnav_layergraph_create(gmt_big_open());

        for (var _c = 0; _c < 5; _c++) {
            gmnav_layergraph_add_node(_lg, _c * 32 + 16, 200, 0);
        }
        for (var _c = 1; _c < 4; _c++) {
            gmnav_layergraph_add_node(_lg, _c * 32 + 16, 140, 1);
        }

        for (var _i = 0; _i < 4; _i++) {
            gmnav_layergraph_link(_lg, _i, _i + 1, gmnav_link.WALK, true);
        }
        for (var _i = 5; _i < 7; _i++) {
            gmnav_layergraph_link(_lg, _i, _i + 1, gmnav_link.WALK, true);
        }
        gmnav_layergraph_link(_lg, 0, 5, gmnav_link.STAIR, true);

        gmnav_layergraph_finish(_lg);
        return _lg;
    };

    gmt_head("G1 a layered graph is just a graph");

    var _lg = _mk();

    gmt_check("node count", _lg.count, 8);
    gmt_check("edge count", array_length(_lg.edge_to), 14);
    gmt_check("road node 2 layer",   gmnav_layergraph_layer(_lg, 2), 0);
    gmt_check("bridge node 6 layer", gmnav_layergraph_layer(_lg, 6), 1);

    // the case a height field cannot express: same x, two surfaces
    gmt_check("road and bridge share a column", (_lg.node_x[2] == _lg.node_x[6]), true);
    gmt_check("but not a height",               (_lg.node_y[2] != _lg.node_y[6]), true);

    gmt_head("G2 gmnav_graphsearch routes it unchanged");

    var _s = gmnav_graphsearch_create(_lg);

    gmt_check("road end to road end", gmnav_graphsearch_solve(_s, 0, 4), true);
    var _p = gmnav_graphsearch_get_path(_s);
    gmt_check("stays on the road", array_length(_p), 5);
    gmt_note("road path", gmt_arr_str(_p));

    gmt_check("road to bridge", gmnav_graphsearch_solve(_s, 4, 7), true);
    _p = gmnav_graphsearch_get_path(_s);
    gmt_note("crossing path", gmt_arr_str(_p));

    gmt_check("crossing uses the stair",
              gmt_has_link(gmnav_graphsearch_get_links(_s), gmnav_link.STAIR), true);
    gmt_check("crossing starts on the road", _p[0], 4);
    gmt_check("crossing ends on the bridge", _p[array_length(_p) - 1], 7);

    gmt_head("G3 layers do not leak into one another");

    // the only stair is at the far end, so getting up is a walk back first
    gmt_check("cannot step straight up under the bridge", (array_length(_p) > 3), true);

    var _iso = gmnav_layergraph_create(gmt_big_open());
    gmnav_layergraph_add_node(_iso, 100, 100, 0);
    gmnav_layergraph_add_node(_iso, 100, 60,  1);
    gmnav_layergraph_finish(_iso);

    var _s3 = gmnav_graphsearch_create(_iso);
    gmt_check("unlinked layers are unreachable", gmnav_graphsearch_solve(_s3, 0, 1), false);
}

function gmt_test_overlay() {
    var _mk = function(_with_bridge) {
        var _g = gmnav_grid_create(12, 12, gmnav_layout_create(gmnav_layout.ORTHO, 32, 32));

        gmnav_grid_fill_blocked(_g, 0, 4, 11, 4, true);
        gmnav_grid_fill_blocked(_g, 0, 6, 11, 6, true);

        if (!_with_bridge) return _g;

        var _ov = gmnav_overlay_create(_g);

        var _d1 = gmnav_overlay_add(_ov, 5, 4, 1);
        var _d2 = gmnav_overlay_add(_ov, 5, 5, 1);
        var _d3 = gmnav_overlay_add(_ov, 5, 6, 1);

        gmnav_overlay_link(_ov, gmnav_grid_node(_g, 5, 3), _d1, gmnav_link.STAIR, true);
        gmnav_overlay_link(_ov, _d3, gmnav_grid_node(_g, 5, 7), gmnav_link.STAIR, true);

        gmnav_overlay_finish(_ov);
        return _g;
    };

    gmt_head("B1 an overlay sits beside the grid, not inside it");

    var _plain = _mk(false);
    gmt_check("a fresh grid has no overlay", gmnav_grid_has_overlay(_plain), false);

    var _g  = _mk(true);
    var _ov = _g.overlay;

    gmt_check("the bridge attaches", gmnav_grid_has_overlay(_g), true);
    gmt_check("three deck cells",    gmnav_overlay_count(_ov), 3);

    var _deck = gmnav_overlay_node_at(_ov, 5, 5, 1);
    gmt_check("deck ids sit past the grid", (_deck >= _g.count), true);
    gmt_check("node_at finds the deck", (_deck != GMNAV_NO_NODE), true);
    gmt_check("nothing on layer 1 elsewhere",
              gmnav_overlay_node_at(_ov, 2, 2, 1), GMNAV_NO_NODE);

    gmt_check("a base node is layer 0",
              gmnav_overlay_layer(_ov, gmnav_grid_node(_g, 5, 5)), 0);
    gmt_check("the deck is layer 1", gmnav_overlay_layer(_ov, _deck), 1);

    gmt_head("B2 the deck and the road are separate surfaces");

    var _north = gmnav_grid_node(_g, 5, 1);
    var _south = gmnav_grid_node(_g, 5, 10);

    var _np = gmnav_grid_node(_plain, 5, 1);
    var _sp = gmnav_grid_node(_plain, 5, 10);
    gmt_check("without the bridge there is no crossing",
              is_undefined(gmt_solve_z(_plain, _np, _sp)), true);

    var _p = gmt_solve_z(_g, _north, _south);
    gmt_check("with the bridge there is", is_array(_p), true);
    gmt_note("crossing", gmt_arr_str(_p));

    gmt_check("the crossing uses the deck",
              (array_get_index(_p, _deck) >= 0), true);
    gmt_check("and not the road cell beneath it",
              (array_get_index(_p, gmnav_grid_node(_g, 5, 5)) < 0), true);

    // traffic along the road is untouched by the bridge overhead
    var _west = gmnav_grid_node(_g, 1,  5);
    var _east = gmnav_grid_node(_g, 10, 5);

    var _r = gmt_solve_z(_g, _west, _east);
    gmt_check("the road still runs", is_array(_r), true);
    gmt_check("passing under the deck, not over it",
              (array_get_index(_r, _deck) < 0), true);
    gmt_check("the road goes through the cell below",
              (array_get_index(_r, gmnav_grid_node(_g, 5, 5)) >= 0), true);
	
    gmt_head("B3 overlay nodes convert to world positions");

    var _t = _g.layout.tile_w;

    var _base65 = gmnav_grid_node(_g, 5, 5);
    var _wb = gmnav_grid_node_to_world(_g, _base65);
    var _wd = gmnav_grid_node_to_world(_g, _deck);

    gmt_check("a base node is unchanged", _wb[0], 5 * _t + _t * 0.5);
    gmt_check("the deck sits over the same column", _wd[0], _wb[0]);
    gmt_check("and the same row, since it is directly above", _wd[1], _wb[1]);

    gmt_head("B4 a path across the bridge has real points");

    var _pp = gmnav_path_create(_g, _p);

    gmt_check("a point per node", _pp.count, array_length(_p));

    var _bad = 0;
    for (var i = 0; i < _pp.count; i++) {
        if (_pp.px[i] < 0 || _pp.px[i] > _g.width  * _t) _bad++;
        if (_pp.py[i] < 0 || _pp.py[i] > _g.height * _t) _bad++;
    }
    gmt_check("no point lands off the map", _bad, 0);

    gmt_note("path length px", string_format(gmnav_path_get_length(_pp), 1, 1));
    gmt_check("the length is sane",
              (gmnav_path_get_length(_pp) > 0
            && gmnav_path_get_length(_pp) < _g.height * _t * 3), true);
	
    gmt_head("B5 the caller names the layer");

    var _wp = gmnav_grid_node_to_world(_g, gmnav_grid_node(_g, 5, 5));
    var _wx = _wp[0];
    var _wy = _wp[1];

    gmt_check("the default layer is 0",
              gmnav_grid_world_to_node(_g, _wx, _wy), gmnav_grid_node(_g, 5, 5));
    gmt_check("layer 0 asked for explicitly matches",
              gmnav_grid_world_to_node(_g, _wx, _wy, 0), gmnav_grid_node(_g, 5, 5));
    gmt_check("layer 1 finds the deck",
              gmnav_grid_world_to_node(_g, _wx, _wy, 1), _deck);

    var _ep = gmnav_grid_node_to_world(_g, gmnav_grid_node(_g, 2, 2));
    gmt_check("layer 1 where there is no deck is nothing",
              gmnav_grid_world_to_node(_g, _ep[0], _ep[1], 1), GMNAV_NO_NODE);
    gmt_check("a layer that does not exist is nothing",
              gmnav_grid_world_to_node(_g, _wx, _wy, 2), GMNAV_NO_NODE);
    gmt_check("a grid with no overlay has no layer 1",
              gmnav_grid_world_to_node(_plain, _wx, _wy, 1), GMNAV_NO_NODE);

    gmt_check("top finds the deck", gmnav_grid_world_to_node_top(_g, _wx, _wy), _deck);
    gmt_check("top falls back to the base",
              gmnav_grid_world_to_node_top(_g, _ep[0], _ep[1]), gmnav_grid_node(_g, 2, 2));
    gmt_check("top on a plain grid is the base",
              gmnav_grid_world_to_node_top(_plain, _wx, _wy), gmnav_grid_node(_plain, 5, 5));
	
    gmt_head("B6 overlays work on every layout");

    // Two rows thick either side of the road, because ISO_STAGGERED can step
    // across a single blocked row on purpose, which N3b already pins down.
    var _mkl = function(_mode, _nb, _bridge) {
        var _gg = gmnav_grid_create(12, 12, gmnav_layout_create(_mode, 32, 32, _nb));

        gmnav_grid_fill_blocked(_gg, 0, 3, 11, 4, true);
        gmnav_grid_fill_blocked(_gg, 0, 6, 11, 7, true);

        if (!_bridge) return _gg;

        var _o = gmnav_overlay_create(_gg);
        var _a = gmnav_overlay_add(_o, 5, 3, 1);
        var _b = gmnav_overlay_add(_o, 5, 4, 1);
        var _c = gmnav_overlay_add(_o, 5, 5, 1);
        var _d = gmnav_overlay_add(_o, 5, 6, 1);
        var _e = gmnav_overlay_add(_o, 5, 7, 1);

        gmnav_overlay_link(_o, gmnav_grid_node(_gg, 5, 2), _a, gmnav_link.STAIR, true);
        gmnav_overlay_link(_o, _e, gmnav_grid_node(_gg, 5, 8), gmnav_link.STAIR, true);

        gmnav_overlay_finish(_o);
        return _gg;
    };

    var _modes = [gmnav_layout.ORTHO,       gmnav_layout.ISO_DIAMOND,
                  gmnav_layout.ISO_STAGGERED, gmnav_layout.HEX_POINTY,
                  gmnav_layout.HEX_FLAT];
    var _mnames = ["ORTHO", "ISO_DIAMOND", "ISO_STAGGERED", "HEX_POINTY", "HEX_FLAT"];

    var _sealed = 0;
    var _crossed = 0;

    for (var m = 0; m < array_length(_modes); m++) {
        var _nb = (m >= 3) ? gmnav_neighbours.SIX : gmnav_neighbours.EIGHT;

        var _no = _mkl(_modes[m], _nb, false);
        var _yes = _mkl(_modes[m], _nb, true);

        var _n1 = gmnav_grid_node(_no,  5, 1);
        var _s1 = gmnav_grid_node(_no,  5, 10);
        var _n2 = gmnav_grid_node(_yes, 5, 1);
        var _s2 = gmnav_grid_node(_yes, 5, 10);

        var _blocked_ok = is_undefined(gmt_solve_z(_no,  _n1, _s1));
        var _cross      = gmt_solve_z(_yes, _n2, _s2);

        if (_blocked_ok) _sealed++;
        if (is_array(_cross)) _crossed++;

        gmt_note(_mnames[m], (_blocked_ok ? "sealed" : "LEAKS")
                           + ", " + (is_array(_cross)
                                     ? string(array_length(_cross)) + " step crossing"
                                     : "NO CROSSING"));
    }

    gmt_check("every layout is sealed without the bridge", _sealed, 5);
    gmt_check("every layout crosses with it",              _crossed, 5);
}

function gmt_test_agent_layers() {
    gmt_head("B7 the agent carries a layer");

    var _g  = gmt_bridge_level();
    var _sc = gmnav_scheduler_create(_g, 8000);

    var _ground = gmnav_grid_node(_g, 5, 1);
    var _deck   = gmnav_grid_world_to_node(_g,
                      gmnav_grid_node_to_world(_g, gmnav_grid_node(_g, 5, 5))[0],
                      gmnav_grid_node_to_world(_g, gmnav_grid_node(_g, 5, 5))[1], 1);

    var _gw = gmnav_grid_node_to_world(_g, _ground);
    var _a  = gmnav_agent_create(_sc, _gw[0], _gw[1], 8, 3);

    gmt_check("a new agent is on layer 0", gmnav_agent_layer(_a), 0);

    gmt_head("B8 it can be sent to a deck");

    var _dw = gmnav_grid_node_to_world(_g, _deck);

    gmt_check("goto with no layer means the ground",
              gmnav_agent_goto(_a, _dw[0], _dw[1], gmnav_priority.IMMEDIATE), true);
    gmnav_scheduler_update(_sc);
    var _p0 = gmnav_scheduler_get_path(_a.ticket);
    gmt_check("so it routes to the road, not the deck",
              (array_get_index(_p0, _deck) < 0), true);

    gmt_check("goto naming layer 1 is accepted",
              gmnav_agent_goto(_a, _dw[0], _dw[1], gmnav_priority.IMMEDIATE, 1), true);
    gmnav_scheduler_update(_sc);
    var _p1 = gmnav_scheduler_get_path(_a.ticket);
    gmt_check("and routes onto the deck",
              (array_get_index(_p1, _deck) >= 0), true);

    gmt_check("a layer with no cell there is refused",
              gmnav_agent_goto(_a, 2 * 32 + 16, 2 * 32 + 16,
                               gmnav_priority.IMMEDIATE, 1), false);

    gmt_head("B9 the layer follows the agent");

    gmnav_agent_goto(_a, _dw[0], _dw[1], gmnav_priority.IMMEDIATE, 1);

    var _r = { layers : [], frames : -1 };
    var _f = gmt_agent_run_layers(_sc, _a, _r);
    gmt_note("frames onto the deck", _f);
    gmt_note("layers visited", gmt_arr_str(_r.layers));

    gmt_check("it arrives", (_f > 0), true);
    gmt_check("and is standing on the deck", gmnav_agent_layer(_a), 1);

    // from the deck, back down to the far side of the road
    var _far = gmnav_grid_node(_g, 5, 10);
    var _fw  = gmnav_grid_node_to_world(_g, _far);

    gmt_check("goto from the deck is accepted",
              gmnav_agent_goto(_a, _fw[0], _fw[1], gmnav_priority.IMMEDIATE), true);
    gmnav_scheduler_update(_sc);

    var _p2 = gmnav_scheduler_get_path(_a.ticket);
    gmt_check("it leaves from the deck, not the road below",
              _p2[0], gmnav_grid_world_to_node(_g, _a.x, _a.y, 1));

    _r = { layers : [], frames : -1 };
    _f = gmt_agent_run_layers(_sc, _a, _r);
    gmt_note("frames back down", _f);
    gmt_note("layers visited", gmt_arr_str(_r.layers));

    gmt_check("it arrives back on the ground", (_f > 0), true);
    gmt_check("on layer 0", gmnav_agent_layer(_a), 0);
	
    gmt_head("B10 smoothing must not shortcut across a layer");

    var _og = gmnav_grid_create(12, 12, gmnav_layout_create(gmnav_layout.ORTHO, 32, 32));

    var _oo = gmnav_overlay_create(_og);
    var _k1 = gmnav_overlay_add(_oo, 5, 4, 1);
    var _k2 = gmnav_overlay_add(_oo, 5, 5, 1);
    var _k3 = gmnav_overlay_add(_oo, 5, 6, 1);

    gmnav_overlay_link(_oo, gmnav_grid_node(_og, 5, 3), _k1, gmnav_link.STAIR, true);
    gmnav_overlay_link(_oo, _k3, gmnav_grid_node(_og, 5, 7), gmnav_link.STAIR, true);
    gmnav_overlay_finish(_oo);

    var _route = [gmnav_grid_node(_og, 5, 2), gmnav_grid_node(_og, 5, 3),
                  _k1, _k2, _k3,
                  gmnav_grid_node(_og, 5, 7), gmnav_grid_node(_og, 5, 8)];

    var _sp = gmnav_path_create(_og, _route);
    gmt_check("seven waypoints before smoothing", _sp.count, 7);

    gmnav_path_smooth(_sp);
    gmt_note("after smoothing", gmt_arr_str(_sp.nodes));

    gmt_check("the deck survives",
              ((array_get_index(_sp.nodes, _k1) >= 0)
            || (array_get_index(_sp.nodes, _k2) >= 0)
            || (array_get_index(_sp.nodes, _k3) >= 0)), true);
    gmt_check("the stair up survives",
              (array_get_index(_sp.nodes, gmnav_grid_node(_og, 5, 3)) >= 0), true);
    gmt_check("the stair down survives",
              (array_get_index(_sp.nodes, gmnav_grid_node(_og, 5, 7)) >= 0), true);

    // within one layer it should still shorten freely
    var _flat = gmnav_path_create(_og, [gmnav_grid_node(_og, 1, 1),
                                        gmnav_grid_node(_og, 2, 1),
                                        gmnav_grid_node(_og, 3, 1),
                                        gmnav_grid_node(_og, 4, 1)]);
    gmnav_path_smooth(_flat);
    gmt_check("a same layer run still collapses", _flat.count, 2);
	
    gmt_head("B12 lifted layers round trip");

    var _lg = gmt_bridge_level();
    gmnav_grid_set_layer_lift(_lg, 20);

    var _lbase = gmnav_grid_node(_lg, 5, 5);
    var _ldeck = gmnav_overlay_node_at(_lg.overlay, 5, 5, 1);

    var _wb = gmnav_grid_node_to_world(_lg, _lbase);
    var _wd = gmnav_grid_node_to_world(_lg, _ldeck);

    gmt_check("same column", _wd[0], _wb[0]);
    gmt_check("the deck is drawn a lift higher", _wb[1] - _wd[1], 20);

    gmt_check("the base point resolves back to the base",
              gmnav_grid_world_to_node(_lg, _wb[0], _wb[1], 0), _lbase);
    gmt_check("the deck point resolves back to the deck",
              gmnav_grid_world_to_node(_lg, _wd[0], _wd[1], 1), _ldeck);
    gmt_check("topmost picks the deck",
              gmnav_grid_world_to_node_top(_lg, _wd[0], _wd[1]), _ldeck);

    var _lp = gmnav_path_create(_lg, [_lbase, _ldeck]);
    gmt_check("path points carry the lift", _lp.py[0] - _lp.py[1], 20);

    gmnav_grid_set_layer_lift(_lg, 0);
    gmt_check("with no lift they coincide",
              gmnav_grid_node_to_world(_lg, _ldeck)[1],
              gmnav_grid_node_to_world(_lg, _lbase)[1]);
}

function gmt_test_demo5_level() {
    gmt_head("B11 the demo 5 level");

    var _lay = gmnav_layout_create(gmnav_layout.ISO_DIAMOND, 64, 32);
    var _g   = gmnav_grid_create(20, 20, _lay);
    demo5_build_level(_g);

    gmt_check("the bridges attached", gmnav_grid_has_overlay(_g), true);
    gmt_check("six deck cells", gmnav_overlay_count(_g.overlay), 6);

    var _north = gmnav_grid_node(_g, 10, 4);
    var _south = gmnav_grid_node(_g, 10, 15);

    var _p = gmt_solve_z(_g, _north, _south);
    gmt_check("north reaches south", is_array(_p), true);
    gmt_note("crossing", string(array_length(_p)) + " steps");

    var _da = demo5_deck_at(_g, DEMO5_BRIDGE_A, DEMO5_ROAD_R);
    var _db = demo5_deck_at(_g, DEMO5_BRIDGE_B, DEMO5_ROAD_R);

    gmt_check("over one of the bridges",
              ((array_get_index(_p, _da) >= 0) || (array_get_index(_p, _db) >= 0)), true);
    gmt_check("and not through the road",
              (array_get_index(_p, gmnav_grid_node(_g, 10, DEMO5_ROAD_R)) < 0), true);

    // the road runs the full width underneath, untouched by either bridge
    var _r = gmt_solve_z(_g, gmnav_grid_node(_g, 1,  DEMO5_ROAD_R),
                             gmnav_grid_node(_g, 18, DEMO5_ROAD_R));
    gmt_check("the road runs end to end", is_array(_r), true);
    gmt_check("passing under both decks",
              ((array_get_index(_r, _da) < 0) && (array_get_index(_r, _db) < 0)), true);
    gmt_check("in a straight line", array_length(_r), 18);

    // the nearer bridge should win from either side
    var _wp = gmt_solve_z(_g, gmnav_grid_node(_g, 3, 4), gmnav_grid_node(_g, 3, 15));
    gmt_check("the west route uses bridge A", (array_get_index(_wp, _da) >= 0), true);

    var _ep = gmt_solve_z(_g, gmnav_grid_node(_g, 17, 4), gmnav_grid_node(_g, 17, 15));
    gmt_check("the east route uses bridge B", (array_get_index(_ep, _db) >= 0), true);
}

function gmt_test_demo6_level() {
    gmt_head("B13 the demo 6 level");

    var _g = gmnav_grid_create(DEMO6_W, DEMO6_H,
                               gmnav_layout_create(gmnav_layout.ISO_DIAMOND, 64, 32));
    demo6_build_level(_g);
    gmnav_grid_set_layer_lift(_g, DEMO6_LIFT);

    gmt_check("three levels of elevation", _g.overlay.max_layer, 2);
    gmt_note("deck cells", gmnav_overlay_count(_g.overlay));

    // the river is the only crossing
    var _west = gmnav_grid_node(_g, 4,  20);
    var _east = gmnav_grid_node(_g, 28, 20);

    var _p = gmt_solve_z(_g, _west, _east);
    gmt_check("west reaches east", is_array(_p), true);
    gmt_check("only over the river crossing",
              (array_get_index(_p, demo6_deck_at(_g, DEMO6_RIVER_C1, DEMO6_XING_R)) >= 0),
              true);

    // the flyover: over it and under it
    var _fw = gmnav_grid_node(_g, DEMO6_FLY_C1 - 1, DEMO6_FLY_R);
    var _fe = gmnav_grid_node(_g, DEMO6_FLY_C2 + 1, DEMO6_FLY_R);
    var _fd = demo6_deck_at(_g, DEMO6_FLY_C1 + 1, DEMO6_FLY_R);

    gmt_check("you can get onto the flyover", is_array(gmt_solve_z(_g, _fw, _fd)), true);

    var _under = gmt_solve_z(_g, _fw, _fe);
    gmt_check("and across underneath it", is_array(_under), true);
    gmt_check("the underneath route ignores the deck",
              (array_get_index(_under, _fd) < 0), true);

    // a bridge is open below, a cliff is not
    gmt_check("the flyover is open below",
              gmnav_grid_is_blocked(_g,
                  gmnav_grid_node(_g, DEMO6_FLY_C1 + 1, DEMO6_FLY_R)), false);
    gmt_check("the cliff is solid at ground level",
              gmnav_grid_is_blocked(_g, gmnav_grid_node(_g, 23, 10)), true);

    // the cliff, and the cliff on the cliff
    var _cliff = demo6_deck_at(_g, 23, DEMO6_CLIFF_R1, 1);
    var _peak  = demo6_deck_at(_g, 23, DEMO6_PEAK_R1,  2);

    var _cp = gmt_solve_z(_g, _east, _cliff);
    gmt_check("the cliff is reachable", is_array(_cp), true);
    gmt_check("by its ramp",
              (array_get_index(_cp, demo6_deck_at(_g, 23, DEMO6_CLIFF_R2, 1)) >= 0), true);

    var _pp = gmt_solve_z(_g, _east, _peak);
    gmt_check("the upper cliff is reachable", is_array(_pp), true);
    gmt_check("only through the lower one",
              (array_get_index(_pp, demo6_deck_at(_g, 23, DEMO6_PEAK_R2 + 1, 1)) >= 0),
              true);
    gmt_note("ground to the peak", string(array_length(_pp)) + " steps");

    // and you walk around the cliff, not through it
    var _behind = gmt_solve_z(_g, gmnav_grid_node(_g, 19, 3),
                                  gmnav_grid_node(_g, 28, 3));
    gmt_check("you can walk behind the cliff", is_array(_behind), true);
    gmt_check("without passing through it",
              (array_get_index(_behind, gmnav_grid_node(_g, 23, 10)) < 0), true);
	
    gmt_check("the peak is solid at deck level",
              demo6_deck_at(_g, 23, DEMO6_PEAK_R1 + 1, 1), GMNAV_NO_NODE);

    // crossing the cliff top has to go around the peak, not through it
    var _across = gmt_solve_z(_g, demo6_deck_at(_g, DEMO6_CLIFF_C1, DEMO6_PEAK_R1, 1),
                                  demo6_deck_at(_g, DEMO6_CLIFF_C2, DEMO6_PEAK_R1, 1));
    gmt_check("you can cross the cliff top", is_array(_across), true);
    gmt_check("without passing through the peak",
              (array_get_index(_across,
                   demo6_deck_at(_g, 23, DEMO6_PEAK_R1 + 1, 1)) < 0), true);
}

function gmt_test_costmode() {
    gmt_head("V1 non square tiles and cost mode");

    // a three quarter view tile: 32 wide, 24 tall
    var _log = gmnav_layout_create(gmnav_layout.ORTHO, 32, 24, gmnav_neighbours.EIGHT,
                                   gmnav_costmode.LOGICAL);
    var _vis = gmnav_layout_create(gmnav_layout.ORTHO, 32, 24, gmnav_neighbours.EIGHT,
                                   gmnav_costmode.VISUAL);

    gmt_note("true diagonal px", string_format(point_distance(0, 0, 32, 24), 1, 2));

    var _lh = gmt_nb_cost(_log, 1, 0);
    var _lv = gmt_nb_cost(_log, 0, 1);
    var _ld = gmt_nb_cost(_log, 1, 1);
    gmt_note("logical h / v / d",
             string_format(_lh, 1, 3) + " / " + string_format(_lv, 1, 3)
           + " / " + string_format(_ld, 1, 3));

    gmt_check("logical ignores tile shape", _lh, _lv);
    gmt_check("logical diagonal is root 2", (abs(_ld / _lh - 1.414214) < 0.001), true);

    var _vh = gmt_nb_cost(_vis, 1, 0);
    var _vv = gmt_nb_cost(_vis, 0, 1);
    var _vd = gmt_nb_cost(_vis, 1, 1);
    gmt_note("visual h / v / d",
             string_format(_vh, 1, 3) + " / " + string_format(_vv, 1, 3)
           + " / " + string_format(_vd, 1, 3));

    gmt_check("visual vertical is cheaper", (_vv < _vh), true);
    gmt_check("visual matches the tile ratio", (abs(_vv / _vh - 24 / 32) < 0.001), true);
    gmt_check("visual diagonal is the real length",
              (abs(_vd / _vh - point_distance(0, 0, 32, 24) / 32) < 0.001), true);

    // square tiles must behave identically in both modes, or switching to VISUAL for a three quarter view would change every other project
    var _sq_l = gmnav_layout_create(gmnav_layout.ORTHO, 32, 32,
                                    gmnav_neighbours.EIGHT, gmnav_costmode.LOGICAL);
    var _sq_v = gmnav_layout_create(gmnav_layout.ORTHO, 32, 32,
                                    gmnav_neighbours.EIGHT, gmnav_costmode.VISUAL);

    gmt_check("square tiles agree, cardinal",
              (abs(gmt_nb_cost(_sq_v, 1, 0) / gmt_nb_cost(_sq_l, 1, 0) - 1) < 0.001), true);
    gmt_check("square tiles agree, diagonal",
              (abs(gmt_nb_cost(_sq_v, 1, 1) / gmt_nb_cost(_sq_l, 1, 1) - 1) < 0.001), true);

    // and it bends a real route: on a squashed tile a vertical detour can beat a straight horizontal run
    var _g = gmnav_grid_create(12, 12, _vis);
    var _p = gmt_solve_z(_g, gmnav_grid_node(_g, 1, 6), gmnav_grid_node(_g, 10, 6));
    gmt_check("a route still solves on squashed tiles", is_array(_p), true);
    gmt_note("squashed run", string(array_length(_p)) + " steps");
}

function gmt_test_demo7_level() {
    gmt_head("Q1 the demo 7 level");

    var _g = demo7_make_grid();

    gmt_check("three levels of elevation", _g.overlay.max_layer, 2);
    gmt_note("deck cells", gmnav_overlay_count(_g.overlay));

    // the river seals, the crossing is the only way through
    var _p = gmt_solve_z(_g, gmnav_grid_node(_g, 20, 8),
                             gmnav_grid_node(_g, 20, 18));
    gmt_check("north reaches south", is_array(_p), true);
    gmt_check("only over the crossing",
              (array_get_index(_p, demo7_deck_at(_g, DEMO7_XING_C, DEMO7_RIVER_R1)) >= 0),
              true);

    // the flyover: over it, and under it
    var _fw = gmnav_grid_node(_g, DEMO7_FLY_C1 - 1, DEMO7_FLY_R);
    var _fe = gmnav_grid_node(_g, DEMO7_FLY_C2 + 1, DEMO7_FLY_R);
    var _fd = demo7_deck_at(_g, DEMO7_FLY_C1 + 2, DEMO7_FLY_R);

    gmt_check("you can get onto it", is_array(gmt_solve_z(_g, _fw, _fd)), true);
    gmt_check("the ground below it is open",
              gmnav_grid_is_blocked(_g,
                  gmnav_grid_node(_g, DEMO7_FLY_C1 + 2, DEMO7_FLY_R)), false);

    // end to end along the row, the deck is a straight line between the two points, so A* takes it. expected behaviour, correctly
    var _along = gmt_solve_z(_g, _fw, _fe);
    gmt_check("along the row it uses the deck",
              (array_get_index(_along, _fd) >= 0), true);

    // crossing the row instead, the deck is off the line, so the route passes underneath it
    var _cross = gmt_solve_z(_g, gmnav_grid_node(_g, DEMO7_FLY_C1 + 2, DEMO7_FLY_R - 3),
                                 gmnav_grid_node(_g, DEMO7_FLY_C1 + 2, DEMO7_FLY_R + 3));
    gmt_check("crossing the row goes underneath", is_array(_cross), true);
    gmt_check("without touching the deck", (array_get_index(_cross, _fd) < 0), true);
    gmt_check("through the cell below it",
              (array_get_index(_cross,
                   gmnav_grid_node(_g, DEMO7_FLY_C1 + 2, DEMO7_FLY_R)) >= 0), true);

    // the cliff is solid, unlike the flyover
    gmt_check("the cliff is solid below",
              gmnav_grid_is_blocked(_g, gmnav_grid_node(_g, 8, 17)), true);

    var _south = gmnav_grid_node(_g, 20, 18);
    var _cliff = demo7_deck_at(_g, DEMO7_CLIFF_C1, DEMO7_CLIFF_R1, 1);
    var _cp = gmt_solve_z(_g, _south, _cliff);
    gmt_check("the cliff is reachable", is_array(_cp), true);
    gmt_check("by its ramp",
              (array_get_index(_cp, demo7_deck_at(_g, DEMO7_RAMP_C,
                                                  DEMO7_CLIFF_R2, 1)) >= 0), true);

    var _peak = demo7_deck_at(_g, DEMO7_PEAK_C1, DEMO7_PEAK_R1, 2);
    var _pp = gmt_solve_z(_g, _south, _peak);
    gmt_check("the peak is reachable", is_array(_pp), true);
    gmt_check("only through the cliff",
              (array_get_index(_pp, demo7_deck_at(_g, DEMO7_RAMP_C,
                                                  DEMO7_PEAK_R2 + 1, 1)) >= 0), true);
    gmt_note("ground to the peak", string(array_length(_pp)) + " steps");

    // you walk around the cliff, not through it
    var _round = gmt_solve_z(_g, gmnav_grid_node(_g, 2, 17),
                                 gmnav_grid_node(_g, 20, 17));
    gmt_check("you can get around the cliff", is_array(_round), true);
    gmt_check("without passing through it",
              (array_get_index(_round, gmnav_grid_node(_g, 8, 17)) < 0), true);
}

function gmt_test_overlay_cells() {
    gmt_head("B14 an overlay cell is a real cell");

    var _g  = gmt_bridge_level();
    var _ov = _g.overlay;
    var _d1 = gmnav_overlay_node_at(_ov, 5, 4, 1);
    var _d2 = gmnav_overlay_node_at(_ov, 5, 5, 1);
    var _d3 = gmnav_overlay_node_at(_ov, 5, 6, 1);

    gmt_check("a deck cell starts unblocked", gmnav_grid_is_blocked(_g, _d2), false);
    gmt_check("and at base cost", gmnav_grid_cost(_g, _d2), 1);

    gmt_head("B15 a collapsed span");

    gmt_check("blocking is accepted", gmnav_overlay_set_blocked(_ov, _d2, true), true);
    gmt_check("it reads back blocked", gmnav_grid_is_blocked(_g, _d2), true);
    gmt_check("its neighbours are not", gmnav_grid_is_blocked(_g, _d1), false);
    gmt_check("the road below is untouched",
              gmnav_grid_is_blocked(_g, gmnav_grid_node(_g, 5, 5)), false);

    gmnav_overlay_finish(_ov);

    var _north = gmnav_grid_node(_g, 5, 1);
    var _south = gmnav_grid_node(_g, 5, 10);
    gmt_check("the bridge no longer crosses",
              is_undefined(gmt_solve_z(_g, _north, _south)), true);

    gmnav_overlay_set_blocked(_ov, _d2, false);
    gmnav_overlay_finish(_ov);
    gmt_check("unblocking restores it", is_array(gmt_solve_z(_g, _north, _south)), true);

    gmt_head("B16 cost on a deck");

    gmt_check("cost is accepted", gmnav_overlay_set_cost(_ov, _d2, 9), true);
    gmt_check("it reads back", gmnav_grid_cost(_g, _d2), 9);
    gmt_check("the road below is unchanged",
              gmnav_grid_cost(_g, gmnav_grid_node(_g, 5, 5)), 1);

    gmnav_overlay_finish(_ov);

    // a route that must cross gets dearer, since there is no alternative
    var _cheap = gmt_solve_cost(_g, _north, _south);
    gmnav_overlay_set_cost(_ov, _d2, 1);
    gmnav_overlay_finish(_ov);
    var _plain = gmt_solve_cost(_g, _north, _south);

    gmt_note("crossing cost, deck at 9 / at 1",
             string_format(_cheap, 1, 2) + " / " + string_format(_plain, 1, 2));
    gmt_check("an expensive deck costs more to cross", (_cheap > _plain), true);

    gmt_head("B17 clearance on a deck over open ground");

    // a two cell wide deck over a wide open field, so the deck's own width is the only thing that could produce a clearance of 2
    var _og = gmnav_grid_create(14, 14,
                  gmnav_layout_create(gmnav_layout.ORTHO, 32, 32));
    var _oo = gmnav_overlay_create(_og);

    for (var _c = 4; _c <= 9; _c++) {
        gmnav_overlay_add(_oo, _c, 6, 1);
        gmnav_overlay_add(_oo, _c, 7, 1);
    }
    gmnav_overlay_finish(_oo);
    gmnav_clearance_build(_og);

    var _wide = gmnav_overlay_node_at(_oo, 6, 6, 1);
    var _end  = gmnav_overlay_node_at(_oo, 4, 6, 1);

    gmt_note("open ground below", gmnav_clearance_at(_og, gmnav_grid_node(_og, 6, 6)));
    gmt_check("a two wide deck measures 1 at its edge", gmnav_clearance_at(_og, _end), 1);
    gmt_check("and the ground below measures more",
              (gmnav_clearance_at(_og, gmnav_grid_node(_og, 6, 6))
             > gmnav_clearance_at(_og, _wide)), true);
}

function gmt_test_overlay_offset() {
    gmt_head("O1 a cell can sit between layers");

    var _g = gmnav_grid_create(12, 12,
                 gmnav_layout_create(gmnav_layout.ORTHO, 32, 24));
    var _ov = gmnav_overlay_create(_g);
    gmnav_grid_set_layer_lift(_g, 24);

    var _flat = gmnav_overlay_add(_ov, 2, 2, 1);
    var _half = gmnav_overlay_add(_ov, 3, 2, 1);
    gmnav_overlay_finish(_ov);

    gmt_check("a new cell has no offset", gmnav_overlay_offset(_ov, _half), 0);

    gmt_check("setting one is accepted",
              gmnav_overlay_set_offset(_ov, _half, -0.5), true);
    gmt_check("it reads back", gmnav_overlay_offset(_ov, _half), -0.5);

    var _wf = gmnav_grid_node_to_world(_g, _flat);
    var _wh = gmnav_grid_node_to_world(_g, _half);

    gmt_check("a flat cell sits at one lift",
              _wf[1], gmnav_layout_cell_y(_g.layout, 2, 2) - 24);
    gmt_check("an offset cell sits between",
              _wh[1], gmnav_layout_cell_y(_g.layout, 3, 2) - 12);

    gmt_head("O2 the round trip still holds");

    gmt_check("the flat cell resolves back",
              gmnav_grid_world_to_node(_g, _wf[0], _wf[1], 1), _flat);
    gmt_check("the offset cell resolves back",
              gmnav_grid_world_to_node(_g, _wh[0], _wh[1], 1), _half);
    gmt_check("topmost finds the offset cell",
              gmnav_grid_world_to_node_top(_g, _wh[0], _wh[1]), _half);

    gmt_head("O3 a ramp climbing east");

    // six cells on layer 1, offsets stepping from the ground to the top, so
    // the ramp rises smoothly rather than popping at its link
    var _r = gmnav_grid_create(16, 12,
                 gmnav_layout_create(gmnav_layout.ORTHO, 32, 24));
    var _ro = gmnav_overlay_create(_r);
    gmnav_grid_set_layer_lift(_r, 24);

    var _cells = [];
    for (var _c = 4; _c <= 9; _c++) {
        array_push(_cells, gmnav_overlay_add(_ro, _c, 5, 1));
    }
    gmnav_overlay_ramp(_ro, _cells);

    gmnav_overlay_link(_ro, gmnav_grid_node(_r, 3, 5),
                       gmnav_overlay_node_at(_ro, 4, 5, 1),
                       gmnav_link.STAIR, true);
    gmnav_overlay_finish(_ro);

    var _prev = gmnav_grid_node_to_world(_r, gmnav_grid_node(_r, 3, 5))[1];
    var _worst = 0;

    for (var _c = 4; _c <= 9; _c++) {
        var _y = gmnav_grid_node_to_world(_r, gmnav_overlay_node_at(_ro, _c, 5, 1))[1];
        _worst = max(_worst, abs(_y - _prev));
        _prev  = _y;
    }

    gmt_note("largest single step in px", string_format(_worst, 1, 2));
    gmt_check("no step is a whole lift", (_worst < 24), true);
    gmt_check("the ramp ends at full height",
              gmnav_grid_node_to_world(_r, gmnav_overlay_node_at(_ro, 9, 5, 1))[1],
              gmnav_layout_cell_y(_r.layout, 9, 5) - 24);

    // and a path across it carries those heights
    var _p = gmnav_path_create(_r, [gmnav_grid_node(_r, 3, 5),
                                    gmnav_overlay_node_at(_ro, 4, 5, 1),
                                    gmnav_overlay_node_at(_ro, 9, 5, 1)]);
    gmt_check("path points climb", (_p.py[0] > _p.py[2]), true);
}

function gmt_test_demo8_level() {
    gmt_head("R1 four ramps, one per side");

    var _g = demo8_make_grid();
    var _ov = _g.overlay;

    gmt_check("one layer", _ov.max_layer, 1);
    gmt_note("deck cells", gmnav_overlay_count(_ov));

    var _top = demo8_deck_at(_g, 17, 14);
    gmt_check("the plateau exists", (_top != GMNAV_NO_NODE), true);
    gmt_check("solid at ground level",
              gmnav_grid_is_blocked(_g, gmnav_grid_node(_g, 17, 14)), true);

    // one approach from each side, all four reaching the top
    var _feet = [[15, DEMO8_PLAT_R2 + DEMO8_RAMP_LEN + 1],
                 [20, DEMO8_PLAT_R1 - DEMO8_RAMP_LEN - 1],
                 [DEMO8_PLAT_C1 - DEMO8_RAMP_LEN - 1, 12],
                 [DEMO8_PLAT_C2 + DEMO8_RAMP_LEN + 1, 17]];
    var _names = ["south", "north", "west", "east"];
    var _ok = 0;

    for (var i = 0; i < 4; i++) {
        var _p = gmt_solve_z(_g, gmnav_grid_node(_g, _feet[i][0], _feet[i][1]), _top);
        if (is_array(_p)) _ok++;
        gmt_note(_names[i], is_array(_p) ? string(array_length(_p)) + " steps"
                                         : "NO ROUTE");
    }
    gmt_check("all four sides reach the top", _ok, 4);

    gmt_head("R2 every ramp climbs smoothly");

    // ::measure the height alone, not the screen y. a north or south step moves a row as well as climbing, and a row is a whole tile, which has nothing to do with whether the climb pops
    var _worst = 0;
    var _where = "";

    for (var i = 0; i < 4; i++) {
        var _p = gmt_solve_z(_g, gmnav_grid_node(_g, _feet[i][0], _feet[i][1]), _top);
        if (!is_array(_p)) continue;

        var _prev = gmt_node_height(_g, _p[0]);

        for (var _k = 1; _k < array_length(_p); _k++) {
            var _h = gmt_node_height(_g, _p[_k]);
            var _d = abs(_h - _prev);

            if (_d > _worst) {
                _worst = _d;
                _where = _names[i] + " step " + string(_k)
                       + ": node " + string(_p[_k - 1])
                       + " at " + string_format(_prev, 1, 3)
                       + " -> node " + string(_p[_k])
                       + " at " + string_format(_h, 1, 3);
            }
            _prev = _h;
        }
    }

    gmt_note("largest height step in lifts", string_format(_worst, 1, 3));
    gmt_note("where", _where);

    // the ramp's own offsets, straight from the overlay
    var _dbg = [];
    for (var _i = 0; _i < DEMO8_RAMP_LEN; _i++) {
        var _n = demo8_deck_at(_g, 15, DEMO8_PLAT_R2 + DEMO8_RAMP_LEN - _i);
        array_push(_dbg, (_n == GMNAV_NO_NODE)
                       ? "none"
                       : string_format(gmnav_overlay_offset(_g.overlay, _n), 1, 3));
    }
    gmt_note("south lane offsets, foot to top", string_join(", ", _dbg));

    gmt_check("every step is an equal fraction of a lift",
              (abs(_worst - 1 / DEMO8_RAMP_LEN) < 0.001), true);

    gmt_head("R3 both lanes of every ramp");

    var _lanes = 0;
    for (var i = 0; i < 4; i++) {
        for (var _l = 0; _l < 2; _l++) {
            var _fc = _feet[i][0] + ((i >= 2) ? 0 : _l);
            var _fr = _feet[i][1] + ((i >= 2) ? _l : 0);

            if (is_array(gmt_solve_z(_g, gmnav_grid_node(_g, _fc, _fr), _top))) _lanes++;
        }
    }
    gmt_check("all eight lanes climb", _lanes, 8);
}

function gmt_test_flowfield_overlay() {
    gmt_head("F2 a field covers the overlay");

    var _g    = gmt_bridge_level();
    var _ov   = _g.overlay;
    var _goal = gmnav_grid_node(_g, 5, 1);          // north side, above the road

    var _deck = gmnav_overlay_node_at(_ov, 5, 5, 1);
    var _far  = gmnav_grid_node(_g, 5, 10);         // south side, only reachable over the bridge

    var _f = gmnav_flowfield_create(_g);
    gmt_check("built", gmnav_flowfield_build(_f, _goal), true);

    gmt_check("the field sizes to the overlay",
              array_length(_f.dist), _g.count + gmnav_overlay_count(_ov));
    gmt_check("next sizes with it", array_length(_f.next), array_length(_f.dist));

    gmt_check("the deck is reachable",     (_f.dist[_deck] < GMNAV_INF), true);
    gmt_check("the far side is reachable", (_f.dist[_far]  < GMNAV_INF), true);
    gmt_note("deck dist",     string_format(_f.dist[_deck], 1, 4));
    gmt_note("far side dist", string_format(_f.dist[_far],  1, 4));

    gmt_check("the road below the deck is a separate cell",
              (_f.dist[gmnav_grid_node(_g, 5, 5)] != _f.dist[_deck]), true);

    gmt_head("F2b without the bridge there is no field either");

    var _p  = gmnav_grid_create(12, 12, gmnav_layout_create(gmnav_layout.ORTHO, 32, 32));
    gmnav_grid_fill_blocked(_p, 0, 4, 11, 4, true);
    gmnav_grid_fill_blocked(_p, 0, 6, 11, 6, true);

    var _pf = gmnav_flowfield_create(_p);
    gmnav_flowfield_build(_pf, gmnav_grid_node(_p, 5, 1));

    gmt_check("the far side is cut off",
              (_pf.dist[gmnav_grid_node(_p, 5, 10)] == GMNAV_INF), true);
    gmt_check("so the bridge is what carries the field", true, true);

    gmt_head("F2c the field descends across the layer change");

    gmt_check("the far side walks home",
              gmt_field_walks_to_goal(_g, _f, _far, _goal), true);
    gmt_check("the deck walks home",
              gmt_field_walks_to_goal(_g, _f, _deck, _goal), true);

    gmt_check("the goal points nowhere", _f.next[_goal], GMNAV_NO_NODE);
    gmt_check("the deck points somewhere", (_f.next[_deck] != GMNAV_NO_NODE), true);

    var _step = _f.next[_far];
    gmt_check("the far side steps to a real node",
              (_step != GMNAV_NO_NODE && _step != _far), true);

    gmt_head("F2d vectors exist on overlay nodes");

    var _dx = _f.dirx[_deck];
    var _dy = _f.diry[_deck];
    gmt_check("the deck carries a direction",
              (_dx != 0 || _dy != 0), true);
    gmt_check_f("and it is normalised", point_distance(0, 0, _dx, _dy), 1.0, 0.001);

    gmt_head("F2e sampling names a layer");

    var _wd = gmnav_grid_node_to_world(_g, _deck);

    gmt_check("layer 1 samples the deck",
              gmnav_flowfield_is_reachable(_f, _wd[0], _wd[1], 1), true);
    gmt_check_f("and reads the deck's own cost",
                gmnav_flowfield_cost_at(_f, _wd[0], _wd[1], 1), _f.dist[_deck]);

    var _sd = gmnav_flowfield_sample(_f, _wd[0], _wd[1], 1);
    gmt_check("the deck's sample is not empty",
              (_sd[0] != 0 || _sd[1] != 0), true);
	
    gmt_head("F2f a lifted deck points where it is drawn");

    var _lg = gmt_bridge_level();
    gmnav_grid_set_layer_lift(_lg, 24);

    var _lov  = _lg.overlay;
    var _lgoal = gmnav_grid_node(_lg, 5, 1);

    var _foot = gmnav_grid_node(_lg, 5, 3);              // the road cell at the foot of the stair
    var _d1   = gmnav_overlay_node_at(_lov, 5, 4, 1);    // the deck cell it climbs onto

    var _lf = gmnav_flowfield_create(_lg);
    gmnav_flowfield_build(_lf, _lgoal);

    // the deck is drawn a lift above its own cell, the road is not
    var _pf = gmnav_grid_node_to_world(_lg, _foot);
    var _pd = gmnav_grid_node_to_world(_lg, _d1);

    // one row apart is 32px, the lift raises the deck by 24, so it still draws 8 below the foot
    gmt_check("the lift closes all but 8px of the row gap", _pf[1] - _pd[1], -8);

    // the deck's own step is back down to the foot, so its vector must point down the stair
    gmt_check("the deck steps to the foot", _lf.next[_d1], _foot);

    var _dv = [_lf.dirx[_d1], _lf.diry[_d1]];
    gmt_check("the deck's vector points up the screen to the foot", (_dv[1] < 0), true);
    gmt_check_f("and it is normalised", point_distance(0, 0, _dv[0], _dv[1]), 1.0, 0.001);

    // the cell offsets are identical, so only the lift can produce that vector
    gmt_check("the two cells share a column",
              gmnav_grid_col(_lg, _foot), gmnav_grid_col(_lg, _d1));
    gmt_check("and sit one row apart",
              gmnav_grid_row(_lg, _d1) - gmnav_grid_row(_lg, _foot), 1);

    gmt_note("deck vector", string_format(_dv[0], 1, 3) + ", " + string_format(_dv[1], 1, 3));
	
    gmt_head("F2g a blocked deck carries no field");

    var _bg   = gmt_bridge_level();
    var _bov  = _bg.overlay;
    var _bgoal = gmnav_grid_node(_bg, 5, 1);
    var _bfar  = gmnav_grid_node(_bg, 5, 10);
    var _bmid  = gmnav_overlay_node_at(_bov, 5, 5, 1);

    var _bf = gmnav_flowfield_create(_bg);
    gmnav_flowfield_build(_bf, _bgoal);
    gmt_check("the far side starts reachable", (_bf.dist[_bfar] < GMNAV_INF), true);

    // collapse the middle span, the documented flow being a re-finish afterwards
    gmnav_overlay_set_blocked(_bov, _bmid, true);
    gmnav_overlay_finish(_bov);

    var _bf2 = gmnav_flowfield_create(_bg);
    gmnav_flowfield_build(_bf2, _bgoal);

    gmt_check("the collapsed span is unreachable", (_bf2.dist[_bmid] == GMNAV_INF), true);
    gmt_check("and the far side is cut off",       (_bf2.dist[_bfar] == GMNAV_INF), true);
    gmt_check("the north bank still carries the field",
              (_bf2.dist[gmnav_grid_node(_bg, 8, 2)] < GMNAV_INF), true);
    gmt_check("the collapsed span points nowhere", _bf2.next[_bmid], GMNAV_NO_NODE);

    gmnav_overlay_set_blocked(_bov, _bmid, false);
    gmnav_overlay_finish(_bov);

    var _bf3 = gmnav_flowfield_create(_bg);
    gmnav_flowfield_build(_bf3, _bgoal);
    gmt_check("repairing the span restores the crossing",
              (_bf3.dist[_bfar] < GMNAV_INF), true);

    gmt_head("F2h a blocked deck is refused without a rebuild");

    var _hg   = gmt_bridge_level();
    var _hov  = _hg.overlay;

    // a second, independent bridge, so there is something left to lose
    var _e1 = gmnav_overlay_add(_hov, 9, 4, 1);
    var _e2 = gmnav_overlay_add(_hov, 9, 5, 1);
    var _e3 = gmnav_overlay_add(_hov, 9, 6, 1);
    gmnav_overlay_link(_hov, gmnav_grid_node(_hg, 9, 3), _e1, gmnav_link.STAIR, true);
    gmnav_overlay_link(_hov, _e3, gmnav_grid_node(_hg, 9, 7), gmnav_link.STAIR, true);
    gmnav_overlay_finish(_hov);

    var _hmid = gmnav_overlay_node_at(_hov, 5, 5, 1);
    var _hgoal = gmnav_grid_node(_hg, 5, 1);
    var _hfar  = gmnav_grid_node(_hg, 5, 10);

    gmnav_overlay_set_blocked(_hov, _hmid, true);   // deliberately no finish

    var _hf = gmnav_flowfield_create(_hg);
    gmnav_flowfield_build(_hf, _hgoal);

    gmt_check("the blocked span is refused", (_hf.dist[_hmid] == GMNAV_INF), true);
    gmt_check("the second bridge still stands",
              (_hf.dist[gmnav_overlay_node_at(_hov, 9, 5, 1)] < GMNAV_INF), true);
    gmt_check("so the far bank is still reached", (_hf.dist[_hfar] < GMNAV_INF), true);
    gmt_check("by the surviving crossing",
              gmt_field_walks_to_goal(_hg, _hf, _hfar, _hgoal), true);

    gmt_head("F2i capping and slicing reach the overlay");

    var _cg2 = gmt_bridge_level();
    var _cgoal = gmnav_grid_node(_cg2, 5, 1);
    var _cdeck = gmnav_overlay_node_at(_cg2.overlay, 5, 5, 1);
    var _cfar  = gmnav_grid_node(_cg2, 5, 10);

    // the deck sits at 4 and the far side at 9, so a cap between them splits the two
    var _capf = gmnav_flowfield_create(_cg2);
    gmnav_flowfield_build(_capf, _cgoal, 6);

    gmt_check("the deck is inside the cap",   (_capf.dist[_cdeck] < GMNAV_INF), true);
    gmt_check("the far side is outside it",   (_capf.dist[_cfar]  == GMNAV_INF), true);

    // the same field, built a slice at a time
    var _slf = gmnav_flowfield_create(_cg2);
    gmnav_flowfield_begin(_slf, _cgoal);

    var _guard = 0;
    while (_slf.state == gmnav_state.WORKING && _guard++ < 500) {
        gmnav_flowfield_step(_slf, 3);
    }

    gmt_check("a sliced build finishes", _slf.state, gmnav_state.FOUND);
    gmt_check_f("and agrees with the whole build on the deck",
                _slf.dist[_cdeck], 4.0);
    gmt_check_f("and on the far side", _slf.dist[_cfar], 9.0);
    gmt_check("and its vectors reached the overlay",
              (_slf.dirx[_cdeck] != 0 || _slf.diry[_cdeck] != 0), true);

    gmt_head("F2j a goal on the deck");

    var _dg = gmt_bridge_level();
    var _ddeck = gmnav_overlay_node_at(_dg.overlay, 5, 5, 1);

    var _df = gmnav_flowfield_create(_dg);
    gmt_check("a field seeds on an overlay node",
              gmnav_flowfield_build(_df, _ddeck), true);

    gmt_check_f("the goal costs nothing", _df.dist[_ddeck], 0.0);
    gmt_check("the goal points nowhere", _df.next[_ddeck], GMNAV_NO_NODE);

    gmt_check("both banks reach a deck goal",
              (_df.dist[gmnav_grid_node(_dg, 5, 1)]  < GMNAV_INF
            && _df.dist[gmnav_grid_node(_dg, 5, 10)] < GMNAV_INF), true);

    gmt_check("the far bank walks up onto it",
              gmt_field_walks_to_goal(_dg, _df, gmnav_grid_node(_dg, 5, 10), _ddeck), true);

    // two goals, one per bank, so the deck chooses whichever is nearer
    var _mf = gmnav_flowfield_create(_dg);
    gmt_check("a field seeds several goals",
              gmnav_flowfield_build(_mf, [gmnav_grid_node(_dg, 5, 1),
                                          gmnav_grid_node(_dg, 5, 10)]), true);

    // the deck sits 4 from the north bank and 5 from the south, so seeding both leaves it on the north stair and drops the south bank from 9 to 0
    gmt_check_f("the deck still takes the north stair", _mf.dist[_ddeck], 4.0);
    gmt_check_f("and the south bank is now a goal itself",
                _mf.dist[gmnav_grid_node(_dg, 5, 10)], 0.0);

    gmt_head("F2k a profile does not reach overlay cells");

    var _pg2 = gmt_bridge_level();
    var _pdeck = gmnav_overlay_node_at(_pg2.overlay, 5, 5, 1);

    var _lay2 = gmnav_costlayer_create(_pg2, "toll");
    gmnav_costlayer_set(_lay2, 5, 5, 20);          // the road under the deck

    var _prof = gmnav_costprofile_create(_pg2, "hauler");
    gmnav_costprofile_add(_prof, _lay2, 1);
    gmnav_costprofile_bake(_prof);

    var _prf = gmnav_flowfield_create(_pg2, _prof);
    gmnav_flowfield_build(_prf, gmnav_grid_node(_pg2, 5, 1));

    gmt_check_f("the deck is unaffected by the layer below it",
                _prf.dist[_pdeck], 4.0);
    gmt_check("the road below it is dearer",
              (_prf.dist[gmnav_grid_node(_pg2, 5, 5)] > 4.0), true);
	
    gmt_head("F2l the search agrees with the field about a collapsed span");

    var _ag   = gmt_bridge_level();
    var _aov  = _ag.overlay;

    var _a1 = gmnav_overlay_add(_aov, 9, 4, 1);
    var _a2 = gmnav_overlay_add(_aov, 9, 5, 1);
    var _a3 = gmnav_overlay_add(_aov, 9, 6, 1);
    gmnav_overlay_link(_aov, gmnav_grid_node(_ag, 9, 3), _a1, gmnav_link.STAIR, true);
    gmnav_overlay_link(_aov, _a3, gmnav_grid_node(_ag, 9, 7), gmnav_link.STAIR, true);
    gmnav_overlay_finish(_aov);

    var _amid  = gmnav_overlay_node_at(_aov, 5, 5, 1);
    var _anorth = gmnav_grid_node(_ag, 5, 1);
    var _asouth = gmnav_grid_node(_ag, 5, 10);

    gmt_check("both bridges carry a route first",
              is_array(gmt_solve_z(_ag, _anorth, _asouth)), true);

    gmnav_overlay_set_blocked(_aov, _amid, true);   // deliberately no finish

    var _ap = gmt_solve_z(_ag, _anorth, _asouth);
    gmt_check("a route survives on the other bridge", is_array(_ap), true);
    gmt_check("and does not cross the collapsed span",
              (array_get_index(_ap, _amid) < 0), true);

    var _af = gmnav_flowfield_create(_ag);
    gmnav_flowfield_build(_af, _anorth);
    gmt_check("the field refuses the same span",
              (_af.dist[_amid] == GMNAV_INF), true);
    gmt_check("and reaches the same far bank",
              (_af.dist[_asouth] < GMNAV_INF), true);

    gmt_head("F2m reshaping a ramp marks dependents stale");

    var _rg  = gmt_bridge_level();
    var _rov = _rg.overlay;
    gmnav_grid_set_layer_lift(_rg, 24);

    var _rdeck = gmnav_overlay_node_at(_rov, 5, 5, 1);

    var _rf = gmnav_flowfield_create(_rg);
    gmnav_flowfield_build(_rf, gmnav_grid_node(_rg, 5, 1));
    gmt_check("a fresh field is not stale", gmnav_flowfield_is_stale(_rf), false);

    var _before = _rg.version;
    gmt_check("setting the same offset changes nothing",
              gmnav_overlay_set_offset(_rov, _rdeck, 0), true);
    gmt_check("so the version holds", _rg.version, _before);
    gmt_check("and the field is still fresh", gmnav_flowfield_is_stale(_rf), false);

    gmt_check("a real offset is accepted",
              gmnav_overlay_set_offset(_rov, _rdeck, -0.5), true);
    gmt_check("it bumps the version", (_rg.version > _before), true);
    gmt_check("so the field knows its vectors are out of date",
              gmnav_flowfield_is_stale(_rf), true);
	
    gmt_head("F2n every per cell array tracks the count");

    var _ng  = gmt_bridge_level();
    var _nov = _ng.overlay;

    gmt_check("offset is as long as the cell count",
              array_length(_nov.offset), gmnav_overlay_count(_nov));
    gmt_check("a new cell extends it too",
              (gmnav_overlay_add(_nov, 2, 5, 1) != GMNAV_NO_NODE
            && array_length(_nov.offset) == gmnav_overlay_count(_nov)), true);
}

function gmt_test_demo9_level() {
    gmt_head("W1 the demo 9 level");

    var _g  = demo9_make_grid();
    var _ov = _g.overlay;

    gmt_check("one layer", _ov.max_layer, 1);
    gmt_note("deck cells", gmnav_overlay_count(_ov));

    var _nd = demo9_deck_at(_g, DEMO9_CHASM_C1, DEMO9_NORTH_R);
    var _sd = demo9_deck_at(_g, DEMO9_CHASM_C1, DEMO9_SOUTH_R);

    gmt_check("the north crossing exists", (_nd != GMNAV_NO_NODE), true);
    gmt_check("the south crossing exists", (_sd != GMNAV_NO_NODE), true);
    gmt_check("the chasm is solid between them",
              gmnav_grid_is_blocked(_g, gmnav_grid_node(_g, DEMO9_CHASM_C1, 10)), true);
    gmt_check("the ground under the approach stays open",
              gmnav_grid_is_blocked(_g,
                  gmnav_grid_node(_g, DEMO9_CHASM_C1 - 2, DEMO9_NORTH_R)), false);

    gmt_head("W2 the crossing climbs in even steps");

    var _lo = DEMO9_CHASM_C1 - DEMO9_RAMP_LEN - 1;   // ground at the west foot
    var _hi = DEMO9_CHASM_C2 + DEMO9_RAMP_LEN + 1;   // ground at the east foot

    var _worst = 0;
    var _prev  = 0;
    var _prof  = [];

    for (var _c = _lo + 1; _c < _hi; _c++) {
        var _dn = demo9_deck_at(_g, _c, DEMO9_NORTH_R);
        var _h  = demo9_height(_g, _dn);

        _worst = max(_worst, abs(_h - _prev));
        array_push(_prof, string_format(_h, 1, 2));
        _prev = _h;
    }
    _worst = max(_worst, abs(_prev));   // and the step back down to ground

    gmt_note("crossing profile", gmt_arr_str(_prof));
    gmt_note("largest step in lifts", string_format(_worst, 1, 3));

    gmt_check_f("the span sits a full lift up", demo9_height(_g, _nd), 1.0);
    gmt_check("no step is more than a quarter lift",
              (_worst <= (1 / DEMO9_RAMP_LEN) + 0.0001), true);

    gmt_head("W3 the banks are joined only by the crossings");

    var _west = gmnav_grid_node(_g, 3,  10);
    var _east = gmnav_grid_node(_g, 24, 10);

    var _p = gmt_solve_z(_g, _west, _east);
    gmt_check("west reaches east", is_array(_p), true);
    gmt_check("not straight through the chasm",
              gmt_path_visits(_g, _p, DEMO9_CHASM_C1, 10), false);
    gmt_note("west to east", string(array_length(_p)) + " steps");

    var _below = gmt_solve_z(_g, gmnav_grid_node(_g, DEMO9_CHASM_C1 - 2, 2),
                                 gmnav_grid_node(_g, DEMO9_CHASM_C1 - 2, 9));
    gmt_check("the ground under the approach still runs", is_array(_below), true);
    gmt_check("without climbing onto it",
              (array_get_index(_below, _nd) < 0), true);

    gmt_head("W4 one field serves both crossings");

    var _goal = _east;
    var _f    = gmnav_flowfield_create(_g);

    gmt_check("the field builds", gmnav_flowfield_build(_f, _goal), true);
    gmt_check("both crossings carry it",
              (_f.dist[_nd] < GMNAV_INF && _f.dist[_sd] < GMNAV_INF), true);

    var _walked = 0, _failed = 0, _unreach = 0;

    for (var _c2 = 1; _c2 < DEMO9_CHASM_C1; _c2++) {
        for (var _r2 = 1; _r2 < DEMO9_H - 1; _r2++) {
            var _n2 = gmnav_grid_node(_g, _c2, _r2);
            if (gmnav_grid_is_blocked(_g, _n2)) continue;

            if (_f.dist[_n2] == GMNAV_INF) { _unreach++; continue; }

            _walked++;
            if (!gmt_field_walks_to_goal(_g, _f, _n2, _goal, 200)) _failed++;
        }
    }

    gmt_note("west bank cells walked", _walked);
    gmt_check("none of the west bank is stranded", _unreach, 0);
    gmt_check("every west bank cell reaches the goal", _failed, 0);

    var _dfail = 0;
    for (var _i = 0; _i < gmnav_overlay_count(_ov); _i++) {
        var _dn2 = _ov.base + _i;
        if (_f.dist[_dn2] == GMNAV_INF) { _dfail++; continue; }
        if (!gmt_field_walks_to_goal(_g, _f, _dn2, _goal, 200)) _dfail++;
    }
    gmt_check("every deck cell reaches the goal too", _dfail, 0);

    gmt_head("W5 the field parts between the two crossings");

    gmt_check("a cell by the north crossing leaves that way",
              gmt_field_exits_via(_g, _f, gmnav_grid_node(_g, 5, DEMO9_NORTH_R), _nd), true);
    gmt_check("a cell by the south crossing leaves that way",
              gmt_field_exits_via(_g, _f, gmnav_grid_node(_g, 5, DEMO9_SOUTH_R), _sd), true);
}