PriorityQueue = {
  nodes = {},
  put = function(node, cost)
  
  end,
  get = function()
  
  end
}

function heuristic(a,b)
  --manhattan distance
  return math.abs(a.x - b.x) + math.abs(a.y - b.y)
end

function gcost(a,b)

end

local cachedNeighbors = {}

function getKey(node)
  return node.position.x.."|"..node.position.y.."|"..node.direction.."|"..node.name
end

function getNeighbors(node, travelDirection)
  local key = getKey(node)
  if not cachedNeighbors[key] then
    for i=0,2 do
      local newTravel, node = FARL.getRail(node, travelDirection, i)
      cachedNeighbors[key][i+1] = FARL.getRail(node, travelDirection, i)
    end
  end
  return cachedNeighbors[key]
end

function astar(start, goal)

  local frontier = PriorityQueue.new() -- open list
  frontier.put(start, 0)
  local cameFrom = {} --closed list
  local cost_so_far = {}
  cameFrom[start] = "None"
  cost_so_far[start] = 0
    
  while #frontier > 0 do
    local current = frontier.get()
    
    -- done
    if current == goal then
      break
    end
    -- get connected nodes from current    
    local neighbors = getNeighbors(current)
    
    for i=1,#neighbors do
      local next = neighbors[i]
      local new_cost = cost_so_far[current] + gcost(current, next)
      if not cost_so_far[next] or new_cost < cost_so_far[next] then
        cost_so_far[next] = new_cost
        local priority = new_cost + heuristic(goal, next)
        frontier.put(next, priority)
        cameFrom[next] = current
      end
    end
  end
end

function getPath(start, goal, cameFrom)
  local current = goal
  local path = {current}
  while current ~= start do
    current = cameFrom[current]
    table.insert(path, current)
  end
end