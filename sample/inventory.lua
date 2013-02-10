--[[
Author: Fatal-Optimism, 2013

inventory.lua
An inventory implementation in Lua with some OOP. Used as a simple project to learn Lua. Has basic functionality
but may contain bugs in certain conditions and use cases. The idea is to simulate an inventory system like you
might find in a game like X-COM: UFO Defense (1994). See here: http://www.ufopaedia.org/images/f/fe/Slots.png

So you might have a number of inventory spaces, of varying sizes or capacities, in grid format. So the backpack
would be 3x3, and the belt would be 2x4, with the bottom middle two slots unavailable for use. Expected
functionality is for items to be placed in areas in an inventory if they meet the size requirements. Then they
may be moved, deleted, or searched for.

The logic of the inventory is this: an Inventory is made up of a number of Cell objects. The Cell objects know
where their location is in the inventory, their current status (open, closed, occupied), and what item, if any
is occupying it.

Classes: Item, Cell, Inventory
--]]


--[[
Item Class

An item knows where it is in the inventory, and can be added, moved, and deleted from an inventory.
--]]
Item =
{
    weight = 0,
    sizeX = 1,
    sizeY = 1,
    coords = {},
    description = "Blank Item"
}

-- Constructor
-- A bit funky because Lu
function Item:new(x, y)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    self.__tostring = Item.toString

    o.sizeX = x or self.sizeX
    o.sizeY = y or self.sizeY

    return o
end

-- ToString
function Item:toString()
	return self.description
end


--[[
Cell Class

An Inventory will essentially hold a bunch of Cells. The Cells know their current state (occupied, usable), and 
conveniently contain a reference to the object that is occupying them.
--]]
Cell =
{
    posX = -1,
    posY = -1,
    isOccupied = false,
    isUsable = true,
    heldItem = nil
}

-- Constructor
function Cell:new(x, y)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    self.__tostring = Cell.toString

    o.posX = x or self.posX
    o.posY = y or self.posY

    return o
end

-- ToString
function Cell:toString()
    local str = "[" .. self.posX .. "," .. self.posY .. "]"

    if not self.isUsable then
        str = "     "
    elseif self.isOccupied then
        str = "[ + ]"
    end

    return str
end


--[[
Inventory Class

An Inventory will manage Cells and Items, and allow for a variety of customizable Inventory objects to be
created. Also takes advantage of some of the cool things about Lua tables to do logging. Here... we... go!
--]]
Inventory =
{
    inv = {}, -- 2D table
    invLog =
    {
        ["build"] = "",
        ["modify"] = "",
        ["add"] = "",
        ["find"] = "",
        ["move"] = "",
        ["delete"] = "",
    },
    logging = false,
    sizeX = 0,
    sizeY = 0,
    currentWeight = 0,
    weightLimit = 0,
    items = {},
    itemLimit = 0
}

-- Constructor
function Inventory:new(x, y)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    self.__tostring = Inventory.toString

    o.sizeX = x or self.sizeX
    o.sizeY = y or self.sizeY

    return o
end

-- ToString
function Inventory:toString()
    local str = ""

    -- Iterate through the Cell objects held in each table in Inv
    for i, b in ipairs(self.inv) do
        for j, a in ipairs(b) do
            str = str .. a:toString()
        end

        -- That stupid # gets the length of the table :<
        if i ~= #self.inv then
            str = str .. "\n"
        end
    end

    if str == "" then
        str = "[]"
    end

    return str
end

--[[ 
build

Using the specified size, create an inventory, building a series of tables and populating them with
Cell objects.

Quick note on 2D lists and x,y coordinates: i=y(outer loop),j=x(inner loop)
--]]
function Inventory:build()
    self.inv = {}
    
    for i = 1, self.sizeY do
        table.insert(self.inv, {})
        for j = 1, self.sizeX do
            table.insert(self.inv[i], Cell:new(j, i))
        end
    end

    if self.logging then
        self.invLog["build"] = self.invLog["build"] .. "Built new inventory " .. #self.inv[1] .. "x" .. #self.inv .. "\n"
    end
end

