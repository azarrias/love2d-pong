--[[ push is a library that allow us to draw our game at a virtual resolution, instead of however large our
     window is; used to provide a more retro aesthetic
     https://github.com/Ulydev/push
]]
push = require 'libs.push'

--[[ class is a library that simplifies OOP with lua, which is very useful here
     https://github.com/vrld/hump/blob/master/class.lua
]]
Class = require 'libs.class'

-- the custom classes defined by using the class library must be imported as well
require 'Paddle'
require 'Ball'

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720 
VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243
FONT_SIZE_SMALL = 8
FONT_SIZE_MEDIUM = 16
FONT_SIZE_BIG = 32
BALL_SIZE = 4
PADDLE_WIDTH = 5
PADDLE_HEIGHT = 20
PADDLE_MARGIN_X = 10
PADDLE_MARGIN_Y = 30
PADDLE_SPEED = 200
SCORE_MARGIN = 30
FPS_INDICATOR_MARGIN = 10
NEW_COLOR_RANGE = love._version_major > 0 or love._version_major == 0 and love._version_minor >= 11

-- Wrapper functions to handle differences across love2d versions
local setColor = function(r, g, b, a)
  if not r or not g or not b or 
    not tonumber(r) or not tonumber(g) or not tonumber(b) 
    or a and not tonumber(a) then
    error("bad argument to 'setColor' (number expected)")
  end
  a = a or 255
  if NEW_COLOR_RANGE then
    love.graphics.setColor(r/255, g/255, b/255, a/255)
  else
    love.graphics.setColor(r, g, b, a)
  end
end

local clear = function(r, g, b, a, clearstencil, cleardepth)
  if not r or not g or not b or 
    not tonumber(r) or not tonumber(g) or not tonumber(b) 
    or a and not tonumber(a) then
    error("bad argument to 'clear' (number expected)")
  end
  a, clearstencil, cleardepth = a or 255, clearstencil or true, cleardepth or true
  if NEW_COLOR_RANGE then
    love.graphics.clear(r/255, g/255, b/255, a/255, clearstencil, cleardepth)
  else
    love.graphics.clear(r, g, b, a)
  end
end

-- Runs when the game first starts up, only once; used to initialize the game
function love.load()
  if arg[#arg] == "-debug" then require("mobdebug").start() end
  -- use nearest-neighbor (point) filtering on upscaling and downscaling to prevent blurring of text and 
  -- graphics instead of the bilinear filter that is applied by default 
  love.graphics.setDefaultFilter('nearest', 'nearest')
  
  love.window.setTitle('Pong')
  
  -- use current time as seed to the RNG for true random behaviour, since that will vary on startup every time
  math.randomseed(os.time())
  
  -- use retro looking font
  smallFont = love.graphics.newFont('assets/font.ttf', FONT_SIZE_SMALL)
  bigFont = love.graphics.newFont('assets/font.ttf', FONT_SIZE_BIG)
  mediumFont = love.graphics.newFont('assets/font.ttf', FONT_SIZE_MEDIUM)
  
  -- set up table with all sound effects
  -- type is static because they are short FXs to be kept in memory
  sounds = {
    ['paddle_hit'] = love.audio.newSource('assets/paddle_hit.wav', 'static'),
    ['score'] = love.audio.newSource('assets/score.wav', 'static'),
    ['wall_hit'] = love.audio.newSource('assets/wall_hit.wav', 'static')
  }
  
  -- initialize virtual resolution, which will be rendered within the actual window no matter its
  -- dimensions; wraps the love.window.setMode call
  push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
    fullscreen = false,
    resizable = true,
    vsync = true
  })

  -- initialize scores, paddle and ball positions
  player1 = Paddle(PADDLE_MARGIN_X, PADDLE_MARGIN_Y, PADDLE_WIDTH, PADDLE_HEIGHT)
  player2 = Paddle(VIRTUAL_WIDTH - PADDLE_MARGIN_X, VIRTUAL_HEIGHT - PADDLE_HEIGHT - PADDLE_MARGIN_Y, PADDLE_WIDTH, PADDLE_HEIGHT)
  ball = Ball(BALL_SIZE, BALL_SIZE)
  player1Score = 0
  player2Score = 0
  
  -- randomize first service
  servingPlayer = math.random(1, 2)
  
  -- initialize game FSM
  gameState = 'start'
end

-- Keyboard handling, called by LOVE2D for each frame
function love.keypressed(key)
  if key == 'escape' then
    love.event.quit()
  elseif key == 'enter' or key == 'return' then
    if gameState == 'start' then
      gameState = 'serve'
    elseif gameState == 'serve' then
      gameState = 'play'
    elseif gameState == 'done' then
      gameState = 'serve'
      ball:reset()
      player1Score = 0
      player2Score = 0
    end
  end
end

