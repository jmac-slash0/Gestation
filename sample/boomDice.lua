--[[
Author: Fatal-Optimism, 2013

boomDice.lua
Dice roller concept
]]

-- Get a random seed each time this is called, otherwise using random() isn't so random
math.randomseed(os.time())

-- A dice roll function with blow-up crits on min value (bad), max value (good)
-- Not sure if crits should always go up, and critfails should always go down
function diceRoll(dice, sides)
    result = 0
    hadCrit = false
    hadCritFail = false
    
    for i = 1, dice do
        
        rolling = true
        while rolling do
            roll = math.random(1, sides)
            --print("Rolled a " .. roll)
            
            -- Roll hits maximum value, critical! Add to result value and roll again!
            if roll == sides then
                --if hadCrit then str = "Another Crit! +" else str = "Crit! +" end
                result = result + roll
                --print(str .. roll)
                hadCrit = true
                
            -- Roll hits minimum value, critical fail! Subtract from result value and roll again!
            elseif roll == 1 then
                --if hadCritFail then str = "Another CritFail! -" else str = "CritFail! -" end
                result = result - roll
                --print(str .. roll)
                hadCritFail = true
                
            -- We're done rolling
            else
                rolling = false
                if hadCritFail then
                    result = result - roll
                else
                    result = result + roll
                end
            end
        end
    end
    
    return result
end

-- A quick compare function for tables
function compare3(a, b)
  return a[1] < b[1]
end

function compare2(a, b)
  return a[2] > b[2]
end

sum = 0
count = 0
min = 0
max = 0
wins = 0
fails = 0
norms = 0
results = {}

for i=1, 1000000 do
    num = diceRoll(1, 6)
    
    found = false
    for key, value in pairs(results) do
        if value[1] == num then
            value[2] = value[2] + 1
            found = true
            break
        end
    end
    
    if not found then table.insert(results, {num, 1}) end

    sum = sum + num
    count = count + 1
    
    if num > max then 
        max = num 
    elseif num < min then 
        min = num 
    end
    
    if num > 6 then 
        wins = wins + 1 
    elseif num > 1 then 
        norms = norms + 1 
    else 
        fails = fails + 1 
    end
    
    if i == 10000 then table.sort(results, compare2) end
    
end


print("Avg:", sum/count)
print("Min:", min)
print("Max:", max)
print("Fails:", fails)
print("Norms:", norms)
print("Wins:", wins)


table.sort(results, compare3)
--file = io.open("values-" .. os.time() .. ".csv", "w")
print()
for key, value in pairs(results) do
    print("Found " .. value[2] .. " instances of " .. value[1])
    --file:write(value[1] .. "," .. value[2] .. "\n")
end

--file:close()