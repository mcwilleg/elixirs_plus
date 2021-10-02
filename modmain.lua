Assets = {
	-- prefab anim files
	Asset("ANIM", "anim/new_elixirs.zip"),
	Asset("ANIM", "anim/bandage_ghost.zip"),
	Asset("ANIM", "anim/gravestones.zip"),

	-- alternate builds
	Asset("ANIM", "anim/ghost_abigail_nightmare_build.zip"),
	Asset("ANIM", "anim/status_newelixir.zip"),

	-- inventory images
  Asset("IMAGE", "images/inventoryimages/bandage_ghost.tex"),
  Asset("ATLAS", "images/inventoryimages/bandage_ghost.xml"),
  Asset("IMAGE", "images/inventoryimages/gravestone_structure.tex"),
  Asset("ATLAS", "images/inventoryimages/gravestone_structure.xml"),
  Asset("IMAGE", "images/inventoryimages/newelixir_sanityaura.tex"),
  Asset("ATLAS", "images/inventoryimages/newelixir_sanityaura.xml"),
  Asset("IMAGE", "images/inventoryimages/newelixir_lightaura.tex"),
  Asset("ATLAS", "images/inventoryimages/newelixir_lightaura.xml"),
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
	"bandage_ghost",
	"gravestone_structure",
	"mound_structure"
}

local STRINGS = GLOBAL.STRINGS
local CHARACTERS = STRINGS.CHARACTERS
local Ingredient = GLOBAL.Ingredient
local RECIPETABS = GLOBAL.RECIPETABS
local CUSTOM_RECIPETABS = GLOBAL.CUSTOM_RECIPETABS
local TECH = GLOBAL.TECH
local require = GLOBAL.require

-- tuning values for this mod here
TUNING.ELIXIRS_PLUS = {
	MAX_SACRIFICE = 10,
	SANITYAURA = {
		AURA = TUNING.SANITYAURA_MED
	},
	LIGHTAURA = {
		LIGHT_RADIUS = 5,
		TEMPERATURE = 85
	},
	HEALTHDAMAGE = {
		LOW_DAMAGE_MULT = 1.4,
		MED_DAMAGE_MULT = 1.6,
		HIGH_DAMAGE_MULT = 1.9,
		CRIT_DAMAGE_MULT = 2.4,

		HIGH_HEALTH = 0.65,
		MED_HEALTH = 0.4,
		LOW_HEALTH = 0.2
	},
	CLEANSE = {
		HEAL_MULT = 0.3,
		SANITY_GAIN = TUNING.SANITY_LARGE
	},
	LIGHTNING = {
		SMITE_CHANCE = 0.1
	}
}

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

local ghostflower_values = {
	bee = 2,
	killerbee = 2,
	butterfly = 1,
	crow = 2,
	robin = 2,
	robin_winter = 2,
	canary = 2,
	puffin = 2,
	fireflies = 3,
	lureplantbulb = 4,
	mosquito = 2,
	rabbit = 1,
	mole = 2,
	carrat = 2,
	moonbutterfly = 3
}

AddAction("MOONSACRIFICE", "Drown", function(act)
  if act.invobject ~= nil and act.doer.components.inventory ~= nil and act.target ~= nil then
		local animal = act.doer.components.inventory:RemoveItem(act.invobject)
		local reason = nil
		if animal ~= nil then
			if GLOBAL.TheWorld.state.moonphase ~= "full" then
				reason = "NO_FULLMOON"
			elseif GLOBAL.TheWorld.state.phase ~= "night" then
				reason = "NO_NIGHT"
			else
				act.target.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/medium")
				if animal.components.health ~= nil and animal.components.health.murdersound ~= nil then
					act.target.SoundEmitter:PlaySound(GLOBAL.FunctionOrValue(animal.components.health.murdersound, animal, act.doer))
				end
				act.target.pending_ghostflowers = math.min((act.target.pending_ghostflowers or 0) + (ghostflower_values[animal.prefab] or 1), TUNING.ELIXIRS_PLUS.MAX_SACRIFICE)
				if act.doer.components.sanity ~= nil then
					act.doer.components.sanity:DoDelta(-TUNING.SANITY_LARGE)
				end
				return true
			end
			act.doer.components.inventory:GiveItem(animal)
			act.target.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/small")
			return false, reason
		end
	end
end)

