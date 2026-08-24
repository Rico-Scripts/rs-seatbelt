Config = {}

Config.Command = 'gordel'
Config.Key = 'B'
Config.EnableMotorcycleHelmet = true
Config.PreventAutomaticMotorcycleHelmet = true
Config.RemoveHelmetOnExit = true
Config.MotorcycleClass = 8
Config.HelmetFlag = 4096
Config.HelmetTexture = -1
Config.HelmetAnimationFlag = 48
Config.HelmetAnimationLoadTimeout = 2500
Config.HelmetAnimations = {
    putOn = {
        dict = 'missheistdockssetup1hardhat@',
        clip = 'put_on_hat',
        duration = 1100,
        applyAt = 650,
    },
    takeOff = {
        dict = 'missheist_agency2ahelmet',
        clip = 'take_off_helmet_stand',
        duration = 1000,
        applyAt = 500,
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
