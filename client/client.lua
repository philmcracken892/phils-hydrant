local RSGCore = exports['rsg-core']:GetCoreObject()
local placedItems = {}
local isPlacingItem = false

-- Configuration
local Config = {
    items = {
        ['hydrant'] = {
            prop = 'p_firehydrantnbx01x',
            animation = {
                dict = 'SCRIPT_RE@GOLD_PANNER@GOLD_SUCCESS',
                clip = 'SEARCH01'
            },
            explosion = {
                id = 10, -- EXP_TAG_DIR_WATER_HYDRANT
                offset = vector3(0.0, 0.0, 0.6), -- spray above prop
                duration = 5000, -- Duration of the effect in milliseconds
                interval = 200 -- Interval between repeated effect triggers in milliseconds
            },
            label = 'Hydrant',
            interactDistance = 2.0
        },
    },
    useKey = 0x760A9C6F, -- G key
    interactKey = 0xCEFD9220  -- E key
}


local function SpawnProp(propName, coords)
    local propHash = GetHashKey(propName)

    RequestModel(propHash)
    while not HasModelLoaded(propHash) do
        Wait(1)
    end

    local prop = CreateObject(propHash, coords.x, coords.y, coords.z, true, true, false)
    PlaceObjectOnGroundProperly(prop)
    FreezeEntityPosition(prop, true)

    return prop
end


local function PlaceItemOnGround(itemName)
    if not Config.items[itemName] then
        lib.notify({
            title = 'Error',
            description = 'Invalid item type',
            type = 'error'
        })
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local forwardVector = GetEntityForwardVector(ped)

    local placeCoords = vector3(
        coords.x + forwardVector.x * 1.5,
        coords.y + forwardVector.y * 1.5,
        coords.z
    )

    local prop = SpawnProp(Config.items[itemName].prop, placeCoords)

    if prop then
        local itemData = {
            prop = prop,
            itemType = itemName,
            coords = placeCoords,
            id = #placedItems + 1
        }

        table.insert(placedItems, itemData)
        AddOxTargetToProp(prop, itemData)

        lib.notify({
            title = 'Item Placed',
            description = 'You placed a ' .. Config.items[itemName].label .. ' on the ground',
            type = 'success'
        })
    else
        lib.notify({
            title = 'Error',
            description = 'Failed to place item',
            type = 'error'
        })
    end
end

-- Trigger an explosion/effect
local function TriggerExplosion(explosionId, prop, offset, duration, interval)
    local coords
    if prop and DoesEntityExist(prop) then
        coords = GetEntityCoords(prop)
    else
        coords = GetEntityCoords(PlayerPedId())
    end

    if offset then
        coords = vector3(coords.x + offset.x, coords.y + offset.y, coords.z + offset.z)
    end

    print(string.format(
       
        explosionId, coords.x, coords.y, coords.z
    ))

    
    local startTime = GetGameTimer()
    Citizen.CreateThread(function()
        while GetGameTimer() - startTime < duration do
            AddExplosion(coords.x, coords.y, coords.z, explosionId, 1.0, true, false, 0.0)
            Wait(interval)
        end
    end)
end


function AddOxTargetToProp(prop, itemData)
    local itemConfig = Config.items[itemData.itemType]

    exports['ox_target']:addLocalEntity(prop, {
        {
            name = 'use_' .. itemData.itemType .. '_' .. itemData.id,
            icon = 'fas fa-hand-holding-water',
            label = 'Use ' .. itemConfig.label,
            onSelect = function()
                UseFloorItemWithAnimation(itemData)
            end,
            distance = itemConfig.interactDistance
        },
        {
            name = 'pickup_' .. itemData.itemType .. '_' .. itemData.id,
            icon = 'fas fa-hand-paper',
            label = 'Pick Up ' .. itemConfig.label,
            onSelect = function()
                PickUpItem(itemData)
            end,
            distance = itemConfig.interactDistance
        }
    })
end


function UseFloorItemWithAnimation(itemData)
    local ped = PlayerPedId()
    local itemConfig = Config.items[itemData.itemType]

   
    TaskGoToCoordAnyMeans(ped, itemData.coords.x, itemData.coords.y, itemData.coords.z, 1.0, 0, 0, 786603, 0xbf800000)

    local timeout = 0
    while GetDistanceBetweenCoords(GetEntityCoords(ped), itemData.coords, true) > 1.5 and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end

    TaskTurnPedToFaceCoord(ped, itemData.coords.x, itemData.coords.y, itemData.coords.z, 1500)
    Wait(1500)

    RequestAnimDict(itemConfig.animation.dict)
    local animTimeout = 0
    while not HasAnimDictLoaded(itemConfig.animation.dict) and animTimeout < 50 do
        Wait(100)
        animTimeout = animTimeout + 1
    end

    if HasAnimDictLoaded(itemConfig.animation.dict) then
        TaskPlayAnim(ped, itemConfig.animation.dict, itemConfig.animation.clip, 8.0, -8.0, 5000, 1, 0, false, false, false)

        if itemConfig.explosion and DoesEntityExist(itemData.prop) then
            Citizen.SetTimeout(1500, function()
                TriggerExplosion(itemConfig.explosion.id, itemData.prop, itemConfig.explosion.offset, itemConfig.explosion.duration, itemConfig.explosion.interval)
            end)
        else
            lib.notify({
                title = 'Error',
                description = 'No explosion data found',
                type = 'error'
            })
        end

        Wait(5000)
        ClearPedTasks(ped)
    else
        lib.notify({
            title = 'Error',
            description = 'Failed to load animation',
            type = 'error'
        })
    end
end


function PickUpItem(itemData)
    if DoesEntityExist(itemData.prop) then
        exports['ox_target']:removeLocalEntity(itemData.prop)
        TriggerServerEvent('floor-items:server:pickupItem', itemData.itemType)
        DeleteEntity(itemData.prop)

        for i, item in ipairs(placedItems) do
            if item.id == itemData.id then
                table.remove(placedItems, i)
                break
            end
        end
    end
end


RegisterNetEvent('floor-items:client:placeItem', function(itemName)
    PlaceItemOnGround(itemName)
end)



-- Cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for _, item in ipairs(placedItems) do
            if DoesEntityExist(item.prop) then
                exports['ox_target']:removeLocalEntity(item.prop)
                DeleteEntity(item.prop)
            end
        end
    end
end)