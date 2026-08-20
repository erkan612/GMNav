#macro GMNAV_DBG_BLOCKED   $2A2AE0   // BGR: red
#macro GMNAV_DBG_OPEN      $60C060   // green
#macro GMNAV_DBG_CLOSED    $C08060   // blue-grey
#macro GMNAV_DBG_PATH      $30F0F0   // yellow
#macro GMNAV_DBG_WALK      $F0F0F0   // white
#macro GMNAV_DBG_FALL      $F0A040   // blue
#macro GMNAV_DBG_JUMP      $40A0F0   // orange
#macro GMNAV_DBG_AGENT     $F040F0   // magenta
#macro GMNAV_DBG_GOAL      $40F040   // bright green

#macro GMNAV_DBG_MAX_CELLS 8000      // per draw call, before bailing out

function gmnav_debug_config() {
    return {
        alpha       : 0.35,
        line_alpha  : 0.9,
        line_width  : 2,
        show_labels : false,   // per-cell numeric text - very slow, small grids only
        cull        : true,    // skip cells outside the current camera
        cull_pad    : 64,      // world units of margin around the view
        max_cells   : GMNAV_DBG_MAX_CELLS
    };
}

function gmnav_debug_draw_grid(_grid, _cfg = undefined) {
    _cfg = _cfg ?? gmnav_debug_config();

    var _v = __gmnav_dbg_view(_cfg);
    var _n = 0;

    draw_set_color(GMNAV_DBG_BLOCKED);
    draw_set_alpha(_cfg.alpha);

    for (var _r = 0; _r < _grid.height; _r++) {
        for (var _c = 0; _c < _grid.width; _c++) {
            if ((_grid.flags[_r * _grid.width + _c] & GMNAV_FLAG_BLOCKED) == 0) continue;
            if (!__gmnav_dbg_visible(_grid.layout, _c, _r, _v)) continue;

            if (++_n > _cfg.max_cells) {
                __gmnav_dbg_bail(_grid, "grid");
                return;
            }
            __gmnav_dbg_cell(_grid.layout, _c, _r);
        }
    }
    __gmnav_dbg_restore();
}

function gmnav_debug_draw_clearance(_grid, _cfg = undefined) {
    _cfg = _cfg ?? gmnav_debug_config();
    if (_grid.clear == undefined) return;

    var _v   = __gmnav_dbg_view(_cfg);
    var _max = 1;
    for (var i = 0; i < _grid.count; i++) _max = max(_max, _grid.clear[i]);

    var _n = 0;
    draw_set_alpha(_cfg.alpha);

    for (var _r = 0; _r < _grid.height; _r++) {
        for (var _c = 0; _c < _grid.width; _c++) {
            var _cl = _grid.clear[_r * _grid.width + _c];
            if (_cl <= 0) continue;
            if (!__gmnav_dbg_visible(_grid.layout, _c, _r, _v)) continue;

            if (++_n > _cfg.max_cells) {
                __gmnav_dbg_bail(_grid, "clearance");
                return;
            }

            var _t = _cl / _max;
            draw_set_color(make_color_rgb(30, 60 + 180 * _t, 30));
            __gmnav_dbg_cell(_grid.layout, _c, _r);
        }
    }
    __gmnav_dbg_restore();
}

function gmnav_debug_draw_costs(_grid, _profile = undefined, _cfg = undefined) {
    _cfg = _cfg ?? gmnav_debug_config();

    var _src = (_profile != undefined) ? _profile.resolved : _grid.cost;
    var _v   = __gmnav_dbg_view(_cfg);

    var _max = 1;
    for (var i = 0; i < _grid.count; i++) _max = max(_max, _src[i]);
    if (_max <= 1) return;   // nothing to show

    var _n = 0;
    draw_set_alpha(_cfg.alpha);

    for (var _r = 0; _r < _grid.height; _r++) {
        for (var _c = 0; _c < _grid.width; _c++) {
            var _i = _r * _grid.width + _c;
            if ((_grid.flags[_i] & GMNAV_FLAG_BLOCKED) != 0) continue;
            if (_src[_i] <= 1) continue;
            if (!__gmnav_dbg_visible(_grid.layout, _c, _r, _v)) continue;

            if (++_n > _cfg.max_cells) {
                __gmnav_dbg_bail(_grid, "costs");
                return;
            }

            var _t = (_src[_i] - 1) / (_max - 1);
            draw_set_color(make_color_rgb(60 + 190 * _t, 40, 40));
            __gmnav_dbg_cell(_grid.layout, _c, _r);
        }
    }
    __gmnav_dbg_restore();
}

