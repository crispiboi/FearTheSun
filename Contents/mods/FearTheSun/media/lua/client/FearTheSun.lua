--based off FearTheRain by Stephanus van Zyl AKA Viceroy

building_table = {};

local SPRING, SUMMER, AUTUMN, WINTER = 0,1,2,3;

local FearTheSun = FearTheSun or {}
FearTheSun.FearTheRain = false;

local pillowmod;
local player;
local initialised = false;
local stepCounter = 0;

--Modifier constants
local sneakLoudlyChance = 0.25; --CHANCE: 0.25% chance of waking zombies while sneaking
local wakeBuildingChance = 2; --CHANCE: 2% chance of waking zombies in building
local stepLoudlyChance = 5; --CHANCE: 5% chance of waking zombies if you step loudly
local hitChance = 25; --CHANCE: 25% chance of waking zombies on hit
local collisionChance = 75; --CHANCE: 75% chance of waking zombies on collision
local lureChance = 75; --CHANCE: 25% chance of luring zombie

local function teleport(character,x,y,z)
    character:setX(x);
    character:setY(y);
    character:setZ(z);
    character:setLx(x);
    character:setLy(y);
    character:setLz(z);
end

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
    count = 0;
    for i, v in pairs(building_table) do 
        return false;
    end
    return true;
end

-- calculate the closeset building in the list
local function calcClosestBuilding(_square, onlyUnexplored) --isAllExplored()
    local sourcesq = _square ;
    local closest = nil;
    local closestDist = 1000000;

    if isBuildingListEmpty() == true then 
        closest = sourcesq;
    else 
        for id, b in pairs(building_table) do
            if onlyUnexplored and b:isAllExplored() then --get nearest unexplored building
                --nothing
            else
                local sq = b:getRandomRoom():getRandomFreeSquare();
                if sq ~= nil then 
                    local dist = IsoUtils.DistanceTo(sourcesq:getX(), sourcesq:getY(), sq:getX() , sq:getY())
                    if dist < closestDist then
                        closest = sq;
                        closestDist = dist;
                    end
                end
            end
        end 
    end 
    return closest
end 

local function probabilityCheck(percentageTrue)
    local random = ZombRand(1,1000);
    return random <= percentageTrue * 10;
end

local function coinFlip()
    return ZombRand(1) == 0;
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
    --spring 6-21
    --summer 6-22
    --autumn 6-21
    --winter 8-17
    local season = getSeason();

    return (season == SPRING and pillowmod.currentHour >= 6 and pillowmod.currentHour <= 21) or
    (season == SUMMER and pillowmod.currentHour >= 6 and pillowmod.currentHour <= 22) or
    (season == AUTUMN and pillowmod.currentHour >= 6 and pillowmod.currentHour <= 21) or
    (season == WINTER and pillowmod.currentHour >= 8 and pillowmod.currentHour <= 17);
end

--calc the IsDay variable
local function calculateHour()
    pillowmod.currentHour = math.floor(math.floor(GameTime:getInstance():getTimeOfDay() * 3600) / 3600);

    pillowmod.IsDay = getIsDay();
end

--calc the IsRaining variable
local function calculateRain()
    pillowmod.IsRaining = RainManager.isRaining();
end

local function calculateChanceModifier()
    local player = getPlayer();
    
    --TODO: maybe add modifier based on skill levels

    pillowmod.isLucky = player:HasTrait("Lucky");
    pillowmod.isUnlucky = player:HasTrait("Lucky");

    pillowmod.isGraceful = player:HasTrait("Graceful");
    pillowmod.isClumsy = player:HasTrait("Clumsy");

    pillowmod.isInconspicuous = player:HasTrait("Inconspicuous");
    pillowmod.isConspicuous = player:HasTrait("Conspicuous");

    local luckyModifier = 1;
    if pillowmod.isLucky then
        luckyModifier = luckyModifier - 0.15;
    elseif pillowmod.isUnlucky then
        luckyModifier = luckyModifier + 0.15;
    end

    local gracefulModifier = 1;
    if pillowmod.isGraceful then
        gracefulModifier = gracefulModifier - 0.1;
    elseif pillowmod.isClumsy then
        gracefulModifier = gracefulModifier + 0.1;
    end

    local conspicuousModifier = 1;
    if pillowmod.isInconspicuous then
        conspicuousModifier = conspicuousModifier - 0.1;
    elseif pillowmod.isClumsy then
        conspicuousModifier = conspicuousModifier + 0.1;
    end

    sneakLoudlyChance = sneakLoudlyChance * luckyModifier * conspicuousModifier * gracefulModifier;
    stepLoudlyChance = stepLoudlyChance * luckyModifier * conspicuousModifier * gracefulModifier;
    hitChance = hitChance * luckyModifier * gracefulModifier;
    collisionChance = collisionChance * luckyModifier * gracefulModifier;
    wakeBuildingChance = wakeBuildingChance * luckyModifier;
