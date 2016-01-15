local Animal = class "Animal"

function Animal:init(parentToCopyFrom)
	self.position = Vector(0, 0)
	self.size = 30
	self.speed = 25
	self.color = Color(0, 180, 0)
	self.bodyNodes = {
		Vector(-self.size/2, self.size/2),
		Vector(self.size/2, self.size/2),
		Vector(self.size/2, -self.size/2),
		Vector(-self.size/2, -self.size/2)
	}
	self.eyeNodes = {
		Vector(-self.size/2 + 6, self.size/2 - 1),
		Vector(self.size/2 - 6, self.size/2 - 1),
	}
	self.pupilNodes = {
		Vector(-self.size/2 + 6, self.size/2 + 3),
		Vector(self.size/2 - 6, self.size/2 + 3)
	}
	self.eyesightNodes = {
		{
			Vector(-self.size/2 + 6, self.size/2 + 10),
			Vector(-self.size/2 + 10, self.size/2 + 110),
			Vector(-self.size/2 - 76, self.size/2 + 110)
		},
		{
			Vector(self.size/2 - 6, self.size/2 + 10),
			Vector(self.size/2 - 10, self.size/2 + 110),
			Vector(self.size/2 + 76, self.size/2 + 110)
		}
	}
	self.generation = 1
	self.foodEaten = 0
	self.foodToHaveChild = 500
	self.hearDistance = 150
	self.smellDistance = 300
	self.health = 1
	self.healthLossToNotEating = 0.04
	self.dead = false
	self.isZapping = false
	self.spearPosition = {Vector(0, 0), Vector(0, 0), Vector(0, 0), Vector(0, 0)}
	self.foodSinceBirth = 0
	
	self.brain = NeuralNetwork(parentToCopyFrom)

	self.leftClock = math.random()
	self.rightClock = math.random()

	self.movementAngle = 0


	--[[
		output data:
		{
			left wheel velocity,
			right wheel velocity
		}
	]]
	self.outputData = {}

	self.shallowCopy = function(t)
		local new = {}
		for i, v in pairs(t) do
			new[i] = v
		end
		return new
	end	

	self.getNewPoint = function(p)
		local theta = self.movementAngle - math.pi / 2
		return Vector (	
			math.cos(theta) * p.x - math.sin(theta) * p.y + self.position.x,
			math.sin(theta) * p.x + math.cos(theta) * p.y + self.position.y
		)
	end

end

