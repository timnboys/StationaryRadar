RegisterNetEvent('setRadar')
RegisterNetEvent('loadRadars')

local speedcams = {};
local maxSpeedKmh = 1;
local maxSpeedMph = 10;

-----------------------------------------------------------------------
---------------------Events--------------------------------------------
-----------------------------------------------------------------------

-- Loads Radars into the client
AddEventHandler('loadRadars', function(array)
    speedcams[array] = 0 -- player has not been busted by cam
end)

-- Manually set Radar
AddEventHandler('setRadar', function(array)
    local currentPos = GetEntityCoords(GetPlayerPed(-1));
    x, y, z = table.unpack(currentPos)
    speedcams[currentPos] = 0;
    TriggerServerEvent("saveRadarPosition", x, y, z);
end)

-- Reguest to get all Radars
AddEventHandler("playerSpawned", function()
    TriggerServerEvent("getRadars");
end)

-----------------------------------------------------------------------
---------------------Functions-----------------------------------------
-----------------------------------------------------------------------

-- Determines if player broke speed and message should be triggered
function SpeedBreak(speedcam, hasBeenFucked, speed, name, numberplate)
    if speed >= maxSpeedKmh then
        if hasBeenFucked == 0 then
            speedcams[speedcam] = 1 -- player got busted by cam
            local streethash = GetStreetNameAtCoord(speedcam['x'], speedcam['y'], speedcam['z']);
            local streetname = GetStreetNameFromHashKey(streethash);
            local info = string.format("%s | %s mph / %s km/h", numberplate, math.ceil(speed*2.236936), math.ceil(speed*3.6));

            -- todo add vehicle name
            local text = string.format("%s | %s | %s mph / %s km/h @ %s", name, numberplate, math.ceil(speed*2.236936), math.ceil(speed*3.6), streetname);
            TriggerEvent("chatMessage", "[Speedcam]", { 255,0,0}, text);
        end
    end
end

-- Determines if player is close enough to trigger cam
function HandleSpeedcam(speedcam, hasBeenFucked)
    local playerPos = GetEntityCoords(GetPlayerPed(-1));

    -- Sets radius in which speeding gets triggered
    local x1 = playerPos['x'] - speedcam['x'];
    local x2 = speedcam['x'] - playerPos['x'];
    local y1 = playerPos['y'] - speedcam['y'];
    local y2 = speedcam['y'] - playerPos['y'];
    local range = 20;

    if y1 <= range 
        and y2 <= range 
        and x1 <= range 
        and x2 <= range 
    then 
        local vehicle = GetPlayersLastVehicle() -- gets the current vehicle the player is in.
        if vehicle ~=nil then
            local numberplate = GetVehicleNumberPlateText(vehicle);
            local name = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle));
            SpeedBreak(speedcam, hasBeenFucked, GetEntitySpeed(vehicle), name, numberplate);
        end
    else
        speedcams[speedcam] = 0;
    end
end

-----------------------------------------------------------------------
---------------------Threads-------------------------------------------
-----------------------------------------------------------------------

-- Thread to loop speedcams
Citizen.CreateThread(function()
    while true do
        Wait(0);
        for key, value in pairs(speedcams) do
            --TriggerEvent("chatMessage", "[System]", { 255,0,0}, "Radar set at".." x: "..key..value)
            HandleSpeedcam(key, value);
        end
    end  
end)