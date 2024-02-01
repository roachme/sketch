local taskpath = "/home/roach/work/sketch/lua/sketch/"

local TaskID = {}
TaskID.__index = TaskID


--[[ TODO
    1. Make a function to create files for current and previous taskid's
]]


--- Class TaskID
-- type TaskID

--- Init class TaskID.
-- @param gtaskpath path where tasks are located
function TaskID.new(gtaskpath)
    local self = setmetatable({
        taskpath = gtaskpath,
        meta = gtaskpath .. "/.tasks",
        --- roachme: seems like we don't use these two
        fcurr = gtaskpath .. "/.curr",
        fprev = gtaskpath .. "/.prev",
        curr  = nil,
        prev  = nil,
    }, TaskID)
    return self
end

--- Get task ID (private).
-- @param val `curr` or `prev` for current or previous task id
-- @return task ID or nil if task doesn't exist
function TaskID:_gettaskid(type)
    local fname = taskpath .. "/." .. type
    local f = io.open(fname)
    if not f then
        print("error: could not open file", fname)
        return
    end
    local curr = f:read("*l")
    f:close()
    return curr
end

--- Set task ID (private).
-- @param taskid task ID to set
-- @param val `curr` or `prev` for current or previous task id
function TaskID:_settaskid(taskid, type)
    local fname = taskpath .. "/." .. type
    local f = io.open(fname, "w")
    if not f then
        print("error: could not open file", fname)
        return
    end
    f:write(taskid, "\n")
    f:close()
end

--- Unset current task ID.
function TaskID:unsetcurr()
    local fname = taskpath .. "/.curr"
    local f = io.open(fname, "w")
    if not f then
        return
    end
    f:close()
end

--- Unset previous task ID.
function TaskID:unsetprev()
    local fname = taskpath .. "/.prev"
    local f = io.open(fname, "w")
    if not f then
        return
    end
    f:close()
end

--- Get current task ID.
-- @return current task ID.
function TaskID:getcurr()
    return self:_gettaskid("curr")
end

--- Get previous task ID.
-- @returtn previous task ID.
function TaskID:getprev()
    return self:_gettaskid("prev")
end

--- Set current task ID.
-- @param task ID
function TaskID:setcurr(taskid)
    self:_settaskid(taskid, "curr")
end

--- Set previous task ID.
-- @param task ID
function TaskID:setprev(taskid)
    self:_settaskid(taskid, "prev")
end

--- Check that task ID exist in database.
-- @param taskid task ID to look up
-- @treturn bool true if task ID exist, otherwise false
function TaskID:check(taskid)
    local res = false
    local f = io.open(self.meta, "r")
    if not f then
        print("error: could not open meta file")
        return
    end
    for line in f:lines() do
        if line == taskid then
            res = true
            break
        end
    end
    f:close()
    return res
end

--- Add a new task ID.
function TaskID:add(taskid)
    local curr = self:getcurr()
    local f = io.open(self.meta, "a+")
    if self:check(taskid) then
        print(("warning: task '%s' already exists"):format(taskid))
        return
    end
    if not f then
        print("error: could not open meta file")
        return
    end
    f:write(taskid, "\n")
    f:close()
    self:setcurr(taskid)
    if curr then
        self:setprev(curr)
    end
end

--- Delete a task ID.
function TaskID:del(taskid)
    local f = io.open(self.meta, "r")
    local lines = {}
    if not self:check(taskid) then
        print(("warning: task '%s' doesn't exist"):format(taskid))
        return
    end
    if not f then
        print("error: could not open meta file")
        return
    end
    for line in f:lines() do
        if line ~= taskid then
            table.insert(lines, line)
        end
    end
    f:close()

    -- Update database file
    f = io.open(self.meta, "w")
    if not f then
        print("error: could not open meta file")
        return
    end
    for _, line in pairs(lines) do
        f:write(line, "\n")
    end
    f:close()

    -- remove current task ID from file
    self:unsetcurr()
end


local taskid = TaskID.new(taskpath)
taskid:del("DE-101")