AddComponentAction("USEITEM", "inventoryitem", function(inst, doer, target, actions, right)
	local item_value = ghostflower_values[inst.prefab] or 0
	if target.prefab == "moondial" and item_value > 0 and ((target.pending_ghostflowers or 0) + item_value) < TUNING.ELIXIRS_PLUS.MAX_SACRIFICE and not target:HasTag("NOCLICK") then
		table.insert(actions, GLOBAL.ACTIONS.MOONSACRIFICE)
	end
	if inst:HasTag("trinket") and target:HasTag("customgrave") and not target:HasTag("NOCLICK") then
		table.insert(actions, GLOBAL.ACTIONS.BURY)
	end
end, "elixirs_plus")

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(GLOBAL.ACTIONS.BURY, "dolongaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(GLOBAL.ACTIONS.BURY, "dolongaction"))

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(GLOBAL.ACTIONS.MOONSACRIFICE, "dolongaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(GLOBAL.ACTIONS.MOONSACRIFICE, "dolongaction"))

AddPrefabPostInit("moondial", function(inst)
	inst:WatchWorldState("isday", function(inst, isday)
		if not isday then return end
		local flowers = inst.pending_ghostflowers or 0
		if flowers > 0 then
			for k = 1, flowers do
				inst:DoTaskInTime(k / 5.0, function(moondial)
					local loot = GLOBAL.SpawnPrefab("ghostflower")
					if loot ~= nil then
						local angle = math.random() * 2 * GLOBAL.PI
            local sinangle = math.sin(angle)
            local cosangle = math.cos(angle)
						local pt = moondial:GetPosition()
						local radius = loot:GetPhysicsRadius(1)
						loot.Transform:SetPosition(
							pt.x - cosangle / 2.0,
							pt.y + 1.2,
							pt.z + sinangle / 2.0
						)
						if loot.Physics ~= nil then
              loot.Physics:SetVel(2 * cosangle, 12, 2 * -sinangle)
						end
					end
				end)
			end
			inst.pending_ghostflowers = 0
		end
	end)
	inst.pending_ghostflowers = 0
end)

local function TrinketPostInit(inst)
	inst:AddTag("trinket")
end

for k = 1, GLOBAL.NUM_TRINKETS do
	AddPrefabPostInit("trinket_"..tostring(k), TrinketPostInit)
	if k <= GLOBAL.NUM_HALLOWEEN_ORNAMENTS then
		AddPrefabPostInit("halloween_ornament_"..tostring(k), TrinketPostInit)
	end
end

local normal_ghost_prefabs = {
	"ghost",
	"smallghost",
}

-- Tag non-abigail ghosts for wendy's sanity aura immunities
for _g, prefab in ipairs(normal_ghost_prefabs) do
	AddPrefabPostInit(prefab, function(inst)
		inst:AddTag("normalghost")
	end)
end

AddPrefabPostInit("wendy", function(inst)
	if inst.components.sanity ~= nil then
		inst.components.sanity:AddSanityAuraImmunity("normalghost")
	end
end)

local function DoNightmareElixir(inst, giver, target)
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
		else
			if inst.prefab == "newelixir_cleanse" then
				return false, "NO_ELIXIR"
			end
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
	--"freeze",
}

-- Update apply functions for all elixirs
for _e, ELIXIR in ipairs(OLD_ELIXIRS) do
	AddPrefabPostInit("ghostlyelixir_"..ELIXIR, UpdateDoApplyElixirFn)
end
for _e, ELIXIR in ipairs(NEW_ELIXIRS) do
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
		TUNING.ABIGAIL_DEFENSIVE_MIN_FOLLOW = 1
		TUNING.ABIGAIL_DEFENSIVE_MED_FOLLOW = 1.5
		TUNING.ABIGAIL_DEFENSIVE_MAX_FOLLOW = 2
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
	inst.UpdateEyes = function(inst)
		if inst.is_defensive then
			inst.AnimState:ClearOverrideSymbol("ghost_eyes")
		else
			inst.AnimState:OverrideSymbol("ghost_eyes", inst.AnimState:GetBuild(), "angry_ghost_eyes")
		end
	end

	-- Add function to turn nightmare abigail on and off
	inst.SetNightmareAbigail = function(inst, nightmare)
		if nightmare then
			inst.AnimState:SetBuild("ghost_abigail_nightmare_build")
			inst:AddComponent("sanityaura")
			inst.components.sanityaura.aura = -TUNING.SANITYAURA_LARGE
			if inst._playerlink ~= nil then
				inst._playerlink.components.sanity:RemoveSanityAuraImmunity("ghost")
			end
		else
			inst.AnimState:SetBuild("ghost_abigail_build")
			inst:RemoveComponent("sanityaura")
			if inst._playerlink ~= nil then
				inst._playerlink.components.sanity:AddSanityAuraImmunity("ghost")
			end
		end
		inst:UpdateEyes()
	end

	-- New inspect dialogue for nightmare abigail
	if inst.components.inspectable ~= nil then
		local OldGetStatus = inst.components.inspectable.getstatus
		inst.components.inspectable.getstatus = function(inst)
			if inst.AnimState:GetBuild() == "ghost_abigail_nightmare_build" then
				return "NIGHTMARE"
			else
				return OldGetStatus(inst)
			end
		end
	end

	-- Let abigail use any build's angry eyes when riled up (normally hard-coded, no good)
	local OldBecomeAggressive = inst.BecomeAggressive
	inst.BecomeAggressive = function(inst)
		local current_build = inst.AnimState:GetBuild()
		OldBecomeAggressive(inst)
		inst.AnimState:OverrideSymbol("ghost_eyes", current_build, "angry_ghost_eyes")
	end
end)

