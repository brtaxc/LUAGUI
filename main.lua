--[[
	RBLX-ImGui Kütüphanesi
	Yazar: Gemini
	Tarih: 11.08.2025
	Açıklama: Roblox için tasarlanmış, tek bir script ile çalışan, ImGui felsefesine dayalı bir arayüz kütüphanesi.
	Kullanımı kolay, özelleştirilebilir temalara sahip ve estetik bir görünüm sunar.

	--- ÖRNEK KULLANIM ---
	
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ImGui = require(ReplicatedStorage.ImGuiModule) -- Modülün yolunu kendi projenize göre ayarlayın

	local RunService = game:GetService("RunService")

	-- Değişkenlerimizi tanımlıyoruz
	local showDemoWindow = true
	local myCheckboxValue = false
	local mySliderValue = 50
	local myColor = Color3.fromRGB(255, 0, 127)
	local myTextBoxValue = "Buraya yazın..."

	RunService.RenderStepped:Connect(function()
		-- Her karede arayüzü çizmeye başlıyoruz
		ImGui.Begin()

		-- Ana penceremizi oluşturuyoruz
		if ImGui.Window("Ana Menü", Vector2.new(100, 100), Vector2.new(350, 400)) then
			
			ImGui.Label("Bu bir ImGui kütüphanesidir.")
			ImGui.Separator()

			if ImGui.Button("Demo Penceresini Göster/Gizle") then
				showDemoWindow = not showDemoWindow
			end

			if ImGui.Checkbox("Bir Seçenek", myCheckboxValue) then
				myCheckboxValue = not myCheckboxValue
			end
			
			ImGui.Label("Seçenek Durumu: " .. tostring(myCheckboxValue))

			ImGui.Separator()
			
			ImGui.Label("Tema Ayarları")
			if ImGui.Button("Açık Tema") then
				ImGui.SetTheme("Light")
			end
			if ImGui.Button("Koyu Tema") then
				ImGui.SetTheme("Dark")
			end

		end
		ImGui.EndWindow()

		-- İkinci, daha karmaşık bir demo penceresi
		if showDemoWindow then
			if ImGui.Window("Demo Penceresi", Vector2.new(500, 100), Vector2.new(300, 350)) then
				ImGui.Label("Bu bir demo penceresidir.")
				ImGui.Separator()
				
				mySliderValue = ImGui.Slider("Değer", mySliderValue, 0, 100)
				ImGui.Label("Slider Değeri: " .. math.floor(mySliderValue))
				
				ImGui.Separator()
				
				myColor = ImGui.ColorPicker("Renk Seçimi", myColor)
				
				ImGui.Separator()
				
				myTextBoxValue = ImGui.TextBox("Metin Kutusu", myTextBoxValue)

			end
			ImGui.EndWindow()
		end

		-- Çizimi bitiriyoruz
		ImGui.End()
	end)
]]

local ImGui = {}
local ImGui_Metatable = { __index = ImGui }

-- Servisler
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- Dahili Durum (Internal State)
local state = {
	screenGui = nil,
	windows = {},
	activeWindow = nil,
	input = {
		mousePosition = Vector2.new(),
		mouseDown = false,
		mouseDownLastFrame = false,
		mouseClicked = false,
	},
	layout = {
		currentWindow = nil,
		cursorPos = Vector2.new(),
		itemSpacing = Vector2.new(8, 8),
		padding = Vector2.new(10, 10),
	},
	cache = {
		elements = {},
		usedThisFrame = {},
	},
	theme = {},
	font = Enum.Font.GothamSemibold,
	fontSize = 16,
}

