maxRecursion = 20
topLeft = 1
bottomLeft = 2
bottomRight = 3
topRight = 4
rooms = 1

nodes = {}

roomSizeLimit = 5
splitPercentage = { 42, 58 }

amountVerticalRooms = 0
amountHorizontalRooms = 0
roomDifferenceLimit = 2

doorTile = " +"
floorTile = " ."
wallTile = " #"

grid = {}
grid.width = 50
grid.height = 50
grid.pos = function (self, x, y) return (x * self.width + y)+1 end
grid.get = function (self, x, y) return self.data[self:pos(x, y)] end
grid.set = function (self, x, y, d) self.data[self:pos(x,y)] = d end
grid.data = {}
for y = 0, grid.height do
	for x = 0, grid.width do
		grid:set(x, y, " #")
	end
end

function ResetVariables()
	amountHorizontalRooms = 0
	amountVerticalRooms = 0
end

function CreateNode(isRoot, parent, rect)
    node = {}
    node.leftChild = nil
    node.rightChild = nil
    node.parent = parent
    node.rect = rect
    node.width = rect[topRight].x - rect[topLeft].x
    node.height = rect[bottomLeft].y - rect[topLeft].y 
    if(isRoot) then
	    node.level = 0
    else
	    if (node.height < 0) 
    		then node.height = 0 
    	end
    	node.level = parent.level + 1
    end
    node.id = 0
    node.vertical = PickDirection(node)
    DrawNode(node)
    return node
end

function DrawNode(node)
	--Loop through the locations the nodes rectangle covers
    local x, y
    for y = node.rect[topLeft].y, node.rect[bottomLeft].y do
        for x = node.rect[topLeft].x, node.rect[topRight].x do		
            if(IsInsideGrid(x, y)) then
            	if (x == node.rect[topLeft].x or x == node.rect[topRight].x 
            		or y == node.rect[topLeft].y or y == node.rect[bottomRight].y) then 
        			--If the position is on the edge of the rectangle it draws a wall "#"
					grid:set(x, y, wallTile)            	
            	else
        			--If not, it draws a floor "."
                	grid:set(x, y, floorTile)
            	end		
            end
    	end
    end 
end

function SplitNode(node)
    if (not node or (node.level >= maxRecursion)) then
        node.id = rooms
        rooms = rooms + 1
        return
    else        
    	--If the max number of recuirsions is not met, split the node into childNodes 
        local split = SplitFromNode(node)
        if (split == nil) then 
        	return 
        end
        --Create two new nodes with the current node as parent
        local r1,r2 = NodeRects(node, split)
        node.leftChild = CreateNode(false, node, r1)
        node.rightChild = CreateNode(false, node, r2)

        --Inserts the new nodes in a table and remove the parent node
        --After all nodes are created, I will loop through this table and place doors
        table.insert(nodes, node.leftChild)
        table.insert(nodes, node.rightChild)
        for i = 1, #nodes do
        	if(nodes[i] == node) then
        		table.remove(nodes, i)
        	end
        end
        --Draw every step of the level creation
        --draw_it(grid)

        --Using recursion to repeat this function until the max number of recursions is met 
        SplitNode(node.leftChild)
        SplitNode(node.rightChild)
    end
end

function PickDirection()
	--if there are more horizontal rooms than vertical rooms, add a vertical room
	if(amountHorizontalRooms >= amountVerticalRooms + roomDifferenceLimit) then
		amountVerticalRooms = amountVerticalRooms + 1
		return true
	--and vice versa
	elseif(amountVerticalRooms >= amountHorizontalRooms + roomDifferenceLimit) then
		amountHorizontalRooms = amountHorizontalRooms + 1
		return false
	end
	--if there are not that big of a difference in amount horizontal and vertical rooms, pick a random direction
    if (math.random(0, 1) == 0) then 
		amountVerticalRooms = amountVerticalRooms + 1
    	return true 
    else
		amountHorizontalRooms = amountHorizontalRooms + 1
    	return false 
    end
end

function SplitFromNode(node)
	--[[When splitting the node, I calculate a random percentage of the width or height,
	which will be where the split occurs]]

    if (node.vertical) then
        local r = math.floor(((math.random(splitPercentage[1], splitPercentage[2])/100) * node.width))
        --To make sure the rooms doesn't become to narrow, I set a minimum limit
        --which makes the rooms at least the size of the roomSizeLimit
        if (r < roomSizeLimit or r > node.width - roomSizeLimit) then 
        	return nil 
        else 
        	return node.rect[topLeft].x + r 
        end
    else
        local r = math.floor(((math.random(splitPercentage[1], splitPercentage[2])/100) * node.height))
        if (r < roomSizeLimit or r > node.height - roomSizeLimit) then 
        	return nil 
        else 
        	return node.rect[topLeft].y + r 
        end
    end
end