AddPrefabPostInit("wendy", function(inst)
	inst.OnUseGhostBandage = function(inst, data)
		if data.cause == "bandage_ghost" then
			if inst.components.sanity ~= nil then
				inst.components.sanity:DoDelta(TUNING.SANITY_MED)
			end
			if inst.components.ghostlybond ~= nil then
				local ghost = inst.components.ghostlybond.ghost
				if ghost ~= nil then
					local healing = ghost.components.health:GetMaxWithPenalty() * 0.2
					ghost.components.health:DoDelta(healing)
				end
			end
		end
	end
	inst:ListenForEvent("healthdelta", inst.OnUseGhostBandage)
end)

-- these numbers are copied from debug logs, not sure how to get net_hash vars outside the class without using literals
AddClassPostConstruct("widgets/statusdisplays", function(inst)
	if inst.pethealthbadge then
		inst.pethealthbadge:SetBuildForSymbol("status_newelixir", 233052865)	--newelixir_sanityaura_buff
		inst.pethealthbadge:SetBuildForSymbol("status_newelixir", 3759892665)	--newelixir_lightaura_buff
		inst.pethealthbadge:SetBuildForSymbol("status_newelixir", 3096020880)	--newelixir_insanitydamage_buff
		inst.pethealthbadge:SetBuildForSymbol("status_newelixir", 3487606133)	--newelixir_shadowfighter_buff
		inst.pethealthbadge:SetBuildForSymbol("status_newelixir", 536102728)	--newelixir_lightning_buff
	end
end)

-- Add recipes for new elixirs
AddRecipe("newelixir_sanityaura", {
	Ingredient("petals", 1),
	Ingredient("ghostflower", 1)
}, CUSTOM_RECIPETABS.ELIXIRBREWING, TECH.NONE, nil, nil, nil, nil, "elixirbrewer",
"images/inventoryimages/newelixir_sanityaura.xml",
"newelixir_sanityaura.tex")

AddRecipe("newelixir_lightaura", {
	Ingredient("redgem", 1),
	Ingredient("ghostflower", 1)
}, CUSTOM_RECIPETABS.ELIXIRBREWING, TECH.NONE, nil, nil, nil, nil, "elixirbrewer",
"images/inventoryimages/newelixir_lightaura.xml",
"newelixir_lightaura.tex")

