fx_version 'cerulean'
game 'gta5'

author 'Ghost Developments'
description 'Official Trouble Some Rp Drug Selling'
version '1.0.1'

shared_script '@ox_lib/init.lua'
shared_script 'config.lua'

client_script 'client.lua'

server_script 'server.lua'

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_inventory'
}
