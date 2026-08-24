local buckled = false
local motorcycleHelmet = false
local helmetBusy = false
local activeVehicle
local activeMotorcycle
local previousSpeed = 0.0
local previousVelocity = vector3(0.0, 0.0, 0.0)
local lastEjection = 0
local savedHeadwear
local activeHelmetType
local helmetObject
local helmetUsesObject = false
local helmetEditor
local motorcycleTypeByHash = {}

for typeName, models in pairs(Config.MotorcycleTypes or {}) do
    for i = 1, #models do motorcycleTypeByHash[joaat(models[i])] = typeName end
end
for model, typeName in pairs(Config.CustomMotorcycleTypes or {}) do
    motorcycleTypeByHash[joaat(model)] = typeName
end

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
    LocalPlayer.state:set('motorcycleHelmetType', motorcycleHelmet and activeHelmetType or nil, true)
    TriggerEvent('rs-seatbelt:client:helmetChanged', motorcycleHelmet)
end

local function getHelmetType(vehicle)
    local typeName = motorcycleTypeByHash[GetEntityModel(vehicle)] or Config.DefaultMotorcycleHelmetType
    if not Config.MotorcycleHelmetTypes[typeName] then typeName = Config.DefaultMotorcycleHelmetType end
    return typeName, Config.MotorcycleHelmetTypes[typeName]
end

local function getPedProfileKey(ped)
    local model = GetEntityModel(ped)
    if model == joaat('mp_m_freemode_01') then return 'male' end
    if model == joaat('mp_f_freemode_01') then return 'female' end
    return 'other'
end

local function rememberHeadwear(ped)
    savedHeadwear = {
        drawable = GetPedPropIndex(ped, 0),
        texture = GetPedPropTextureIndex(ped, 0),
    }
    if savedHeadwear.drawable >= 0 and type(GetPedPropCollectionName) == 'function'
        and type(GetPedPropCollectionLocalIndex) == 'function' then
        savedHeadwear.collection = GetPedPropCollectionName(ped, 0)
        savedHeadwear.localDrawable = GetPedPropCollectionLocalIndex(ped, 0)
    end
end

local function restoreHeadwear(ped)
    local original = savedHeadwear
    savedHeadwear = nil
    if not original then return end
    if original.drawable < 0 then return ClearPedProp(ped, 0) end

    if original.collection and type(SetPedCollectionPropIndex) == 'function' then
        SetPedCollectionPropIndex(ped, 0, original.collection, original.localDrawable,
            math.max(0, original.texture), true)
        return
    end
    SetPedPropIndex(ped, 0, original.drawable, math.max(0, original.texture), true)
end

local function applyConfiguredProp(ped, prop)
    if type(prop) ~= 'table' then return false end
    local drawable = tonumber(prop.drawable)
    local texture = math.max(0, tonumber(prop.texture) or 0)
    if not drawable or drawable < 0 then return false end

    if prop.collection and type(GetNumberOfPedCollectionPropDrawableVariations) == 'function'
        and type(GetNumberOfPedCollectionPropTextureVariations) == 'function'
        and type(SetPedCollectionPropIndex) == 'function' then
        local count = GetNumberOfPedCollectionPropDrawableVariations(ped, 0, prop.collection)
        if drawable >= count then return false end
        local textures = GetNumberOfPedCollectionPropTextureVariations(ped, 0, prop.collection, drawable)
        if texture >= math.max(1, textures) then return false end
        SetPedCollectionPropIndex(ped, 0, prop.collection, drawable, texture, true)
        return GetPedPropIndex(ped, 0) >= 0
    end

    local count = GetNumberOfPedPropDrawableVariations(ped, 0)
    if drawable >= count then return false end
    local textures = GetNumberOfPedPropTextureVariations(ped, 0, drawable)
    if texture >= math.max(1, textures) then return false end
    SetPedPropIndex(ped, 0, drawable, texture, true)
    return GetPedPropIndex(ped, 0) == drawable
end

local function deleteHelmetObject()
    if helmetObject and DoesEntityExist(helmetObject) then
        DetachEntity(helmetObject, true, true)
        SetEntityAsMissionEntity(helmetObject, true, true)
        DeleteEntity(helmetObject)
    end
    helmetObject = nil
    helmetUsesObject = false
end

local function refreshHelmetObjectAttachment(ped, objectConfig)
    if not helmetObject or not DoesEntityExist(helmetObject) or type(objectConfig) ~= 'table' then return end
    local position = objectConfig.position or {}
    local rotation = objectConfig.rotation or {}
    DetachEntity(helmetObject, true, true)
    AttachEntityToEntity(helmetObject, ped, GetPedBoneIndex(ped, tonumber(objectConfig.bone) or 31086),
        tonumber(position.x) or 0.0, tonumber(position.y) or 0.0, tonumber(position.z) or 0.0,
        tonumber(rotation.x) or 0.0, tonumber(rotation.y) or 0.0, tonumber(rotation.z) or 0.0,
        true, true, false, true, 2, true)
end