AddRecipe("newelixir_healthdamage", {
	Ingredient("mosquitosack", 2),
	Ingredient(GLOBAL.CHARACTER_INGREDIENT.HEALTH, 30),
	Ingredient("ghostflower", 3)
}, CUSTOM_RECIPETABS.ELIXIRBREWING, TECH.NONE, nil, nil, nil, nil, "elixirbrewer",
"images/inventoryimages/newelixir_lightaura.xml",
"newelixir_lightaura.tex")

AddRecipe("newelixir_cleanse", {
	Ingredient("ash", 2),
	Ingredient("petals", 2),
	Ingredient("ghostflower", 2)
}, CUSTOM_RECIPETABS.ELIXIRBREWING, TECH.NONE, nil, nil, nil, nil, "elixirbrewer",
"images/inventoryimages/newelixir_cleanse.xml",
"newelixir_cleanse.tex")

AddRecipe("newelixir_insanitydamage", {
	Ingredient("stinger", 1),
	Ingredient("nightmarefuel", 5),
	Ingredient("ghostflower", 3)
}, CUSTOM_RECIPETABS.ELIXIRBREWING, TECH.MAGIC_THREE, nil, nil, nil, nil, "elixirbrewer",
"images/inventoryimages/newelixir_insanitydamage.xml",
"newelixir_insanitydamage.tex")

AddRecipe("newelixir_shadowfighter", {
	Ingredient("purplegem", 1),
	Ingredient("nightmarefuel", 5),
	Ingredient("ghostflower", 3)
}, CUSTOM_RECIPETABS.ELIXIRBREWING, TECH.MAGIC_THREE, nil, nil, nil, nil, "elixirbrewer",
"images/inventoryimages/newelixir_shadowfighter.xml",
"newelixir_shadowfighter.tex")

AddRecipe("newelixir_lightning", {
	Ingredient("lightninggoathorn", 1),
	Ingredient("nightmarefuel", 5),
	Ingredient("ghostflower", 3)
}, CUSTOM_RECIPETABS.ELIXIRBREWING, TECH.MAGIC_THREE, nil, nil, nil, nil, "elixirbrewer",
"images/inventoryimages/newelixir_lightning.xml",
"newelixir_lightning.tex")

AddRecipe("gravestone_structure", {
	Ingredient("marble", 10),
	Ingredient("boneshard", 4),
	Ingredient("shovel", 1)
}, RECIPETABS.TOWN, TECH.NONE, "gravestone_structure_placer", nil, nil, nil, "elixirbrewer",
"images/inventoryimages/gravestone_structure.xml",
"gravestone_structure.tex")

--AddRecipe("bandage_ghost", {
	--Ingredient("charcoal", 1),
	--Ingredient("petals", 1),
	--Ingredient("ice", 2)
--}, CUSTOM_RECIPETABS.ELIXIRBREWING, TECH.NONE, nil, nil, nil, nil, "elixirbrewer",
--"images/inventoryimages/bandage_ghost.xml",
--"bandage_ghost.tex")

--AddRecipe("newelixir_freeze", {
	--Ingredient("bluegem", 1),
	--Ingredient("nightmarefuel", 5),
	--Ingredient("ghostflower", 3)
--}, CUSTOM_RECIPETABS.ELIXIRBREWING, TECH.NONE, nil, nil, nil, nil, "elixirbrewer",
--"images/inventoryimages/newelixir_freeze.xml",
--"newelixir_freeze.tex")

