local Theme = {
    current = {}
}

-- Default Dark Theme
Theme.Dark = {
    name = "Dark",
    background = {r=24, g=26, b=32, a=255},
    button = {
        background = {r=50, g=54, b=64, a=255},
        text = {r=220, g=220, b=220, a=255},
        hover = {r=70, g=75, b=86, a=255},
        pressed = {r=40, g=44, b=52, a=255},
        radius = 8,
        height = 40
    },
    slider = {
        track = {r=40, g=44, b=52, a=255},
        thumb = {r=90, g=96, b=108, a=255},
        fill = {r=100, g=110, b=255, a=255},
        hover = {r=110, g=116, b=128, a=255},
        radius = 4,
        height = 10
    },
    font = "Arial" -- Placeholder font name
}

function Theme.load(theme_table)
    Theme.current = theme_table
end

function Theme.get(key)
    local parts = {}
    for part in string.gmatch(key, "[^.]+") do table.insert(parts, part) end
    
    local value = Theme.current
    for _, part in ipairs(parts) do
        if value and value[part] then
            value = value[part]
        else
            return nil
        end
    end
    return value
end

return Theme
