local Animator = require("modules/animator")
local Theme = require("modules/theme")

-- Base Widget "class" would be defined elsewhere
local Button = { x = 0, y = 0, width = 150, text = "Button" }
Button.__index = Button

function Button.new(text, x, y, onClick)
    local self = setmetatable({}, Button)
    
    self.text = text
    self.x = x
    self.y = y
    self.onClick = onClick or function() end
    
    -- Get initial styles from the theme
    self.height = Theme.get("button.height")
    self.radius = Theme.get("button.radius")
    
    -- This 'style' table is what we will animate
    self.style = {
        background = Theme.get("button.background"),
        scale = 1.0
    }
    
    self.state = "idle" -- "idle", "hover", "pressed"
    
    return self
end

-- Commentary: How animations are triggered
-- The update function checks for state changes. If the state changes (e.g., from "idle" to "hover"),
-- it doesn't just change the color instantly. Instead, it calls Animator.tween() to start a
-- smooth transition from the current color to the target theme color over 0.2 seconds.
function Button:update(dt, mouse_x, mouse_y, is_mouse_down)
    local is_hovering = (mouse_x > self.x and mouse_x < self.x + self.width and
                         mouse_y > self.y and mouse_y < self.y + self.height)

    local new_state = "idle"
    if is_hovering then
        new_state = is_mouse_down and "pressed" or "hover"
    end
    
    -- Check if state changed to trigger animations
    if new_state ~= self.state then
        self.state = new_state
        local target_color
        local target_scale = 1.0
        
        if self.state == "hover" then
            target_color = Theme.get("button.hover")
        elseif self.state == "pressed" then
            target_color = Theme.get("button.pressed")
            target_scale = 0.95 -- Button visually shrinks when pressed
        else -- idle
            target_color = Theme.get("button.background")
        end
        
        -- Start the animations!
        Animator.tween(self, "style", { background = target_color }, 0.2)
        Animator.tween(self, "style", { scale = target_scale }, 0.15)
        
        -- Trigger the click event on mouse release
        if not is_mouse_down and is_hovering and self.was_pressed then
            self.onClick()
        end
    end

    self.was_pressed = is_mouse_down and is_hovering
end

-- This function just describes what to draw. The main GUI manager will call the real renderer.
function Button:draw()
    local w = self.width * self.style.scale
    local h = self.height * self.style.scale
    local offset_x = (self.width - w) / 2
    local offset_y = (self.height - h) / 2

    return {
        {
            type = "rect",
            x = self.x + offset_x, y = self.y + offset_y,
            width = w, height = h,
            color = self.style.background,
            radius = self.radius * self.style.scale
        },
        {
            type = "text",
            text = self.text,
            x = self.x + self.width / 2,
            y = self.y + self.height / 2,
            font = Theme.get("font"),
            size = 16,
            color = Theme.get("button.text"),
            align = "center"
        }
    }
end

return Button
