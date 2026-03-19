-- ia_factory/crafter.lua

local S = technic.getter
local modname = core.get_current_modname()

-- Texture Overlays
local tube_entry = "^pipeworks_tube_connection_metallic.png"
local cable_entry = "^technic_cable_connection_overlay.png"

-- Configuration
local autocraft_demand = 2500
local eject_dir = vector.new(0, 1, 0)

-- Helper: Update machine UI
local function set_autocrafter_formspec(meta)
    local formspec = "size[8,9]"..
        "label[0,0;HV Smart Autocrafter]"..
        "label[0,0.6;Target Product]"..
        "list[context;target;0,1;1,1;]"..
        "label[2,0.6;Ingredient Buffer]"..
        "list[context;buffer;2,1;6,3;]"..
        "list[current_player;main;0,5;8,4;]"..
        "listring[context;buffer]"..
        "listring[current_player;main]"

    local status_btn = meta:get_int("enabled") == 1 and "disable;Enabled" or "enable;Disabled"
    formspec = formspec .. "button[0,2.5;1.5,1;" .. status_btn .. "]"
    
    meta:set_string("formspec", formspec)
end

-- Power Management Logic
local function check_autocrafter_power(meta)
    local enabled = (meta:get_int("enabled") == 1)
    local eu_input = meta:get_int("HV_EU_input")
    local has_power = (eu_input >= autocraft_demand)

    if not enabled then
        meta:set_string("infotext", "Autocrafter Disabled")
        meta:set_int("HV_EU_demand", 0)
        return false
    end
    if not has_power then
        meta:set_string("infotext", "Autocrafter Unpowered (Demand: " .. autocraft_demand .. ")")
        meta:set_int("HV_EU_demand", autocraft_demand)
        return false
    end

    meta:set_string("infotext", "Autocrafter Active (" .. eu_input .. " EU)")
    meta:set_int("HV_EU_demand", autocraft_demand)
    return true
end

-- Main Processing Logic
local function autocrafter_run(pos, node)
    local meta = core.get_meta(pos)
    local inv = meta:get_inventory()
    
    if not check_autocrafter_power(meta) then return end

    local target_stack = inv:get_stack("target", 1)
    if target_stack:is_empty() then return end
    
    local item_name = target_stack:get_name()

    -- ASSUMPTION: The following API methods will be implemented in the next stage
    -- 1. ia_crapht.get_primary_recipe(item_name) -> Returns a standard Minetest recipe table
    -- 2. ia_crapht.has_ingredients(inv, "buffer", recipe) -> Boolean check
    -- 3. ia_crapht.consume_ingredients(inv, "buffer", recipe) -> Removes items from buffer
    
    local recipe = ia_crapht.get_primary_recipe(item_name)
    if not recipe then
        meta:set_string("infotext", "Error: No recipe found for " .. item_name)
        return
    end

    if ia_crapht.has_ingredients(inv, "buffer", recipe) then
        -- Perform the craft
        ia_crapht.consume_ingredients(inv, "buffer", recipe)
        
        -- Generate the output stack
        local output_stack = ItemStack(recipe.output)
        
        -- Eject completed item via Pipeworks
        technic.tube_inject_item(pos, pos, eject_dir, output_stack:to_table())
        
        -- Add logging for tracking
        -- [cite: 2026-02-28] Use logging for better information before logic modification.
        minetest.log("action", "[ia_factory] Autocrafter at " .. minetest.pos_to_string(pos) .. 
                     " produced " .. output_stack:get_name())
    else
        meta:set_string("infotext", "Status: Waiting for ingredients...")
    end
end

core.register_node(modname..":autocrafter_hv", {
    description = "HV Smart Autocrafter",
    tiles = {
        "technic_carbon_steel_block.png" .. tube_entry,
        "technic_carbon_steel_block.png" .. cable_entry,
        "technic_carbon_steel_block.png" .. cable_entry,
        "technic_carbon_steel_block.png" .. cable_entry,
        "technic_carbon_steel_block.png^gui_furnace_arrow_bg.png",
        "technic_carbon_steel_block.png" .. cable_entry,
    },
    groups = {cracky=2, tubedevice=1, technic_machine=1, technic_hv=1},
    paramtype2 = "facedir",
    connect_sides = {"top", "bottom", "left", "right", "back"},

    tube = {
        connect_sides = {top = 1, left = 1, right = 1, back = 1},
        priority = 15,
        can_go = function(pos, node, velocity, stack)
            return { eject_dir }
        end
    },

    on_construct = function(pos)
        local meta = core.get_meta(pos)
        local inv = meta:get_inventory()
        inv:set_size("target", 1)
        inv:set_size("buffer", 18)
        meta:set_int("enabled", 0)
        meta:set_int("HV_EU_demand", 0)
        set_autocrafter_formspec(meta)
    end,

    after_place_node = function(pos, placer, itemstack)
        pipeworks.scan_for_tube_objects(pos)
    end,

    after_dig_node = pipeworks.scan_for_tube_objects,

    on_receive_fields = function(pos, formname, fields, sender)
        local meta = core.get_meta(pos)
        if fields.enable then meta:set_int("enabled", 1) end
        if fields.disable then meta:set_int("enabled", 0) end
        set_autocrafter_formspec(meta)
    end,

    technic_run = autocrafter_run,
})

technic.register_machine("HV", modname..":autocrafter_hv", technic.receiver)
