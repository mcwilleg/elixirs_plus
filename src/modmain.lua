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

local STRINGS = GLOBAL.STRINGS
local CHARACTERS = GLOBAL.STRINGS.CHARACTERS
local Ingredient = GLOBAL.Ingredient
local RECIPETABS = GLOBAL.RECIPETABS
local CUSTOM_RECIPETABS = GLOBAL.CUSTOM_RECIPETABS
local TECH = GLOBAL.TECH

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

local sacrifices = {
	bee = { flowers = 2, sound = "dontstarve/bee/bee_death" },
	killerbee = { flowers = 2, sound = "dontstarve/bee/killerbee_death" },
	butterfly = { flowers = 1 },
	crow = { flowers = 2 },
	robin = { flowers = 2 },
	robin_winter = { flowers = 2 },
	canary = { flowers = 2 },
	puffin = { flowers = 2 },
	fireflies = { flowers = 3 },
	lureplantbulb = { flowers = 4, sound = "dontstarve/creatures/eyeplant/vine_retract" },
	mosquito = { flowers = 2, sound = "dontstarve/creatures/mosquito/mosquito_death" },
	rabbit = { flowers = 1 },
	mole = { flowers = 2 },
	carrat = { flowers = 2 },
	moonbutterfly = { flowers = 3 },
}

AddAction("MOONSACRIFICE", "Sacrifice", function(act)
	if act.invobject ~= nil and act.doer.components.inventory ~= nil and act.target ~= nil then
		local animal = act.doer.components.inventory:RemoveItem(act.invobject)
		local reason
		if animal ~= nil then
			local sacrifice_value = sacrifices[animal.prefab].flowers or 0
			local old_total = act.target.pending_ghostflowers or 0
			if GLOBAL.TheWorld.state.moonphase ~= "full" then
				reason = "NO_FULLMOON"
			elseif GLOBAL.TheWorld.state.phase ~= "night" then
				reason = "NO_NIGHT"
			elseif old_total >= TUNING.ELIXIRS_PLUS.MAX_SACRIFICE then
				reason = "MOONDIAL_FULL"
			else
				act.target.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/medium")
				local murdersound = sacrifices[animal.prefab].sound or (animal.components.health ~= nil and animal.components.health.murdersound or nil)
				if murdersound ~= nil then
					act.target.SoundEmitter:PlaySound(GLOBAL.FunctionOrValue(murdersound, animal, act.doer))
				end
				act.target:PushEvent("onmoonsacrifice", { sacrifice_value = sacrifice_value })
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

AddComponentAction("USEITEM", "inventoryitem", function(inst, doer, target, actions, _)
	if doer:HasTag("elixirbrewer") and target.prefab == "moondial" and sacrifices[inst.prefab] ~= nil and not target:HasTag("NOCLICK") then
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
	inst:WatchWorldState("isday", function(moondial, isday)
		if not isday then return end
		local flowers = moondial.pending_ghostflowers or 0
		if flowers > 0 then
			for k = 1, flowers do
				moondial:DoTaskInTime(k * 0.1 + 3, function(lootdropper)
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
						lootdropper.SoundEmitter:PlaySound("dontstarve/common/deathpoof")
					end
				end)
			end
			moondial.SoundEmitter:KillSound("idlesound")
			moondial.pending_ghostflowers = 0
		end
	end)

	inst.pending_ghostflowers = 0
	inst:ListenForEvent("onmoonsacrifice", function(moondial, data)
		moondial.pending_ghostflowers = math.min(moondial.pending_ghostflowers + data.sacrifice_value, TUNING.ELIXIRS_PLUS.MAX_SACRIFICE)
		local pt = moondial:GetPosition()
		pt.y = 2
		local fx = GLOBAL.SpawnPrefab("splash")
		fx.Transform:SetPosition(pt:Get())
		if moondial.pending_ghostflowers >= TUNING.ELIXIRS_PLUS.MAX_SACRIFICE and not moondial.SoundEmitter:PlayingSound("idlesound") then
			moondial.SoundEmitter:PlaySound("dontstarve/common/together/celestial_orb/active")
			moondial.SoundEmitter:PlaySound("dontstarve/common/together/celestial_orb/idle_LP", "idlesound")
			moondial.Light:SetRadius(7.0)
		end
	end)

	if inst.components.inspectable ~= nil then
		local OldGetStatus = inst.components.inspectable.getstatus
		inst.components.inspectable.getstatus = function(moondial, viewer)
			if viewer.prefab == "wendy" and moondial.pending_ghostflowers >= TUNING.ELIXIRS_PLUS.MAX_SACRIFICE then
				return "RITUAL_COMPLETE"
			else
				return OldGetStatus(moondial, viewer)
			end
		end
	end
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
	--"freeze",
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
			abigail:AddComponent("sanityaura")
			abigail.components.sanityaura.aura = -TUNING.SANITYAURA_LARGE
			if abigail._playerlink ~= nil then
				abigail._playerlink.components.sanity:RemoveSanityAuraImmunity("ghost")
			end
		else
			abigail.AnimState:SetBuild("ghost_abigail_build")
			abigail:RemoveComponent("sanityaura")
			if abigail._playerlink ~= nil then
				abigail._playerlink.components.sanity:AddSanityAuraImmunity("ghost")
			end
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
	inst:ListenForEvent("death", function(abigail)
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
			abigail.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/shield")
		end
	end)
end)

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

--AddRecipe("newelixir_freeze", {
	--Ingredient("bluegem", 1),
	--Ingredient("nightmarefuel", 5),
	--Ingredient("ghostflower", 3)
--}, CUSTOM_RECIPETABS.ELIXIRBREWING, TECH.NONE, nil, nil, nil, nil, "elixirbrewer",
--"images/inventoryimages/newelixir_freeze.xml",
--"newelixir_freeze.tex")

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
	NO_FULLMOON = "I will have to wait for a full moon.",
	NO_NIGHT = "I will have to wait for night.",
	MOONDIAL_FULL = "It appears to be satisfied."
}

CHARACTERS.WENDY.DESCRIBE.ABIGAIL.NIGHTMARE = "A-...Abigail...?"
CHARACTERS.WENDY.DESCRIBE.MOONDIAL.RITUAL_COMPLETE = "It's humming..."

STRINGS.NAMES.GRAVESTONE_STRUCTURE = "Headstone"
STRINGS.RECIPE_DESC.GRAVESTONE_STRUCTURE = "Revenant relocation."
CHARACTERS.WENDY.DESCRIBE.GRAVESTONE_STRUCTURE = "Asylum for a lost soul."

STRINGS.NAMES.MOUND_STRUCTURE = "Grave"
CHARACTERS.WENDY.DESCRIBE.MOUND_STRUCTURE = {
	GENERIC = "Now we can help.",
	DUG = "All it needs is an offering."
}

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
