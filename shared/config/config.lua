Config = {}

Config.Locale = 'br' -- The language you want to use for your server.

Config.DrawDistance = 100

-- Config.TruckPlateNumb = 0

Config.MaxStops = 10 -- Total number of stops a person is allowed to do before having to return to the depot.
Config.MaxBags = 10 -- Total number of bags a person can get out of a bin.
Config.MinBags = 4 -- Min number of bags that a bin can contain.
Config.BagPay = 50 -- The amount paid to each person per bag.
Config.StopPay = 200 -- Total pay for the stop before bagpay.

-- Config.EnableSocietyOwnedVehicles = false -- Disabled...

Config.JobName = 'lixeiro' -- Use this to set the jobname that you want to be able to do garbagecrew.


-- List with all the authorized vehicles that a person can use to work.
Config.AuthorizedVehicles = {
  {model = 'trash', label = 'Caminhão de Lixo'}
}

-- List with all the dumpsters hashes, avaiables to work.
Config.AvaiableDumpsters = {
  218085040,
  666561306,
  -58485588,
  -206690185,
  1511880420,
  682791951,
  -387405094,
  364445978,
  1605769687,
  -1831107703,
  -515278816,
  -1790177567,
}

-- List with all the blips/zones in the job.
Config.Zones = {

	Cloakroom = {
		Pos     = {x = -321.62, y = -1545.82, z = 30.02},
		Size    = {x = 2.0, y = 2.0, z = 1.0},
		Color   = {r = 204, g = 204, b = 0},
		Type    = 1, Rotate = false
	},

	VehicleSpawnPoint = {
		Pos     = {x = -316.87, y = -1538.25, z = 27.66},
		Size    = {x = 1.5, y = 1.5, z = 1.0},
		Type    = -1, Rotate = false,
		Heading = 341.69
	},

	VehicleDeleter = {
		Pos   = {x = 908.317, y = -183.070, z = 73.201},
		Size  = {x = 3.0, y = 3.0, z = 0.25},
		Color = {r = 255, g = 0, b = 0},
		Type  = 1, Rotate = false
	}

	-- VehicleSpawner = {
	-- 	Pos   = {x = -319.22, y = -1546.36, z = 26.78},
	-- 	Size  = {x = 2.0, y = 2.0, z = 1.0},
	-- 	Color = {r = 204, g = 204, b = 0},
	-- 	Type  = 1, Rotate = false
	-- },
}

-- List with all the marks that are going to show in the player map.
Config.Markers = {

	Cloakroom = {
		Pos = vector3(-321.62,-1545.82,31.02),
		Config = {sprite = 318, display = 4, scale = 1.2, colour = 4, shortRange = true}
	},

	-- VehicleSpawner = {
	-- 	Pos = vector3(-319.22,-1546.36,26.78),
	-- 	Config = {sprite = 318, display = 4, scale = 1.2, colour = 4, shortRange = true}
	-- },
}