local Vector = class "Vector"

function Vector:init(x, y)
	self.x = x
	self.y = y
	self.slope = y / x
	self.magnitude = math.sqrt(x*x + y*y)
end

function Vector:unit()
	return Vector(self.x / self.magnitude, self.y / self.magnitude)
end

function Vector:printComp()
	print(("[%d, %d]"):format(self.x, self.y))
end

function Vector.__add(self, other)
	if type(other) == "number" then
		return Vector(self.x + other, self.y + other)
	end
	return Vector(self.x + other.x, self.y + other.y)
end

function Vector.__sub(self, other)
	if type(other) == "number" then
		return Vector(self.x - other, self.y - other)
	end
	return Vector(self.x - other.x, self.y - other.y)
end

function Vector.__mul(self, other)
	if type(other) == "number" then
		return Vector(self.x * other, self.y * other)
	end
	return Vector(self.x * other.x, self.y * other.y)
end

function Vector.__div(self, other)
	if type(other) == "number" then
		return Vector(self.x / other, self.y / other)
	end

	return Vector(self.x / other.x, self.y / other.y)
end


return Vector
