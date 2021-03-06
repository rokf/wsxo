
-- tic tac toe server

local server = require 'http.server'
local websocket = require 'http.websocket'
local cqueues = require 'cqueues'
-- local serpent = require 'serpent'

local function checkwin(f)
  local g = {
    {1,2,3},
    {4,5,6},
    {7,8,9},
    {1,4,7},
    {2,5,8},
    {3,6,9},
    {1,5,9},
    {7,5,3}
  }
  for _,v in ipairs(g) do
    if f[v[1]] == f[v[2]] and f[v[1]] == f[v[3]] and f[v[1]] ~= 0 then
      return f[v[1]]
    end
  end
  return 0
end

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
    points = {0,0}
  }
  local player = 0
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
    onstream = function (_,st)
      local function send_turn()
        for _,wsock in ipairs(state.sockets) do
          local msg = "now:" .. state.turn
          wsock:send(msg)
        end
      end
      local function send_updates()
        for client_num,wsock in ipairs(state.sockets) do
          local msg = "update" .. tostring(state.fields)
          print('sending to', client_num, msg)
          wsock:send(msg)
        end
      end
      local function send_close()
        for _,wsock in ipairs(state.sockets) do
          wsock:send('close:' .. player)
        end
      end
      local function send_points()
        for _,wsock in ipairs(state.sockets) do
          wsock:send('points:' .. state.points[1] .. ':' .. state.points[2])
        end
      end
      local function reset_game()
        for i,_ in ipairs(state.fields) do state.fields[i] = 0 end
        state.restart = {false,false}
        state.turn = 1
        send_updates()
        send_turn()
      end
      local ws = websocket.new_from_stream(st, st:get_headers())
      ws:accept(); print('accepted')
      state.pc = state.pc + 1
      player = state.pc
      state.sockets[player] = ws
      ws:send('welcome ' .. player)

      send_updates() -- show board on both sides
      send_turn()

      while true do
        local text, _ = ws:receive()
        if text == nil then break end
        local mput = {string.match(text, "put@(%d):(%d)")}
        local mres = {string.match(text, "restart:(%d)")}
        local mqt = {string.match(text, "quit:(%d)")}

        if mput[1] then
          -- update fields
          print('put log',mput[1],mput[2])
          if tonumber(mput[2]) == state.turn and state.fields[tonumber(mput[1])] == 0 then
            state.fields[tonumber(mput[1])] = tonumber(mput[2])
            -- send back updated to both clients
            send_updates()
            local winner = checkwin(state.fields)
            if winner ~= 0 then
              state.points[winner] = state.points[winner] + 1
              send_points()
              reset_game()
            else
              -- switch player in turn
              if state.turn == 1 then state.turn = 2 else state.turn = 1 end
              send_turn()
            end
          end
        elseif mres[1] then
          state.restart[tonumber(mres[1])] = true
          if state.restart[1] and state.restart[2] then
            -- have to restart the game
            reset_game()
          end
        elseif mqt[1] then
          -- state.socket[tonumber(mqt[1])] = nil
          -- state.pc = state.pc - 1
          send_close()
          break
        else
          print(text, 'not matching any pattern')
        end
      end
      state.sockets[player] = nil
      state.pc = state.pc - 1
      ws:close()
    end
  })
  -- s:listen()
  s:loop()
end)

cq:loop()
