
-- tic tac toe server

local server = require 'http.server'
local websocket = require 'http.websocket'
local cqueues = require 'cqueues'
-- local serpent = require 'serpent'

local cq = cqueues.new()

cq:wrap(function ()
  local state = {
    pc = 0,
    fields = {
      0,0,0,
      0,0,0,
      0,0,0
    },
    sockets = {},
    restart = {false, false},
    turn = 1,
  }
  setmetatable(state.fields, {
    __tostring = function (f)
      return string.format("{%d:%d:%d:%d:%d:%d:%d:%d:%d}",f[1],f[2],f[3],f[4],f[5],f[6],f[7],f[8],f[9])
    end,
    __newindex = function (f, k, v)
      rawset(f,k,v)
    end,
    __index = function (f,k)
      return rawget(f,k)
    end
  })
  local s = server.listen({
    host = '127.0.0.1',
    port = 4000,
    onstream = function (sv,st)
      local function send_updates()
        for client_num,wsock in ipairs(state.sockets) do
          local msg = "update" .. tostring(state.fields)
          print('sending to', client_num, msg)
          wsock:send(msg)
        end
      end

      local ws = websocket.new_from_stream(st, st:get_headers())
      ws:accept(); print('accepted')
      state.pc = state.pc + 1
      local player = state.pc
      state.sockets[player] = ws
      ws:send('welcome ' .. player)

      send_updates() -- show board on both sides

      while true do
        local text, _ = ws:receive()
        if text == nil then break end
        local mput = {string.match(text,"put@(%d):(%d)")}
        local mres = {string.match(text,"restart:(%d)")}

        if mput[1] then
          -- update fields
          print('put log',mput[1],mput[2])
          if tonumber(mput[2]) == state.turn then
            state.fields[tonumber(mput[1])] = tonumber(mput[2])
            -- send back updated to both clients
            send_updates()
            -- switch player in turn
            if state.turn == 1 then state.turn = 2 else state.turn = 1 end
          end
        elseif mres[1] then
          state.restart[tonumber(mres[1])] = true
          if state.restart[1] and state.restart[2] then
            -- have to restart the game
            for i,_ in ipairs(state.fields) do state.fields[i] = 0 end
            state.restart = {false,false}
            state.turn = 1
            send_updates()
          end
        else
          print(text, 'not matching any pattern')
        end

      end
      ws:close()
    end
  })
  -- s:listen()
  s:loop()
end)

cq:loop()
