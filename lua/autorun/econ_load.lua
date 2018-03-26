economy = economy or {}

if (SERVER) then
	AddCSLuaFile("econ_main_sh.lua")
	AddCSLuaFile("econ_main_cl.lua")
	AddCSLuaFile("econ_config.lua")

	timer.Simple(5, function()	
		include("econ_main_sh.lua")
		include("econ_config.lua")
		include("econ_main_sv.lua")
	end)
else
	
	timer.Simple(5, function()
		include("econ_main_sh.lua")
		include("econ_config.lua")
		include("econ_main_cl.lua")
	end)
end