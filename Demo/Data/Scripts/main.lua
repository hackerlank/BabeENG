-- Introduction To Urho3D

-- Main

require 'Scripts/levelgenerator'
require 'Scripts/picking'

g_gamestate=nil
g_newgamestate=nil

g_noderemovelist={}
count=0

drawDebug = 0

emptyvm = VariantMap()

function Start()
	SubscribeToEvent("Update", "HandleUpdate")
	SubscribeToEvent("PostRenderUpdate", "HandlePostRenderUpdate")
	
	--context = GetContext()
	cache = GetCache()
	input = GetInput()
	renderer = GetRenderer()
	ui = GetUI()
	graphics = GetGraphics()
	log = GetLog()
	log.level = LOG_DEBUG
	engine = GetEngine()
	--input:SetMouseVisible(true)
	
	-- Get default style
    local uiStyle = cache:GetResource("XMLFile", "UI/DefaultStyle.xml")
    if uiStyle == nil then
        return
    end

    -- Create console
    engine:CreateConsole()
    console.defaultStyle = uiStyle
    console.background.opacity = 0.8

    -- Create debug HUD
    engine:CreateDebugHud()
    debugHud.defaultStyle = uiStyle
			
	local icon = cache:GetResource("Image", "Textures/UrhoIcon.png")
    graphics:SetWindowIcon(icon)
    graphics.windowTitle = "WalkStep"
	
	cursor = Cursor:new()
	cursor:DefineShape(CS_NORMAL, cache:GetResource("Image", "Textures/uilib.png"), IntRect(64,64,127,127), IntVector2(22, 18))
	ui.cursor = cursor
	ui.cursor.visible = true
	ui.cursor:SetPosition(ui.root.width/2, ui.root.height/2)
	
	local font = cache:GetResource("Font", "UI/BlueHighway.ttf")
	local fontsize = 18
	
	function label(text,x,y)
		local t=ui.root:CreateChild("Text")
		t:SetFont(font,fontsize)
		t:SetText(text)
		t:SetPosition(Vector2(x,y))
	end
	
	local h = graphics:GetHeight()
	
	label("Controls\n\nUse Middle Mouse to move camera (when spin or pitch are enabled)\nUse Mouse Wheel to zoom in/out (when zoom enabled)\n\nKey 1: Toggle Spin Control\nKey 2: Toggle Pitch Control\nKey 3: Toggle Zoom Control\nKey 4: Toggle Camera Clipping\nKey 5: Toggle Soft Camera Tracking\nKey 6: Toggle Orthographic", 0, 0)
	
	
	renderer.drawShadows=true
	renderer.shadowMapSize = 1024
	renderer.shadowQuality = SHADOWQUALITY_LOW_16BIT
	
	g_newgamestate = GenerateLevel()
	
end

function Stop()
	print("Stopping.\n")
end

function HandlePostRenderUpdate(eventType, eventData)
		
	if drawDebug == 1 then
        renderer:DrawDebugGeometry(true)
    end
    if drawDebug == 2 then
        --g_gamestate.scene:GetComponent("PhysicsWorld"):DrawDebugGeometry(true)
		g_gamestate.scene:GetComponent("NavigationMesh"):DrawDebugGeometry(true)
    end
end

function HandleUpdate(eventType, eventData)
	count = count + 1
	
	if count == 120 then
		print("gc:", collectgarbage("count").."\n")
		count = 0
		collectgarbage()
	end
	
	FlushRemovedNodes() -- Remove any nodes that were queued for removal last update
	
	if g_newgamestate then
		if g_gamestate and g_gamestate.Stop then g_gamestate:Stop() end
		g_gamestate=g_newgamestate
		g_newgamestate=nil
		if g_gamestate and g_gamestate.Start then g_gamestate:Start() end
		return
	end
	
	if input:GetKeyPress(KEY_PRINTSCREEN) then
		--vm:SetString("filename", filename)
		--SendEvent("TakeScreenshot", vm)
	elseif input:GetKeyPress(KEY_ESC) then
		-- if g_gamestate and g_gamestate.Stop then g_gamestate:Stop() end
		-- g_gamestate=nil
		-- engine:Exit()
		-- return
	elseif input:GetKeyPress(KEY_R) then
		SendEvent("Report", vm)
	end
	
	-- Do any per-state updating as required
	local dt = eventData["TimeStep"]:GetFloat()
	--print("main HandleUpdate: ", dt)
	if g_gamestate and g_gamestate.Update then g_gamestate:Update(dt) end
	-- Test picking
	if g_gamestate then
		local pick=Pick(g_gamestate.scene, 100)
		if pick then
			pick:SendEvent("Pick", emptyvm)
			print("Pick")
		end
	end
end

function RemoveNode(node)
	-- See if already queued for removal
	local n
	for _,n in ipairs(g_noderemovelist) do
		if n==node then return end
	end
	
	table.insert(g_noderemovelist, node)
	node.enabled=false
end

function FlushRemovedNodes()
	local i,n
	for i=#g_noderemovelist,1,-1 do
		n=g_noderemovelist[i]
		n:RemoveAllComponents()
		n:RemoveAllChildren()
		n:Remove()
		g_noderemovelist[i]=nil
	end
	
	g_noderemovelist={}
end