
local window
--
--Entry Point
--
function Start()
	log = GetLog()
	fs = GetFileSystem()

	log:Open("modelEditor.log")
	OpenConsoleWindow()
	Log:Write(LOG_INFO, "### Start ModelEditor###")
	Log:Write(LOG_INFO, "Platform: " .. GetPlatform())
	Log:Write(LOG_INFO, "ProgramDir: " .. fs:GetProgramDir())
	Log:Write(LOG_INFO, "CurrentDir: " .. fs:GetCurrentDir())
	Log:Write(LOG_INFO, "PhysicalCPUs: " .. GetNumPhysicalCPUs())
	Log:Write(LOG_INFO, "NumLogicalCPUs: " .. GetNumLogicalCPUs())
	
	--OpenConsoleWindow()
	--GetConsoleInput()
	input.mouseVisible = true

    -- Load XML file containing default UI style sheet
    local style = cache:GetResource("XMLFile", "UI/DefaultStyle.xml")
    -- Set the loaded style as default style
    ui.root.defaultStyle = style
    -- Initialize Window
	CreateMainMenu()
end
--Stop Point
function Stop()
	Log:Write(LOG_INFO, "Stop")
end

function CreateMainMenu()
	-- Create the Window and add it to the UI's root node
    window = Window:new()
    ui.root:AddChild(window)

    -- Set Window size and layout settings
    --window:SetMinSize(384, 192)
	window:SetMinSize(600, 800)
    --window:SetLayout(LM_VERTICAL, 6, IntRect(6, 6, 6, 6))
    window:SetAlignment(HA_CENTER, VA_CENTER)
    window:SetName("Window")
	window:SetLayout(LM_VERTICAL, 0, IntRect(6, 6, 6, 6))

    -- Create Window 'titlebar' container
    local titleBar = UIElement:new()
    titleBar:SetMinSize(0, 24)
    titleBar.verticalAlignment = VA_TOP
    titleBar.layoutMode = LM_HORIZONTAL

    -- Create the Window title Text
    local windowTitle = Text:new()
    windowTitle.name = "WindowTitle"
    windowTitle.text = "分享的快乐"


    -- Create the Window's close button
    local buttonClose = Button:new()
    buttonClose:SetName("CloseButton")

    -- Add the controls to the title bar
    titleBar:AddChild(windowTitle)
    titleBar:AddChild(buttonClose)

    -- Add the title bar to the Window
    window:AddChild(titleBar)
	
	-- Apply styles
    window:SetStyleAuto()
    windowTitle:SetStyleAuto()
    buttonClose:SetStyle("CloseButton")
	
	 -- Subscribe to buttonClose release (following a 'press') events
    SubscribeToEvent(buttonClose, "Released",
        function (eventType, eventData)
            engine:Exit()
        end)

    -- Subscribe also to all UI mouse clicks just to see where we have clicked
    SubscribeToEvent("UIMouseClick", HandleControlClicked)
		
end

function HandleControlClicked(eventType, eventData)
	-- Get the Text control acting as the Window's title
	local element = window:GetChild("WindowTitle", true)
	local windowTitle = tolua.cast(element, 'Text')

	-- Get control that was clicked
	local clicked = eventData["Element"]:GetPtr("UIElement")
	local name = "...?"
	if clicked ~= nil then
		-- Get the name of the control that was clicked
		name = clicked.name
	end

	-- Update the Window's title text
	windowTitle.text = "Hello " .. name .. "!"
end