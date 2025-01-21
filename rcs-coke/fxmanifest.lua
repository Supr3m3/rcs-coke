fx_version 'cerulean'
game 'gta5'

author 'YourName'
description 'Cocaine Planting System'
version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua', -- QBCore Localization
    'config.lua'                  -- Configuration file for constants
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',     -- Database library (if needed for persistence)
    'server.lua'
}

dependencies {
    'qb-core', 'qb-inventory', 'qb-target', 'qb-menu'
}
