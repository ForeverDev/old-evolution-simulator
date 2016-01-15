local Color = class "Color"

function Color:init(r, g, b, a)
	self.r = r
	self.g = g
	self.b = b
	self.a = a or 255
end

function Color:components()
	return self.r, self.g, self.b, self.a
end

return Color