function gmnav_debug_draw_flowfield(_field, _cfg = undefined, _show_dist = true) {
    _cfg = _cfg ?? gmnav_debug_config();

    var _grid = _field.grid;
    var _lay  = _grid.layout;
    var _v    = __gmnav_dbg_view(_cfg);

    var _maxd = 1;
    for (var i = 0; i < _grid.count; i++) {
        var _d = _field.dist[i];
        if (_d < GMNAV_INF && _d > _maxd) _maxd = _d;
    }

    var _len = min(_lay.tile_w, _lay.tile_h) * 0.35;
    var _n   = 0;

    for (var _r = 0; _r < _grid.height; _r++) {
        for (var _c = 0; _c < _grid.width; _c++) {
            var _i = _r * _grid.width + _c;
            if ((_grid.flags[_i] & GMNAV_FLAG_BLOCKED) != 0) continue;

            var _m = _field.mark[_i];
            if (_m != _field.gen && _m != -_field.gen) continue;
            if (!__gmnav_dbg_visible(_lay, _c, _r, _v)) continue;

            if (++_n > _cfg.max_cells) {
                __gmnav_dbg_bail(_grid, "flowfield");
                return;
            }

            var _cx = gmnav_layout_cell_x(_lay, _c, _r);
            var _cy = gmnav_layout_cell_y(_lay, _c, _r);

            if (_show_dist) {
                var _t = _field.dist[_i] / _maxd;
                draw_set_alpha(_cfg.alpha);
                draw_set_color(make_color_rgb(40, 60 + 150 * (1 - _t), 60 + 150 * _t));
                __gmnav_dbg_cell(_lay, _c, _r);
            }

            var _dx = _field.dirx[_i];
            var _dy = _field.diry[_i];
            if (_dx == 0 && _dy == 0) {
                draw_set_alpha(_cfg.line_alpha);
                draw_set_color(GMNAV_DBG_GOAL);
                draw_circle(_cx, _cy, _len * 0.4, false);
                continue;
            }

            draw_set_alpha(_cfg.line_alpha);
            draw_set_color(GMNAV_DBG_PATH);
            __gmnav_dbg_arrow(_cx - _dx * _len, _cy - _dy * _len,
                              _cx + _dx * _len, _cy + _dy * _len, _len * 0.4);
        }
    }
    __gmnav_dbg_restore();
}

function gmnav_debug_draw_path(_grid, _path, _cfg = undefined, _colour = GMNAV_DBG_PATH) {
    _cfg = _cfg ?? gmnav_debug_config();

    var _n = array_length(_path);
    if (_n == 0) return;

    var _lay = _grid.layout;
    var _w   = _grid.width;

    draw_set_alpha(_cfg.line_alpha);
    draw_set_color(_colour);

    var _px = 0, _py = 0;
    for (var i = 0; i < _n; i++) {
        var _nd = _path[i];
        var _cx = gmnav_layout_cell_x(_lay, _nd % _w, _nd div _w);
        var _cy = gmnav_layout_cell_y(_lay, _nd % _w, _nd div _w);

        if (i > 0) __gmnav_dbg_line(_px, _py, _cx, _cy, _cfg.line_width);
        draw_circle(_cx, _cy, 3, false);

        _px = _cx;
        _py = _cy;
    }
    __gmnav_dbg_restore();
}

