-- Introduction to Urho3D

-- Picking utilities
pickvm=VariantMap()

function TopLevelNodeFromDrawable(drawable, scene)
	local n = drawable:GetNode()
	if not n then print("No node\n") return nil end
	while n.parent~=scene do if n.parent==nil then return nil end n=n.parent end
	--print("ID: "..n:GetID().."\n")
	return n
end

function PathPick(scene, maxDistance)
	print("-->PathPick")
	if not maxDistance then maxDistance=100 end
	
	local hitDrawable = nil
	if (ui.cursor and not ui.cursor.visible and input.mouseVisible==false) then
		return nil
	end
	
	SendEvent("RequestMouseRay", pickvm)
	
	local origin=pickvm["origin"]:GetVector3()
	local direction=pickvm["direction"]:GetVector3()
	local ray=Ray(origin,direction)

    local octree = scene:GetComponent("Octree")
    
	local resultvec = octree:Raycast(ray, RAY_TRIANGLE, maxDistance, DRAWABLE_GEOMETRY)
	print("#resultvec: ", #resultvec)
	if #resultvec==0 then return nil end
	
	local i
	for i=1, #resultvec,1 do
		--local node = TopLevelNodeFromDrawable(resultvec[i].drawable, scene)
		--if not node:GetVars():GetBool("hostile") and not node:GetVars():GetBool("player") then
		--print("node type : " .. resultvec[i].drawable:GetVars()["world"])
		print("resultvec[i].distance " .. resultvec[i].distance)
		--if node:GetVars()["world"] == true and resultvec[i].distance >= 0 then
			print("type == world")
			hitPos = ray.origin + ray.direction * resultvec[i].distance
			return hitPos
		--end
	end
	
	return nil
end

function CameraPick(scene, ray, followdist)
	local octree = scene:GetComponent("Octree")
    
	local resultvec=octree:Raycast(ray, RAY_TRIANGLE, followdist, DRAWABLE_GEOMETRY)
	if #resultvec==0 then return followdist end
	
	local i
	for i=1,#resultvec,1 do
		local node=TopLevelNodeFromDrawable(resultvec[i].drawable, scene)
		--if not node:GetVars():GetBool("hostile") and not node:GetVars():GetBool("player") then
		if node:GetVars()["solid"]==true and resultvec[i].distance>=0 then
			return math.min(resultvec[i].distance-0.05,followdist)
		end
	end
	
	return followdist
end

function Pick(scene, maxDistance)
	if not maxDistance then maxDistance=100.0 end
	
	
	local hitPos = nil
    local hitDrawable = nil
	if (ui.cursor and not ui.cursor.visible and input.mouseVisible==false) then
		return nil
	end
	
	SendEvent("RequestMouseRay", pickvm)
	local origin=pickvm["origin"]:GetVector3()
	local direction=pickvm["direction"]:GetVector3()
	local ray=Ray(origin,direction)

   
    local octree = scene:GetComponent("Octree")
   
	local resultvec=octree:Raycast(ray, RAY_TRIANGLE, maxDistance, DRAWABLE_GEOMETRY)
	if #resultvec==0 then return nil end
	
	local i
	for i=1,#resultvec,1 do
		local node=TopLevelNodeFromDrawable(resultvec[i].drawable, scene)
		if node:GetVars()["hostile"] == true then return node end
	end
	
	return nil
end