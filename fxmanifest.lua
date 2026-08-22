fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Rico Scripts'
description 'Veiligheidsgordel met HUD-status, uitstapblokkering en botsingsejectie'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_script 'client/main.lua'
server_script '@rs_discordlogs/server/intercept.lua'

dependencies {
    'ox_lib',
    'rs_discordlogs'
}
