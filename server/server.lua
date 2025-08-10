local RSGCore = exports['rsg-core']:GetCoreObject()

-- Configuration (should match client)
local Config = {
    items = {
        ['wateringcan'] = {
            prop = 'mp007_p_mp_tonicbox01x',
            animation = {
                dict = 'SCRIPT_RE@GOLD_PANNER@GOLD_SUCCESS',
                clip = 'SEARCH01'
            },
            explosion = {
                tag = 'EXP_TAG_DIR_WATER_HYDRANT', 
                id = 10, -- Explosion ID
                offset = vector3(0.0, 0.0, 0.0) 
            },
            label = 'Water Bucket',
            interactDistance = 2.0
        },
    },
    useKey = 0x760A9C6F,
    interactKey = 0xCEFD9220  
}


RegisterNetEvent('floor-items:server:placeItem', function(itemName)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then 
        
        return 
    end
    
    
    if not Config.items[itemName] then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'Invalid item',
            type = 'error'
        })
        return
    end
    
    
    
   
    local item = Player.Functions.GetItemByName(itemName)
    if not item or item.amount < 1 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'You don\'t have this item',
            type = 'error'
        })
       
        return
    end
    
    
    local removed = Player.Functions.RemoveItem(itemName, 1)
    if removed then
       
        
        TriggerClientEvent('floor-items:client:placeItem', src, itemName)
    else
        
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'Failed to remove item',
            type = 'error'
        })
    end
end)


RegisterNetEvent('floor-items:server:pickupItem', function(itemName)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
   
    local added = Player.Functions.AddItem(itemName, 1)
    if added then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Success',
            description = 'Item added to inventory',
            type = 'success'
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Error',
            description = 'Could not add item to inventory',
            type = 'error'
        })
    end
end)


RSGCore.Functions.CreateUseableItem("hydrant", function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end
    
    
    
    
    local hasItem = Player.Functions.GetItemByName('hydrant')
    if not hasItem or hasItem.amount < 1 then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Error',
            description = 'You don\'t have this item',
            type = 'error'
        })
        return
    end
    
    
    local removed = Player.Functions.RemoveItem('hydrant', 1)
    if removed then
        
        TriggerClientEvent('floor-items:client:placeItem', source, 'hydrant')
    else
       
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Error',
            description = 'Failed to remove item',
            type = 'error'
        })
    end
end)