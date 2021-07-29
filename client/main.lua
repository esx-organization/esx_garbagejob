ESX = nil

local HasAlreadyEnteredMarker, OnJob, IsDead, CurrentActionData = false
local LastZone, CurrentAction, CurrentActionMsg

local clockedIn, vehicleSpawned = false

local MainBlip, NewDrop, WorkVehicle
local AlbeToGetBags = false
local Blips, CollectionJobs = {}

local CurrentStop = 0

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

  while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end

  ESX.PlayerData = ESX.GetPlayerData()

  local blipSprite = Config.Markers.Cloakroom.Config.sprite;
  local blipDisplay = Config.Markers.Cloakroom.Config.display;
  local blipScale = Config.Markers.Cloakroom.Config.scale;
  local blipColour = Config.Markers.Cloakroom.Config.colour;
  local blipShortRange = Config.Markers.Cloakroom.Config.shortRange;

  if ESX.PlayerData.job.name == Config.JobName then
    MainBlip = AddBlipForCoord(Config.Markers.Cloakroom.Pos)

    SetBlipSprite (MainBlip, blipSprite)
		SetBlipDisplay(MainBlip, blipDisplay)
		SetBlipScale  (MainBlip, blipScale)
		SetBlipColour (MainBlip, blipColour)
		SetBlipAsShortRange(MainBlip, blipShortRange)

		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(_U('job_central'))
		EndTextCommandSetBlipName(MainBlip)
	end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.PlayerData = xPlayer
  TriggerServerEvent('esx_garbagejob:setConfig')
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job
  TriggerEvent('esx_garbagejob:checkJob')
end)

RegisterNetEvent('esx_garbagejob:updateJobs')
AddEventHandler('esx_garbagejob:updateJobs', function(NewJobTable)
	CollectionJobs = NewJobTable
end)

RegisterNetEvent('esx_garbagejob:selectNextJob')
AddEventHandler('esx_garbagejob:selectNextJob', function()
	if CurrentStop < Config.MaxStops then
		SetVehicleDoorShut(work_truck, 5, false)
		SetBlipRoute(Blips['delivery'], false)
		FindDeliveryLocation()
		AlbeToGetBags = false
	else
		NewDrop = nil
		OnCollection = false
		SetVehicleDoorShut(WorkVehicle, 5, false)
		RemoveBlip(Blips['delivery'])
		SetBlipRoute(Blips['endMission'], true)
		AlbeToGetBags = false
		ESX.ShowNotification(_U('return_mission'))
	end
end)

AddEventHandler('esx_garbagejob:hasEnteredMarker', function(zone)
	if zone == 'Cloakroom' then
		CurrentAction     = 'cloakroom'
		CurrentActionMsg  = _U('cloakroom_action')
		CurrentActionData = {}

	-- elseif zone == 'VehicleSpawner' then
	-- 	CurrentAction     = 'vehicle_spawner'
	-- 	CurrentActionMsg  = _U('spawner_action')
	-- 	CurrentActionData = {}
	end
end)

AddEventHandler('esx_garbagejob:hasExitedMarker', function(zone)
	ESX.UI.Menu.CloseAll()
	CurrentAction = nil
end)

function StartGarbageJob()
	if ESX ~= nil and ESX.PlayerData.job.name == Config.JobName then
  	OnJob = true
  	exports.es_extended:showLoadingPrompt(_U('taking_service'), 5000, 3)
	end
	return OnJob
end

