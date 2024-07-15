 local self=require('openmw.self')
local core=require('openmw.core')
local types = require('openmw.types')
local util = require('openmw.util')

local Cared=false

local function Cared(data)
	core.sendGlobalEvent("CarePlant",{Plant=self, Player=data})
end

local function onUpdate()
--[[
	if string.find(self.type.record(self).name,"Young ") then
		if self.scale<1 then
--			core.sendGlobalEvent('SetScale',{ Object = self, scale=self.scale+0.05})
		elseif self.scale>1 and self.scale<1.1 then
			core.sendGlobalEvent('CreateFlora',{ Object = self, CellName=self.cell.name, Position=self.position})
			core.sendGlobalEvent('RemoveItem',{ Object = self, number=1})
		end
	end
]]--
end

return {
	eventHandlers = {},
	engineHandlers = {
		onUpdate=onUpdate,
		onActivated=Cared
	}

}