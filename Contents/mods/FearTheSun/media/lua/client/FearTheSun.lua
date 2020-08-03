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
end 

--as squares are unloaded, remove the associated buildings from the table.
function removeBuildingList(_square)
    local sq = _square;
    if sq then 
            if sq:isOutside() == false
                then building_table[sq:getBuilding()] = nil;
            else end
    end   
end 

--calc the IsDay variable
function calculateHour()
    pillowmod = getPlayer():getModData();
    pillowmod.currentHour = math.floor(math.floor(GameTime:getInstance():getTimeOfDay() * 3600) / 3600);
    if pillowmod.currentHour >= 5 and pillowmod.currentHour <= 17 then
        pillowmod.IsDay = true
    else pillowmod.IsDay = false end 

end 

-- This function iterates through all the building that are currently loaded and plays 5-10 sounds inside to draw zombies
function lureZombiesInside()
    if pillowmod.IsDay then
        for id , b in ipairs(building_table) do
            print("drawing zombies inside");
            for i = 0 , ZombRand(5,10) do
                sq = b:getRandomRoom():getRandomSquare();
                addSound(sq , sq:getX(), sq:getY(), sq:getZ(), 300, 300);
            end 
        end 
    else end 

--    if pillowmod.IsDay then
--        for id, sq in pairs(inside_table) do
--            addSound(nil , sq:getX(), sq:getY(), sq:getZ(), ZombRand(100,200), ZombRand(100,200));
--            if verboseDebug then
--            end
--        end
--    else end
--

end

function callZombsOut()
    --this function is too laggy. Figure out a better way to handle this.

    if pillowmod.IsDay == false then
        for id, sq in pairs(outside_table) do
            addSound(nil , sq:getX(), sq:getY(), sq:getZ(), ZombRand(50,200), ZombRand(50,200));
            if verboseDebug then
            end
        end
    else end

end 

--this should definitely query the whole cell zombie list
--set them to inactive when they are inside a building and it's daytime.
--chance of the zombie being fake dead or simply standing uselessly
function setDocileZombs()
    local zlist = getPlayer():getCell():getZombieList();
        if(zlist ~= nil) then
            for i=0, zlist:size()-1 do
                if zlist:get(i):getCurrentSquare():isOutside() == false and pillowmod.IsDay
                    then 
                        if ZombRand(2)+1 == ZombRand(2)+1 
                            and  (zlist:get(i):getModData().docile == nil
                                or zlist:get(i):getModData().docile == false)
                        then 
                            zlist:get(i):setFakeDead(true);
                            zlist:get(i):getModData().docile = true
                        elseif  (zlist:get(i):getModData().docile == nil
                                or zlist:get(i):getModData().docile == false)
                        then 
                            zlist:get(i):setUseless(true); 
                            zlist:get(i):getModData().docile = true
                        end
                else 

                end
            end
        end
end 

--wake zombies up
function setActiveZombs()
    local zlist = getPlayer():getCell():getZombieList();
        if(zlist ~= nil) then
            for i=0, zlist:size()-1 do
                if pillowmod.IsDay == false
                    then 
                        zlist:get(i):setFakeDead(false);
                        zlist:get(i):setUseless(false); 
                        zlist:get(i):getModData().docile = false
 
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
Events.EveryTenMinutes.Add(lureZombiesInside);
Events.EveryTenMinutes.Add(setDocileZombs);

--waking zombie functions, every hour since it really should happen just once unlesss player moves to a new cell
Events.EveryHours.Add(setActiveZombs);
Events.OnWeaponHitCharacter.Add(smackZombie);

--Events.EveryHours.Add(callZombsOut); --this function is too laggy.