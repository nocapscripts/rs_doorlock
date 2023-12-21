local NPX = exports[Config.Core]:GetCoreObject()

-- Functions

local function showWarning(msg)
	print(('^3%s: %s^0'):format(Lang:t("general.warning"), msg))
end

local function removeItem(Player, item)
	if Config.Consumables[item.name] then
		Player.Functions.RemoveItem(item.name, item.amount >= Config.Consumables[item.name] and Config.Consumables[item.name] or 1)
	end
end

local function checkAndRemoveItem(Player, item, shouldRemove)
	if not item then return false end
	if shouldRemove then
		removeItem(Player, item)
	end
	return true
end

local function checkItems(Player, items, needsAll, shouldRemove)
	if needsAll == nil then needsAll = true end
	local isTable = type(items) == 'table'
	local isArray = isTable and table.type(items) == 'array' or false
	local totalItems = 0
	local count = 0
	if isTable then for _ in pairs(items) do totalItems += 1 end else totalItems = #items end
	local kvIndex
	if isArray then kvIndex = 2 else kvIndex = 1 end
	if isTable then
		for k, v in pairs(items) do
			local itemKV = {k, v}
			local item = Player.Functions.GetItemByName(itemKV[kvIndex])
			if needsAll then
				if checkAndRemoveItem(Player, item, false) then
					count += 1
				end
			else
				if checkAndRemoveItem(Player, item, shouldRemove) then
					return true
				end
			end
		end
		if count == totalItems then
			for k, v in pairs(items) do
				local itemKV = {k, v}
				local item = Player.Functions.GetItemByName(itemKV[kvIndex])
				checkAndRemoveItem(Player, item, shouldRemove)
			end
			return true
		end
	else -- Single item as string
		local item = Player.Functions.GetItemByName(items)
		return checkAndRemoveItem(Player, item, shouldRemove)
	end
	return false
end

local function isAuthorized(Player, door, usedLockpick)
	if door.allAuthorized then return true end

	if Config.AdminAccess and NPX.Functions.HasPermission(Player.PlayerData.source, Config.AdminPermission) then
		if Config.Warnings then
			showWarning(Lang:t("general.warn_admin_privilege_used", {player = Player.PlayerData.name, license = Player.PlayerData.license}))
		end
		return true
	end

	if (door[4] or door.lockpick) and usedLockpick then return true end

	if door.authorizedJobs then
		if door.authorizedJobs[Player.PlayerData.job.name] and Player.PlayerData.job.grade.level >= door.authorizedJobs[Player.PlayerData.job.name] then
			return true
		elseif type(door.authorizedJobs[1]) == 'string' then
			for _, job in pairs(door.authorizedJobs) do -- Support for old format
				if job == Player.PlayerData.job.name then return true end
			end
		end
	end

	if door.authorizedGangs then
		if door.authorizedGangs[Player.PlayerData.gang.name] and Player.PlayerData.gang.grade.level >= door.authorizedGangs[Player.PlayerData.gang.name] then
			return true
		elseif type(door.authorizedGangs[1]) == 'string' then
			for _, gang in pairs(door.authorizedGangs) do -- Support for old format
				if gang == Player.PlayerData.gang.name then return true end
			end
		end
	end

	if door.authorizedCitizenIDs then
		if door.authorizedCitizenIDs[Player.PlayerData.citizenid] then
			return true
		elseif type(door.authorizedCitizenIDs[1]) == 'string' then
			for _, id in pairs(door.authorizedCitizenIDs) do -- Support for old format
				if id == Player.PlayerData.citizenid then return true end
			end
		end
	end

	if door.items then return checkItems(Player, door.items, door.needsAllItems, true) end

	return false
end

local function SaveDoorStates()
    SaveResourceFile(GetCurrentResourceName(), "./saves/doorstates.json", json.encode(Config.DoorStates), -1)
end

local function LoadDoorStates()
	local DoorStates = LoadResourceFile(GetCurrentResourceName(), "./saves/doorstates.json")
	if DoorStates then
		DoorStates = json.decode(DoorStates)
		if not next(DoorStates) then return end

		for key,isLocked in pairs(DoorStates) do
			if Config.DoorList[key] ~= nil then
				Config.DoorList[key].locked = isLocked
			end
		end
		Config.DoorStates = DoorStates
	end
