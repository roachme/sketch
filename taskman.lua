--- Manage task units.
-- Create a new unit, move to diff statuses and so on.
-- @module TaskMan


local taskid    = require("taskid")
local taskunit  = require("taskunit")
local git = require("git")

local function log(fmt, ...)
    local msg = "tman: " .. fmt:format(...)
    print(msg)
end

local TaskMan = {}
TaskMan.__index = TaskMan

local function usage()
    print(([[
Usage: %s cmd [TASKID] [STATUS]
Task items related commands:
  new   - create new task item
  use   - mark a task as current
  move  - move a task to new status. Default: backlog
  prev  - switch to previous task
  list  - list all tasks
  show  - show task info. Default: current task (if exists)
  amend - amend task description and branch
  review- push commits for review
  done  - move task unit to .done directory

Task specificly related commands:
  check - check git commit, rebase/ merge, CHANGELOG.md and pass task code through tests in MakefileWimark
  time  - time you spent on task
  dline - show updated deadline

General:
  help  - show this message
  info  - show inner things as list of statuses and other info

For developer:
  init  - download repos and create symlinks for all them
  del   - delete task dir, branch, and meta
]]):format("tman"))
end


--- Class TaskMan
-- type TaskMan

--- Init class TaskMan.
function TaskMan.init()
    local taskpath = "/home/roach/work/tasks"
    local self = setmetatable({
        taskid   = taskid.new(taskpath),
        taskunit = taskunit.newobj(taskpath),
    }, TaskMan)
    return self
end

--- Create a new task unit.
-- @param id task ID
function TaskMan:new(id)
    if not id then
        print("tman: missing task ID")
        os.exit(1)
    end
    if not self.taskid:add(id) then
        log("task ID '%s' exists already", id)
        os.exit(1)
    end
    if not self.taskunit:new(id) then
        print("taskman: colud not create new task unit")
        self.taskid:del(id)
        os.exit(1)
    end
end

--- Switch to new task.
-- @param id task ID
function TaskMan:use(id)
    if not id then
        print("tman: missing task ID")
        os.exit(1)
    end
    if not self.taskid:exist(id) then
        log("task ID '%s' does't exist", id)
        os.exit(1)
    end
    self:move("progress", id)
    -- roachme: check this no current task,
    -- if so then check if we can move to backlog
    -- i.e. check it has no uncommited changes
end

--- Move task to new status.
-- FIXME: case: when new ID and current task ID are the same
-- @param status status to move task to
-- @param id task ID. Default: current task ID
function TaskMan:move(status, id)
    if not status then
        log("missing status")
        os.exit(1)
    end
    if id and id == self.taskid.curr then
        log("task '%s' is already in use", id)
        os.exit(1)

    elseif (id and self.taskid.curr) and status == "progress" then
        print("replace new task with current one (in progress)")
        local gitobj = git.new(id, self.taskunit:getunit(id, "branch"))
        if not gitobj:branch_switch() then
            log("repo has uncommited changes")
            os.exit(1)
        end
        self.taskunit:setunit(self.taskid.curr, "Status", "backlog")
        self.taskunit:setunit(id, "Status", "progress")
        self.taskid:setcurr(id)

    elseif id and status == "progress" then
        print("new task to progress")
        local gitobj = git.new(id, self.taskunit:getunit(id, "branch"))
        if not gitobj:branch_switch() then
            log("repo has uncommited changes")
            os.exit(1)
        end
        print("set new current task ID")
        self.taskunit:setunit(id, "Status", status)
        self.taskid:setcurr(id)

    elseif id and status ~= "progress" then
        print("new task to somewhere else:", id)
        self.taskunit:setunit(id, "Status", status)

    elseif self.taskid.curr and status ~= "progress" then
        print("move current task to somewhere else")
        local gitobj = git.new(self.taskid.curr, self.taskunit:getunit(self.taskid.curr, "branch"))
        if not gitobj:branch_switch() then
            log("repo has uncommited changes")
            os.exit(1)
        end
        self.taskunit:setunit(self.taskid.curr, "Status", status)
        self.taskid:unsetcurr()

    else
        log("no current task exists")
        os.exit(1)
    end
    return true
end

--- Switch to previous task.
function TaskMan:prev()
    self:move("progress", self.taskid.prev)
    local prev = self.taskid.prev
    self.taskid:setprev(self.taskid.curr)
    self.taskid:setcurr(prev)
end

--- List all task IDs.
function TaskMan:list()
    self.taskid:list(function() return "" end)
end

--- Show task unit metadata.
-- @param id task ID
function TaskMan:show(id)
    -- roachme: taskunit should check that id exists
    id = id or self.taskid.curr
    if not id then
        print("tman: neither task ID passed nor current exists")
        os.exit(1)
    end
    if not self.taskid:exist(id) then
        log("no such task ID '%s'", id)
        os.exit(1)
    end
    self.taskunit:show(id)
end

--- Amend task unit.
-- @param id task ID
function TaskMan:amend(id)
end

--- Delete task unit.
-- @param id task ID
function TaskMan:del(id)
    if not self.taskid:exist(id) then
        log("taskid '%s' does not exist", id)
        os.exit(1)
    end
    self.taskunit:del(id)
    self.taskid:del(id)
end

--- Move task to done directory.
-- @param id task ID
function TaskMan:done(id)
end

--- Interface.
function TaskMan:main(arg)
    if arg[1] == "new" then
        self:new(arg[2])
    elseif arg[1] == "use" then
        self:use(arg[2])
    elseif arg[1] == "move" then
        self:move(arg[2], arg[3])
    elseif arg[1] == "list" then
        self:list()
    elseif arg[1] == "show" then
        self:show(arg[2])
    elseif arg[1] == "prev" then
        self:prev()
    elseif arg[1] == "del" then
        self:del(arg[2])
    elseif arg[1] == "done" then
        self:done(arg[2])
    elseif not arg[1] then
        print("tman: command expected")
    else
        print("tman: no such command: " .. arg[1])
    end
end

local tman = TaskMan.init()
tman:main(arg)

return TaskMan
