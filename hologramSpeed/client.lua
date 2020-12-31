local DuiEntity
local DuiTxd
local DuiObj
local DuiHandle
local DuiLoaded = false
local Enabled = true
local IsDuiDisplayed = false
local carRPM, carSpeed, carGear, carIL, carAcceleration, carHandbrake, carBrakePressure, carBrakeAbs, carLS_r, carLS_o, carLS_h
local Profile
local ProfileInitialized = false

Citizen.CreateThread(function()
	InitProfile()
end)

Citizen.CreateThread(function()
	while ProfileInitialized == false do
		Citizen.Wait(100)
	end
	while true do
		Citizen.Wait(0)
		if Enabled then
			if IsPedInAnyVehicle(GetPlayerPed(-1), false) then
				if IsDuiDisplayed then
					UpdateDui()
				else
					DisplayDui()
					IsDuiDisplayed = true
				end
			else
				if IsDuiDisplayed then
					HideDui()
					IsDuiDisplayed = false
				end
			end
		else
			HideDui()
			IsDuiDisplayed = false
		end
	end
end)

Citizen.CreateThread(function()
	while ProfileInitialized == false do
		Citizen.Wait(100)
	end
	while true do
		Citizen.Wait(0)
		if IsControlJustPressed(0, Profile.keyControl) then
			Enabled = not Enabled
			local CurrentStatus = Enabled and "^2On^0" or "^1Off^0"
			SendChatMessage("Your speedometer has been switched to " .. CurrentStatus)
		end
	end
end)

RegisterCommand('hsp', function(source, args)
	local cmd = args[1] or ''
	if cmd == 'mph' then
		Profile.useMph = not Profile.useMph
		SetPlayerProfile(Profile)
		local CurrentUnit = Profile.useMph and "^2MPH^0" or "^2KPH^0"
		SendChatMessage("Your speed unit has been switched to " .. CurrentUnit .. ", please restart your game to take effect")
	elseif cmd == 'nve' then
		Profile.useNve = not Profile.useNve
		SetPlayerProfile(Profile)
		local CurrentNve = Profile.useNve and "^2On^0" or "^1Off^0"
		SendChatMessage("Your NVE graphic mods has been switched to " .. CurrentNve .. ", please restart your game to take effect")
	else
		Enabled = not Enabled
		local CurrentStatus = Enabled and "^2On^0" or "^1Off^0"
		SendChatMessage("Your speedometer has been switched to " .. CurrentStatus)
	end
end, false)

function SendChatMessage(data)
	TriggerEvent('chat:addMessage', {
		args = { data }
	})
end

function InitProfile()
	Profile = GetPlayerProfile()
	if Profile.unit == nil then
		Profile.unit = Config.unit
	end
	if Profile.keyControl == nil then
		Profile.keyControl = Config.keyControl
	end
	if Profile.useNve == nil then
		Profile.useNve = Config.useNve
	end
	SetPlayerProfile(Profile)
	ProfileInitialized = true
end

function CreateHologramDui()
	print("Loading " .. Config.duiUrl)
	local urlHash = "#"
	local jsonTemp = {}
	if Profile.useMph then
		jsonTemp.unit = "MPH"
	else
		jsonTemp.unit = "KPH"
	end
	if Profile.useNve then
		jsonTemp.nve = true
	else
		jsonTemp.nve = false
	end
	urlHash = urlHash .. json.encode(jsonTemp)
	DuiTxd = CreateRuntimeTxd('DuiHologramTxd')
	DuiObj = CreateDui(Config.duiUrl .. urlHash, 512, 512)
	while not IsDuiAvailable(DuiObj) do
		Wait(100)
	end
	print("Successful create Dui")
	_G.DuiObj = DuiObj
	DuiHandle = GetDuiHandle(DuiObj)
	local tx5 = CreateRuntimeTextureFromDuiHandle(DuiTxd, 'DuiTexture', DuiHandle)
	print("Replace textures...")
	AddReplaceTexture('hologram_box_model', 'p_hologram_box', 'DuiHologramTxd', 'DuiTexture')
end

function DestroyHologramDui()
	DestroyDui(DuiObj)
end

