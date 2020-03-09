require "wfc"
local g = love.graphics
debug = io.open("debug.txt", "w+")

function love.load()
  Width = g.getWidth()
  Height = g.getHeight()

  imgData = love.image.newImageData(Width/2, Height/2)

  inputImgData = love.image.newImageData("input_simple.png")
  imgDataIsNil = "false"
  if imgData == nil then
    imgDataIsNil = "true"
  end

  wfc = WFC:create(inputImgData, 2, true, 7, 7)
  wfc:build()
end

function love.update(dt)
  if love.keyboard.isDown("space") and not wfc.isFinished then
    imgData = wfc:step()
    while imgData == "oops" do
      debug:write("oops")
      wfc = WFC:create(inputImgData, 3, true, 7, 7)
      wfc:build()
      imgData = wfc:step()
    end
  end
  -- if not wfc.isFinished() then
  --   outImageData = wfc.step()
  -- end
end

function love.draw()
  img = g.newImage(imgData)
  g.draw(img, 0, 0, 0, 5, 5)
end

function love.keypressed(key)
  if key == "escape" then
    love.event.quit(0)
  end
end
