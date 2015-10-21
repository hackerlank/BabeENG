-- Introduction to Urho3D

-- Level Generator

require 'Scripts/objectinstancing'
require 'Scripts/camera'

require 'Scripts/maze'
require 'Scripts/picking'
require 'Scripts/animationmap'
require 'Scripts/randomwandercontroller'
require 'Scripts/playercontroller'
require 'Scripts/WASDController'


-- Component to alter camera characteristics in response to input

CameraSettings = ScriptObject()

function CameraSettings:Start()
	print("CameraSettings:Start()")
	self:SubscribeToEvent("Update", "CameraSettings:HandleUpdate")
end

function CameraSettings:HandleUpdate(eventType, eventData)
	local vm=VariantMap()
	if input:GetKeyPress(KEY_1) then vm["flag"] = "allowspin" self.node:SendEvent("ToggleCameraFlag", vm)
	elseif input:GetKeyPress(KEY_2) then vm["flag"] = "allowpitch" self.node:SendEvent("ToggleCameraFlag", vm)
	elseif input:GetKeyPress(KEY_3) then vm["flag"] = "allowzoom" self.node:SendEvent("ToggleCameraFlag", vm)
	elseif input:GetKeyPress(KEY_4) then vm["flag"] = "clipcamera" self.node:SendEvent("ToggleCameraFlag", vm)
	elseif input:GetKeyPress(KEY_5) then vm["flag"] = "springtrack" self.node:SendEvent("ToggleCameraFlag", vm)
	elseif input:GetKeyPress(KEY_6) then vm["flag"] = "orthographic" self.node:SendEvent("ToggleCameraFlag", vm)
	end
	
	
end


levelobjects=
{
	
	camera=
	{
		Components=
		{
			{
				Type="ScriptObject", 
				Classname="ThirdPersonCamera", 
				Parameters=
				{
					pitch=30, 
					follow=10,
					minfollow=5,
					maxfollow=10,
					orthographic=false, 
					cellsize=128, 
					yaw=45, 
					allowpitch=false, 
					allowspin=false,
					allowzoom=true, 
					clipcamera=false,
					springtrack=false,
				}
			},
		},
	},
	
	cubeblock=
	{
		Vars=
		{
			solid=true,
		},
		Scale={x=1.1, y=1, z=1.1},
		Components=
		{
			{Type="StaticModel", Model="Models/CubeBlock.mdl", Material="Materials/cubeblock.xml", CastShadows=true},
		},
	},
	
	player=
	{
		Scale={x=0.5,y=0.5,z=0.5},
		Components=
		{
			{Type="ScriptObject", Classname="CameraControl"},
			{Type="ScriptObject", Classname="CameraSettings"},
			{Type="ScriptObject", Classname="PlayerController"},
			--{Type="ScriptObject", Classname="WASDController"},
			{Type="AnimatedModel", Model="Models/gob.mdl", Material="Materials/blueghost.xml", CastShadows=false},
			{Type="AnimatedModel", Model="Models/gob.mdl", Material="Materials/gob.xml", CastShadows=true},
			{Type="AnimationController"},
			{Type="ScriptObject", Classname="AnimationMap",
				Parameters=
				{
					animations=
					{
						walk="Models/GC_Walk.ani",
						idle="Models/GC_Idle.ani",
						start="Models/GC_Walk.ani",
					}
				},
			},

		},
		
		Children=
		{
			{
				Position={x=0,y=1.5,z=-0.5},
				Components=
				{
					{Type="Light", LightType=LIGHT_POINT, Color={r=0.85*2,g=0.45*2,b=0.25*2}, Range=8, CastShadows=true},
				},
			},
		}
	},
	
	tree=
	{
		Vars=
		{
			solid=true,
		},
		Children=
		{
			{
				Scale={x=2,y=2,z=2},
				Components=
				{
					{Type="StaticModel", Model="Models/TreeTrunk.mdl", Material="Materials/TreeTrunk.xml", CastShadows=true},
					{Type="StaticModel", Model="Models/TreeCanopy.mdl", Material="Materials/TreeCanopy.xml", CastShadows=true},


				}
			}
		},
	},
	
	thing=
	{
		Scale={x=0.5,y=0.5,z=0.5},
		Components=
		{
			--{Type="ScriptObject", Classname="RandomWanderController"},
			{Type="AnimatedModel", Model="Models/gob.mdl", Material="Materials/gob.xml", CastShadows=true},
			{Type="AnimatedModel", Model="Models/gob.mdl", Material="Materials/redghost.xml", CastShadows=false},
			{Type="AnimationController"},
			{Type="ScriptObject", Classname="AnimationMap",
				Parameters=
				{
					animations=
					{
						walk="Models/GC_Walk.ani",
						idle="Models/GC_Walk.ani",
						start="Models/GC_Walk.ani",
						attack="Models/GC_Melee.ani",
					}
				},
			},

		},
		
		Children=
		{
			{
				Position={x=0,y=1.5,z=0.5},
				Components=
				{
					{Type="Light", LightType=LIGHT_POINT, Color={r=0.85*2,g=0.45*2,b=0.25*2}, Range=5, CastShadows=true},
				},
			},
		}
	},
	
	dungeonlight=
	{
		Children=
		{
			{
				Direction={x=0, y=-1, z=-2},
				Components=
				{
					{Type="Light", LightType=LIGHT_DIRECTIONAL, Color={r=1*0.25, g=1*0.25, b=1*0.25},CastShadows=true,
						ShadowBias={ConstantBias=0.00001, SlopeScaledBias=0.5},
						ShadowCascade={Split1=2, Split2=10, Split3=30, Split4=50, FadeStart=0.8}}
				}
			},
		
		},
		
		Components=
		{
			--{Type="Zone", AmbientColor={b=0.15, g=0.14, r=0.14}, FogColor={b=0.15, g=0.14, r=0.14}, FogStart=50, FogEnd=60, BoundingBox=BoundingBox(-1000,1000)},
		}
	},
	
	
	floor=
	{
		Vars=
		{
			world=true,
		},
		Components=
		{
			{Type="StaticModel", Model="Models/floor.mdl", Material="Materials/floor.xml", CastShadows=false},
		}
	},
	
	wallfloor=
	{
		Vars=
		{
			world=true,
		},
		Components=
		{
			{Type="StaticModel", Model="Models/wallfloor.mdl", Material="Materials/floor.xml", CastShadows=false},
		}
	},
}


