local NeuralNetwork = class "NeuralNetwork"

-- Neuron is a local class to NeuralNetwork
local Neuron = class "Neuron"

function Neuron:init(row, col)
	self.axons = {}
	self.neuronsAttachedToMe = {}
	self.row = row
	self.col = col
	self.charge = 0
end

function Neuron:StringToRow(row, chanceToMakeConnection)
	for i, neuron in pairs(row) do
		if math.random() < chanceToMakeConnection then
			local axon = {
				connectedTo = neuron,
				colOfConnectedTo = neuron.col,
				rowOfConnectedTo = neuron.row,
				weight = (math.random() - 0.5) * 2
			}
			table.insert(self.axons, axon)
			table.insert(neuron.neuronsAttachedToMe, {
				neuron = self,
				axon = axon
			})
		end
	end
end

function Neuron:StringRowToNeuron(row, chanceToMakeConnection)
	for i, neuron in ipairs(row) do
		if math.random() < chanceToMakeConnection then
			local axon = {
				connectedTo = self,
				colOfConnectedTo = self.col,
				rowOfConnectedTo = self.row,
				weight = (math.random() - 0.5) * 2
			}
			table.insert(neuron.axons, axon)
			table.insert(self.neuronsAttachedToMe, {
				neuron = neuron,
				axon = axon
			})
		end
	end
end

function Neuron:GetChargeFromAxons()
	local charge = 0
	for i, axon in ipairs(self.axons) do
		charge = charge + axon.startsFrom.charge * axon.weight
	end
	return charge
end

-- start NeuralNetwork class

