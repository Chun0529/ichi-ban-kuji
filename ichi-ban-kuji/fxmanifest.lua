fx_version 'cerulean'
game 'gta5'

author 'YourName'
description 'Weapon Upgrade System'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/database.lua',
    'server/main.lua'
}

dependencies {
    'qb-core',
    'ox_inventory',
    'qb-target'
}