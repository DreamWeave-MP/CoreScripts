---@class vec3
local vec3 = {}

vec3.__index = vec3

function vec3:__call(x, y, z)
    return setmetatable({x = x or 0, y = y or 0, z = z or 0}, getmetatable(self))
end

function vec3:length()
    return math.sqrt(self.x^2 + self.y^2 + self.z^2)
end

function vec3.__pow(a, b)
    if type(b) ~= 'number' then return end
    return vec3(a.x^b, a.y^b, a.z^b)
end

function vec3.__add(a, b)
    return vec3(a.x + b.x, a.y + b.y, a.z + b.z)
end

function vec3.__sub(a, b)
    return vec3(a.x - b.x, a.y - b.y, a.z - b.z)
end

function vec3.__mul(a, b)
    if type(a) == 'number' then
        return vec3(a * b.x, a * b.y, a * b.z)
    elseif type(b) == 'number' then
        return vec3(a.x * b, a.y * b, a.z * b)
    end
    return vec3(a.x * b.x, a.y * b.y, a.z * b.z)
end

function vec3.__div(a, b)
    return vec3(a.x / b, a.y / b, a.z / b)
end

function vec3.__eq(a, b)
    return a.x == b.x and a.y == b.y and a.z == b.z
end

function vec3.__tostring(a)
    return "vec3(" .. a.x .. ", " .. a.y .. ', ' .. a.z .. ")"
end

---@class vec2
local vec2 = {}

vec2.__index = vec2

function vec2:__call(x, z)
    return setmetatable({x = x or 0, z = z or 0}, getmetatable(self))
end

function vec2:length()
    return math.sqrt(self.x^2 + self.z^2)
end

function vec2.__pow(a, b)
    if type(b) ~= 'number' then return end
    return vec2(a.x^b, a.z^b)
end

function vec2.__add(a, b)
    return vec2(a.x + b.x, a.z + b.z)
end

function vec2.__sub(a, b)
    return vec2(a.x - b.x, a.z - b.z)
end

function vec2.__mul(a, b)
    if type(a) == 'number' then
        return vec2(a * b.x, a * b.z)
    elseif type(b) == 'number' then
        return vec2(a.x * b, a.z * b)
    end
    return vec2(a.x * b.x, a.z * b.z)
end

function vec2.__div(a, b)
    return vec2(a.x / b, a.z / b)
end

function vec2.__eq(a, b)
    return a.x == b.x and a.z == b.z
end

function vec2.__tostring(a)
    return "vec2(" .. a.x .. ", " .. a.z .. ")"
end

return setmetatable({vec3 = vec3, vec2 = vec2})