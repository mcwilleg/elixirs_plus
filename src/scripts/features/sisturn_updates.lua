local CONTAINERS = require("containers")

CONTAINERS.params.sisturn.itemtestfn = function(_, item, _)
    return item.prefab == "petals" or item.prefab == "glommerflower"
end
