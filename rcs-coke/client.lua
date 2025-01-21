local QBCore = exports['qb-core']:GetCoreObject()
local plantedPlants = {}

-- Planting seeds
RegisterNetEvent('qb-cocaine:client:plantSeed', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    if not IsOnGrass(coords) then
        QBCore.Functions.Notify("You can only plant seeds on grass!", "error")
        return
    end

    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_GARDENER_PLANT", 0, true)
    QBCore.Functions.Progressbar("plant_seed", "Planting Seed...", 5000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Success
        ClearPedTasks(ped)
        TriggerServerEvent('qb-cocaine:server:plantSeed', coords)
    end, function() -- Cancel
        ClearPedTasks(ped)
        QBCore.Functions.Notify("Planting canceled", "error")
    end)
end)

-- Spawn plant
RegisterNetEvent('qb-cocaine:client:spawnPlant', function(plantId, plantData)
    local model = GetPlantModelByStage(plantData.growthStage)
    RequestModel(model)

    while not HasModelLoaded(model) do
        Wait(100)
    end

    local plant = CreateObject(model, plantData.coords.x, plantData.coords.y, plantData.coords.z - 1.0, false, false, false)
    FreezeEntityPosition(plant, true)
    SetEntityAsMissionEntity(plant, true, true)
    plantedPlants[plantId] = { entity = plant, stage = plantData.growthStage }

    -- Add qb-target interaction with a menu
    exports['qb-target']:AddTargetEntity(plant, {
        options = {
            {
                label = "Plant Options",
                icon = "fas fa-seedling",
                action = function()
                    OpenPlantMenu(plantId)
                end,
            }
        },
        distance = 2.0
    })
end)

-- Update plant growth stage
RegisterNetEvent('qb-cocaine:client:updatePlant', function(plantId, newGrowthStage)
    local plant = plantedPlants[plantId]
    if plant then
        local coords = GetEntityCoords(plant.entity)
        DeleteObject(plant.entity)

        -- Update the plant's growth stage to the new one
        plant.growthStage = newGrowthStage  -- Make sure the 'growthStage' variable is used here

        -- Get the new model based on the new growth stage
        local model = GetPlantModelByStage(newGrowthStage)
        RequestModel(model)

        -- Wait until the model is loaded
        while not HasModelLoaded(model) do
            Wait(100)
        end

        -- Create the new plant object
        local newPlant = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
        FreezeEntityPosition(newPlant, true)
        plantedPlants[plantId] = { entity = newPlant, stage = newGrowthStage }

        -- Reapply qb-target interaction to the new plant object
        exports['qb-target']:AddTargetEntity(newPlant, {
            options = {
                {
                    label = "Plant Options",
                    icon = "fas fa-seedling",
                    action = function()
                        OpenPlantMenu(plantId)
                    end,
                }
            },
            distance = 2.0
        })

        -- Update the plant stats in the menu for the new growth stage
        TriggerClientEvent('qb-cocaine:client:updatePlantStats', -1, plantId, newGrowthStage)
    end
end)

