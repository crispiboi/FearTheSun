--      based off FearTheRain by Stephanus van Zyl AKA Viceroy                                                                               #

building_table = {};

local SPRING, SUMMER, AUTUMN, WINTER = 0,1,2,3;

local pillowmod;

--as squares are loaded, add the associated buildings to a table
local function addBuildingList(_square)
    local sq = _square;
    if sq then 
            if sq:isOutside() == false then
                local building = sq:getBuilding();
                building_table[building] = building;
            end
    end   
end --end add building function

--as squares are unloaded, remove the associated buildings from the table.
local function removeBuildingList(_square)
    local sq = _square;
    if sq then 
            if sq:isOutside() == false then 
                building_table[sq:getBuilding()] = nil;
            end
    end   
end --end remove building function

local function isBuildingListEmpty()
    count = 0
    for i, v in pairs(building_table) do 
        count = count + 1;
    end
    if count ~= 0 then 
        return false;
    else 
        return true;
    end
end

local function getMonth() 
	local gametime = GameTime:getInstance();
	return gametime:getMonth();
end

local function getSeason()
	--Spring month == 2 or month == 3 or month == 4
	--Summer month == 5 or month == 6 or month == 7
	--Autumn month == 8 or month == 9 or month == 10
	--Winter month == 11 or month == 0 or month == 1
	local month = getMonth();
	if month == 2 or month == 3 or month == 4 then
		return SPRING;
    elseif month == 5 or month == 6 or month == 7 then
        return SUMMER;
    elseif month == 8 or month == 9 or month == 10 then
        return AUTUMN;
	else
		return WINTER;
	end
end

local function getIsDay()
    --spring 6-22
    --summer 6-23
    --autumn 6-22
    --winter 8-18
    local season = getSeason();

    return (season == SPRING and pillowmod.currentHour >= 6 and pillowmod.currentHour <= 22) or
    (season == SUMMER and pillowmod.currentHour >= 6 and pillowmod.currentHour <= 22) or
    (season == AUTUMN and pillowmod.currentHour >= 6 and pillowmod.currentHour <= 22) or
    (season == WINTER and pillowmod.currentHour >= 6 and pillowmod.currentHour <= 22);
end

--calc the IsDay variable
local function calculateHour()
    pillowmod.currentHour = math.floor(math.floor(GameTime:getInstance():getTimeOfDay() * 3600) / 3600);

    pillowmod.IsDay = getIsDay();
end --end calc hour function 

--calc the IsRaining variable
local function calculateRain()
    if RainManager.isRaining() then
        pillowmod.IsRaining = false;
    end;
end

local function initialise()
    pillowmod = getPlayer():getModData();
    calculateHour();
    calculateRain();
end

local function isDay()
    return pillowmod.IsDay ~= nil and pillowmod.IsDay;
end

local function isRaining()
    return pillowmod.IsRaining ~= nil and pillowmod.IsRaining;
end

local function updateZCounter()
    local playerData = getPlayer():getModData();
    if playerData.zCounter == nil or playerData.zCounter >= 2000
        then playerData.zCounter = 1;
        elseif playerData.zCounter <= 2001
        then playerData.zCounter = playerData.zCounter + 1;
    else end 
end 

-- calculate the closeset building in the list
local function calcClosestBuilding(_square)
    sourcesq = _square ;
    local closest = nil;
    local closestDist = 1000000;
    if isBuildingListEmpty() == true
        then closest = sourcesq;
        else 
            for id, b in pairs(building_table) do
                sq = b:getRandomRoom():getRandomSquare();
                if sq ~= nil
                    then 
                    local dist = IsoUtils.DistanceTo(sourcesq:getX(), sourcesq:getY(), sq:getX() , sq:getY())
                    if dist < closestDist then
                        closest = sq;
                        closestDist = dist;
                    end
                end
            end 
        end 
    return closest
end 

--lure zombie to closest building using sound
local function lureZombiePathSound(zombie)
        sourcesq = zombie:getCurrentSquare();
        targetsq = calcClosestBuilding(sourcesq);
        zombie:pathToSound(targetsq:getX(), targetsq:getY(), targetsq:getZ());
end

--lure zombie to closest building using path
local function lureZombiePathLocation(zombie)
        sourcesq = zombie:getCurrentSquare();
        targetsq = calcClosestBuilding(sourcesq);
        zombie:pathToLocation(targetsq:getX(), targetsq:getY(), targetsq:getZ());
end

local function zombieStop(zombie)
        zombie:changeState(ZombieIdleState.instance());
        targetsq = zombie:getCurrentSquare();
        val = ZombRand(-5,5);
        zombie:pathToLocation(targetsq:getX()+val, targetsq:getY()+val, targetsq:getZ());
end

local function isZombieIdle(zombie)
    if zombie ~= nil and zombie:isMoving() == false then 
        return true;
    else 
        return false;
    end 
end

local function isSquareOutside(square)
    if square:isOutside() == false then 
        return false;
    else 
        return true;
    end
end

local function isCharacterOutside(character)
    local currentSquare = character:getCurrentSquare();
    return isSquareOutside(currentSquare);
end

local function zResetCommand(zombieModData)
    zombieModData.commandSent = false;
end 

local function zombieHasCommand(zombie)
    local zombieModData = zombie:getModData();

    if zombieModData.commandSent == nil then 
        return false;
    else 
        return zombieModData.commandSent;
    end
end

