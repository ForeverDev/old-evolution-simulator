function love.load()

	math.randomseed(os.time())

	DRAW = love.graphics
	WINDOW = love.window
	TIMER = love.timer

	BIGFONT = DRAW.getFont()
	SMALLFONT = DRAW.newFont(9)
	
	WINDOW.setFullscreen(true)

	SCREEN_WIDTH = DRAW.getWidth()
	SCREEN_HEIGHT = DRAW.getHeight()
	SCREEN_PIXELS = SCREEN_WIDTH * SCREEN_HEIGHT

	DRAW.setBackgroundColor(255, 255, 255)

	do
		local oldSet, oldGet = DRAW.setColor, DRAW.getColor
		DRAW.setColor = function(color)
			oldSet(color:components())
		end
		DRAW.getColor = function()
			return Color(oldGet())
		end
	end

	class = require "class"
	Color = require "color"
	Vector = require "vector"
	NeuralNetwork = require "neural_network"
	Animal = require "animal"
	Simulator = require "simulator"

	simulator = Simulator()
	
end

function love.update(dt)
	simulator:update(dt)
end

function love.draw()
	simulator:draw()
end

function love.mousepressed(x, y, b)
	simulator:mousepressed(x, y, b)
end

function love.keypressed(key)
	if key == "escape" then
		love.event.quit()
	end
	simulator:keypressed(key)
end