-- Temalar
local Themes = {
	Dark = {
		WindowBg = Color3.fromRGB(20, 20, 22),
		TitleBg = Color3.fromRGB(30, 30, 32),
		TitleBgActive = Color3.fromRGB(70, 90, 120),
		Text = Color3.fromRGB(230, 230, 230),
		Border = Color3.fromRGB(50, 50, 50),
		Button = Color3.fromRGB(55, 55, 60),
		ButtonHover = Color3.fromRGB(70, 70, 75),
		ButtonActive = Color3.fromRGB(85, 85, 90),
		CheckboxBg = Color3.fromRGB(40, 40, 45),
		CheckboxTick = Color3.fromRGB(120, 150, 255),
		Separator = Color3.fromRGB(50, 50, 50),
		SliderGrab = Color3.fromRGB(120, 150, 255),
		SliderTrack = Color3.fromRGB(40, 40, 45),
		TextBoxBg = Color3.fromRGB(40, 40, 45),
	},
	Light = {
		WindowBg = Color3.fromRGB(240, 240, 240),
		TitleBg = Color3.fromRGB(225, 225, 225),
		TitleBgActive = Color3.fromRGB(180, 200, 230),
		Text = Color3.fromRGB(20, 20, 20),
		Border = Color3.fromRGB(180, 180, 180),
		Button = Color3.fromRGB(220, 220, 220),
		ButtonHover = Color3.fromRGB(205, 205, 205),
		ButtonActive = Color3.fromRGB(190, 190, 190),
		CheckboxBg = Color3.fromRGB(255, 255, 255),
		CheckboxTick = Color3.fromRGB(0, 120, 215),
		Separator = Color3.fromRGB(200, 200, 200),
		SliderGrab = Color3.fromRGB(0, 120, 215),
		SliderTrack = Color3.fromRGB(210, 210, 210),
		TextBoxBg = Color3.fromRGB(255, 255, 255),
	}
}
state.theme = Themes.Dark -- Varsayılan tema

-- Yardımcı Fonksiyonlar (Helper Functions)
local function getElement(id, className, parent)
	local fullId = tostring(state.layout.currentWindow) .. "_" .. id
	if not state.cache.elements[fullId] then
		local newElement = Instance.new(className)
		newElement.Parent = parent
		state.cache.elements[fullId] = newElement
	end
	state.cache.usedThisFrame[fullId] = true
	return state.cache.elements[fullId]
end

local function updateInput()
	state.input.mousePosition = UserInputService:GetMouseLocation()
	state.input.mouseDown = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
	state.input.mouseClicked = (state.input.mouseDown and not state.input.mouseDownLastFrame)
	state.input.mouseDownLastFrame = state.input.mouseDown
end

local function isMouseInRect(pos, size)
	local m = state.input.mousePosition
	return m.X >= pos.X and m.Y >= pos.Y and m.X <= pos.X + size.X and m.Y <= pos.Y + size.Y
end

local function placeItem(size)
	local window = state.windows[state.layout.currentWindow]
	local pos = window.position + state.layout.cursorPos
	
	local item = {}
	item.pos = pos
	item.size = size
	
	state.layout.cursorPos = state.layout.cursorPos + Vector2.new(0, size.Y + state.layout.itemSpacing.Y)
	
	return item
end

-- Kütüphane Fonksiyonları
function ImGui.Begin()
	-- ScreenGui'yi oluştur veya bul
	if not state.screenGui or not state.screenGui.Parent then
		state.screenGui = Instance.new("ScreenGui")
		state.screenGui.DisplayOrder = 999
		state.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		state.screenGui.ResetOnSpawn = false
		state.screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end
	
	-- Her karede kullanılacak elementleri sıfırla
	table.clear(state.cache.usedThisFrame)
	
	updateInput()
end

function ImGui.End()
	-- Bu karede kullanılmayan elementleri gizle
	for id, element in pairs(state.cache.elements) do
		if not state.cache.usedThisFrame[id] then
			element.Visible = false
		end
	end
	
	-- Aktif pencere sürüklenmiyorsa sıfırla
	if not state.input.mouseDown then
		state.activeWindow = nil
	end
end

