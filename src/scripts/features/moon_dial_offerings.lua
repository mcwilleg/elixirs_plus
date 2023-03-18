local function GetOfferingValue(moondial, offering)
    local ritual_complete = moondial.pending_trinkets >= TUNING.NEW_ELIXIRS.MOONDIAL.RITUAL_COMPLETE_TRINKETS
    local item_value = offering.components.tradable and offering.components.tradable.goldvalue or 0
    if item_value > 0 then
        if ritual_complete then
            if TUNING.NEW_ELIXIRS.MOONDIAL.RITUAL_COMPLETE_FLOWERS >= 0 then
                item_value = TUNING.NEW_ELIXIRS.MOONDIAL.RITUAL_COMPLETE_FLOWERS
            end
        elseif TUNING.NEW_ELIXIRS.MOONDIAL.RITUAL_STARTED_FLOWERS >= 0 then
            item_value = TUNING.NEW_ELIXIRS.MOONDIAL.RITUAL_STARTED_FLOWERS
        end
    end
    return item_value or 0
end

local function SpewGhostFlowers(moondial)
    local flowers = moondial.pending_ghostflowers or 0
    if flowers > 0 then
        for k = 1, flowers do
            moondial:DoTaskInTime(k * 0.1 + 1.5, function(lootdropper)
                local loot = GLOBAL.SpawnPrefab("ghostflower")
                if loot ~= nil then
                    -- fling ghostflowers
                    local angle = math.random() * 2 * GLOBAL.PI
                    local sinangle = math.sin(angle)
                    local cosangle = math.cos(angle)
                    local pt = lootdropper:GetPosition()
                    pt.y = 2
                    loot.Transform:SetPosition(pt:Get())
                    if loot.Physics ~= nil then
                        loot.Physics:SetVel(2 * cosangle, 12, 2 * -sinangle)
                    end
                    local fx = GLOBAL.SpawnPrefab("splash")
                    fx.Transform:SetPosition(pt:Get())
                end
            end)
        end
        moondial.SoundEmitter:KillSound("idlesound")
        moondial.SoundEmitter:KillSound("howl")
        moondial.pending_trinkets = 0
        moondial.pending_ghostflowers = 0
    end
end

local function AddOffering(moondial, offering)
    local offering_value = GetOfferingValue(moondial, offering)
    moondial.pending_trinkets = (moondial.pending_trinkets or 0) + 1
    moondial.pending_ghostflowers = (moondial.pending_ghostflowers or 0) + offering_value
    if moondial.pending_trinkets >= TUNING.NEW_ELIXIRS.MOONDIAL.RITUAL_COMPLETE_TRINKETS then
        moondial.pending_ghostflowers = moondial.pending_ghostflowers + TUNING.NEW_ELIXIRS.MOONDIAL.RITUAL_COMPLETE_BONUS_FLOWERS
        moondial.SoundEmitter:PlaySound("dontstarve/common/together/celestial_orb/active")
        if not moondial.SoundEmitter:PlayingSound("idlesound") then
            moondial.SoundEmitter:PlaySound("dontstarve/common/together/celestial_orb/idle_LP", "idlesound")
        end
        if not moondial.SoundEmitter:PlayingSound("howl") then
            moondial.SoundEmitter:PlaySound("dontstarve/ghost/ghost_howl_LP", "howl")
        end
    end
    local pt = moondial:GetPosition()
    pt.y = 2
    local fx = GLOBAL.SpawnPrefab("splash")
    fx.Transform:SetPosition(pt:Get())
    moondial.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/medium")
end

AddAction("MOONOFFERING", "Make Offering", function(act)
    -- guard clauses
    if not act.invobject or not act.doer.components.inventory or not act.target then
        return
    end
    local player = act.doer
    local moondial = act.target
    local offering = player.components.inventory:RemoveItem(act.invobject)
    if not offering then
        return
    end

    -- failure reasons
    local reason
    if moondial.is_glassed then
        reason = "GLASSED"
    elseif GLOBAL.TheWorld.state.moonphase ~= "full" then
        reason = "NO_FULLMOON"
    elseif GLOBAL.TheWorld.state.phase ~= "night" then
        reason = "NO_NIGHT"
    end
    if reason then
        player.components.inventory:GiveItem(offering)
        moondial.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/small")
        return false, reason
    end

    moondial:AddOffering(offering)
    return true
end)

AddPrefabPostInit("moondial", function(inst)
    inst.pending_trinkets = 0
    inst.pending_ghostflowers = 0

    -- spew pending ghostflowers at dawn
    inst:WatchWorldState("isday", function(moondial, isday)
        if not isday then return end
        SpewGhostFlowers(moondial)
    end)

    inst.AddOffering = AddOffering

    if inst.components.inspectable ~= nil then
        local OldGetStatus = inst.components.inspectable.getstatus
        inst.components.inspectable.getstatus = function(moondial, viewer)
            if viewer.prefab == "wendy" then
                if moondial.pending_trinkets >= TUNING.NEW_ELIXIRS.MOONDIAL.RITUAL_COMPLETE_TRINKETS then
                    return "RITUAL_COMPLETE"
                elseif moondial.pending_trinkets > 0 then
                    return "RITUAL_STARTED"
                end
            else
                return OldGetStatus(moondial, viewer)
            end
        end
    end
end)

-- allow trinkets to be used on the moon dial via "MOONOFFERING" action
AddComponentAction("USEITEM", "inventoryitem", function(inst, doer, target, actions, _)
    if not target:HasTag("NOCLICK") then
        return
    end
    if doer:HasTag("elixirbrewer") and target.prefab == "moondial" and inst:HasTag("trinket") and GetOfferingValue(target, inst) > 0 then
        table.insert(actions, GLOBAL.ACTIONS.MOONOFFERING)
    end
end, "elixirs_plus")

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(GLOBAL.ACTIONS.MOONOFFERING, "dolongaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(GLOBAL.ACTIONS.MOONOFFERING, "dolongaction"))