function gmnav_debug_draw_path_object(_path, _cfg = undefined, _colour = GMNAV_DBG_PATH) {
    _cfg = _cfg ?? gmnav_debug_config();
    if (_path == undefined || _path.count == 0) return;

    draw_set_alpha(_cfg.line_alpha);
    draw_set_color(_colour);

    for (var i = 0; i < _path.count; i++) {
        if (i > 0) __gmnav_dbg_line(_path.px[i - 1], _path.py[i - 1],
                                    _path.px[i], _path.py[i], _cfg.line_width);
        draw_circle(_path.px[i], _path.py[i], 4, false);
    }
    __gmnav_dbg_restore();
}

function gmnav_debug_draw_search(_srch, _cfg = undefined) {
    _cfg = _cfg ?? gmnav_debug_config();
    if (_srch.slot == undefined) return;

    var _grid = _srch.grid;
    var _lay  = _grid.layout;
    var _slot = _srch.slot;
    var _gen  = _slot.gen;
    var _v    = __gmnav_dbg_view(_cfg);
    var _n    = 0;

    draw_set_alpha(_cfg.alpha);

    for (var _r = 0; _r < _grid.height; _r++) {
        for (var _c = 0; _c < _grid.width; _c++) {
            var _m = _slot.mark[_r * _grid.width + _c];
            if (_m != _gen && _m != -_gen) continue;
            if (!__gmnav_dbg_visible(_lay, _c, _r, _v)) continue;

            if (++_n > _cfg.max_cells) {
                __gmnav_dbg_bail(_grid, "search");
                return;
            }

            draw_set_color((_m == _gen) ? GMNAV_DBG_OPEN : GMNAV_DBG_CLOSED);
            __gmnav_dbg_cell(_lay, _c, _r);
        }
    }
    __gmnav_dbg_restore();
}

function gmnav_debug_draw_platgraph(_pg, _cfg = undefined, _types = 7, _focus = -1) {
    _cfg = _cfg ?? gmnav_debug_config();
    if (_pg.phase != gmnav_bake.DONE) return;

    var _v = __gmnav_dbg_view(_cfg);

    var _i0 = (_focus >= 0) ? _focus : 0;
    var _i1 = (_focus >= 0) ? _focus + 1 : _pg.count;

    draw_set_alpha(_cfg.line_alpha);

    for (var _i = _i0; _i < _i1; _i++) {
        var _fx = _pg.node_x[_i];
        var _fy = _pg.node_y[_i];

        if (_cfg.cull && (_fx < _v[0] || _fx > _v[2] || _fy < _v[1] || _fy > _v[3])) continue;

        var _e0 = _pg.edge_start[_i];
        var _e1 = _pg.edge_start[_i + 1];

        for (var e = _e0; e < _e1; e++) {
            var _lt  = _pg.edge_type[e];
            var _bit = (_lt == gmnav_link.WALK) ? 1
                     : ((_lt == gmnav_link.FALL) ? 2 : 4);
            if ((_types & _bit) == 0) continue;

            var _to = _pg.edge_to[e];
            var _tx = _pg.node_x[_to];
            var _ty = _pg.node_y[_to];

            switch (_lt) {
                case gmnav_link.WALK: draw_set_color(GMNAV_DBG_WALK); break;
                case gmnav_link.FALL: draw_set_color(GMNAV_DBG_FALL); break;
                default:              draw_set_color(GMNAV_DBG_JUMP); break;
            }

            if (_lt == gmnav_link.WALK) {
                __gmnav_dbg_line(_fx, _fy, _tx, _ty, 1);
            } else {
                __gmnav_dbg_arc(_fx, _fy, _tx, _ty,
                                (_lt == gmnav_link.JUMP) ? -0.12 : -0.06);
            }

            if (_lt != gmnav_link.WALK) {
                var _a = point_direction(_fx, _fy, _tx, _ty);
                draw_line(_tx, _ty, _tx + lengthdir_x(5, _a + 155),
                                    _ty + lengthdir_y(5, _a + 155));
                draw_line(_tx, _ty, _tx + lengthdir_x(5, _a - 155),
                                    _ty + lengthdir_y(5, _a - 155));
            }
        }

        draw_set_color((_focus >= 0) ? GMNAV_DBG_PATH : GMNAV_DBG_GOAL);
        draw_circle(_fx, _fy, (_focus >= 0) ? 5 : 3, false);
    }
    __gmnav_dbg_restore();
}