-- bandage_ghost description
CHARACTERS.GENERIC.DESCRIBE.BANDAGE_GHOST = CHARACTERS.GENERIC.DESCRIBE.GHOSTLYELIXIR_SPEED
CHARACTERS.WILLOW.DESCRIBE.BANDAGE_GHOST = CHARACTERS.WILLOW.DESCRIBE.GHOSTLYELIXIR_SPEED
CHARACTERS.WOLFGANG.DESCRIBE.BANDAGE_GHOST = CHARACTERS.WOLFGANG.DESCRIBE.GHOSTLYELIXIR_SPEED
CHARACTERS.WX78.DESCRIBE.BANDAGE_GHOST = CHARACTERS.WX78.DESCRIBE.GHOSTLYELIXIR_SPEED
CHARACTERS.WICKERBOTTOM.DESCRIBE.BANDAGE_GHOST = CHARACTERS.WICKERBOTTOM.DESCRIBE.GHOSTLYELIXIR_SPEED
CHARACTERS.WOODIE.DESCRIBE.BANDAGE_GHOST = CHARACTERS.WOODIE.DESCRIBE.GHOSTLYELIXIR_SPEED
CHARACTERS.WAXWELL.DESCRIBE.BANDAGE_GHOST = CHARACTERS.WAXWELL.DESCRIBE.GHOSTLYELIXIR_SPEED
CHARACTERS.WATHGRITHR.DESCRIBE.BANDAGE_GHOST = CHARACTERS.WATHGRITHR.DESCRIBE.GHOSTLYELIXIR_SPEED
CHARACTERS.WEBBER.DESCRIBE.BANDAGE_GHOST = CHARACTERS.WEBBER.DESCRIBE.GHOSTLYELIXIR_SPEED
CHARACTERS.WARLY.DESCRIBE.BANDAGE_GHOST = CHARACTERS.WARLY.DESCRIBE.GHOSTLYELIXIR_SPEED
CHARACTERS.WORMWOOD.DESCRIBE.BANDAGE_GHOST = CHARACTERS.WORMWOOD.DESCRIBE.GHOSTLYELIXIR_SPEED
CHARACTERS.WINONA.DESCRIBE.BANDAGE_GHOST = CHARACTERS.WINONA.DESCRIBE.GHOSTLYELIXIR_SPEED
CHARACTERS.WORTOX.DESCRIBE.BANDAGE_GHOST = CHARACTERS.WORTOX.DESCRIBE.GHOSTLYELIXIR_SPEED
CHARACTERS.WURT.DESCRIBE.BANDAGE_GHOST = CHARACTERS.WURT.DESCRIBE.GHOSTLYELIXIR_SPEED
CHARACTERS.WALTER.DESCRIBE.BANDAGE_GHOST = CHARACTERS.WALTER.DESCRIBE.GHOSTLYELIXIR_SPEED

-- mound_structure description
CHARACTERS.GENERIC.DESCRIBE.MOUND_STRUCTURE = CHARACTERS.GENERIC.DESCRIBE.MOUND
CHARACTERS.WILLOW.DESCRIBE.MOUND_STRUCTURE = CHARACTERS.WILLOW.DESCRIBE.MOUND
CHARACTERS.WOLFGANG.DESCRIBE.MOUND_STRUCTURE = CHARACTERS.WOLFGANG.DESCRIBE.MOUND
CHARACTERS.WX78.DESCRIBE.MOUND_STRUCTURE = CHARACTERS.WX78.DESCRIBE.MOUND
CHARACTERS.WICKERBOTTOM.DESCRIBE.MOUND_STRUCTURE = CHARACTERS.WICKERBOTTOM.DESCRIBE.MOUND
CHARACTERS.WOODIE.DESCRIBE.MOUND_STRUCTURE = CHARACTERS.WOODIE.DESCRIBE.MOUND
CHARACTERS.WAXWELL.DESCRIBE.MOUND_STRUCTURE = CHARACTERS.WAXWELL.DESCRIBE.MOUND
CHARACTERS.WATHGRITHR.DESCRIBE.MOUND_STRUCTURE = CHARACTERS.WATHGRITHR.DESCRIBE.MOUND
CHARACTERS.WEBBER.DESCRIBE.MOUND_STRUCTURE = CHARACTERS.WEBBER.DESCRIBE.MOUND
CHARACTERS.WARLY.DESCRIBE.MOUND_STRUCTURE = CHARACTERS.WARLY.DESCRIBE.MOUND
CHARACTERS.WORMWOOD.DESCRIBE.MOUND_STRUCTURE = CHARACTERS.WORMWOOD.DESCRIBE.MOUND
CHARACTERS.WINONA.DESCRIBE.MOUND_STRUCTURE = CHARACTERS.WINONA.DESCRIBE.MOUND
CHARACTERS.WORTOX.DESCRIBE.MOUND_STRUCTURE = CHARACTERS.WORTOX.DESCRIBE.MOUND
CHARACTERS.WURT.DESCRIBE.MOUND_STRUCTURE = CHARACTERS.WURT.DESCRIBE.MOUND
CHARACTERS.WALTER.DESCRIBE.MOUND_STRUCTURE = CHARACTERS.WALTER.DESCRIBE.MOUND

