-- Third Person Camera
--
require 'Scripts/tokenize'

ThirdPersonCamera=ScriptObject()

function ThirdPersonCamera:Start()
	-- Override any of these parameters when instancing the component in order to change the characteristics
	-- of the view.
	print("ThirdPersonCamera:Start()")
	self.cellsize = 128         -- Orthographic on-screen size of 1 unit 
	self.pitch = 30             -- 30 degrees for standard 2:1 tile ratio
	self.yaw = 45               -- 45 degrees for standard axonometric projections
	self.follow = 10              -- Target zoom distance
	self.minfollow = 1            -- Closest zoom distance for perspective modes
	self.maxfollow = 20           -- Furthest zoom distance for perspective modes
	self.clipdist = 60            -- Far clip distance
	self.clipcamera = true        -- Cause camera to clip when view is obstructed by world geometry
	self.springtrack = true       -- Use a spring function for location tracking to smooth camera translation
								  -- Set to false to lock camera tightly to target.
	self.allowspin = true         -- Camera yaw angle can be adjusted via MOUSEB_MIDDLE + Mouse move in X
	self.allowpitch = true        -- Camera pitch can be adjusted via MOUSEB_MIDDLE + Mouse move in y
	self.allowzoom = true         -- Camera can be zoomed via Mouse wheel
	self.orthographic = false     -- Orthographic projection
	
	self.curfollow = self.follow  -- Current zoom distance (internal use only)
	self.followvel = 0              -- Zoom movement velocity (internal use only)
	self.pos = Vector3(0,0,0)         -- Vars used for location spring tracking (internal use only)
	self.newpos = Vector3(0,0,0)
	self.posvelocity = Vector3(0,0,0)
	
	self.shakemagnitude = 0
	self.shakespeed = 0
	self.shaketime = 0
	self.shakedamping = 0
end

function ThirdPersonCamera:Finalize()
	print("ThirdPersonCamera:Finalize()")
	self.curfollow = self.follow
	
	-- Set up node hierarchy
	-- root level node is used for position and yaw control
	-- shakenode is used for applying camera shake translations
	-- anglenode is used for pitch control
	-- cameranode holds the camera and is used for zoom distance control as well
	
	self.shakenode = self.node:CreateChild("ShakeNode", LOCAL)
	self.anglenode = self.shakenode:CreateChild("AngleNode", LOCAL)
	self.cameranode = self.anglenode:CreateChild("CameraNode", LOCAL)
	self.camera = self.cameranode:CreateComponent("Camera")
	
	-- If orthographic, use the cellsize to calculate the orthographic size
	
	if self.orthographic then
		self.camera:SetOrthographic(true)
		local w,h=graphics:GetWidth(), graphics:GetHeight()
		self.camera:SetOrthoSize(Vector2(w/(self.cellsize*math.sqrt(2)), h/(self.cellsize*math.sqrt(2))))
	end
	
	self.viewport=Viewport:new(self.node:GetScene(), self.camera)
    renderer:SetViewport(0, self.viewport)
	
	-- Apply initial pitch/yaw/zoom
	
	self.node:SetRotation(Quaternion(self.yaw, Vector3(0,1,0)))
	self.cameranode:SetPosition(Vector3(0,0,-self.follow))
	self.anglenode:SetRotation(Quaternion(self.pitch, Vector3(1,0,0)))
	self.node:SetPosition(Vector3(0,0,0))
	
	self:SubscribeToEvent("Update", "ThirdPersonCamera:HandleUpdate")
	self:SubscribeToEvent("ShakeCamera", "ThirdPersonCamera:HandleShakeCamera")
	self:SubscribeToEvent("RequestMouseGround", "ThirdPersonCamera:HandleRequestMouseGround")
	self:SubscribeToEvent("RequestMouseRay", "ThirdPersonCamera:HandleRequestMouseRay")
	self:SubscribeToEvent("SetCameraPosition", "ThirdPersonCamera:HandleSetCameraPosition")
	self:SubscribeToEvent("ResetCameraPosition", "ThirdPersonCamera:HandleResetCameraPosition")  -- Used to hard-lock a soft tracking camera to a location, skipping the smooth scroll
	self:SubscribeToEvent("RequestCameraRotation", "ThirdPersonCamera:HandleRequestCameraRotation")
	self:SubscribeToEvent("SetCameraParameter", "ThirdPersonCamera:HandleSetCameraParameter")
	self:SubscribeToEvent("ToggleCameraFlag", "ThirdPersonCamera:HandleToggleFlag")
	
	self.camera:SetFarClip(self.clipdist)
