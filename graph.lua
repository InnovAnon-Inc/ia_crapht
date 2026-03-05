-- ia_crapht/graph.lua
-- Industrial Graph Analytics: Centrality, Cycles, and Depth.

ia_crapht.metrics = {
    centrality = {}, -- How many recipes depend on this item?
    depth = {},      -- How many steps from raw materials?
    cycles = {},     -- Does this item belong to a circular dependency?
}

function ia_crapht.compute_metrics()
    local log = ia_util.get_logger(minetest.get_current_modname())
    log(ia_util.log_levels.INFO, "Computing industrial graph metrics...")

    -- Initialize metrics
    for name in pairs(minetest.registered_items) do
        ia_crapht.metrics.centrality[name] = 0
        ia_crapht.metrics.depth[name] = 0
    end

    -- 1. Calculate Centrality (Usage Frequency)
    for name, _ in pairs(minetest.registered_items) do
        local recipes = minetest.get_all_craft_recipes(name)
        if recipes then
            for _, recipe in ipairs(recipes) do
                ia_crapht.for_each_ingredient(recipe, function(ing)
                    -- If it's a group, every member gets a centrality bump
                    if ing:sub(1,6) == "group:" then
                        local members = ia_crapht.groups[ing] or {}
                        for _, m in ipairs(members) do
                            ia_crapht.metrics.centrality[m] = ia_crapht.metrics.centrality[m] + 1
                        end
                    else
                        ia_crapht.metrics.centrality[ing] = (ia_crapht.metrics.centrality[ing] or 0) + 1
                    end
                end)
            end
        end
    end

    -- 2. Detect Cycles (Simple DFS approach)
    local function check_cycle(name, visited, stack)
        if stack[name] then return true end
        if visited[name] then return false end

        visited[name] = true
        stack[name] = true

        local recipes = minetest.get_all_craft_recipes(name)
        if recipes and recipes[1] then
            local found = false
            ia_crapht.for_each_ingredient(recipes[1], function(ing)
                -- Resolve group to first member for cycle check
                local target = ing
                if ing:sub(1,6) == "group:" then
                    target = (ia_crapht.groups[ing] or {})[1]
                end
                if target and check_cycle(target, visited, stack) then
                    found = true
                end
            end)
            if found then return true end
        end

        stack[name] = nil
        return false
    end

    for name in pairs(minetest.registered_items) do
        if check_cycle(name, {}, {}) then
            ia_crapht.metrics.cycles[name] = true
        end
    end

    log(ia_util.log_levels.INFO, "Graph metrics computation complete.")
end

-- Hook into the crawler's end phase
-- Note: Ensure this is called AFTER ia_crapht.analyze_world()
