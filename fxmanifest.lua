fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Rico Scripts'
description 'Veiligheidsgordel en handmatige motorhelm met HUD-status en botsingsejectie'
version '1.5.1'

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