end

function ThirdPersonCamera:GetMouseRay()
	-- Construct a ray based on current mouse coordinates.
	local mousepos
	if input.mouseVisible then
		mousepos=input:GetMousePosition()
	else
		mousepos=ui:GetCursorPosition()
	end
	
	return self.camera:GetScreenRay(mousepos.x/graphics.width, mousepos.y/graphics.height)
end

function ThirdPersonCamera:GetMouseGround()
	-- Calculate the intersection of the current mouse coordinates with the ground plane
	print("ThirdPersonCamera:GetMouseGround()")
	local ray=self:GetMouseRay()
	
	local pos=self.node:GetWorldPosition()
	local x = pos.x local y = pos.y local z = pos.z
	local hitdist=ray:HitDistance(Plane(Vector3(0,1,0), Vector3(0,0,0)))
	local dx=(ray.origin.x+ray.direction.x*hitdist)
	local dz=(ray.origin.z+ray.direction.z*hitdist)
	return dx,dz
end

function ThirdPersonCamera:HandleSetCameraPosition(eventType, eventData)
	-- Camera position setting. Responds to event generated by CameraControl components.
	
	self.newpos.x = eventData["x"]:GetDouble()
	self.newpos.y = eventData["y"]:GetDouble()
	self.newpos.z = eventData["z"]:GetDouble()
end

function ThirdPersonCamera:HandleResetCameraPosition(eventType, eventData)
	-- Camera position setting. Responds to event generated by CameraControl components.
	self.pos.x = eventData["x"]:GetDouble()
	self.pos.y = eventData["y"]:GetDouble()
	self.pos.z = eventData["z"]:GetDouble()
	
	self.newpos.x = self.pos.x
	self.newpos.y = self.pos.y
	self.newpos.z = self.pos.z
	print("ThirdPersonCamera:HandleResetCameraPosition ", eventType, self.newpos.x, self.newpos.y, self.newpos.z)
end

function ThirdPersonCamera:HandleRequestCameraRotation(eventType, eventData)
	-- Request to provide the camera pitch and yaw, for controllers that use it such as the WASD controllers
	
	eventData["spin"] = self.yaw
	eventData["pitch"] = self.pitch
end

function ThirdPersonCamera:SpringFollow(dt)
	-- Spring function to smooth camera zoom action
	
	local df=self.follow-self.curfollow
	local af=9*df-6*self.followvel
	self.followvel=self.followvel+dt*af
	self.curfollow=self.curfollow+dt*self.followvel
end

function ThirdPersonCamera:CameraPick(ray, followdist)
	-- Cast a ray from camera target toward camera and determine the nearest clip position.
	-- Only objects marked by setting node user var solid=true are considered.
	
	local scene = self.node:GetScene()
	local octree = scene:GetComponent("Octree")
    
	local resultvec=octree:Raycast(ray, RAY_TRIANGLE, followdist, DRAWABLE_GEOMETRY)
	if #resultvec==0 then return followdist end
	
	local i
	for i=1,#resultvec,1 do
		--local node = TopLevelNodeFromDrawable(resultvec[i].drawable, scene)
		
		--if node:GetVars()["solid"]==true and resultvec[i].distance>=0 then
			return math.min(resultvec[i].distance-0.05, followdist)
		--end
	end
	
	return followdist
end

function ThirdPersonCamera:SpringPosition(dt)
	local d=self.newpos-self.pos
	local a=d*Vector3(8,8,8) - self.posvelocity*Vector3(6,6,6)
	self.posvelocity=self.posvelocity+a*Vector3(dt,dt,dt)
	self.pos=self.pos+self.posvelocity*Vector3(dt,dt,dt)
end

