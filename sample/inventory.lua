--[[
Author: Fatal-Optimism, 2013

inventory.lua
An inventory implementation in Lua with some OOP. Used as a project to learn Lua. From memory, I think
the moving and logging sections (and maybe find?) are incomplete.

Classes: Item, Cell, Inventory
]]

-- [Item Class] --
Item =
{
	weight = 0,
    sizeX = 1,
    sizeY = 1,
    coords = {{}},
    description = "Blank Item"
}

-- Constructor
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
-- [/Item Class] --


-- [Cell Class] --
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
-- [/Cell Class] --


-- [Inventory Class] --
-- Oh Shit
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

-- build
-- Quick note on 2D lists and x,y coordinates: i=y(outer loop),j=x(inner loop)
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

-- modify - Modify the cells at the coordinates given as coordList; switchy determines
-- if the modification is the Occupied (0) or Usable (1) status; switches the flips!
-- The cell can also be told what item it is on it
function Inventory:modify(coordList, incItem, switchy)
	local switch = switchy or 0
	local item = incItem or nil
	local x = 0
	local y = 0
	local myLog = ""

	for key, coords in pairs(coordList) do
		x = coords[1]
		y = coords[2]

		if x > 0 and x <= self.sizeX and y > 0 and y <= self.sizeY then
			if switch == 0 then

				myLog = "Switching isOccupied state..."

				-- Switch the cell's state to the opposite state
				self.inv[y][x].isOccupied = not self.inv[y][x].isOccupied

				-- If a cell is now occupied, give it the occupying item
				if self.inv[y][x].isOccupied and item ~= nil then
					myLog = myLog .. " to occupied"
					self.inv[y][x].heldItem = item
				-- Otherwise the cell is becoming unoccupied, remove the item
				else
					myLog = myLog .. " to unoccupied"
					self.inv[y][x].heldItem = nil
				end

			elseif switch == 1 then
				myLog = "Switching isUsable state"
				self.inv[y][x].isUsable = not self.inv[y][x].isUsable
			end
		end
	end

	if self.logging then
		self.invLog["modify"] = self.invLog["modify"] .. myLog .. "\n"
	end
end

-- addItem - Add an item to the inventory at the specified x and y coordinates
function Inventory:add(item, x, y)
	local canPlace = false
	local added = false
	local underLimit = true
	local coordList = {}
	local myLog = ""

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
end

-- Find out if an item is at the specified coordinates
function Inventory:find(targetCoord)
	local foundItem = nil
	local mylog = ""

	-- Note the X Y reversal
	foundItem = self.inv[targetCoord[2]][targetCoord[1]].heldItem

	if foundItem ~= nil then
		myLog = "Found '" .. tostring(foundItem) .. "' at " .. targetCoord[1] .. "," .. targetCoord[2]
	else
		myLog = "Cound not find anything at " .. tostring(targetCoord)
	end

	if self.logging then
		self.invLog["find"] = self.invLog["find"] .. myLog .. "\n"
	end

	-- Check if an item has the specified coordinate (i.e. check for item at [1, 1])
	-- Go through each item
--~ 	for i, currentItem in ipairs(self.items) do
--~ 		-- Go through each coordinate the current item has
--~ 		for j, coord in ipairs(currentItem.coords) do

--~ 			if coord[1] == targetCoord[1] and coord[2] == targetCoord[2] then
--~ 				foundItem = currentItem
--~ 				break
--~ 			end
--~ 		end
--~ 	end

	return foundItem
end

-- Delete an item from the inventory by coordinate location
function Inventory:delete(targetCoord)
	local deleted = false
	local item = self:find(targetCoord)
	local annoying = 0
	local myLog = ""

	if item ~= nil then
		self.currentWeight = self.currentWeight - item.weight -- Modify weight
		self.items[item] = nil -- Remove reference to item, let lua garbage collection do its thing
		self:modify(item.coords) -- Modify cells
		myLog = "Deletion successful\n\n"
	else
		myLog = "Deletion failed\n\n"
	end

	-- Updates find log, because this function is entirely dependent on it
	if self.logging then
		self.invLog["find"] = self.invLog["find"] .. myLog .. "\n"
	end
end

-- Move an item by coordinates
function Inventory:move(toCoord, fromCoord)
	local canPlace = true
	local item = self:find(fromCoord)
	local x = toCoord[1]
	local y = toCoord[2]
	local newCoords = {}
	local currentCoords = item.coords
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
					if  not self.inv[j][i].isUsable then
						myLog = "An unusable cell blocked the item placement at " .. j .. "," .. y
						canPlace = false
						break
					elseif self.inv[j][i].isOccupied and self.inv[j][i].heldItem ~= item then
						myLog = "A foreign occupied cell blocked the item placement at " .. j .. "," .. y
						canPlace = false
						break
					end
				end
			end

			-- Add item to our list of inventory items
			if canPlace then
				self:modify(currentCoords) -- Unmark old cells
				self:modify(newCoords, item) -- Mark new cells
				item.coords = coordList -- Tell item where it is
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
print("\nTesting Item:")
a = Item:new()
b = Item:new(3, 2)

b.description = "Item2"
b.weight = 100

print("Item Size Comparison: " .. a.sizeX .. " vs " .. b.sizeX)
print(a)
print(b)

-- Cell
print("\nTesting Cell:")
c = Cell:new()
d = Cell:new(5, 5)

c.isOccupied = true
print(c)
print(d)

-- Inventory
print("\nTesting Inventory:")
invy = Inventory:new(5, 5)
invy.logging = true
invy2 = Inventory:new()
print(invy.sizeX .. ":" .. invy.sizeY)
print(invy2.sizeX .. ":" .. invy2.sizeY)

invy:build()

num1 = 1
num2 = 1
print("Inserting " .. b:toString() .. " at " .. num1 .. "," .. num2)
invy:add(b, num1, num2)

print(invy)
print("Found item: " .. tostring(invy:find({1, 1})))
invy:move({1,1}, {2,2})
--invy:delete({1,1})
print(invy.items[1])
print("Deleted item.")
print(invy)

-- Move is broken and so is dynamically printing logs

print(invy.invLog["build"])
print(invy.invLog["add"])
print(invy.invLog["modify"])
print(invy.invLog["find"])
print(invy.invLog["move"])

for key, value in ipairs(invy.invLog) do
	print("um")
	print(key)
	print(value)
end
