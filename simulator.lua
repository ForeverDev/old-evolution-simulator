local Simulator = class "Simulator"

function Simulator:init()
	self.timeMultiplier = 1
	self.paused = false
	self.animals = {}
	self.focusedAnimal = nil

	self.food = {}

	self.pixelsPerAnimal = 100000
	self.chanceToSpawnFoodPerNode = 0.25
	self.totalFoodCount = 0
	self.foodSize = 75
	self.ticksSinceLastFood = 0
	self.ticksToRegenFood = 50

	self.elapsedTime = 0
	
	for i = 1, SCREEN_PIXELS / self.pixelsPerAnimal do
		local animal = Animal()
		animal.position = Vector(math.random(SCREEN_WIDTH), math.random(SCREEN_HEIGHT))
		table.insert(self.animals, animal)
	end

	for x = 1, SCREEN_WIDTH, self.foodSize do
		for y = 1, SCREEN_HEIGHT, self.foodSize do
			if math.random() < self.chanceToSpawnFoodPerNode then
				table.insert(self.food, {
					position = Vector(x, y),
					size = self.foodSize,
					remaining = 100
				})
			end
		end
	end

	self.totalFoodCount = #self.food
end

function Simulator:update(dt, isRecurse)
	if self.paused then
		return
	end
	self.elapsedTime = self.elapsedTime + dt
	if #self.food < self.totalFoodCount and self.ticksSinceLastFood >= self.ticksToRegenFood then
		self.ticksSinceLastFood = 0
		local pickedSpot = Vector (
			math.random(math.floor(SCREEN_WIDTH / self.foodSize)) * self.foodSize + 1,
			math.random(math.floor(SCREEN_HEIGHT / self.foodSize)) * self.foodSize + 1
		)
		local createdFood = false
		while not createdFood do
			local spotAvailable = true
			for i, food in ipairs(self.food) do
				if food.position.x == pickedSpot.x and food.position.y == pickedSpot.y then
					spotAvailable = false
					break
				end
			end
			if not spotAvailable then
				pickedSpot = Vector (
					math.random(math.floor(SCREEN_WIDTH / self.foodSize)) * self.foodSize + 1,
					math.random(math.floor(SCREEN_HEIGHT / self.foodSize)) * self.foodSize + 1
				)
			else
				table.insert(self.food, {
					position = pickedSpot,
					size = self.foodSize,
					remaining = 100
				})
				createdFood = true
			end
		end
	end
	self.ticksSinceLastFood = self.ticksSinceLastFood + 1
	if not isRecurse then
		for i = 1, self.timeMultiplier - 1 do
			self:update(dt, true)
		end
	end
	for i, animal in ipairs(self.animals) do
		animal:update(dt)
	end
end

function Simulator:draw()
	for i, food in ipairs(self.food) do
		DRAW.setColor(Color(255 - food.remaining * 2.55, 255 - food.remaining * 2.55, 255 - food.remaining * 2.55))
		DRAW.rectangle("fill", food.position.x, food.position.y, food.size, food.size)
	end
	for i, animal in ipairs(self.animals) do
		animal:draw()
	end
	if self.focusedAnimal then
		self.focusedAnimal.brain:draw()
	end
	DRAW.setColor(Color(0, 255, 0))
	DRAW.print("time multiplier: " .. self.timeMultiplier, 10, SCREEN_HEIGHT - 20)
	DRAW.print("elapsed time: " .. ("%.2f"):format(self.elapsedTime), 10, SCREEN_HEIGHT - 35)
end

function Simulator:mousepressed(x, y, b)
	local function mouseIsInBounds(animal)
		return Vector(x - animal.position.x, y - animal.position.y).magnitude < animal.size
	end
	local foundAnimal = false
	for i, animal in ipairs(self.animals) do
		if mouseIsInBounds(animal) then
			self.focusedAnimal = animal
			foundAnimal = true
			break
		end
	end
	if not foundAnimal then
		self.focusedAnimal = nil
	end
end

function Simulator:keypressed(key)
	if key == "w" then
		self.timeMultiplier = self.timeMultiplier + 1
	elseif key == "s" then
		self.timeMultiplier = self.timeMultiplier - 1
	elseif key == "c" then
		local cmd, key = io.read():match("(.-) (.-)$")
		if cmd == "time" then
			self.timeMultiplier = math.floor(tonumber(key) or 1)
		elseif cmd == "skip" then
			self.skips = math.floor(tonumber(key) or 1)
			for i = 1, self.skips * 60 do
				self:update(1/60)
			end
		elseif cmd == "spawn" then
			if tonumber(key) == 1 then
				local animal = Animal()
				animal.position = Vector(SCREEN_WIDTH/2, SCREEN_HEIGHT/2)
				animal.leftClock = 1
				animal.rightClock = 0.5
				animal.brain:Wipe()
				animal.brain:PushAxons {
					-- bc1 -> h1
					{1, 1, 2, 1, 1},
					-- h1 -> lwv
					{2, 1, 3, 1, 0.6},
					-- h1 -> rwv
					{2, 1, 3, 2, 0.35},
					-- bc1 -> inc speed
					{1, 1, 3, 3, 0.5},
					-- iop -> eat plant
					{1, 3, 3, 4, 1},
					-- iop -> h1
					{1, 3, 2, 1, -1},
					-- lef -> lwv
					{1, 4, 3, 1, 0.5},
					-- lef -> rwv
					{1, 4, 3, 2, -0.5},
					-- ref -> lwv
					{1, 6, 3, 1, -0.5},
					-- ref -> rwv
					{1, 6, 3, 2, 0.5},
					-- bc1 -> green
					{1, 1, 3, 6, 1},
					-- lea -> lwv
					{1, 5, 3, 1, -1},
					-- lea -> rwv
					{1, 5, 3, 2, 1},
					-- lea -> inc speed
					{1, 5, 3, 3, -0.5},
					-- rea -> lwv
					{1, 7, 3, 1, 1},
					-- rea -> rwv
					{1, 7, 3, 2, -1},
					-- rea -> inc speed
					{1, 7, 3, 3, -0.5},
				}
				table.insert(self.animals, animal)
			elseif tonumber(key) == 2 then
				local animal = Animal()
				animal.position = Vector(SCREEN_WIDTH/2, SCREEN_HEIGHT/2)
				animal.leftClock = 1
				animal.rightClock = 0.5
				animal.brain:Wipe()
				animal.brain:PushAxons {
					-- bc1 -> h1
					{1, 1, 2, 1, 1},
					-- h1 -> lwv
					{2, 1, 3, 1, 0.6},
					-- h1 -> rwv
					{2, 1, 3, 2, 0.1},
					-- bc1 -> inc speed
					{1, 1, 3, 3, 0.5},
					-- bc1 -> green
					{1, 1, 3, 5, 1},
					-- lea -> lwv
					{1, 5, 3, 1, 1},
					-- lea -> rwv
					{1, 5, 3, 2, -1},
					-- rea -> lwv
					{1, 7, 3, 1, -1},
					-- rea -> rwv
					{1, 7, 3, 2, 1},
					-- rea -> inc speed
					{1, 7, 3, 3, 1},
					-- aiop -> zap
					{1, 8, 3, 8, 1}
				}
				table.insert(self.animals, animal)
			end
		end
	elseif key == "p" then
		self.paused = not self.paused
	end
	if self.timeMultiplier <= 0 then
		self.timeMultiplier = 1
	end
end

-- start non-event functions

return Simulator