function UpdateDui()
	
	if not DoesEntityExist(DuiEntity) then
		DisplayDui()
	end
	
	playerPed = GetPlayerPed(-1)
		
	if playerPed and IsDuiDisplayed then
		
		playerCar = GetVehiclePedIsIn(playerPed, false)
		
		if playerCar and GetPedInVehicleSeat(playerCar, -1) == playerPed then
			
			local NcarRPM                      = GetVehicleCurrentRpm(playerCar)
			local NcarSpeed                    = GetEntitySpeed(playerCar)
			local NcarGear                     = GetVehicleCurrentGear(playerCar)
			local NcarIL                       = GetVehicleIndicatorLights(playerCar)
			local NcarAcceleration             = IsControlPressed(0, 71)
			local NcarHandbrake                = GetVehicleHandbrake(playerCar)
			local NcarBrakePressure            = GetVehicleWheelBrakePressure(playerCar, 0)
			local NcarBrakeAbs                 = (GetVehicleWheelSpeed(playerCar, 0) == 0.0 and NcarSpeed > 0.0)
			local NcarLS_r, NcarLS_o, NcarLS_h = GetVehicleLightsState(playerCar)
			
			local shouldUpdate = false
			
			if NcarRPM ~= carRPM then
				shouldUpdate = true
			end
			if NcarSpeed ~= carSpeed then
				shouldUpdate = true
			end
			if NcarGear ~= carGear then
				shouldUpdate = true
			end
			if NcarIL ~= carIL then
				shouldUpdate = true
			end
			if NcarAcceleration ~= carAcceleration then
				shouldUpdate = true
			end
			if NcarHandbrake ~= carHandbrake then
				shouldUpdate = true
			end
			if NcarBrakePressure ~= carBrakePressure then
				shouldUpdate = true
			end
			if NcarBrakeAbs ~= carBrakeAbs then
				shouldUpdate = true
			end
			if NcarLS_r ~= carLS_r then
				shouldUpdate = true
			end
			if NcarLS_o ~= carLS_o then
				shouldUpdate = true
			end
			if NcarLS_h ~= carLS_h then
				shouldUpdate = true
			end
			
			if shouldUpdate then
				carRPM           = NcarRPM
				carGear          = NcarGear
				carSpeed         = NcarSpeed
				carIL            = NcarIL
				carAcceleration  = NcarAcceleration
				carHandbrake     = NcarHandbrake
				carBrakePressure = NcarBrakePressure
				carBrakeAbs      = NcarBrakeAbs
				carLS_r          = NcarLS_r
				carLS_o          = NcarLS_o
				carLS_h          = NcarLS_h
				
				if Profile.useMph then
					carCalcSpeed = math.ceil(carSpeed * 2.236936)
				else
					carCalcSpeed = math.ceil(carSpeed * 3.6)
				end
				
				SendDuiMessage(DuiObj, json.encode({
					ShowHud                = true,
					CurrentCarRPM          = carRPM,
					CurrentCarGear         = carGear,
					CurrentCarSpeed        = carCalcSpeed,
					CurrentCarIL           = carIL,
					CurrentCarAcceleration = carAcceleration,
					CurrentCarHandbrake    = carHandbrake,
					CurrentCarBrake        = carBrakePressure,
					CurrentCarAbs          = carBrakeAbs,
					CurrentCarLS_r         = carLS_r,
					CurrentCarLS_o         = carLS_o,
					CurrentCarLS_h         = carLS_h,
					PlayerID               = GetPlayerServerId(GetPlayerIndex())
				}))
			end
		elseif IsDuiDisplayed then
			SendDuiMessage(DuiObj, json.encode({HideHud = true}))
		end
		
		Wait(50)
	end
end

function HideDui()
	SetEntityAsNoLongerNeeded(DuiEntity)
	DeleteVehicle(DuiEntity)
	DeleteEntity(DuiEntity)
end