-- new elixir descriptions for non-Wendy characters
for _, ELIXIR in ipairs(NEW_ELIXIRS) do
	CHARACTERS.GENERIC.DESCRIBE["NEWELIXIR_"..string.upper(ELIXIR)] = CHARACTERS.GENERIC.DESCRIBE.GHOSTLYELIXIR_SPEED
	CHARACTERS.WILLOW.DESCRIBE["NEWELIXIR_"..string.upper(ELIXIR)] = CHARACTERS.WILLOW.DESCRIBE.GHOSTLYELIXIR_SPEED
	CHARACTERS.WOLFGANG.DESCRIBE["NEWELIXIR_"..string.upper(ELIXIR)] = CHARACTERS.WOLFGANG.DESCRIBE.GHOSTLYELIXIR_SPEED
	CHARACTERS.WX78.DESCRIBE["NEWELIXIR_"..string.upper(ELIXIR)] = CHARACTERS.WX78.DESCRIBE.GHOSTLYELIXIR_SPEED
	CHARACTERS.WICKERBOTTOM.DESCRIBE["NEWELIXIR_"..string.upper(ELIXIR)] = CHARACTERS.WICKERBOTTOM.DESCRIBE.GHOSTLYELIXIR_SPEED
	CHARACTERS.WOODIE.DESCRIBE["NEWELIXIR_"..string.upper(ELIXIR)] = CHARACTERS.WOODIE.DESCRIBE.GHOSTLYELIXIR_SPEED
	CHARACTERS.WAXWELL.DESCRIBE["NEWELIXIR_"..string.upper(ELIXIR)] = CHARACTERS.WAXWELL.DESCRIBE.GHOSTLYELIXIR_SPEED
	CHARACTERS.WATHGRITHR.DESCRIBE["NEWELIXIR_"..string.upper(ELIXIR)] = CHARACTERS.WATHGRITHR.DESCRIBE.GHOSTLYELIXIR_SPEED
	CHARACTERS.WEBBER.DESCRIBE["NEWELIXIR_"..string.upper(ELIXIR)] = CHARACTERS.WEBBER.DESCRIBE.GHOSTLYELIXIR_SPEED
	CHARACTERS.WARLY.DESCRIBE["NEWELIXIR_"..string.upper(ELIXIR)] = CHARACTERS.WARLY.DESCRIBE.GHOSTLYELIXIR_SPEED
	CHARACTERS.WORMWOOD.DESCRIBE["NEWELIXIR_"..string.upper(ELIXIR)] = CHARACTERS.WORMWOOD.DESCRIBE.GHOSTLYELIXIR_SPEED
	CHARACTERS.WINONA.DESCRIBE["NEWELIXIR_"..string.upper(ELIXIR)] = CHARACTERS.WINONA.DESCRIBE.GHOSTLYELIXIR_SPEED
	CHARACTERS.WORTOX.DESCRIBE["NEWELIXIR_"..string.upper(ELIXIR)] = CHARACTERS.WORTOX.DESCRIBE.GHOSTLYELIXIR_SPEED
	CHARACTERS.WURT.DESCRIBE["NEWELIXIR_"..string.upper(ELIXIR)] = CHARACTERS.WURT.DESCRIBE.GHOSTLYELIXIR_SPEED
	CHARACTERS.WALTER.DESCRIBE["NEWELIXIR_"..string.upper(ELIXIR)] = CHARACTERS.WALTER.DESCRIBE.GHOSTLYELIXIR_SPEED
end

-- Item names, recipe descriptions, and Wendy inspect dialogue
CHARACTERS.WENDY.ACTIONFAIL.GIVE.WRONG_ELIXIR = "I can't apply it without cleansing her!"
CHARACTERS.WENDY.ACTIONFAIL.GIVE.NO_ELIXIR = "It won't stick!"
CHARACTERS.WENDY.ACTIONFAIL.MOONSACRIFICE = {
	NO_FULLMOON = "There is not enough water yet.",
	NO_NIGHT = "I will have to wait for night."
}