end

local function initialise()
    if not initialised then
        player = getPlayer();
        pillowmod = player:getModData();
        calculateHour();
        calculateRain();
        calculateChanceModifier();
        initialised = true;
    end
end

local function isDay()
    return pillowmod.IsDay ~= nil and pillowmod.IsDay;
end

local function isRaining()
    return pillowmod.IsRaining ~= nil and pillowmod.IsRaining;
end

local function updateCounters()
    if pillowmod.stuckCounter == nil or pillowmod.stuckCounter > 500 then
        pillowmod.stuckCounter = 1;
    elseif pillowmod.stuckCounter <= 501 then
        pillowmod.stuckCounter = pillowmod.stuckCounter + 1;
    end

    if pillowmod.zActionCounter == nil or pillowmod.zActionCounter >= 50 then 
        pillowmod.zActionCounter = 1;
    elseif pillowmod.zActionCounter <= 51 then 
        pillowmod.zActionCounter = pillowmod.zActionCounter + 1;
    end

    if pillowmod.zCounter == nil or pillowmod.zCounter >= 2000 then 
        pillowmod.zCounter = 1;
    elseif pillowmod.zCounter <= 2001 then 
        pillowmod.zCounter = pillowmod.zCounter + 1;
    end
end 

local function lureLocationXYZ(zombie, x, y ,z)
    zombie:pathToLocationF(x, y ,z);
end

local function lureSoundXYZ(zombie, x, y ,z)
    zombie:pathToSound(x, y ,z);
end

local function lureZombieToSoundSquare(zombie, targetsq)
    lureSoundXYZ(zombie, targetsq:getX(), targetsq:getY(), targetsq:getZ());
end

local function lureZombieToLocationSquare(zombie, targetsq)
    lureLocationXYZ(zombie,targetsq:getX(), targetsq:getY(), targetsq:getZ());
end


local function getRandomOutdoorSquare(character)
    local cell = character:getCurrentSquare():getCell();
    return cell:getRandomOutdoorTile();
end

local function getSquareInClosestBuilding(character)
    local sourcesq = character:getCurrentSquare();
    return calcClosestBuilding(sourcesq, false);
end

local function getSquareInClosestUnexploredBuilding(character)
    local sourcesq = character:getCurrentSquare();
    return calcClosestBuilding(sourcesq, true);
end

local function targetSquareIsFar(character,targetsq)
    local sourcesq = character:getCurrentSquare();
    local dist = IsoUtils.DistanceTo(sourcesq:getX(), sourcesq:getY(), targetsq:getX() , targetsq:getY())
    if dist > 25 then 
        return true ;
    else 
        return false ;
    end
end 

local function randomLureZombieFar(zombie)
    local targetsq = zombie:getCurrentSquare();

    if targetsq == nil then return; end

    local x,y,z = targetsq:getX() + ZombRand(-100,100), targetsq:getY() + ZombRand(-100,100), targetsq:getZ();

    if coinFlip() then
        lureSoundXYZ(zombie, x, y, z);
    else
        lureLocationXYZ(zombie, x, y, z);
    end
end

--Main random lure function that calls into others
--daytime gets a square inside, nighttime gets a square outside
--if the target is too far, 25 tiles, just send the zombie walking far, handling rural cases wakeAll
local function randomLureZombie(zombie)
    local targetsq = zombie:getCurrentSquare();

    if isDay() then
        targetsq = getSquareInClosestBuilding(zombie);
    else
        targetsq = getRandomOutdoorSquare(zombie);
    end

    if targetsq == nil then return; end

    if targetSquareIsFar(zombie,targetsq) == true then
        randomLureZombieFar(zombie);
    elseif coinFlip() then
        lureZombieToSoundSquare(zombie, targetsq);
    else
        lureZombieToLocationSquare(zombie, targetsq);
    end
 
end

