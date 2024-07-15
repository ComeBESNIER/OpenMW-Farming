local self=require('openmw.self')
local core=require('openmw.core')
local types=require('openmw.types')

local SeedIn=false

local function onUpdate()
	if self.recordId=="clod" and SeedIn==false then
		if self.type.content(self):getAll(types.Miscellaneous)[1] then
			if string.find(self.type.content(self):getAll(types.Miscellaneous)[1].type.record(self.type.content(self):getAll(types.Miscellaneous)[1]).name," seed") then
				SeedIn=true
				print("seedin")
				core.sendGlobalEvent('CreateYoungFlora',{ Name = string.gsub(self.type.content(self):getAll(types.Miscellaneous)[1].type.record(self.type.content(self):getAll(types.Miscellaneous)[1]).name," seed",""), CellName=self.cell.name, Position=self.position})
				core.sendGlobalEvent('RemoveItem',{ Object = self, number=1})
			end
		end
	end
end



return {
	engineHandlers = {onUpdate=onUpdate}
}