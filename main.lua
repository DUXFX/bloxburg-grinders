local _g = getfenv();
local _s = string;
local _t = table;
local _m = math;
local _b = bit32;

_g.BLOXBURG_GRINDERS_LOADED = true;

local function _d(t)
    local r = ""
    for _, c in ipairs(t) do
        r = r .. _s.char(c)
    end
    return r
end

local _strs = {
    _d({103, 101, 116, 116, 104, 114, 101, 97, 100, 105, 100, 101, 110, 116, 105, 116, 121}),
    _d({115, 101, 116, 116, 104, 114, 101, 97, 100, 105, 100, 101, 110, 116, 105, 116, 121}),
    _d({104, 111, 111, 107, 109, 101, 116, 97, 109, 101, 116, 104, 111, 100}),
    _d({102, 105, 114, 101, 115, 105, 103, 110, 97, 108}),
    _d({108, 111, 97, 100, 115, 116, 114, 105, 110, 103}),
    _d({114, 101, 113, 117, 105, 114, 101}),
    _d({103, 101, 116, 117, 112, 118, 97, 108, 117, 101}),
    _d({104, 111, 111, 107, 102, 117, 110, 99, 116, 105, 111, 110}),
    _d({99, 104, 101, 99, 107, 99, 97, 108, 108, 101, 114}),
    _d({110, 101, 119, 99, 99, 108, 111, 115, 117, 114, 101})
}

for _, v in ipairs(_strs) do
    if not _g[v] then
        warn(_d({77, 105, 115, 115, 105, 110, 103, 32, 102, 117, 110, 99, 116, 105, 111, 110, 58, 32}) .. v)
        return
    end
end

local _i = _g[_strs[1]] and _g[_strs[1]]() or 8
local _lib = _g[_strs[5]](game[_d({72, 116, 116, 112, 71, 101, 116})](_g, _d({104, 116, 116, 112, 115, 58, 47, 47, 114, 97, 119, 46, 103, 105, 116, 104, 117, 98, 117, 115, 101, 114, 99, 111, 110, 116, 101, 110, 116, 46, 99, 111, 109, 47, 105, 111, 112, 115, 101, 99, 47, 98, 108, 111, 120, 98, 117, 114, 103, 45, 103, 114, 105, 110, 100, 101, 114, 115, 47, 109, 97, 105, 110, 47, 117, 105, 46, 108, 117, 97})))()

local _u = {}
_u.f = function(p, s, w)
    local ps = _s.split(p, ".")
    local bi = s
    if not bi then
        local suc, res = pcall(game[_d({71, 101, 116, 83, 101, 114, 118, 105, 99, 101})], game, ps[1])
        bi = res
        _t.remove(ps, 1)
    end
    for _, seg in ipairs(ps) do
        if w then
            bi = bi[_d({87, 97, 105, 116, 70, 111, 114, 67, 104, 105, 108, 100})](bi, seg, 10)
        else
            bi = bi[_d({70, 105, 110, 100, 70, 105, 114, 115, 116, 67, 104, 105, 108, 100})](bi, seg)
        end
        if not bi then return nil end
    end
    return bi
end

local _p = _u.f(_d({80, 108, 97, 121, 101, 114, 115, 46, 76, 111, 99, 97, 108, 80, 108, 97, 121, 101, 114}))
local _m_p = _u.f(_d({80, 108, 97, 121, 101, 114, 83, 99, 114, 105, 112, 116, 115, 46, 77, 111, 100, 117, 108, 101, 115}), _p, true)
local _j_m = _g[_strs[6]](_u.f(_d({74, 111, 98, 72, 97, 110, 100, 108, 101, 114}), _m_p, true))
local _i_m = _g[_strs[6]](_u.f(_d({73, 110, 116, 101, 114, 97, 99, 116, 105, 111, 110, 72, 97, 110, 100, 108, 101, 114}), _m_p, true))
local _l = _u.f(_d({87, 111, 114, 107, 115, 112, 97, 99, 101, 46, 69, 110, 118, 105, 114, 111, 110, 109, 101, 110, 116, 46, 76, 111, 99, 97, 116, 105, 111, 110, 115}), nil, true)
local _v_u = game[_d({71, 101, 116, 83, 101, 114, 118, 105, 99, 101})](game, _d({86, 105, 114, 116, 117, 97, 108, 85, 115, 101, 114}))
local _g_h = _g[_strs[6]](_m_p[_d({87, 97, 105, 116, 70, 111, 114, 67, 104, 105, 108, 100})](_m_p, _d({73, 110, 118, 101, 110, 116, 111, 114, 121, 72, 97, 110, 100, 108, 101, 114})))[_d({77, 111, 100, 117, 108, 101, 115})][_d({71, 85, 73, 72, 97, 110, 100, 108, 101, 114})]

_p.Idled:Connect(function()
    _v_u[_d({66, 117, 116, 116, 111, 110, 50, 68, 111, 119, 110})](_v_u, Vector2.new(0,0),workspace.CurrentCamera.CFrame)
    task.wait(0.5)
    _v_u[_d({66, 117, 116, 116, 111, 110, 50, 85, 112})](_v_u, Vector2.new(0,0),workspace.CurrentCamera.CFrame)
end)

