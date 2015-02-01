PriorityQueue = {
  
  new = function()
    local o = {nodes={}, n = 0}
    setmetatable(o, {__index=PriorityQueue})
    return o
  end,
  
  put = function(self, node, cost)
    self.nodes[cost] = self.nodes[cost] or {}
    for i, ncost in pairs(self.nodes) do
      for j, n in pairs(ncost) do
        if node == n then
           table.remove(self.nodes[i], j)
           self.n = self.n-1
        end
      end
    end
    table.insert(self.nodes[cost], node)
    self.n = self.n + 1
  end,
  
  get = function(self)
    local min = 1/0
    local ret
    for cost, nodes in pairs(self.nodes) do
      min = cost < min and cost or min
    end
    if self.nodes[min] then
      ret = table.remove(self.nodes[min])
      if #self.nodes[min] == 0 then
        self.nodes[min] = nil
      end
      self.n = self.n - 1
      return ret
    else
      return nil
    end
  end
}

function heuristic(a,b)
  return  (((a.position.x - b.position.x)^2 + (a.position.y - b.position.y)^2)^0.5)
--  local dx = math.abs(a.position.x - b.position.x)
--  local dy = math.abs(a.position.y - b.position.y)
--  local max = dx > dy and dx or dy
--  return max
end

function tiebreaker(current, start, goal)
  local dx1 = current.position.x - goal.position.x
  local dy1 = current.position.x - goal.position.x
  local dx2 = start.position.x - goal.position.x
  local dy2 = start.position.x - goal.position.x
  local cross = math.abs(dx1*dy2 - dx2*dy1)*0.001
  return cross
end

function gcost(a,b, goal)
  local penalty = a.travelDir ~= b.travelDir and 5 or 0
  return heuristic(a,b) + penalty  
end

cachedNeighbors = {n=0}

function getKey(node)
  --debugDump(node,true)
  return node.position.x.."|"..node.position.y.."|"..node.direction.."|"..node.name.."|"..node.travelDir
end

function getNeighbors(node)
  local key = getKey(node)
  if not cachedNeighbors[key] then
    cachedNeighbors[key] = {}
    cachedNeighbors.n = cachedNeighbors.n+1
    for i=0,2 do
      local newTravel, node = FARL.getRail(node, node.travelDir, i)
      if type(newTravel) == "number" then
        node.travelDir = newTravel
      else
        node = node[2]
        node.travelDir = newTravel[2]
      end
        --debugDump(newTravel,true)
        cachedNeighbors[key][i+1] = node
    end
  end
  return cachedNeighbors[key]
end

function goalReached(current, goal)
  if  current.position.x == goal.position.x and 
      current.position.y == goal.position.y and
      current.direction == goal.direction and
      current.travelDir == goal.travelDir then
    return true
  else
    return false
  end
end

function astar(start, goal)
  cachedNeighbors = {n=0}
  local frontier = PriorityQueue.new() -- open list
  frontier:put(start, 0)
  local cameFrom = {} --closed list
  local cost_so_far = {}
  cameFrom[start] = "Null"
  cost_so_far[getKey(start)] = 0
  --debugDump({start,goal},true)
  local count = 1
  local current
  --while count < 400 do  
    count = count+1
  while frontier.n > 0 do
    current = frontier:get()
    -- done
    --debugDump({n=frontier.n, current},true)
    if current ~= nil then
      if goalReached(current, goal) then
        break
      end
      -- get connected nodes from current
      local neighbors = getNeighbors(current)
      --debugDump({nei=neighbors, current = current},true)
      for i=1,#neighbors do
          local next = neighbors[i]
          local new_cost = cost_so_far[getKey(current)] + gcost(current, next, goal)
          if not cost_so_far[getKey(next)] or new_cost < cost_so_far[getKey(next)] then
            cost_so_far[getKey(next)] = new_cost
            local priority = new_cost + heuristic(goal, next) --+ tiebreaker(current,start,goal)
            frontier:put(next, priority)
            cameFrom[next] = current
          end
      end
    end
  end
  debugDump("finished, cached Neighbors:"..cachedNeighbors.n, true)
  return getPath(start, current, cameFrom), cost_so_far
end

function getPath(start, goal, cameFrom)
  local current = goal
  local path = {current}
  while current and not goalReached(current, start) do
    current = cameFrom[current]
    table.insert(path, current)
  end
  return path
end