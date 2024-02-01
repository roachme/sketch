--- Operate on task units in database.
-- Like add, delete, list units and so on.
-- @module TaskID


local TaskID = {}
TaskID.__index = TaskID


--[[ TODO
    1. Make a function to create files for current and previous taskid's
    2. Set and update vars curr and prev not to calculate 'em all over again.
]]


--- Class TaskID
-- type TaskID

--- Init class TaskID.
-- @param gtaskpath path where tasks are located
function TaskID.new(gtaskpath)
    local self = setmetatable({
        taskpath = gtaskpath,
        meta  = gtaskpath .. "/.tasks",
        curr  = nil,
        prev  = nil,
    }, TaskID)
    self:getcurr()
    self:getprev()
    return self
end

--- Get task ID (private).
-- @param val `curr` or `prev` for current or previous task id
-- @return task ID or nil if task doesn't exist
function TaskID:_gettaskid(type)
    local fname = self.taskpath .. "/." .. type
    local f = io.open(fname)
    if not f then
        print("error: could not open file", fname)
        return
    end
    local id = f:read("*l")
    f:close()
    return id
end

--- Set task ID (private).
-- @param taskid task ID to set
-- @param val `curr` or `prev` for current or previous task id
function TaskID:_settaskid(taskid, type)
    local fname = self.taskpath .. "/." .. type
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
    local fname = self.taskpath .. "/.curr"
    local f = io.open(fname, "w")
    if not f then
        return
    end
    f:close()
end

--- Unset previous task ID.
function TaskID:unsetprev()
    local fname = self.taskpath .. "/.prev"
    local f = io.open(fname, "w")
    if not f then
        return
    end
    f:close()
end

--- Get current task ID.
-- @return current task ID.
function TaskID:getcurr()
    self.curr = self:_gettaskid("curr")
    return self.curr
end

--- Get previous task ID.
-- @returtn previous task ID.
function TaskID:getprev()
    self.prev = self:_gettaskid("prev")
    return self.prev
end

--- Set current task ID.
-- @param task ID
function TaskID:setcurr(taskid)
    self:_settaskid(taskid, "curr")
    self.curr = taskid
end

--- Set previous task ID.
-- @param task ID
function TaskID:setprev(taskid)
    self:_settaskid(taskid, "prev")
    self.prev = taskid
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
-- @param taskid task ID to add to database
-- @treturn bool true if task ID was adde, otherwise false
function TaskID:add(taskid)
    local curr = self:getcurr()
    local f = io.open(self.meta, "a+")
    if self:check(taskid) then
        print(("warning: task '%s' already exists"):format(taskid))
        return false
    end
    if not f then
        print("error: could not open meta file")
        return false
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

--- List all task IDs from the database.
-- @param fn callback function
function TaskID:list(fn)
    local f = io.open(self.meta)
    if not f then
        print("error: could not open meta file")
        return
    end
    for id in f:lines() do
        if self.curr == id then
            local fmt = "* %-8s %s"
            print(fmt:format(id, fn()))
        else
            local fmt = "  %-8s %s"
            print(fmt:format(id, fn()))
        end
    end
end

return TaskID
