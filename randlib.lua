local F = {
    hash = {},
    vec = {},
    table = {},
    random = {}
}

function F.add_connections(entity, connections)
    for _, connection in pairs(connections) do
        if connection.direction == 0 then
            connection.position.y = math.floor(entity.collision_box.left_top.y + 0.5)
        elseif connection.direction == 4 then
            connection.position.x = math.floor(entity.collision_box.right_bottom.x + 0.5)
        elseif connection.direction == 8 then
            connection.position.y = math.floor(entity.collision_box.right_bottom.y + 0.5)
        elseif connection.direction == 12 then
            connection.position.x = math.floor(entity.collision_box.left_top.x + 0.5)
        end
    end
end

---Returns the item with the given name, if it exists
---@param name string
---@return data.ItemPrototype?
function F.get_item(name)
    for type in pairs(defines.prototypes.item) do
        if data.raw[type] and data.raw[type][name] then
            ---@type data.ItemPrototype
            return data.raw[type][name]
        end
    end
end

---comment
---@param item data.ItemPrototype
---@return boolean
function F.is_stackable(item)
    if item.stack_size == 1 then
        return false
    end
    for _, flag in pairs(item.flags or {}) do
        if flag == "not-stackable" then
            return false
        end
    end
    return true
end

---Returns a list containing every value in both `m` and `n`
---@param m [any]
---@param n [any]
---@return [any]
function F.table.intersect(m, n)
    local r = {}
    for _, x in pairs(m) do
        for _, y in pairs(n) do
            if x == y then
                table.insert(r, x)
                break
            end
        end
    end
    return r
end

function F.table.common_idx(t)
    local r = nil
    for _, v in pairs(t) do
        if not r then
            r = F.table.intersect(v, v)
        else
            r = F.table.intersect(r, v)
        end
    end
    return r
end

