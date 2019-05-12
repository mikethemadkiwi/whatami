_c = {
    top = 1000,
    mid = 750,
    low = 600
}
viewDist = 1
cObj = ""
cDist = 0
mod = 0
whatami = ""
showstate = 0
showObjs = false
showPickups = false
showVehicles = false
showPeds = false
objList = {}
------------------------------------------------------------------------------
drawOnScreen3D = function(coords, text, size)
  local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
  local camCoords      = GetGameplayCamCoords()
  local dist           = GetDistanceBetweenCoords(camCoords.x, camCoords.y, camCoords.z, coords.x, coords.y, coords.z, 1)
  local size           = size

  if size == nil then
    size = 1
  end

  local scale = (size / dist) * 2
  local fov   = (1 / GetGameplayCamFov()) * 100
  local scale = scale * fov

  if onScreen then

    SetTextScale(0.0 * scale, 0.55 * scale)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry('STRING')
    SetTextCentre(1)

    AddTextComponentString(text)

    DrawText(x, y)
  end

end

drawOnScreen2D = function(text, r, g, b, a, x, y, scale)
	SetTextFont(4)
	SetTextProportional(1)
	SetTextScale(scale, scale)
	SetTextColour(r, g, b, a)
	SetTextDropShadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()

	BeginTextCommandDisplayText("STRING")
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandDisplayText(x, y)
end

function GetAllPeds()
  local peds = {}
  for ped in EnumeratePeds() do
      if DoesEntityExist(ped) then
          table.insert(peds, ped)
      end
  end
  return peds
end

function GetAllVehicles()
  local vehicles = {}
  for vehicle in EnumerateVehicles() do
      if DoesEntityExist(vehicle) then
          table.insert(vehicles, vehicle)
      end
  end
  return vehicles
end

function GetAllPickups()
  local pickups = {}
  for pickup in EnumeratePickups() do
      if DoesEntityExist(pickup) then
          table.insert(pickups, pickup)
      end
  end
  return pickups
end


GetObjects = function()

  local objects = {}

  for object in EnumerateObjects() do
    if DoesEntityExist(object) then
      table.insert(objects, object)
    end
  end

  return objects

end

RoundNumber = function(num, numDecimalPlaces)-- this is likely overkill... but fugg it.
  if numDecimalPlaces and numDecimalPlaces>0 then
      local mult = 10^numDecimalPlaces
      return math.floor(num * mult + 0.5) / mult
  end
  return math.floor(num + 0.5)
end


local entityEnumerator = {
  __gc = function(enum)
    if enum.destructor and enum.handle then
      enum.destructor(enum.handle)
    end
    enum.destructor = nil
    enum.handle = nil
  end
}

local function EnumerateEntities(initFunc, moveFunc, disposeFunc)
  return coroutine.wrap(function()
    local iter, id = initFunc()
    if not id or id == 0 then
      disposeFunc(iter)
      return
    end

    local enum = {handle = iter, destructor = disposeFunc}
    setmetatable(enum, entityEnumerator)

    local next = true
    repeat
      coroutine.yield(id)
      next, id = moveFunc(iter)
    until not next

    enum.destructor, enum.handle = nil, nil
    disposeFunc(iter)
  end)
end

function EnumerateObjects()
  return EnumerateEntities(FindFirstObject, FindNextObject, EndFindObject)
end

function EnumeratePeds()
  return EnumerateEntities(FindFirstPed, FindNextPed, EndFindPed)
end

function EnumerateVehicles()
  return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end

function EnumeratePickups()
  return EnumerateEntities(FindFirstPickup, FindNextPickup, EndFindPickup)
end

------------------------------------------------------------------------------
function showstateSetup()
  showstate = showstate + 1
  if showstate > 5 then showstate = 0 end
  if showstate == 0 then
    showObjs = false
    showPickups = false
    showVehicles = false
    showPeds = false
  elseif showstate == 1 then
    showObjs = true
    showPickups = false
    showVehicles = false
    showPeds = false
  elseif showstate == 2 then
    showObjs = false
    showPickups = true
    showVehicles = false
    showPeds = false
  elseif showstate == 3 then
    showObjs = false
    showPickups = false
    showVehicles = true
    showPeds = false
  elseif showstate == 4 then
    showObjs = false
    showPickups = false
    showVehicles = false
    showPeds = true
  elseif showstate == 5 then
    showObjs = true
    showPickups = true
    showVehicles = true
    showPeds = true
  end
end
function showstateViewChange()
  viewDist = viewDist + 1
  if viewDist > 10 then
    viewDist = 1
  end
