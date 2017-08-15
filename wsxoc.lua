
-- tic tac toe client

local websocket = require 'http.websocket'
local tfx = require 'termfx'
local cqueues = require 'cqueues'
local serpent = require 'serpent'

local ws = websocket.new_from_uri("ws://127.0.0.1:4000")
print('connecting:',ws:connect())

local playnum = 0

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

cq:wrap(function ()
  repeat
    recv, toe = ws:receive()
  until quit
end)

repeat
  local evt = tfx.pollevent(100)
  cq:step(0)
  if recv then
    local mupd = {string.match(recv, 'update{(%d):(%d):(%d):(%d):(%d):(%d):(%d):(%d):(%d)}')}
    tfx.setcell(1,1,mupd[1])
    tfx.setcell(2,1,mupd[2])
    tfx.setcell(3,1,mupd[3])
    tfx.setcell(1,2,mupd[4])
    tfx.setcell(2,2,mupd[5])
    tfx.setcell(3,2,mupd[6])
    tfx.setcell(1,3,mupd[7])
    tfx.setcell(2,3,mupd[8])
    tfx.setcell(3,3,mupd[9])
  else
    tfx.printat(1,11,toe)
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
  tfx.present()
until quit

ws:send('quit ' .. playnum)
ws:close()
tfx.shutdown()