function ImGui.Window(title, position, size)
	state.layout.currentWindow = title
	
	local window = state.windows[title]
	if not window then
		window = {
			position = position,
			size = size,
			isDragging = false,
			dragStart = nil,
			dragOffset = nil,
		}
		state.windows[title] = window
	end
	
	local titleBarHeight = 30
	local titleBarPos = window.position
	local titleBarSize = Vector2.new(window.size.X, titleBarHeight)

	-- Pencere sürükleme mantığı
	if state.activeWindow == nil and isMouseInRect(titleBarPos, titleBarSize) and state.input.mouseClicked then
		state.activeWindow = title
		window.isDragging = true
		window.dragOffset = state.input.mousePosition - window.position
	end

	if window.isDragging and state.input.mouseDown then
		window.position = state.input.mousePosition - window.dragOffset
	else
		window.isDragging = false
	end

	-- Ana pencere çerçevesi
	local frame = getElement(title, "Frame", state.screenGui)
	frame.Visible = true
	frame.Position = UDim2.fromOffset(window.position.X, window.position.Y)
	frame.Size = UDim2.fromOffset(window.size.X, window.size.Y)
	frame.BackgroundColor3 = state.theme.WindowBg
	frame.BorderSizePixel = 1
	frame.BorderColor3 = state.theme.Border
	frame.ZIndex = 1
	
	local corner = getElement(title .. "_corner", "UICorner", frame)
	corner.CornerRadius = UDim.new(0, 6)

	-- Başlık çubuğu
	local titleBar = getElement(title .. "_titlebar", "Frame", frame)
	titleBar.Position = UDim2.fromOffset(0, 0)
	titleBar.Size = UDim2.fromOffset(window.size.X, titleBarHeight)
	titleBar.BackgroundColor3 = state.activeWindow == title and state.theme.TitleBgActive or state.theme.TitleBg
	titleBar.BorderSizePixel = 0
	titleBar.ZIndex = 2
	
	local titleCorner = getElement(title .. "_titlecorner", "UICorner", titleBar)
	titleCorner.CornerRadius = UDim.new(0, 6)
	
	local titleLabel = getElement(title .. "_titlelabel", "TextLabel", titleBar)
	titleLabel.Size = UDim2.new(1, 0, 1, 0)
	titleLabel.Text = title
	titleLabel.Font = state.font
	titleLabel.TextSize = state.fontSize + 2
	titleLabel.TextColor3 = state.theme.Text
	titleLabel.BackgroundTransparency = 1
	titleLabel.ZIndex = 3

	-- İçerik için layout'u hazırla
	state.layout.cursorPos = Vector2.new(state.layout.padding.X, titleBarHeight + state.layout.padding.Y)
	
	return true
end

function ImGui.EndWindow()
	state.layout.currentWindow = nil
end

function ImGui.Label(text)
	local window = state.windows[state.layout.currentWindow]
	if not window then return end
	
	local textSize = Vector2.new(window.size.X - state.layout.padding.X * 2, state.fontSize + 4)
	local item = placeItem(textSize)
	
	local label = getElement(text, "TextLabel", state.cache.elements[state.layout.currentWindow])
	label.Visible = true
	label.Position = UDim2.fromOffset(item.pos.X - window.position.X, item.pos.Y - window.position.Y)
	label.Size = UDim2.fromOffset(item.size.X, item.size.Y)
	label.Text = text
	label.Font = state.font
	label.TextSize = state.fontSize
	label.TextColor3 = state.theme.Text
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 3
end

function ImGui.Button(text)
	local window = state.windows[state.layout.currentWindow]
	if not window then return false end
	
	local buttonSize = Vector2.new(window.size.X - state.layout.padding.X * 2, 30)
	local item = placeItem(buttonSize)
	
	local button = getElement(text, "TextButton", state.cache.elements[state.layout.currentWindow])
	button.Visible = true
	button.Position = UDim2.fromOffset(item.pos.X - window.position.X, item.pos.Y - window.position.Y)
	button.Size = UDim2.fromOffset(item.size.X, item.size.Y)
	button.Text = text
	button.Font = state.font
	button.TextSize = state.fontSize
	button.TextColor3 = state.theme.Text
	button.ZIndex = 3
	
	local corner = getElement(text .. "_corner", "UICorner", button)
	corner.CornerRadius = UDim.new(0, 4)
	
	local isHovered = isMouseInRect(item.pos, item.size)
	local isClicked = isHovered and state.input.mouseClicked and state.activeWindow == nil

	if isHovered then
		button.BackgroundColor3 = state.theme.ButtonHover
	else
		button.BackgroundColor3 = state.theme.Button
	end
	
	if isClicked then
		button.BackgroundColor3 = state.theme.ButtonActive
		return true
	end
	
	return false