local function applyStreamedHelmetProp(ped, objectConfig)
    if not Config.UseStreamedHelmetProps or type(objectConfig) ~= 'table' then return false end
    local model = joaat(tostring(objectConfig.model or ''))
    if not IsModelInCdimage(model) or not IsModelValid(model) then return false end

    RequestModel(model)
    local timeout = GetGameTimer() + (tonumber(Config.HelmetPropLoadTimeout) or 5000)
    while not HasModelLoaded(model) and GetGameTimer() < timeout do Wait(10) end
    if not HasModelLoaded(model) then return false end

    local coords = GetEntityCoords(ped)
    local object = CreateObjectNoOffset(model, coords.x, coords.y, coords.z, false, false, false)
    if object == 0 or not DoesEntityExist(object) then
        SetModelAsNoLongerNeeded(model)
        return false
    end

    SetEntityAsMissionEntity(object, true, true)
    SetEntityCollision(object, false, false)
    SetEntityInvincible(object, true)
    helmetObject = object
    helmetUsesObject = true
    refreshHelmetObjectAttachment(ped, objectConfig)
    SetModelAsNoLongerNeeded(model)

    ClearPedProp(ped, 0)
    return true
end

local function applyMotorcycleHelmet(ped, vehicle)
    local typeName, profile = getHelmetType(vehicle)
    activeHelmetType = typeName
    rememberHeadwear(ped)

    deleteHelmetObject()
    local applied = applyStreamedHelmetProp(ped, profile.object)
    local props = profile.props or {}
    if not applied and not applyConfiguredProp(ped, props[getPedProfileKey(ped)] or props.other) then
        SetPedHelmet(ped, true)
        GivePedHelmet(ped, false, tonumber(profile.helmetFlag) or Config.HelmetFlag,
            tonumber(profile.texture) or Config.HelmetTexture)
    end
    publishHelmetState(true)
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

    -- De standaard motor-taak gebruikt zelf een secondary upper-body animatie.
    -- Maak die eerst vrij, anders blijven de handen zichtbaar aan het stuur.
    ClearPedSecondaryTask(ped)
    Wait(50)

    TaskPlayAnim(ped, animation.dict, animation.clip, 8.0, -8.0, duration,
        Config.HelmetAnimationFlag, 0.0, false, false, false)

    -- Op sommige add-on motoren overschrijft de rijtaak de eerste aanvraag.
    -- Vraag de animatie eenmaal opnieuw aan wanneer hij niet gestart is.
    local startTimeout = GetGameTimer() + 300
    while not IsEntityPlayingAnim(ped, animation.dict, animation.clip, 3)
        and GetGameTimer() < startTimeout do
        Wait(10)
    end
    if not IsEntityPlayingAnim(ped, animation.dict, animation.clip, 3) then
        TaskPlayAnim(ped, animation.dict, animation.clip, 8.0, -8.0, duration,
            Config.HelmetAnimationFlag, 0.0, false, false, false)
    end

    Wait(applyAt)
    applyVisual()
    Wait(math.max(0, duration - applyAt))
    StopAnimTask(ped, animation.dict, animation.clip, 2.0)
    ClearPedSecondaryTask(ped)
    RemoveAnimDict(animation.dict)
end

local function removeMotorcycleHelmet(ped, silent)
    local usedObject = helmetUsesObject
    deleteHelmetObject()
    if not usedObject and (motorcycleHelmet or IsPedWearingHelmet(ped)) then RemovePedHelmet(ped, true) end
    SetPedHelmet(ped, false)
    restoreHeadwear(ped)
    activeHelmetType = nil
    publishHelmetState(false)
    if not silent then notify('Helm af.', 'inform') end
end

local function toggleMotorcycleHelmet(ped, vehicle)
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
            applyMotorcycleHelmet(ped, vehicle)
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
        return toggleMotorcycleHelmet(ped, vehicle)
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

local function cloneVectorTable(source)
    source = source or {}
    return {
        x = tonumber(source.x) or 0.0,
        y = tonumber(source.y) or 0.0,
        z = tonumber(source.z) or 0.0,
    }
end

local function closeHelmetEditor(restore)
    if not helmetEditor then return end
    if restore then
        helmetEditor.object.position = cloneVectorTable(helmetEditor.originalPosition)
        helmetEditor.object.rotation = cloneVectorTable(helmetEditor.originalRotation)
        refreshHelmetObjectAttachment(PlayerPedId(), helmetEditor.object)
    end
    helmetEditor = nil
    lib.hideTextUI()
end

local function showHelmetEditorHelp()
    local mode = helmetEditor and helmetEditor.mode == 'rotation' and 'ROTATIE' or 'POSITIE'
    lib.showTextUI(('[Helm afstellen: %s]  Pijlen: X/Y  |  PgUp/PgDn: Z  |  R: wisselen  |  Shift: sneller  |  Enter: kopiëren  |  Backspace: annuleren'):format(mode), {
        position = 'top-center',
        icon = 'helmet-safety',
    })
end

