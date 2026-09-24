// toolbar background
draw_set_color(#0A0A0E);
draw_rectangle(0, TROOP_MAP_H, TROOP_ROOM_W, TROOP_ROOM_H, false);

draw_set_color(#202028);
draw_rectangle(0, TROOP_MAP_H, TROOP_ROOM_W, TROOP_MAP_H + 2, false);

// counts
var _scouts = 0, _heavies = 0, _selected = 0;

for (var i = 0; i < array_length(units); i++) {
    var _u = units[i];
    if (_u.type == TROOP_TYPE_SCOUT) _scouts++;
    else                             _heavies++;
    if (_u.selected) _selected++;
}

var _by = TROOP_MAP_H + 20;

draw_set_color(#E8C46A);
draw_text(30, _by,      "SCOUTS");
draw_set_color(c_white);
draw_text(30, _by + 22, string(_scouts));

draw_set_color(#5FB4E0);
draw_text(150, _by,      "HEAVIES");
draw_set_color(c_white);
draw_text(150, _by + 22, string(_heavies));

draw_set_color(#FFD040);
draw_text(290, _by,      "SELECTED");
draw_set_color(c_white);
draw_text(290, _by + 22, string(_selected));

// formation / mode
var _bx = 480;

draw_set_color(#8A8A8A);
draw_text(_bx, _by,      "FORMATION");
draw_set_color(c_white);
draw_text(_bx, _by + 22, troop_formation_name(formation));

var _avoid_names = ["BASIC", "CONTEXT", "FOLLOW"];
var _avoid_cols  = [ #E0B84A, #5FC8F0, #60C075 ];

_bx = 650;
draw_set_color(#8A8A8A);
draw_text(_bx, _by,      "AVOID");
draw_set_color(_avoid_cols[avoid_mode_idx]);
draw_text(_bx, _by + 22, _avoid_names[avoid_mode_idx]);

// key hints
var _hx = 820;

draw_set_color(#8A8A8A);
draw_text(_hx, _by,      "N / M     add scouts / heavies");
draw_text(_hx, _by + 22, "A / S     select all / stop");
draw_text(_hx, _by + 44, "F / B     formation / avoid mode");
draw_text(_hx, _by + 66, "K / P     cost layer / paths");
draw_text(_hx, _by + 88, "Tab       settings");

// left click hint
draw_set_color(#4A4A52);
draw_text(30, TROOP_MAP_H + 80, "left drag select  -  right click move");

draw_set_color(c_white);

// settings panel
if (settings_open) {
    var _panel_h = settings_header_h + array_length(settings_rows) * settings_row_h + 8;

    // background
    draw_set_alpha(0.92);
    draw_set_color(#0E0E14);
    draw_rectangle(settings_px, settings_py,
                   settings_px + settings_pw, settings_py + _panel_h, false);

    draw_set_color(#303040);
    draw_rectangle(settings_px, settings_py,
                   settings_px + settings_pw, settings_py + _panel_h, true);

    draw_set_alpha(1);

    // header
    draw_set_color(c_white);
    draw_text(settings_px + 12, settings_py + 14, "AVOIDANCE SETTINGS");

    var _sel_count = 0;
    for (var i = 0; i < array_length(units); i++) if (units[i].selected) _sel_count++;

    draw_set_color(#8A8A8A);
    draw_text(settings_px + 12, settings_py + 30,
              (_sel_count > 0)
                ? "applies to " + string(_sel_count) + " selected"
                : "applies to ALL units");

    // reset button
    draw_set_color(#303040);
    draw_rectangle(settings_px + settings_pw - 70, settings_py + 8,
                   settings_px + settings_pw - 12, settings_py + 34, false);
    draw_set_color(c_white);
    draw_text(settings_px + settings_pw - 62, settings_py + 14, "RESET");

    // rows
    var _only_sel = (_sel_count > 0);

    for (var i = 0; i < array_length(settings_rows); i++) {
        var _row = settings_rows[i];
        var _ry  = settings_py + settings_header_h + i * settings_row_h;
        var _val = troop_settings_read(units, _row.key, _only_sel);

        // label
        draw_set_color(c_white);
        draw_text(settings_px + 14, _ry + 5, _row.label);

        // minus button
        var _minus_x = settings_px + 210;
        draw_set_color(#404060);
        draw_rectangle(_minus_x, _ry + 2, _minus_x + 22, _ry + 22, false);
        draw_set_color(c_white);
        draw_text(_minus_x + 7, _ry + 4, "-");

        // plus button
        var _plus_x = settings_px + settings_pw - 34;
        draw_set_color(#404060);
        draw_rectangle(_plus_x, _ry + 2, _plus_x + 22, _ry + 22, false);
        draw_set_color(c_white);
        draw_text(_plus_x + 7, _ry + 4, "+");

        // value
        draw_set_color(#A0D0FF);
        draw_text(_minus_x + 34, _ry + 5, string_format(_val, 1, 2));
    }
}