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
	
end