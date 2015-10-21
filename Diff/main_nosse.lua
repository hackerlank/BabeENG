--
--Entry Point
--
function Start()
	local log = GetLog()
	local fs = GetFileSystem()
	local time = GetTime()
	OpenConsoleWindow()
	
	log:Open("diff_nosse.log")
	
	Log:Write(LOG_INFO, "### Start ModelEditor###")
	Log:Write(LOG_INFO, "Platform: " .. GetPlatform())
	Log:Write(LOG_INFO, "ProgramDir: " .. fs:GetProgramDir())
	Log:Write(LOG_INFO, "CurrentDir: " .. fs:GetCurrentDir())
	Log:Write(LOG_INFO, "PhysicalCPUs: " .. GetNumPhysicalCPUs())
	Log:Write(LOG_INFO, "NumLogicalCPUs: " .. GetNumLogicalCPUs())
	
	OpenConsoleWindow()
	--GetConsoleInput()
	--Vector2
	local pointA = Vector2(1, 1)
	local pointB = Vector2(2, 2)
	local result = pointA:DotProduct(pointB)
	PrintLine(result)
	PrintLine(pointB:Length())
	
	--Vector3
	local pointA = Vector3(1, 0, 0)
	local pointB = Vector3(0, 1, 0)
	local pointC = Vector3(0, 0, 1)
	local result = pointA:CrossProduct(pointB)
	assert(result == pointC)
	Log:Write(LOG_INFO, result:ToString())
	Log:Write(LOG_INFO, Vector3.RIGHT:ToString())
	Log:Write(LOG_INFO, Vector3.FORWARD:ToString())
	--Quaternion
	Log:Write(LOG_INFO, "--Quaternion")
	local quatA = Quaternion(45, Vector3.UP)
	local quatB = Quaternion(Vector3.FORWARD, Vector3.RIGHT)
	local quatC = Quaternion()
	
	Log:Write(LOG_INFO, quatA:ToString())
	Log:Write(LOG_INFO, quatB:ToString())
	Log:Write(LOG_INFO, quatC:ToString())
	
	local inputP = Vector3(0, 0, 1)
	local result = quatA * inputP
	Log:Write(LOG_INFO, result:ToString())
	Log:Write(LOG_INFO, Time:GetTimeStamp())
	local begin = Time:GetSystemTime()
	for i = 1, 100000 do
		local quatA = Quaternion(45, Vector3.UP)
		local inputP = Vector3(0, 0, 1)
		local result = quatA * inputP
	end
	local delta = Time:GetSystemTime() - begin
	Log:Write(LOG_INFO, delta)
	
	--Matrix3*4
	local mat34 = Matrix3x4()
	
	
end