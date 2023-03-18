local Ingredient = GLOBAL.Ingredient
local RECIPETABS = GLOBAL.RECIPETABS
local CUSTOM_RECIPETABS = GLOBAL.CUSTOM_RECIPETABS
local Recipes = GLOBAL.AllRecipes
local TECH = GLOBAL.TECH

-- add recipes for new elixirs
AddRecipe("newelixir_sanityaura", {
    Ingredient("petals", 1),
    Ingredient("ghostflower", 1)
}, CUSTOM_RECIPETABS.ELIXIRBREWING, TECH.NONE, nil, nil, nil, nil, "elixirbrewer",
        "images/inventoryimages/newelixir_sanityaura.xml",
        "newelixir_sanityaura.tex")

AddRecipe("newelixir_lightaura", {
    Ingredient("redgem", 1),
    Ingredient("ghostflower", 2)
}, CUSTOM_RECIPETABS.ELIXIRBREWING, TECH.NONE, nil, nil, nil, nil, "elixirbrewer",
        "images/inventoryimages/newelixir_lightaura.xml",
        "newelixir_lightaura.tex")

AddRecipe("newelixir_healthdamage", {
    Ingredient("mosquitosack", 2),
    Ingredient(GLOBAL.CHARACTER_INGREDIENT.HEALTH, 30),
    Ingredient("ghostflower", 3)
}, CUSTOM_RECIPETABS.ELIXIRBREWING, TECH.NONE, nil, nil, nil, nil, "elixirbrewer",
        "images/inventoryimages/newelixir_healthdamage.xml",
        "newelixir_healthdamage.tex")

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

local recipe_gravestone_structure = AddRecipe("gravestone_structure", {
    Ingredient("marble", 6),
    Ingredient("boneshard", 3),
    Ingredient("shovel", 1)
}, RECIPETABS.TOWN, TECH.NONE, "gravestone_structure_placer", nil, nil, nil, "elixirbrewer",
        "images/inventoryimages/gravestone_structure.xml",
        "gravestone_structure.tex")

-- recipe sorting
recipe_gravestone_structure.sortkey = Recipes.sisturn.sortkey + 0.1