RegisterNetEvent('qb-cocaine:client:fertilizePlant', function(plantId)
    local ped = PlayerPedId()

    -- Request the black jerry can model
    local jerryCanModel = `w_am_jerrycan_sf`
    RequestModel(jerryCanModel)

    local particleDict = "core"
    local particleName = "water_splash_obj_in"  -- Use the correct particle name

    -- Request particle asset
    RequestNamedPtfxAsset(particleDict)
    while not HasNamedPtfxAssetLoaded(particleDict) do
        Wait(100)
    end

    -- Request the jerry can model and wait for it to load
    while not HasModelLoaded(jerryCanModel) do
        Wait(100)
    end

    -- Create the jerry can prop
    local jerryCan = CreateObject(jerryCanModel, 0, 0, 0, true, true, true)

    -- Attach the jerry can to the player’s hand
    AttachEntityToEntity(jerryCan, ped, GetPedBoneIndex(ped, 57005), 
        0.05, 0.0, -0.28,  -- Adjusted position offsets for proper hand alignment
        -136.0, 58.0, -46.0,  -- Adjusted rotation for proper grip alignment
        true, true, false, false, 1, true
    )
        
	CreateThread(function()
       Wait(0)
    -- Ensure the particle effect is attached to the jerry can
    	UseParticleFxAssetNextCall(particleDict)
    	local particleFx = StartParticleFxLoopedOnEntity(particleName, jerryCan, 0.16, 0.0, 0.23, 2.0, 90.0, 9.0, 1.0, false, false, false)
   	 end)
    -- Load the animation dictionary
    RequestAnimDict("weapons@first_person@aim_rng@generic@misc@jerrycan")
    while not HasAnimDictLoaded("weapons@first_person@aim_rng@generic@misc@jerrycan") do
        Wait(100)
    end

    -- Play the fertilizing animation
    TaskPlayAnim(ped, "weapons@first_person@aim_rng@generic@misc@jerrycan", "fire_intro_high", 1.0, -1.0, -1, 50, 0, false, false, false)

    -- Show the progress bar during fertilization
    QBCore.Functions.Progressbar("fertilize_plant", "Fertilizing Plant...", 5000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Success
        ClearPedTasks(ped)

        -- Stop the particle effect and remove the jerry can prop
        --StopParticleFxLooped(particleFx, false)
        DetachEntity(jerryCan, true, false)
        DeleteObject(jerryCan)

        -- Trigger the fertilizing server event
        TriggerServerEvent('qb-cocaine:server:fertilizePlant', plantId)
    end, function() -- Cancel
        ClearPedTasks(ped)

        -- Stop the particle effect if the action is canceled
        --StopParticleFxLooped(particleFx, false)

        -- Remove the jerry can prop
        DetachEntity(jerryCan, true, false)
        DeleteObject(jerryCan)

        QBCore.Functions.Notify("Fertilizing canceled", "error")
    end)
end)


-- Update plant growth stage
RegisterNetEvent('qb-cocaine:client:updatePlantGrowth', function(plantId, newGrowthStage)
    local plant = plantedPlants[plantId]
    if plant then
        plant.growthStage = newGrowthStage  -- Make sure to set this correctly

        -- Debugging log to verify the growth stage
        print("Updated growth stage for plant " .. plantId .. ": " .. newGrowthStage)

        local coords = GetEntityCoords(plant.entity)
        DeleteObject(plant.entity)

        -- Get the new model based on the new growth stage
        local model = GetPlantModelByStage(newGrowthStage)
        RequestModel(model)

        -- Wait until the model is loaded
        while not HasModelLoaded(model) do
            Wait(100)
        end

        -- Create the new plant object
        local newPlant = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
        FreezeEntityPosition(newPlant, true)
        plantedPlants[plantId] = { entity = newPlant, stage = newGrowthStage }

        -- Reapply qb-target interaction to the new plant object
        exports['qb-target']:AddTargetEntity(newPlant, {
            options = {
                {
                    label = "Plant Options",
                    icon = "fas fa-seedling",
                    action = function()
                        OpenPlantMenu(plantId)
                    end,
                }
            },
            distance = 2.0
        })

        -- Update the plant stats in the menu for the new growth stage
        TriggerClientEvent('qb-cocaine:client:updatePlantStats', -1, plantId, newGrowthStage)
    end
end)



-- Remove plant
RegisterNetEvent('qb-cocaine:client:removePlant', function(plantId)
    local plant = plantedPlants[plantId]
    if plant then
        DeleteObject(plant.entity)
        plantedPlants[plantId] = nil
    end
end)

