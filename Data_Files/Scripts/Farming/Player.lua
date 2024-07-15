local self=require('openmw.self')
local ui=require('openmw.ui')
local core=require('openmw.core')
local types = require('openmw.types')
local util = require('openmw.util')
local async = require('openmw.async')
local interfaces = require('openmw.interfaces')
local input = require('openmw.input')
local nearby = require('openmw.nearby')
local time=require("openmw_aux.time")

local ActionButton=false
local TimeChecking=core.getGameTime()

local function TakeCare(data)
	if data.Cared==false then
		ui.showMessage("You take care of the plant")
	else
		ui.showMessage("You already have taken care of this plant today")
	end
end

local function onFrame()
	if core.getGameTime()>(TimeChecking+86400) then
		core.sendGlobalEvent("GrowPlants",{player=self})
		TimeChecking=TimeChecking+86400
	elseif core.getGameTime()<TimeChecking then
		TimeChecking=core.getGameTime()
	end


--[[	if core.getGameTime()>(TimeChecking+86400) then
		for i=1,math.floor((core.getGameTime()-TimeChecking)/86400) do
			core.sendGlobalEvent("GrowPlants")
		end
		TimeChecking=math.floor(core.getGameTime()/86400)*86400
	end
]]--	
end

local function CheckPlantInCell()
	for i, container in pairs(nearby.containers) do
		if container.type.record(container).weight==0 and string.find(container.type.record(container).id,"flora") then
			return(true)
		end
	end
end

local function onUpdate()
	if input.isActionPressed(input.ACTION.Use)==false 
	and ActionButton==true 
	and types.Actor.getStance(self) == 1 
	and types.Actor.getEquipment(self, 16).recordId=="miner's pick" 
	and self.rotation:getPitch()>=1 
	and self.position.z>0 
	and CheckPlantInCell()==true
	then
		ActionButton=false
		if nearby.castRay(self.position,self.position+util.vector3(0,0,-50)).hit and nearby.castRay(self.position,self.position+util.vector3(0,0,-50)).hitObject==nil then
			for i, container in pairs(nearby.containers) do
				if container.recordId=="clod" then
					if (container.position-self.position):length()<100 then
						core.sendGlobalEvent('RemoveItem',{ Object = container, number=1})
					end
				end
			end
			for i, activator in pairs(nearby.activators) do
				if activator.recordId then
					if string.find(activator.recordId,"young ") and (activator.position-self.position):length()<100 then
						core.sendGlobalEvent('RemoveItem',{ Object = activator, number=1})
					end
				end
			end
			core.sendGlobalEvent('CreateTeleport',{ RecordId = "Clod", CellName=self.cell.name, Position=nearby.castRay(self.position,self.position+util.vector3(0,0,-50)).hitPos})
		end
	elseif input.isActionPressed(input.ACTION.Use) and ActionButton==false then 
		ActionButton=true
	end

end

return {
	eventHandlers = {TakeCare=TakeCare},
	engineHandlers = {

        onFrame = onFrame,
		onUpdate=onUpdate,
	}

}