local function randomLureZombieNearby(zombie)
    local targetsq = zombie:getCurrentSquare();

    if targetsq == nil then return; end

    local x,y,z = targetsq:getX() + ZombRand(-5,5), targetsq:getY() + ZombRand(-5,5), targetsq:getZ();

    if coinFlip() then
        lureSoundXYZ(zombie, x, y, z);
    else
        lureLocationXYZ(zombie, x, y, z);
    end
end

local function isZombieIdle(zombie)
    return zombie ~= nil and zombie:isMoving() == false;
end

local function isCharacterOutside(character)
    local currentSquare = character:getCurrentSquare();
    return currentSquare:isOutside();
end

local function zResetDayCommand(zombieModData)
    zombieModData.dayCommandSent = false;
end 

local function zResetNightCommand(zombieModData)
    zombieModData.nightCommandSent = false;
end

local function zResetAllCommmands(zombieModData)
    zombieModData.dayCommandSent = false;
    zombieModData.nightCommandSent = false;
end

local function zombieHasDayCommand(zombie)
    local zombieModData = zombie:getModData();

    if zombieModData.dayCommandSent == nil then 
        zombieModData.dayCommandSent = false;
        return false;
    else 
        return zombieModData.dayCommandSent;
    end
end

local function zombieHasNightCommand(zombie)
    local zombieModData = zombie:getModData();

    if zombieModData.nightCommandSent == nil then 
        zombieModData.nightCommandSent = false;
        return false;
    else 
        return zombieModData.nightCommandSent;
    end
end

local function setZombieActive(zombie,zombieModData)
    zombie:setFakeDead(false);
    zombie:setUseless(false); 
    zombieModData.docile = false;
    zombie:DoZombieStats();
end 

--daytime routine 2023-02-15 removed making some zombies wander inside using zCounter tick 
local function zDayRoutine(zombie, zombieModData)

    if zombieHasNightCommand(zombie) then
        zResetAllCommmands(zombieModData);
    end 
    
    --daytime zombie state checks
    if isCharacterOutside(zombie) == false then 
        if not zombieModData.docile then
            zombieModData.dayCommandSent = true;
            zombie:setUseless(true); 
            zombieModData.docile = true;
            zombie:DoZombieStats();
        end

    --daytime 
    elseif pillowmod.zActionCounter > 25 and pillowmod.zActionCounter <= 50 and ((zombieHasDayCommand(zombie) == false and isCharacterOutside(zombie)) 
        or ( isCharacterOutside(zombie) and isZombieIdle(zombie))) then 
        --remove check for HasDayCommand = false from OR statement above. zombieHasDayCommand(zombie) == false and
            zombie:setBodyToEat(nil);
            zombie:setUseless(false); -- add 2023-02-15 to fix bug of docile outside zombies
            zombieModData.dayCommandSent = true;
            zombieModData.docile = false; 

            if zombie:isSitAgainstWall() then
                zombie:setSitAgainstWall(false);
            end

            zombie:DoZombieStats();
            randomLureZombie(zombie);

    --reset every 2000 ticks to tickle zombies that didn't listen to their commands
    elseif pillowmod.zCounter == 2000 -- and zombieHasDayCommand(zombie) --2023-02-15 remove check for hasDayCommand, this seems to cause stuck zombies
        then 
        zResetDayCommand(zombieModData);
    end
end 

--at night zombies should get a random chance to be lured out of buildings
--it breaks immersion to have the whole population moving
--2023-02-15 remove action counter condition from reset conditions.
local function zNightRoutine(zombie, zombieModData)

    if zombieHasDayCommand(zombie) then
        zResetAllCommmands(zombieModData);
    end
        
    --reset zombies to an active state
    if zombieModData.docile == true 
      then 
        zombie:setFakeDead(false);
        zombie:setUseless(false); 
        zombieModData.docile = false;
        zombie:DoZombieStats();
    end

    --randomly lure some zombies. All zombies get one night command sent.
    --all of these conditions may not be neccesary but get the best behavior as of 2023-02-16
    if isCharacterOutside(zombie) == false and zombieHasNightCommand(zombie) == false and pillowmod.zActionCounter > 25 and pillowmod.zActionCounter <= 50 
        or (isCharacterOutside(zombie) == false and isZombieIdle(zombie) and zombieHasNightCommand(zombie)== false) then
        if probabilityCheck(lureChance) then
            randomLureZombie(zombie);    
        end
        zombieModData.nightCommandSent = true;
    end 

end