function OpenPlantMenu(plantId)
    local plant = plantedPlants[plantId]
    if not plant then return end

    -- Retrieve growth stage and fertilizer level
    local growthStage = plant.stage or "Unknown"  -- Ensure it is correctly initialized
    local fertilizerLevel = plant.fertilizerLevel or 0

    -- Check if the plant is fully grown (stage 3)
    local menuOptions = {
        {
            header = "Plant Options",
            isMenuHeader = true
        },
        {
            header = "Growth Stage",
            txt = "Current Growth Stage: " .. tostring(growthStage),
            isHeader = true
        },
        {
            header = "Fertilizer Level",
            txt = "Current Fertilizer Level: " .. tostring(fertilizerLevel) .. "%",
            isHeader = true
        },
        {
            header = "Fertilize Plant",
            txt = "Apply fertilizer to help the plant grow.",
            params = {
                event = "qb-cocaine:client:fertilizePlant",  -- Ensure this event matches
                args = plantId  -- Directly pass the plant ID
            }
        }
    }

    -- Add the Harvest option if the plant is fully grown (stage 3)
    if growthStage == 3 then
        table.insert(menuOptions, {
            header = "Harvest Plant",
            txt = "Harvest the fully grown plant.",
            params = {
                event = "qb-cocaine:client:harvestPlant",  -- Event to harvest the plant
                args = plantId
            }
        })
    end

    -- Add Close Menu option
    table.insert(menuOptions, {
        header = "Close Menu",
        params = {
            event = "qb-menu:closeMenu"
        }
    })

    -- Open the menu
    exports['qb-menu']:openMenu(menuOptions)
end



-- Check plant stats
RegisterNetEvent('qb-cocaine:client:checkPlant', function(data)
    local plantId = data.plantId
    TriggerServerEvent('qb-cocaine:server:getPlantStats', plantId)
end)


-- Check plant stats
-- Display plant stats when checking the plant
RegisterNetEvent('qb-cocaine:client:displayPlantStats', function(plantId, growthStage, fertilizerLevel)
    local elements = {
        { label = "Growth Stage: " .. growthStage, value = "growth_stage" },
        { label = "Fertilizer Level: " .. fertilizerLevel, value = "fertilizer_level" }
    }

    -- Add fertilize option
    table.insert(elements, {
        label = "Fertilize Plant",
        value = "fertilize_plant"
    })

    -- Open the menu with stats and fertilize option
    exports['qb-menu']:openMenu(elements, function(data, menu)
        if data.value == "fertilize_plant" then
            TriggerServerEvent('qb-cocaine:server:fertilizePlant', plantId)
        end
        menu.close()
    end)
end)


-- Harvest plant (fully grown)
RegisterNetEvent('qb-cocaine:client:harvestPlant', function(plantId)
    local ped = PlayerPedId()

    -- Start harvest animation
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_GARDENER_PLANT", 0, true)

    -- Show progress bar for harvesting
    QBCore.Functions.Progressbar("harvest_plant", "Harvesting Plant...", 5000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Success
        -- Clear animation
        ClearPedTasks(ped)

        -- Remove the plant object
        local plant = plantedPlants[plantId]
        if plant then
            DeleteObject(plant.entity)
            plantedPlants[plantId] = nil
        end

        -- Get the player's server ID (not citizenid)
        local playerPed = PlayerPedId()
        local playerId = GetPlayerServerId(PlayerId())
		
        print(GetPlayerServerId(PlayerId()))        
        -- Add cocaine leaves to inventory
        TriggerServerEvent('qb-cocaine:server:addCocaineLeaves', playerId)  -- Pass the server ID here
        QBCore.Functions.Notify("You have harvested the plant and received cocaine leaves!", "success")
    end, function() -- Cancel
        ClearPedTasks(ped)
        QBCore.Functions.Notify("Harvesting canceled", "error")
    end)
end)

-- Helper Functions
function GetPlantModelByStage(stage)
    if stage == 1 then return `prop_plant_fern_02a` end
    if stage == 2 then return `prop_plant_fern_02b` end
    if stage == 3 then return `prop_plant_01a` end
end

function IsOnGrass(coords)
    local ground, z = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z)
    if ground then
        -- Check the surface type using a raycast
        local rayHandle = StartShapeTestRay(coords.x, coords.y, coords.z + 10.0, coords.x, coords.y, coords.z - 10.0, 1, PlayerPedId(), 0)
        local _, hit, _, _, material = GetShapeTestResult(rayHandle)
        
        -- Print material for debugging
        print("Material: " .. material)
        
        -- Check if material is a grass-like surface (using material types or hashes)
        local grassMaterials = {
            [887810] = true, -- grass
            [241410] = true, -- grass path
            -- Additional material hashes can be added here if necessary
        }

        -- Return true if the material is a grass material
        return grassMaterials[material] ~= nil
    end
    return false
end