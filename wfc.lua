math.randomseed(os.time())

WFC = {}
WFC.__index = WFC

function WFC:create(data, N, shouldStep, ow, oh)
  local wfc = {}
  setmetatable(wfc, WFC)
  wfc.finished = false
  wfc.tiles = {}
  function WFC:giveTiles()
    return tiles
  end
  wfc.adjacencyIndex = {}
  wfc.colors = {}
  wfc.colorLists = {}
  wfc.wave = {}
  wfc.toPropagate = {}
  wfc.s, wfc.m = nil, nil
  wfc.imgData = data
  wfc.inW = data:getWidth()
  wfc.inH = data:getHeight()
  wfc.outW = ow
  wfc.outH = oh
  wfc.N = N
  wfc.wave.w = (wfc.outW-1)/(wfc.N-1)
  wfc.wave.h = (wfc.outH-1)/(wfc.N-1)
  wfc.shouldStep = step
  wfc.contradiction = false
  return wfc
end

function WFC:build()
  WFC:getTiles()
  WFC:buildPropagator()
  WFC:buildWave()
  debug:write("\n")
  if wfc.shouldStep == false then
    while not wfc.finished do
      wfc.observe()
      wfc.propagate()
    end
    return outputWave()
  end
end

function WFC:step()
  output = WFC:outputWave()
  wfc.observe()
  wfc.propagate()
  debug:write("\n")
  if wfc.contradiction then
    return "oops"
  else return output end
end