function DisplayDui()
	if not IsModelInCdimage(Config.modelName) or not IsModelAVehicle(Config.modelName) then
        TriggerEvent('chat:addMessage', {
            args = { 'Cannot find the model "' .. Config.modelName .. '", please make sure you install the plugin correctly' }
        })
        return
    end
	print("Creating model...")
    RequestModel(Config.modelName)
    while not HasModelLoaded(Config.modelName) do
        Citizen.Wait(500)
    end
	local pos       = GetEntityCoords(GetPlayerPed(-1))
	local playerCar = GetVehiclePedIsIn(GetPlayerPed(-1))
    DuiEntity = CreateVehicle(Config.modelName, pos.x, pos.y, pos.z, GetEntityHeading(GetPlayerPed(-1)), false, false)
	print("Setting entity status...")
	SetVehicleEngineOn(DuiEntity, true, true)
	SetVehicleDoorsLockedForAllPlayers(DuiEntity, true)
	print("Attach to entity...")
	local EntityBone = GetEntityBoneIndexByName(playerCar, "chassis")
	local BindPos = {x = 2.5, y = -1.0, z = 0.85}
	AttachEntityToEntity(DuiEntity, playerCar, EntityBone, BindPos.x, BindPos.y, BindPos.z, 0.0, 0.0, -15.0, false, false, false, false, false, true)
	Citizen.Wait(200)
	if not DuiLoaded then
		print("Creating Dui...")
		CreateHologramDui()
		DuiLoaded = true
	end
end

function GetPlayerProfile()
	local kvpData = GetResourceKvpString("HologramProfile")
	if kvpData ~= nil then
		return json.decode(kvpData)
	else
		return {}
	end
end

function SetPlayerProfile(data)
	SetResourceKvp("HologramProfile", json.encode(data))
end




----- NEW 
-- SCREEN POSITION PARAMETERS
local screenPosX = 0.165                    -- X coordinate (top left corner of HUD)
local screenPosY = 0.882                    -- Y coordinate (top left corner of HUD)

-- GENERAL PARAMETERS
local enableController = true               -- Enable controller inputs

-- SPEEDOMETER PARAMETERS
local speedLimit = 100.0                    -- Speed limit for changing speed color
local speedColorText = {255, 255, 255}      -- Color used to display speed label text
local speedColorUnder = {255, 255, 255}     -- Color used to display speed when under speedLimit
local speedColorOver = {255, 96, 96}        -- Color used to display speed when over speedLimit

-- FUEL PARAMETERS
local fuelShowPercentage = false             -- Show fuel as a percentage (disabled shows fuel in liters)
local fuelWarnLimit = 25.0                  -- Fuel limit for triggering warning color
local fuelColorText = {255, 255, 255}       -- Color used to display fuel text
local fuelColorOver = {255, 255, 255}       -- Color used to display fuel when good
local fuelColorUnder = {255, 96, 96}        -- Color used to display fuel warning

