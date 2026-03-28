local randlib = require("randlib")

local DUPLICATE_COUNT = settings.startup["rtw-duplicate-count"].value
local PREREQ_SEED = settings.startup["rtw-prerequisite-seed"].value
local RANDOM_GENERATOR = randlib.random.new(PREREQ_SEED)
local DUPABLE_PREREQUISITE_CHANCE = settings.startup["rtw-prerequisite-chance"].value -- Out of 100

--First we need to count up all the relevant technology names to duplicate.
local original_techs_to_dupe = {} --Dictionary of tech name to a copy of that technology with only allowed duplicate modifiers
local allowed_effect_types = {["unlock-recipe"] = true}

for name, prototype in pairs(data.raw["technology"]) do
    if not prototype.effects or not name then goto continue end
    if prototype.research_trigger then goto continue end

    local prototype_copy = table.deepcopy(prototype)

    local current_effects = {}
    for _, effect in pairs(prototype.effects) do
        if effect.type and allowed_effect_types[effect.type] then
            table.insert(current_effects, effect)
        end
    end

    if #current_effects == 0 then goto continue end

    --We have at least one valid tech effect, so we are making dupes!
    prototype_copy.effects = current_effects

    --Make sure it localises properly.
    if not prototype_copy.localised_name then
        --See if we need to get a weird level thing
        local string_pos1, string_pos2 = string.find(name, "%-%d+$")
        if string_pos1 and string_pos2 and string_pos2 > string_pos1 and string_pos1 > 2 then
            local level = tonumber(string.sub(name, string_pos1 + 1, string_pos2))
            local unleveled_name = string.sub(name, 1, string_pos1 - 1)
            if data.raw["technology"][unleveled_name] then
                prototype_copy.level = level
                prototype_copy.localised_name = {"", {"technology-name." .. unleveled_name}, " ", tostring(level)}
            else --Try standard name
                prototype_copy.localised_name = {"technology-name." .. name}
            end

        else --Standard localised string
            prototype_copy.localised_name = {"technology-name." .. name}
        end

        
    end
    if not prototype_copy.localised_description then
        prototype_copy.localised_description = {"technology-description." .. name}
    end

    original_techs_to_dupe[name] = prototype_copy
    ::continue::
end


--Original tech prototype name goes in. Out comes the name of the nth duplicate
local function make_duplicate_name_i(original_tech_name, dupe_number)
    return original_tech_name .. "-rtw-" .. tostring(dupe_number) .. "-dupe"
end


--Go fix prerequisites before we go duping
local function add_dupes_to_prerequisites(tech_prototype)
    if not tech_prototype or not tech_prototype.prerequisites then return end

    local dupable_prerequisites = {}
    for _, name in pairs(tech_prototype.prerequisites) do
        if original_techs_to_dupe[name] then
            table.insert(dupable_prerequisites, name)
        end
    end

    --Now we go stochastically adding dupes
    for _, entry in pairs(dupable_prerequisites) do
        for i = 1, DUPLICATE_COUNT do
            local rng = randlib.random.value(RANDOM_GENERATOR) * 100        
            --math.random(1, 100)
            if rng < DUPABLE_PREREQUISITE_CHANCE then
                table.insert(tech_prototype.prerequisites,
                    make_duplicate_name_i(entry,i))
            end
        end
    end
end


--Add dupes to all tech prototypes, then the copies
for _, proto in pairs(data.raw["technology"]) do
    add_dupes_to_prerequisites(proto)
end
for _, proto in pairs(original_techs_to_dupe or {}) do
    add_dupes_to_prerequisites(proto)
end


--Go make the duplicate techs
for name, tech in pairs(original_techs_to_dupe) do
    for i = 1, DUPLICATE_COUNT do
        local new_dupe = table.deepcopy(tech)
        new_dupe.name = make_duplicate_name_i(name, i)
        data.extend({new_dupe})
    end
end