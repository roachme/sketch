--- Operate on task unit inside meta data.
-- Metadata like branch name, date, description and so on.
-- @module TaskUnit

local posix = require("posix")


local TaskUnit = {}
TaskUnit.__index = TaskUnit


local function get_input(promtp)
    io.write(promtp, ": ")
    return io.read("*line")
end

local function format_branch(task)
    local branch = task.type.value .. "/" .. task.id.value
    branch = branch .. "_" .. task.desc.value:gsub(" ", "_")
    branch = branch .. "_" .. task.date.value
    return branch
end

--- Check that user specified task type exists.
-- @tparam string type user specified type
-- @treturn bool true if exists, otherwise false
local function check_tasktype(type)
    local tasktypes = { "bugfix", "feature", "hotfix" }
    local found = false
    for _, dtype in pairs(tasktypes) do
        if type == dtype then
            found = true
        end
    end
    return found
end


--- Class TaskUnit
-- type TaskUnit

--- Init class TaskUnit.
function TaskUnit.newobj(gtaskpath)
    local self = setmetatable({
        taskpath = gtaskpath
    }, TaskUnit)
    return self
end


--- Create a new unit for a task.
-- @param id task id
function TaskUnit:new(id)
    local file    = nil
    local taskdir = self.taskpath .. "/" .. id
    local fname   = taskdir .. "/.note"

    local unit = {
        id     = { mark = false, inptext = "ID",     value = id },
        type   = { mark = true,  inptext = "Type",   value = "" },
        desc   = { mark = true,  inptext = "Desc",   value = "" },
        date   = { mark = false, inptext = "Date",   value = os.date("%Y%m%d") },
        branch = { mark = false, inptext = "Branch", value = "" },
        status = { mark = false, inptext = "Status", value = "progress" },
    }

    -- roachme: sort table
    -- Get user input
    for _, item in pairs(unit) do
        if item.mark then
            item.value = get_input(item.inptext)
        end
    end
    unit.branch.value = format_branch(unit)

    -- Check user input
    if not check_tasktype(unit.type.value) then
        print("taskunit: error: unknown task type: " .. unit.type.value)
        return false
    end

    -- roachme: git: create branches in repos

    -- Save task info
    posix.mkdir(taskdir)
    file = io.open(fname, "w")
    if not file then
        print("taskunit: error: could not create file note", fname)
        return false
    end
    for _, item in pairs(unit) do
        file:write(("%s: %s\n"):format(item.inptext, item.value))
    end
    file:close()
    return true
end

--- Update task status.
-- @param id task ID
-- @param status what status to move a task to
function TaskUnit:setstatus(id, status)
end

--- Amend task unit.
-- Like branch name, ID, etc.
function TaskUnit:amend(id)
end

--- Show task unit metadata.
-- @param id task ID
function TaskUnit:show(id)
    local fname = self.taskpath .. "/" .. id .. "/.note"
    local f = io.open(fname)
    if not f then
        print("taskunit: could not open file", fname)
        return false
    end
    for line in f:lines() do
        print(line)
    end
    f:close()
    return true
end

--- Delete task unit.
-- @param id task ID
function TaskUnit:del(id)
    return os.execute("rm -rf " .. self.taskpath .. "/" .. id)
end

return TaskUnit
