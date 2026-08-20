function gmnav_heap_create(_capacity = GMNAV_HEAP_INIT) {
    return {
        count : 0,
        cap   : _capacity,
        key_f : array_create(_capacity, 0),
        key_h : array_create(_capacity, 0),
        node  : array_create(_capacity, GMNAV_NO_NODE)
    };
}

function gmnav_heap_clear(_heap) {
    _heap.count = 0;
}

function gmnav_heap_is_empty(_heap) {
    return (_heap.count == 0);
}

function gmnav_heap_peek_f(_heap) {
    return (_heap.count > 0) ? _heap.key_f[0] : GMNAV_INF;
}

function __gmnav_heap_grow(_heap) {
    var _nc = _heap.cap * 2;
    array_resize(_heap.key_f, _nc);
    array_resize(_heap.key_h, _nc);
    array_resize(_heap.node,  _nc);
    _heap.cap = _nc;
}

function gmnav_heap_push(_heap, _f, _h, _node) {
    var _i = _heap.count;
    if (_i >= _heap.cap) __gmnav_heap_grow(_heap);

    var _kf = _heap.key_f, _kh = _heap.key_h, _kn = _heap.node;

    while (_i > 0) {
        var _p  = (_i - 1) >> 1;
        var _pf = _kf[_p];

        if (_f > _pf) break;
        if (_f == _pf) {
            var _ph = _kh[_p];
            if (_h > _ph) break;
            if (_h == _ph && _node > _kn[_p]) break;
        }

        _kf[_i] = _pf; _kh[_i] = _kh[_p]; _kn[_i] = _kn[_p];
        _i = _p;
    }

    _kf[_i] = _f; _kh[_i] = _h; _kn[_i] = _node;
    _heap.count++;
}

function gmnav_heap_pop(_heap) {
    var _n = _heap.count;
    if (_n == 0) return GMNAV_NO_NODE;

    var _kf = _heap.key_f, _kh = _heap.key_h, _kn = _heap.node;
    var _top = _kn[0];

    _n--;
    _heap.count = _n;
    if (_n == 0) return _top;

    var _f  = _kf[_n];
    var _h  = _kh[_n];
    var _nd = _kn[_n];

    var _i    = 0;
    var _half = _n >> 1;

    while (_i < _half) {
        var _c = (_i << 1) + 1;
        var _r = _c + 1;

        if (_r < _n) {
            var _cf = _kf[_c], _rf = _kf[_r];
            var _take_right = false;

            if (_rf < _cf) _take_right = true;
            else if (_rf == _cf) {
                var _ch = _kh[_c], _rh = _kh[_r];
                if (_rh < _ch) _take_right = true;
                else if (_rh == _ch && _kn[_r] < _kn[_c]) _take_right = true;
            }

            if (_take_right) _c = _r;
        }

        var _cf2 = _kf[_c];
        if (_f < _cf2) break;
        if (_f == _cf2) {
            var _ch2 = _kh[_c];
            if (_h < _ch2) break;
            if (_h == _ch2 && _nd < _kn[_c]) break;
        }

        _kf[_i] = _cf2; _kh[_i] = _kh[_c]; _kn[_i] = _kn[_c];
        _i = _c;
    }

    _kf[_i] = _f; _kh[_i] = _h; _kn[_i] = _nd;
    return _top;
}