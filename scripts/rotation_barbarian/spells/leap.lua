local my_utility = require("my_utility/my_utility")

local menu_elements_leap =
{
    tree_tab                    = tree_node:new(1),
    main_boolean                = checkbox:new(true, get_hash(my_utility.plugin_label .. "base_leap_base_main_bool")),
    allow_elite_single_target   = checkbox:new(true, get_hash(my_utility.plugin_label .. "allow_elite_single_target_base_leap")),
    min_targets                 = slider_int:new(1, 30, 3, get_hash(my_utility.plugin_label .. "min_number_of_targets_for_cast_base_leap")),

}

local function menu()

    if menu_elements_leap.tree_tab:push("Leap")then
        menu_elements_leap.main_boolean:render("Enable Spell", "")

        if menu_elements_leap.main_boolean:get() then
            menu_elements_leap.allow_elite_single_target:render("Prio Bosses/Elites", "Allow single target hit on elites/bosses")
            menu_elements_leap.min_targets:render("Min Enemies hit", "Minimum targets to cast the spell")
        end

        menu_elements_leap.tree_tab:pop()
    end
end

local spell_id_leap= 196545;

local spell_data_leap = spell_data:new(
    1.5,-- radius
    5.0,-- range
    1.0,-- cast_delay
    0.7,-- projectile_speed
    true,-- has_collision
    spell_id_leap,-- spell_id
    spell_geometry.circular,-- geometry_type
    targeting_type.skillshot--targeting_type
)
local next_time_allowed_cast = 0.0;
local function logics(target)

    local menu_boolean = menu_elements_leap.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
                menu_boolean,
                next_time_allowed_cast,
                spell_id_leap);

    if not is_logic_allowed then
        return false;
    end;

    local player_position = get_player_position()
    local target_position = target:get_position()
    local cursor_position = get_cursor_position();

    local distance_sqr = player_position:squared_dist_to_ignore_z(target_position)

    if distance_sqr > (spell_data_leap.range * spell_data_leap.range) then
        return false
    end

    local area_data = target_selector.get_most_hits_target_circular_area_heavy(player_position, spell_data_leap.range, spell_data_leap.radius)
    local best_target = area_data.main_target;
    local units = area_data.n_hits

    if not best_target then
        return;
    end

    if units < menu_elements_leap.min_targets:get() then
        return false;
    end;

    local best_target_position = best_target:get_position();
    local best_cast_data = my_utility.get_best_point(best_target_position, spell_data_leap.radius, area_data.victim_list)

    local best_hit_list = best_cast_data.victim_list

    local is_single_target_allowed = false;
    if menu_elements_leap.allow_elite_single_target:get() then
        for _, unit in ipairs(best_hit_list) do
            --local current_health_percentage = unit:get_current_health() / unit:get_max_health()
            if unit:is_boss() then -- and current_health_percentage > 0.15
                is_single_target_allowed = true
                break
            end

            if unit:is_elite() then -- and current_health_percentage > 0.35
                is_single_target_allowed = true
                break
            end
        end
    end

    local best_cast_hits = best_cast_data.hits;
    if best_cast_hits < menu_elements_leap.min_targets:get() and not is_single_target_allowed then
        return false
    end

    local best_cast_position = best_cast_data.point;

    if not is_auto_play_active then
        -- angle check
        local angle = best_cast_position:get_angle(cursor_position, player_position)
        if angle > 100.0 then
            return false
        end
    end

    if cast_spell.position(spell_id_leap, best_cast_position, 1) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + 0.5;

        console.print("Casted Leap");
        return true;
    end;

    return false;
end


return 
{
    menu = menu,
    logics = logics,   
}