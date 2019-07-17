--from: https://github.com/mspielberg/factorio-miniloader/blob/master/version.lua
local version = {}

function version.parse(str)
  local major, minor, patch = string.match(str, "^(%d+)%.(%d+)%.(.+)$")
  return {tonumber(major), tonumber(minor), tonumber(patch)}
end

function version.eq(v1, v2)
  for i = 1, 3 do
    if v1[i] ~= v2[i] then
      return false
    end
  end
  return true
end

function version.lt(v1, v2)
  for i = 1, 3 do
    if v1[i] < v2[i] then
      return true
    elseif v1[i] > v2[i] then
      return false
    end
  end
  return false
end

function version.gteq(v1, v2)
  return not version.lt(v1, v2)
end

function version.between(x, l, h)
  return version.gteq(x, l) and version.lt(x, h)
end

return version