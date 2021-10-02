local assets = {
    Asset("ANIM", "anim/gravestones.zip"),
}

local prefabs = {
    "ghost",
}

local function ReturnChildren(inst)
    local toremove = {}
    for _, v in pairs(inst.components.childspawner.childrenoutside) do
        table.insert(toremove, v)
    end
    for _, v in ipairs(toremove) do
        if v:IsAsleep() then
            v:PushEvent("detachchild")
            v:Remove()
        else
            v.components.health:Kill()
        end
    end
end

local function spawnghost(inst, chance)
    if inst.ghost == nil and math.random() <= (chance or 1) then
        inst.ghost = SpawnPrefab("ghost")
        if inst.ghost ~= nil then
            local x, y, z = inst.Transform:GetWorldPosition()
            inst.ghost.Transform:SetPosition(x - .3, y, z - .3)
            inst:ListenForEvent("onremove", function() inst.ghost = nil end, inst.ghost)
            return true
        end
    end
    return false
end

local function OnFinishedDiggingCallback(inst, worker)
    inst.AnimState:PlayAnimation("dug")
    inst:RemoveComponent("workable")
    if worker ~= nil then
        if spawnghost(inst, inst.ghost_of_a_chance) then
            inst.ghost_of_a_chance = 0.0
        end
        if inst.components.gravecontainer.buried_trinket ~= nil then
            inst.components.lootdropper:SpawnLootPrefab(inst.components.gravecontainer.buried_trinket)
            inst.components.gravecontainer.buried_trinket = nil
        end
    end
end

local function onfinishburying(inst)
    inst.AnimState:PlayAnimation("gravedirt")
    inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/mole/emerge")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(OnFinishedDiggingCallback)
end

local function onfullmoon(inst, isfullmoon)
    if isfullmoon then
        inst.components.childspawner:StartSpawning()
        inst.components.childspawner:StopRegen()
    else
        inst.components.childspawner:StopSpawning()
        inst.components.childspawner:StartRegen()
        ReturnChildren(inst)
    end
end

local function GetStatus(inst)
    if inst.components.gravecontainer.buried_trinket == nil then
        return "DUG"
    end
end

local function OnSave(inst, data)
    data.buried_trinket = inst.components.gravecontainer.buried_trinket
end

local function OnLoad(inst, data)
    local buried_trinket = data ~= nil and data.buried_trinket or nil
    if buried_trinket == nil then
        inst.AnimState:PlayAnimation("dug")
    else
        onfinishburying(inst)
    end
    inst.components.gravecontainer.buried_trinket = data.buried_trinket
end

local function OnHaunt(_, _)
    return true
end

local function oninit(inst)
    inst:WatchWorldState("isfullmoon", onfullmoon)
    onfullmoon(inst, TheWorld.state.isfullmoon)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("gravestone")
    inst.AnimState:SetBuild("gravestones")
    inst.AnimState:PlayAnimation("dug")

    inst:AddTag("grave")
    inst:AddTag("customgrave")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("lootdropper")

    inst.ghost = nil
    inst.ghost_of_a_chance = 0.1

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_SMALL)
    inst.components.hauntable:SetOnHauntFn(OnHaunt)

    inst:AddComponent("childspawner")
    inst.components.childspawner.childname = "ghost"
    inst.components.childspawner:SetMaxChildren(1)
    inst.components.childspawner:SetSpawnPeriod(10, 3)

    inst:AddComponent("gravecontainer")
    inst.components.gravecontainer.buried_trinket = nil
    inst.components.gravecontainer.onfinishburying = onfinishburying

    inst:DoTaskInTime(0, oninit)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("mound_structure", fn, assets, prefabs)
