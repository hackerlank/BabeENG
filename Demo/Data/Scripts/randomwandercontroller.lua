-- Introduction to Urho3D

-- Random Wander Controller
require 'Scripts/picking'
require 'Scripts/playercontroller'

RandomWanderController=ScriptObject()

function RandomWanderController:Start()
	self:SubscribeToEvent("Update", "RandomWanderController:HandleUpdate")
	self:SubscribeToEvent(self.node, "Pick", "RandomWanderController:HandlePick")
	
	self.pathtracker=nil
	self.speed=2
	self.vm=VariantMap()
	
	local vars=self.node:GetVars()
	vars["hostile"] = true
	
	self.rotationvel=720
	self.curangle=0
	self.nextangle=0
	self.lastuse=0
	self.lastusedelta=0
end

function RandomWanderController:TakeStep(dt)
	local pos=self.node:GetWorldPosition()
	local navmesh=self.node:GetScene():GetComponent("NavigationMesh")
	
	if self.pathtracker==nil then return false end
	
	local vec,angle=self.pathtracker:getStepVectorAndAngle(pos, dt, self.speed)
	
	if vec==nil or angle==nil then self.pathtracker=nil return false end
	--print("Angle: "..angle.."\n")
	local step=pos+vec
	local nearest=navmesh:FindNearestPoint(step)
	local move=navmesh:MoveAlongSurface(pos,nearest)
	self.node:SetWorldPosition(move)
	self.node:SetRotation(Quaternion(angle+90, Vector3(0,-1,0)))
	self.vm["angle"] = angle+90
	
	angle=angle+90
	-- Smoothing
	while angle<0 do angle=angle+360 end
	while angle>=360 do angle=angle-360 end
	

	return true, angle
	
end

function RandomWanderController:SetPath(path)
	self.pathtracker = PathTracker(path, self.node:GetScene():GetComponent("NavigationMesh"))
end

function RandomWanderController:HandleUpdate(eventType, eventData)
	
	local dt=eventData["TimeStep"]:GetFloat()
	
	if self.pathtracker==nil then
		local pos = self.node:GetWorldPosition()
		local x = pos.x local y = pos.y local z = pos.z
		local ex,ey,ez=x+(math.random()*20)-10, 0, z+(math.random()*20)-10
		local path=self.node:GetScene():GetComponent("NavigationMesh"):FindPath(self.node:GetWorldPosition(), Vector3(ex,ey,ez))
		self:SetPath(path)
	end
	
	local success, angle=self:TakeStep(dt)
	if success then
		self.vm["animation"] = "walk"
		
		-- Smoothing
		self.nextangle=angle
		
		local delta1=self.nextangle-self.curangle
		local delta2=(self.nextangle+360)-self.curangle
		local delta3=(self.nextangle-360)-self.curangle
	
		local m1,m2,m3=math.abs(delta1),math.abs(delta2),math.abs(delta3)
		local use=math.min(m1,m2,m3)
		local usedelta
	
		if use<0.001 then
			self.curangle=self.nextangle
			self.node:SetRotation(Quaternion(self.curangle,Vector3(0,-1,0)))
			return
		end
	
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
	else
		self.vm["animation"] = "idle"
	end
	self.vm["loop"] = true
	self.node:SendEvent("PlayAnimation", self.vm)
	
end

function RandomWanderController:HandlePick(eventType, eventData)
	print("Picked\n")
end