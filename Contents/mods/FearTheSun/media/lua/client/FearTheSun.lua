--      based off FearTheRain by Stephanus van Zyl AKA Viceroy                                                                               #

building_table = {};


--as squares are loaded, add the associated buildings to a table
function addBuildingList(_square)
    local sq = _square;
    if sq then 
            if sq:isOutside() == false
                then building_table[sq:getBuilding()] = sq:getBuilding();
            else end
    end   
end --end add building function

--as squares are unloaded, remove the associated buildings from the table.
function removeBuildingList(_square)
    local sq = _square;
    if sq then 
            if sq:isOutside() == false
                then building_table[sq:getBuilding()] = nil;
            else end
    end   
end --end remove building function

function isBuildingListEmpty()
    count = 0
    for i, v in pairs(building_table) do 
    count = count + 1;
    end
    if count ~= 0 then return false
    else return true
    end
end

--calc the IsDay variable
function calculateHour()
    pillowmod = getPlayer():getModData();
    pillowmod.currentHour = math.floor(math.floor(GameTime:getInstance():getTimeOfDay() * 3600) / 3600);
    if pillowmod.currentHour >= 5 and pillowmod.currentHour <= 19 then
        pillowmod.IsDay = true
    else pillowmod.IsDay = false end 

end --end calc hour function 

function updateZCounter()
    pillowmod = getPlayer():getModData();
    if pillowmod.zCounter == nil or pillowmod.zCounter >= 2000
        then pillowmod.zCounter = 1;
        elseif pillowmod.zCounter <= 2001
        then pillowmod.zCounter = pillowmod.zCounter + 1;
    else end 
end 

-- calculate the closeset building in the list
function calcClosestBuilding(_square)
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
function lureZombiePathSound(zombie)
        sourcesq = zombie:getCurrentSquare();
        targetsq = calcClosestBuilding(sourcesq);
        zombie:pathToSound(targetsq:getX(), targetsq:getY(), targetsq:getZ());
end

--lure zombie to closest building using path
function lureZombiePathLocation(zombie)
        sourcesq = zombie:getCurrentSquare();
        targetsq = calcClosestBuilding(sourcesq);
        zombie:pathToLocation(targetsq:getX(), targetsq:getY(), targetsq:getZ());
end

function zombieStop(zombie)
        zombie:changeState(ZombieIdleState.instance());
        targetsq = zombie:getCurrentSquare();
        val = ZombRand(-5,5);
        zombie:pathToLocation(targetsq:getX()+val, targetsq:getY()+val, targetsq:getZ());
end

function isZombieIdle(zombie)
    if zombie:isMoving() == false
        then b = true;
        else b = false;
    end 
    return b
end

function isZombieOutside(zombie)
    if zombie:getCurrentSquare():isOutside() == false 
        then b = false;
        else b = true;
    end
    return b 
end

function zResetCommand(zombie)
    zombie:getModData().commandSent = false;
end 

function zombieHasCommand(zombie)
    if zombie:getModData().commandSent == nil 
    then 
        b = false;
    else 
        b =  zombie:getModData().commandSent;
    end
    return b
end

function zCheck(zombie)

    --initialize wake tick, decrement it
    if zombie:getModData().awakeTick == nil or zombie:getModData().awakeTick < 0
        then zombie:getModData().awakeTick = 1;
    else zombie:getModData().awakeTick = zombie:getModData().awakeTick - 1;
    end 

    if isZombieOutside(zombie) == false and zombie:getModData().awakeTick > 1 
        then return
    else end 

    if pillowmod.IsDay 
        then
            zDayRoutine(zombie);
        else
            zNightRoutine(zombie);
    end

end

function zDayRoutine(zombie)
    -- day, inside
    if zombieHasCommand(zombie) == false and isZombieOutside(zombie) == false and pillowmod.zCounter <= 1000
        then 
            zombie:getModData().commandSent = true;
            zombie:setUseless(true); 
            zombie:getModData().docile = true;
            zombie:DoZombieStats();
    -- day, outside, lure via sound or location
    elseif (zombieHasCommand(zombie) == false and isZombieOutside(zombie) and pillowmod.zCounter >= 300 and pillowmod.zCounter <=1099 ) 
        or(zombieHasCommand(zombie) == false and isZombieOutside(zombie) and isZombieIdle(zombie))
        then 
            zombie:getModData().commandSent = true;
            zombie:getModData().docile = false;
            if ZombRand(1)==0
                then lureZombiePathSound(zombie);
                else lureZombiePathLocation(zombie);
            end 
    -- day, help un-stuck zombie
    elseif zombieHasCommand(zombie) == false and isZombieOutside(zombie) and pillowmod.zCounter >= 1799 and pillowmod.zCounter <= 1899
        then 
            zombie:getModData().commandSent = true;
            zombie:getModData().docile = false;
            zombieStop(zombie);
    elseif pillowmod.zCounter >= 1900
        then zResetCommand(zombie) ;
    else end

end 

function zNightRoutine(zombie)

        if pillowmod.zCounter  == 100
            then 
            zombie:setMoving(true);
            zombie:setVariable("bMoving", true);
            zombie:setFakeDead(false);
            zombie:setUseless(false); 
            zombie:getModData().docile = false;
            zombie:DoZombieStats();
            zResetCommand(zombie) ;
        else end
end




--not sure any other methods to get the zombie list, so get the whole cell
--compare each one to the same room as player, and then wake them up.
function smackZombie()
    currentroom = getPlayer():getCurrentSquare():getRoom();
    print("smacked a zombie, waking up it's friends.");
    local zlist = getPlayer():getCell():getZombieList();
            if(zlist ~= nil) then
                for i=0, zlist:size()-1 do
                    if  zlist:get(i):getCurrentSquare():getRoom() == currentroom
                        then 
                            zlist:get(i):setFakeDead(false);
                            zlist:get(i):setUseless(false); 
                            zlist:get(i):getModData().docile = false;
                            zlist:get(i):getModData().awakeTick = 500;
                    else end
                end
        end
end 

function zIgniteZombie(zombie)
    end 




--calc hour must be done at game start and then every hour because it initializes the time of day variable
Events.OnGameStart.Add(calculateHour);
Events.EveryHours.Add(calculateHour);

--gridsquare functions that were modified from original fear the rain.
Events.LoadGridsquare.Add(addBuildingList);
Events.ReuseGridsquare.Add(removeBuildingList);

Events.OnZombieUpdate.Add(zCheck);
Events.OnPlayerUpdate.Add(updateZCounter);


--waking zombie functions, every hour since it really should happen just once unlesss player moves to a new cell
Events.OnWeaponHitCharacter.Add(smackZombie);
