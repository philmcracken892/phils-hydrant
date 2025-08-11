local RSGCore = exports['rsg-core']:GetCoreObject()
local placedItems = {}
local isPlacingItem = false
local trackedVehicles = {}

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
                offset = vector3(0.0, 0.0, 0.2),
                duration = 5000,
                interval = 500,
                radius = 25.0
            },
            label = 'Hydrant',
            interactDistance = 5.0
        },
        ['explosivesbox'] = {
            prop = 'mp001_p_mp_cratetnt03x',
            animation = {
                dict = 'SCRIPT_RE@GOLD_PANNER@GOLD_SUCCESS',
                clip = 'SEARCH01'
            },
            explosion = {
                id = 0, -- EXP_TAG_GRENADE
                offset = vector3(0.0, 0.0, 0.5),
                duration = 1000,
                interval = 500,
                timer = 15000,
                radius = 25.0
            },
            label = 'Explosives Box',
            interactDistance = 5.0
        },
    },
    vehicles = {
        ['cart05'] = {
            model = 'cart05',
            hash = GetHashKey('cart05'),
            label = 'Fire Cart',
            interactDistance = 3.0,
            waterEffect = {
                id = 10,
                offset = vector3(0.0, 0.0, 0.2),
                duration = 8000,
                interval = 500,
                radius = 25.0
            }
        }
    },
    crouchAnimationDuration = 1000
}


local function SpawnProp(propName, coords)
    local propHash = GetHashKey(propName)
    RequestModel(propHash)
    while not HasModelLoaded(propHash) do
        Wait(1)
    end
    local prop = CreateObject(propHash, coords.x, coords.y, coords.z, true, true, false)
    if prop then
       
        PlaceObjectOnGroundProperly(prop)
        FreezeEntityPosition(prop, true)
        return prop
    else
        
        return nil
    end
end


local function SetupItemInteractions(prop, itemData)
    if not DoesEntityExist(prop) then
      
        return
    end
    if not exports['ox_target'] then
       
        return
    end
    local itemConfig = Config.items[itemData.itemType]
    local useIcon = itemData.itemType == 'explosivesbox' and 'fas fa-bomb' or 'fas fa-hand-holding-water'
    local useLabel = itemData.itemType == 'explosivesbox' and 'Detonate ' or 'Use '
    local targetName = string.format('use_%s_%s_%s', itemData.itemType, itemData.id, tostring(prop))
   
    exports['ox_target']:addLocalEntity(prop, {
        {
            name = targetName,
            icon = useIcon,
            label = useLabel .. itemConfig.label,
            onSelect = function() UseFloorItemWithAnimation(itemData) end,
            distance = itemConfig.interactDistance
        },
        {
            name = string.format('pickup_%s_%s_%s', itemData.itemType, itemData.id, tostring(prop)),
            icon = 'fas fa-hand-paper',
            label = 'Pick Up ' .. itemConfig.label,
            onSelect = function() PickUpItem(itemData) end,
            distance = itemConfig.interactDistance
        }
    })
   
end


local function PlaceItemOnGround(itemName)
    if not Config.items[itemName] then 
        print('Invalid item: ' .. itemName)
        return 
    end
    if isPlacingItem then 
        print('Already placing an item')
        return 
    end
    isPlacingItem = true

    local ped = PlayerPedId()
    lib.notify({title = 'Placing Item', description = 'Placing ' .. Config.items[itemName].label .. '...', type = 'inform'})
    Wait(Config.crouchAnimationDuration)
    ClearPedTasks(ped)

    local coords = GetEntityCoords(ped)
    local forwardVector = GetEntityForwardVector(ped)
    local placeCoords = coords + forwardVector * 1.5
    local prop = SpawnProp(Config.items[itemName].prop, placeCoords)

    if prop then
        local itemData = {
            prop = prop,
            itemType = itemName,
            coords = placeCoords,
            id = #placedItems + 1
        }
        table.insert(placedItems, itemData)
       
        SetupItemInteractions(prop, itemData)
        lib.notify({title = 'Item Placed', description = 'You placed a ' .. Config.items[itemName].label, type = 'success'})
    else
        lib.notify({title = 'Error', description = 'Failed to place ' .. Config.items[itemName].label, type = 'error'})
    end
    isPlacingItem = false
end