--return true if aggro, false if not aggro
local function updateAggro(zombie, zombieModData)
    if zombieModData.noTargetTick == nil then
        zombieModData.noTargetTick = 0;
    end

    if zombie:getTarget() ~= nil then
        zombieModData.hasAggro = true;
        zombieModData.noTargetTick = 1000;
        return true;
    elseif zombieModData.noTargetTick > 0 then
        zombieModData.hasAggro = false;
        if zombieModData.noTargetTick == nil then 
            zombieModData.noTargetTick = 0 
        else
            zombieModData.noTargetTick = zombieModData.noTargetTick - 1;
        end
    end

    --if no target for 1000 ticks, return to regular programming
    return zombieModData.noTargetTick > 0;
end


-- 2023-02-16 this function reused to intialize zombies with their states required for the mod.
--buildings are loaded after zombies so they never receive a building when they are initialized
local function loadZombie(zombie)
    local zombieModData = zombie:getModData();
    zResetAllCommmands(zombieModData); 
    zombie:setFakeDead(false);
    zombie:setUseless(false); 
    zombieModData.docile = false;
    zombieModData.loaded = true;
    zombieModData.hasAggro = false;
    zombie:DoZombieStats();
    randomLureZombie(zombie);
end

local function walkingOnTheSpot(lastSq, currSq)
    if lastSq ~= nil and currSq ~= nil then
        local lx,ly,cx,cy = lastSq:getX(), lastSq:getY(), currSq:getX(), currSq:getY();
        local dist = IsoUtils.DistanceToSquared(lx, ly, cx, cy) + 0.0;
        if dist <= 1 then
            return true; 
        end
    end
end

--Main zcheck routine OnZombieupdate.
--load zombie function is called here and was significantly modified removing all teleporting functions.
--Try to get out of this function as quickly as possible for dead zombies, uninitiated zombies, and aggroed zombies
local function zCheck(zombie)
    if(zombie:isDead()) then
        return;
    end

    local zombieModData = zombie:getModData();
    --2023-02-16 enable load zombie function again with logic checking for it being loaded
    if zombieModData.loaded == nil 
        then
        loadZombie(zombie, zombieModData); 
    end 

    if updateAggro(zombie, zombieModData) then --if aggro'd, let zombie do its thing
        return;
    end

    --if zombie is moving for every 100 ticks and is still on same tile, move randomly in a different direction
    if pillowmod.stuckCounter == 100 then
        if walkingOnTheSpot(zombie:getCurrentSquare(), zombieModData.lastKnownSquare) then
            if isDay() then   
                randomLureZombie(zombie);
            else
                randomLureZombieNearby(zombie);
            end
        end
        zombieModData.lastKnownSquare = zombie:getCurrentSquare();
    end
   
    if not isDay() or (FearTheSun.FearTheRain and isRaining()) then --REMOVE RAINING FOR NOW
        zNightRoutine(zombie, zombieModData);
    else
        zDayRoutine(zombie, zombieModData);
    end
end

local function aggroZombie(zombie)
    local zombieModData = zombie:getModData();
    zombie:setFakeDead(false);
    zombie:setUseless(false); 
    zombieModData.docile = false;
    zombieModData.hasAggro = true;
    zResetNightCommand(zombieModData);
    zResetDayCommand(zombieModData);
end

local function wakeZombie(zombie, wakeAll)
    if wakeAll then
        aggroZombie(zombie);
    else
        if coinFlip() then
            aggroZombie(zombie);
        end
    end
end

local function wakeUpZombiesInTargetsRoom(target)
    if target ~= nil then
        local currentRoom = target:getCurrentSquare():getRoom();
        if currentRoom ~= nil then
            local wakeAll = coinFlip();
            --print("Waking up zombies in room.");
            local zlist = player:getCell():getZombieList();
            if(zlist ~= nil) then
                for i=0, zlist:size()-1 do
                    local zombie = zlist:get(i);
                    if zombie:getCurrentSquare():getRoom() == currentRoom then 
                        wakeZombie(zombie, wakeAll);
                    end
                end
            end
        end
    end
end

local function wakeUpZombiesInTargetsBuilding(target)
    if target ~= nil then
        local currentBuilding = target:getCurrentSquare():getBuilding();
        if currentBuilding ~= nil then
            local wakeAll = coinFlip();
            --print("Unlucky! Waking up zombies in building.");
            local zlist = player:getCell():getZombieList();
            if(zlist ~= nil) then
                for i=0, zlist:size()-1 do
                    local zombie = zlist:get(i);
                    if zombie:getCurrentSquare():getBuilding() == currentBuilding then 
                        wakeZombie(zombie, wakeAll);
                    end
                end
            end
        end
    end