function ThirdPersonCamera:HandleUpdate(eventType, eventData)
	
	local dt = eventData["TimeStep"]:GetFloat()
	--print("ThirdPersonCamera:HandleUpdate ", dt)
	-- Calculate camera shake factors
	self.shaketime = self.shaketime + dt * self.shakespeed
	local s = math.sin(self.shaketime) * self.shakemagnitude
	
	local shakepos = Vector3(math.sin(self.shaketime*3)*s, math.cos(self.shaketime)*s,0)
	self.shakemagnitude = self.shakemagnitude - self.shakedamping*dt
	if self.shakemagnitude < 0 then self.shakemagnitude = 0 end
	
	
	if self.allowzoom and not ui:GetElementAt(ui.cursor:GetPosition()) then
		-- Modify follow (zoom) in response to wheel motion
		-- This modifies the target zoom, or the desired zoom level, not the actual zoom.
		
		local wheel = input:GetMouseMoveWheel()
		self.follow = self.follow - wheel * dt * 20
		if self.follow < self.minfollow then self.follow = self.minfollow end
		if self.follow > self.maxfollow then self.follow = self.maxfollow end
	end
	
	if input:GetMouseButtonDown(MOUSEB_MIDDLE) and (self.allowspin or self.allowpitch) then
		-- Hide the cursor when altering the camera angles
		ui.cursor.visible = false
		
		if self.allowpitch then
			-- Adjust camera pitch angle
			
			local mmovey = input:GetMouseMoveY()/graphics:GetHeight()
			self.pitch = self.pitch + mmovey*600

			if self.pitch < 1 then self.pitch = 1 end
			if self.pitch > 89 then self.pitch = 89 end
		end
		
		if self.allowspin then
			-- Adjust camera yaw angle
			
			local mmovex = input:GetMouseMoveX()/graphics:GetWidth()
			self.yaw = self.yaw + mmovex*800
			while self.yaw < 0 do self.yaw = self.yaw + 360 end
			while self.yaw >=360 do self.yaw = self.yaw -360 end
		end
		
	else
		ui.cursor.visible = true
	end
	
	-- Apply the spring function to the zoom (follow) level.
	-- This provides smooth camera movement toward the desired zoom level.
	
	self:SpringFollow(dt)		
	
	if self.clipcamera then
		-- After calculating the camera zoom position, test a ray from view center for obstruction and
		-- clip camera position to nearest obstruction distance.
		local ray=self.camera:GetScreenRay(0.5,0.5)
		local revray = Ray(self.node:GetPosition(), ray.direction*Vector3(-1,-1,-1))
		
		self.curfollow = self:CameraPick(revray, self.curfollow)
	end
	
	-- Set camera shake factor (do it here rather than before the camera clipping, so that
	-- shake translations do not affect the casting of the view ray, which could cause
	-- the camera zoom to go haywire
	self.shakenode:SetPosition(shakepos)
	
	if self.springtrack then
		self:SpringPosition(dt)
		self.node:SetPosition(self.pos)
	else
		self.node:SetPosition(self.newpos)
		self.pos=self.newpos
	end
	
	-- Set camera pitch, zoom and yaw.
	self.node:SetRotation(Quaternion(self.yaw, Vector3(0,1,0)))
	self.cameranode:SetPosition(Vector3(0, 0, -self.curfollow))
	self.anglenode:SetRotation(Quaternion(self.pitch, Vector3(1,0,0)))
end

function ThirdPersonCamera:HandleShakeCamera(eventType, eventData)
	-- Apply some shake factors
	-- Shake is applied via three values
	
	-- magnitude determines the strength of the shake, or maximum deflection, from great big swooping shakes
	-- to small vibrations.
	
	-- speed determines the velocity of the shake vibration
	
	-- damping determines how quickly the shaking fades out.
	
	self.shakemagnitude = eventData["magnitude"]:GetDouble();
    self.shakespeed = eventData["speed"]:GetDouble();
    self.shakedamping = eventData["damping"]:GetDouble();
	
	print("@@@@@@", self.shakemagnitude, self.shakespeed, self.shakedamping)
end

function ThirdPersonCamera:HandleRequestMouseGround(eventType, eventData)
	local dx,dz=self:GetMouseGround()
	
	eventData["ground"] = Vector3(dx,0,dz)
end

function ThirdPersonCamera:HandleRequestMouseRay(eventType, eventData)
	local ray=self:GetMouseRay()
	--print("origin: ", ray.origin)
	--print("direction: ", ray.direction)
	eventData["origin"] = ray.origin
	eventData["direction"] = ray.direction
end

function ThirdPersonCamera:SetOrthographic()
	self.orthographic=true
	self.camera:SetOrthographic(true)
	local w,h=graphics:GetWidth(), graphics:GetHeight()
	self.camera:SetOrthoSize(Vector2(w/(self.cellsize), h/(self.cellsize)))
end

function ThirdPersonCamera:HandleSetCameraParameter(eventType, eventData)
	local paramstring = eventData["parameters"]:GetString()
	local params = string.split(params,';')
	local p
	for _,p in ipairs(params) do
		if p=="pitch" then self.pitch=eventData["pitch"]:GetFloat() end
		if p=="yaw" then self.yaw=eventData["yaw"]:GetFloat() end
		if p=="follow" then self.follow=eventData["follow"]:GetFloat() end
		if p=="cellsize" then self.cellsize=eventData["cellsize"]:GetFloat() end
		if p=="minfollow" then self.minfollow=eventData["minfollow"]:GetFloat() end
		if p=="maxfollow" then self.maxfollow=eventData["maxfollow"]:GetFloat() end
		if p=="allowspin" then self.allowspin=eventData["allowspin"]:GetBool() end
		if p=="allowpitch" then self.allowpitch=eventData["allowpitch"]:GetBool() end
		if p=="allowzoom" then self.allowzoom=eventData["allowzoom"]:GetBool() end
		if p=="clipcamera" then self.clipcamera=eventData["clipcamera"]:GetBool() end
		if p=="springtrack" then self.springtrack=eventData["springtrack"]:GetBool() end
		if p=="orthographic" then
			self.orthographic=eventData["orthographic"]:GetBool()
			if self.orthographic then self:SetOrthographic()
			else self.camera:SetOrthographic(false)
			end
		end
	end
end

function ThirdPersonCamera:HandleToggleFlag(eventType, eventData)
	local flag=eventData["flag"]:GetString()
	
	if flag=="allowspin" then self.allowspin=not self.allowspin end
	if flag=="allowpitch" then self.allowpitch=not self.allowpitch end
	if flag=="allowzoom" then self.allowzoom=not self.allowzoom end
	if flag=="clipcamera" then self.clipcamera=not self.clipcamera end
	if flag=="springtrack" then self.springtrack=not self.springtrack end
	if flag=="orthographic" then
		self.orthographic=not self.orthographic
		if self.orthographic then self:SetOrthographic()
		else self.camera:SetOrthographic(false)
		end
	end
end

-- CameraControl
-- Component for controlling the position of the camera.
-- Place this component on the main actor/avatar object in your scene to allow mirroring
-- that object's world translation to the camera root node.

CameraControl = ScriptObject()

function CameraControl:Start()
	print("CameraControl:Start")
	self:SubscribeToEvent(self.node, "TransformChanged", "CameraControl:TransformChanged")
	self.enabled = true
	self.offset = 0.5
	self.vm = VariantMap()
end

function CameraControl:DelayedStart()
	print("CameraControl:DelayedStart() ###################")
	if self.enabled then
		local pos = self.node:GetWorldPosition()
		local x = pos.x
		local y = pos.y
		local z = pos.z
		self.vm["x"] = x
		self.vm["y"] = y+self.offset
		self.vm["z"] = z
		self.node:SendEvent("ResetCameraPosition", self.vm)
	end
end

function CameraControl:TransformChanged()
	local pos = self.node:GetWorldPosition()
	local x = pos.x
	local y = pos.y
	local z = pos.z
	--print("CameraControl:TransformChanged()", x, y, z, self.node)

	self.vm["x"] = x
	self.vm["y"] = y + self.offset
	self.vm["z"] = z
	self.node:SendEvent("SetCameraPosition", self.vm)
end