function gmnav_debug_draw_agent(_agent, _cfg = undefined) {
    _cfg = _cfg ?? gmnav_debug_config();

    if (gmnav_agent_has_path(_agent)) {
        var _colour = _agent.path.stale ? GMNAV_DBG_BLOCKED : GMNAV_DBG_PATH;
        gmnav_debug_draw_path_object(_agent.path, _cfg, _colour);

        if (_agent.seek_i < _agent.path.count) {
            draw_set_alpha(_cfg.line_alpha);
            draw_set_color(GMNAV_DBG_GOAL);
            draw_circle(_agent.path.px[_agent.seek_i],
                        _agent.path.py[_agent.seek_i], 7, true);
        }
    }

    draw_set_alpha(_cfg.line_alpha);
    draw_set_color(GMNAV_DBG_AGENT);
    draw_circle(_agent.x, _agent.y, _agent.radius, true);

    var _sp = point_distance(0, 0, _agent.vx, _agent.vy);
    if (_sp > 0.01) {
        var _s = (_agent.radius * 2) / max(0.0001, _agent.speed);
        __gmnav_dbg_arrow(_agent.x, _agent.y,
                          _agent.x + _agent.vx * _s,
                          _agent.y + _agent.vy * _s, 5);
    }

    if (_agent.has_goal) {
        draw_set_color(GMNAV_DBG_GOAL);
        __gmnav_dbg_cross(_agent.goal_x, _agent.goal_y, 6);
    }
    __gmnav_dbg_restore();
}

function gmnav_debug_draw_stats(_sched, _x = 8, _y = 8) {
    var _s = "GMNav " + GMNAV_VERSION
           + "\ndomain    " + ((_sched.domain == gmnav_domain.PLATFORM) ? "PLATFORM" : "GRID")
           + "\nbudget    " + string(_sched.budget)
           + "\nactive    " + string(_sched.last_active) + " / " + string(_sched.concurrent)
           + "\npending   " + string(gmnav_scheduler_pending(_sched))
           + "\npops used " + string(_sched.last_pops)
           + "\npooled    " + string(array_length(_sched.pool));

    draw_set_alpha(0.7);
    draw_set_color(c_black);
    draw_rectangle(_x - 4, _y - 4, _x + 150, _y + 100, false);

    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_text(_x, _y, _s);
    __gmnav_dbg_restore();
}

function gmnav_debug_search_text(_srch) {
    var _st = ["IDLE", "WORKING", "FOUND", "FAILED"];
    return _st[_srch.state]
         + "  exp " + string(_srch.expansions)
         + "  pops " + string(_srch.pops)
         + (gmnav_search_is_stale(_srch) ? "  STALE" : "");
}

function __gmnav_dbg_restore() {
    draw_set_alpha(1);
    draw_set_color(c_white);
}

function __gmnav_dbg_bail(_grid, _what) {
    __gmnav_dbg_restore();
    show_debug_message("GMNav debug: " + _what + " overlay exceeded the cell budget on a "
                     + string(_grid.width) + "x" + string(_grid.height)
                     + " grid. Zoom in, or raise cfg.max_cells.");
}

function __gmnav_dbg_view(_cfg) {
    if (!_cfg.cull) return [-999999, -999999, 999999, 999999];

    var _cam = view_camera[view_current];
    var _x = camera_get_view_x(_cam);
    var _y = camera_get_view_y(_cam);
    var _w = camera_get_view_width(_cam);
    var _h = camera_get_view_height(_cam);
    var _p = _cfg.cull_pad;

    return [_x - _p, _y - _p, _x + _w + _p, _y + _h + _p];
}

function __gmnav_dbg_visible(_lay, _c, _r, _v) {
    var _x = gmnav_layout_cell_x(_lay, _c, _r);
    if (_x < _v[0] || _x > _v[2]) return false;
    var _y = gmnav_layout_cell_y(_lay, _c, _r);
    return (_y >= _v[1] && _y <= _v[3]);
}

