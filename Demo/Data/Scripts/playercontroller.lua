-- Player Controller
--

-- PointClickFollow Controller

-- Introduction to Urho3D

-- Point and Click Controller
-- Basic D2-ish point and click controller

--

-- PointClickFollow Controller

-- Introduction to Urho3D

-- Point and Click Controller
-- Basic D2-ish point and click controller

require 'Scripts/Class'

PathTracker = class(function(self, path, navmesh)
	if #path<2 then return end
	self.navmesh = navmesh
	self.path = path
	self.currentindex = 2
	self.currenttarget = path[2]
end)

function PathTracker:getStepVectorAndAngle(mypos ,dt, speed)
	if self.path == nil or self.currentindex > #self.path then 
		print("fuck1")
		return nil 
	end -- Can't go further

	local delta = self.currenttarget - mypos
	local len = delta:Length()
	delta:Normalize()
	--print("getStepVectorAndAngle: ", len, dt*speed, self.currentindex, #self.path)
	if len <= dt*speed then
		self.currentindex = self.currentindex + 1
		if self.currentindex <= #self.path then 
			self.currenttarget = self.path[self.currentindex] 
		else
			print("fuck2")
			self.path = nil 
			self.currenttarget = nil 
		end
		return delta * Vector3(len, len, len), math.atan2(delta.z,delta.x)*180/math.pi
	else
		return delta * Vector3(dt*speed, dt*speed, dt*speed), math.atan2(delta.z,delta.x)*180/math.pi
	end
end

PlayerController = ScriptObject()

function PlayerController:Start()

	print("PlayerController:Start()")
	self:SubscribeToEvent("Update", "PlayerController:HandleUpdate")
	self:SubscribeToEvent("MouseButtonDown", "PlayerController:HandleMouseButtonDown")
	self:SubscribeToEvent("MouseButtonUp", "PlayerController:HandleMouseButtonUp")
	self:SubscribeToEvent("KeyDown", "PlayerController:HandleKeyDown")
	self.pathtracker = nil
	self.speed = 2
	self.vm = VariantMap()
	
	self.targetid = nil
	self.lmbdown = false
	
	self.state = "idle"
	self.node:GetVars()["player"] = true
	
	self.rotationvel = 720
	self.curangle = 0
	self.nextangle = 0
	self.lastuse = 0
	self.lastusedelta = 0
end

function PlayerController:HandleKeyDown(eventType, eventData)
    local key = eventData["Key"]:GetInt()
    -- Close console (if open) or exit when ESC is pressed
    if key == KEY_ESC then
        if not console:IsVisible() then
            if g_gamestate and g_gamestate.Stop then g_gamestate:Stop() end
			g_gamestate=nil
			engine:Exit()
        else
            console:SetVisible(false)
        end		
    elseif key == KEY_F1 then
        console:Toggle()

    elseif key == KEY_F2 then
        debugHud:ToggleAll()
    end

    if ui.focusElement == nil then
        -- Preferences / Pause
        if key == KEY_SELECT and touchEnabled then
            paused = not paused
            if screenJoystickSettingsIndex == M_MAX_UNSIGNED then
                -- Lazy initialization
                screenJoystickSettingsIndex = input:AddScreenJoystick(cache:GetResource("XMLFile", "UI/ScreenJoystickSettings_Samples.xml"), cache:GetResource("XMLFile", "UI/DefaultStyle.xml"))
            else
                input:SetScreenJoystickVisible(screenJoystickSettingsIndex, paused)
            end

        -- Texture quality
        elseif key == KEY_1 then
            local quality = renderer.textureQuality
            quality = quality + 1
            if quality > QUALITY_HIGH then
                quality = QUALITY_LOW
            end
            renderer.textureQuality = quality

        -- Material quality
        elseif key == KEY_2 then
            local quality = renderer.materialQuality
            quality = quality + 1
            if quality > QUALITY_HIGH then
                quality = QUALITY_LOW
            end
            renderer.materialQuality = quality

        -- Specular lighting
        elseif key == KEY_3 then
            renderer.specularLighting = not renderer.specularLighting

        -- Shadow rendering
        elseif key == KEY_4 then
            renderer.drawShadows = not renderer.drawShadows

        -- Shadow map resolution
        elseif key == KEY_5 then
            local shadowMapSize = renderer.shadowMapSize
            shadowMapSize = shadowMapSize * 2
            if shadowMapSize > 2048 then
                shadowMapSize = 512
            end
            renderer.shadowMapSize = shadowMapSize

        -- Shadow depth and filtering quality
        elseif key == KEY_6 then
            local quality = renderer.shadowQuality
            quality = quality + 1
            if quality > SHADOWQUALITY_HIGH_24BIT then
                quality = SHADOWQUALITY_LOW_16BIT
            end
            renderer.shadowQuality = quality

        -- Occlusion culling
        elseif key == KEY_7 then
            local occlusion = renderer.maxOccluderTriangles > 0
            occlusion = not occlusion
            if occlusion then
                renderer.maxOccluderTriangles = 5000
            else
                renderer.maxOccluderTriangles = 0
            end

        -- Instancing
        elseif key == KEY_8 then
            renderer.dynamicInstancing = not renderer.dynamicInstancing

        -- Take screenshot
        elseif key == KEY_9 then
            local screenshot = Image()
            graphics:TakeScreenShot(screenshot)
            local timeStamp = Time:GetTimeStamp()
            timeStamp = string.gsub(timeStamp, "[:. ]", "_")
            -- Here we save in the Data folder with date and time appended
            screenshot:SavePNG(fileSystem:GetProgramDir() .. "Data/Screenshot_" .. timeStamp .. ".png")
        elseif key == KEY_D then
            drawDebug = drawDebug + 1
            if drawDebug > 2 then
                drawDebug = 0
            end
		elseif key == KEY_T then
            debugHud:Toggle(DEBUGHUD_SHOW_PROFILER)
		elseif input:GetKeyPress(KEY_SPACE) then
			local vm = VariantMap()
			vm["speed"] = 60
			vm["magnitude"] = 0.2
			vm["damping"] = 2
			SendEvent("ShakeCamera",  vm)
		end
		
    end
end



function PlayerController:TakeStep(dt)
	
	local pos = self.node:GetWorldPosition()
	local navmesh = self.node:GetScene():GetComponent("NavigationMesh")
	
	if self.pathtracker == nil then 
		return false
	end
	
	local vec, angle = self.pathtracker:getStepVectorAndAngle(pos, dt, self.speed)
	
	if vec == nil then 
		self.pathtracker = nil 
		print("TakeStep ", 1)
		return false
	end
	
	local step = pos + vec
	
	self.node:SetWorldPosition(step)
	
	
	--local nearest = navmesh:FindNearestPoint(step)
	--local move = navmesh:MoveAlongSurface(pos, nearest)
	--print("nearest ", nearest.x, nearest.y, nearest.z, self.node)
	--self.node:SetWorldPosition(nearest)
	self.node:SetRotation(Quaternion(angle + 90, Vector3(0,-1,0)) )
	
	self.node:SendEvent("TransformChanged")
	
	print("@Now: ", step.x, step.y, step.z, angle)
	
	
	return true
	
end

function PlayerController:SetPath(path)
	self.pathtracker = PathTracker(path, self.node:GetScene():GetComponent("NavigationMesh"))
end

function PlayerController:HandleMouseButtonDown(eventType, eventData)
	print("PlayerController:HandleMouseButtonDown")
	local button = eventData["Button"]:GetInt()
	if button == MOUSEB_LEFT then
		local pick = Pick(self.node:GetScene(), 100)
		if pick and pick:GetVars()["hostile"]==true then
			self.targetid = pick:GetID()
		end
	end
	if self.targetid then
		local target = self.node:GetScene():GetNode(self.targetid)
		if target then
			local path = self.node:GetScene():GetComponent("NavigationMesh"):FindPath(self.node:GetWorldPosition(), target:GetWorldPosition())
			self:SetPath(path)
		else
			self.targetid=nil
			local ground = PathPick(self.node:GetScene())
			if ground then
				local path = self.node:GetScene():GetComponent("NavigationMesh"):FindPath(self.node:GetPosition(), ground)
				self:SetPath(path)
			end
		end
	else
		self.targetid = nil
		local ground = PathPick(self.node:GetScene())
		if ground then
			local path = self.node:GetScene():GetComponent("NavigationMesh"):FindPath(self.node:GetPosition(), ground)
			self:SetPath(path)
		end
	end
		
end

function PlayerController:HandleMouseButtonUp(eventType, eventData)
	print("PlayerController:HandleMouseButtonUp")
	local button = eventData["Button"]:GetInt()
	if button == MOUSEB_LEFT then
		self.targetid=nil
	end
end

function PlayerController:HandleUpdate(eventType, eventData)
	local dt = eventData["TimeStep"]:GetFloat()
	--print("PlayerController:HandleUpdate ", dt)

	local success, angle = self:TakeStep(dt)
	
	if success then
		self.vm["animation"] = "walk"
	else
		self.vm["animation"] = "idle"
	end
	
	self.vm["loop"] = true
	
	self.node:SendEvent("PlayAnimation", self.vm)
	
end