function NodeRects(node, split)
    --Creates two rectangles based on the split location and split it vertical or horizontally based on randomness
    local rect1, rect2
    if node.vertical then
        rect1 = {[topLeft] = node.rect[topLeft], [bottomLeft] = node.rect[bottomLeft], 
        	[topRight] = {x = split, y = node.rect[topRight].y}, [bottomRight] = { x = split, y = node.rect[bottomRight].y}}

        rect2 = {[topLeft] = { x = split, y = node.rect[topLeft].y }, [bottomLeft] = { x = split, y = node.rect[bottomLeft].y}, 
    		[topRight] = node.rect[topRight], [bottomRight] = node.rect[bottomRight]}
        return rect1,rect2
    else
        rect1 = {[topLeft] = node.rect[topLeft], [topRight] = node.rect[topRight], 
        	[bottomLeft] = { x = node.rect[bottomLeft].x, y = split}, [bottomRight] = { x = node.rect[bottomRight].x, y = split}}

        rect2 = {[topLeft] = { x=node.rect[topLeft].x, y = split}, [topRight] = { x = node.rect[topRight].x, 
        	y = split}, [bottomLeft] = node.rect[bottomLeft], [bottomRight] = node.rect[bottomRight]}
        return rect1,rect2
    end
end

function IsInsideGrid(x, y)
	return (x >= 1 and x <= grid.width - 1 and y >= 1 and y <= grid.height - 1)
end

function PlaceDoors()
	local hasDoorTop = false
	local hasDoorBottom = false
	local hasDoorLeft = false
	local hasDoorRight = false

	local xPos = nil
	local yPos = nil

	--Loops through all the nodes to check where the doors will be placed
	for i = 1, #nodes do 
		hasDoorTop = false
		hasDoorBottom = false
		hasDoorLeft = false
		hasDoorRight = false

		--Goes through the walls of the nodes rectangle to determine if there already is a door placed
		for x =  nodes[i].rect[topLeft].x, nodes[i].rect[topRight].x do
			if((grid:get(x, nodes[i].rect[topLeft].y)) == doorTile) then
				hasDoorTop = true			
			end	
			if((grid:get(x, nodes[i].rect[bottomLeft].y)) == doorTile) then
				hasDoorBottom = true		
			end			
		end
		for y =  nodes[i].rect[topLeft].y, nodes[i].rect[bottomLeft].y do
			if((grid:get(nodes[i].rect[topLeft].x, y)) == doorTile) then
				hasDoorLeft = true			
			end	
			if((grid:get(nodes[i].rect[topRight].x, y)) == doorTile) then
				hasDoorRight = true
			end			
		end


		--[[If no door is placed, check if the tile is passable around the middle of the wall
		if it is passable, place a door there]]
		if(not hasDoorTop) then
			xPos = math.ceil(nodes[i].rect[topLeft].x + (nodes[i].width * 0.5))
			yPos = nodes[i].rect[topLeft].y
			if(IsPassable(xPos, yPos)) then			
				grid:set(xPos, yPos, " +")
			end
		end
		if(not hasDoorBottom) then
			xPos = math.ceil(nodes[i].rect[topLeft].x + (nodes[i].width * 0.5))
			yPos = nodes[i].rect[bottomLeft].y
			if(IsPassable(xPos, yPos)) then			
				grid:set(xPos, yPos, " +")
			end
		end
		if(not hasDoorLeft) then
			xPos = nodes[i].rect[topLeft].x
			yPos = math.ceil(nodes[i].rect[topLeft].y + (nodes[i].height * 0.5))
			if(IsPassable(xPos, yPos)) then			
				grid:set(xPos, yPos, " +")
			end
		end
		if(not hasDoorRight) then
			xPos = nodes[i].rect[topRight].x
			yPos = math.ceil(nodes[i].rect[topRight].y + (nodes[i].height * 0.5))
			if(IsPassable(xPos, yPos)) then			
				grid:set(xPos, yPos, " +")
			end
		end
	end
end

function IsPassable(x, y)
	--If the location is at the border of the grid, return false since the one of the neighbors position might be outside of the grid
	if(not IsInsideGrid(x, y)) then
		return false
	end

	--Get the data of the current tile and its neighbours
	local gridData = grid:get(x, y)
	local gridDataRight = grid:get(x - 1, y)
	local gridDataLeft = grid:get(x + 1, y)
	local gridDataTop = grid:get(x, y - 1)
	local gridDataBottom = grid:get(x, y + 1)

	--Make sure the current gridData is a wall and check if the top/bottom or left/right neighbors are floor tiles
	if((gridData == wallTile and gridDataRight == floorTile and gridDataLeft == floorTile)
		or (gridData == wallTile and gridDataTop == floorTile and gridDataBottom == floorTile)) then
		return true
	end
	return false
end



function BinarySpaceParitioning()
	--Resets some variables if BSP is running more than once
	ResetVariables()
	--Create the root rectangle based on the grids width and height
	local rect = {
    	[topLeft] = {x = 0, y = 0},
    	[bottomLeft] = {x = 0, y = grid.height},
		[bottomRight] = {x = grid.width, y = grid.height},
    	[topRight] = {x = grid.width,y = 0}
	}
    SplitNode(CreateNode(true, nil, rect))
    PlaceDoors()

end

function DrawGrid(gridToDraw)
    local line = ""
    local file = io.open("GeneratedLevel.txt",'w')
    for y = 0, gridToDraw.height do
        for x = 0, gridToDraw.width do
            line = ""..line..(gridToDraw.data[gridToDraw:pos(x,y)] or 0)
        end
        print(line)
        --Prints out the level in a txt file
    	if file then
        	file:write(tostring(line).."\n")
    	end
        line = ""
    end
    if file then
		file:close()
	end
end

BinarySpaceParitioning()
DrawGrid(grid)

