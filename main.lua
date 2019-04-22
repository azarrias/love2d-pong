--[[ push is a library that allow us to draw our game at a virtual resolution, instead of however large our
     window is; used to provide a more retro aesthetic
     https://github.com/Ulydev/push
]]
push = require 'push'

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720 
VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243
FONT_SIZE_SMALL = 8
FONT_SIZE_BIG = 32
BALL_SIZE = 4
PADDLE_WIDTH = 5
PADDLE_HEIGHT = 20
PADDLE_MARGIN_X = 10
PADDLE_MARGIN_Y = 30
PADDLE_SPEED = 200
SCORE_MARGIN = 30

-- Runs when the game first starts up, only once; used to initialize the game
function love.load()
  -- use nearest-neighbor (point) filtering on upscaling and downscaling to prevent blurring of text and 
  -- graphics instead of the bilinear filter that is applied by default 
  love.graphics.setDefaultFilter('nearest', 'nearest')
  
  -- use current time as seed to the RNG for true random behaviour, since that will vary on startup every time
  math.randomseed(os.time())
  
  -- use retro looking font
  smallFont = love.graphics.newFont('assets/font.ttf', FONT_SIZE_SMALL)
  bigFont = love.graphics.newFont('assets/font.ttf', FONT_SIZE_BIG)
  
  -- initialize virtual resolution, which will be rendered within the actual window no matter its
  -- dimensions; wraps the love.window.setMode call
  push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
    fullscreen = false,
    resizable = false,
    vsync = true
  })

  -- initialize scores, paddle and ball positions
  player1Score = 0
  player2Score = 0
  player1Y = PADDLE_MARGIN_Y
  player2Y = VIRTUAL_HEIGHT - PADDLE_HEIGHT - PADDLE_MARGIN_Y
  initBall()
  
  -- initialize game FSM
  gameState = 'start'
end

-- Keyboard handling, called by LOVE2D for each frame
function love.keypressed(key)
  if key == 'escape' then
    love.event.quit()
  elseif key == 'enter' or key == 'return' then
    if gameState == 'start' then
      gameState = 'play'
    else
      gameState = 'start'
      initBall()
    end
  end
end

function initBall()
  ballX = VIRTUAL_WIDTH / 2 - BALL_SIZE / 2
  ballY = VIRTUAL_HEIGHT / 2 - BALL_SIZE / 2
  -- equivalent to ternary operator 
  -- math.random(2) == 1 ? 100 : -100
  ballDX = math.random(2) == 1 and 100 or -100
  ballDY = math.random(-50, 50) * 1.5
end

-- Runs every frame
function love.update(dt)
  -- player 1 movement (scaled by delta time)
  if love.keyboard.isDown('w') then
    player1Y = math.max(0, player1Y + -PADDLE_SPEED * dt)
  elseif love.keyboard.isDown('s') then
    player1Y = math.min(VIRTUAL_HEIGHT - PADDLE_HEIGHT, player1Y + PADDLE_SPEED * dt)
  end

  -- player 2 movement (scaled by delta time)
  if love.keyboard.isDown('up') then
    player2Y = math.max(0, player2Y + -PADDLE_SPEED * dt)
  elseif love.keyboard.isDown('down') then
    player2Y = math.min(VIRTUAL_HEIGHT - PADDLE_HEIGHT, player2Y + PADDLE_SPEED * dt)
  end
  
  if gameState == 'play' then
    ballX = ballX + ballDX * dt
    ballY = ballY + ballDY * dt
  end
end

-- Called after update by LOVE2D, used to draw anything to the screen, updated or otherwise
function love.draw()
  -- begin rendering at virtual resolution (push works as a state machine, like OpenGL)
  push:apply('start')
  
  -- clear screen with a RGBA color
  love.graphics.clear(40/255, 45/255, 52/255, 1)
  
  love.graphics.setFont(smallFont)
  love.graphics.printf('Hello Pong!',  0, 20, VIRTUAL_WIDTH, 'center')
  
  -- draw the scores, paddles and ball
  love.graphics.setFont(bigFont)
  love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - FONT_SIZE_BIG / 2 - SCORE_MARGIN, VIRTUAL_HEIGHT / 3)
  love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH / 2 + SCORE_MARGIN, VIRTUAL_HEIGHT / 3)
  love.graphics.rectangle('fill', PADDLE_MARGIN_X, player1Y, PADDLE_WIDTH, PADDLE_HEIGHT)
  love.graphics.rectangle('fill', VIRTUAL_WIDTH - PADDLE_MARGIN_X, player2Y, PADDLE_WIDTH, PADDLE_HEIGHT)
  love.graphics.rectangle('fill', ballX, ballY, BALL_SIZE, BALL_SIZE)
  
  -- end rendering at virtual resolution
  push:apply('end')
end