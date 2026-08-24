Config = {}

Config.Command = 'gordel'
Config.Key = 'B'
Config.EnableMotorcycleHelmet = true
Config.PreventAutomaticMotorcycleHelmet = true
Config.RemoveHelmetOnExit = true
Config.MotorcycleClass = 8
Config.HelmetFlag = 4096
Config.HelmetTexture = -1
Config.UseStreamedHelmetProps = true
Config.HelmetPropLoadTimeout = 5000
Config.HideHelmetPropInFirstPerson = true

-- Het type wordt automatisch gekozen aan de hand van de spawnnaam.
-- Zonder geldige kledingoverride gebruikt het script een veilige GTA-helm.
Config.DefaultMotorcycleHelmetType = 'sport'
Config.MotorcycleHelmetTypes = {
    sport = {
        label = 'Integraalhelm',
        object = {
            model = 'integraalhelm',
            bone = 31086,
            position = { x = 0.0, y = 0.0, z = 0.0 },
            rotation = { x = 0.0, y = 0.0, z = 0.0 },
        },
        helmetFlag = 8192,
        texture = -1,
        props = {
            male = { collection = '', drawable = 18, texture = 7 },
            female = { collection = '', drawable = 18, texture = 7 },
        },
    },
    offroad = {
        label = 'Crosshelm',
        object = {
            model = 'crosshelm_met_bril',
            bone = 31086,
            position = { x = 0.0, y = 0.0, z = 0.0 },
            rotation = { x = 0.0, y = 0.0, z = 0.0 },
        },
        helmetFlag = 8192,
        texture = -1,
        props = {
            male = { collection = '', drawable = 16, texture = 5 },
            female = { collection = '', drawable = 16, texture = 5 },
        },
    },
    cruiser = {
        label = 'Open helm',
        object = {
            model = 'chopperhelm',
            bone = 31086,
            position = { x = 0.0, y = 0.0, z = 0.0 },
            rotation = { x = 0.0, y = 0.0, z = 0.0 },
        },
        helmetFlag = 4096,
        texture = -1,
        props = {
            male = { collection = '', drawable = 17, texture = 5 },
            female = { collection = '', drawable = 17, texture = 5 },
        },
    },
    scooter = {
        label = 'Scooterhelm',
        object = {
            model = 'chopperhelm',
            bone = 31086,
            position = { x = 0.0, y = 0.0, z = 0.0 },
            rotation = { x = 0.0, y = 0.0, z = 0.0 },
        },
        helmetFlag = 4096,
        texture = -1,
        props = {
            male = { collection = '', drawable = 17, texture = 7 },
            female = { collection = '', drawable = 17, texture = 7 },
        },
    },
}

-- Standaard GTA-motoren. Add-onmotoren kunnen hieronder in CustomMotorcycleTypes.
Config.MotorcycleTypes = {
    sport = {
        'akuma', 'bati', 'bati2', 'carbonrs', 'defiler', 'double', 'hakuchou',
        'hakuchou2', 'lectro', 'nemesis', 'pcj', 'powersurge', 'reever',
        'ruffian', 'shinobi', 'shotaro', 'thrust', 'vader', 'vindicator', 'vortex',
    },
    offroad = {
        'bf400', 'enduro', 'esskey', 'manchez', 'manchez2', 'manchez3',
        'sanchez', 'sanchez2',
    },
    cruiser = {
        'avarus', 'bagger', 'chimera', 'daemon', 'daemon2', 'gargoyle', 'hexer',
        'innovation', 'nightblade', 'ratbike', 'sanctus', 'sovereign', 'wolfsbane',
        'zombiea', 'zombieb',
    },
    scooter = { 'faggio', 'faggio2', 'faggio3' },
}

-- Voeg add-onmotoren toe als: ['spawnnaam'] = 'sport' / 'offroad' / 'cruiser' / 'scooter'.
Config.CustomMotorcycleTypes = {}

-- De officiële GTA-basiscollectie ('') hieronder is de fallback als een object niet laadt.
-- Optioneel kun je ze vervangen door een exacte EUP-helm. Collectienamen blijven stabiel.
-- Een ongeldige/missende override valt automatisch terug op de GTA-helm hierboven.
-- Voorbeeld:
-- Config.MotorcycleHelmetTypes.sport.props = {
--     male = { collection = 'jouw_male_collectie', drawable = 0, texture = 0 },
--     female = { collection = 'jouw_female_collectie', drawable = 0, texture = 0 },
-- }
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
