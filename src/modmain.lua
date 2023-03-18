Assets = {
	-- prefab anim files
	Asset("ANIM", "anim/new_elixirs.zip"),
	Asset("ANIM", "anim/gravestones.zip"),

	-- alternate builds
	Asset("ANIM", "anim/ghost_abigail_nightmare_build.zip"),
	Asset("ANIM", "anim/status_newelixir.zip"),

	-- inventory images
	Asset("IMAGE", "images/inventoryimages/gravestone_structure.tex"),
	Asset("ATLAS", "images/inventoryimages/gravestone_structure.xml"),
	Asset("IMAGE", "images/inventoryimages/newelixir_sanityaura.tex"),
	Asset("ATLAS", "images/inventoryimages/newelixir_sanityaura.xml"),
	Asset("IMAGE", "images/inventoryimages/newelixir_lightaura.tex"),
	Asset("ATLAS", "images/inventoryimages/newelixir_lightaura.xml"),
	Asset("IMAGE", "images/inventoryimages/newelixir_healthdamage.tex"),
	Asset("ATLAS", "images/inventoryimages/newelixir_healthdamage.xml"),
	Asset("IMAGE", "images/inventoryimages/newelixir_cleanse.tex"),
	Asset("ATLAS", "images/inventoryimages/newelixir_cleanse.xml"),
	Asset("IMAGE", "images/inventoryimages/newelixir_insanitydamage.tex"),
	Asset("ATLAS", "images/inventoryimages/newelixir_insanitydamage.xml"),
	Asset("IMAGE", "images/inventoryimages/newelixir_shadowfighter.tex"),
	Asset("ATLAS", "images/inventoryimages/newelixir_shadowfighter.xml"),
	Asset("IMAGE", "images/inventoryimages/newelixir_lightning.tex"),
	Asset("ATLAS", "images/inventoryimages/newelixir_lightning.xml"),
}

PrefabFiles = {
	"new_elixirs",
	"gravestone_structure",
	"mound_structure"
}

modimport("tuning.lua")

for k = 1, GLOBAL.NUM_TRINKETS do
	AddPrefabPostInit("trinket_"..tostring(k), function(inst)
		inst:AddTag("trinket")
	end)
end

modimport("features/moon_dial_offerings.lua")


AddAction("BURY", "Bury", function(act)
	if act.invobject ~= nil and act.doer.components.inventory ~= nil and act.target ~= nil then
		local trinket = act.doer.components.inventory:RemoveItem(act.invobject)
		if trinket ~= nil then
			if act.target.components.gravecontainer ~= nil and act.target.components.gravecontainer:Bury(trinket, act.doer) then
				return true
			end
			act.doer.components.inventory:GiveItem(trinket)
		end
	end
end)