---Returns a list with every unique value in `t`
---@param t [any]
---@return [any]
function F.table.remove_duplicates(t)
    local table = {}
    local res = {}
    for _, v in pairs(t) do
        if not table[v] then
            res[#res+1] = v
            table[v] = true
        end
    end
    return res
end

---@param vec {[1]: number, [2]: number} | {x: number, y: number}
---@return {[1]: number, [2]: number}
function F.vec.vec_as_array(vec)
    local x = vec[1] or vec.x
    local y = vec[2] or vec.y
    return {x, y}
end

---returns the euclidean distance between `vec1` and `vec2`
---@param vec1 {[1]: number, [2]: number} | {x: number, y: number}
---@param vec2 {[1]: number, [2]: number} | {x: number, y: number}
---@return number
function F.vec.euclidean_dist(vec1, vec2)
    vec1 = F.vec.vec_as_array(vec1)
    vec2 = F.vec.vec_as_array(vec2)
    return math.sqrt((vec1[1] - vec2[1]) ^ 2 + (vec1[2] - vec2[2]) ^ 2)
end

---returns the manhattan distance between `vec1` and `vec2`
---@param vec1 {[1]: number, [2]: number} | {x: number, y: number}
---@param vec2 {[1]: number, [2]: number} | {x: number, y: number}
---@return number
function F.vec.manhattan_dist(vec1, vec2)
    vec1 = F.vec.vec_as_array(vec1)
    vec2 = F.vec.vec_as_array(vec2)
    local x = math.abs(vec1[1] - vec2[1])
    local y = math.abs(vec1[2] - vec2[2])
    return x + y
end

---returns the square distance between `vec1` and `vec2`
---@param vec1 {[1]: number, [2]: number} | {x: number, y: number}
---@param vec2 {[1]: number, [2]: number} | {x: number, y: number}
---@return number
function F.vec.square_dist(vec1, vec2)
    vec1 = F.vec.vec_as_array(vec1)
    vec2 = F.vec.vec_as_array(vec2)
    local x = math.abs(vec1[1] - vec2[1])
    local y = math.abs(vec1[2] - vec2[2])
    return math.max(x, y)
end

---@class hasher: {h: integer, write: function, finish: function}

---@alias hashable string | number | boolean | [hashable] | {[hashable]: hashable}

---Returns a new hasher
---@param seed integer
---@return hasher
function F.hash.new(seed)
    return {
        h = seed,
        write = F.hash.write,
        finish = F.hash.finish
    }
end

---Writes `v` into `hasher`
---@param hasher hasher
---@param v hashable
function F.hash.write(hasher, v)
    if type(v) == "string" then
        for i = 1, #v do
            hasher.h = hasher.h * 32 + v:byte(i)
        end
    elseif type(v) == "number" then
        hasher.h = hasher.h * 32 + v
    elseif type(v) == "boolean" then
        if v then
            hasher.h = hasher.h * 32 + 1
        else
            hasher.h = hasher.h * 32
        end
    elseif type(v) == "table" then
        for _, v in pairs(v) do
            hasher:write(v)
        end
    end
end

---Returns the hashed value in `hasher`
---@param hasher hasher
---@return integer
function F.hash.finish(hasher)
    return hasher.h
end

---@class generator: {X1: number, X2: number, value: function, seed: function, int: function, range: function, float_range: function, shuffle: function, bool: function, vec_int: function, vec_float: function, energy: function, colour: function, energy_source: function, module_slots: function}


local A1, A2 = 727595, 798405  -- 5^17=D20*A1+A2
local D20, D40 = 1048576, 1099511627776  -- 2^20, 2^40

---Returns a new generator with the given seed
---@param seed number
---@return generator
function F.random.new(seed)
    local generator = {
        X1 = 0,
        X2 = 1,
        value = F.random.value,
        seed = F.random.seed,
        int = F.random.int,
        range = F.random.range,
        float_range = F.random.float_range,
        shuffle = F.random.shuffle,
        bool = F.random.bool,
        vec_int = F.random.vec_int,
        vec_float = F.random.vec_float,
        energy = F.random.energy,
        colour = F.random.colour,
        energy_source = F.random.energy_source,
        module_slots = F.random.module_slots
    }
    generator:seed(seed)
    return generator
end

---Returns a new generator seeded from `table` hashed using `seed`
---@param v hashable
---@param seed integer
---@return generator
function F.random.for_v(v, seed)
    local hasher = F.hash.new(seed)
    hasher:write(v)
    local local_seed = hasher:finish()
    return F.random.new(local_seed)
end

---Returns a decimal value between [0, 1]
---@param generator generator
function F.random.value(generator)
    local U = generator.X2*A2
    local V = (generator.X1*A2 + generator.X2*A1) % D20
    V = (V*D20 + U) % D40
    generator.X1 = math.floor(V/D20)
    generator.X2 = V - generator.X1*D20
    return V/D40
end

---Seed the generator
---@param generator generator
---@param seed number
function F.random.seed(generator, seed)
    generator.X1 = (seed * 2 + 11111) % D20
    generator.X2 = (seed * 4 + 1) % D20
    generator:value()
end

---Returns an integer value between [1, max]
---@param generator generator
---@param max number
---@return number
function F.random.int(generator, max)
    return math.floor(generator:value()*max) + 1
end

---Returns an integer value between [min, max]
---@param generator generator
---@param min number
---@param max number
---@return number
function F.random.range(generator, min, max)
    return min + generator:int(max - min + 1) - 1
end

---Returns a float value between [min. max]
---@param generator generator
---@param min number
---@param max number
---@return number
function F.random.float_range(generator, min, max)
    return min + generator:value() * (max - min)
end

---Shuffle a table
---@param generator generator,
---@param tbl table
---@return table
function F.random.shuffle(generator, tbl)
    for i = #tbl, 2, -1 do
        local j = generator:int(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end

---Returns a random boolean
---@param generator generator
---@return boolean
function F.random.bool(generator)
    return ({true, false})[generator:range(1, 2)]
end

---Returns an integer vector in the area between `top_right` and `bottom_left`, excluding any vectors in `excludes`
---@param generator generator
---@param top_right {[1]: number, [2]: number} | {x: number, y: number}
---@param bottom_left {[1]: number, [2]: number} | {x: number, y: number}
---@param excludes [{[1]: number, [2]: number} | {x: number, y: number}]
---@return table
function F.random.vec_int(generator, top_right, bottom_left, excludes)
    excludes = excludes or {}
    local x1 = top_right[1] or top_right.x
    local y1 = top_right[2] or top_right.y
    local x2 = bottom_left[1] or bottom_left.x
    local y2 = bottom_left[2] or bottom_left.y
    local continue = true
    local vec
    while continue do
    continue = false
        vec = {generator:range(x1, x2), generator:range(y1, y2)}
        for _, exclude in pairs(excludes) do
            if vec == F.vec.vec_as_array(exclude) then
                continue = true
                break
            end
        end
    end
    return vec
end

---Returns a float vector in the area between `top_right` and `bottom_left`, excluding any vectors within range of any value in `excludes`.
---
---Distance is calculated by `dist`, which takes 2 vectors and outputs a number, is `euclidean_dist` by default.
---@param generator generator
---@param top_right {[1]: number, [2]: number} | {x: number, y: number}
---@param bottom_left {[1]: number, [2]: number} | {x: number, y: number}
---@param excludes [{pos: {[1]: number, [2]: number}, dist: number} | {pos: {x: number, y: number}, dist: number}]
---@param dist function
---@return table
function F.random.vec_float(generator, top_right, bottom_left, excludes, dist)
    dist = dist or F.vec.euclidean_dist
    excludes = excludes or {}
    local x1 = top_right[1] or top_right.x
    local y1 = top_right[2] or top_right.y
    local x2 = bottom_left[1] or bottom_left.x
    local y2 = bottom_left[2] or bottom_left.y
    local continue = true
    local vec
    while continue do
    continue = false
        vec = {generator:float_range(x1, x2), generator:float_range(y1, y2)}
        for _, exclude in pairs(excludes) do
            if dist(vec, exclude.pos) <= exclude.dist then
                continue = true
                break
            end
        end
    end
    return vec
end

---Returns a random energy between [min, max] watts
---@param generator generator
---@param min number
---@param max number
---@param unit "W" | "J"
---@param suffix ("" | "k" | "M" | "G" | "T" | "P" | "E" | "Z" | "Y" | "R" | "Q")?
---@return string
function F.random.energy(generator, min, max, unit, suffix)
    suffix = suffix or ""
    return generator:range(min, max) .. suffix .. unit
end

---Returns a random colour
---@param generator generator
---@param with_alpha boolean?
---@return data.Color
function F.random.colour(generator, with_alpha)
    local r = generator:float_range(0, 1)
    local g = generator:float_range(0, 1)
    local b = generator:float_range(0, 1)
    local a
    if with_alpha then
        a = generator:float_range(0, 1)
    end
    return {r = r, g = g, b = b, a = a}
end

---Randomizes the energy source of `entity`
---@param generator generator
---@param entity any
---@param types ["electric" | "burner" | "heat" | "fluid" | "void"]
---@param connections [data.PipeConnectionDefinition]
---@param priority data.ElectricUsagePriority
function F.random.energy_source(generator, entity, types, connections, priority)
    priority = priority or "secondary-input"
    local heat_connections = connections or {
        {direction = 0, position = {0, 0}},
        {direction = 4, position = {0, 0}},
        {direction = 8, position = {0, 0}},
        {direction = 12, position = {0, 0}}
    }
    fluid_connections = heat_connections
    for _, connection in pairs(fluid_connections) do
        connection.flow_direction = "input-output"
    end
    source = types[generator:range(1, #types)]
    if source == "electric" then
        entity.energy_source = {
            type = "electric",
            usage_priority = priority,
            buffer_capacity = (generator:range(0, 1000000000) .. "J"),
            drain = (generator:range(0, 100000) .. "W")
        }
    elseif source == "burner" then
        entity.energy_source = {
            type = "burner",
            fuel_inventory_size = generator:range(1, 3),
            burnt_inventory_size = generator:range(1, 3),
            effectivity = generator:float_range(0.1, 5),
            initial_fuel_percent = generator:value()
        }
    elseif source == "heat" then
        entity.energy_source = {
            type = "heat",
            max_temperature = generator:range(20, 1000),
            max_transfer = "5TJ",
            specific_heat = (generator:range(0, 1000000) .. "J"),
            connections = heat_connections
        }
    elseif source == "fluid" then
        entity.energy_source = {
            type = "fluid",
            fluid_box = {
                pipe_connections = fluid_connections,
                volume = generator:float_range(10, 2^10),
                filter = "steam"
            },
            effectivity = generator:float_range(0.1, 5),
            fluid_usage_per_tick = generator:float_range(0.01, 0.5)
        }
    else
        entity.energy_source = {type = "void"}
    end
end

---Randomizes the module slots of `entity`
---@param generator generator
---@param entity any
---@param min integer
---@param max integer
function F.random.module_slots(generator, entity, min, max)
    if entity.allowed_effects and table_size(entity.allowed_effects) > 0 then
        entity.module_slots = generator:range(min, max)
    end
end

return F