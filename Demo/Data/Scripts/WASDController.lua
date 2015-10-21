-- Player WASDController

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

WASDController=ScriptObject()

function WASDController:Start()
	self.speed=2
	self.vm=VariantMap()
	
	self.state="idle"
	self.node:GetVars()["player"] = true
	
	self:SubscribeToEvent("Update", "WASDController:HandleUpdate")
	
	self.rotationvel=720
	self.curangle=0
	self.nextangle=0
	self.lastuse=0
	self.lastusedelta=0
end

function WASDController:HandleUpdate(eventType, eventData)
	local dt = eventData["TimeStep"]:GetFloat()
	--print("WASDController:HandleUpdate ", dt)
	local dir = Vector3(0,0,0)
	local keyisdown=false
	
	if input:GetKeyDown(KEY_W) or (input:GetMouseButtonDown(MOUSEB_RIGHT) and input:GetMouseButtonDown(MOUSEB_LEFT)) then
		dir=dir+Vector3(0,0,1)
		keyisdown=true
	end
	
	if input:GetKeyDown(KEY_A) then
		dir=dir+Vector3(-1,0,0)
		keyisdown=true
	end
	
	if input:GetKeyDown(KEY_S) then
		dir=dir+Vector3(0,0,-1)
		keyisdown=true
	end
	
	if input:GetKeyDown(KEY_D) then
		dir=dir+Vector3(1,0,0)
		keyisdown=true
	end
	
	if dir:Length()>0 then
		dir:Normalize()
	
		self.node:SendEvent("RequestCameraRotation", self.vm)
		local spinquat=Quaternion(self.vm["spin"]:GetFloat(), Vector3(0,1,0))
		--self.node:SetRotation(spinquat)
		local movevec = spinquat*dir
		movevec = movevec*Vector3(self.speed*dt,self.speed*dt,self.speed*dt)
		
		--self.vm:SetFloat("angle", (-self.vm:GetFloat("spin")+180))
		--self.node:SendEvent("SetRotationAngle", self.vm)
		self.nextangle=(-self.vm["spin"]:GetFloat()+180)
		
		-- Smoothing
		
		local delta1=self.nextangle-self.curangle
		local delta2=(self.nextangle+360)-self.curangle
		local delta3=(self.nextangle-360)-self.curangle
	
		local m1,m2,m3=math.abs(delta1),math.abs(delta2),math.abs(delta3)
		local use=math.min(m1,m2,m3)
		local usedelta
	
		if use<0.001 then
			self.curangle=self.nextangle
			self.node:SetRotation(Quaternion(self.curangle,Vector3(0,-1,0)))
		else
	
			if use==math.abs(delta1) then
				usedelta=delta1
			elseif use==math.abs(delta2) then
				usedelta=delta2
			else
				usedelta=delta3
			end
			self.lastuse=use
			self.lastusedelta=usedelta
	
			local sign=1
			if usedelta<0 then sign=-1 end
	
			local step=dt*self.rotationvel
			step=math.min(step,use)
			self.curangle=self.curangle+step*sign
		
			while self.curangle>=360 do self.curangle=self.curangle-360 end
			while self.curangle<0 do self.curangle=self.curangle+360 end 

			self.node:SetRotation(Quaternion(self.curangle,Vector3(0,-1,0)))
		end
	
		local navmesh=self.node:GetScene():GetComponent("NavigationMesh")
		local nearest=navmesh:FindNearestPoint(self.node:GetWorldPosition()+movevec)
		self.node:SetWorldPosition(nearest)
		CameraControl:TransformChanged()
		self.vm["animation"] = "walk"
		
	else
		self.vm["animation"] = "idle"
	end
	
	
	
	self.vm["loop"] = true
	self.node:SendEvent("PlayAnimation", self.vm)
end
