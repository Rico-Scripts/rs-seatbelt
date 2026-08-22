local buckled = false
local activeVehicle
local previousSpeed = 0.0
local previousVelocity = vector3(0.0, 0.0, 0.0)
local lastEjection = 0

local function notify(message, kind)
    lib.notify({ title = 'Veiligheidsgordel', description = message, type = kind or 'inform' })
end

local function supportsSeatbelt(vehicle)
    return vehicle ~= 0 and DoesEntityExist(vehicle) and not Config.IgnoredVehicleClasses[GetVehicleClass(vehicle)]
end

local function publishState(value)
    buckled = value == true
    LocalPlayer.state:set('seatbelt', buckled, true)
    TriggerEvent('rs-seatbelt:client:changed', buckled)
end

local function resetTracking(vehicle)
    activeVehicle = vehicle ~= 0 and vehicle or nil
    previousSpeed = activeVehicle and GetEntitySpeed(activeVehicle) or 0.0
    previousVelocity = activeVehicle and GetEntityVelocity(activeVehicle) or vector3(0.0, 0.0, 0.0)
end

local function unbuckle(silent)
    if not buckled then return end
    publishState(false)
    if not silent then notify('Gordel los.', 'inform') end
end

local function toggleSeatbelt()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if not supportsSeatbelt(vehicle) then return notify('Dit voertuig heeft geen veiligheidsgordel.', 'error') end
    publishState(not buckled)
    PlaySoundFrontend(-1, buckled and 'NAV_UP_DOWN' or 'NAV_LEFT_RIGHT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    notify(buckled and 'Gordel vast.' or 'Gordel los.', buckled and 'success' or 'inform')
end

local function ejectPlayer(ped, vehicle)
    if GetGameTimer() - lastEjection < Config.EjectCooldown then return end
    lastEjection = GetGameTimer()
    local coords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 1.0, 1.0)
    SetEntityCoords(ped, coords.x, coords.y, coords.z, true, true, true, false)
    SetEntityVelocity(ped, previousVelocity.x, previousVelocity.y, previousVelocity.z)
    SetPedToRagdoll(ped, Config.RagdollMilliseconds, Config.RagdollMilliseconds, 0, false, false, false)
    if Config.EjectDamage > 0 then
        SetEntityHealth(ped, math.max(0, GetEntityHealth(ped) - Config.EjectDamage))
    end
end

RegisterCommand(Config.Command, toggleSeatbelt, false)
RegisterKeyMapping(Config.Command, 'Veiligheidsgordel vast/los', 'keyboard', Config.Key)

CreateThread(function()
    publishState(false)
    while true do
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if not supportsSeatbelt(vehicle) then
            if buckled then unbuckle(true) end
            if activeVehicle then resetTracking(0) end
            Wait(400)
        else
            if activeVehicle ~= vehicle then
                if buckled then unbuckle(true) end
                resetTracking(vehicle)
            end

            if buckled and Config.DisableExitWhileBuckled then DisableControlAction(0, 75, true) end

            local speed = GetEntitySpeed(vehicle)
            local speedKmh = speed * 3.6
            local speedDropKmh = (previousSpeed - speed) * 3.6
            if Config.EnableEjection and not buckled and previousSpeed * 3.6 >= Config.MinimumEjectSpeed
                and speedDropKmh >= Config.MinimumSpeedDrop and HasEntityCollidedWithAnything(vehicle) then
                ejectPlayer(ped, vehicle)
            end

            previousSpeed = speed
            previousVelocity = GetEntityVelocity(vehicle)
            Wait(0)
        end
    end
end)

AddEventHandler('esx:onPlayerDeath', function() unbuckle(true) end)
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then publishState(false) end
end)

exports('IsSeatbeltOn', function() return buckled end)
