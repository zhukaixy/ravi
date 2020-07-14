-- $Id: testes/gengc.lua $
-- See Copyright Notice in file all.lua

print('testing generational garbage collection')

local debug = require"debug"

assert(collectgarbage("isrunning"))

collectgarbage()

local oldmode = collectgarbage("generational")


-- ensure that table barrier evolves correctly
do
  local U = {}
  -- full collection makes 'U' old
  collectgarbage()
  assert(not T or T.gcage(U) == "old")

  -- U refers to a new table, so it becomes 'touched1'
  U[1] = {x = {234}}
  assert(not T or (T.gcage(U) == "touched1" and T.gcage(U[1]) == "new"))

  -- both U and the table survive one more collection
  collectgarbage("step", 0)
  assert(not T or (T.gcage(U) == "touched2" and T.gcage(U[1]) == "survival"))

  -- both U and the table survive yet another collection
  -- now everything is old
  collectgarbage("step", 0)
  assert(not T or (T.gcage(U) == "old" and T.gcage(U[1]) == "old1"))

  -- data was not corrupted
  assert(U[1].x[1] == 234)
end


do   -- bug in 5.4.0
-- When an object aged OLD1 is finalized, it is moved from the list
-- 'finobj' to the *beginning* of the list 'allgc', but that part of the
-- list was not being visited by 'markold'.
  local A = {}
  A[1] = false     -- old anchor for object

  -- obj finalizer
  local function gcf (obj)
    A[1] = obj     -- anchor object
    assert(not T or T.gcage(obj) == "old1")
    obj = nil      -- remove it from the stack
    collectgarbage("step", 0)   -- do a young collection
    print(getmetatable(A[1]).x)   -- metatable was collected
  end

  collectgarbage()   -- make A old
  local obj = {}     -- create a new object
  collectgarbage("step", 0)   -- make it a survival
  assert(not T or T.gcage(obj) == "survival")
  setmetatable(obj, {__gc = gcf, x = "ok"})   -- create its metatable
  assert(not T or T.gcage(getmetatable(obj)) == "new")
  obj = nil   -- clear object
  collectgarbage("step", 0)   -- will call obj's finalizer
end


if T == nil then
  (Message or print)('\n >>> testC not active: \z
                             skipping some generational tests <<<\n')
  print 'OK'
  return
end


-- ensure that userdata barrier evolves correctly
do
  local U = T.newuserdata(0, 1)
  -- full collection makes 'U' old
  collectgarbage()
  assert(T.gcage(U) == "old")

  -- U refers to a new table, so it becomes 'touched1'
  debug.setuservalue(U, {x = {234}})
  print(T.gcage(U))
  print(T.gcage(debug.getuservalue(U)))
  --assert(T.gcage(U) == "touched1" and
  --       T.gcage(debug.getuservalue(U)) == "new")

  -- both U and the table survive one more collection
  collectgarbage("step", 0)
  print(T.gcage(U))
  print(T.gcage(debug.getuservalue(U)))
  --assert(T.gcage(U) == "touched2" and
  --       T.gcage(debug.getuservalue(U)) == "survival")

  -- both U and the table survive yet another collection
  -- now everything is old
  collectgarbage("step", 0)
  print(T.gcage(U))
  print(T.gcage(debug.getuservalue(U)))
  --assert(T.gcage(U) == "old" and
  --       T.gcage(debug.getuservalue(U)) == "old1")

  -- data was not corrupted
  assert(debug.getuservalue(U).x[1] == 234)
end

-- just to make sure
assert(collectgarbage'isrunning')



-- just to make sure
assert(collectgarbage'isrunning')

collectgarbage(oldmode)

print('OK')