function OpenCloakroom()
  ESX.UI.Menu.CloseAll()
	
	local elements = {}

	for i=1, #Config.AuthorizedVehicles, 1 do
		table.insert(elements, {
			label = GetLabelText(GetDisplayNameFromVehicleModel(Config.AuthorizedVehicles[i].model)),
			value = Config.AuthorizedVehicles[i]
		})
	end

  ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'garbage_cloakroom', {
    title = _U('cloakroom_menu'),
    align = 'top-left',
    elements = {
      {label = _U('wear_citizen'), value = 'wear_citizen'},
      {label = _U('wear_garbage'), value = 'wear_garbage'},
      {label = _U('spawn_vehicle'), value = 'vehicle_spawner'},
  }}, function(data, menu)
    if data.current.value == 'wear_citizen' then
			ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
				TriggerEvent('skinchanger:loadSkin', skin)
				clockedIn = false
        exports.es_extended:showLoadingPrompt(_U('retire_service'), 5000, 3)
				
				-- menu.close()
			end)
		elseif data.current.value == 'wear_garbage' then
			ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
				if skin.sex == 0 then
					TriggerEvent('skinchanger:loadClothes', skin, jobSkin.skin_male)
					clockedIn = true
          exports.es_extended:showLoadingPrompt(_U('taking_service'), 5000, 3)

					-- menu.close()
				else
					TriggerEvent('skinchanger:loadClothes', skin, jobSkin.skin_female)
				end
			end)

		elseif data.current.value == 'vehicle_spawner' then
			if Config.EnableSocietyOwnedVehicles then

				ESX.TriggerServerCallback('esx_society:getVehiclesInGarage', function(vehicles)
		
					for i=1, #vehicles, 1 do
						table.insert(elements, {
							label = GetDisplayNameFromVehicleModel(vehicles[i].model) .. ' [' .. vehicles[i].plate .. ']',
							value = vehicles[i]
						})
					end
		
					ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_spawner', {
						title    = _U('vehicle_selection'),
						align    = 'top-left',
						elements = elements
					}, function(data, menu)
						if not ESX.Game.IsSpawnPointClear(Config.Zones.VehicleSpawnPoint.Pos, 5.0) then
							ESX.ShowNotification(_U('spawnpoint_blocked'))
							return
						end
		
						menu.close()
		
						local vehicleProps = data.current.value
						ESX.Game.SpawnVehicle(vehicleProps.model, Config.Zones.VehicleSpawnPoint.Pos, Config.Zones.VehicleSpawnPoint.Heading, function(vehicle)
							ESX.Game.SetVehicleProperties(vehicle, vehicleProps)
							local playerPed = PlayerPedId()
							TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
						end)
		
						TriggerServerEvent('esx_society:removeVehicleFromGarage', 'trash', vehicleProps)
					end, function(data, menu)
						CurrentAction     = 'vehicle_spawner'
						CurrentActionMsg  = _U('spawner_prompt')
						CurrentActionData = {}
		
						menu.close()
					end)
				end, 'trash')
		
			else -- not society vehicles
		
				ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_spawner', {
					title    = _U('vehicle_selection'),
					align    = 'top-left',
					elements = Config.AuthorizedVehicles
				}, function(data, menu)
					if not ESX.Game.IsSpawnPointClear(Config.Zones.VehicleSpawnPoint.Pos, 5.0) then
						ESX.ShowNotification(_U('spawnpoint_blocked'))
						return
					end
		
					menu.close()

					ESX.Game.SpawnVehicle(data.current.model, Config.Zones.VehicleSpawnPoint.Pos, Config.Zones.VehicleSpawnPoint.Heading, function(vehicle)
						local playerPed = PlayerPedId()
						TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
					end)
				end)
			end
			menu.close()
		end
	end, function(data, menu)
		menu.close()

		CurrentAction     = 'cloakroom'
		CurrentActionMsg  = _U('cloakroom_action')
		CurrentActionData = {}
	end)
end

-- function OpenVehicleSpawnerMenu()
-- 	ESX.UI.Menu.CloseAll()

-- 	local elements = {}

-- 	if Config.EnableSocietyOwnedVehicles then

-- 		ESX.TriggerServerCallback('esx_society:getVehiclesInGarage', function(vehicles)

-- 			for i=1, #vehicles, 1 do
-- 				table.insert(elements, {
-- 					label = GetDisplayNameFromVehicleModel(vehicles[i].model) .. ' [' .. vehicles[i].plate .. ']',
-- 					value = vehicles[i]
-- 				})
-- 			end

-- 			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_spawner', {
-- 				title    = _U('vehicle_selection'),
-- 				align    = 'top-left',
-- 				elements = elements
-- 			}, function(data, menu)
-- 				if not ESX.Game.IsSpawnPointClear(Config.Zones.VehicleSpawnPoint.Pos, 5.0) then
-- 					ESX.ShowNotification(_U('spawnpoint_blocked'))
-- 					return
-- 				end

