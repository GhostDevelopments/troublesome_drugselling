local npc = {}
local isCooldown = false
local sellingActive = false
local transactionActive = false
local transactionCancelled = false
local activeMoneyZoneIndex
local next_ped
local queueNextPed

local function isValidMoneyZone(zone)
    return type(zone) == "table"
        and zone.coords
        and type(zone.radius) == "number"
        and type(zone.multiplier) == "number"
        and zone.radius > 0
        and zone.multiplier >= 1.0
end

local function createMoneyZoneBlips()
    for _, zone in ipairs(Config.moneyZones or {}) do
        if isValidMoneyZone(zone) and zone.showBlip ~= false then
            local radiusBlip = AddBlipForRadius(zone.coords.x, zone.coords.y, zone.coords.z, zone.radius)
            SetBlipColour(radiusBlip, Config.moneyZoneBlip.color)
            SetBlipAlpha(radiusBlip, Config.moneyZoneBlip.alpha)
        end
    end
end

local function getActiveMoneyZone(playerCoords)
    local highestZone
    local highestIndex

    for index, zone in ipairs(Config.moneyZones or {}) do
        if isValidMoneyZone(zone) and #(playerCoords - zone.coords) <= zone.radius then
            if not highestZone or zone.multiplier > highestZone.multiplier then
                highestZone = zone
                highestIndex = index
            end
        end
    end

    return highestZone, highestIndex
end

CreateThread(function()
    createMoneyZoneBlips()

    while true do
        Wait(1000)

        if cache.ped and cache.ped ~= 0 then
            local activeZone, activeZoneIndex = getActiveMoneyZone(GetEntityCoords(cache.ped))
            if activeZoneIndex ~= activeMoneyZoneIndex then
                activeMoneyZoneIndex = activeZoneIndex

                if activeZone then
                    local zoneName = activeZone.name or ("Zone %s"):format(activeZoneIndex)
                    lib.notify({
                        title = Config.notify.title,
                        description = Config.notify.multiplierZone:format(zoneName, activeZone.multiplier),
                        type = "inform"
                    })
                end
            end
        end
    end
end)

RegisterNetEvent("gd_drugselling:client:salePaid", function(drugLabel, saleCount, salePrice)
    lib.notify({
        title = Config.notify.title,
        description = (Config.notify.sold):format(saleCount, drugLabel, salePrice),
        type = "success"
    })
end)

local function cancelDrugSale()
    if not transactionActive then
        return
    end

    transactionCancelled = true
    pcall(lib.cancelProgress)
end

RegisterCommand("+cancelDrugSale", cancelDrugSale, false)
RegisterCommand("-cancelDrugSale", function() end, false)
RegisterKeyMapping("+cancelDrugSale", "Cancel active drug sale transaction", "keyboard", "x")


local function playAnim(dict, anim, speed, time, flag)
    lib.requestAnimDict(dict)
    TaskPlayAnim(cache.ped, dict, anim, speed, speed, time, flag, 1, false, false, false)
end

local function playAnimOnPed(ped, dict, anim, speed, time, flag)
    lib.requestAnimDict(dict)
    TaskPlayAnim(ped, dict, anim, speed, speed, time, flag, 1, false, false, false)
end

local function makeEntityFaceEntity(entity1, entity2)
    local p1 = GetEntityCoords(entity1, true)
    local p2 = GetEntityCoords(entity2, true)
    local dx = p2.x - p1.x
    local dy = p2.y - p1.y
    local heading = GetHeadingFromVector_2d(dx, dy)
    SetEntityHeading(entity1, heading)
end

local function notifyPolice()
    local coords = GetEntityCoords(cache.ped)
    local uniqueId = ("drug-sale-%s-%s"):format(GetPlayerServerId(PlayerId()), GetGameTimer())

    TriggerServerEvent("cd_dispatch:AddNotification", {
        job_table = { "police" },
        coords = coords,
        title = Config.notify.police_notify_title,
        message = Config.notify.police_notify_subtitle,
        flash = 0,
        unique_id = uniqueId,
        sound = 1,
        blip = {
            sprite = 431,
            scale = 1.2,
            colour = 1,
            flashes = false,
            text = Config.notify.police_notify_title,
            time = 5,
            radius = 0
        }
    })
end

