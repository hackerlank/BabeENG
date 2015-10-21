AnimationMap = ScriptObject()

function AnimationMap:Start()
	print("AnimationMap:Start()")
	self:SubscribeToEvent(self.node, "PlayAnimation", "AnimationMap:HandlePlayAnimation")
	self.animations = {}
	self.currentanimation=""
end

function AnimationMap:Finalize()
	print("AnimationMap:Finalize()")
	if self.animations["start"] then
		local controller=self.node:GetComponent("AnimationController")
		if controller==nil then return end
		local animname=self.animations["start"]
		if animname then
			controller:StopLayer(0,0)
			controller:Play(animname,0, true,0)
		end
	end
end

function AnimationMap:HandlePlayAnimation(eventType, eventData)
	local controller = self.node:GetComponent("AnimationController")
	if controller == nil then return end
	
	local a = eventData["animation"]:GetString()
	--print("AnimationMap:HandlePlayAnimation ", a, self.currentanimation, debug.traceback())
	
	if a == self.currentanimation then
		local speed = eventData["speed"] and eventData["speed"]:GetFloat() or 0
		if speed ==0 then speed = 1 end
		controller:SetSpeed(self.animations[self.currentanimation], speed)
		return 
	end
	
	local oldAnim =  self.animations[self.currentanimation]
	local animname = self.animations[a]
		
	self.currentanimation = a
	
	local loop = eventData["loop"]:GetBool()
	
	print(oldAnim, animname)
	
	controller:Stop(oldAnim, 0.2)
	controller:Play(animname, 0, loop, 0.2)
	
	local speed = eventData["speed"] and eventData["speed"]:GetFloat() or 0
	if speed ==0 then speed = 1 end
	controller:SetSpeed(self.animations[animname],speed)
	
end