local function ExtinguishFiresInRange(x, y, z, radius)
    local numFires = Citizen.InvokeNative(0xF9617BC6FAE61E08, x, y, z, radius) or 0
    Citizen.InvokeNative(0xDB38F247BD421708, x, y, z, radius) -- STOP_FIRE_IN_RANGE
    
    local nearbyPeds = GetNearbyPeds(vector3(x, y, z), radius, 10)
    for _, ped in ipairs(nearbyPeds) do
        if DoesEntityExist(ped) and IsEntityOnFire(ped) then -- Changed from IsPedOnFire to IsEntityOnFire
            Citizen.InvokeNative(0x8390751DC40C1E98, ped) -- STOP_ENTITY_FIRE
        end
    end
    
    local nearbyVehicles = GetNearbyVehicles(vector3(x, y, z), radius, 5)
    for _, veh in ipairs(nearbyVehicles) do
        if DoesEntityExist(veh) and IsEntityOnFire(veh) then
            Citizen.InvokeNative(0x8390751DC40C1E98, veh) -- STOP_ENTITY_FIRE
        end
    end
end


function GetNearbyPeds(coords, radius, maxPeds)
    local peds = {}
    local handle, ped = FindFirstPed()
    local success = true
    
    repeat
        if DoesEntityExist(ped) and ped ~= PlayerPedId() then
            local pedCoords = GetEntityCoords(ped)
            if #(pedCoords - coords) <= radius then 
                table.insert(peds, ped) 
            end
        end
        success, ped = FindNextPed(handle)
    until not success or #peds >= maxPeds
    
    EndFindPed(handle)
    return peds
end

function GetNearbyVehicles(coords, radius, maxVehicles)
    local vehicles = {}
    local handle, veh = FindFirstVehicle()
    local success = true
    
    repeat
        if DoesEntityExist(veh) then
            local vehCoords = GetEntityCoords(veh)
            if #(vehCoords - coords) <= radius then
                table.insert(vehicles, veh)
            end
        end
        success, veh = FindNextVehicle(handle)
    until not success or #vehicles >= maxVehicles
    
    EndFindVehicle(handle)
    return vehicles
end


local function TriggerVehicleWaterSpray(vehicle, waterConfig)
    if not DoesEntityExist(vehicle) then return end
    
    local sprayCoords = GetOffsetFromEntityInWorldCoords(vehicle, waterConfig.offset.x, waterConfig.offset.y, waterConfig.offset.z)
    local startTime = GetGameTimer()

    Citizen.CreateThread(function()
        while GetGameTimer() - startTime < waterConfig.duration do
            if DoesEntityExist(vehicle) then
                sprayCoords = GetOffsetFromEntityInWorldCoords(vehicle, waterConfig.offset.x, waterConfig.offset.y, waterConfig.offset.z)
                AddExplosion(sprayCoords.x, sprayCoords.y, sprayCoords.z, waterConfig.id, 1.5, true, false, 0.0)
                ExtinguishFiresInRange(sprayCoords.x, sprayCoords.y, sprayCoords.z, waterConfig.radius)
            else 
                break 
            end
            Wait(waterConfig.interval)
        end
        lib.notify({title = 'Fire Cart', description = 'Water spray system deactivated', type = 'inform'})
    end)
end


function UseFireCart(vehicle)
    if not DoesEntityExist(vehicle) then 
        lib.notify({title = 'Error', description = 'Vehicle no longer exists', type = 'error'})
        return 
    end
    
    local ped = PlayerPedId()
    RequestAnimDict('script_re@gold_panner@gold_success')
    while not HasAnimDictLoaded('script_re@gold_panner@gold_success') do
        Wait(0)
    end
    
    TaskPlayAnim(ped, 'script_re@gold_panner@gold_success', 'search01', 8.0, -8.0, Config.vehicles['cart05'].waterEffect.duration, 1, 0, false, false, false)
    lib.notify({title = 'Fire Cart Activated', description = 'Water spray system engaged!', type = 'success'})
    
    Citizen.SetTimeout(1500, function()
        TriggerVehicleWaterSpray(vehicle, Config.vehicles['cart05'].waterEffect)
    end)
end


local function AddVehicleTarget(vehicle)
    if not DoesEntityExist(vehicle) then return end
    if trackedVehicles[vehicle] then return end
    
    local vehicleConfig = Config.vehicles['cart05']
    local targetName = string.format('use_fire_cart_%s', VehToNet(vehicle))
    
    exports['ox_target']:addLocalEntity(vehicle, {
        {
            name = targetName,
            icon = 'fas fa-fire-extinguisher',
            label = 'Use ' .. vehicleConfig.label,
            onSelect = function() UseFireCart(vehicle) end,
            distance = vehicleConfig.interactDistance
        }
    })
    
   
    trackedVehicles[vehicle] = true