local function handlePedSelling(drugToSell)
    local canSell = true
    while sellingActive and npc.ped and DoesEntityExist(npc.ped) and not IsEntityDead(npc.ped) do
        local sleep = 500
        local playerCoords = GetEntityCoords(cache.ped)
        npc.coords = GetEntityCoords(npc.ped)
        local distanceSq = #(playerCoords - npc.coords)

        if distanceSq < 5.0 then
            sleep = 0
            if distanceSq < 2.0 then
                if not lib.isTextUIOpen() then
                    lib.showTextUI(Config.notify.press)
                end
                
                if IsControlJustPressed(0, 38) and canSell then
                    canSell = false
                    lib.hideTextUI()
                    
                    if cache.vehicle then
                        lib.notify({ title = Config.notify.title, description = Config.notify.vehicle, type = 'error' })
                        canSell = true
                    else
                        npc.saleInProgress = true
                        local reject = math.random(1, 10)
                        if reject <= 3 then
                            lib.notify({ title = Config.notify.title, description = Config.notify.reject, type = 'error' })
                            PlayAmbientSpeech1(npc.ped, "GENERIC_HI", "SPEECH_PARAMS_STANDARD")
                            notifyPolice()

                            local failedPed = npc.ped
                            if DoesEntityExist(failedPed) then
                                ClearPedTasks(failedPed)
                                SetEntityAsMissionEntity(failedPed, true, true)
                                DeleteEntity(failedPed)
                            end

                            npc = {}
                            queueNextPed()
                            return
                        end

                        makeEntityFaceEntity(cache.ped, npc.ped)
                        makeEntityFaceEntity(npc.ped, cache.ped)
                        SetPedTalk(npc.ped)
                        PlayAmbientSpeech1(npc.ped, "GENERIC_HI", "SPEECH_PARAMS_STANDARD")
                        
                        local drugProp = CreateObject(`prop_weed_bottle`, 0, 0, 0, true, true, true)
                        AttachEntityToEntity(drugProp, cache.ped, GetPedBoneIndex(cache.ped, 57005), 0.13, 0.02, 0.0, -90.0, 0, 0, 1, 1, 0, 1, 0, 1)
                        
                        local cashProp = CreateObject(`hei_prop_heist_cash_pile`, 0, 0, 0, true, true, true)
                        AttachEntityToEntity(cashProp, npc.ped, GetPedBoneIndex(npc.ped, 57005), 0.13, 0.02, 0.0, -90.0, 0, 0, 1, 1, 0, 1, 0, 1)
                        
                        local salePed = npc.ped
                        local saleProgressDuration = math.max(1, Config.saleProgressDuration)
                        playAnim("mp_common", "givetake1_a", 8.0, saleProgressDuration, 1)
                        playAnimOnPed(salePed, "mp_common", "givetake1_a", 8.0, saleProgressDuration, 1)

                        CreateThread(function()
                            Wait(math.floor(saleProgressDuration / 2))

                            if not sellingActive or npc.ped ~= salePed then
                                return
                            end

                            AttachEntityToEntity(cashProp, cache.ped, GetPedBoneIndex(cache.ped, 57005), 0.13, 0.02, 0.0, -90.0, 0, 0, 1, 1, 0, 1, 0, 1)
                            AttachEntityToEntity(drugProp, salePed, GetPedBoneIndex(salePed, 57005), 0.13, 0.02, 0.0, -90.0, 0, 0, 1, 1, 0, 1, 0, 1)
                        end)
                        
                        transactionActive = true
                        transactionCancelled = false
                        local saleCompleted = lib.progressCircle({
                            duration = saleProgressDuration,
                            label = Config.notify.saleProgress,
                            position = "bottom",
                            useWhileDead = false,
                            canCancel = true,
                            disable = {
                                move = true,
                                car = true,
                                combat = true
                            }
                        })
                        transactionActive = false

                        DeleteEntity(drugProp)
                        DeleteEntity(cashProp)

                        if not saleCompleted or not sellingActive then
                            if transactionCancelled and sellingActive then
                                lib.notify({
                                    title = Config.notify.title,
                                    description = Config.notify.saleCancelled,
                                    type = "inform"
                                })
                            end

                            transactionCancelled = false
                            ClearPedTasks(cache.ped)
                            if DoesEntityExist(salePed) then
                                ClearPedTasks(salePed)
                                SetEntityAsMissionEntity(salePed, true, true)
                                DeleteEntity(salePed)
                            end

                            if sellingActive then
                                npc = {}
                                queueNextPed()
                            end

                            return
                        end
                        
                        PlayAmbientSpeech1(salePed, "GENERIC_THANKS", "SPEECH_PARAMS_STANDARD")
                        SetPedAsNoLongerNeeded(salePed)
                        TriggerServerEvent("gd_drugselling:server:pay", drugToSell)
                        npc = {}
                        queueNextPed()
                        return
                    end
                end
            else
                lib.hideTextUI()
            end
        end
        Wait(sleep)
    end

    if sellingActive then
        npc = {}
        queueNextPed()
    end
end

