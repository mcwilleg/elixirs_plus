local elixirs = require("scripts/libraries/custom_elixirs_params.lua")

local prefabs = {}

local general_params = elixirs.all_elixirs
local nightmare_params = elixirs.all_nightmare_elixirs

local function create_newelixir(prefab, data)
    local params = elixirs[prefab]
    local elixir = params.itemfn and params.itemfn() or general_params.itemfn()
    if params.nightmare then
        elixir = nightmare_params.postitemfn and nightmare_params.postitemfn(elixir) or elixir
    end
    elixir = params.postitemfn and params.postitemfn(elixir) or elixir
    table.insert(prefabs, elixir)
end

local function create_newelixir_buff(prefab, data)
    local params = elixirs[prefab]
    local buff = params.bufffn and params.bufffn() or general_params.bufffn()
    if params.nightmare then
        buff = nightmare_params.postbufffn and nightmare_params.postbufffn(buff) or buff
    end
    buff = params.postbufffn and params.postbufffn(buff) or buff
    table.insert(prefabs, buff)
end

for prefab, data in pairs(elixirs) do
    if string.startswith(prefab, "newelixir_") then
        create_newelixir(prefab, data)
        create_newelixir_buff(prefab, data)
    end
end

return unpack(prefabs)