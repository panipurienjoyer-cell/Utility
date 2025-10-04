local Signal = {};
Signal.__index = Signal;

function Signal.new()
    local instance = setmetatable({}, Signal);
    instance._listeners = {};
    instance._waiting = {};
    return instance;
end;

function Signal:Fire(...)
    local params = {...};
    local count = select('#', ...);

    for i = #self._listeners, 1, -1 do
        local sub = self._listeners[i];
        if sub._dead then
            table.remove(self._listeners, i);
        else
            task.spawn(function()
                sub._handler(table.unpack(params, 1, count));
            end);
        end;
    end;

    for i = #self._waiting, 1, -1 do
        local thread = table.remove(self._waiting, i);
        task.spawn(thread, table.unpack(params, 1, count));
    end;
end;

function Signal:Connect(callback)
    local subscriber = {
        _event = self,
        _handler = callback,
        _dead = false
    };

    function subscriber:Disconnect()
        subscriber._dead = true;
    end;

    table.insert(self._listeners, subscriber);
    return subscriber;
end;

function Signal:Wait()
    table.insert(self._waiting, coroutine.running());
    return coroutine.yield();
end;

function Signal:Destroy()
    table.clear(self._listeners);
    table.clear(self._waiting);
end;

return Signal;