CHARACTERS.WENDY.DESCRIBE.ABIGAIL.NIGHTMARE = "A-...Abigail...?"

STRINGS.NAMES.GRAVESTONE_STRUCTURE = "Headstone"
STRINGS.RECIPE_DESC.GRAVESTONE_STRUCTURE = "Revenant relocation."
CHARACTERS.WENDY.DESCRIBE.GRAVESTONE_STRUCTURE = "Asylum for a lost soul."

STRINGS.NAMES.MOUND_STRUCTURE = "Grave"
CHARACTERS.WENDY.DESCRIBE.MOUND_STRUCTURE = {
	GENERIC = "Now we can help another.",
	DUG = "An offering may attract a lost soul."
}

STRINGS.NAMES.BANDAGE_GHOST = "Spiritual Liniment"
STRINGS.RECIPE_DESC.BANDAGE_GHOST = "For mind and soul."
CHARACTERS.WENDY.DESCRIBE.BANDAGE_GHOST = "This will be good for both of us."

STRINGS.NAMES.NEWELIXIR_SANITYAURA = "Floral Incense"
STRINGS.RECIPE_DESC.NEWELIXIR_SANITYAURA = "Spirit-scents."
CHARACTERS.WENDY.DESCRIBE.NEWELIXIR_SANITYAURA = "It smells of hyacinth and lily."

STRINGS.NAMES.NEWELIXIR_LIGHTAURA = "Radiant Remedy"
STRINGS.RECIPE_DESC.NEWELIXIR_LIGHTAURA = "A brilliant blazing brew."
CHARACTERS.WENDY.DESCRIBE.NEWELIXIR_LIGHTAURA = "Abigail would love this one."

STRINGS.NAMES.NEWELIXIR_HEALTHDAMAGE = "Sanguine Solution"
STRINGS.RECIPE_DESC.NEWELIXIR_HEALTHDAMAGE = "Harness the power of your grevious wounds."
CHARACTERS.WENDY.DESCRIBE.NEWELIXIR_HEALTHDAMAGE = "The closer we get, the stronger we become."

STRINGS.NAMES.NEWELIXIR_CLEANSE = "Purifying Balm"
STRINGS.RECIPE_DESC.NEWELIXIR_CLEANSE = "Cleanse your sister's soul."
CHARACTERS.WENDY.DESCRIBE.NEWELIXIR_CLEANSE = "This will help you stay calm."

STRINGS.NAMES.NEWELIXIR_INSANITYDAMAGE = "Nightmare Serum"
STRINGS.RECIPE_DESC.NEWELIXIR_INSANITYDAMAGE = "Harness the power of your bad dreams."
CHARACTERS.WENDY.DESCRIBE.NEWELIXIR_INSANITYDAMAGE = "Oh, but it wasn't a dream."

STRINGS.NAMES.NEWELIXIR_SHADOWFIGHTER = "Tenebrous Tincture"
STRINGS.RECIPE_DESC.NEWELIXIR_SHADOWFIGHTER = "Cloak your spirit in the shadows."
CHARACTERS.WENDY.DESCRIBE.NEWELIXIR_SHADOWFIGHTER = "This will help you see them too."

STRINGS.NAMES.NEWELIXIR_LIGHTNING = "Distilled Wrath"
STRINGS.RECIPE_DESC.NEWELIXIR_LIGHTNING = "Smite with the fury of the dead."
CHARACTERS.WENDY.DESCRIBE.NEWELIXIR_LIGHTNING = "It tingles."

--STRINGS.NAMES.NEWELIXIR_FREEZE = "Frigor Mortis"
--STRINGS.RECIPE_DESC.NEWELIXIR_FREEZE = "Wield the chill of death."
--CHARACTERS.WENDY.DESCRIBE.NEWELIXIR_FREEZE = "I know you can't feel the cold."

--STRINGS.NAMES.NEWELIXIR_ = "item_name"
--STRINGS.RECIPE_DESC.NEWELIXIR_ = "recipe_description"
--CHARACTERS.WENDY.DESCRIBE.NEWELIXIR_ = "inspect_dialogue"
