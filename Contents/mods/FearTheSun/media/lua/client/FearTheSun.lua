--      based off FearTheRain by Stephanus van Zyl AKA Viceroy                                                                               #

--square_table = {};
inside_table = {};
--outside_table = {};
verboseDebug = false;

function checkGridSquare(_square)

    local sq                    = _square;
            
    if sq then 
        if sq:getZ() == 0 then  -- We can safely (for now) ignore any doors or windows on higher levels 
            if sq:isOutside() == false
                then inside_table[tostring( sq:getX() ) .. ":" .. tostring( sq:getY() ) .. ":" .. tostring( sq:getZ() )] = sq;
            else 
                    --outside table note used
                   -- outside_table[tostring( sq:getX() ) .. ":" .. tostring( sq:getY() ) .. ":" .. tostring( sq:getZ() )] = sq;
            end

        end
            
    end
        
end

-- This function is called on reusegridsquare to remove the windows and doors that are no longer loaded.
function removeGridSquare(_square)

    local sq                    = _square;  
    
    if sq then
        inside_table[tostring( sq:getX() ) .. ":" .. tostring( sq:getY() ) .. ":" .. tostring( sq:getZ() )] = nil;
        if verboseDebug then
            print(tostring( sq:getX() ) .. ":" .. tostring( sq:getY() ) .. ":" .. tostring( sq:getZ() ) .. " removed from table");
        end
            
    end
    
end

function calculateHour()
    pillowmod = getPlayer():getModData();
    pillowmod.currentHour = math.floor(math.floor(GameTime:getInstance():getTimeOfDay() * 3600) / 3600);
    if pillowmod.currentHour >= 6 and pillowmod.currentHour <= 18 then
        pillowmod.IsDay = true
    else pillowmod.IsDay = false end 

end 

-- This function attracts zombies every ten minutes in-game to each entry in square_table, AKA our windows und doors.
function lureZombiesInside()


    if pillowmod.IsDay then
        for id, sq in pairs(inside_table) do
            addSound(nil , sq:getX(), sq:getY(), sq:getZ(), ZombRand(50,200), ZombRand(50,200));
            if verboseDebug then
            --print(tostring( sq:getX() ) .. ":" .. tostring( sq:getY() ) .. ":" .. tostring( sq:getZ() ) .. " WANTS TO LURE ZEDS");
            end
        end
    else end

end

function callZombsOut()
    --this function is too laggy. Figure out a better way to handle this.

    if pillowmod.IsDay == false then
        for id, sq in pairs(outside_table) do
            addSound(nil , sq:getX(), sq:getY(), sq:getZ(), ZombRand(50,200), ZombRand(50,200));
            if verboseDebug then
            --print(tostring( sq:getX() ) .. ":" .. tostring( sq:getY() ) .. ":" .. tostring( sq:getZ() ) .. " WANTS TO LURE ZEDS");
            end
        end
    else end

end 


function setDocileZombs()

    local zlist = getPlayer():getCell():getZombieList();
        if(zlist ~= nil) then
            for i=0, zlist:size()-1 do
                --zlist:get(i):setUseless(false);
                if zlist:get(i):getCurrentSquare():isOutside() == false and pillowmod.IsDay
                    then 
                        if ZombRand(2)+1 == ZombRand(2)+1 
                            and  zlist:get(i):isFakeDead() == false
                            and  zlist:get(i):isUseless() == false
                        then 
                            zlist:get(i):setFakeDead(true);
                        elseif  zlist:get(i):isFakeDead() == false
                            and  zlist:get(i):isUseless() == false
                        then 
                            zlist:get(i):setUseless(true); 
                        end
                else 

                end
            end
        end
end 

function setActiveZombs()

    local zlist = getPlayer():getCell():getZombieList();
        if(zlist ~= nil) then
            for i=0, zlist:size()-1 do
                --zlist:get(i):setUseless(false);
                if pillowmod.IsDay == false
                    then 
                        zlist:get(i):setFakeDead(false);
                        zlist:get(i):setUseless(false); 
 
                else end
                --zlist:get(i):setFakeDead(true);
               -- tempx = zlist:get(i):getX() + ZombRand(-50,50);
                --tempy = zlist:get(i):getY() + ZombRand(-50,50);
                
                --zlist:get(i):PathTo(tempx,tempy,zlist:get(i):getZ(),true);
            end
        end
end 
Events.OnGameStart.Add(calculateHour);
Events.LoadGridsquare.Add(checkGridSquare);
Events.ReuseGridsquare.Add(removeGridSquare);
Events.EveryTenMinutes.Add(lureZombiesInside);
Events.EveryTenMinutes.Add(calculateHour);
Events.EveryTenMinutes.Add(setDocileZombs);
Events.EveryTenMinutes.Add(setActiveZombs);

--Events.EveryHours.Add(callZombsOut); --this function is too laggy.


---to make zombies go back outside
--on dusk, find all outside squares and make noises.