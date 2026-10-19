lib.callback.register('gd_drugselling:server:getPoliceCount', function(source)
    local cops = 0
    local players = exports.qbx_core:GetQBPlayers()
    for _, v in pairs(players) do
        if v.PlayerData.job.name == 'police' and v.PlayerData.job.onduty then
            cops = cops + 1
        end
    end
    return cops
end)

--- Find the highest configured payout multiplier at the player's current location.
--- @param source number The server player ID
--- @return number multiplier The payout multiplier for the location
local function getLocationMultiplier(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then
        return 1.0
    end

    local playerCoords = GetEntityCoords(ped)
    local highestMultiplier = 1.0

    for _, zone in ipairs(Config.moneyZones or {}) do
        if type(zone) == "table"
            and zone.coords
            and type(zone.radius) == "number"
            and type(zone.multiplier) == "number"
            and zone.radius > 0
            and zone.multiplier >= 1.0
            and #(playerCoords - zone.coords) <= zone.radius
            and zone.multiplier > highestMultiplier then
            highestMultiplier = zone.multiplier
        end
    end

    return highestMultiplier
end

RegisterNetEvent("gd_drugselling:server:pay", function(drugData)
    local src = source
    if src <= 0 or type(drugData) ~= "table" or type(drugData.name) ~= "string" then
        return
    end

    local player = exports.qbx_core:GetPlayer(src)
    local drugConfig = Config.drugs[drugData.name]
    local saleCount = tonumber(drugData.count)

    if not player or not drugConfig or type(drugConfig) ~= "table" or not saleCount or saleCount < Config.saleAmountMin or saleCount > Config.saleAmountMax or saleCount % 1 ~= 0 then
        return
    end

    local availableCount = exports.ox_inventory:GetItemCount(src, drugData.name)
    if availableCount < saleCount then
        exports.qbx_core:Notify(src, "You don't have enough drugs", "error")
        return
    end

    local basePrice = tonumber(drugConfig.price)
    if not basePrice or basePrice < 1 then
        return
    end

    local players = exports.qbx_core:GetQBPlayers()
    local cops = 0
    for _, onlinePlayer in pairs(players) do
        if onlinePlayer.PlayerData.job.name == "police" and onlinePlayer.PlayerData.job.onduty then
            cops = cops + 1
        end
    end

    local policeMultipliers = { [3] = 1.10, [4] = 1.15, [5] = 1.20, [6] = 1.25 }
    local policeMultiplier = policeMultipliers[cops] or (cops >= 7 and 1.30 or 1.0)
    local locationMultiplier = getLocationMultiplier(src)
    local salePrice = math.floor(basePrice * saleCount * policeMultiplier * locationMultiplier + 0.5)

    local removed = exports.ox_inventory:RemoveItem(src, drugData.name, saleCount)
    if not removed then
        exports.qbx_core:Notify(src, "The sale could not be completed", "error")
        return
    end

    if drugConfig.account == "black_money" or drugConfig.account == "dirty_money" then
        local added, reason = exports.ox_inventory:AddItem(src, "black_money", salePrice)
        if not added then
            exports.ox_inventory:AddItem(src, drugData.name, saleCount)
            print(("[gd_drugselling] black_money payout failed for player %s: %s"):format(src, tostring(reason)))
            exports.qbx_core:Notify(src, "The black_money item could not be added. Check your inventory item setup.", "error")
            return
        end
    elseif drugConfig.account == "money" then
        exports.qbx_core:AddMoney(src, "cash", salePrice, "drug-sale")
    else
        exports.ox_inventory:AddItem(src, drugData.name, saleCount)
        return
    end

    TriggerClientEvent(
        "gd_drugselling:client:salePaid",
        src,
        drugData.label or drugData.name,
        saleCount,
        salePrice
    )
end)

