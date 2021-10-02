local GraveContainer = Class(function(self, inst)
    self.inst = inst
    self.buried_trinket = nil
end)

function GraveContainer:Bury(trinket, doer)
    if trinket:HasTag("trinket") then
        self.buried_trinket = trinket.prefab
        if self.onfinishburying ~= nil then
            self.onfinishburying(self.inst, doer)
        end
        return true
    end
end

return GraveContainer