-- Called by LOVE2D whenever screed is resized
function love.resize(w, h)
  push:resize(w, h)
end

-- Runs every frame
function love.update(dt)
  -- player 1 movement (scaled by delta time)
  if love.keyboard.isDown('w') then
    player1.dy = -PADDLE_SPEED
  elseif love.keyboard.isDown('s') then
    player1.dy = PADDLE_SPEED
  else 
    player1.dy = 0
  end

  -- player 2 movement (scaled by delta time)
  if love.keyboard.isDown('up') then
    player2.dy = -PADDLE_SPEED
  elseif love.keyboard.isDown('down') then
    player2.dy = PADDLE_SPEED
  else
    player2.dy = 0
  end
  
  if gameState == 'serve' then
    -- initialize ball's velocity based on serving player
    ball.dy = math.random(-50, 50)
    if servingPlayer == 1 then
      ball.dx = math.random(140, 200)
    else
      ball.dx = -math.random(140, 200)
    end
  elseif gameState == 'play' then
    if ball:collides(player1) or ball:collides(player2) then
      ball.dx = -ball.dx * 1.03
      -- instantly shift ball to prevent it from becoming stuck in the collision
      shift_ball_x = ball.x < VIRTUAL_WIDTH / 2 and PADDLE_WIDTH or -PADDLE_WIDTH
      ball.x = ball.x + shift_ball_x
      
      if ball.dy < 0 then
        ball.dy = -math.random(10, 150)
      else
        ball.dy = math.random(10, 150)
      end
      
      sounds['paddle_hit']:play()
    end
    
    -- detect upper and lower screen boundary collision and bounce if collided
    if ball.y <= 0 then
      ball.y = 0
      ball.dy = -ball.dy
      sounds['wall_hit']:play()
    elseif ball.y >= VIRTUAL_HEIGHT - BALL_SIZE then
      ball.y = VIRTUAL_HEIGHT - BALL_SIZE
      ball.dy = -ball.dy
      sounds['wall_hit']:play()
    end
    
    -- check if a goal has been scored
    if ball.x + BALL_SIZE < 0 then
      servingPlayer = 1
      player2Score = player2Score + 1
      sounds['score']:play()
      -- check for game over (losing player will serve first in next game)
      if player2Score == 10 then
        winningPlayer = 2
        gameState = 'done'
      else
        ball:reset()
        gameState = 'serve'
      end
    elseif ball.x > VIRTUAL_WIDTH then
      servingPlayer = 2
      player1Score = player1Score + 1
      sounds['score']:play()
      if player1Score == 10 then
        winningPlayer = 1
        gameState = 'done'
      else
        ball:reset()
        gameState = 'serve'
      end
    end
     
  end
  
  if gameState == 'play' then
    ball:update(dt)
  end
  
  player1:update(dt)
  player2:update(dt)
end

-- Called after update by LOVE2D, used to draw anything to the screen, updated or otherwise
function love.draw()
  -- begin rendering at virtual resolution (push works as a state machine, like OpenGL)
  push:apply('start')
  
  -- clear screen with a RGBA color
  clear(40, 45, 52, 255)
  
  displayScore()
  displayFeedback()
  
  -- draw the players paddles and the ball
  player1:render()
  player2:render()
  ball:render()
  
--  displayFPS()
  
  -- end rendering at virtual resolution
  push:apply('end')
end

function displayFPS()
    -- simple FPS display across all states
    love.graphics.setFont(smallFont)
    setColor(0, 255, 0, 255)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), FPS_INDICATOR_MARGIN, FPS_INDICATOR_MARGIN)
end

function displayScore()
  love.graphics.setFont(bigFont)
  love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - FONT_SIZE_BIG / 2 - SCORE_MARGIN, VIRTUAL_HEIGHT / 3)
  love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH / 2 + SCORE_MARGIN, VIRTUAL_HEIGHT / 3)
end

function displayFeedback()
  love.graphics.setFont(smallFont)
  if gameState == 'start' then
    love.graphics.printf('Welcome to Pong!', 0, 10, VIRTUAL_WIDTH, 'center')
    love.graphics.printf('Press Enter to begin!', 0, 20, VIRTUAL_WIDTH, 'center')
  elseif gameState == 'serve' then
    love.graphics.printf('Player ' .. tostring(servingPlayer) .. "'s serve!",
      0, 10, VIRTUAL_WIDTH, 'center')
    love.graphics.printf('Press Enter to serve!', 0, 20, VIRTUAL_WIDTH, 'center')
  elseif gameState == 'done' then
    love.graphics.printf('Press Enter to restart!', 0, 30, VIRTUAL_WIDTH, 'center')
    love.graphics.setFont(mediumFont)
    love.graphics.printf('Player ' .. tostring(winningPlayer) .. ' wins!', 0, 10, VIRTUAL_WIDTH, 'center')
  end
end