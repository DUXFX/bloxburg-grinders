-- shit ui library, I made it super duper fast and only made what I needed.
-- it's specifically for a bloxburg autofarm, so all I needed was toggles, buttons and labels.


local tween_service = game:GetService("TweenService");
local user_input_service = game:GetService("UserInputService");
local library = { flags = {} };
local window_open = false;

function library:create_window(title, base_width)
	base_width = base_width or 250;
	local uI = Instance.new("ScreenGui")
	uI.Name = "UI"
	uI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local main = Instance.new("Frame")
	main.Name = "Main"
	main.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
	main.BorderColor3 = Color3.fromRGB(0, 0, 0)
	main.BorderSizePixel = 0
	main.ClipsDescendants = true
	main.Position = UDim2.fromOffset(100, 50)
	main.Size = UDim2.fromOffset(base_width, 44)

	local mainCorner = Instance.new("UICorner")
	mainCorner.Name = "MainCorner"
	mainCorner.Parent = main

	local content = Instance.new("ScrollingFrame")
	content.Name = "Content"
	content.Active = true
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	content.BackgroundTransparency = 1
	content.BorderColor3 = Color3.fromRGB(0, 0, 0)
	content.BorderSizePixel = 0
	content.CanvasSize = UDim2.new()
	content.Position = UDim2.fromOffset(0, 44)
	content.ScrollBarThickness = 2
	content.Size = UDim2.new(1, 0, 1, -44)

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.Name = "ContentLayout"
	contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Parent = content

	local contentPadding = Instance.new("UIPadding")
	contentPadding.Name = "ContentPadding"
	contentPadding.Parent = content
	
	content.Parent = main

	local mainTitle = Instance.new("TextLabel")
	mainTitle.Name = "MainTitle"
	mainTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	mainTitle.BackgroundTransparency = 1
	mainTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
	mainTitle.BorderSizePixel = 0
	mainTitle.FontFace = Font.new(
		"rbxassetid://12187365364",
		Enum.FontWeight.ExtraBold,
		Enum.FontStyle.Normal
	)
	mainTitle.Size = UDim2.new(1, 0, 0, 44)
	mainTitle.Text = title
	mainTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	mainTitle.TextSize = 18
	mainTitle.TextWrapped = true

	local mainToggle = Instance.new("ImageButton")
	mainToggle.Name = "MainToggle"
	mainToggle.AnchorPoint = Vector2.new(0, 0.5)
	mainToggle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	mainToggle.BackgroundTransparency = 1
	mainToggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
	mainToggle.BorderSizePixel = 0
	mainToggle.Image = "http://www.roblox.com/asset/?id=6031091004"
	mainToggle.Position = UDim2.new(1, -36, 0.5, 0)
	mainToggle.Size = UDim2.fromOffset(30, 30)
	mainToggle.Parent = mainTitle

	mainTitle.Parent = main

	main.Parent = uI

	local function parentGui(ui)
		local cloneref = cloneref or function(...) return ... end;
		local playerGui = game:GetService("Players").LocalPlayer.PlayerGui;

		if game:GetService("RunService"):IsStudio() then
			ui.Parent = playerGui;
		end

		local success, errMsg = pcall(function()
			ui.Parent = cloneref(game:GetService("CoreGui"));
		end);

		if not success then
			ui.Parent = playerGui
		end
	end
	uI.Parent =  and  or ;
	
	local start_mouse_pos, start_frame_pos, is_dragging = nil, nil, false;
	
	mainTitle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			is_dragging = true;
			start_mouse_pos = input.Position;
			start_frame_pos = main.Position;
		end
	end)
	
	user_input_service.InputChanged:Connect(function(input)
		if is_dragging then
			local delta = input.Position - start_mouse_pos;
			main.Position = UDim2.fromOffset(start_frame_pos.X.Offset + delta.X, start_frame_pos.Y.Offset + delta.Y)
		end
	end)
	
	user_input_service.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and is_dragging then
			is_dragging = false;
			start_frame_pos = nil;
			start_mouse_pos = nil;
		end
	end)

	local current_y = 44
	local function toggle_window(state, skip)
		current_y = state and 44 + contentLayout.AbsoluteContentSize.Y or 44
		tween_service:Create(main, TweenInfo.new(skip and 0 or 0.15), {
			Size = UDim2.new(0, base_width, 0, current_y)
		}):Play()
		
		if not skip then
			tween_service:Create(mainToggle, TweenInfo.new(0.15), {
				Rotation = state and 180 or 0
			}):Play()
		end
	end
	
	contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		if window_open then
			local calculated_y = 44 + contentLayout.AbsoluteContentSize.Y;
			if calculated_y ~= current_y then
				toggle_window(true, true);
			end
		end
	end);
	
	mainToggle.Activated:Connect(function()
		window_open = not window_open;
		toggle_window(window_open);
	end);
	
	library.content = content;