end

-- Callbacks

NPX.Functions.CreateCallback('rs_doorlock:server:setupDoors', function(_, cb)
	cb(Config.DoorList)
end)

NPX.Functions.CreateCallback('rs_doorlock:server:checkItems', function(source, cb, items, needsAll)
	local Player = NPX.Functions.GetPlayer(source)
	cb(checkItems(Player, items, needsAll, false))
end)

-- Events

RegisterNetEvent('rs_doorlock:server:updateState', function(doorID, locked, src, usedLockpick, unlockAnyway, enableSounds, enableAnimation, sentSource)
	local playerId = sentSource or source
	local Player = NPX.Functions.GetPlayer(playerId)
	if not Player then return end
	if type(doorID) ~= 'number' and type(doorID) ~= 'string' then
		if Config.Warnings then
			showWarning((Lang:t("general.warn_wrong_doorid_type", {player = Player.PlayerData.name, license = Player.PlayerData.license, doorID = doorID})))
		end
		return
	end

	if type(locked) ~= 'boolean' then
		if Config.Warnings then
			showWarning((Lang:t("general.warn_wrong_state", {player = Player.PlayerData.name, license = Player.PlayerData.license, state = locked})))
		end
		return
	end

	if not Config.DoorList[doorID] then
		if Config.Warnings then
			showWarning(Lang:t("general.warn_wrong_doorid", {player = Player.PlayerData.name, license = Player.PlayerData.license, doorID = doorID}))
		end
		return
	end

	if not unlockAnyway and not isAuthorized(Player, Config.DoorList[doorID], usedLockpick) then
		if Config.Warnings then
			showWarning(Lang:t("general.warn_no_authorisation", {player = Player.PlayerData.name, license = Player.PlayerData.license, doorID = doorID}))
		end
		return
	end

	Config.DoorList[doorID].locked = locked
	if Config.DoorStates[doorID] == nil then Config.DoorStates[doorID] = locked elseif Config.DoorStates[doorID] ~= locked then Config.DoorStates[doorID] = nil end
	TriggerClientEvent('rs_doorlock:client:setState', -1, playerId, doorID, locked, src or false, enableSounds, enableAnimation)

	if not Config.DoorList[doorID].autoLock then return end
	SetTimeout(Config.DoorList[doorID].autoLock, function()
		if Config.DoorList[doorID].locked then return end
		Config.DoorList[doorID].locked = true
		if Config.DoorStates[doorID] == nil then Config.DoorStates[doorID] = locked elseif Config.DoorStates[doorID] ~= locked then Config.DoorStates[doorID] = nil end
		TriggerClientEvent('rs_doorlock:client:setState', -1, playerId, doorID, true, src or false, enableSounds, enableAnimation)
	end)
end)