AddComponentAction("USEITEM", "inventoryitem", function(inst, _, target, actions, _)
	if inst:HasTag("trinket") and target:HasTag("customgrave") and not target:HasTag("NOCLICK") then
		table.insert(actions, GLOBAL.ACTIONS.BURY)
	end
end, "elixirs_plus")

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(GLOBAL.ACTIONS.BURY, "dolongaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(GLOBAL.ACTIONS.BURY, "dolongaction"))



local function DoNightmareElixir(_, _, target)
	target.AnimState:SetBuild("ghost_abigail_nightmare_build")
end

local function DoApplyElixir(inst, giver, target)
	if target ~= nil and target.components.debuffable ~= nil then
		local cur_buff = target.components.debuffable:GetDebuff("elixir_buff")
		if cur_buff ~= nil then
			if cur_buff.potion_tunings.NIGHTMARE_ELIXIR and not inst.potion_tunings.NIGHTMARE_ELIXIR and inst.prefab ~= "newelixir_cleanse" then
				return false, "WRONG_ELIXIR"
			end
			if cur_buff.prefab ~= inst.buff_prefab then
				target.components.debuffable:RemoveDebuff("elixir_buff")
			end
		elseif inst.prefab == "newelixir_cleanse" then
			return false, "NO_ELIXIR"
		end
		target.components.debuffable:AddDebuff("elixir_buff", inst.buff_prefab)
		if inst.potion_tunings.NIGHTMARE_ELIXIR then
			DoNightmareElixir(inst, giver, target)
		end
		return true
	end
end

local function UpdateDoApplyElixirFn(inst)
	if inst.components.ghostlyelixir ~= nil then
		inst.components.ghostlyelixir.doapplyelixerfn = DoApplyElixir
	end
end

-- Name suffixes of old elixirs
local OLD_ELIXIRS = {
	"slowregen",
	"fastregen",
	"speed",
	"attack",
	"shield",
	"retaliation",
}

-- Name suffixes of all new elixirs
local NEW_ELIXIRS = {
	"sanityaura",
	"lightaura",
	"healthdamage",
	"cleanse",
	"insanitydamage",
	"shadowfighter",
	"lightning",
}

-- Update apply functions for all elixirs
for _, ELIXIR in ipairs(OLD_ELIXIRS) do
	AddPrefabPostInit("ghostlyelixir_"..ELIXIR, UpdateDoApplyElixirFn)
end
for _, ELIXIR in ipairs(NEW_ELIXIRS) do
	AddPrefabPostInit("newelixir_"..ELIXIR, UpdateDoApplyElixirFn)
end

-- Update (improve) old elixir buffs
AddPrefabPostInit("ghostlyelixir_speed", function(inst)
	if not inst.potion_tunings then
		return
	end
	local old_apply_fn = inst.potion_tunings.ONAPPLY
	inst.potion_tunings.ONAPPLY = function(elixir, target)
		if old_apply_fn ~= nil then
			old_apply_fn(elixir, target)
		end
		elixir.old_min_follow = TUNING.ABIGAIL_DEFENSIVE_MIN_FOLLOW
		elixir.old_med_follow = TUNING.ABIGAIL_DEFENSIVE_MED_FOLLOW
		elixir.old_max_follow = TUNING.ABIGAIL_DEFENSIVE_MAX_FOLLOW
		TUNING.ABIGAIL_DEFENSIVE_MIN_FOLLOW = 0.6
		TUNING.ABIGAIL_DEFENSIVE_MED_FOLLOW = 1.2
		TUNING.ABIGAIL_DEFENSIVE_MAX_FOLLOW = 1.5
	end

	local old_detach_fn = inst.potion_tunings.ONDETACH
	inst.potion_tunings.ONDETACH = function(elixir, target)
		if old_detach_fn ~= nil then
			old_detach_fn(elixir, target)
		end
		TUNING.ABIGAIL_DEFENSIVE_MIN_FOLLOW = elixir.old_min_follow
		TUNING.ABIGAIL_DEFENSIVE_MED_FOLLOW = elixir.old_med_follow
		TUNING.ABIGAIL_DEFENSIVE_MAX_FOLLOW = elixir.old_max_follow
	end
end)

AddPrefabPostInit("ghostlyelixir_slowregen", function(inst)
	if not inst.potion_tunings then
		return
	end
	local old_apply_fn = inst.potion_tunings.ONAPPLY
	inst.potion_tunings.ONAPPLY = function(elixir, target)
		if old_apply_fn ~= nil then
			old_apply_fn(elixir, target)
		end
		if target._playerlink ~= nil then
			target._playerlink.components.ghostlybond:SetBondTimeMultiplier(elixir.prefab, 3)
		end
	end

	local old_detach_fn = inst.potion_tunings.ONDETACH
	inst.potion_tunings.ONDETACH = function(elixir, target)
		if old_detach_fn ~= nil then
			old_detach_fn(elixir, target)
		end
		if target._playerlink ~= nil then
			target._playerlink.components.ghostlybond:SetBondTimeMultiplier(elixir.prefab, nil)
		end
	end
end)

AddPrefabPostInit("abigail", function(inst)
	-- Add function to update angry eyes build when riled up
	inst.UpdateEyes = function(abigail)
		if abigail.is_defensive then
			abigail.AnimState:ClearOverrideSymbol("ghost_eyes")
		else
			abigail.AnimState:OverrideSymbol("ghost_eyes", abigail.AnimState:GetBuild(), "angry_ghost_eyes")
		end
	end

	-- Add function to turn nightmare abigail on and off
	inst.SetNightmareAbigail = function(abigail, nightmare)
		if nightmare then
			abigail.AnimState:SetBuild("ghost_abigail_nightmare_build")
			--[[abigail:AddComponent("sanityaura")
			abigail.components.sanityaura.aura = -TUNING.SANITYAURA_LARGE
			if abigail._playerlink ~= nil then
				abigail._playerlink.components.sanity:RemoveSanityAuraImmunity("ghost")
			end]]
		else
			abigail.AnimState:SetBuild("ghost_abigail_build")
			--[[abigail:RemoveComponent("sanityaura")
			if abigail._playerlink ~= nil then
				abigail._playerlink.components.sanity:AddSanityAuraImmunity("ghost")
			end]]
		end
		abigail:UpdateEyes()
	end

	-- Add function to get nightmare status
	inst.IsNightmareAbigail = function(abigail)
		return abigail.AnimState:GetBuild() == "ghost_abigail_nightmare_build"
	end

	-- New inspect dialogue for nightmare abigail
	if inst.components.inspectable ~= nil then
		local OldGetStatus = inst.components.inspectable.getstatus
		inst.components.inspectable.getstatus = function(abigail, viewer)
			if viewer.prefab == "wendy" and abigail.AnimState:GetBuild() == "ghost_abigail_nightmare_build" then
				return "NIGHTMARE"
			else
				return OldGetStatus(abigail)
			end
		end
	end

	-- Let abigail use any build's angry eyes when riled up (normally hard-coded, no good)
	local OldBecomeAggressive = inst.BecomeAggressive
	inst.BecomeAggressive = function(abigail)
		local current_build = abigail.AnimState:GetBuild()
		OldBecomeAggressive(abigail)
		abigail.AnimState:OverrideSymbol("ghost_eyes", current_build, "angry_ghost_eyes")
	end

	-- sanity bomb nearby players when abigail dies with a nightmare elixir equipped
	inst:ListenForEvent("stopaura", function(abigail)
		if abigail:IsNightmareAbigail() then
			local x, y, z = abigail.Transform:GetWorldPosition()
			local necessary_tags = { "player" }
			local nearby_players = GLOBAL.TheSim:FindEntities(x, y, z, 15, necessary_tags)
			for _, p in ipairs(nearby_players) do
				if p.components.sanity ~= nil then
					p.components.sanity:DoDelta(-TUNING.SANITY_HUGE)
				end
			end
			local nightmare_burst = GLOBAL.SpawnPrefab("stalker_shield")
			nightmare_burst.Transform:SetPosition(abigail:GetPosition():Get())
			nightmare_burst.AnimState:SetScale(1.5, 1.5, 1.5)
			abigail.SoundEmitter:PlaySound("dontstarve/common/deathpoof")
		end
	end)
end)

--[[
local normal_ghost_prefabs = {
	"ghost",
	"smallghost",
}

-- Tag non-abigail ghosts for wendy's sanity aura immunities
for _, prefab in ipairs(normal_ghost_prefabs) do
	AddPrefabPostInit(prefab, function(inst)
		inst:AddTag("normalghost")
	end)
end
AddPrefabPostInit("wendy", function(inst)
	if inst.components.sanity ~= nil then
		inst.components.sanity:AddSanityAuraImmunity("normalghost")
	end
end)]]

-- these numbers are copied from debug logs, not sure how to get net_hash vars outside the class without using literals
-- print(abigail._playerlink.components.pethealthbar:GetDebugString()) -> convert symbol hex to decimal
AddClassPostConstruct("widgets/statusdisplays", function(inst)
	if inst.pethealthbadge then
		inst.pethealthbadge:SetBuildForSymbol("status_newelixir", 233052865)	--newelixir_sanityaura_buff
		inst.pethealthbadge:SetBuildForSymbol("status_newelixir", 3759892665)	--newelixir_lightaura_buff
		inst.pethealthbadge:SetBuildForSymbol("status_newelixir", 1525997575)	--newelixir_healthdamage_buff
		inst.pethealthbadge:SetBuildForSymbol("status_newelixir", 3096020880)	--newelixir_insanitydamage_buff
		inst.pethealthbadge:SetBuildForSymbol("status_newelixir", 3487606133)	--newelixir_shadowfighter_buff
		inst.pethealthbadge:SetBuildForSymbol("status_newelixir", 536102728)	--newelixir_lightning_buff
	end
end)

modimport("recipes.lua")
modimport("constants.lua")

-- enter debug mode
GLOBAL.CHEATS_ENABLED = true
GLOBAL.require('debugkeys')