local function helmetConfigBlock(editor)
    local object = editor.object
    local position = object.position
    local rotation = object.rotation
    return ([[object = {
    model = '%s',
    bone = %d,
    position = { x = %.4f, y = %.4f, z = %.4f },
    rotation = { x = %.4f, y = %.4f, z = %.4f },
},]]):format(tostring(object.model), tonumber(object.bone) or 31086,
        position.x, position.y, position.z, rotation.x, rotation.y, rotation.z)
end

local function startHelmetEditor()
    if not Config.EnableHelmetPositionEditor then
        return notify('De helm-afstelmodus staat uit in config.lua.', 'error')
    end
    if helmetEditor then
        closeHelmetEditor(true)
        return notify('Helm-afstelmodus geannuleerd.', 'inform')
    end

    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if not isMotorcycle(vehicle) then
        return notify('Ga eerst op de motor zitten.', 'error')
    end
    if not motorcycleHelmet or not helmetObject or not DoesEntityExist(helmetObject) then
        return notify('Zet eerst de gestreamde helm op met B.', 'error')
    end

    local typeName, profile = getHelmetType(vehicle)
    if not profile or type(profile.object) ~= 'table' then
        return notify('Voor dit motortype ontbreekt een objectprofiel.', 'error')
    end

    profile.object.position = cloneVectorTable(profile.object.position)
    profile.object.rotation = cloneVectorTable(profile.object.rotation)
    helmetEditor = {
        typeName = typeName,
        object = profile.object,
        mode = 'position',
        originalPosition = cloneVectorTable(profile.object.position),
        originalRotation = cloneVectorTable(profile.object.rotation),
    }
    showHelmetEditorHelp()
    notify(('Afstelmodus gestart voor %s.'):format(profile.label or typeName), 'success')
end

RegisterCommand(Config.HelmetPositionCommand or 'helmpositie', startHelmetEditor, false)

CreateThread(function()
    while true do
        if not helmetEditor then
            Wait(400)
        else
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            if not isMotorcycle(vehicle) or not helmetObject or not DoesEntityExist(helmetObject) then
                closeHelmetEditor(true)
                notify('Helm-afstelmodus gestopt.', 'inform')
            else
                for _, control in ipairs({ 10, 11, 21, 45, 172, 173, 174, 175, 177, 191 }) do
                    DisableControlAction(0, control, true)
                end

                if IsDisabledControlJustPressed(0, 45) then
                    helmetEditor.mode = helmetEditor.mode == 'position' and 'rotation' or 'position'
                    showHelmetEditorHelp()
                elseif IsDisabledControlJustPressed(0, 177) then
                    closeHelmetEditor(true)
                    notify('Wijzigingen geannuleerd.', 'inform')
                elseif IsDisabledControlJustPressed(0, 191) then
                    local block = helmetConfigBlock(helmetEditor)
                    print(('^2[rs-seatbelt] %s helmwaarden:^7\n%s'):format(helmetEditor.typeName, block))
                    if lib.setClipboard then lib.setClipboard(block) end
                    closeHelmetEditor(false)
                    notify('Helmwaarden gekopieerd en in de F8-console gezet.', 'success')
                else
                    local target = helmetEditor.object[helmetEditor.mode]
                    local baseStep = helmetEditor.mode == 'position'
                        and (tonumber(Config.HelmetPositionStep) or 0.005)
                        or (tonumber(Config.HelmetRotationStep) or 0.5)
                    local step = IsDisabledControlPressed(0, 21) and baseStep * 5.0 or baseStep
                    local changed = false

                    if IsDisabledControlPressed(0, 174) then
                        target.x = target.x - step
                        changed = true
                    end
                    if IsDisabledControlPressed(0, 175) then
                        target.x = target.x + step
                        changed = true
                    end
                    if IsDisabledControlPressed(0, 172) then
                        target.y = target.y + step
                        changed = true
                    end
                    if IsDisabledControlPressed(0, 173) then
                        target.y = target.y - step
                        changed = true
                    end
                    if IsDisabledControlPressed(0, 10) then
                        target.z = target.z + step
                        changed = true
                    end
                    if IsDisabledControlPressed(0, 11) then
                        target.z = target.z - step
                        changed = true
                    end

                    if changed then refreshHelmetObjectAttachment(ped, helmetEditor.object) end
                end
                Wait(0)
            end
        end
    end
end)


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
            if helmetObject and DoesEntityExist(helmetObject) and Config.HideHelmetPropInFirstPerson then
                SetEntityVisible(helmetObject, GetFollowVehicleCamViewMode() ~= 4, false)
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
        if helmetEditor then closeHelmetEditor(true) end
        deleteHelmetObject()
        publishState(false)
        if motorcycleHelmet and IsPedWearingHelmet(ped) then RemovePedHelmet(ped, true) end
        restoreHeadwear(ped)
        activeHelmetType = nil
        publishHelmetState(false)
        SetPedHelmet(ped, true)
    end
end)

exports('IsSeatbeltOn', function() return buckled end)
exports('IsMotorcycleHelmetOn', function() return motorcycleHelmet end)
