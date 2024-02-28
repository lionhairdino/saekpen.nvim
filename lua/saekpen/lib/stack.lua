local S = {}

function S.new()
  return { top = 0 }
end

function S.push(stack, v)
  stack.top = stack.top + 1
  stack[stack.top] = v
end

function S.pop(stack)
  if stack.top > 0 then
    local res = stack[stack.top]
    stack[stack.top] = nil
    stack.top = stack.top -1
    return res
  else
    return nil
  end
end

return S