end

function ImGui.Checkbox(text, checked)
	local window = state.windows[state.layout.currentWindow]
	if not window then return false end
	
	local checkboxSize = 20
	local itemSize = Vector2.new(window.size.X - state.layout.padding.X * 2, checkboxSize)
	local item = placeItem(itemSize)
	
	local fullRectPos = Vector2.new(item.pos.X, item.pos.Y)
	local fullRectSize = Vector2.new(item.size.X, item.size.Y)
	
	-- Checkbox kutusu
	local box = getElement(text .. "_box", "Frame", state.cache.elements[state.layout.currentWindow])
	box.Visible = true
	box.Position = UDim2.fromOffset(item.pos.X - window.position.X, item.pos.Y - window.position.Y)
	box.Size = UDim2.fromOffset(checkboxSize, checkboxSize)
	box.BackgroundColor3 = state.theme.CheckboxBg
	box.BorderSizePixel = 1
	box.BorderColor3 = state.theme.Border
	box.ZIndex = 3
	
	local corner = getElement(text .. "_box_corner", "UICorner", box)
	corner.CornerRadius = UDim.new(0, 4)
	
	-- Checkbox işareti
	local tick = getElement(text .. "_tick", "Frame", box)
	tick.Visible = checked
	tick.Position = UDim2.new(0.2, 0, 0.2, 0)
	tick.Size = UDim2.new(0.6, 0, 0.6, 0)
	tick.BackgroundColor3 = state.theme.CheckboxTick
	tick.BorderSizePixel = 0
	
	local tickCorner = getElement(text .. "_tick_corner", "UICorner", tick)
	tickCorner.CornerRadius = UDim.new(0, 2)
	
	-- Checkbox metni
	local label = getElement(text .. "_label", "TextLabel", state.cache.elements[state.layout.currentWindow])
	label.Visible = true
	label.Position = UDim2.fromOffset(item.pos.X - window.position.X + checkboxSize + 8, item.pos.Y - window.position.Y)
	label.Size = UDim2.fromOffset(item.size.X - checkboxSize - 8, item.size.Y)
	label.Text = text
	label.Font = state.font
	label.TextSize = state.fontSize
	label.TextColor3 = state.theme.Text
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 3

	local isHovered = isMouseInRect(fullRectPos, fullRectSize)
	if isHovered and state.input.mouseClicked and state.activeWindow == nil then
		return true
	end
	
	return false
end

function ImGui.Separator()
	local window = state.windows[state.layout.currentWindow]
	if not window then return end
	
	local separatorSize = Vector2.new(window.size.X - state.layout.padding.X * 2, 1)
	local item = placeItem(separatorSize)
	
	local line = getElement("separator_" .. item.pos.Y, "Frame", state.cache.elements[state.layout.currentWindow])
	line.Visible = true
	line.Position = UDim2.fromOffset(item.pos.X - window.position.X, item.pos.Y - window.position.Y)
	line.Size = UDim2.fromOffset(item.size.X, item.size.Y)
	line.BackgroundColor3 = state.theme.Separator
	line.BorderSizePixel = 0
	line.ZIndex = 3
end