function GenerateLevel()
	print("GenerateLevel")
	math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) )
	
	local gamestate =
	{
	}
	
	gamestate.scene = Scene()
	gamestate.scene:CreateComponent("Octree")
	gamestate.scene:CreateComponent("DebugRenderer")
	-- Create scene node & StaticModel component for showing a static plane
    local planeNode = gamestate.scene:CreateChild("Plane")
    planeNode.scale = Vector3(100.0, 1.0, 100.0)
	planeNode:GetVars()['world'] = true
    local planeObject = planeNode:CreateComponent("StaticModel")
    planeObject.model = cache:GetResource("Model", "Models/Plane.mdl")
    planeObject.material = cache:GetResource("Material", "Materials/StoneTiled.xml")
	
	-- Create a Zone component for ambient lighting & fog control
    local zoneNode = gamestate.scene:CreateChild("Zone")
    local zone = zoneNode:CreateComponent("Zone")
    zone.boundingBox = BoundingBox(-1000.0, 1000.0)
    zone.ambientColor = Color(0.15, 0.15, 0.15)
    zone.fogColor = Color(0.5, 0.5, 0.7)
    zone.fogStart = 10.0
	zone.fogEnd = 35.0

	-- Create randomly sized boxes. If boxes are big enough, make them occluders. Occluders will be software rasterized before
    -- rendering to a low-resolution depth-only buffer to test the objects in the view frustum for visibility
    local boxGroup = gamestate.scene:CreateChild("Boxes")
    for i = 1, 20 do
        local boxNode = boxGroup:CreateChild("Box")
        local size = 1.0 + Random(10.0)
        boxNode.position = Vector3(Random(80.0) - 40.0, size * 0.5, Random(80.0) - 40.0)
        boxNode:SetScale(size)
        local boxObject = boxNode:CreateComponent("StaticModel")
        boxObject.model = cache:GetResource("Model", "Models/Box.mdl")
        boxObject.material = cache:GetResource("Material", "Materials/Stone.xml")
        boxObject.castShadows = true
        if size >= 3.0 then
            boxObject.occluder = true
        end
    end
	
	local navmesh = gamestate.scene:CreateComponent("NavigationMesh")
	gamestate.scene:CreateComponent("Navigable")
	navmesh:SetAgentHeight(0.2)
	navmesh:SetAgentRadius(0.25)
	navmesh:SetAgentMaxClimb(0.15)
	navmesh:SetCellSize(0.05)
	navmesh:SetCellHeight(0.025)
	navmesh:SetPadding(Vector3(0,2,0))
	navmesh:SetTileSize(129)
	
	-- Create a DynamicNavigationMesh component to the scene root
    -- local navMesh = gamestate.scene:CreateComponent("DynamicNavigationMesh")
	-- gamestate.scene:CreateComponent("Navigable")

    -- Enable drawing debug geometry for obstacles and off-mesh connections
    -- navMesh.drawObstacles = true
    -- navMesh.drawOffMeshConnections = true
    -- Set the agent height large enough to exclude the layers under boxes
    -- navMesh.agentHeight = 10
    -- Set nav mesh cell height to minimum (allows agents to be grounded)
    -- navMesh.cellHeight = 0.05
  
    -- Add padding to the navigation mesh in Y-direction so that we can add objects on top of the tallest boxes
    -- in the scene and still update the mesh correctly
    -- navMesh.padding = Vector3(0.0, 10.0, 0.0)
    -- Now build the navigation geometry. This will take some time. Note that the navigation mesh will prefer to use
    -- physics geometry from the scene nodes, as it often is simpler, but if it can not find any (like in this example)
    -- it will use renderable geometry instead
    
	
	
	navmesh:Build()
	
	
	
	gamestate.Stop = function()
		gamestate.scene:Remove()
		gamestate.scene = nil
	end
	
	
	InstanceObject(levelobjects.camera, gamestate.scene)

	local p = InstanceObject(levelobjects.player, gamestate.scene)
	p:SetWorldPosition(Vector3(0,0,0))
	p:SendEvent("TransformChanged")
	local vm = VariantMap()
	vm["animation"] = "idle"
	vm["loop"] = true
	
	p:SendEvent("PlayAnimation", vm)
	
	playerobject = p
	
	InstanceObject(levelobjects.dungeonlight, gamestate.scene)
	
	-- local c
	-- for c=1,30,1 do
		-- local n=InstanceObject(levelobjects.thing, gamestate.scene)
		-- n:SetWorldPosition(navmesh:GetRandomPoint())
	-- end
	return gamestate
end