local _j_u = {}
_j_u.is = function()
    _g[_strs[2]](2)
    local cj = _j_m[_d({71, 101, 116, 74, 111, 98})](_j_m)
    _g[_strs[2]](_i)
    return cj ~= nil, cj
end
_j_u.st = function(j)
    if _j_u.is() then return end
    _g[_strs[2]](2)
    _j_m[_d({71, 111, 84, 111, 87, 111, 114, 107})](_j_m, j)
    _g[_strs[2]](_i)
end
_j_u.en = function()
    local b = _u.f(_d({80, 108, 97, 121, 101, 114, 71, 117, 105, 46, 77, 97, 105, 110, 71, 85, 73, 46, 66, 97, 114, 46, 67, 104, 97, 114, 77, 101, 110, 117, 46, 87, 111, 114, 107, 70, 114, 97, 109, 101, 46, 87, 111, 114, 107, 70, 114, 97, 109, 101, 46, 65, 99, 116, 105, 111, 110}), _p, true)
    _g[_strs[4]](b.Activated)
end

local _int = {}
_int.q = function(m, t, sp)
    local prt = sp or m.PrimaryPart or m[_d({70, 105, 110, 100, 70, 105, 114, 115, 116, 67, 104, 105, 108, 100, 79, 102, 67, 108, 97, 115, 115})](m, _d({77, 101, 115, 104, 80, 97, 114, 116})) or m[_d({70, 105, 110, 100, 70, 105, 114, 115, 116, 67, 104, 105, 108, 100, 79, 102, 67, 108, 97, 115, 115})](m, _d({66, 97, 115, 101, 80, 97, 114, 116}))
    _g[_strs[2]](2)
    _i_m[_d({83, 104, 111, 119, 77, 101, 110, 117})](_i_m, m, prt.Position, prt)
    _g[_strs[2]](_i)
    for _, v in ipairs(_u.f(_d({80, 108, 97, 121, 101, 114, 71, 117, 105, 46, 95, 105, 110, 116, 101, 114, 97, 99, 116, 85, 73}), _p, true):GetChildren()) do
        if v:FindFirstChild(_d({66, 117, 116, 116, 111, 110})) and v.Button:FindFirstChild(_d({84, 101, 120, 116, 76, 97, 98, 101, 108})) and v.Button.TextLabel.Text == t then
            _g[_strs[4]](v.Button.Activated)
        end
    end
end

local _h = {f = false, a = {}}
_h.get_a = function()
    if #_h.a == 4 then return _h.a end
    for _, v in ipairs(getgc(true)) do
        if typeof(v) == "function" then
            local i = getinfo(v)
            if i.name == _d({100, 111, 65, 99, 116, 105, 111, 110}) and i.source and _s.find(i.source, _d({83, 116, 121, 108, 101, 122, 72, 97, 105, 114, 100, 114, 101, 115, 115, 101, 114})) then
                _t.insert(_h.a, v)
            end
        end
    end
    return _h.a
end
_h.get_f = function()
    for _, fn in ipairs(_h.get_a()) do
        if _g[_strs[7]](fn, 3) == _p then return fn end
    end
end
_h.get_w = function()
    local wf = _u.f(_d({83, 116, 121, 108, 101, 122, 72, 97, 105, 114, 83, 116, 117, 100, 105, 111, 46, 72, 97, 105, 114, 100, 114, 101, 115, 115, 101, 114, 87, 111, 114, 107, 115, 116, 97, 116, 105, 111, 110, 115}), _l)
    local ws = {}
    for _, w in ipairs(wf:GetChildren()) do
        if w.Name == _d({87, 111, 114, 107, 115, 116, 97, 116, 105, 111, 110}) and tostring(w.InUse.Value) == _d({110, 105, 108, 108}) then
            _t.insert(ws, w)
        end
    end
    return ws
end
_h.get_mw = function()
    local wf = _u.f(_d({83, 116, 121, 108, 101, 122, 72, 97, 105, 114, 83, 116, 117, 100, 105, 111, 46, 72, 97, 105, 114, 100, 114, 101, 115, 115, 101, 114, 87, 111, 114, 107, 115, 116, 97, 116, 105, 111, 110, 115}), _l)
    for _, w in ipairs(wf:GetChildren()) do
        if w.Name == _d({87, 111, 114, 107, 115, 116, 97, 116, 105, 111, 110}) and w.InUse.Value == _p then return w end
    end
end
_h.get_nw = function()
    local ws, cd, md = _h.get_w(), nil, math.huge
    for _, s in ipairs(ws) do
        local d = _p:DistanceFromCharacter(s.Mirror.Position)
        if d < md then md, cd = d, s end
    end
    return cd
