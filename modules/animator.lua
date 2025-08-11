local Animator = {}
Animator.active_tweens = {}

-- Easing functions (simplified for clarity)
local Easing = {
    linear = function(t) return t end,
    easeOutCubic = function(t) return 1 - (1 - t)^3 end,
    easeInOutQuad = function(t) return t < 0.5 and 2 * t * t or 1 - (-2 * t + 2)^2 / 2 end
}

-- Helper to interpolate between two values (handles numbers and color tables)
local function lerp(a, b, t)
    if type(a) == "number" then
        return a + (b - a) * t
    elseif type(a) == "table" and type(b) == "table" then -- For colors {r,g,b,a}
        local result = {}
        for k, v in pairs(a) do
            result[k] = lerp(v, b[k] or v, t)
        end
        return result
    end
    return a
end

-- Create a new animation (tween)
function Animator.tween(target, property, to, duration, ease_func)
    ease_func = ease_func or Easing.easeOutCubic
    local from = {}
    -- Deep copy 'from' values to avoid reference issues
    for k, v in pairs(to) do
        from[k] = target[property][k]
    end

    local tween = {
        target = target,
        property = property,
        from = from,
        to = to,
        duration = duration,
        progress = 0,
        ease_func = ease_func
    }
    table.insert(Animator.active_tweens, tween)
    return tween
end

-- Update all active animations
function Animator.update(dt)
    for i = #Animator.active_tweens, 1, -1 do
        local tween = Animator.active_tweens[i]
        tween.progress = tween.progress + dt

        local t = math.min(tween.progress / tween.duration, 1)
        local eased_t = tween.ease_func(t)

        tween.target[tween.property] = lerp(tween.from, tween.to, eased_t)

        if t >= 1 then
            table.remove(Animator.active_tweens, i)
        end
    end
end

return Animator