-- SEATBELT PARAMETERS
local seatbeltInput = 311                   -- Toggle seatbelt on/off with K or DPAD down (controller)
local seatbeltPlaySound = true              -- Play seatbelt sound
local seatbeltDisableExit = true            -- Disable vehicle exit when seatbelt is enabled
local seatbeltEjectSpeed = 45.0             -- Speed threshold to eject player (MPH)
local seatbeltEjectAccel = 100.0            -- Acceleration threshold to eject player (G's)
local seatbeltColorOn = {160, 255, 160}     -- Color used when seatbelt is on
local seatbeltColorOff = {255, 96, 96}      -- Color used when seatbelt is off

-- CRUISE CONTROL PARAMETERS
local cruiseInput = 137                     -- Toggle cruise on/off with CAPSLOCK or A button (controller)
local cruiseColorOn = {160, 255, 160}       -- Color used when seatbelt is on
local cruiseColorOff = {255, 255, 255}      -- Color used when seatbelt is off

-- LOCATION AND TIME PARAMETERS
local locationAlwaysOn = false              -- Always display location and time
local locationColorText = {255, 255, 255}   -- Color used to display location and time

-- Lookup tables for direction and zone
local directions = { [0] = 'N', [1] = 'NW', [2] = 'W', [3] = 'SW', [4] = 'S', [5] = 'SE', [6] = 'E', [7] = 'NE', [8] = 'N' } 
local zones = { ['AIRP'] = "Los Santos International Airport", ['ALAMO'] = "Alamo Sea", ['ALTA'] = "Alta", ['ARMYB'] = "Fort Zancudo", ['BANHAMC'] = "Banham Canyon Dr", ['BANNING'] = "Banning", ['BEACH'] = "Vespucci Beach", ['BHAMCA'] = "Banham Canyon", ['BRADP'] = "Braddock Pass", ['BRADT'] = "Braddock Tunnel", ['BURTON'] = "Burton", ['CALAFB'] = "Calafia Bridge", ['CANNY'] = "Raton Canyon", ['CCREAK'] = "Cassidy Creek", ['CHAMH'] = "Chamberlain Hills", ['CHIL'] = "Vinewood Hills", ['CHU'] = "Chumash", ['CMSW'] = "Chiliad Mountain State Wilderness", ['CYPRE'] = "Cypress Flats", ['DAVIS'] = "Davis", ['DELBE'] = "Del Perro Beach", ['DELPE'] = "Del Perro", ['DELSOL'] = "La Puerta", ['DESRT'] = "Grand Senora Desert", ['DOWNT'] = "Downtown", ['DTVINE'] = "Downtown Vinewood", ['EAST_V'] = "East Vinewood", ['EBURO'] = "El Burro Heights", ['ELGORL'] = "El Gordo Lighthouse", ['ELYSIAN'] = "Elysian Island", ['GALFISH'] = "Galilee", ['GOLF'] = "GWC and Golfing Society", ['GRAPES'] = "Grapeseed", ['GREATC'] = "Great Chaparral", ['HARMO'] = "Harmony", ['HAWICK'] = "Hawick", ['HORS'] = "Vinewood Racetrack", ['HUMLAB'] = "Humane Labs and Research", ['JAIL'] = "Bolingbroke Penitentiary", ['KOREAT'] = "Little Seoul", ['LACT'] = "Land Act Reservoir", ['LAGO'] = "Lago Zancudo", ['LDAM'] = "Land Act Dam", ['LEGSQU'] = "Legion Square", ['LMESA'] = "La Mesa", ['LOSPUER'] = "La Puerta", ['MIRR'] = "Mirror Park", ['MORN'] = "Morningwood", ['MOVIE'] = "Richards Majestic", ['MTCHIL'] = "Mount Chiliad", ['MTGORDO'] = "Mount Gordo", ['MTJOSE'] = "Mount Josiah", ['MURRI'] = "Murrieta Heights", ['NCHU'] = "North Chumash", ['NOOSE'] = "N.O.O.S.E", ['OCEANA'] = "Pacific Ocean", ['PALCOV'] = "Paleto Cove", ['PALETO'] = "Paleto Bay", ['PALFOR'] = "Paleto Forest", ['PALHIGH'] = "Palomino Highlands", ['PALMPOW'] = "Palmer-Taylor Power Station", ['PBLUFF'] = "Pacific Bluffs", ['PBOX'] = "Pillbox Hill", ['PROCOB'] = "Procopio Beach", ['RANCHO'] = "Rancho", ['RGLEN'] = "Richman Glen", ['RICHM'] = "Richman", ['ROCKF'] = "Rockford Hills", ['RTRAK'] = "Redwood Lights Track", ['SANAND'] = "San Andreas", ['SANCHIA'] = "San Chianski Mountain Range", ['SANDY'] = "Sandy Shores", ['SKID'] = "Mission Row", ['SLAB'] = "Stab City", ['STAD'] = "Maze Bank Arena", ['STRAW'] = "Strawberry", ['TATAMO'] = "Tataviam Mountains", ['TERMINA'] = "Terminal", ['TEXTI'] = "Textile City", ['TONGVAH'] = "Tongva Hills", ['TONGVAV'] = "Tongva Valley", ['VCANA'] = "Vespucci Canals", ['VESP'] = "Vespucci", ['VINE'] = "Vinewood", ['WINDF'] = "Ron Alternates Wind Farm", ['WVINE'] = "West Vinewood", ['ZANCUDO'] = "Zancudo River", ['ZP_ORT'] = "Port of South Los Santos", ['ZQ_UAR'] = "Davis Quartz" }

-- Globals
local pedInVeh = false
local timeText = ""
local locationText = ""
local currentFuel = 0.0

-- Main thread
Citizen.CreateThread(function()
    -- Initialize local variable
    local currSpeed = 0.0
    local cruiseSpeed = 999.0
    local prevVelocity = {x = 0.0, y = 0.0, z = 0.0}
    local cruiseIsOn = false
    local seatbeltIsOn = false

    while true do
        -- Loop forever and update HUD every frame
        Citizen.Wait(0)

        -- Get player PED, position and vehicle and save to locals
        local player = GetPlayerPed(-1)
        local position = GetEntityCoords(player)
        local vehicle = GetVehiclePedIsIn(player, false)

        -- Set vehicle states
        if IsPedInAnyVehicle(player, false) then
            pedInVeh = true
        else
            -- Reset states when not in car
            pedInVeh = false
            cruiseIsOn = false
            seatbeltIsOn = false
        end
        
        -- Display Location and time when in any vehicle or on foot (if enabled)
        if pedInVeh or locationAlwaysOn then
            -- Get time and display
            drawTxt(timeText, 4, locationColorText, 0.4, screenPosX, screenPosY + 0.048)
            
            -- Display heading, street name and zone when possible
            drawTxt(locationText, 4, locationColorText, 0.5, screenPosX, screenPosY + 0.075)
        
            -- Display remainder of HUD when engine is on and vehicle is not a bicycle
            local vehicleClass = GetVehicleClass(vehicle)
            if pedInVeh and GetIsVehicleEngineRunning(vehicle) and vehicleClass ~= 13 then
                -- Save previous speed and get current speed
                local prevSpeed = currSpeed
                currSpeed = GetEntitySpeed(vehicle)

                -- Set PED flags
                SetPedConfigFlag(PlayerPedId(), 32, true)
                
                -- Check if seatbelt button pressed, toggle state and handle seatbelt logic
                if IsControlJustReleased(0, seatbeltInput) and (enableController or GetLastInputMethod(0)) and vehicleClass ~= 8 then
                    -- Toggle seatbelt status and play sound when enabled
                    seatbeltIsOn = not seatbeltIsOn
                    if seatbeltPlaySound then
                        PlaySoundFrontend(-1, "Faster_Click", "RESPAWN_ONLINE_SOUNDSET", 1)
                    end
                end
                if not seatbeltIsOn then
                    -- Eject PED when moving forward, vehicle was going over 45 MPH and acceleration over 100 G's
                    local vehIsMovingFwd = GetEntitySpeedVector(vehicle, true).y > 1.0
                    local vehAcc = (prevSpeed - currSpeed) / GetFrameTime()
                    if (vehIsMovingFwd and (prevSpeed > (seatbeltEjectSpeed/2.237)) and (vehAcc > (seatbeltEjectAccel*9.81))) then
                        SetEntityCoords(player, position.x, position.y, position.z - 0.47, true, true, true)
                        SetEntityVelocity(player, prevVelocity.x, prevVelocity.y, prevVelocity.z)
                        Citizen.Wait(1)
                        SetPedToRagdoll(player, 1000, 1000, 0, 0, 0, 0)
                    else
                        -- Update previous velocity for ejecting player
                        prevVelocity = GetEntityVelocity(vehicle)
                    end
                elseif seatbeltDisableExit then
                    -- Disable vehicle exit when seatbelt is on
                    DisableControlAction(0, 75)
                end

                -- When player in driver seat, handle cruise control
                if (GetPedInVehicleSeat(vehicle, -1) == player) then
                    -- Check if cruise control button pressed, toggle state and set maximum speed appropriately
                    if IsControlJustReleased(0, cruiseInput) and (enableController or GetLastInputMethod(0)) then
                        cruiseIsOn = not cruiseIsOn
                        cruiseSpeed = currSpeed
                    end
                    local maxSpeed = cruiseIsOn and cruiseSpeed or GetVehicleHandlingFloat(vehicle,"CHandlingData","fInitialDriveMaxFlatVel")
                    SetEntityMaxSpeed(vehicle, maxSpeed)
                else
                    -- Reset cruise control
                    cruiseIsOn = false
                end
--[[
                -- Check what units should be used for speed
                if ShouldUseMetricMeasurements() then
                    -- Get vehicle speed in KPH and draw speedometer
                    local speed = currSpeed*3.6
                    local speedColor = (speed >= speedLimit) and speedColorOver or speedColorUnder
                    drawTxt(("%.3d"):format(math.ceil(speed)), 2, speedColor, 0.8, screenPosX + 0.000, screenPosY + 0.000)
                    drawTxt("KPH", 2, speedColorText, 0.4, screenPosX + 0.030, screenPosY + 0.018)
                else
                    -- Get vehicle speed in MPH and draw speedometer
                    local speed = currSpeed*2.23694
                    local speedColor = (speed >= speedLimit) and speedColorOver or speedColorUnder
                    drawTxt(("%.3d"):format(math.ceil(speed)), 2, speedColor, 0.8, screenPosX + 0.000, screenPosY + 0.000)
                    drawTxt("MPH", 2, speedColorText, 0.4, screenPosX + 0.030, screenPosY + 0.018)
                end
                
                -- Draw fuel gauge
                local fuelColor = (currentFuel >= fuelWarnLimit) and fuelColorOver or fuelColorUnder
                drawTxt(("%.3d"):format(math.ceil(currentFuel)), 2, fuelColor, 0.8, screenPosX + 0.055, screenPosY + 0.000)
                drawTxt("FUEL", 2, fuelColorText, 0.4, screenPosX + 0.085, screenPosY + 0.018)
]]--
                -- Draw cruise control status
                local cruiseColor = cruiseIsOn and cruiseColorOn or cruiseColorOff
                drawTxt("CRUISE", 2, cruiseColor, 0.4, screenPosX + 0.040, screenPosY + 0.048)

                -- Draw seatbelt status if not a motorcyle
         --       if vehicleClass ~= 8 then
        --            local seatbeltColor = seatbeltIsOn and seatbeltColorOn or seatbeltColorOff
           --         drawTxt("SEATBELT", 2, seatbeltColor, 0.4, screenPosX + 0.080, screenPosY + 0.048)
          --      end
            end
        end
    end
end)

-- Secondary thread to update strings
Citizen.CreateThread(function()
    while true do
        -- Update when player is in a vehicle or on foot (if enabled)
        if pedInVeh or locationAlwaysOn then
            -- Get player, position and vehicle
            local player = GetPlayerPed(-1)
            local position = GetEntityCoords(player)

            -- Update time text string
            local hour = GetClockHours()
            local minute = GetClockMinutes()
            timeText = ("%.2d"):format((hour == 0) and 12 or hour) .. ":" .. ("%.2d"):format( minute) .. ((hour < 12) and " AM" or " PM")

            -- Get heading and zone from lookup tables and street name from hash
            local heading = directions[math.floor((GetEntityHeading(player) + 22.5) / 45.0)]
            local zoneNameFull = zones[GetNameOfZone(position.x, position.y, position.z)]
            local streetName = GetStreetNameFromHashKey(GetStreetNameAtCoord(position.x, position.y, position.z))
            
            -- Update location text string
            locationText = heading
            locationText = (streetName == "" or streetName == nil) and (locationText) or (locationText .. " | " .. streetName)
            locationText = (zoneNameFull == "" or zoneNameFull == nil) and (locationText) or (locationText .. " | " .. zoneNameFull)

            -- Update fuel when in a vehicle
            if pedInVeh then
                local vehicle = GetVehiclePedIsIn(player, false)
                if fuelShowPercentage then
                    -- Display remaining fuel as a percentage
                    currentFuel = 100 * GetVehicleFuelLevel(vehicle) / GetVehicleHandlingFloat(vehicle,"CHandlingData","fPetrolTankVolume")
                else
                    -- Display remainign fuel in liters
                    currentFuel = GetVehicleFuelLevel(vehicle)
                end
            end

            -- Update every second
            Citizen.Wait(1000)
        else
            -- Wait until next frame
            Citizen.Wait(0)
        end
    end
end)

-- Helper function to draw text to screen
function drawTxt(content, font, colour, scale, x, y)
    SetTextFont(font)
    SetTextScale(scale, scale)
    SetTextColour(colour[1],colour[2],colour[3], 255)
    SetTextEntry("STRING")
    SetTextDropShadow(0, 0, 0, 0,255)
    SetTextDropShadow()
    SetTextEdge(4, 0, 0, 0, 255)
    SetTextOutline()
    AddTextComponentString(content)
    DrawText(x, y)
end