local function zDayRoutine(zombie, zombieModData)
    -- day, inside
    if zombieHasCommand(zombie) == false and isCharacterOutside(zombie) == false and pillowmod.zCounter <= 1000
        then 
            zombieModData.commandSent = true;
            zombie:setUseless(true); 
            zombieModData.docile = true;
            zombie:DoZombieStats();
    -- day, outside, lure via sound or location
    elseif (zombieHasCommand(zombie) == false and isCharacterOutside(zombie) and pillowmod.zCounter >= 300 and pillowmod.zCounter <=1099 ) 
        or(zombieHasCommand(zombie) == false and isCharacterOutside(zombie) and isZombieIdle(zombie))
        then 
            zombieModData.commandSent = true;
            zombieModData.docile = false;
            if ZombRand(1)==0 then 
                lureZombiePathSound(zombie);
            else 
                lureZombiePathLocation(zombie);
            end 
    -- day, help un-stuck zombie
    elseif zombieHasCommand(zombie) == false and isCharacterOutside(zombie) and pillowmod.zCounter >= 1799 and pillowmod.zCounter <= 1899
        then 
            zombieModData.commandSent = true;
            zombieModData.docile = false;
            zombieStop(zombie);
    elseif pillowmod.zCounter >= 1900
        then zResetCommand(zombieModData) ;
    else end
end 

local function zNightRoutine(zombie, zombieModData)
        if pillowmod.zCounter  == 100
            then 
            zombie:setMoving(true);
            zombie:setVariable("bMoving", true);
            zombie:setFakeDead(false);
            zombie:setUseless(false); 
            zombieModData.docile = false;
            zombie:DoZombieStats();
            zResetCommand(zombieModData) ;
        else end
end

local function zCheck(zombie)
    
    local zombieModData = zombie:getModData();

    --initialize wake tick, decrement it
    if zombieModData.awakeTick == nil or zombieModData.awakeTick < 0 then 
        zombieModData.awakeTick = 1;
    else 
        zombieModData.awakeTick = zombieModData.awakeTick - 1;
    end 

    if isCharacterOutside(zombie) == false and zombieModData.awakeTick > 1 then 
        return;
    end
    
    if isDay() and not isRaining() then
        zDayRoutine(zombie, zombieModData);
    else
        zNightRoutine(zombie, zombieModData);
    end
end

local function aggroZombie(zombie)
    local zombieModData = zombie:getModData();
    zombie:setFakeDead(false);
    zombie:setUseless(false); 
    zombieModData.docile = false;
    zombieModData.awakeTick = 500;
end

local function wakeUpZombiesInTargetsRoom(target)
    if target ~= nil then
        local currentRoom = target:getCurrentSquare():getRoom();
        print("Waking up zombies in room.");
        local zlist = player:getCell():getZombieList();
        if(zlist ~= nil) then
            for i=0, zlist:size()-1 do
                local zombie = zlist:get(i);
                if zombie:getCurrentSquare():getRoom() == currentRoom then 
                    aggroZombie(zombie);
                else end
            end
        end
    end
end

local function wakeUpZombiesInTargetsBuilding(target)
    if target ~= nil then
        local currentBuilding = target:getCurrentSquare():getBuilding();
        print("Unlucky! Waking up zombies in building.");
        local zlist = player:getCell():getZombieList();
        if(zlist ~= nil) then
            for i=0, zlist:size()-1 do
                local zombie = zlist:get(i);
                if zombie:getCurrentSquare():getBuilding() == currentBuilding then 
                    aggroZombie(zombie);
                else end
            end
        end
    end
end

--Each triggering action has a small chance to wake up the whole building
local function rollSetZombieActive(target)
    local random = ZombRand(1, 100);
    if random < 95 then --95% chance of waking zombies in room
        wakeUpZombiesInTargetsRoom(target);
    else --5% chance of waking zombies in building
        wakeUpZombiesInTargetsBuilding(target);
    end
end

local function onHitOrCollideWithZombie(source, target)
    --xor, check if collision/hit is between zombie and player
    local onlyOneIsPlayer = source ~= nil and target ~= nil and source:isZombie() ~= target:isZombie();

    if onlyOneIsPlayer then
        print("Hit or collided with zombie");
        if isCharacterOutside(source) == false then
            rollSetZombieActive(source)
        elseif  isCharacterOutside(target) == false then
            rollSetZombieActive(target)
        end
    end
end

local function onMoveWhileInside()
    local player = getPlayer();
    if player:isSneaking() == false and isCharacterOutside(player) == false then
        print("Did not sneak while inside");
        rollSetZombieActive(player);
    end
end

Events.OnGameStart.Add(initialise);

--calc hour must be done at game start and then every hour because it initializes the time of day variable
Events.EveryHours.Add(calculateHour);

--calc rain done every ten minutes to check for rain updates
Events.EveryTenMinutes.Add(calculateRain);

--gridsquare functions that were modified from original fear the rain.
Events.LoadGridsquare.Add(addBuildingList);
Events.ReuseGridsquare.Add(removeBuildingList);

--Check for each zombie
Events.OnZombieUpdate.Add(zCheck);
Events.OnPlayerUpdate.Add(updateZCounter);

--waking zombie functions, every hour since it really should happen just once unlesss player moves to a new cell
Events.OnWeaponHitCharacter.Add(onHitOrCollideWithZombie);
Events.OnCharacterCollide.Add(onHitOrCollideWithZombie);
Events.OnPlayerMove.Add(onMoveWhileInside);