next_ped = function(drugToSell)
    if not sellingActive then
        return false
    end

    if isCooldown then
        lib.notify({ title = Config.notify.title, description = Config.notify.cooldown, type = 'error' })
        return false
    end

    local playerCoords = GetEntityCoords(cache.ped)

    if Config.cityPoint and #(playerCoords - Config.cityPoint) > 1500.0 then
        lib.notify({ title = Config.notify.title, description = Config.notify.toofar, type = 'error' })
        return false
    end

    if npc.ped and DoesEntityExist(npc.ped) then
        SetPedAsNoLongerNeeded(npc.ped)
    end

    local cops = lib.callback.await('gd_drugselling:server:getPoliceCount', false)
    if not sellingActive then
        return false
    end

    if cops < Config.requiredCops then
        lib.notify({ title = Config.notify.title, description = Config.notify.cops, type = 'error' })
        return false
    end

    isCooldown = true
    SetTimeout(Config.nextPedDelay, function()
        isCooldown = false
    end)

    TaskStartScenarioInPlace(cache.ped, "WORLD_HUMAN_STAND_MOBILE", 0, true)
    lib.notify({ title = Config.notify.title, description = Config.notify.searching .. drugToSell.label, type = 'inform' })
    
    Wait(math.random(5000, 10000))

    if not sellingActive then
        ClearPedTasks(cache.ped)
        return false
    end

    ClearPedTasks(cache.ped)

    local modelName = Config.pedlist[math.random(1, #Config.pedlist)]
    local model = joaat(modelName)
    lib.requestModel(model)

    if not sellingActive then
        SetModelAsNoLongerNeeded(model)
        return false
    end

    local spawnCoords = GetOffsetFromEntityInWorldCoords(
        cache.ped,
        0.0,
        Config.pedSpawnDistance,
        0.0
    )
    local foundGround, groundZ = GetGroundZFor_3dCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z + 50.0, 0)
    local z = foundGround and groundZ or spawnCoords.z
    
    npc.ped = CreatePed(5, model, spawnCoords.x, spawnCoords.y, z, 0.0, true, true)
    SetEntityAsMissionEntity(npc.ped, true, true)
    PlaceObjectOnGroundProperly(npc.ped)

    local spawnedPed = npc.ped
    SetTimeout(Config.pedDespawnTime, function()
        if npc.ped ~= spawnedPed or npc.saleInProgress then
            return
        end

        if DoesEntityExist(spawnedPed) then
            ClearPedTasks(spawnedPed)
            SetEntityAsMissionEntity(spawnedPed, true, true)
            DeleteEntity(spawnedPed)
        end

        npc.ped = nil
        lib.hideTextUI()
    end)

    if not DoesEntityExist(npc.ped) or IsEntityDead(npc.ped) then
        isCooldown = false
        lib.notify({ title = Config.notify.title, description = Config.notify.notfound, type = 'error' })
        return false
    end

    local zoneName = GetLabelText(GetNameOfZone(spawnCoords))
    lib.notify({ title = Config.notify.approach, description = Config.notify.found .. zoneName, type = 'success' })
    
    TaskGoToEntity(npc.ped, cache.ped, 40000, 4.0, Config.pedMoveSpeed, 0, 0)
    handlePedSelling(drugToSell)
    return true
end

local function getDrugData()
    local inventory = exports.ox_inventory:Items()

    for drugName, data in pairs(Config.drugs) do
        local count = exports.ox_inventory:GetItemCount(drugName)
        if count > 0 then
            local price = type(data) == "table" and data.price or data
            local label = inventory and inventory[drugName] and inventory[drugName].label or drugName
            local saleCount = math.min(math.random(Config.saleAmountMin, Config.saleAmountMax), count)

            return {
                name = drugName,
                label = label,
                price = price,
                count = saleCount
            }
        end
    end

    return nil
end

queueNextPed = function()
    if not sellingActive then
        return
    end

    SetTimeout(Config.nextPedDelay, function()
        if not sellingActive then
            return
        end

        local drugData = getDrugData()
        if not drugData then
            sellingActive = false
            lib.notify({ title = Config.notify.title, description = Config.notify.nodrugs, type = "error" })
            return
        end

        if not next_ped(drugData) then
            sellingActive = false
        end
    end)
end

local function stopSelling()
    if not sellingActive then
        lib.notify({ title = Config.notify.title, description = Config.notify.notSelling, type = "inform" })
        return
    end

    sellingActive = false
    isCooldown = false
    if transactionActive then
        transactionCancelled = true
        pcall(lib.cancelProgress)
    end

    transactionActive = false
    transactionCancelled = false
    lib.hideTextUI()
    ClearPedTasks(cache.ped)

    if npc.ped and DoesEntityExist(npc.ped) then
        ClearPedTasks(npc.ped)
        SetEntityAsMissionEntity(npc.ped, true, true)
        DeleteEntity(npc.ped)
    end

    npc = {}
    lib.notify({ title = Config.notify.title, description = Config.notify.stopped, type = "inform" })
end

RegisterCommand("selldrugs", function()
    if sellingActive then
        lib.notify({ title = Config.notify.title, description = Config.notify.alreadySelling, type = "inform" })
        return
    end

    if cache.vehicle then
        lib.notify({ title = Config.notify.title, description = Config.notify.vehicle, type = "error" })
        return
    end

    local drugData = getDrugData()
    if not drugData then
        lib.notify({ title = Config.notify.title, description = Config.notify.nodrugs, type = "error" })
        return
    end

    sellingActive = true
    lib.notify({ title = Config.notify.title, description = Config.notify.started, type = "inform" })

    if not next_ped(drugData) then
        sellingActive = false
    end
end)

RegisterCommand("stopselling", function()
    stopSelling()
end)
