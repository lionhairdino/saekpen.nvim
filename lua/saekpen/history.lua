local H = {}
local stack = require("saekpen/lib/stack")

function H.init()
  return { undo = stack.new(), redo = stack.new() }
end
function H.add(history, v)
  stack.push(history.undo, v)
end

function H.undo(history)
  local one = stack.pop(history.undo)
  if one ~= nil then
    stack.push(history.redo,{-one[1],one[2],one[3],one[4],one[5],one[6]})
  end
  return one
end

function H.redo(history)
  local one = stack.pop(history.redo)
  if one ~= nil then
    stack.push(history.undo,{-one[1],one[2],one[3],one[4],one[5],one[6]})
  end
  return one
end

function H.reset_redo(history)
  history.redo = stack.new()
end

function H.save()

end

function H.load()

end

return H

