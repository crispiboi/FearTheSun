--       FearTheRain by Stephanus van Zyl AKA Viceroy                                                                               #

square_table = {};
verboseDebug = false;

function checkGridSquare(_square)

    local sq                    = _square;
    local sqN                   = sq:getN();
    local sqW                   = sq:getW();
    local sqS                   = sq:getS();
    local sqE                   = sq:getE();
    
    local self_hasWall          = IsoObjectType.wall;
    local self_isWindowW        = IsoFlagType.windowW;
    local self_isWindowN        = IsoFlagType.windowN;
    local self_isDoorW          = IsoFlagType.doorW;
    local self_isDoorN          = IsoFlagType.doorN;
    local self_isExterior       = IsoFlagType.exterior;
            
    if ( sq and sqN and sqW and sqE and sqS ) then 
    
        if sq:getZ() == 0 then  -- We can safely (for now) ignore any doors or windows on higher levels 
                
            if ( sq:Is(self_isDoorN) or sq:Is(self_isWindowN) ) then
            
                if not sqN:isOutside() then
                    square_table[tostring( sqN:getX() ) .. ":" .. tostring( sqN:getY() ) .. ":" .. tostring( sqN:getZ() )] = sqN;

                elseif not sqS:isOutside() then
                    square_table[tostring( sqS:getX() ) .. ":" .. tostring( sqS:getY() ) .. ":" .. tostring( sqS:getZ() )] = sqS;   
                    
                end             
                                        
            elseif ( sq:Is(self_isDoorW) or sq:Is(self_isWindowW) ) then
            
                if not sqE:isOutside() then
                    square_table[tostring( sqE:getX() ) .. ":" .. tostring( sqE:getY() ) .. ":" .. tostring( sqE:getZ() )] = sqE;

                elseif not sqW:isOutside() then
                    square_table[tostring( sqW:getX() ) .. ":" .. tostring( sqW:getY() ) .. ":" .. tostring( sqW:getZ() )] = sqW;   
                    
                end             
                
            end
            
        end
            
    end
        
end

-- This function is called on reusegridsquare to remove the windows and doors that are no longer loaded.
function removeGridSquare(_square)

    local sq                    = _square;  
    
    if sq then
        square_table[tostring( sq:getX() ) .. ":" .. tostring( sq:getY() ) .. ":" .. tostring( sq:getZ() )] = nil;
        if verboseDebug then
            print(tostring( sq:getX() ) .. ":" .. tostring( sq:getY() ) .. ":" .. tostring( sq:getZ() ) .. " removed from table");
        end
            
    end
    
end

-- This function attracts zombies every ten minutes in-game to each entry in square_table, AKA our windows und doors.
function lureZombiesToEntrances()
    currentHour = math.floor(math.floor(GameTime:getInstance():getTimeOfDay() * 3600) / 3600);
    if currentHour >= 7 and currentHour <= 18 then
        IsDay = true
    else IsDay = false end 

    if IsDay then
        for id, sq in pairs(square_table) do
            addSound(nil , sq:getX(), sq:getY(), sq:getZ(), 50, 50);
            if verboseDebug then
            --print(tostring( sq:getX() ) .. ":" .. tostring( sq:getY() ) .. ":" .. tostring( sq:getZ() ) .. " WANTS TO LURE ZEDS");
            end
        end
    else end

end

Events.LoadGridsquare.Add(checkGridSquare);
Events.ReuseGridsquare.Add(removeGridSquare);
Events.EveryTenMinutes.Add(lureZombiesToEntrances);

--Events.OnThunderStart.Add(TheyCome);
