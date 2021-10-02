local assets = {
  Asset("ANIM", "anim/bandage_ghost.zip"),
}

local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddNetwork()

  MakeInventoryPhysics(inst)

  inst.AnimState:SetBank("bandage_ghost")
  inst.AnimState:SetBuild("bandage_ghost")
  inst.AnimState:PlayAnimation("idle")

  MakeInventoryFloatable(inst)

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  inst:AddComponent("stackable")
  inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

  inst:AddComponent("inspectable")

  inst:AddComponent("inventoryitem")
  inst.components.inventoryitem.imagename = "bandage_ghost"
  inst.components.inventoryitem.atlasname = "images/inventoryimages/bandage_ghost.xml"

  inst:AddComponent("healer")
  inst.components.healer:SetHealthAmount(0)

  MakeHauntableLaunch(inst)

  return inst
end

return Prefab("bandage_ghost", fn, assets)