function Animal:update(dt)
	local colorSpottedOne = Color(0, 0, 0)
	colorSpottedOne.black = 0
	local colorSpottedTwo = Color(0, 0, 0)
	colorSpottedTwo.black = 0
	local foodMagnitudeOne = nil
	local foodMagnitudeTwo = nil
	local enemyMagnitudeOne = nil
	local enemyMagnitudeTwo = nil
	local enemySpottedOne = false
	local enemySpottedTwo = false
	local spearTarget
	local function pointIsInTriangle(point, a, b, c)
		local function sign(p1, p2, p3)
			return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y)
		end
		local b1 = sign(point, a, b) < 0
		local b2 = sign(point, b, c) < 0
		local b3 = sign(point, c, a) < 0
		return b1 == b2 and b2 == b3
	end
	local function checkEyeCollisions(eyeIndex, eye, node, isLookingAtFood)
		local magnitudeOfSpotted = nil
		local a = self.getNewPoint(eye[1])
		local b = self.getNewPoint(eye[2])
		local c = self.getNewPoint(eye[3])
		local colorSpot = eyeIndex == 1 and colorSpottedOne or colorSpottedTwo
		local didFind = false
		if not magnitudeOfSpotted then
			if pointIsInTriangle(node, a, b, c) then
				didFind = true
				magnitudeOfSpotted = (a - node).magnitude
			end
		elseif (a - node).magnitude < magnitudeOfSpotted then
			if pointIsInTriangle(node, a, b, c) then
				didFind = true
				magnitudeOfSpotted = (a - node).magnitude
			end
		end
		if didFind then
			if isLookingAtFood then
				colorSpot.black = 255
			else
				if eyeIndex == 1 then
					enemySpottedOne = true
				else
					enemySpottedTwo = true
				end
			end
		end
		return magnitudeOfSpotted
	end
	for i, animal in ipairs(simulator.animals) do
		if self ~= animal and (animal.position - self.position).magnitude < 300 then
			-- check vision
			local eyes = {
				self.eyesightNodes[1],
				self.eyesightNodes[2]
			}
			local nodes = self.shallowCopy(animal.bodyNodes)
			table.insert(nodes, Vector(animal.position.x, animal.position.y))
			for j, node in ipairs(nodes) do
				node = animal.getNewPoint(node)
				for k, eye in ipairs(eyes) do
					local magnitudeResult = checkEyeCollisions(k, eye, node)
					if magnitudeResult then
						local dist = 1 - (magnitudeResult / 110)
						if k == 1 then
							enemyMagnitudeOne = dist
						else
							enemyMagnitudeTwo = dist
						end
					end
				end
			end
			-- check zapping
			for i, point in ipairs(self.spearPosition) do
				if (animal.position - point).magnitude < animal.size and not spearTarget then
					spearTarget = animal
				end
			end
		end
	end
	local didFindFood = false
	for i, food in ipairs(simulator.food) do
		if self:isOnFood(food) then
			food.remaining = food.remaining - (self.outputData[4] or 0)
			self.health = self.health + (self.outputData[4] or 0) * dt
			self.foodEaten = self.foodEaten + (self.outputData[4] or 0)
			self.foodSinceBirth = self.foodSinceBirth + (self.outputData[4] or 0)
			if math.floor(self.foodEaten) % self.foodToHaveChild == 0 and self.foodEaten > 1 then
				self.foodEaten = self.foodEaten + 1
				self:GiveBirth()
			end
			if self.health > 1 then
				self.health = 1
			end
			if food.remaining <= 0 then
				table.remove(simulator.food, i)
			end
			didFindFood = true
	 	else
			self.health = self.health - (self.outputData[4] or 0) / 1000 * dt 
		end
		if (food.position - self.position).magnitude < 300 then
			local eyes = {
				self.eyesightNodes[1],
				self.eyesightNodes[2]
			}
			local foodCorners = {
				Vector(food.position.x, food.position.y),
				Vector(food.position.x, food.position.y + food.size),
				Vector(food.position.x + food.size, food.position.y),
				Vector(food.position.x + food.size, food.position.y + food.size),
				Vector(food.position.x + food.size/2, food.position.y + food.size/2)
			}
			for j, node in ipairs(foodCorners) do
				for k, eye in ipairs(eyes) do
					local magnitude = checkEyeCollisions(k, eye, node, true)
					if magnitude then
						local dist = 1 - (magnitude / 110)
						if k == 1 then
							if not foodMagnitudeOne then
								foodMagnitudeOne = dist
							elseif dist < foodMagnitudeOne then
								foodMagnitudeOne = dist
							end
						else
							if not foodMagnitudeTwo then
								foodMagnitudeTwo = dist
							elseif dist < foodMagnitudeTwo then
								foodMagnitudeTwo = dist
							end
						end
					end
				end
			end
		end
	end
	self.brain:FeedData {
		self.leftClock,		
		self.rightClock,		
		didFindFood and 1 or 0,

		colorSpottedTwo.black / 255,
		enemySpottedTwo and 1 or 0,

		colorSpottedOne.black / 255,
		enemySpottedOne and 1 or 0,

		spearTarget and 1 or 0
	}
	self.outputData = self.brain:GetOutputData()
	if self.outputData[8] > 0.2 then
		if spearTarget then
			spearTarget.health = spearTarget.health - self.outputData[8] * dt
			self.health = self.health + self.outputData[8] * dt
			self.foodEaten = self.foodEaten + 4
			self.foodSinceBirth = self.foodSinceBirth + 4
			if self.foodSinceBirth >= 500 then
				self:GiveBirth()
				self.foodSinceBirth = 0
			end
			self.isZapping = true
		else
			self.health = self.health - self.outputData[8] * dt
			self.isZapping = false
		end
	end
	self.color = Color(self.outputData[5] * 255, self.outputData[6] * 255, self.outputData[7] * 255)
	self.position = self.position + (Vector(math.cos(self.movementAngle), math.sin(self.movementAngle)) * ((self.speed + (self.outputData[3] * self.speed * 3)) * dt))
	if self.position.x + self.size > SCREEN_WIDTH then
		self.position = Vector(SCREEN_WIDTH - self.size, self.position.y)
		self.movementAngle = self.movementAngle + math.pi
	elseif self.position.x - self.size < 0 then
		self.position = Vector(self.size, self.position.y)
		self.movementAngle = self.movementAngle + math.pi 
	end
	if self.position.y + self.size > SCREEN_HEIGHT then
		self.position = Vector(self.position.x, SCREEN_HEIGHT - self.size)
		self.movementAngle = self.movementAngle + math.pi
	elseif self.position.y - self.size < 0 then
		self.position = Vector(self.position.x, self.size)
		self.movementAngle = self.movementAngle + math.pi 
	end
	local angle = (self.outputData[2] - self.outputData[1]) / 10
	self.movementAngle = self.movementAngle + angle / 5
	if self.health > 1 then
		self.health = 1
	end
	self.health = self.health - dt * self.healthLossToNotEating
	if self.health <= 0 then
		for i, animal in ipairs(simulator.animals) do
			if animal == self then
				table.remove(simulator.animals, i)
				break
			end
		end
	end
	local bodyNodes = self.shallowCopy(self.bodyNodes)
	for i, v in ipairs(bodyNodes) do
		bodyNodes[i] = self.getNewPoint(v)
	end
	local slope = (-1 / ((bodyNodes[2].y - bodyNodes[1].y) / (bodyNodes[2].x - bodyNodes[1].x))) 
	local midpoint = Vector(bodyNodes[1].x + ((bodyNodes[2].x - bodyNodes[1].x) / 2), bodyNodes[1].y + ((bodyNodes[2].y - bodyNodes[1].y) / 2))
	local angle = math.deg(math.abs(self.movementAngle)) % 360
	local multiplier = (angle >= 270 or angle <= 90) and 1 or -1
	local point1 = Vector(midpoint.x + math.cos(math.atan(slope)) * 100 * multiplier, midpoint.y + math.sin(math.atan(slope)) * 100 * multiplier)
	local point2 = Vector(midpoint.x + math.cos(math.atan(slope)) * 80 * multiplier, midpoint.y + math.sin(math.atan(slope)) * 80 * multiplier)
	local point3 = Vector(midpoint.x + math.cos(math.atan(slope)) * 60 * multiplier, midpoint.y + math.sin(math.atan(slope)) * 60 * multiplier)
	local point4 = Vector(midpoint.x + math.cos(math.atan(slope)) * 40 * multiplier, midpoint.y + math.sin(math.atan(slope)) * 40 * multiplier)
	local point5 = Vector(midpoint.x + math.cos(math.atan(slope)) * 20 * multiplier, midpoint.y + math.sin(math.atan(slope)) * 20 * multiplier)
	self.spearPosition = {point1, point2, point3, point4}
