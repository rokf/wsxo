
-- tic tac toe client

local websocket = require 'http.websocket'
local fx = require 'termfx'

local ws = websocket.new_from_uri("ws://127.0.0.1:4000")
ws:connect(); print('connected')

local playnum = 0

local is_welcome, toe = ws:receive()
if is_welcome then
  playnum = string.match(is_welcome, "welcome (%d)")
else
  error(toe)
end

while true do
  local text = io.read("*line")
  if text == "q" then break end
  ws:send(text)
  print('received:',ws:receive())
end

ws:close()
