Ball = Class{}

function Ball:init(width, height)
  self.width = width
  self.height = height
  
  self:reset()
end

function Ball:reset()
  self.x = VIRTUAL_WIDTH / 2 - self.width / 2
  self.y = VIRTUAL_HEIGHT / 2 - self.height / 2
  -- equivalent to ternary operator 
  -- math.random(2) == 1 ? 100 : -100
  self.dx = math.random(2) == 1 and 100 or -100
  self.dy = math.random(-50, 50) * 1.5
end

function Ball:collides(paddle)
  -- left side of either is farther to the right than the right side of the other
  if self.x > paddle.x + paddle.width or paddle.x > self.x + self.width then
    return false
  end
  
  -- bottom side of either is higher than the top side of the other
  if self.y > paddle.y + paddle.height or paddle.y > self.y + self.height then
    return false
  end
  
  -- otherwise, they are overlapping
  return true
end  

function Ball:update(dt)
  self.x = self.x + self.dx * dt
  self.y = self.y + self.dy * dt
end

function Ball:render()
  love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
end