end

function Animal:draw()
	DRAW.setColor(self.color)
	-- draw the animal's square body
	local bodyNodes = self.shallowCopy(self.bodyNodes)
	for i, v in ipairs(bodyNodes) do
		bodyNodes[i] = self.getNewPoint(v)
	end
	for i, v in ipairs(bodyNodes) do
		if i == #bodyNodes then
			DRAW.line(v.x, v.y, bodyNodes[1].x, bodyNodes[1].y)
		else
			DRAW.line(v.x, v.y, bodyNodes[i + 1].x, bodyNodes[i + 1].y)
		end
	end
	-- draw tail
	local slope = (-1 / ((bodyNodes[4].y - bodyNodes[3].y) / (bodyNodes[4].x - bodyNodes[3].x))) + math.cos(TIMER.getTime() * 15) / 1.5
	local midpoint = Vector(bodyNodes[3].x + ((bodyNodes[4].x - bodyNodes[3].x) / 2), bodyNodes[3].y + ((bodyNodes[4].y - bodyNodes[3].y) / 2))
	local angle = math.deg(math.abs(self.movementAngle)) % 360
	local multiplier = (angle <= 270 and angle >= 90) and 1 or -1
	local point = Vector(midpoint.x + math.cos(math.atan(slope)) * 25 * multiplier, midpoint.y + math.sin(math.atan(slope)) * 25 * multiplier)
	DRAW.line(midpoint.x, midpoint.y, point.x, point.y)
	-- draw eyes
	for i, eye in ipairs(self.eyeNodes) do
		eye = self.getNewPoint(eye)
		DRAW.setColor(Color(0, 0, 0))
		DRAW.circle("fill", eye.x, eye.y, 7)
		DRAW.setColor(Color(255, 255, 255))
		DRAW.circle("fill", eye.x, eye.y, 5)
	end
	DRAW.setColor(Color(0, 0, 0))
	for i, pupil in ipairs(self.pupilNodes) do
		pupil = self.getNewPoint(pupil)
		DRAW.circle("fill", pupil.x, pupil.y, 3)
	end
	DRAW.setColor(Color(255, 153, 0))
	for i, triangle in ipairs(self.eyesightNodes) do
		for j, point in ipairs(triangle) do
			local node, connect
			if j == #triangle then
				node, connect = self.getNewPoint(point), self.getNewPoint(triangle[1])
			else
				node, connect = self.getNewPoint(point), self.getNewPoint(triangle[j + 1])
			end
			DRAW.line(node.x, node.y, connect.x, connect.y)
		end
	end
	-- draw spear
	local slope = (-1 / ((bodyNodes[2].y - bodyNodes[1].y) / (bodyNodes[2].x - bodyNodes[1].x))) 
	local midpoint = Vector(bodyNodes[1].x + ((bodyNodes[2].x - bodyNodes[1].x) / 2), bodyNodes[1].y + ((bodyNodes[2].y - bodyNodes[1].y) / 2))
	local angle = math.deg(math.abs(self.movementAngle)) % 360
	DRAW.setColor((self.outputData[8] or 0) >= 0.2 and Color(255, 255, 0) or self.color)
	DRAW.line(midpoint.x, midpoint.y, self.spearPosition[1].x, self.spearPosition[1].y)
	for i, point in ipairs(self.spearPosition) do
		DRAW.circle("fill", point.x, point.y, (self.outputData[8] or 0) >= 0.2 and 8 or 3)
	end
	-- draw the health bar
	DRAW.setColor(Color(255, 0, 0))
	DRAW.rectangle("fill", self.position.x + self.size/2, self.position.y + self.size/2, 6, 40)
	DRAW.setColor(Color(0, 255, 0))
	DRAW.rectangle("fill", self.position.x + self.size/2, (self.position.y + self.size/2) + (40 - (self.health * 40)), 6, self.health * 40)
	-- draw needed stats
	DRAW.setColor(Color(50, 50, 50))
	DRAW.rectangle("fill", self.position.x + self.size/2 + 9, self.position.y + self.size/2, 30, 40)
	DRAW.setFont(SMALLFONT)
	DRAW.setColor(Color(255, 255, 255))
	DRAW.printf(self.generation, self.position.x + self.size/2 + 10, self.position.y + self.size/2 + 2, 100, "left")
	DRAW.printf(math.floor(self.foodEaten), self.position.x + self.size/2 + 10, self.position.y + self.size/2 + 12, 100, "left")
	DRAW.setFont(BIGFONT)
end

function Animal:otherIsColliding(p, other)
	return Vector(other.position.x - p.x, other.position.y - p.y).magnitude < other.size
end

function Animal:feelerIsOnFood(feeler, food)
	return (
		feeler.finish.x > food.position.x and
		feeler.finish.y > food.position.y and
		feeler.finish.x < food.position.x + food.size and
		feeler.finish.y < food.position.y + food.size
	)
end

function Animal:isOnFood(food)
	return (
		food.position.x + food.size > self.position.x - self.size/2 and
		food.position.y + food.size > self.position.y - self.size/2 and
		food.position.x < self.position.x + self.size/2 and
		food.position.y < self.position.y + self.size/2
	)
end

function Animal:GiveBirth()
	local child = Animal(self)
	child.position = self.position
	child.generation = self.generation + 1
	child.movementAngle = math.random(360)
	child.leftClock = self.leftClock
	child.rightClock = self.rightClock
	if math.random() < 0.15 then
		child.leftClock = self.leftClock + ((math.random() - 0.5) * 2) / 5
	elseif math.random() < 0.15 then
		child.rightClock = self.rightClock + ((math.random() - 0.5) * 2) / 5
	end
	table.insert(simulator.animals, child)
end

return Animal

-------------



