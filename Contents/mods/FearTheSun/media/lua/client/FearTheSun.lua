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

--calc the IsDay variable
function calculateHour()
    pillowmod = getPlayer():getModData();
    pillowmod.currentHour = math.floor(math.floor(GameTime:getInstance():getTimeOfDay() * 3600) / 3600);
    if pillowmod.currentHour >= 5 and pillowmod.currentHour <= 17 then
        pillowmod.IsDay = true
    else pillowmod.IsDay = false end 

end --end calc hour function 

-- This function iterates through all the building that are currently loaded and plays 5-10 sounds inside to draw zombies
function lureZombiesInside()
   -- print("running lure");
    pillowmod = getPlayer():getModData();
    if pillowmod.IsDay == true then
        for id, b in pairs(building_table) do
            for i = 0, ZombRand(1,3) do
                sq = b:getRandomRoom():getRandomSquare();
                if sq ~= nil
                    then
                        --print("drawing zombies inside");
                        addSound(nil , sq:getX(), sq:getY(), sq:getZ(), ZombRand(25,50), ZombRand(25,50));
                else end -- end null square check
            end -- end for loops to create multiple sounds
        end --end for building loop
    else end --end is day check

end --end lure function

--directly path the zombies to the nearst building based on calcClosestBuilding
function lureZombiesInsideTwo()
    pillowmod = getPlayer():getModData();
    if pillowmod.IsDay == true then
        local zlist = getPlayer():getCell():getZombieList();
        if(zlist ~= nil) then
            for i=0, zlist:size()-1 do
                z = zlist:get(i);
                if z:getModData().docile then
                    return
                else
                    sourcesq = z:getCurrentSquare();
                    targetsq = calcClosestBuilding(sourcesq);
                    z:pathToLocation(targetsq:getX(), targetsq:getY(), targetsq:getZ());
                    z:setVariable("bPathfind", false);
                    z:setVariable("bMoving", true);
                end
            end
        end 
    end 

end 

function goInside(zombie)
z = zombie;
end --end goinside function


-- calculate the closeset building in the list
function calcClosestBuilding(_square)
    sourcesq = _square ;
    local closest = nil;
    local closestDist = 1000000;
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
    return closest
end 

--this function is extra loud to draw zombies more because sometimes they're too far to hear it
function megaLureZombiesInside()
   -- print("running megalure");
    pillowmod = getPlayer():getModData();
        if pillowmod.LureTick == nil then pillowmod.LureTick = 0 end

        if pillowmod.IsDay == true and pillowmod.LureTick >= 2 then
        for id, b in pairs(building_table) do
            for i = 0, ZombRand(1,3) do
                sq = b:getRandomRoom():getRandomSquare();
                if sq ~= nil then
                    --print("drawing zombies inside");
                    addSound(nil , sq:getX(), sq:getY(), sq:getZ(), ZombRand(200,300), ZombRand(200,300));
                else end -- end null square check
                pillowmod.LureTick = 0;
            end -- end for loops to create multiple sounds
        end --end for building loop
        else 
            pillowmod.LureTick = pillowmod.LureTick + 1 ;
        end --end is day check

end --end mega lure function

function callZombsOut()
    --this function is too laggy. Figure out a better way to handle this.

    if pillowmod.IsDay == false then
        for id, sq in pairs(outside_table) do
            addSound(nil , sq:getX(), sq:getY(), sq:getZ(), ZombRand(50,200), ZombRand(50,200));
            if verboseDebug then
            end
        end
    else end

end --end call zomb out function


--this should definitely query the whole cell zombie list
--set them to inactive when they are inside a building and it's daytime.
--chance of the zombie being fake dead or simply standing uselessly
function setDocileZombs()
    local zlist = getPlayer():getCell():getZombieList();
        if(zlist ~= nil) then
            for i=0, zlist:size()-1 do
                if zlist:get(i):getCurrentSquare():isOutside() == false and pillowmod.IsDay
                    then 
                        if ZombRand(4)+1 == ZombRand(4)+1 
                            and  (zlist:get(i):getModData().docile == nil
                                or zlist:get(i):getModData().docile == false)
                        then 
                            z = zlist:get(i);
                            z:setMoving(false);
                            z:setFakeDead(true);
                            z:getModData().docile = true
                            z:setVariable("bMoving", false);
                            z:DoZombieStats();
                        elseif  (zlist:get(i):getModData().docile == nil
                                or zlist:get(i):getModData().docile == false)
                        then 
                            z = zlist:get(i);
                            z:setMoving(false);
                            z:setUseless(true); 
                            z:getModData().docile = true
                            z:setVariable("bMoving", false);
                            z:DoZombieStats();
                        end
                        
                else 

                end
            end
        end
end 

--wake zombies up
function setActiveZombs()
    pillowmod = getPlayer():getModData();
    local zlist = getPlayer():getCell():getZombieList();
        if(zlist ~= nil) then
            for i=0, zlist:size()-1 do
                if pillowmod.IsDay == false
                    then 
                        z =zlist:get(i);
                        z:setMoving(true);
                        z:setFakeDead(false);
                        z:setUseless(false); 
                        z:getModData().docile = false;
                        z:DoZombieStats();
                elseif pillowmod.IsDay == true and zlist:get(i):getCurrentSquare():isOutside() == true
                    then 
                        z =zlist:get(i);
                        z:setMoving(true);
                        z:setFakeDead(false);
                        z:setUseless(false); 
                        z:getModData().docile = false;
                        z:DoZombieStats();
                else end
            end
        end
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
                else end
            end
        end
end 

--calc hour must be done at game start and then every hour because it initializes the time of day variable
Events.OnGameStart.Add(calculateHour);
Events.EveryHours.Add(calculateHour);

--gridsquare functions that were modified from original fear the rain.
Events.LoadGridsquare.Add(addBuildingList);
Events.ReuseGridsquare.Add(removeBuildingList);

--luring and chill zombie out functions every 10 minute because its core mod functionality
Events.EveryHours.Add(lureZombiesInsideTwo);
Events.EveryTenMinutes.Add(lureZombiesInside);
Events.EveryTenMinutes.Add(setDocileZombs);
Events.EveryHours.Add(megaLureZombiesInside);



--waking zombie functions, every hour since it really should happen just once unlesss player moves to a new cell
Events.EveryHours.Add(setActiveZombs);
Events.OnWeaponHitCharacter.Add(smackZombie);

--Events.EveryHours.Add(callZombsOut); --this function is too laggy.