end


local function AddVehicleFireSuppression()
    Citizen.CreateThread(function()
        local cart05Hash = Config.vehicles['cart05'].hash
        
        while true do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local vehicles = GetNearbyVehicles(playerCoords, 50.0, 20)
            
            for _, vehicle in ipairs(vehicles) do
                if DoesEntityExist(vehicle) and not trackedVehicles[vehicle] then
                    local modelHash = GetEntityModel(vehicle)
                    
                    if modelHash == cart05Hash then
                        AddVehicleTarget(vehicle)
                    end
                end
            end
            
            for veh, _ in pairs(trackedVehicles) do
                if not DoesEntityExist(veh) then 
                    trackedVehicles[veh] = nil 
                    
                end
            end
            
            Wait(1000)
        end
    end)
end


local function CheckForNearbyFireCarts()
    Citizen.CreateThread(function()
        local cart05Hash = Config.vehicles['cart05'].hash
        
        while true do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            local closestVehicle = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, 15.0, 0, 71)
            
            if DoesEntityExist(closestVehicle) and not trackedVehicles[closestVehicle] then
                local modelHash = GetEntityModel(closestVehicle)
                
                if modelHash == cart05Hash then
                    AddVehicleTarget(closestVehicle)
                    
                end
            end
            
            Wait(500)
        end
    end)
end


function PickUpItem(itemData)
    if DoesEntityExist(itemData.prop) then
        exports['ox_target']:removeLocalEntity(itemData.prop)
        DeleteEntity(itemData.prop)
        
        for i, item in ipairs(placedItems) do
            if item.id == itemData.id then 
                table.remove(placedItems, i) 
                break 
            end
        end
        
        -- Trigger server event to add item to inventory
        TriggerServerEvent('floor-items:server:pickupItem', itemData.itemType)
    end
end


function UseFloorItemWithAnimation(itemData)
    local ped = PlayerPedId()
    local animConfig = Config.items[itemData.itemType].animation
    
    RequestAnimDict(animConfig.dict)
    while not HasAnimDictLoaded(animConfig.dict) do
        Wait(0)
    end
    
    TaskPlayAnim(ped, animConfig.dict, animConfig.clip, 8.0, -8.0, 5000, 1, 0, false, false, false)
    lib.notify({title = 'Using ' .. Config.items[itemData.itemType].label, description = 'Activating...', type = 'inform'})
    
    Citizen.SetTimeout(1500, function()
        local ex = Config.items[itemData.itemType].explosion
        local coords = GetEntityCoords(itemData.prop)
        local explosionCoords = vector3(
            coords.x + ex.offset.x, 
            coords.y + ex.offset.y, 
            coords.z + ex.offset.y
        )
        
        if itemData.itemType == 'explosivesbox' then
            lib.notify({title = 'Explosives', description = 'Timer activated! Take cover!', type = 'error'})
            Citizen.SetTimeout(ex.timer or 5000, function()
                AddExplosion(explosionCoords.x, explosionCoords.y, explosionCoords.z, ex.id, 2.0, true, false, 1.0)
                PickUpItem(itemData)
            end)
        else
            AddExplosion(explosionCoords.x, explosionCoords.y, explosionCoords.z, ex.id, 1.5, true, false, 0.0)
            local startTime = GetGameTimer()
            Citizen.CreateThread(function()
                while GetGameTimer() - startTime < ex.duration do
                    if DoesEntityExist(itemData.prop) then
                        AddExplosion(explosionCoords.x, explosionCoords.y, explosionCoords.z, ex.id, 1.5, true, false, 0.0)
                        ExtinguishFiresInRange(explosionCoords.x, explosionCoords.y, explosionCoords.z, ex.radius)
                    else
                        break
                    end
                    Wait(ex.interval)
                end
            end)
        end
    end)
end




RegisterNetEvent('floor-items:client:placeItem', function(itemName)
   
    PlaceItemOnGround(itemName)
end)


Citizen.CreateThread(function()
    Wait(1000)
    AddVehicleFireSuppression()
end)

Citizen.CreateThread(function()
    Wait(2000)
    CheckForNearbyFireCarts()
end)


AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for _, item in ipairs(placedItems) do
            if DoesEntityExist(item.prop) then
                exports['ox_target']:removeLocalEntity(item.prop)
                DeleteEntity(item.prop)
            end
        end
        
        for vehicle, _ in pairs(trackedVehicles) do
            if DoesEntityExist(vehicle) then
                exports['ox_target']:removeLocalEntity(vehicle)
            end
        end
        
        
    end
end)
