Config = {}

Config.Command = 'gordel'
Config.Key = 'B'
Config.EnableMotorcycleHelmet = true
Config.PreventAutomaticMotorcycleHelmet = true
Config.RemoveHelmetOnExit = true
Config.MotorcycleClass = 8
Config.HelmetFlag = 4096
Config.HelmetTexture = -1
-- 51 houdt de animatie op het bovenlichaam terwijl de ped op de motor blijft zitten.
Config.HelmetAnimationFlag = 51
Config.HelmetAnimationLoadTimeout = 2500
Config.HelmetAnimations = {
    putOn = {
        dict = 'mp_masks@standard_car@ds@',
        clip = 'put_on_mask',
        duration = 1250,
        applyAt = 700,
    },
    takeOff = {
        dict = 'mp_masks@standard_car@ds@',
        clip = 'put_on_mask',
        duration = 1250,
        applyAt = 550,
    },
}
Config.DisableExitWhileBuckled = true
Config.EnableEjection = true
Config.MinimumEjectSpeed = 65.0
Config.MinimumSpeedDrop = 35.0
Config.EjectCooldown = 3000
Config.RagdollMilliseconds = 3500
Config.EjectDamage = 20
Config.IgnoredVehicleClasses = {
    [8] = true,
    [13] = true,
    [14] = true,
    [15] = true,
    [16] = true,
    [21] = true,
}