function WFC:buildWave()
  debug:write("building the wave\n")
  print("building wave")
  wfc.tileWave = {}
  for i = 1, #wfc.tiles do
    wfc.tileWave[i] = true
    print("setting tile " .. i .. "/" .. #wfc.tiles .. " to true")
  end

  for i = 1, wfc.wave.w do
    wfc.wave[i] = {}
    for j = 1, wfc.wave.h do
      wfc.wave[i][j] = wfc.tileWave
      print("setting space (" .. i .. ", " .. j .. ")")
    end
  end
  print("done")
end

function WFC:observe()
  debug:write("observing --------------------------------\n")
  debug:write(waveToEntropy())
  print("observing")
  if wfc.checkIfFinished() then
    wfc.finished = true
    debug:write("wooo! done!")
    return
  end
  i, j = wfc.findLowestEntropy()
  debug:write("- lowest entropy is at (" .. i .. ", " .. j .. ")\n")
  chosen = nil
  while chosen == nil do
    for w = 1, #wfc.wave[i][j] do
      if chosen == nil then
        prob = math.random()
        if prob < wfc.tiles[w].frequency/#wfc.tiles then
          chosen = w
          debug:write("-- chosen is " .. w .. "\n")
        end
      end
    end
  end
  debug:write(waveToText())
  local tempSpace = {}
  for w = 1, #wfc.tiles do
    if w ~= chosen then
      tempSpace[w] = false
      debug:write("-- set " .. w .. " to false\n")
    else
      tempSpace[w] = true
    end
  end
  wfc.wave[i][j] = tempSpace
  debug:write(waveToText())
  table.insert(wfc.toPropagate, {i, j})
end

function WFC:propagate()
  debug:write("propagating --------------------------------\n")
  print("propagating")
  debug:write("- tP: (" .. #wfc.toPropagate .. ")\n")
  local futurePropagate = {}

  i = 1
  while i <= #wfc.toPropagate do    -- go through all spaces in the toPropagate list
    x = wfc.toPropagate[i][1]
    y = wfc.toPropagate[i][2]   -- current coors of a toPropagate space
    debug:write("- propagating space #" .. i .. " at (" .. x .. ", " .. y .. ")\n")

    for j = 1, #wfc.wave[x][y] do   -- go through all tiles at space (x, y)
      debug:write("-- tile " .. j .. " is " .. (wfc.wave[x][y][j] and 'true' or 'false') .. "\n")
      if wfc.wave[x][y][j] then   -- if that space is allowed
        debug:write("-- possible tile is " .. j .. "\n")
        local adjacency = wfc.adjacencyIndex[j]   -- adjacency data of current tile

        for w = 1, #adjacency.top do
          if adjacency.top[w] == false and y - 1 >= 1 then
            wfc.wave[x][y-1][w] = false
            ny = y-1
            top = {x, ny}
            table.insert(futurePropagate, top)
          else debug:write("--- ↑ kept " .. w .. "\n") end
        end

        for w = 1, #adjacency.right do
          if adjacency.right[w] == false and x + 1 <= #wfc.wave then
            wfc.wave[x+1][y][w] = false
            nx = x+1
            right = {nx, y}
            table.insert(futurePropagate, right)
          else debug:write("--- → kept " .. w .. "\n") end
        end

        for w = 1, #adjacency.bottom do
          if adjacency.bottom[w] == false and y + 1 <= #wfc.wave[x] then
            wfc.wave[x][y+1][w] = false
            ny = y+1
            bottom = {x, ny}
            table.insert(futurePropagate, bottom)
          else debug:write("--- ↓ kept " .. w .. "\n") end
        end

        for w = 1, #adjacency.left do
          if adjacency.left[w] == false and x - 1 >= 1 then
            wfc.wave[x-1][y][w] = false
            nx = x-1
            left = {nx, y}
            table.insert(futurePropagate, left)
          else debug:write("--- ← kept " .. w .. "\n") end
        end

      end
    end

    if i == #wfc.toPropagate then   -- add the fP to the (cleared) tP and clear fP
      for j = #wfc.toPropagate, 1, -1 do
        table.remove(wfc.toPropagate)
      end

      for a = 1, #futurePropagate do
        for b = #futurePropagate, a+1, -1 do
          if tableIsTable(futurePropagate[b], futurePropagate[a]) then
            table.remove(futurePropagate, b)
          end
        end
      end

      debug:write("- adding fP (" .. #futurePropagate .. ") to tP (" .. #wfc.toPropagate .. ")\n")

      for j = #futurePropagate, 1, -1 do
        tempLoc = table.remove(futurePropagate)
        debug:write("-- tempLoc: (" .. tempLoc[1] .. ", " .. tempLoc[2] .. ")\n")
        table.insert(wfc.toPropagate, tempLoc)
      end
      debug:write("- fP: (" .. #futurePropagate .. "), tP: (" .. #wfc.toPropagate .. ")\n")

      i = 1
    else i = i+1 end

  end
end

function waveToText()
  local str = ""
  for i = 1, #wfc.wave do
    for j = 1, #wfc.wave[i] do
      str = str .. "["
      for w = 1, #wfc.wave[i][j] do
        str = str .. (wfc.wave[i][j][w] and 't' or '.')
      end
      str = str .. "]"
    end
    str = str .. "\n"
  end
  return str
end

function waveToEntropy()
  local str = ""
  for i = 1, #wfc.wave do
    for j = 1, #wfc.wave[i] do
      str = str .. "[" .. getEntropy(i, j) .. "]"
    end
    str = str .. "\n"
  end
  return str
end

function WFC:outputWave()
  debug:write("outputting --------------------------------\n")
  print("outputting")
  outImgData = love.image.newImageData(wfc.outW, wfc.outH)    -- create output image
  for i = 1, #wfc.wave do
    for j = 1, #wfc.wave[i] do    -- go through the wave

      local tilesToDraw = {}    -- make a table of the tiles you need to draw in a space
      for w = 1, #wfc.wave[i][j] do
        if wfc.wave[i][j][w] then
          table.insert(tilesToDraw, wfc.tiles[w])   -- add a tile to the list you need to draw in a space
        end
      end

      for cx = 0, wfc.N-1 do
        for cy = 0, wfc.N-1 do    -- iterate over the pixels for a space
          tr, tg, tb, ta = 0, 0, 0, 0   -- initialize the average rgba variables
          for t = 1, #tilesToDraw do    -- go over all the tiles in a space that need to be drawn
            r, g, b, a = tilesToDraw[t].imgData:getPixel(cx, cy)
            tr = tr + r
            tg = tg + g
            tb = tb + b
            ta = ta + a   -- add up the rgba values
          end
          tr = tr / #tilesToDraw
          tg = tg / #tilesToDraw
          tb = tb / #tilesToDraw
          ta = ta / #tilesToDraw    -- find the averages
          outImgData:setPixel(i + cx - 1, j + cy - 1, tr, tg, tb, ta)   -- set the pixel in the output to the average of the tiles' pixels for that space
        end
      end
    end
  end
  return outImgData   -- return the output image
end

function WFC:checkIfFinished()
  isItFinished = true
  for i = 1, #wfc.wave do
    for j = 1, #wfc.wave[i] do
      numLeft = 0
      for w = 1, #wfc.wave[i][j] do
        if wfc.wave[i][j][w] then
          numLeft = numLeft + 1
        end
      end
      if numLeft ~= 1 then isItFinished = false end
    end
  end
  return isItFinished
end

function WFC:findLowestEntropy()
  lowest = {}
  lowest.entropy = 10000000
  lowest.coors = {-1, -1}
  for i = 1, #wfc.wave do
    for j = 1, #wfc.wave[i] do
      currentEntropy = getEntropy(i, j) + math.random()
      if currentEntropy < lowest.entropy then
        lowest.entropy = currentEntropy
        lowest.coors = {i, j}
      end
    end
  end

  return lowest.coors[1], lowest.coors[2]
end

function getEntropy(i, j)
  local entropy = 0
  local tileSup = wfc.wave[i][j]

  numTrue = 0
  for i = 1, #tileSup do
    if tileSup[i] then numTrue = numTrue + 1 end
  end

  if numTrue == 1 then
    entropy = 0
  elseif numTrue == 0 then
    entropy = 9999999999
    wfc.contradiction = true
  else
    for w = 1, #wfc.tiles do
      entropy = entropy + wfc.tiles[w].frequency
    end
  end
  return entropy
end

function WFC:getTiles()
  debug:write("generating tiles --------------------------------\n")
  print("generating tiles")
  for x = 0, wfc.inW - wfc.N do   -- make the tiles from the input and create color ids
    for y = 0, wfc.inH - wfc.N do
      local tile = {}
      tile.imgData = love.image.newImageData(wfc.N, wfc.N)
      tile.id = 1
      for tx = 0, wfc.N - 1 do
        for ty = 0, wfc.N - 1 do
          r, g, b, a = wfc.imgData:getPixel(tx + x, ty + y)
          tile.imgData:setPixel(tx, ty, r, g, b, a)
        end
      end

      tile.color = {}

      tile.color.top = 0
      local topColors = {}
      for tx = 0, wfc.N-1 do
        r, g, b, a = tile.imgData:getPixel(tx, 0)
        local topColor = 0
        if #wfc.colors == 0 then    -- if there are no other stored colors
          table.insert(wfc.colors, {r, g, b, a})
          topColor = 1
        else
          local isUnique = true
          for i = 1, #wfc.colors do   -- check if the current color is unique
            if tableIsTable({r, g, b, a}, wfc.colors[i]) then   -- if not, it's a color in the list
              topColor = i
              isUnique = false
            end
          end
          if isUnique then    -- if it is, add it to the list and set color to last list index
            table.insert(wfc.colors, {r, g, b, a})
            topColor = #wfc.colors
          end
        end
        table.insert(topColors, topColor)   -- add the color index to list
      end
      if #wfc.colorLists == 0 then
        table.insert(wfc.colorLists, topColors)
        tile.color.top = 1
      else
        local isUnique = true
        for i = 1, #wfc.colorLists do
          if tableIsTable(topColors, wfc.colorLists[i]) then
            tile.color.top = i
            isUnique = false
          end
        end
        if isUnique then
          table.insert(wfc.colorLists, topColors)
          tile.color.top = #wfc.colorLists
        end
      end

      tile.color.bottom = 0
      local bottomColors = {}
      for tx = 0, wfc.N-1 do
        r, g, b, a = tile.imgData:getPixel(tx, wfc.N-1)
        local bottomColor = 0
        if #wfc.colors == 0 then
          table.insert(wfc.colors, {r, g, b, a})
          bottomColor = 1
        else
          local isUnique = true
          for i = 1, #wfc.colors do
            if tableIsTable({r, g, b, a}, wfc.colors[i]) then
              bottomColor = i
              isUnique = false
            end
          end
          if isUnique then
            table.insert(wfc.colors, {r, g, b, a})
            bottomColor = #wfc.colors
          end
        end
        table.insert(bottomColors, bottomColor)
      end
      if #wfc.colorLists == 0 then
        table.insert(wfc.colorLists, bottomColors)
        tile.color.bottom = 1
      else
        local isUnique = true
        for i = 1, #wfc.colorLists do
          if tableIsTable(bottomColors, wfc.colorLists[i]) then
            tile.color.bottom = i
            isUnique = false
          end
        end
        if isUnique then
          table.insert(wfc.colorLists, bottomColors)
          tile.color.bottom = #wfc.colorLists
        end
      end

      tile.color.left = 0
      local leftColors = {}
      for ty = 0, wfc.N-1 do
        r, g, b, a = tile.imgData:getPixel(0, ty)
        local leftColor = 0
        if #wfc.colors == 0 then
          table.insert(wfc.colors, {r, g, b, a})
          leftColor = 1
        else
          local isUnique = true
          for i = 1, #wfc.colors do
            if tableIsTable({r, g, b, a}, wfc.colors[i]) then
              leftColor = i
              isUnique = false
            end
          end
          if isUnique then
            table.insert(wfc.colors, {r, g, b, a})
            leftColor = #wfc.colors
          end
        end
        table.insert(leftColors, leftColor)
      end
      if #wfc.colorLists == 0 then
        table.insert(wfc.colorLists, leftColors)
        tile.color.left = 1
      else
        local isUnique = true
        for i = 1, #wfc.colorLists do
          if tableIsTable(leftColors, wfc.colorLists[i]) then
            tile.color.left = i
            isUnique = false
          end
        end
        if isUnique then
          table.insert(wfc.colorLists, leftColors)
          tile.color.left = #wfc.colorLists
        end
      end

      tile.color.right = 0
      local rightColors = {}
      for ty = 0, wfc.N-1 do
        r, g, b, a = tile.imgData:getPixel(wfc.N-1, ty)
        local rightColor = 0
        if #wfc.colors == 0 then
          table.insert(wfc.colors, {r, g, b, a})
          rightColor = 1
        else
          local isUnique = true
          for i = 1, #wfc.colors do
            if tableIsTable({r, g, b, a}, wfc.colors[i]) then
              rightColor = i
              isUnique = false
            end
          end
          if isUnique then
            table.insert(wfc.colors, {r, g, b, a})
            rightColor = #wfc.colors
          end
        end
        table.insert(rightColors, rightColor)
      end
      if #wfc.colorLists == 0 then
        table.insert(wfc.colorLists, rightColors)
        tile.color.right = 1
      else
        local isUnique = true
        for i = 1, #wfc.colorLists do
          if tableIsTable(rightColors, wfc.colorLists[i]) then
            tile.color.right = i
            isUnique = false
          end
        end
        if isUnique then
          table.insert(wfc.colorLists, rightColors)
          tile.color.right = #wfc.colorLists
        end
      end

      tile.id = tonumber(tile.color.top .. tile.color.bottom .. tile.color.left .. tile.color.right)

      tile.frequency = 1
      table.insert(wfc.tiles, tile)
    end
  end

  for i = 1, #wfc.tiles do   -- make tiles unique, updating frequency
    local currentId = wfc.tiles[i].id
    for j = #wfc.tiles, i do
      local checkId = wfc.tiles[j].id
      if currentId == checkId then
        table.remove(wfc.tiles[j])
        wfc.tiles[i].frequency = wfc.tiles[i].frequency + 1
      end
    end
  end
  for i = 1, #wfc.tiles do
    local fileData = wfc.tiles[i].imgData:encode("png", "tile" .. i .. ".png")
  end

  debug:write("- colors:\n")
  for i = 1, #wfc.colors do
    r = round(wfc.colors[i][1], 2)
    g = round(wfc.colors[i][2], 2)
    b = round(wfc.colors[i][3], 2)
    debug:write("-- color #" .. i ..": (" .. r .. ", " .. g .. ", " .. b .. ")\n")
  end

  debug:write("- color lists:\n")
  for i = 1, #wfc.colorLists do
    local str = "-- list #" .. i .. ": "
    for j = 1, #wfc.colorLists[i] do
      str = str .. wfc.colorLists[i][j] .. " "
    end
    str = str .. "\n"
    debug:write(str)
  end
end

function WFC:buildPropagator()
  debug:write("building the propagator --------------------------------\n")
  print("building propagator")
  for i = 1, #wfc.tiles do    -- go through all tiles
    debug:write("- tile " .. i .." (id: " .. wfc.tiles[i].id .. ")\n")
    local currentTile = wfc.tiles[i]    -- get current tile
    local tileAdjacency = {}    -- make a new adjacency table
    tileAdjacency.top = {}    -- list of possible tiles above
    for j = 1, #wfc.tiles do    -- check other tiles
      local checkTile = wfc.tiles[j]
      -- debug:write("-- " .. checkTile.color.bottom .." == " .. currentTile.color.top .. "\n")
      if checkTile.color.bottom == currentTile.color.top then
        tileAdjacency.top[j] = true
        debug:write("--- ↑ tile #" .. j .." (id: " .. wfc.tiles[j].id .. ")\n")
      else tileAdjacency.top[j] = false end
    end
    tileAdjacency.bottom = {}
    for j = 1, #wfc.tiles do
      local checkTile = wfc.tiles[j]
      -- debug:write("-- " .. checkTile.color.top .." == " .. currentTile.color.bottom .. "\n")
      if checkTile.color.top == currentTile.color.bottom then
        tileAdjacency.bottom[j] = true
        debug:write("--- ↓ tile #" .. j .." (id: " .. wfc.tiles[j].id .. ")\n")
      else tileAdjacency.bottom[j] = false end
    end
    tileAdjacency.left = {}
    for j = 1, #wfc.tiles do
      local checkTile = wfc.tiles[j]
      -- debug:write("-- " .. checkTile.color.right .." == " .. currentTile.color.left .. "\n")
      if checkTile.color.right == currentTile.color.left then
        tileAdjacency.left[j] = true
        debug:write("--- ← tile #" .. j .." (id: " .. wfc.tiles[j].id .. ")\n")
      else tileAdjacency.left[j] = false end
    end
    tileAdjacency.right = {}
    for j = 1, #wfc.tiles do
      local checkTile = wfc.tiles[j]
      -- debug:write("-- " .. checkTile.color.left .." == " .. currentTile.color.right .. "\n")
      if checkTile.color.left == currentTile.color.right then
        tileAdjacency.right[j] = true
        debug:write("--- → tile #" .. j .." (id: " .. wfc.tiles[j].id .. ")\n")
      else tileAdjacency.right[j] = false end
    end
    table.insert(wfc.adjacencyIndex, tileAdjacency)
  end
end

function tableIsTable(a, b)
  same = true
  if #a ~= #b then
    return false
  else
    for i = 1, #a do
      if a[i] ~= b[i] then same = false end
    end
  end
  return same
end

function valueIsInTable(value, table)
  for i = 1, #wfc.table do
    if wfc.table[i] == value then return true end
  end
  return false
end

function round(num, numDecimalPlaces)
  rounded = tonumber(string.format("%#." .. (numDecimalPlaces or 0) .. "f", num))
  if rounded == 1 then
    rounded = "1.00"
  elseif rounded == 0 then
    rounded = "0.00"
  end
  return rounded
end
