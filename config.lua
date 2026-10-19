Config = {}

Config.requiredCops = 0
Config.nextPedDelay = 5000
Config.pedSpawnDistance = 15.0
Config.pedDespawnTime = 15000
Config.pedStopDistance = 2.0
Config.saleProgressDuration = 6000
Config.pedMoveSpeed = 3.0
Config.saleAmountMin = 1
Config.saleAmountMax = 10
Config.npcFightOnReject = true
Config.account = 'black_money' -- 'black_money' adds the black_money item, 'money' adds Qbox cash
Config.drugs = {
    ['baggy_weed'] = { price = 50, account = 'black_money' },
    ['meth_baggy'] = { price = 30, account = 'black_money' },
    ['cokebaggy'] = { price = 80, account = 'black_money' },
    ['drug_lean'] = { price = 25, account = 'black_money' },
}

-- Players inside a zone receive the configured multiplier on their drug-sale payout.
-- If zones overlap, the highest multiplier is used.
-- Set showBlip = false on an individual zone to hide its map radius.
Config.moneyZones = {
    {
        name = "Starter Pack",
        coords = vector3(-769.89, -988.56, 13.7),
        radius = 100.0,
        multiplier = 2.0,
        showBlip = true,
    },
    {
        name = "Streetlabs",
        coords = vector3(148.11, 181.93, 104.68),
        radius = 50.0,
        multiplier = 2.0,
        showBlip = true,
    },
    {
        name = "The Villas",
        coords = vector3(-1147.98, -221.86, 36.93),
        radius = 50.0,
        multiplier = 2.0,
        showBlip = true,
    },
}

Config.moneyZoneBlip = {
    color = 3,
    alpha = 80,
}

Config.cityPoint = false -- set to false to disable distance check

Config.notify = {
    title = 'Drugs',
    nodrugs = 'You don\'t have any drugs to sell',
    started = 'You started looking for customers',
    stopped = 'Drug selling stopped',
    alreadySelling = 'You are already selling drugs',
    notSelling = 'You are not selling drugs',
    cooldown = 'Please wait some time',
    toofar = 'You\'re too far from the city',
    cops = 'There\'s no cops in the city',
    searching = 'You\'re searching for clients for ',
    abort = 'Client has resigned from the order',
    notfound = 'There\'s no nearby clients',
    approach = 'Your client is approaching',
    found = 'You\'ve found client on ',
    press = 'Press [E] to sell',
    reject = 'This stuff is shitty!',
    vehicle = 'You\'ve to leave vehicle to sell',
    saleProgress = 'Completing drug sale...',
    saleCancelled = 'Drug sale cancelled',
    multiplierZone = 'You are in an active multiplier zone: %s (%sx payout)',
    sold = 'You\'ve sold x%s of %s for %s$',
    client = 'Your client wants to buy x%s %s',
    police_notify_title = 'Police dispatch',
    police_notify_subtitle = 'Drug sale report',
}

Config.pedlist = {
    'ig_abigail', 'csb_abigail', 'u_m_y_abner', 'a_m_m_afriamer_01', 'ig_mp_agent14',
    'csb_mp_agent14', 'csb_agent', 's_f_y_airhostess_01', 's_m_y_airworker', 'u_m_m_aldinapoli',
    'ig_amandatownley', 'cs_amandatownley', 's_m_y_ammucity_01', 's_m_m_ammucountry',
    'ig_andreas', 'cs_andreas', 'csb_anita', 'u_m_y_antonb', 'csb_anton',
    'g_m_m_armboss_01', 'g_m_m_armgoon_01', 'g_m_y_armgoon_02', 'g_m_m_armlieut_01',
    'mp_s_m_armoured_01', 's_m_m_armoured_01', 's_m_m_armoured_02', 's_m_y_armymech_01',
    'ig_ashley', 'cs_ashley', 's_m_y_autopsy_01', 's_m_m_autoshop_01', 's_m_m_autoshop_02',
    'ig_money', 'csb_money', 'g_m_y_azteca_01', 'u_m_y_babyd', 'g_m_y_ballaeast_01',
    'g_m_y_ballaorig_01', 'g_f_y_ballas_01', 'ig_ballasog', 'csb_ballasog',
    'g_m_y_ballasout_01', 'u_m_m_bankman', 'ig_bankman', 'cs_bankman', 's_m_y_barman_01'
}
