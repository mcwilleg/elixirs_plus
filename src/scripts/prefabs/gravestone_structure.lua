require "prefabutil"

local prefabs = {
    "smallghost",
    "mound",
    "globalmapicon"
}

local assets = {
    Asset("ANIM", "anim/gravestones.zip"),
    Asset("MINIMAP_IMAGE", "gravestones"),
}

local function on_child_mound_dug(_, _)
end

local function specialdescriptionfn(inst, viewer)
    if viewer.prefab == "wendy" then
        return STRINGS.CHARACTERS.WENDY.DESCRIBE.GRAVESTONE_STRUCTURE
    end
    return inst.components.inspectable.description
end

local function onhit(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_stone")
    inst.AnimState:PlayAnimation(inst.grave_anim.."_hit")
    inst.AnimState:PushAnimation(inst.grave_anim, false)
end

local function on_gravestone_removed(inst)
    if inst.mound then
        local buried_trinket = inst.mound.components.gravecontainer.buried_trinket
        if buried_trinket ~= nil then
            inst.components.lootdropper:SpawnLootPrefab(buried_trinket)
            inst.mound.components.gravecontainer.buried_trinket = nil
        end
        inst.mound:Remove()
    end
    inst.components.lootdropper:SpawnLootPrefab("marble")
    inst.components.lootdropper:SpawnLootPrefab("marble")
    inst.components.lootdropper:SpawnLootPrefab("marble")
    if inst.ghost ~= nil then
        inst.ghost.sg:GoToState("disappear", function(ghost)
            ghost:DoTaskInTime(0, inst.ghost.RemoveFromScene)
        end)
        inst.ghost:DoTaskInTime(1, function(ghost) ghost:Remove() end)
    end
end

local function onfinishcallback(inst, _)
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("stone")
    inst:Remove()
end

local function onload(inst, data, newents)
    if data then
        if inst.mound and data.mounddata then
            if newents and data.mounddata.id then
                newents[data.mounddata.id] = {entity=inst.mound, data=data.mounddata}
            end
            inst.mound:SetPersistData(data.mounddata.data, newents)
        end

        if data.setepitaph then
            --this handles custom epitaphs set in the tile editor
            inst.components.inspectable:SetDescription("'"..data.setepitaph.."'")
            inst.setepitaph = data.setepitaph
        end
    end
end

local function onsave(inst, data)
    if inst.mound then
        data.mounddata = inst.mound:GetSaveRecord()
    end
    data.setepitaph = inst.setepitaph

    local ents = {}
    if inst.ghost ~= nil then
        data.ghost_id = inst.ghost.GUID
        table.insert(ents, data.ghost_id)
    end

    return ents
end

-- Ghosts on a quest (following someone) shouldn't block other ghost spawns!
local CANTHAVE_GHOST_TAGS = {"questing"}
local MUSTHAVE_GHOST_TAGS = {"ghostkid"}
local function on_day_change(inst)
    if inst.ghost == nil or not inst.ghost:IsValid() and #AllPlayers > 0 then
        local ghost_spawn_chance = 0
        for _, v in ipairs(AllPlayers) do
            if v:HasTag("ghostlyfriend") then
                ghost_spawn_chance = ghost_spawn_chance + TUNING.GHOST_GRAVESTONE_CHANCE
            end
        end
        ghost_spawn_chance = math.max(ghost_spawn_chance, TUNING.GHOST_GRAVESTONE_CHANCE)
        if inst.mound.components.gravecontainer.buried_trinket == nil then
            ghost_spawn_chance = 0.0
        end

        if math.random() < ghost_spawn_chance then
            local gx, gy, gz = inst.Transform:GetWorldPosition()
            local nearby_ghosts = TheSim:FindEntities(gx, gy, gz, TUNING.UNIQUE_SMALLGHOST_DISTANCE / 2, MUSTHAVE_GHOST_TAGS, CANTHAVE_GHOST_TAGS)
            if #nearby_ghosts < 3 then
                inst.ghost = SpawnPrefab("smallghost")
                inst.ghost.Transform:SetPosition(gx + 0.3, gy, gz + 0.3)
                inst.ghost:LinkToHome(inst)
            end
        end
    end
end

local function onloadpostpass(inst, newents, savedata)
    inst.ghost = nil
    if savedata ~= nil then
        if savedata.ghost_id ~= nil and newents[savedata.ghost_id] ~= nil then
            inst.ghost = newents[savedata.ghost_id].entity
			inst.ghost:LinkToHome(inst)
        end
    end
end

local function OnHaunt(inst)
    if inst.setepitaph == nil and #STRINGS.EPITAPHS > 1 then
        --change epitaph (if not a set custom epitaph)
        --guarantee it's not the same as b4!
        local oldepitaph = inst.components.inspectable.description
        local newepitaph = STRINGS.EPITAPHS[math.random(#STRINGS.EPITAPHS - 1)]
        if newepitaph == oldepitaph then
            newepitaph = STRINGS.EPITAPHS[#STRINGS.EPITAPHS]
        end
        inst.components.inspectable:SetDescription(newepitaph)
        inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
    else
        inst.components.hauntable.hauntvalue = TUNING.HAUNT_TINY
    end
    return true
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .25)

    inst.MiniMapEntity:SetIcon("gravestones.png")

    inst:AddTag("structure")
    inst:AddTag("grave")

    inst.AnimState:SetBank("gravestone")
    inst.AnimState:SetBuild("gravestones")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.grave_anim = "grave"..tostring(math.random(4))
    inst.AnimState:PlayAnimation(inst.grave_anim)

    inst:AddComponent("inspectable")
    inst.components.inspectable:SetDescription(STRINGS.EPITAPHS[math.random(#STRINGS.EPITAPHS)])
    inst.components.inspectable.getspecialdescription = specialdescriptionfn

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(6)
    inst.components.workable:SetOnFinishCallback(onfinishcallback)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst.mound = inst:SpawnChild("mound_structure")
    inst.mound.ghost_of_a_chance = 0.1
    inst:ListenForEvent("worked", on_child_mound_dug, inst.mound)
    inst.mound.Transform:SetPosition((TheCamera:GetDownVec()*.5):Get())

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetOnHauntFn(OnHaunt)

    inst:WatchWorldState("cycles", on_day_change)

    inst:ListenForEvent("onremove", on_gravestone_removed)

    inst.OnLoad = onload
    inst.OnSave = onsave
    inst.OnLoadPostPass = onloadpostpass

    return inst
end

return Prefab("gravestone_structure", fn, assets, prefabs),
       MakePlacer("gravestone_structure_placer", "gravestone", "gravestones", "grave2")
