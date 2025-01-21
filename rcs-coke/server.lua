local QBCore = exports['qb-core']:GetCoreObject()
local plants = {}

-- Handle seed planting
RegisterNetEvent('qb-cocaine:server:plantSeed', function(coords)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    local cokeseedItem = player.Functions.GetItemByName("cocaine_seed") -- Assuming your fertilizer item is named "weed_nutrition"
    if cokeseedItem and cokeseedItem.amount > 0 then
        -- Deduct one fertilizer from the player's inventory
        player.Functions.RemoveItem("cocaine_seed", 1)
            
        local src = source
        local plantId = #plants + 1

        plants[plantId] = {
            owner = src,
            coords = { x = coords.x, y = coords.y, z = coords.z },
            growthStage = 1,
            fertilizerLevel = 100,
            lastUpdated = os.time()
        }

        -- Notify clients to spawn the plant
        TriggerClientEvent('qb-cocaine:client:spawnPlant', -1, plantId, plants[plantId])
        print(("Plant [%d] planted at %.2f, %.2f, %.2f"):format(plantId, coords.x, coords.y, coords.z))
    end
end)

-- Periodic growth management
-- Periodic growth management
CreateThread(function()
    while true do
        Wait(600000) -- Check every 5 minutes for plant growth (to match 30-second growth stage interval)

        for plantId, plant in pairs(plants) do
            local timeElapsed = os.time() - plant.lastUpdated  -- Time elapsed since the last update

            -- If enough time has passed for growth (30 seconds per stage)
            if timeElapsed >= 600 then
                -- Increase growth stage if the time interval has passed
                if plant.growthStage < 3 then  -- Only grow if not fully grown (stage 3)
                    plant.growthStage = plant.growthStage + 1
                    plant.lastUpdated = os.time()  -- Reset the timer for the next growth stage
                    TriggerClientEvent('qb-cocaine:client:updatePlant', -1, plantId, plant.growthStage)  -- Notify all clients of growth change

                    -- Print debug message for growth
                    print(("Plant [%d] has advanced to growth stage %d"):format(plantId, plant.growthStage))
                end
            end
        end
    end
end)

-- Check plant stats
RegisterNetEvent('qb-cocaine:server:checkPlantStats', function(plantId)
    local src = source
    local plant = plants[plantId]

    if plant then
        local timeElapsed = os.time() - plant.lastUpdated
        local timeRemaining = math.max(0, 30 - timeElapsed)  -- Time until the next growth stage

        TriggerClientEvent('QBCore:Notify', src, string.format(
            "Growth Stage: %d\nFertilizer Level: %d%%\nTime Until Next Stage: %ds",
            plant.growthStage, plant.fertilizerLevel, timeRemaining
        ), "primary")
    else
        TriggerClientEvent('QBCore:Notify', src, "This plant no longer exists.", "error")
    end
end)

RegisterNetEvent('qb-cocaine:server:fertilizePlant', function(plantId)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    
    -- Check if the player has fertilizer
    local fertilizerItem = player.Functions.GetItemByName("weed_nutrition") -- Assuming your fertilizer item is named "weed_nutrition"
    if fertilizerItem and fertilizerItem.amount > 0 then
        -- Deduct one fertilizer from the player's inventory
        player.Functions.RemoveItem("weed_nutrition", 1)
        
        -- Update the plant's fertilizer level (or apply it)
        local plant = plants[plantId]
        if plant then
            -- Increase fertilizer level
            plant.fertilizerLevel = math.min(plant.fertilizerLevel + 20, 100) -- Increase fertilizer level, max 100%
            
            -- Notify the player about the fertilization success
            TriggerClientEvent('QBCore:Notify', src, "Plant fertilized successfully!", "success")

            -- Update the client with the new fertilizer level
            TriggerClientEvent('qb-cocaine:client:updatePlantFertilizer', -1, plantId, plant.fertilizerLevel)

            -- Remove the growth stage update here
            -- Do not change growth stage based on fertilizer here
        end
    else
        -- Notify player if they don't have fertilizer
        TriggerClientEvent('QBCore:Notify', src, "You don't have any fertilizer!", "error")
    end
end)

-- Handle getting plant stats
RegisterNetEvent('qb-cocaine:server:getPlantStats', function(plantId)
    local src = source
    local plant = plants[plantId]

    if plant then
        -- Send plant data back to client
        TriggerClientEvent('qb-cocaine:client:displayPlantStats', src, plantId, plant.growthStage, plant.fertilizerLevel)
    else
        TriggerClientEvent('QBCore:Notify', src, "Plant not found!", "error")
    end
end)

-- Periodically decrease fertilizer level over time
CreateThread(function()
    while true do
        Wait(10000) -- 30 seconds (adjust this for how frequently you want the fertilizer to decrease)

        for plantId, plant in pairs(plants) do
            if plant.fertilizerLevel > 0 then
                -- Decrease fertilizer level by 1% per minute (you can adjust this rate)
                plant.fertilizerLevel = math.max(0, plant.fertilizerLevel - 1)

                -- Notify the client about the decrease in fertilizer level
                TriggerClientEvent('qb-cocaine:client:updatePlantFertilizer', -1, plantId, plant.fertilizerLevel)
            end
        end
    end
end)

-- Server-side code to give cocaine leaves when harvested
RegisterNetEvent('qb-cocaine:server:addCocaineLeaves', function(playerId)
    print("Server event triggered: Adding cocaine leaf to player " .. playerId)  -- Debugging line
    local player = QBCore.Functions.GetPlayer(playerId)  -- This should now find the player by server ID
    if player then
           
        local randomAmount = math.random(4, 8)
        -- Add cocaine leaves to the player's inventory
        print("Giving cocaine leaf to player")  -- Debugging line
        player.Functions.AddItem("cocaine_leaf", randomAmount)
        TriggerClientEvent("inventory:client:ItemBox", player, QBCore.Shared.Items["cocaine_leaf"], "add")
    else
        print("Player not found with ID: " .. playerId)  -- If no player is found, print an error
    end
end)