RegisterNetEvent('rs_doorlock:server:saveNewDoor', function(data, doubleDoor)
	local src = source
	if not NPX.Functions.HasPermission(src, Config.CommandPermission) and not IsPlayerAceAllowed(src, 'command') then
		if Config.Warnings then
			showWarning(Lang:t("general.warn_no_permission_newdoor", {player = GetPlayerName(src), license = NPX.Functions.GetIdentifier(src, 'license'), source = src}))
		end
		return
	end
	local Player = NPX.Functions.GetPlayer(src)
	if not Player then return end
	local configData = {}
	local jobs, gangs, cids, items, doorType, identifier
	if data[8] then configData.authorizedJobs = { [data[8]] = 0 } jobs = "['"..data[8].."'] = 0" end
	if data[9] then configData.authorizedGangs = { [data[9]] = 0 } gangs = "['"..data[9].."'] = 0" end
	if data[10] then configData.authorizedCitizenIDs = { [data[10]] = true } cids = "['"..data[10].."'] = true" end
	if data[7] then configData.items = { [data[7]] = 1 } items = "['"..data[7].."'] = 1" end
	configData.locked = data[11]
	configData.distance = data[5]
	configData.doorType = data[4]
	configData.doorRate = 1.0
	configData.doorLabel = data[3]
	doorType = "'"..data[4].."'"
	identifier = data[1]..'-'..data[2]
	if doubleDoor then
		configData.doors = {
			{objName = data.model[1], objYaw = data.heading[1], objCoords = data.coords[1]},
			{objName = data.model[2], objYaw = data.heading[2], objCoords = data.coords[2]}
		}
	else
		configData.objName = data.model
		configData.objYaw = data.heading
		configData.objCoords = data.coords
		configData.fixText = true
	end

	local path = GetResourcePath(GetCurrentResourceName())

	if data[1] then
		local tempfile, err = io.open(path:gsub('//', '/')..'/configs/'..string.gsub(data[1], ".lua", "")..'.lua', 'a+')
		if tempfile then
			tempfile:close()
			path = path:gsub('//', '/')..'/configs/'..string.gsub(data[1], ".lua", "")..'.lua'
		else
			return error(err)
		end
	else
		path = path:gsub('//', '/')..'/config.lua'
	end

	local file = io.open(path, 'a+')
	local label = "\n\n-- "..data[2].." ".. Lang:t("general.created_by") .." "..Player.PlayerData.name.."\nConfig.DoorList['"..identifier.."'] = {"
	file:write(label)
	for k, v in pairs(configData) do
		if k == 'authorizedJobs' or k == 'authorizedGangs' or k == 'authorizedCitizenIDs' or k == 'items' then
			local auth = jobs
			if k == 'authorizedGangs' then
				auth = gangs
			elseif k == 'authorizedCitizenIDs' then
				auth = cids
			elseif k == 'items' then
				auth = items
			end
			local str = ("\n    %s = { %s },"):format(k, auth)
			file:write(str)
		elseif k == 'doors' then
			local doors = {}
			for i = 1, 2 do
				doors[i] = ("    {objName = %s, objYaw = %s, objCoords = %s}"):format(configData.doors[i].objName, configData.doors[i].objYaw, configData.doors[i].objCoords)
			end
			local str = ("\n    %s = {\n    %s,\n    %s\n    },"):format(k, doors[1], doors[2])
			file:write(str)
		elseif k == 'doorType' then
			local str = ("\n    %s = %s,"):format(k, doorType)
			file:write(str)
		elseif k == 'locked' then
			local str = ("\n    %s = %s,"):format(k, configData.locked)
			file:write(str)

		elseif k == 'doorLabel' then
			local str = ("\n    %s = '%s',"):format(k, v)
			file:write(str)
		
		else
			local str = ("\n    %s = %s,"):format(k, v)
			file:write(str)
		end
	end
	file:write("\n}")
	file:close()

	Config.DoorList[identifier] = configData
	TriggerClientEvent('rs_doorlock:client:newDoorAdded', -1, configData, identifier, src)
end)

AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() == resource and Config.PersistentDoorStates then
		CreateThread(function()
			LoadDoorStates()
			Wait(1000)
			while true do
				Wait(Config.PersistentSaveInternal)
				SaveDoorStates()
			end
		end)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if GetCurrentResourceName() == resource and Config.PersistentDoorStates then
		SaveDoorStates()
    end
end)

RegisterNetEvent('txAdmin:events:scheduledRestart', function(eventData)
    if eventData.secondsRemaining == 60 then
        CreateThread(function()
            Wait(45000)
			SaveDoorStates()
        end)
	else
		SaveDoorStates()
    end
end)

RegisterNetEvent('rs_doorlock:server:removeLockpick', function(type)
	local Player = NPX.Functions.GetPlayer(source)

	if not Player then return end

	if type == "advancedlockpick" or type == "lockpick" then
		Player.Functions.RemoveItem(type, 1)
	end
end)

-- Commands

NPX.Commands.Add('door', Lang:t("general.newdoor_command_description"), {}, false, function(source)
	TriggerClientEvent('rs_doorlock:client:addNewDoor', source)
end, Config.CommandPermission)

NPX.Commands.Add('doordebug', Lang:t("general.doordebug_command_description"), {}, false, function(source)
	TriggerClientEvent('rs_doorlock:client:ToggleDoorDebug', source)
end, Config.CommandPermission)
