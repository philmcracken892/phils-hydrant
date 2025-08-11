local RSGCore = exports['rsg-core']:GetCoreObject()


local Config = {
    items = {
        ['hydrant'] = {
            label = 'Hydrant'
        },
        ['explosivesbox'] = {
            label = 'Explosives Box'
        }
    }
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

-- Useable item: Hydrant
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

-- Useable item: Explosives Box
RSGCore.Functions.CreateUseableItem("explosivesbox", function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local hasItem = Player.Functions.GetItemByName('explosivesbox')
    if not hasItem or hasItem.amount < 1 then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Error',
            description = 'You don\'t have this item',
            type = 'error'
        })
        return
    end
    
    local removed = Player.Functions.RemoveItem('explosivesbox', 1)
    if removed then
        TriggerClientEvent('floor-items:client:placeItem', source, 'explosivesbox')
    else
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Error',
            description = 'Failed to remove item',
            type = 'error'
        })
    end
end)
