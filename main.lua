-- 1. Setup
local Animator = require("modules/animator")
local Theme = require("modules/theme")
local Button = require("widgets/button")
-- Other widgets would be included here...

-- Global list to hold all widgets
local widgets = {}

function love.load()
    -- 2. Initialize Library Systems
    Theme.load(Theme.Dark) -- Load the dark theme

    -- 3. Create GUI Elements
    local myButton = Button.new("Click Me!", 50, 50, function()
        print("Button was clicked!")
    end)
    table.insert(widgets, myButton)
    
    -- Here you would create sliders, windows, etc.
end

function love.update(dt)
    -- 4. Update Core Systems
    Animator.update(dt) -- This runs all active animations

    local mx, my = love.mouse.getPosition()
    local is_down = love.mouse.isDown(1)
    
    -- Update all widgets with current input state
    for _, widget in ipairs(widgets) do
        widget:update(dt, mx, my, is_down)
    end
end

-- 5. Define the Renderer
-- This is the bridge between the UI library's abstract commands and LÖVE's specific drawing functions.
local function executeDrawCommands(commands)
    for _, cmd in ipairs(commands) do
        love.graphics.setColor(cmd.color.r, cmd.color.g, cmd.color.b, cmd.color.a)
        
        if cmd.type == "rect" then
            love.graphics.rectangle("fill", cmd.x, cmd.y, cmd.width, cmd.height, cmd.radius)
        elseif cmd.type == "text" then
            -- (Simplified text rendering logic)
            local font = love.graphics.newFont(cmd.size)
            love.graphics.setFont(font)
            love.graphics.printf(cmd.text, cmd.x, cmd.y, cmd.width or 100, cmd.align or "left")
        end
    end
end

function love.draw()
    -- 6. Render the UI
    for _, widget in ipairs(widgets) do
        local draw_commands = widget:draw()
        executeDrawCommands(draw_commands)
    end
    
    love.graphics.print("Move mouse over the button and click!", 50, 100)
end