-- 				menu.close()

-- 				local vehicleProps = data.current.value
-- 				ESX.Game.SpawnVehicle(vehicleProps.model, Config.Zones.VehicleSpawnPoint.Pos, Config.Zones.VehicleSpawnPoint.Heading, function(vehicle)
-- 					ESX.Game.SetVehicleProperties(vehicle, vehicleProps)
-- 					local playerPed = PlayerPedId()
-- 					TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
-- 				end)

-- 				TriggerServerEvent('esx_society:removeVehicleFromGarage', 'trash', vehicleProps)
-- 			end, function(data, menu)
-- 				CurrentAction     = 'vehicle_spawner'
-- 				CurrentActionMsg  = _U('spawner_prompt')
-- 				CurrentActionData = {}

-- 				menu.close()
-- 			end)
-- 		end, 'trash')

-- 	else -- not society vehicles

-- 		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_spawner', {
-- 			title    = _U('vehicle_selection'),
-- 			align    = 'top-left',
-- 			elements = Config.AuthorizedVehicles
-- 		}, function(data, menu)
-- 			if not ESX.Game.IsSpawnPointClear(Config.Zones.VehicleSpawnPoint.Pos, 5.0) then
-- 				ESX.ShowNotification(_U('spawnpoint_blocked'))
-- 				return
-- 			end

-- 			menu.close()
-- 			ESX.Game.SpawnVehicle(data.current.model, Config.Zones.VehicleSpawnPoint.Pos, Config.Zones.VehicleSpawnPoint.Heading, function(vehicle)
-- 				local playerPed = PlayerPedId()
-- 				TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
-- 			end)
-- 		end, function(data, menu)
-- 			CurrentAction     = 'vehicle_spawner'
-- 			CurrentActionMsg  = _U('spawner_prompt')
-- 			CurrentActionData = {}

-- 			menu.close()
-- 		end)
-- 	end
-- end

-- Enter / Exit marker events, and draw markers
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if ESX.PlayerData.job and ESX.PlayerData.job.name == Config.JobName then
			local coords = GetEntityCoords(PlayerPedId())
			local isInMarker, letSleep, currentZone = false, true

			for k,v in pairs(Config.Zones) do
				local distance = GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true)

				if v.Type ~= -1 and distance < Config.DrawDistance then
					letSleep = false
					DrawMarker(v.Type, v.Pos.x, v.Pos.y, v.Pos.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, v.Size.x, v.Size.y, v.Size.z, v.Color.r, v.Color.g, v.Color.b, 100, false, false, 2, v.Rotate, nil, nil, false)
				end

				if distance < v.Size.x then
					isInMarker, currentZone = true, k
				end
			end

			if (isInMarker and not HasAlreadyEnteredMarker) or (isInMarker and LastZone ~= currentZone) then
				HasAlreadyEnteredMarker, LastZone = true, currentZone
				TriggerEvent('esx_garbagejob:hasEnteredMarker', currentZone)
			end

			if not isInMarker and HasAlreadyEnteredMarker then
				HasAlreadyEnteredMarker = false
				TriggerEvent('esx_garbagejob:hasExitedMarker', LastZone)
			end

			if letSleep then
				Citizen.Wait(500)
			end
		else
			Citizen.Wait(1000)
		end
	end
end)

-- Key Controls
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if CurrentAction and not IsDead then
			ESX.ShowHelpNotification(CurrentActionMsg)

			if IsControlJustReleased(0, 38) and ESX.PlayerData.job and ESX.PlayerData.job.name == Config.JobName then
				if CurrentAction == 'cloakroom' then
					OpenCloakroom()
				-- elseif CurrentAction == 'vehicle_spawner' and clockedIn and not vehicleSpawned then
				-- 	OpenVehicleSpawnerMenu()
				end

				CurrentAction = nil
			end
		end
	end
end)

AddEventHandler('esx:onPlayerDeath', function()
	IsDead = true
end)

AddEventHandler('playerSpawned', function(spawn)
	IsDead = false
end)