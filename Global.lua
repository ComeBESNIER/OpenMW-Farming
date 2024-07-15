local world = require('openmw.world')
local types = require('openmw.types')
local interfaces = require('openmw.interfaces')
local util = require('openmw.util')
local time=require("openmw_aux.time")

local Initialize=false
local Seeds={}
local YoungFlora={}
local SavedData={}
if SavedData.SeedsRecordId==nil then
	SavedData.SeedsRecordId={}
end
if SavedData.FloraIngredients==nil then
	SavedData.FloraIngredients={}
end
if SavedData.YoungFlora==nil then
	SavedData.YoungFlora={}
	SavedData.YoungFlora.List={}
	SavedData.YoungFlora.Cared={}
end
if SavedData.YoungFlora then
	if SavedData.YoungFlora.List==nil then
		SavedData.YoungFlora.List={}
	end
	if SavedData.YoungFlora.Cared==nil then
		SavedData.YoungFlora.Cared={}
	end
end
print(SavedData.YoungFlora)


local ActiveCell=nil

local function SetScale(data)
	print("scale")
	data.Object:setScale(data.scale)
end

local function RemoveItem(data)
	if data.number>0 and data.Object.count>0 then
		data.Object:remove(data.number)
	end
end

local function CreateTeleport(data)
	world.createObject(data.RecordId,1):teleport(data.CellName,data.Position)
end

local function CreateYoungFlora(data)
	print("youngcreated")
	local YoungF=nil
	for i,youngflora in pairs(YoungFlora) do
		if youngflora.name=="Young "..data.Name then
			YoungF=world.createObject(youngflora.id,1)
			print(SavedData.YoungFlora)
			table.insert(SavedData.YoungFlora.List,YoungF)
			SavedData.YoungFlora.Cared[YoungF.recordId]=false
			YoungF:setScale(0.1)
			YoungF:teleport(data.CellName,data.Position+util.vector3(0,0,10))
			break
		end
	end
end

local function CarePlant(data)
	if SavedData.YoungFlora.Cared[data.Plant.recordId]==false then
		data.Player:sendEvent("TakeCare",{Cared=false})
		SavedData.YoungFlora.Cared[data.Plant.recordId]=true
	else 
		data.Player:sendEvent("TakeCare",{Cared=true})
	end
end

local function GrowPlants(data)
	if data.player==world.players[1] then
		if SavedData.YoungFlora~=nil then
			print("grow1")
			for i, youngplant in pairs(SavedData.YoungFlora.List) do
				if youngplant.scale<1 then
					print("Grown")
					local GrowChance=10
					if SavedData.YoungFlora.Cared[youngplant.recordId]==true then
						GrowChance=GrowChance+80
						SavedData.YoungFlora.Cared[youngplant.recordId]=false
					end
					for i, container in pairs(youngplant.cell:getAll(types.Container)) do
						if container.type.record(container).name==string.gsub(youngplant.type.record(youngplant).name,"Young ","") then
							GrowChance=GrowChance+10
							break
						end
					end
					if math.random(100)<GrowChance then
						print(youngplant.recordId.." grow2")
						youngplant:setScale(youngplant.scale+0.1)
					end
				elseif youngplant.scale>1 and youngplant.scale<1.1 and youngplant.count>0 then
					local Flora
					--print("create flora")
					for i,container in pairs(types.Container.records) do
						--print(container.model)
						--print(youngplant.type.record(youngplant).model)
						if container.name==string.gsub(youngplant.type.record(youngplant).name,"Young ","") and container.model==youngplant.type.record(youngplant).model then
							Flora=world.createObject(container.id,1)
							if SavedData.FloraIngredients[container.name] then
								world.createObject(SavedData.FloraIngredients[container.name],1):moveInto(types.Container.content(Flora))
							else
								types.Container.content(Flora):resolve()
							end
							--table.remove(SavedData.YoungFlora.Cared,youngplant.recordId)
							--table.remove(SavedData.YoungFlora.List,youngplant)
							SavedData.YoungFlora.Cared[youngplant.recordId]=nil
							SavedData.YoungFlora.List[youngplant]=nil
							print(youngplant)
							Flora:teleport(youngplant.cell.name,youngplant.position)
							youngplant:remove()
							break
						end
					end
				end
			end
		end
	end
	
end

local function CreateFlora(data)
	local Flora
	print("create flora")
	for i,container in pairs(types.Container.records) do
		print(container.model)
		print(data.Object.type.record(data.Object).model)
		if container.name==string.gsub(data.Object.type.record(data.Object).name,"Young ","") and container.model==data.Object.type.record(data.Object).model then
			Flora=world.createObject(container.id,1)
			if SavedData.FloraIngredients[container.name] then
				world.createObject(SavedData.FloraIngredients[container.name],1):moveInto(types.Container.content(Flora))
			else
				types.Container.content(Flora):resolve()
			end
			Flora:teleport(data.CellName,data.Position+util.vector3(0,0,10))
			break
		end
	end
end


local function CreateMoveInto(data)
	world.createObject(data.Object,1):moveInto(types.Container.content(data.container))
end

local function onUpdate()
	if Initialize==false then
		Initialize=true
		for i,container in pairs(types.Container.records) do
			if container.weight==0 and string.find(container.id,"flora") then --Check string waiting for checking respan and organic in container.record
				--print(container.name.." seed")
				--print("Young "..container.name)
				Seeds[container.name]=world.createRecord(types.Miscellaneous.createRecordDraft({	name=container.name.." seed", 
																											value=10, 
																											weight=0.01,
																											icon="icons/farming/seed.tga",
																											model="meshes\\farming\\seed.nif",
																										}))
				YoungFlora[container.name]=world.createRecord(types.Activator.createRecordDraft({	name="Young "..container.name, 
																												model=container.model,
																											}))
			end
		end
		for i,seed in pairs(Seeds) do
			world.createObject(seed.id,1):teleport(world.players[1].cell.name,world.players[1].position)
		end
	end

	if ActiveCell==nil then
		ActiveCell=world.players[1].cell
	elseif ActiveCell~=world.players[1].cell then	
		ActiveCell=world.players[1].cell
		for i, object in ipairs(world.players[1].cell:getAll(types.Container)) do
			if object.type.record(object).weight==0 and string.find(object.type.record(object).id,"flora") then --Check string waiting for checking respan and organic in container.record
				if math.random(100)<=101 then
					world.createObject(Seeds[object.type.record(object).name].id,1 ):moveInto(types.Container.content(object))
					print(object.type.content(object):getAll(types.Miscellaneous)[1])
				end
				if SavedData.FloraIngredients[object.type.record(object).name]==nil and object.type.content(object):getAll(types.Ingredient)[1] then
					SavedData.FloraIngredients[object.type.record(object).name]=object.type.content(object):getAll(types.Ingredient)[1].recordId
				end
			end
		end
	end

end


local function onSave()
	return{SavedData=SavedData,}
end

local function onLoad(data)
	if data then
		SavedData=data.SavedData
	end
end


return {
	eventHandlers = {CarePlant=CarePlant, GrowPlants=GrowPlants, CreateFlora=CreateFlora,SetScale=SetScale, CreateYoungFlora=CreateYoungFlora, CreateTeleport=CreateTeleport,RemoveItem=RemoveItem,},
	engineHandlers = {
        onUpdate = onUpdate,
		onSave=onSave,
		onLoad=onLoad,

	},
}