--[[ 
modify

Modify the cells at the coordinates given as coordList; switchy determines if the modification is the 
Occupied (0) or Usable (1) status; switches the flips! The cell can also be told what item it is on it.

Params: List of coordinates, [the item being placed thier], modify behavior (0 = default, flip occupied
state, 1 = flip usable state)

Returns: Number of cells modified
--]]
function Inventory:modify(coordList, incItem, switchy)
    local switch = switchy or 0
    local item = incItem or nil
    local x = 0
    local y = 0
    local myLog = ""
    local modifiedCount = 0

    -- For each set of coordinates...
    for i, coords in ipairs(coordList) do
        x = coords[1]
        y = coords[2]

        -- Check for correct params
        if x > 0 and x <= self.sizeX and y > 0 and y <= self.sizeY then
            if switch == 0 then

                -- Switch the cell's state to the opposite state
                self.inv[y][x].isOccupied = not self.inv[y][x].isOccupied
                myLog = myLog .. x .. "," .. y .. " switched to "

                -- If a cell is now occupied, give it the occupying item
                if self.inv[y][x].isOccupied and item ~= nil then
                    myLog = myLog .. "occupied"
                    self.inv[y][x].heldItem = item
                -- Otherwise the cell is becoming unoccupied, remove the item
                else
                    myLog = myLog .. "unoccupied"
                    self.inv[y][x].heldItem = nil
                end
                
                modifiedCount = modifiedCount + 1

            elseif switch == 1 then
                myLog = "Switching isUsable state"
                self.inv[y][x].isUsable = not self.inv[y][x].isUsable
                modifiedCount = modifiedCount + 1
            else
                myLog = "Unknown 3rd parameter for switch"
            end
        else
            myLog = "Coords " .. x .. ", " .. " out of scope " .. self.sizeX .. ", " .. self.sizeY
        end
        
        if i ~= #coordList then myLog = myLog .. "\n" end
    end

    if self.logging then
        self.invLog["modify"] = self.invLog["modify"] .. myLog .. "\n"
    end

    return modifiedCount
end

--[[ 
add

Add items to the inventory.

Params: the item to be added, and the key coordinates
Returns: bool success
--]]
function Inventory:add(item, coordStart)
    local canPlace = false
    local added = false
    local underLimit = true
    local coordList = {}
    local myLog = ""
    local x = coordStart[1]
    local y = coordStart[2]

    -- Check if under weight limit
    if self.weightLimit ~= 0 then
        if self.currentWeight + item.weight > self.weightLimit then
            underLimit = false
            myLog = "Over inventory weight limit: " .. item.weight ", " .. self.currentWeight .. "/" .. self.weightLimit
        end
    end

    -- Check if under item limit
    if self.itemLimit ~= 0 then
        if #items + 1 > self.itemLimit then
            underLimit = false
            myLog = "Over item number limit of " .. self.itemLimit
        end
    end

    -- Check for dupes
    if underLimit then
        for key, i in pairs(self.items) do
            if i == item then
                underLimit = false
                myLog = "Item '" .. item .. "' is already in the inventory (duplicate object)"
            end
        end
    end

    if underLimit then

        myLog = "Coordinates " .. x .. "," .. y .. " don't exist in inventory"
        -- Check if x and y parameters are within inventory size
        if x <= self.sizeX and x > 0 and y <= self.sizeY and y > 0 then
            myLog = "Item will run off the inventory's cells"

            -- Check if item size will run over inventory from specified position
            if x + item.sizeX - 1 <= self.sizeX and y + item.sizeY - 1 <= self.sizeY then

                canPlace = true
                -- Check if inventory has room
                for i = y, y + item.sizeY - 1 do
                    for j = x, x + item.sizeX - 1 do

                        -- Make a note of current coordinate
                        table.insert(coordList, {j, i})

                        -- Check if we can place an item at the current location
                        if self.inv[j][i].isOccupied or not self.inv[j][i].isUsable then
                            myLog = "An occupied or unusable cell blocked the item placement at " .. j .. "," .. y
                            canPlace = false
                            break
                        end
                    end
                end

                -- Add item to our list of inventory items
                if canPlace then
                    self.currentWeight = self.currentWeight + item.weight -- Adjust weight
                    self:modify(coordList, item) -- Mark used spots
                    item.coords = coordList -- Tell item where it is
                    table.insert(self.items, item) -- Add item to this inventory's list of held items
                    added = true
                    myLog = "'" .. tostring(item) .. "' has been added at " .. x .. "," .. y
                end
            end
        end
    end

    if self.logging then
        self.invLog["add"] = self.invLog["add"] .. myLog .. "\n"
    end
    
    return (underLimit and canPlace)
end

