--- Operate on task units in database.
-- Like add, delete, list task IDs and so on.
-- @module TaskID


local TaskID = {}
TaskID.__index = TaskID

local TaskIDPrivate = {}
TaskIDPrivate.__index = TaskIDPrivate


--[[ TODO
    1. Make a function to create files for current and previous taskid's
    2. Set and update vars curr and prev not to calculate 'em all over again.
]]


--[[
Notes:
    To simplify upper layers life this module check everything itself.
]]


local function log(fmt, ...)
    local msg = "taskid: " .. fmt:format(...)
    print(msg)
end


--- Class TaskIDPrivate
-- type TaskIDPrivate


--- Init class TaskIDPrivate.
-- @param gtaskpath path where tasks are located
function TaskIDPrivate.new()
    local self = setmetatable({
        taskpath = "/home/roach/work/tasks",
        meta  = "/home/roach/work/tasks" .. "/.tasks",
        curr  = nil,
        prev  = nil,
    }, TaskIDPrivate)
    self.curr = self:getcurr()
    self.prev = self:getprev()
    return self
end

--- Get task ID (private).
-- @param val `curr` or `prev` for current or previous task id
-- @return task ID or nil if task doesn't exist
function TaskIDPrivate:_gettaskid(type)
    local fname = self.taskpath .. "/." .. type
    local f = io.open(fname)
    if not f then
        log("could not open file", fname)
        return
    end
    local id = f:read("*l")
    f:close()
    return id
end

--- Set task ID (private).
-- @param taskid task ID to set
-- @param val `curr` or `prev` for current or previous task id
function TaskIDPrivate:_settaskid(taskid, type)
    local fname = self.taskpath .. "/." .. type
    local f = io.open(fname, "w")
    if not f then
        log("could not open file", fname)
        return
    end
    f:write(taskid, "\n")
    f:close()
end

--- Unset current task ID (private).
function TaskIDPrivate:unsetcurr()
    local fname = self.taskpath .. "/.curr"
    local f = io.open(fname, "w")
    if not f then
        return
    end
    f:close()
end

--- Unset previous task ID (private).
function TaskIDPrivate:unsetprev()
    local fname = self.taskpath .. "/.prev"
    local f = io.open(fname, "w")
    if not f then
        return
    end
    f:close()
end

--- Get current task ID (private).
-- @return current task ID.
function TaskIDPrivate:getcurr()
    return self:_gettaskid("curr")
end

--- Get previous task ID (private).
-- @returtn previous task ID.
function TaskIDPrivate:getprev()
    return self:_gettaskid("prev")
end

--- Set current task ID (private).
-- @param task ID
function TaskIDPrivate:setcurr(taskid)
    self:_settaskid(taskid, "curr")
    self.curr = taskid
end

--- Set previous task ID (private).
-- @param task ID
function TaskIDPrivate:setprev(taskid)
    self:_settaskid(taskid, "prev")
    self.prev = taskid
end


--- Class TaskID
-- type TaskID


local taskid_pr = TaskIDPrivate.new()

--- Init class TaskID.
function TaskID.new()
    local self = setmetatable({
        curr = taskid_pr:getcurr(),
        prev = taskid_pr:getprev(),
    }, TaskID)
    return self
end

--- Add a new task ID.
-- @param taskid task ID to add to database
-- @treturn bool true if task ID was adde, otherwise false
function TaskID:add(taskid)
    local f = io.open(taskid_pr.meta, "a+")
    if self:exist(taskid) then
        log(("task '%s' already exists"):format(taskid))
        return false
    end
    if not f then
        log("could not open meta file")
        return false
    end
    f:write(taskid, "\n")
    f:close()

    taskid_pr:setcurr(taskid)
    self.curr = taskid_pr:getcurr()
    if self.curr then
        taskid_pr:setprev(self.curr)
    end
    return true
end

--- Check that task ID exist in database (private).
-- @param taskid task ID to look up
-- @treturn bool true if task ID exist, otherwise false
function TaskID:exist(taskid)
    local res = false
    local f = io.open(taskid_pr.meta, "r")
    if not f then
        log("could not open meta file")
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

--- Delete a task ID.
-- @treturn bool true if deleting task ID was successful, otherwise false
function TaskID:del(taskid)
    local f = io.open(taskid_pr.meta, "r")
    local lines = {}
    if not self:exist(taskid) then
        log("task '%s' doesn't exist", taskid)
        return false
    end
    if not f then
        log("could not open meta file")
        return false
    end
    for line in f:lines() do
        if line ~= taskid then
            table.insert(lines, line)
        end
    end
    f:close()

    -- Update database file
    f = io.open(taskid_pr.meta, "w")
    if not f then
        log("could not open meta file")
        return false
    end
    for _, line in pairs(lines) do
        f:write(line, "\n")
    end
    f:close()

    -- remove current task ID from file
    taskid_pr:unsetcurr()
    self.curr = taskid_pr:getcurr()
    return true
end

--- List all task IDs from the database.
-- @param fn callback function
function TaskID:list(fn)
    local f = io.open(taskid_pr.meta)
    if not f then
        log("could not open meta file")
        return
    end
    if self.curr then
        print(("* %-8s %s"):format(self.curr, fn()))
    end
    for id in f:lines() do
        if self.curr ~= id then
            print(("  %-8s %s"):format(id, fn()))
        end
    end
    f:close()
end

return TaskID
