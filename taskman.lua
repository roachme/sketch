--- Manage task units.
-- Create a new unit, move to diff statuses and so on.
-- @module TaskMan


local taskid    = require("taskid")
local taskunit  = require("taskunit")


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

Task specificly related commands:
  check - check git commit, rebase/ merge, CHANGELOG.md and pass task code through tests in MakefileWimark
  time  - time you spent on task
  dline - show updated deadline
  done  - git push task code

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
    if self.taskid:check(id) then
        print(("taskman: such task ID already exits: '%s'"):format(id))
        os.exit(1)
    end
    if not self.taskunit:new(id) then
        print("taskman: colud not create new task unit")
        os.exit(1)
    end
    self.taskid:add(id)
end

function TaskMan:use()
end

function TaskMan:move()
end

--- Switch to previous task.
function TaskMan:prev()
end

--- List all task IDs.
function TaskMan:list()
    self.taskid:list(function() return "" end)
end

--- Show task unit metadata.
-- @param id task ID
function TaskMan:show(id)
    if not self.taskid:check(id) then
        print(("taskman: no such task ID: '%s'"):format(id))
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
    -- roachme: git: delete git branches in repos
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
        self:use()
    elseif arg[1] == "move" then
        self:move()
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
--tman:main(arg)



local function get_input(promtp)
    -- TODO: trim trailing newlines and whitespaces
    io.write(promtp, ": ")
    return io.read("*line")
end


return TaskMan
