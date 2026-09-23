// info panel

draw_set_alpha(0.85);
draw_set_color(c_black);
draw_rectangle(8, 8, 340, 200, false);
draw_set_alpha(1);

draw_set_color(c_white);
draw_text(20, 16, "GMNav Demo 15 - avoidance modes");
draw_text(20, 40, "left click   send everyone there");
draw_text(20, 58, "B            cycle mode");
draw_text(20, 76, "R            reset to spawn");
draw_text(20, 94, "P / G        paths, grid");

var _names = ["BASIC (separation)", "CONTEXT (probe based)", "FOLLOW (queue)"];
var _cols  = [ #E0B84A, #5FC8F0, #60C075 ];

draw_set_color(_cols[mode]);
draw_text(20, 122, "mode        " + _names[mode]);

var _arrived = demo15_count_arrived(id);
draw_set_color(_arrived == array_length(agents) ? #75C060 : c_white);
draw_text(20, 150, "arrived     " + string(_arrived) + " / " + string(array_length(agents)));

// timing. since the last click, or since arrival
var _since = frames - mode_changed;

draw_set_color(c_white);
if (arrived_at > 0) {
    draw_set_color(#75C060);
    draw_text(20, 178, "last wave   " + string(arrived_at) + " frames");
} else if (click_x >= 0) {
    draw_set_color(#E0B84A);
    draw_text(20, 178, "running     " + string(frames) + " frames");
} else {
    draw_text(20, 178, "click anywhere to send the crowd");
}

// mode switch counter
draw_set_color(c_white);
draw_text(360, 16, "frames since switch  " + string(_since));

// hero close-up

var _px = 920;
var _py = 400;
var _pw = 350;
var _ph = 280;

draw_set_alpha(0.85);
draw_set_color(c_black);
draw_rectangle(_px, _py, _px + _pw, _py + _ph, false);
draw_set_alpha(1);

draw_set_color(c_white);
draw_text(_px + 12, _py + 8, "hero (agent 0)");

var _hero = agents[0];
var _cx   = _px + _pw * 0.5;
var _cy   = _py + _ph * 0.55;

// BASIC
if (mode == 0) {
    var _av = __gmnav_agent_avoid_basic(_hero, agents);
    var _am = point_distance(0, 0, _av[0], _av[1]);

    draw_set_color(#E0B84A);
    if (_am > 0.001) {
        draw_line(_cx, _cy, _cx + _av[0] / _am * 60, _cy + _av[1] / _am * 60);
    } else {
        draw_circle(_cx, _cy, 6, true);
        draw_text(_px + 12, _py + _ph - 30, "no push");
    }
}

// CONTEXT
if (mode == 1) {
    var _probes  = _hero.cs_probes;
    var _step    = 360 / _probes;
    var _wall_r  = _hero.radius * _hero.cs_wall_range;
    var _ray_len = 70;
    var _n_src   = gmnav_grid_world_to_node(grid, _hero.x, _hero.y);

    for (var p = 0; p < _probes; p++) {
        var _ang = p * _step;
        var _ux  = lengthdir_x(1, _ang);
        var _uy  = lengthdir_y(1, _ang);

        var _wx = _hero.x + _ux * _wall_r;
        var _wy = _hero.y + _uy * _wall_r;
        var _wn = gmnav_grid_world_to_node(grid, _wx, _wy);

        var _blocked = false;
        if (_wn == GMNAV_NO_NODE || _n_src == GMNAV_NO_NODE) _blocked = true;
        else if (!gmnav_grid_node_line_clear(grid, _n_src, _wn)) _blocked = true;

        draw_set_alpha(_blocked ? 0.75 : 0.35);
        draw_set_color(_blocked ? #E05A3C : #5FC8F0);
        draw_line(_cx, _cy, _cx + _ux * _ray_len, _cy + _uy * _ray_len);
    }
    draw_set_alpha(1);
}

// FOLLOW
if (mode == 2) {
    var _dm = point_distance(0, 0, _hero.vx, _hero.vy);
    var _ux = 1, _uy = 0;

    if (_dm > 0.001) {
        _ux = _hero.vx / _dm;
        _uy = _hero.vy / _dm;
    }

    var _ang_f = point_direction(0, 0, _ux, _uy);
    var _range = _hero.radius * _hero.avoid_range;
    var _cone  = _hero.follow_cone * _hero.radius * 2;

    draw_set_alpha(0.2);
    draw_set_color(#60C075);
    draw_primitive_begin(pr_trianglefan);
    draw_vertex(_cx, _cy);
    for (var a = -30; a <= 30; a += 10) {
        var _pa = _ang_f + a;
        var _rr = _range * 1.4;
        draw_vertex(_cx + lengthdir_x(_rr, _pa),
                    _cy + lengthdir_y(_rr, _pa));
    }
    draw_primitive_end();
    draw_set_alpha(1);

    draw_set_color(#E0B84A);
    for (var i = 0; i < array_length(agents); i++) {
        var _o = agents[i];
        if (_o == _hero) continue;

        var _dx = _o.x - _hero.x;
        var _dy = _o.y - _hero.y;
        var _fwd = _dx * _ux + _dy * _uy;
        if (_fwd <= 0 || _fwd > _range) continue;

        var _lat = abs(_dx * (-_uy) + _dy * _ux);
        if (_lat > _cone) continue;

        draw_circle(_cx + _dx * 0.7, _cy + _dy * 0.7, 4, false);
    }
}

// hero body
draw_set_color(#F2D268);
draw_circle(_cx, _cy, _hero.radius, false);
draw_set_color(#7A5F1E);
draw_circle(_cx, _cy, _hero.radius, true);

// velocity arrow
if (_hero.vx != 0 || _hero.vy != 0) {
    var _vm = point_distance(0, 0, _hero.vx, _hero.vy);

    if (_vm > 0.01) {
        var _ex = _cx + _hero.vx / _vm * 70;
        var _ey = _cy + _hero.vy / _vm * 70;
        var _ea = point_direction(_cx, _cy, _ex, _ey);

        draw_set_color(c_white);
        draw_line(_cx, _cy, _ex, _ey);
        draw_line(_ex, _ey,
                  _ex + lengthdir_x(6, _ea + 150),
                  _ey + lengthdir_y(6, _ea + 150));
        draw_line(_ex, _ey,
                  _ex + lengthdir_x(6, _ea - 150),
                  _ey + lengthdir_y(6, _ea - 150));
    }
}

draw_set_color(c_white);
draw_set_alpha(1);