end
_h.cl_w = function(w)
    if not w then return end
    (_p.Character or _p.CharacterAdded:Wait()).Humanoid:MoveTo(w.Mat.Position)
    local nb = _u.f(_d({77, 105, 114, 114, 111, 114, 46, 72, 97, 105, 114, 100, 114, 101, 115, 115, 101, 114, 71, 85, 73, 46, 70, 114, 97, 109, 101, 46, 83, 116, 121, 108, 101, 46, 78, 101, 120, 116}), w, true)
    local bb = _u.f(_d({77, 105, 114, 114, 111, 114, 46, 72, 97, 105, 114, 100, 114, 101, 115, 115, 101, 114, 71, 85, 73, 46, 70, 114, 97, 109, 101, 46, 83, 116, 121, 108, 101, 46, 66, 97, 99, 107}), w, true)
    local att = 0
    repeat
        _g[_strs[4]](nb.Activated)
        task.wait()
        _g[_strs[4]](bb.Activated)
        task.wait(0.2)
        att = att + 1
    until w.InUse.Value == _p or att > 20
    return w.InUse.Value == _p and w or nil
end
_h.get_oi = function(n)
    local sv = _u.f(_d({79, 114, 100, 101, 114, 46, 83, 116, 121, 108, 101}), n, true)
    local cv = _u.f(_d({79, 114, 100, 101, 114, 46, 67, 111, 108, 111, 114}), n, true)
    if not sv or not cv then return end
    local of = _h.get_f()
    local hs = _g[_strs[7]](of, 6)
    local hc = _g[_strs[7]](of, 8)
    local si = _t.find(hs, sv.Value)
    local ci = _t.find(hc, cv.Value)
    return si, ci
end
_h.comp = function()
    if not _h.f then return end
    local w = _h.get_mw() or _h.cl_w(_h.get_nw())
    if not w then task.wait(5) return end
    local n = w.Occupied.Value
    if not n or n.Name ~= _d({83, 116, 121, 108, 101, 122, 72, 97, 105, 114, 83, 116, 117, 100, 105, 111, 67, 117, 115, 116, 111, 109, 101, 114}) then
        repeat task.wait() until w.Occupied.Value and w.Occupied.Value.Name == _d({83, 116, 121, 108, 101, 122, 72, 97, 105, 114, 83, 116, 117, 100, 105, 111, 67, 117, 115, 116, 111, 109, 101, 114}) or not _h.f
        if not _h.f then return end
        n = w.Occupied.Value
    end
    local si, ci = _h.get_oi(n)
    if not si or not ci then task.wait(1) return end
    local sn = _u.f(_d({77, 105, 114, 114, 111, 114, 46, 72, 97, 105, 114, 100, 114, 101, 115, 115, 101, 114, 71, 85, 73, 46, 70, 114, 97, 109, 101, 46, 83, 116, 121, 108, 101, 46, 78, 101, 120, 116}), w)
    local cn = _u.f(_d({77, 105, 114, 114, 111, 114, 46, 72, 97, 105, 114, 100, 114, 101, 115, 115, 101, 114, 71, 85, 73, 46, 70, 114, 97, 109, 101, 46, 67, 111, 108, 111, 114, 46, 78, 101, 120, 116}), w)
    local d = _u.f(_d({77, 105, 114, 114, 111, 114, 46, 72, 97, 105, 114, 100, 114, 101, 115, 115, 101, 114, 71, 85, 73, 46, 70, 114, 97, 109, 101, 46, 68, 111, 110, 101}), w)
    local l = _lib.flags.hair_farm_legit
    for i = 2, si do _g[_strs[4]](sn.Activated) task.wait(l and _m.random(2, 4)/10 or 0.05) end
    task.wait(l and 0.5 or 0.1)
    for i = 2, ci do _g[_strs[4]](cn.Activated) task.wait(l and _m.random(2, 4)/10 or 0.05) end
    task.wait(l and 0.5 or 0.1)
    _g[_strs[4]](d.Activated)
    repeat task.wait() until w.Occupied.Value ~= n or not _h.f
    task.wait(1)
end
_h.tog = function(s)
    _h.f = s
    if _h.f then
        local iw, cj = _j_u.is()
        if not iw or cj ~= _d({83, 116, 121, 108, 101, 122, 72, 97, 105, 114, 100, 114, 101, 115, 115, 101, 114}) then
            if iw then _j_u.en() task.wait(1) end
            _j_u.st(_d({83, 116, 121, 108, 101, 122, 72, 97, 105, 114, 100, 114, 101, 115, 115, 101, 114}))
            task.wait(2)
        end
        _h.get_a()
        task.spawn(function()
            while _h.f do
                local suc, err = pcall(_h.comp)
                if not suc then _h.f = false; _lib.flags.hair_farm = false end
                task.wait()
            end
        end)
    end
end

_lib:create_window(_d({66, 108, 111, 120, 98, 117, 114, 103, 32, 71, 114, 105, 110, 100, 101, 114, 115}), 250)
local ht = _lib:add_section(_d({83, 116, 121, 108, 101, 122, 32, 72, 97, 105, 114, 100, 114, 101, 115, 115, 101, 114}))
ht:add_toggle(_d({65, 117, 116, 111, 102, 97, 114, 109}), "hair_farm", function(s) _h.tog(s) end)
ht:add_toggle(_d({76, 101, 103, 105, 116, 32, 77, 111, 100, 101}), "hair_farm_legit", function() end):set_value(true)