--[[ 
find

Find items at the specified coordinates in the inventory. Made convenient by having the Cell object know
what Item it is holding.

Params: coordinates to search {x, y}
Returns: the item if found, otherwise nil
--]]
function Inventory:find(targetCoord)
    local foundItem = nil
    local mylog = ""

    -- Note the X Y reversal (targetCoord format: {x, y})
    foundItem = self.inv[targetCoord[2]][targetCoord[1]].heldItem

    if foundItem ~= nil then
        myLog = "Found '" .. tostring(foundItem) .. "' at " .. targetCoord[1] .. "," .. targetCoord[2]
    else
        myLog = "Cound not find anything at " .. targetCoord[1] .. "," .. targetCoord[2]
    end

    if self.logging then
        self.invLog["find"] = self.invLog["find"] .. myLog .. "\n"
    end

    return foundItem
end

--[[ 
delete

Remove items from the inventory. To do: double check object reference removed from Cells as well

Params: Coordinates to remove an item from {x, y}
--]]
function Inventory:delete(targetCoord)
    local result = 0
    local item = self:find(targetCoord)
    local myLog = ""

    -- If item was found...
    if item ~= nil then
        result = self:modify(item.coords) -- Modify cells
        self.currentWeight = self.currentWeight - item.weight -- Update weight
        self.items[item] = nil -- Remove reference to item, let lua garbage collection do its thing
        myLog = "Deletion successful"
    else
        myLog = "Deletion failed"
    end

    myLog = myLog .. "(" .. result .. ") at " .. targetCoord[1] .. "," .. targetCoord[2]

    if self.logging then
        self.invLog["delete"] = self.invLog["delete"] .. myLog .. "\n"
    end
end

--[[ 
move

Move items around in the inventory

Params: location of the item {x, y}, location it should move to {x, y}
--]]
function Inventory:move(fromCoord, toCoord)
    local canPlace = true
    local item = self:find(fromCoord)
    local x = toCoord[1]
    local y = toCoord[2]
    local newCoords = {}
    local myLog = ""

    myLog = "Coordinates " .. x .. "," .. y .. " don't exist in inventory"
    -- Check if x and y parameters are within inventory size
    if x <= self.sizeX and x > 0 and y <= self.sizeY and y > 0 then

        myLog = "Item will run off the inventory's cells"
        -- Check if item size will run over inventory from specified position
        if x + item.sizeX - 1 <= self.sizeX and y + item.sizeY - 1 <= self.sizeY then

            -- Check if inventory has room
            for i = y, y + item.sizeY - 1 do
                for j = x, x + item.sizeX - 1 do

                    -- Make a note of current coordinate
                    table.insert(newCoords, {j, i})

                    -- Check if we can place an item at the current location
                    -- is already there or (is usable and is unoccupied)
                    if self.inv[j][i].heldItem == item or (self.inv[j][i].isUsable and not self.inv[j][i].isOccupied) then
                        canPlace = true -- This check is kind of reversed atm...
                    else
                        canPlace = false
                        myLog = "A bad cell blocked the item placement at " .. j .. "," .. y
                        break
                    end
                end
            end

            -- Add item to our list of inventory items
            if canPlace then
                self:modify(item.coords) -- Unmark old cells
                self:modify(newCoords, item) -- Mark new cells
                item.coords = newCoords -- Tell item where it is
                myLog = "'" .. tostring(item) .. "' has been moved from " .. tostring(fromCoord) .. " to "  .. tostring(toCoord)
            end
        end
    end

    if self.logging then
        self.invLog["move"] = self.invLog["move"] .. myLog .. "\n"
    end
end
-- [/Inventory Class] --




-- Testing
-- Testing idea: put messages from methods into a key mapping table, print the table

-- Item
--print("\nTesting Item:")
a = Item:new()
b = Item:new(3, 2)

b.description = "Item2"
b.weight = 100

--print("Item Size Comparison: " .. a.sizeX .. " vs " .. b.sizeX)
--print(a)
--print(b)

-- Cell
--print("\nTesting Cell:")
c = Cell:new()
d = Cell:new(5, 5)

c.isOccupied = true
--print(c)
--print(d)

-- Inventory
invy = Inventory:new(5, 5)
invy.logging = true
invy2 = Inventory:new()

invy:build()
invy:add(b, {1, 1})
invy:move({1,1}, {2,2})
invy:delete({2, 2})
invy:find({2, 2})

for key, value in pairs(invy.invLog) do
	print(key)
	print(value)
end

print(invy)
