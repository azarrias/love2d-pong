--[[ push is a library that allow us to draw our game at a virtual resolution, instead of however large our
     window is; used to provide a more retro aesthetic
     https://github.com/Ulydev/push
]]
push = require 'push'

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720 
VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243
FONT_SIZE = 8
BALL_SIZE = 4
PADDLE_WIDTH = 5
PADDLE_HEIGHT = 20
PADDLE_MARGIN_X = 10
PADDLE_MARGIN_Y = 30

-- Runs when the game first starts up, only once; used to initialize the game
function love.load()
  -- use nearest-neighbor (point) filtering on upscaling and downscaling to prevent blurring of text and 
  -- graphics instead of the bilinear filter that is applied by default 
  love.graphics.setDefaultFilter('nearest', 'nearest')
  
  -- use retro looking font
  smallFont = love.graphics.newFont('assets/font.ttf', FONT_SIZE)
  love.graphics.setFont(smallFont)
  
  -- initialize virtual resolution, which will be rendered within the actual window no matter its
  -- dimensions; wraps the love.window.setMode call
  push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
    fullscreen = false,
    resizable = false,
    vsync = true
  })
end

-- Keyboard handling, called by LOVE2D for each frame
function love.keypressed(key)
  if key == 'escape' then
    love.event.quit()
  end
end

-- Called after update by LOVE2D, used to draw anything to the screen, updated or otherwise
function love.draw()
  -- begin rendering at virtual resolution (push works as a state machine, like OpenGL)
  push:apply('start')
  
  -- clear screen with a RGBA color
  love.graphics.clear(40/255, 45/255, 52/255, 1)
  
  love.graphics.printf('Hello Pong!',  0, 20, VIRTUAL_WIDTH, 'center')
  
  -- the paddles and the ball will be represented by simple rectangles
  love.graphics.rectangle('fill', PADDLE_MARGIN_X, PADDLE_MARGIN_Y, PADDLE_WIDTH, PADDLE_HEIGHT)
  love.graphics.rectangle('fill', VIRTUAL_WIDTH - PADDLE_MARGIN_X, VIRTUAL_HEIGHT - PADDLE_HEIGHT - PADDLE_MARGIN_Y, PADDLE_WIDTH, PADDLE_HEIGHT)
  love.graphics.rectangle('fill', VIRTUAL_WIDTH / 2 - BALL_SIZE / 2, VIRTUAL_HEIGHT / 2 - BALL_SIZE / 2, BALL_SIZE, BALL_SIZE)
  
  -- end rendering at virtual resolution
  push:apply('end')
end