end

--Each triggering action has a small chance to wake up the whole building
local function rollSetZombieActive(target)
    if probabilityCheck(wakeBuildingChance) then --CHANCE: waking zombies in building
        wakeUpZombiesInTargetsBuilding(target);
    else --CHANCE: waking zombies in room
        wakeUpZombiesInTargetsRoom(target);        
    end
end

local function onHitZombie(source, target)
    --xor, check if hit is between zombie and player
    local onlyOneIsPlayer = source ~= nil and target ~= nil and source:isZombie() ~= target:isZombie();
    
    if onlyOneIsPlayer then
        local zombie = source;

        if target:isZombie() then
            zombie = target;
        end

        aggroZombie(zombie);

        if probabilityCheck(hitChance) then --CHANCE: waking zombies on hit
            rollSetZombieActive(zombie)
        end
    end
end

local function onCollideWithZombie(source, target)
    --xor, check if collision is between zombie and player
    local onlyOneIsPlayer = source ~= nil and target ~= nil and source:isZombie() ~= target:isZombie();

    if onlyOneIsPlayer then
        local zombie = source;

        if target:isZombie() then
            zombie = target;
        end

        aggroZombie(zombie);

        if probabilityCheck(collisionChance) then --CHANCE: waking zombies on collision
            rollSetZombieActive(zombie)
        end
    end
end

local function onMove()
    stepCounter = stepCounter + 1; 
    if stepCounter >= 100 then 
        stepCounter = 0;
        local player = getPlayer();
        if isCharacterOutside(player) == false then
            if player:isSneaking() == false then
                if probabilityCheck(stepLoudlyChance) then --CHANCE: waking zombies if you step loudly
                    --print("Did not sneak while inside");
                    rollSetZombieActive(player);
                end
            elseif player:isSneaking() and player:isRunning() then
                if probabilityCheck(stepLoudlyChance*0.5) then --CHANCE: waking zombies while sneak running (only in room)
                    --print("Sneak ran while inside but were too clumsy");
                    wakeUpZombiesInTargetsRoom(player);
                end
            end
        end
    end
end

--DEBUG: UNCOMMENT TO BE ABLE TO RELOAD MOD
Events.OnTick.Add(initialise);

--events
Events.OnGameStart.Add(initialise);

--calc hour must be done at game start and then every hour because it initializes the time of day variable
Events.EveryHours.Add(calculateHour);

--calc rain done every ten minutes to check for rain updates (DISABLED FOR NOW)
Events.EveryTenMinutes.Add(calculateRain);

--gridsquare functions that were modified from original fear the rain.
Events.LoadGridsquare.Add(addBuildingList);
Events.ReuseGridsquare.Add(removeBuildingList);

--Check for each zombie
Events.OnZombieUpdate.Add(zCheck);
Events.OnPlayerUpdate.Add(updateCounters);

--player actions that might wake up zombies
Events.OnWeaponHitCharacter.Add(onHitZombie);
Events.OnCharacterCollide.Add(onCollideWithZombie);
Events.OnPlayerMove.Add(onMove);

----- MOD OPTIONS SUPPORT ------
if ModOptions and ModOptions.getInstance then
    local function fearTheSunOnModOptionsApply(optionValues)
		FearTheSun.FearTheRain = optionValues.settings.options.FearTheRain
    end

	function fearTheSunOnModOptionsApplyInGame(optionValues)
		fearTheSunOnModOptionsApply(optionValues);
    end

    local SETTINGS = {
        options_data = {
            FearTheRain = {
                name = getText("UI_FearTheRain"),
                tooltip = getText("UI_FearTheRainDesc"),
                default = false,
                OnApplyMainMenu = fearTheSunOnModOptionsApply,
                OnApplyInGame = fearTheSunOnModOptionsApplyInGame,
            },
        },

        mod_id = 'FearTheSun',
        mod_shortname = getText("UI_ModName"),
        mod_fullname = getText("UI_ModName"),
    }

    ModOptions:getInstance(SETTINGS);
    ModOptions:loadFile();
	
	Events.OnGameStart.Add(function() fearTheSunOnModOptionsApplyInGame({ settings = SETTINGS }); end);
end