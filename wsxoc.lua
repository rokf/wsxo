
-- tic tac toe client

local websocket = require 'http.websocket'
local tfx = require 'termfx'
local cqueues = require 'cqueues'
local serpent = require 'serpent'

local ws = websocket.new_from_uri("ws://127.0.0.1:4000")
print('connecting:',ws:connect())

local playnum = 0
local pturn = 0

local is_welcome, toe = ws:receive()
if is_welcome then
  playnum = string.match(is_welcome, "welcome (%d)")
else
  error(toe)
end

tfx.init()
tfx.clear(tfx.color.WHITE, tfx.color.BLACK)

local quit = false

local cq = cqueues.new()

local recv, toe

local queue = {}

cq:wrap(function ()
  repeat
    recv, toe = ws:receive()
    table.insert(queue,recv)
  until quit
end)

local wholeft = playnum

local points = {0,0}

repeat
  local evt = tfx.pollevent(100)
  cq:step(0)
  if queue[1] then
    local mupd = {string.match(queue[1], 'update{(%d):(%d):(%d):(%d):(%d):(%d):(%d):(%d):(%d)}')}
    local mtrn = {string.match(queue[1], 'now:(%d)')}
    local mcls = {string.match(queue[1], 'close:(%d)')}
    local mpts = {string.match(queue[1], 'points:(%d+):(%d+)')}
    table.remove(queue,1)
    if mupd[1] then
      tfx.setcell(1,1,mupd[1])
      tfx.setcell(2,1,mupd[2])
      tfx.setcell(3,1,mupd[3])
      tfx.setcell(1,2,mupd[4])
      tfx.setcell(2,2,mupd[5])
      tfx.setcell(3,2,mupd[6])
      tfx.setcell(1,3,mupd[7])
      tfx.setcell(2,3,mupd[8])
      tfx.setcell(3,3,mupd[9])
    elseif mtrn[1] then
      pturn = tonumber(mtrn[1])
    elseif mcls[1] then
      wholeft = mcls[1]
      quit = true
    elseif mpts[1] then
      points[1] = tonumber(mpts[1])
      points[2] = tonumber(mpts[2])
    end
  else
    tfx.printat(1,11,toe) -- received nil
  end
  if evt then
    if evt.type == 'key' then
      if evt.char and string.match(evt.char, "[1-9]") then
        ws:send('put@' .. evt.char .. ':' .. playnum)
      elseif evt.char == 'r' then
        ws:send('restart:' .. playnum)
      end
      quit = evt.key == tfx.key.ESC
    end
  end
  tfx.printat(tfx.width() - 10, 2, "player " .. playnum)
  tfx.printat(tfx.width() - 10, 4, "now " .. pturn)
  tfx.printat(tfx.width() - 10, 6, "+ " .. points[1] .. ' ' .. points[2])
  tfx.present()
until quit

ws:send('quit:' .. playnum)
ws:close()
tfx.shutdown()

print('player ' .. wholeft .. ' has left')