function __gmnav_dbg_cell(_lay, _c, _r) {
    var _cx = gmnav_layout_cell_x(_lay, _c, _r);
    var _cy = gmnav_layout_cell_y(_lay, _c, _r);
    var _hw = _lay.tile_w * 0.5;
    var _hh = _lay.tile_h * 0.5;

    switch (_lay.mode) {
        case gmnav_layout.ORTHO:
            draw_rectangle(_cx - _hw + 1, _cy - _hh + 1, _cx + _hw - 1, _cy + _hh - 1, false);
            break;

        case gmnav_layout.ISO_DIAMOND:
        case gmnav_layout.ISO_STAGGERED:
            draw_primitive_begin(pr_trianglefan);
            draw_vertex(_cx, _cy - _hh);
            draw_vertex(_cx + _hw, _cy);
            draw_vertex(_cx, _cy + _hh);
            draw_vertex(_cx - _hw, _cy);
            draw_primitive_end();
            break;

        case gmnav_layout.HEX_POINTY:
            draw_primitive_begin(pr_trianglefan);
            draw_vertex(_cx,       _cy - _hh);
            draw_vertex(_cx + _hw, _cy - _hh * 0.5);
            draw_vertex(_cx + _hw, _cy + _hh * 0.5);
            draw_vertex(_cx,       _cy + _hh);
            draw_vertex(_cx - _hw, _cy + _hh * 0.5);
            draw_vertex(_cx - _hw, _cy - _hh * 0.5);
            draw_primitive_end();
            break;

        case gmnav_layout.HEX_FLAT:
            draw_primitive_begin(pr_trianglefan);
            draw_vertex(_cx - _hw * 0.5, _cy - _hh);
            draw_vertex(_cx + _hw * 0.5, _cy - _hh);
            draw_vertex(_cx + _hw,       _cy);
            draw_vertex(_cx + _hw * 0.5, _cy + _hh);
            draw_vertex(_cx - _hw * 0.5, _cy + _hh);
            draw_vertex(_cx - _hw,       _cy);
            draw_primitive_end();
            break;
    }
}

function __gmnav_dbg_line(_x1, _y1, _x2, _y2, _w) {
    if (_w <= 1) draw_line(_x1, _y1, _x2, _y2);
    else         draw_line_width(_x1, _y1, _x2, _y2, _w);
}

function __gmnav_dbg_arrow(_x1, _y1, _x2, _y2, _head) {
    draw_line(_x1, _y1, _x2, _y2);

    var _a = point_direction(_x1, _y1, _x2, _y2);
    draw_line(_x2, _y2, _x2 + lengthdir_x(_head, _a + 150),
                        _y2 + lengthdir_y(_head, _a + 150));
    draw_line(_x2, _y2, _x2 + lengthdir_x(_head, _a - 150),
                        _y2 + lengthdir_y(_head, _a - 150));
}

function __gmnav_dbg_arc(_x1, _y1, _x2, _y2, _bow, _steps = 8) {
    var _mx = (_x1 + _x2) * 0.5;
    var _my = (_y1 + _y2) * 0.5;
    var _d  = point_distance(_x1, _y1, _x2, _y2);
    var _a  = point_direction(_x1, _y1, _x2, _y2) + 90;

    var _cx = _mx + lengthdir_x(_d * _bow, _a);
    var _cy = _my + lengthdir_y(_d * _bow, _a);

    var _px = _x1, _py = _y1;
    for (var i = 1; i <= _steps; i++) {
        var _t = i / _steps;
        var _u = 1 - _t;
        var _qx = _u * _u * _x1 + 2 * _u * _t * _cx + _t * _t * _x2;
        var _qy = _u * _u * _y1 + 2 * _u * _t * _cy + _t * _t * _y2;
        draw_line(_px, _py, _qx, _qy);
        _px = _qx;
        _py = _qy;
    }
}

function __gmnav_dbg_cross(_x, _y, _s) {
    draw_line(_x - _s, _y - _s, _x + _s, _y + _s);
    draw_line(_x - _s, _y + _s, _x + _s, _y - _s);
}