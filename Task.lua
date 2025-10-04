local Maid = {};
Maid.__index = Maid;

function Maid.new()
    return setmetatable({
        _tasks = {},
        _features = {},
        _indices = {},
        _threads = {}
    }, Maid);
end

function Maid:AddTask(task, feature)
    assert(task ~= nil, 'Task cannot be nil');
    if feature then
        assert(type(feature) == 'string' or type(feature) == 'number', 'Feature must be a string or number');
        self._features[feature] = self._features[feature] or {};
        table.insert(self._features[feature], task);
    end
    table.insert(self._tasks, task);
    if typeof(task) == 'thread' then
        table.insert(self._threads, task);
    end
    return task;
end

function Maid:Add(task)
    assert(task ~= nil, 'Task cannot be nil');
    return self:AddTask(task);
end

function Maid:GiveTask(task)
    assert(task ~= nil, 'Task cannot be nil');
    return self:AddTask(task);
end

function Maid:GivePromise(promise)
    assert(promise ~= nil, 'Promise cannot be nil');
    if promise.Status == 'Rejected' or promise.Status == 'Resolved' then
        return promise;
    end
    local connPromise = nil;
    connPromise = promise:Finally(function()
        self:Remove(connPromise);
    end);
    return self:AddTask(connPromise);
end

function Maid:__newindex(index, task)
    if task == nil then
        self:Remove(self._indices[index]);
        self._indices[index] = nil;
        return;
    end
    self._indices[index] = task;
    self:AddTask(task);
end

function Maid:Remove(task)
    if task == nil then
        return;
    end

    for idx1, task1 in ipairs(self._tasks) do
        if task1 == task then
            local removedTask1 = table.remove(self._tasks, idx1);
            self:_cleanupTask(removedTask1);
            return;
        end
    end

    for featKey2, tasksList2 in pairs(self._features) do
        for idx2, task2 in ipairs(tasksList2) do
            if task2 == task then
                local removedTask2 = table.remove(tasksList2, idx2);
                self:_cleanupTask(removedTask2);
                return;
            end
        end
    end

    for idx3, thread3 in ipairs(self._threads) do
        if thread3 == task then
            table.remove(self._threads, idx3);
            return;
        end
    end
end

function Maid:_cleanupTask(task)
    if task == nil then
        return;
    end

    local taskType = typeof(task);

    if taskType == 'function' then
        task();
    elseif taskType == 'RBXScriptConnection' then
        task:Disconnect();
    elseif taskType == 'Instance' then
        task:Destroy();
    elseif taskType == 'thread' then
        if coroutine.status(task) ~= 'dead' then
            pcall(function()
                coroutine.close(task);
            end);
        end
    elseif taskType == 'table' then
        if task.Destroy then
            task:Destroy();
        elseif task.Disconnect then
            task:Disconnect();
        elseif task.destroy then
            task:destroy();
        elseif task.disconnect then
            task:disconnect();
        elseif task.Clean then
            task:Clean();
        elseif task.cancel then
            task:cancel();
        end
    end
end

function Maid:Clean()
    for idx4, task4 in ipairs(self._tasks) do
        self:_cleanupTask(task4);
    end
    table.clear(self._tasks);
    table.clear(self._features);
    table.clear(self._indices);
    table.clear(self._threads);
end

function Maid:Cleanup(feature)
    if feature then
        assert(type(feature) == 'string' or type(feature) == 'number', 'Feature must be a string or number');
        for idx5, task5 in ipairs(self._features[feature] or {}) do
            self:_cleanupTask(task5);
        end
        self._features[feature] = {};

        for i = #self._tasks, 1, -1 do
            local candidate6 = self._tasks[i];
            for idx6, featureTask6 in ipairs(self._features[feature] or {}) do
                if candidate6 == featureTask6 then
                    table.remove(self._tasks, i);
                    break;
                end
            end
        end

        return;
    end

    for idx7, task7 in ipairs(self._tasks) do
        self:_cleanupTask(task7);
    end

    self._tasks = {};
    self._features = {};
    self._indices = {};
    self._threads = {};
end

function Maid:Destroy()
    self:Cleanup();
end

function Maid:DoCleaning()
    self:Cleanup();
end

return Maid;