end

local active_section = nil

function library:add_section(title)
	if not library.content then
		return error("You must create the window before you add a section dum dum", 0);
	end
	
	local section = Instance.new("Frame")
	section.Name = "Section"
	section.BackgroundColor3 = Color3.fromRGB(44, 44, 44)
	section.BackgroundTransparency = 1
	section.BorderColor3 = Color3.fromRGB(0, 0, 0)
	section.BorderSizePixel = 0
	section.ClipsDescendants = true
	section.Size = UDim2.new(1, 0, 0, 40)

	local sectionTop = Instance.new("Frame")
	sectionTop.Name = "SectionTop"
	sectionTop.BackgroundColor3 = Color3.fromRGB(44, 44, 44)
	sectionTop.BorderColor3 = Color3.fromRGB(0, 0, 0)
	sectionTop.BorderSizePixel = 0
	sectionTop.Size = UDim2.new(1, 0, 0, 40)

	local sectionTopPadding = Instance.new("UIPadding")
	sectionTopPadding.Name = "SectionTopPadding"
	sectionTopPadding.PaddingLeft = UDim.new(0, 12)
	sectionTopPadding.Parent = sectionTop

	local sectionTitle = Instance.new("TextLabel")
	sectionTitle.Name = "SectionTitle"
	sectionTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sectionTitle.BackgroundTransparency = 1
	sectionTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
	sectionTitle.BorderSizePixel = 0
	sectionTitle.FontFace = Font.new(
		"rbxassetid://12187365364",
		Enum.FontWeight.SemiBold,
		Enum.FontStyle.Normal
	)
	sectionTitle.Size = UDim2.new(0, 50, 1, 0)
	sectionTitle.Text = title
	sectionTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	sectionTitle.TextSize = 16
	sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
	sectionTitle.Parent = sectionTop

	local sectionToggle = Instance.new("ImageButton")
	sectionToggle.Name = "SectionToggle"
	sectionToggle.AnchorPoint = Vector2.new(0, 0.5)
	sectionToggle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sectionToggle.BackgroundTransparency = 1
	sectionToggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
	sectionToggle.BorderSizePixel = 0
	sectionToggle.Image = "http://www.roblox.com/asset/?id=6034818372"
	sectionToggle.Position = UDim2.new(1, -40, 0.5, 0)
	sectionToggle.Size = UDim2.fromOffset(34, 30)
	sectionToggle.Parent = sectionTop

	sectionTop.Parent = section

	local sectionLayout = Instance.new("UIListLayout")
	sectionLayout.Name = "SectionLayout"
	sectionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	sectionLayout.Padding = UDim.new(0, 8)
	sectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sectionLayout.Parent = section

	local sectionPadding = Instance.new("UIPadding")
	sectionPadding.Name = "SectionPadding"
	sectionPadding.Parent = section

	section.Parent = library.content
	
	local section_open = false;
	local current_y = 40;
	local function toggle_section(state, skip)
		if not state then
			state = not section_open
		end
		
		section_open = state
		
		current_y = state and sectionLayout.AbsoluteContentSize.Y + 8 or 40;
		tween_service:Create(section, TweenInfo.new(0.15), {
			Size = UDim2.new(1, 0, 0, current_y)
		}):Play();
		
		if state == true and not skip then
			active_section = toggle_section
		end
		
		if not skip then
			tween_service:Create(sectionToggle, TweenInfo.new(0.15), {
				Rotation = state and 180 or 0
			}):Play()
		end
	end

	sectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		if section_open then
			local calculated_y = sectionLayout.AbsoluteContentSize.Y + 8;
			if calculated_y ~= current_y then
				toggle_section(true, true);
			end
		end
	end);

	sectionToggle.Activated:Connect(function()
		toggle_section();
	end);
		
	local components = {};
	
	function components:add_button(text, callback)
		local button = Instance.new("Frame")
		button.Name = "Button"
		button.BackgroundColor3 = Color3.fromRGB(44, 44, 44)
		button.BorderColor3 = Color3.fromRGB(0, 0, 0)
		button.BorderSizePixel = 0
		button.Size = UDim2.new(1, -16, 0, 40)

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.Name = "ButtonCorner"
		buttonCorner.CornerRadius = UDim.new(0, 6)
		buttonCorner.Parent = button

		local buttonElement = Instance.new("TextButton")
		buttonElement.Name = "ButtonElement"
		buttonElement.AnchorPoint = Vector2.new(0.5, 0.5)
		buttonElement.AutoButtonColor = false
		buttonElement.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		buttonElement.BorderColor3 = Color3.fromRGB(0, 0, 0)
		buttonElement.BorderSizePixel = 0
		buttonElement.FontFace = Font.new(
			"rbxassetid://12187365364",
			Enum.FontWeight.SemiBold,
			Enum.FontStyle.Normal
		)
		buttonElement.Position = UDim2.fromScale(0.5, 0.5)
		buttonElement.Size = UDim2.new(1, -6, 1, -6)
		buttonElement.TextColor3 = Color3.fromRGB(255, 255, 255)
		buttonElement.TextSize = 16
		buttonElement.Text = text
		buttonElement.TextXAlignment = Enum.TextXAlignment.Left

		local buttonElementCorner = Instance.new("UICorner")
		buttonElementCorner.Name = "ButtonElementCorner"
		buttonElementCorner.CornerRadius = UDim.new(0, 6)
		buttonElementCorner.Parent = buttonElement

		local buttonElementPadding = Instance.new("UIPadding")
		buttonElementPadding.Name = "ButtonElementPadding"
		buttonElementPadding.PaddingLeft = UDim.new(0, 8)
		buttonElementPadding.Parent = buttonElement

		buttonElement.Parent = button

		button.Parent = section

		
		buttonElement.Activated:Connect(function()
			task.spawn(callback or function() end);
		end);
	end
	
	function components:add_toggle(text, flag, callback)
		library.flags[flag] = false;
		
		local toggle = Instance.new("Frame")
		toggle.Name = "Toggle"
		toggle.BackgroundColor3 = Color3.fromRGB(44, 44, 44)
		toggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
		toggle.BorderSizePixel = 0
		toggle.Size = UDim2.new(1, -16, 0, 40)

		local toggleCorner = Instance.new("UICorner")
		toggleCorner.Name = "ToggleCorner"
		toggleCorner.CornerRadius = UDim.new(0, 6)
		toggleCorner.Parent = toggle

		local toggleContent = Instance.new("Frame")
		toggleContent.Name = "ToggleContent"
		toggleContent.Active = true
		toggleContent.AnchorPoint = Vector2.new(0.5, 0.5)
		toggleContent.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		toggleContent.BorderColor3 = Color3.fromRGB(0, 0, 0)
		toggleContent.BorderSizePixel = 0
		toggleContent.Position = UDim2.fromScale(0.5, 0.5)
		toggleContent.Selectable = true
		toggleContent.Size = UDim2.new(1, -6, 1, -6)

		local toggleContentCorner = Instance.new("UICorner")
		toggleContentCorner.Name = "ToggleContentCorner"
		toggleContentCorner.CornerRadius = UDim.new(0, 6)
		toggleContentCorner.Parent = toggleContent

		local toggleContentPadding = Instance.new("UIPadding")
		toggleContentPadding.Name = "ToggleContentPadding"
		toggleContentPadding.PaddingLeft = UDim.new(0, 8)
		toggleContentPadding.Parent = toggleContent

		local textLabel = Instance.new("TextLabel")
		textLabel.Name = "TextLabel"
		textLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		textLabel.BackgroundTransparency = 1
		textLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
		textLabel.BorderSizePixel = 0
		textLabel.FontFace = Font.new(
			"rbxassetid://12187365364",
			Enum.FontWeight.SemiBold,
			Enum.FontStyle.Normal
		)
		textLabel.Size = UDim2.new(0, 50, 1, 0)
		textLabel.Text = text
		textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		textLabel.TextSize = 16
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.Parent = toggleContent

		local toggleBox = Instance.new("TextButton")
		toggleBox.Name = "ToggleBox"
		toggleBox.AnchorPoint = Vector2.new(0, 0.5)
		toggleBox.AutoButtonColor = false
		toggleBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		toggleBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
		toggleBox.BorderSizePixel = 0
		toggleBox.ClipsDescendants = true
		toggleBox.FontFace = Font.new(
			"rbxassetid://12187365364",
			Enum.FontWeight.SemiBold,
			Enum.FontStyle.Normal
		)
		toggleBox.Position = UDim2.new(1, -28, 0.5, 0)
		toggleBox.Size = UDim2.fromOffset(22, 22)
		toggleBox.Text = "✓"
		toggleBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		toggleBox.TextSize = 16

		local toggleBoxStroke = Instance.new("UIStroke")
		toggleBoxStroke.Name = "ToggleBoxStroke"
		toggleBoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		toggleBoxStroke.Color = Color3.fromRGB(44, 44, 44)
		toggleBoxStroke.Thickness = 2
		toggleBoxStroke.Parent = toggleBox

		local toggleBoxCorner = Instance.new("UICorner")
		toggleBoxCorner.Name = "ToggleBoxCorner"
		toggleBoxCorner.CornerRadius = UDim.new(0, 6)
		toggleBoxCorner.Parent = toggleBox

		local toggleBoxHide = Instance.new("Frame")
		toggleBoxHide.Name = "ToggleBoxHide"
		toggleBoxHide.AnchorPoint = Vector2.new(0.5, 0.5)
		toggleBoxHide.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		toggleBoxHide.BorderColor3 = Color3.fromRGB(0, 0, 0)
		toggleBoxHide.BorderSizePixel = 0
		toggleBoxHide.Position = UDim2.fromScale(0.5, 0.5)
		toggleBoxHide.Size = UDim2.fromScale(0.9, 0.9)

		toggleBoxHide.Parent = toggleBox

		toggleBox.Parent = toggleContent

		toggleContent.Parent = toggle

		toggle.Parent = section
		
		local function toggle_animation()
			local toggle_tween = tween_service:Create(toggleBoxHide, TweenInfo.new(0.15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
				Position = UDim2.new(library.flags[flag] and 1.5 or 0.5, 0, .5, 0);
			});

			toggle_tween:Play();
		end
		
		toggleBox.Activated:Connect(function()
			library.flags[flag] = not library.flags[flag];
			toggle_animation();
			callback(library.flags[flag]);
		end)
	end
	
	function components:add_label(label_text)
		local label = Instance.new("Frame")
		label.Name = "Label"
		label.AutomaticSize = Enum.AutomaticSize.Y
		label.BackgroundColor3 = Color3.fromRGB(44, 44, 44)
		label.BorderColor3 = Color3.fromRGB(0, 0, 0)
		label.BorderSizePixel = 0
		label.Position = UDim2.fromScale(0.0296, 0.391)
		label.Size = UDim2.new(1, -16, 0, 0)

		local labelCorner = Instance.new("UICorner")
		labelCorner.Name = "LabelCorner"
		labelCorner.CornerRadius = UDim.new(0, 6)
		labelCorner.Parent = label

		local text = Instance.new("TextLabel")
		text.Name = "Text"
		text.AutomaticSize = Enum.AutomaticSize.Y
		text.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		text.BackgroundTransparency = 1
		text.BorderColor3 = Color3.fromRGB(0, 0, 0)
		text.BorderSizePixel = 0
		text.FontFace = Font.new(
			"rbxassetid://12187365364",
			Enum.FontWeight.SemiBold,
			Enum.FontStyle.Normal
		)
		text.Size = UDim2.fromScale(1, 1)
		text.TextColor3 = Color3.fromRGB(255, 255, 255)
		text.TextSize = 16
		text.TextWrapped = true
		text.Text = label_text
		text.Parent = label

		local labelPadding = Instance.new("UIPadding")
		labelPadding.Name = "LabelPadding"
		labelPadding.PaddingBottom = UDim.new(0, 6)
		labelPadding.PaddingLeft = UDim.new(0, 12)
		labelPadding.PaddingRight = UDim.new(0, 12)
		labelPadding.PaddingTop = UDim.new(0, 6)
		labelPadding.Parent = label

		label.Parent = section
		
		return label;
	end
	
	return components;
end

return library;