function NeuralNetwork:init(parentToCopyFrom)
	self.neurons = {}
	self.chanceToDevelopAxon = 0.7
	self.hiddenLayers = 1

	-- create three rows for self.neurons,
	-- 1) input
	-- 2) hidden layer
	-- 3) output
	
	-- create the outputs
	-- outputNames is both for reference and for drawing the brain
	self.outputNames = {
		"left wheel velocity",
		"right wheel velocity",
		"increased speed",
		"food eating force",
		"red color",
		"green color",
		"blue color",
		"zapping power"
	}

	self.inputNames = {
		"body clock one",
		"body clock two",
		"is on plant",

		"left eye food",
		"left eye animal",

		"right eye food",
		"right eye animal",

		"animal is on spear"
	}

 
	-- inherit brain from parent
	if parentToCopyFrom then
		for i, row in ipairs(parentToCopyFrom.brain.neurons) do
			self.neurons[i] = {}
			for j, neuronToCopy in ipairs(row) do
				self.neurons[i][j] = Neuron(i, j)
			end
		end
		for i, row in ipairs(parentToCopyFrom.brain.neurons) do
			for j, neuronToCopy in ipairs(row) do
				local neuron = self.neurons[i][j]
				for k, axon in ipairs(neuronToCopy.axons) do
					local toAttachTo = self.neurons[axon.rowOfConnectedTo][axon.colOfConnectedTo]
					if toAttachTo then
						table.insert(neuron.axons, {
							connectedTo = toAttachTo,
							rowOfConnectedTo = axon.rowOfConnectedTo,
							colOfConnectedTo = axon.colOfConnectedTo,
							weight = axon.weight
						})
						table.insert(toAttachTo.neuronsAttachedToMe, {
							axon = axon,
							neuron = neuron
						})
					end
				end
			end
		end
		local mutationsToMake = math.random(4, 9)
		for i = 1, mutationsToMake do
			local roll = math.random()
			local mutationType = (
				roll <= 0.22 and "weightChange" or	-- 22%
				roll <= 0.44 and "axonRedirect" or	-- 22%
				roll <= 0.66 and "axonRemove" or	-- 22%
				roll <= 0.88 and "axonAdd" or		-- 22%
				roll <= 0.94 and "neuronAdd" or		-- 6%
				"neuronRemove"						-- 6%
			)
			if mutationType == "weightChange" then
				local row = self.neurons[math.random(2, #self.neurons - 1)]
				local neuron = row[math.random(#row)]
				if #neuron.axons > 0 then
					local axon = neuron.axons[math.random(#neuron.axons)]
					axon.weight = axon.weight + (math.random() - 0.5) / 2
				end
			elseif mutationType == "axonRedirect" then
				local rowIndex = math.random(#self.neurons - 1)
				local row = self.neurons[rowIndex]
				local neuron = row[math.random(#row)]
				if #neuron.axons > 0 then
					local axon = neuron.axons[math.random(#neuron.axons)]
					local row2 = self.neurons[rowIndex + 1]
					local neuronToGoTo = row2[math.random(#row2)]
					for i, connection in ipairs(axon.connectedTo.neuronsAttachedToMe) do
						if connection.axon == axon then
							table.remove(axon.connectedTo.neuronsAttachedToMe, i)
							break
						end
					end
					axon.connectedTo = neuronToGoTo
					axon.colOfConnectedTo = neuronToGoTo.col
					axon.rowOfConnectedTo = neuronToGoTo.row
					table.insert(neuronToGoTo.neuronsAttachedToMe, {
						neuron = neuron,
						axon = axon
					})
				end
			elseif mutationType == "axonRemove" then
				local rowIndex = math.random(#self.neurons - 1)
				local row = self.neurons[rowIndex]
				local neuron = row[math.random(#row)]
				if #neuron.axons > 0 then
					local axon = neuron.axons[math.random(#neuron.axons)]
					local toRemove = {}
					for i, nextRowNeuron in ipairs(self.neurons[rowIndex + 1]) do
						for q, connection in ipairs(nextRowNeuron.neuronsAttachedToMe) do
							if connection.axon == axon then
								table.insert(toRemove, q)
							end
						end
					end
					table.sort(toRemove, function(a, b)
						return a > b
					end)
					for i, v in ipairs(toRemove) do
						table.remove(self.neurons[rowIndex + 1], v)
					end
				end
				table.remove(neuron.axons, math.random(#neuron.axons))
			elseif mutationType == "axonAdd" then
				local rowIndex = math.random(#self.neurons - 1)
				local row = self.neurons[rowIndex]
				local neuron = row[math.random(#row)]
				local row2 = self.neurons[rowIndex + 1]
				local neuronToAttachTo = row2[math.random(#row2)]
				local axon = {
					connectedTo = neuronToAttachTo,
					colOfConnectedTo = neuronToAttachTo.col,
					rowOfConnectedTo = neuronToAttachTo.row,
					weight = (math.random() - 0.5) * 2
				}
				table.insert(neuronToAttachTo.neuronsAttachedToMe, {
					neuron = neuron,
					axon = axon
				})
				table.insert(neuron.axons, axon)
			elseif mutationType == "neuronAdd" then
				local rowIndex = math.random(2, #self.neurons - 1)
				local row = self.neurons[rowIndex]
				local neuron = Neuron(rowIndex, #row + 1)
				neuron:StringToRow(self.neurons[rowIndex + 1], 0.6)
				neuron:StringRowToNeuron(self.neurons[rowIndex - 1], 0.6)
				table.insert(self.neurons[rowIndex], neuron)
			elseif mutationType == "neuronRemove" then
				local rowIndex = math.random(2, #self.neurons - 1)
				local row = self.neurons[rowIndex]
				if #row > 1 then
					local neuronIndex = math.random(#row)
					local neuron = row[neuronIndex]
					for i, neuronToReduce in ipairs(row) do
						if i > neuronIndex then
							neuronToReduce.col = neuronToReduce.col - 1
						end
					end
					for i, connection in ipairs(neuron.neuronsAttachedToMe) do
						for j, axon in ipairs(connection.neuron.axons) do
							if axon.connectedTo == neuron then
								table.remove(connection.neuron.axons, j)
								break
							end
						end
					end
					table.remove(row, neuronIndex)
				end
			end
		end
	-- else create new brain
	else	
		-- create outputs
		self.neurons[self.hiddenLayers + 2] = {}
		for i = 1, #self.outputNames do
			self.neurons[self.hiddenLayers + 2][i] = Neuron(self.hiddenLayers + 2, i)
		end

		-- create middle layers
		for i = self.hiddenLayers + 1, 2, -1 do
			self.neurons[i] = {}
			-- create a random number of hidden neurons
			for j = 1, math.random(4, 9) do
				local neuron = Neuron(i, j)
				-- attach new neuron to outputs
				neuron:StringToRow(self.neurons[i + 1], self.chanceToDevelopAxon)
				self.neurons[i][j] = neuron
			end
		end

		-- create the inputs
		self.neurons[1] = {}
		for i = 1, #self.inputNames do
			self.neurons[1][i] = Neuron(1, i)
		end

		for i, neuron in ipairs(self.neurons[1]) do
			neuron:StringToRow(self.neurons[2], 0.4)
			neuron:StringToRow(self.neurons[3], 0.3)
			neuron:StringToRow(self.neurons[#self.neurons], 0.2)
		end

		-- manually wire an axon to eat food
		local foundEatAxon = false
		for i, axon in ipairs(self.neurons[1][3].axons) do
			if axon.connectedTo == self.neurons[self.hiddenLayers + 2][4] then
				foundEatAxon = true
				break
			end
		end
		if not foundEatAxon then
			local axon = {
				connectedTo = self.neurons[self.hiddenLayers + 2][4],
				colOfConnectedTo = self.neurons[self.hiddenLayers + 2][4].col,
				rowOfConnectedTo = self.neurons[self.hiddenLayers + 2][4].row,
				weight = 1
			}
			table.insert(self.neurons[1][3].axons, axon)
			table.insert(self.neurons[self.hiddenLayers + 2][4].neuronsAttachedToMe, {
				axon = axon,
				neuron = self.neurons[1][3]
			})
		end
	end
end

function NeuralNetwork:update(dt)

end

function NeuralNetwork:draw()
	local corner = Vector(120, 255)
	local neuronDistance = Vector(120, 50)
	local queuedCircleDrawings = {}
	DRAW.setColor(Color(38, 38, 38, 200))
	DRAW.rectangle("fill", 5, 5, 180 + #self.neurons * neuronDistance.x, 50 + #self.inputNames * 50)
	for i, row in ipairs(self.neurons) do
		for j, neuron in ipairs(row) do
			local neuronPosition = Vector(corner.x + (i - 1) * neuronDistance.x, (corner.y + (j - 1) * neuronDistance.y) - #row * neuronDistance.y / 2)
			for u, axon in ipairs(neuron.axons) do
				if i ~= #self.neurons and axon.connectedTo then
					if axon.weight > 0 then
						DRAW.setColor(Color(0, 0, 190))
					else
						DRAW.setColor(Color(255, 255, 255))
					end
					DRAW.line(
						neuronPosition.x, 
						neuronPosition.y, 
						(corner.x + (axon.connectedTo.row - 1) * neuronDistance.x),
						(corner.y + (axon.connectedTo.col - 1) * neuronDistance.y) - #self.neurons[axon.connectedTo.row] * neuronDistance.y / 2
					)
				end
			end
		end
	end
	for i, row in ipairs(self.neurons) do
		for j, neuron in ipairs(row) do
			local neuronPosition = Vector(corner.x + (i - 1) * neuronDistance.x, (corner.y + (j - 1) * neuronDistance.y) - #row * neuronDistance.y / 2)
			DRAW.setColor(Color(0, 0, 190))
			DRAW.circle("fill", neuronPosition.x, neuronPosition.y, 12)
			DRAW.setColor(Color(255 - neuron.charge * 255, 255 - neuron.charge * 255, 255 - neuron.charge * 255))
			DRAW.circle("fill", neuronPosition.x, neuronPosition.y, 10)
			if i == 1 then
				DRAW.setColor(Color(0, 255, 0))
				DRAW.printf(self.inputNames[j], neuronPosition.x - 115, neuronPosition.y - 5, 100, "right")
			elseif i == self.hiddenLayers + 2 then
				DRAW.setColor(Color(0, 255, 0))
				DRAW.printf(self.outputNames[j], neuronPosition.x + 15, neuronPosition.y - 5, 200, "left")
			end
		end
	end
end

-- start non-event functions

--[[
	data comes in form of:
	{
		clock #1,
		clock #2,
		hearing
	}
]] --
function NeuralNetwork:FeedData(data)
	if not self.neurons then
		return
	end
	for i, stat in ipairs(data) do
		stat = math.min(math.max(stat, 0), 1)
		self.neurons[1][i].charge = stat
	end
	for i = 2, self.hiddenLayers + 2 do
		for j, neuron in ipairs(self.neurons[i]) do
			local sum = 0
			for u, prev in ipairs(neuron.neuronsAttachedToMe) do
				sum = sum + prev.axon.weight * prev.neuron.charge
			end
			local charge = 1 / (1 + math.exp(-sum * 3))
			if i == self.hiddenLayers + 2 then
				neuron.charge = math.max(math.min(sum, 1), 0)
			else
				if charge > 0.3 then
					neuron.charge = charge
				else
					neuron.charge = 0
				end
			end
		end
	end
end

function NeuralNetwork:GetOutputData()
	local output = {}
	for i, neuron in ipairs(self.neurons[self.hiddenLayers + 2]) do
		output[i] = neuron.charge or 0
	end
	for i = 1, #self.outputNames do
		output[i] = output[i] or 0
	end
	return output
end

function NeuralNetwork:Wipe()
	self.isEngineered = true
	self.neurons = {}
	self.neurons[1] = {}
	self.neurons[2] = {}
	self.neurons[3] = {}
	for i = 1, #self.inputNames do
		self.neurons[1][i] = Neuron(1, i)
	end
	for i = 1, 6 do
		self.neurons[2][i] = Neuron(2, i)
	end
	for i = 1, #self.outputNames do
		self.neurons[3][i] = Neuron(3, i)
	end
end

--[[
	axons in form of
	{
		start neuron row,
		start neuron col,
		finish neuron row,
		finish neuron col,
		axon weight
	}
]]
function NeuralNetwork:PushAxons(axons)
	for i, info in ipairs(axons) do
		local axon = {
			connectedTo = self.neurons[info[3]][info[4]],
			rowOfConnectedTo = info[3],
			colOfConnectedTo = info[4],
			weight = info[5]
		}
		table.insert(self.neurons[info[1]][info[2]].axons, axon)
		table.insert(self.neurons[info[3]][info[4]].neuronsAttachedToMe, {
			neuron = self.neurons[info[1]][info[2]],
			axon = axon
		})
	end
end

return NeuralNetwork
