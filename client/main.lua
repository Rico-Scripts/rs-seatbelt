local buckled = false
local motorcycleHelmet = false
local helmetBusy = false
local activeVehicle
local activeMotorcycle
local previousSpeed = 0.0
local previousVelocity = vector3(0.0, 0.0, 0.0)
local lastEjection = 0

local function notify(message, kind)
    lib.notify({ title = 'Voertuigveiligheid', description = message, type = kind or 'inform' })
end

local function isMotorcycle(vehicle)
    return Config.EnableMotorcycleHelmet and vehicle ~= 0 and DoesEntityExist(vehicle)
        and GetVehicleClass(vehicle) == Config.MotorcycleClass
end

local function supportsSeatbelt(vehicle)
    return vehicle ~= 0 and DoesEntityExist(vehicle) and not Config.IgnoredVehicleClasses[GetVehicleClass(vehicle)]
end

local function publishState(value)
    buckled = value == true
    LocalPlayer.state:set('seatbelt', buckled, true)
    TriggerEvent('rs-seatbelt:client:changed', buckled)
end

local function publishHelmetState(value)
    motorcycleHelmet = value == true
    LocalPlayer.state:set('motorcycleHelmet', motorcycleHelmet, true)
    TriggerEvent('rs-seatbelt:client:helmetChanged', motorcycleHelmet)
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

local function loadAnimationDictionary(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + Config.HelmetAnimationLoadTimeout
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do Wait(10) end
    return HasAnimDictLoaded(dict)
end

local function runHelmetAnimation(ped, animation, applyVisual)
    local loaded = animation and loadAnimationDictionary(animation.dict)
    if not loaded then
        applyVisual()
        return
    end

    local duration = math.max(250, tonumber(animation.duration) or 1000)
    local applyAt = math.min(duration, math.max(0, tonumber(animation.applyAt) or math.floor(duration / 2)))
    TaskPlayAnim(ped, animation.dict, animation.clip, 8.0, -8.0, duration,
        Config.HelmetAnimationFlag, 0.0, false, false, false)
    Wait(applyAt)
    applyVisual()
    Wait(math.max(0, duration - applyAt))
    StopAnimTask(ped, animation.dict, animation.clip, 2.0)
    RemoveAnimDict(animation.dict)
end

local function removeMotorcycleHelmet(ped, silent)
    if motorcycleHelmet or IsPedWearingHelmet(ped) then RemovePedHelmet(ped, true) end
    SetPedHelmet(ped, false)
    publishHelmetState(false)
    if not silent then notify('Helm af.', 'inform') end
end

local function toggleMotorcycleHelmet(ped)
    if helmetBusy or IsEntityDead(ped) then return end
    helmetBusy = true

    if motorcycleHelmet then
        runHelmetAnimation(ped, Config.HelmetAnimations.takeOff, function()
            removeMotorcycleHelmet(ped, true)
        end)
        PlaySoundFrontend(-1, 'NAV_LEFT_RIGHT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
        notify('Helm af.', 'inform')
    else
        runHelmetAnimation(ped, Config.HelmetAnimations.putOn, function()
            SetPedHelmet(ped, true)
            GivePedHelmet(ped, false, Config.HelmetFlag, Config.HelmetTexture)
            publishHelmetState(true)
        end)
        PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
        notify('Helm op.', 'success')
    end

    helmetBusy = false
end

local function toggleSafety()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if isMotorcycle(vehicle) then
        activeMotorcycle = vehicle
        return toggleMotorcycleHelmet(ped)
    end
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

RegisterCommand(Config.Command, toggleSafety, false)
RegisterKeyMapping(Config.Command, 'Gordel vast/los of motorhelm op/af', 'keyboard', Config.Key)

CreateThread(function()
    publishState(false)
    publishHelmetState(false)
    while true do
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)

        if isMotorcycle(vehicle) then
            if buckled then unbuckle(true) end
            if activeVehicle then resetTracking(0) end
            if activeMotorcycle ~= vehicle then
                activeMotorcycle = vehicle
                removeMotorcycleHelmet(ped, true)
            elseif Config.PreventAutomaticMotorcycleHelmet and not motorcycleHelmet then
                SetPedHelmet(ped, false)
                if IsPedWearingHelmet(ped) then RemovePedHelmet(ped, true) end
            end
            Wait(150)
        else
            if activeMotorcycle then
                activeMotorcycle = nil
                if Config.RemoveHelmetOnExit then removeMotorcycleHelmet(ped, true) end
            end

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
    end
end)

AddEventHandler('esx:onPlayerDeath', function()
    unbuckle(true)
    removeMotorcycleHelmet(PlayerPedId(), true)
end)
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        local ped = PlayerPedId()
        publishState(false)
        if motorcycleHelmet and IsPedWearingHelmet(ped) then RemovePedHelmet(ped, true) end
        publishHelmetState(false)
        SetPedHelmet(ped, true)
    end
end)

exports('IsSeatbeltOn', function() return buckled end)
exports('IsMotorcycleHelmetOn', function() return motorcycleHelmet end)