function ImGui.Slider(text, value, min, max)
	local window = state.windows[state.layout.currentWindow]
	if not window then return value end
	
	local sliderHeight = 20
	local itemSize = Vector2.new(window.size.X - state.layout.padding.X * 2, sliderHeight)
	
	-- Önce metni yerleştir
	ImGui.Label(text)
	
	-- Sonra slider'ı yerleştir
	local item = placeItem(itemSize)
	
	local track = getElement(text .. "_track", "Frame", state.cache.elements[state.layout.currentWindow])
	track.Visible = true
	track.Position = UDim2.fromOffset(item.pos.X - window.position.X, item.pos.Y - window.position.Y)
	track.Size = UDim2.fromOffset(item.size.X, item.size.Y)
	track.BackgroundColor3 = state.theme.SliderTrack
	track.BorderSizePixel = 1
	track.BorderColor3 = state.theme.Border
	track.ZIndex = 3
	
	local corner = getElement(text .. "_track_corner", "UICorner", track)
	corner.CornerRadius = UDim.new(0, 4)
	
	local ratio = (value - min) / (max - min)
	local grabSize = 10
	
	local fill = getElement(text .. "_fill", "Frame", track)
	fill.Visible = true
	fill.Size = UDim2.new(ratio, 0, 1, 0)
	fill.BackgroundColor3 = state.theme.SliderGrab
	fill.BorderSizePixel = 0
	fill.ZIndex = 4
	
	local fillCorner = getElement(text .. "_fill_corner", "UICorner", fill)
	fillCorner.CornerRadius = UDim.new(0, 4)

	local isHovered = isMouseInRect(item.pos, item.size)
	if (isHovered and state.input.mouseDown and state.activeWindow == nil) then
		state.activeWindow = text .. "_slider" -- Bu slider'ı aktif hale getir
	end
	
	if state.activeWindow == text .. "_slider" then
		local mouseX = state.input.mousePosition.X
		local trackX = item.pos.X
		local newRatio = math.clamp((mouseX - trackX) / item.size.X, 0, 1)
		return min + (max - min) * newRatio
	end

	return value
end

function ImGui.ColorPicker(text, color)
	local window = state.windows[state.layout.currentWindow]
	if not window then return color end
	
	ImGui.Label(text)
	
	local r, g, b = color:ToHSV()
	
	r = ImGui.Slider("H (Renk Tonu)", r * 360, 0, 360) / 360
	g = ImGui.Slider("S (Doygunluk)", g * 100, 0, 100) / 100
	b = ImGui.Slider("V (Parlaklık)", b * 100, 0, 100) / 100
	
	local newColor = Color3.fromHSV(r, g, b)
	
	-- Renk önizlemesi
	local previewSize = Vector2.new(window.size.X - state.layout.padding.X * 2, 20)
	local item = placeItem(previewSize)
	
	local preview = getElement(text .. "_preview", "Frame", state.cache.elements[state.layout.currentWindow])
	preview.Visible = true
	preview.Position = UDim2.fromOffset(item.pos.X - window.position.X, item.pos.Y - window.position.Y)
	preview.Size = UDim2.fromOffset(item.size.X, item.size.Y)
	preview.BackgroundColor3 = newColor
	preview.BorderSizePixel = 1
	preview.BorderColor3 = state.theme.Border
	preview.ZIndex = 3
	
	local corner = getElement(text .. "_preview_corner", "UICorner", preview)
	corner.CornerRadius = UDim.new(0, 4)
	
	return newColor
end

function ImGui.TextBox(text, value)
	local window = state.windows[state.layout.currentWindow]
	if not window then return value end
	
	ImGui.Label(text)
	
	local boxSize = Vector2.new(window.size.X - state.layout.padding.X * 2, 30)
	local item = placeItem(boxSize)
	
	local textbox = getElement(text, "TextBox", state.cache.elements[state.layout.currentWindow])
	textbox.Visible = true
	textbox.Position = UDim2.fromOffset(item.pos.X - window.position.X, item.pos.Y - window.position.Y)
	textbox.Size = UDim2.fromOffset(item.size.X, item.size.Y)
	textbox.Font = state.font
	textbox.Text = value
	textbox.TextSize = state.fontSize
	textbox.TextColor3 = state.theme.Text
	textbox.BackgroundColor3 = state.theme.TextBoxBg
	textbox.BorderSizePixel = 1
	textbox.BorderColor3 = state.theme.Border
	textbox.ClearTextOnFocus = false
	textbox.ZIndex = 3
	
	local corner = getElement(text .. "_corner", "UICorner", textbox)
	corner.CornerRadius = UDim.new(0, 4)
	
	if textbox:IsFocused() then
		state.activeWindow = text .. "_textbox"
	elseif state.activeWindow == text .. "_textbox" and not textbox:IsFocused() then
		state.activeWindow = nil
	end
	
	return textbox.Text
end


-- Genel Ayarlar
function ImGui.SetTheme(themeName)
	if Themes[themeName] then
		state.theme = Themes[themeName]
	else
		warn("ImGui: Geçersiz tema adı - " .. tostring(themeName))
	end
end

return ImGui
