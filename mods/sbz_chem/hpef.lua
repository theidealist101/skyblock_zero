-- theese allow_metadata_* functions were taken from the mtg furnace
local function allow_metadata_inventory_put(pos, listname, index, stack, player)
    if listname == "dst" then
        return 0
    end
    return stack:get_count()
end

local function allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
    if to_list == "dst" then return 0 end
    return count
end


sbz_api.register_machine("sbz_chem:high_power_electric_furnace", {
    description = "High Power Electric Furnace",
    tiles = {
        { name = "simple_alloy_furnace.png", animation = { type = "vertical_frames", length = 0.7 } } -- this needs update TODO
    },
    groups = { matter = 1 },
    allow_metadata_inventory_move = allow_metadata_inventory_move,
    allow_metadata_inventory_put = allow_metadata_inventory_put,

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        inv:set_size("src", 1)
        inv:set_size("dst", 1)


        minetest.sound_play("machine_build", {
            to_player = player_name,
            gain = 1.0,
        })
    end,
    on_rightclick = function(pos, node, player, pointed_thing)
        local player_name = player:get_player_name()
        local meta = minetest.get_meta(pos)

        meta:set_string("formspec", [[
formspec_version[7]
size[8.2,9]
style_type[list;spacing=.2;size=.8]
list[context;src;3.5,1;1,1;]
list[context;dst;3.5,3;1,1;]
list[current_player;main;0.2,5;8,4;]
listring[]
    ]])
        minetest.sound_play("machine_open", {
            to_player = player_name,
            gain = 1.0,
        })
    end,

    control_action_raw = true,
    action = function(pos, node, meta, supply, demand)
        local power_needed = 15
        local inv = meta:get_inventory()

        if demand + power_needed > supply then
            meta:set_string("infotext", "Not enough power")
            return power_needed
        else
            meta:set_string("infotext", "Smelting...")
            minetest.sound_play({ name = "simple_alloy_furnace_running", gain = 0.6, pos = pos })

            local src = inv:get_list("src")

            local out, decremented_input = minetest.get_craft_result({
                method = "cooking",
                width = 1,
                items = src,
            })
            if out.item:is_empty() then
                meta:set_string("infotext", "Invalid/no recipe")
                return 0
            end

            if not inv:room_for_item("dst", out.item) then
                meta:set_string("infotext", "Full")
                return 0
            end

            inv:set_stack("src", 1, decremented_input.items[1])
            inv:add_item("dst", out.item)
            return power_needed
        end
    end,
})

minetest.register_craft({
    output = "sbz_chem:simple_alloy_furnace",
    recipe = {
        { "sbz_power:simple_charged_field", "sbz_resources:antimatter_dust",   "sbz_power:simple_charged_field" },
        { "sbz_resources:matter_blob",      "sbz_resources:emittrium_circuit", "sbz_resources:matter_blob" },
        { "sbz_power:simple_charged_field", "sbz_resources:matter_blob",       "sbz_power:simple_charged_field" }
    }
})