end
Citizen.CreateThread(function()
    while true do
      local playerPed = GetPlayerPed(-1)
      local coords = GetEntityCoords(playerPed)

      -- Objs
      if showObjs then
        objList = GetObjects()
        for i=1, #objList, 1 do
            local objectCoords = GetEntityCoords(objList[i])
            local distance     = GetDistanceBetweenCoords(objectCoords.x, objectCoords.y, objectCoords.z, coords.x, coords.y, coords.z, true)
            if distance < viewDist then
                drawOnScreen3D(objectCoords, '~g~Object HashID:~y~'..tostring(objList[i])..' ~g~Object ModelHash: ~y~'..GetEntityModel(objList[i])..'\n~w~'..RoundNumber(objectCoords.x, 3)..'/'..RoundNumber(objectCoords.y,3)..'/'..RoundNumber(objectCoords.z,3), 0.5)
            end
        end
      end
      -- Peds
      if showPeds then
        pedList = GetAllPeds()
        for p=1, #pedList, 1 do
          local pedCoords = GetEntityCoords(pedList[p])
          local distance     = GetDistanceBetweenCoords(pedCoords.x, pedCoords.y, pedCoords.z, coords.x, coords.y, coords.z, true)
          -- local pedCoordsd = {pedCoords.x, pedCoords.y, (pedCoords.z+GetEntityHeightAboveGround(pedList[p]))}
          local cash = GetPedMoney(pedList[p])
          local pedarmed = IsPedArmed(pedList[p],7)
          local isarmed = "false"
          if pedarmed then
            isarmed = "true"
          end
          if distance < viewDist then  --
            local drawZ = (pedCoords.z + 1.0)
            drawOnScreen3D(vector3(pedCoords.x,pedCoords.y, drawZ), '~g~Ped HashID:~o~'..tostring(pedList[p])..' ~g~Ped ModelHash: ~o~'..GetEntityModel(pedList[p])..'', 0.5)
            drawZ = (drawZ - 0.05)
            drawOnScreen3D(vector3(pedCoords.x,pedCoords.y, drawZ), '~g~Coords: ~w~'..RoundNumber(pedCoords.x, 1)..'/'..RoundNumber(pedCoords.y,1)..'/'..RoundNumber(pedCoords.z,1)..'', 0.5)
            drawZ = (drawZ - 0.05)
            drawOnScreen3D(vector3(pedCoords.x,pedCoords.y, drawZ), '~g~Cash: ~w~$'..cash..' ~g~Armed: ~w~'..isarmed..'', 0.5)
          end
          -- SetPedMoney(pedList[p], (GetPedMoney(pedList[p])+1)) <-- definately makes sure the ped has cash.
        end 
      end
      -- Vehicles
      if showVehicles then
        vehList = GetAllVehicles()
        for v=1, #vehList, 1 do
          local vehCoords = GetEntityCoords(vehList[v])
          local distance     = GetDistanceBetweenCoords(vehCoords.x, vehCoords.y, vehCoords.z, coords.x, coords.y, coords.z, true)
          local fuellvl = GetVehicleFuelLevel(vehList[v])
          local damage = IsVehicleDamaged(vehList[v])
          if distance < viewDist then
            local drawZ = (vehCoords.z + 1.25)
            drawOnScreen3D(vector3(vehCoords.x,vehCoords.y, drawZ), '~g~Vehicle HashID: ~b~'..tostring(vehList[v])..' ~g~Vehicle ModelHash: ~b~'..GetEntityModel(vehList[v])..'', 0.5)
            drawZ = (drawZ - 0.05)
            drawOnScreen3D(vector3(vehCoords.x,vehCoords.y, drawZ), '~g~Vehicle Coords: ~w~'..RoundNumber(vehCoords.x, 3)..'/'..RoundNumber(vehCoords.y,3)..'/'..RoundNumber(vehCoords.z,3)..'', 0.5)
            drawZ = (drawZ - 0.05)
            drawOnScreen3D(vector3(vehCoords.x,vehCoords.y, drawZ), '~g~Vehicle Fuel: ~w~'..fuellvl..' ~g~Vehicle Damage: ~w~'..tostring(damage)..'', 0.5)
            
        end
        end 
      end
      -- Pickups
      if showPickups then
        picList = GetAllPickups()
        for pu=1, #picList, 1 do
          local puCoords = GetEntityCoords(picList[pu])
          local distance     = GetDistanceBetweenCoords(puCoords.x, puCoords.y, puCoords.z, coords.x, coords.y, coords.z, true)
          if distance < viewDist then
            drawOnScreen3D(puCoords, '~g~Pickup HashID:~r~'..tostring(picList[pu])..' ~g~Pickup ModelHash: ~r~'..GetEntityModel(picList[pu])..'\n~w~'..RoundNumber(puCoords.x, 3)..'/'..RoundNumber(puCoords.y,3)..'/'..RoundNumber(puCoords.z,3), 0.5)
        end
        end 
      end

      if IsControlJustReleased(0,97) then
        showstateSetup()
      end
      if IsControlJustReleased(0,96) then
        showstateViewChange()
      end
      drawOnScreen2D('~r~WHATAMI[~o~Obj ~w~'..tostring(showObjs)..' ~o~Ped ~w~'..tostring(showPeds)..' ~o~Veh ~w~'..tostring(showVehicles)..' ~o~Pic ~w~'..tostring(showPickups)..'~r~]WHATAMI (Num-)', 255, 255, 255, 255, 0.05, 0.05, 0.3)
      drawOnScreen2D('~r~WHATAMI[~o~View Distance: ~w~'..tostring(viewDist)..'~r~]WHATAMI (Num+)', 255, 255, 255, 255, 0.05, 0.07, 0.3)
  Citizen.Wait(1)
	end
end)