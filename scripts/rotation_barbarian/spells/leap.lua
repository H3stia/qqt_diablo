local my_utility = require("my_utility/my_utility")
local my_target_selector = require("my_utility/my_target_selector")

local menu_elements_leap =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "base_leap_base_main_bool")),
    min_enemies_slider  = slider_int:new(1, 10, 3, get_hash(my_utility.plugin_label .. "base_leap_min_enemies_slider")),
    single_target_checkbox = checkbox:new(false, get_hash(my_utility.plugin_label .. "base_leap_single_target_checkbox")),
}

local function menu()
    if menu_elements_leap.tree_tab:push("Leap") then
        menu_elements_leap.main_boolean:render("Enable Spell", "")
        menu_elements_leap.min_enemies_slider:render("Min Enemies to Hit", "")
        menu_elements_leap.single_target_checkbox:render("Use on Single Target", "")
        menu_elements_leap.tree_tab:pop()
    end
end

local spell_id_leap = 196545

local spell_data_leap = spell_data:new(
    1.5,                        -- radius
    5.0,                        -- range
    1.0,                        -- cast_delay
    0.7,                        -- projectile_speed
    true,                       -- has_collision
    spell_id_leap,              -- spell_id
    spell_geometry.circular,    -- geometry_type
    targeting_type.skillshot    -- targeting_type
)

local next_time_allowed_cast = 0.0

local function logics(target)
    local menu_boolean = menu_elements_leap.main_boolean:get()
    local min_enemies = menu_elements_leap.min_enemies_slider:get()
    local use_on_single_target = menu_elements_leap.single_target_checkbox:get()

    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_id_leap
    )

    if not is_logic_allowed then
        return false
    end

    local player_position = get_player_position()
    local best_point_data = my_target_selector.get_most_hits_circular(player_position, spell_data_leap.range, spell_data_leap.radius)

    -- Check for boss in range
    local target_selector_data = my_target_selector.get_target_selector_data(player_position, my_target_selector.get_target_list(player_position, spell_data_leap.range))
    local boss_in_range = target_selector_data.has_boss

    if boss_in_range then
        local boss_position = target_selector_data.closest_boss:get_position()
        if cast_spell.position(spell_data_leap.spell_id, boss_position,  1) then
            local current_time = get_time_since_inject()
            next_time_allowed_cast = current_time + 0.5
            console.print("Casted Leap on Boss")
            return true
        end
    elseif best_point_data.is_valid and (best_point_data.hits_amount >= min_enemies or (use_on_single_target and best_point_data.hits_amount > 0)) then
        if cast_spell.position( spell_data_leap.spell_id, best_point_data.point, 1) then
            local current_time = get_time_since_inject()
            next_time_allowed_cast = current_time + 0.5
            console.print("Casted Leap")
            return true
        end
    end

    return false
end

return
{
    menu = menu,
    logics = logics,
}