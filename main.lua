local VHP = SMODS.current_mod
local FULL_HOUSE_PATTERN = {
        {rank = {"a", 0}},
        {rank = {"a", 0}},
        {rank = {"a", 0}},
        {rank = {"b", 0}},
        {rank = {"b", 0}},
}
local SAME_SUIT_PATTERN = {
        {suit = {"a", false}},
        {suit = {"a", false}},
}
local FIND_KICKER_PATTERN = {
        {rank = {"a", 0}, unscoring = true},
        {rank = {"a", 0}, unscoring = true},
        {rank = {"b", 0}, unscoring = true},
        {rank = {"b", 0}, unscoring = true},
        {rank = {"c", 0}},
}
local TROLLEY_FIND_ONE = {
        {suit = {"a", false}, special = "face", unscoring = true},
        {suit = {"a", false}, special = "face", unscoring = true},
        {suit = {"a", false}, special = "face", unscoring = true},
        {suit = {"b", false}, special = "face"},
}
local TROLLEY_FIND_THREE = {
        {suit = {"a", false}, special = "face"},
        {suit = {"a", false}, special = "face"},
        {suit = {"a", false}, special = "face"},
        {suit = {"b", false}, special = "face", unscoring = true},
}
local RANK_CARD_KEY_MAP = {[10] = "T", [11] = "J", [12] = "Q", [13] = "K", [14] = "A"}
local SUIT_CARD_KEY_MAP = {Spades = "S", Hearts = "H", Clubs = "C", Diamonds = "D"}
local CUSTOM_JOKERS_ATLAS_MAP = {
    "custom_jokers_low_card.png",
    "custom_jokers_nothing.png",
    "custom_jokers_bumblebee_straight.png",
    "custom_jokers_parable.png",
    "custom_jokers_royal_sampler.png", -- 5
    "custom_jokers_aaaaa.png",
    "custom_jokers_last_ditch.png",
    "custom_jokers_namuko.png",
    "custom_jokers_ak47.png",
    "custom_jokers_2048.png", -- 10
    "custom_jokers_polygamy.png",
    "custom_jokers_incognito.png",
}
local CUSTOM_PLANETS_ATLAS_MAP = {
    "custom_planet_garn47.png",
    "custom_planet_sigma_n.png",
    "custom_planet_omicron.png",
    "custom_planet_lemon.png",
    "custom_planet_nomis.png", -- 5
    "custom_planet_namuko.png",
    "custom_planet_7column.png",
    "custom_planet_uno.png",
    "custom_planet_2048.png",
    "custom_planet_aaaaa.png", -- 10
    "custom_planet_jewel.png",
    "custom_planet_polygamy.png",
    "custom_planet_all_in.png",
    "custom_planet_am_special.png",
    "custom_planet_cioiith.png", -- 15
    "custom_planet_highest_card.png",
    "custom_planet_joke.png",
    "custom_planet_long_pi.png",
    "custom_planet_incognito.png",
}

local json = assert(SMODS.load_file('json.lua'))()
local hands_json = assert(SMODS.load_file('parsed_hands.lua'))()
local poker_hands = json.decode(hands_json)
local nostalgic_hand_ids = {}
local nostalgic_ranks_hand_set = {}
local nostalgic_resetter_hand_ids_set = {}
local rng_hand_ids = {}
local dejavu_hand_ids = {}
local ceasar_ids_values = {}
local money_ease_hand_map = {}
local probability_mod_hand_map = {}
local banana_scoring_hand_set = {}
local special_mult_hand_map = {}
local special_xmult_hand_map = {}
local enhance_kicker_hand_set = {}
local special_joker_hand_set = {}
local gene_dupes_hand_set = {}
local create_joker_hand_map = {}
local hand_size_mod_hand_map = {}
local special_wild_hand_map = {}
local draw_extra_hand_map = {}
local ritual_hand_set = {}
local disable_boss_blind_hand_set = {}
local change_blind_req_hand_map = {}
local ritual_type_hand_map = {}
local special_perma_bonus_hand_map = {}
local special_perma_mult_hand_map = {}
local add_first_card_seal_hand_map = {}
local draw_before_scoring_hand_set = {}
local special_horsemen_xmult_hand_map = {}
local create_consumable_hand_map = {}
local special_destroy_hand_set = {}
local special_chips_hand_map = {}
local special_copy_hand_map = {}
local enhance_faces_held_in_hand_hand_set = {}
local debuff_faces_held_in_hand_hand_set = {}
local special_chance_hand_map = {}
local trolley_debuff_hand_set = {}
local game_speed_hand_map = {}
local open_url_hand_map = {}
local super_ritual_type_hand_map = {}
local spicy_hands_set = {}
local keyed_hand_set = {}
local special_balance_hand_set = {}
local special_swap_hand_set = {}
local special_maximize_hand_set = {}
local omni_mult_hand_map = {}
local omni_chips_hand_map = {}
local hand_ease_hand_map = {}
local no_wee_hand_set = {}
local perma_all_cards_rank_count_as_hand_map = {}
local nonspecial_convert_hand_map = {}
local nonspecial_remove_mods_hand_set = {}
local base_emult_hand_map = {}
local tsunami_dupe_hand_map = {}
local cigarette_chance_hand_map = {}
local level_up_multi_hand_map = {}

local loc_debuff_text_replacement = nil


local function talis_num(x)
    if to_big then
        return to_big(x)
    end
    return x
end


-- WARNING: Only works with positive rotation
local function ceasar_rotation(rank_id, rotation)
    local result = rank_id + rotation
    if result > 14 then
        result = result - 13
    end
    return result
end


SMODS.Atlas{
	key = "modicon",
	path = "modicon.png",
	px = 34,
	py = 34,
}
for key, value in pairs(CUSTOM_JOKERS_ATLAS_MAP) do
    SMODS.Atlas{
        key = "custom_jokers" .. tostring(key),
        path = value,
        px = 71,
        py = 95,
    }
end
for key, value in pairs(CUSTOM_PLANETS_ATLAS_MAP) do
    SMODS.Atlas{
        key = "custom_planet" .. tostring(key),
        path = value,
        px = 71,
        py = 95,
    }
end


local current_extra_print = nil
local function time_and_return(func, ...)
    local start_time = love.timer.getTime()
    local ret = func(...)
    local end_time = love.timer.getTime()
    if 1000*(end_time-start_time) > 0 then
        if current_extra_print then
            print(current_extra_print)
        end
        print(1000*(end_time-start_time))
    end
    return ret
end


local function to_timing(func, extra_print)
    return function (...)
        current_extra_print = extra_print
        return time_and_return(func, ...)
    end
end


local function cartesian_product(L, N)
    local function sub_product(current, depth)
        if depth == 0 then
            return {current}
        end

        local result = {}
        for _, item in ipairs(L) do
            local new_current = copy_table(current)--{table.unpack(current)}
            table.insert(new_current, item)
            local sub_result = sub_product(new_current, depth - 1)
            for _, sub in ipairs(sub_result) do
                table.insert(result, sub)
            end
        end
        return result
    end

    return sub_product({}, N)
end


local function permutation_something(list, n)
    local results = {}
    
    local function helper(current, remaining)
        if #current == n then
            table.insert(results, copy_table(current))
            return
        end
        for i = 1, #remaining do
            local new_current = copy_table(current)
            table.insert(new_current, remaining[i])
            
            local new_remaining = copy_table(remaining)
            table.remove(new_remaining, i)
            
            helper(new_current, new_remaining)
        end
    end
    
    helper({}, list)
    return results
end


-- Only works for numbers in range [1, 16]
local function to_binary(n)
    local bin = {}
    while n > 0 do
        table.insert(bin, 1, n % 2)
        n = math.floor(n / 2)
    end
    while #bin < 4 do
        table.insert(bin, 1, 0)
    end
    return bin
end


-- Only works for numbers in range [1, 16]
local function from_binary(bin)
    local num = 0
    local power = 1
    for i = #bin, 1, -1 do
        num = num + bin[i] * power
        power = power * 2
    end
    return num
end


local function bitwise_and(a, b)
    local bin_a = to_binary(a)
    local bin_b = to_binary(b)
    local bin_result = {}

    for i = 1, #bin_a do
        table.insert(bin_result, (bin_a[i] == 1 and bin_b[i] == 1) and 1 or 0)
    end

    return from_binary(bin_result)
end


local function bitwise_nor(a, b)
    local bin_a = to_binary(a)
    local bin_b = to_binary(b)
    local bin_result = {}

    for i = 1, #bin_a do
        local or_result = (bin_a[i] == 1 or bin_b[i] == 1) and 1 or 0
        table.insert(bin_result, 1 - or_result)
    end

    return from_binary(bin_result)
end


-- Implementation of hyperoperation a{n}b for small positive non-zero numbers
-- https://github.com/qntm/hyperoperate/blob/main/src/index.js
local function hyperoperator_small(n, a, b)
    local INVALID_RESULT = -1000000000000
    if n <= 0 or a <= 0 or b <= 0 then
        return INVALID_RESULT
    end
    
    if n == 1 then
        return a + b
    elseif n == 2 then
        return a * b
    elseif n == 3 then
        return a ^ b
    end

    if a == 1 then
        return 1
    end

    if b == 1 then
        return a
    end

    if a == 2 and b == 2 then
        return 4
    end

    if n < 6 then
        local result = a
        for i = 1, b - 1, 1 do
            result = hyperoperator_small(n - 1, a, result)
            if result > 1e100 then
                return INVALID_RESULT
            end
        end
    end

    return INVALID_RESULT
end


local function calculate_mode(numbers)
    local frequency = {}
    local max_count = 0
    local modes = {}
    
    -- Count occurrences of each number
    for _, num in ipairs(numbers) do
        frequency[num] = (frequency[num] or 0) + 1
        if frequency[num] > max_count then
            max_count = frequency[num]
        end
    end
    
    -- Find all numbers that appear with max frequency
    for num, count in pairs(frequency) do
        if count == max_count then
            table.insert(modes, num)
        end
    end
    
    return modes
end


local function reset_key_hand()
    G.GAME.vhp_key_hand = {}
    for i = 1, 5, 1 do
        local chosen_enhancement = pseudorandom_element({
            "m_bonus",
            "m_mult",
            "m_wild",
            "m_glass",
            "m_steel",
            "m_stone",
            "m_gold",
            "m_lucky",
            "m_vhp_special",
        }, pseudoseed("vhp_keyed"))
        table.insert(G.GAME.vhp_key_hand, chosen_enhancement)
    end
end


local function match_special(card, special, whole_hand_for_scoring)
    if special == "debuffed" then
        return card.debuff
    elseif special == "editioned" then
        return card.edition ~= nil
    elseif special == "nondebuffed" then
        return not card.debuff
    elseif special == "dark" then
        return card._vhp_cache.is_suit.Spades or card._vhp_cache.is_suit.Clubs
    elseif special == "light" then
        return card._vhp_cache.is_suit.Hearts or card._vhp_cache.is_suit.Diamonds
    elseif special == "gold" then
        return card.config.center_key == "m_gold"
    elseif special == "special" then
        return card.config.center_key == "m_vhp_special"
    elseif special == "nonspecial" then
        return card.config.center_key ~= "m_vhp_special"
    elseif special == "lucky" then
        return card.config.center_key == "m_lucky"
    elseif special == "bonus" then
        return card.config.center_key == "m_bonus"
    elseif special == "mult" then
        return card.config.center_key == "m_mult"
    elseif special == "steel" then
        return card.config.center_key == "m_steel"
    elseif special == "glass" then
        return card.config.center_key == "m_glass"
    elseif special == "negative" then
        return card.edition and card.edition.negative
    elseif special == "nonface" then
        return not (card._vhp_cache.get_id == 11 or card._vhp_cache.get_id == 12 or card._vhp_cache.get_id == 13 or (next(find_joker("Pareidolia")) or false))
    elseif special == "face" then
        return card._vhp_cache.get_id == 11 or card._vhp_cache.get_id == 12 or card._vhp_cache.get_id == 13 or (next(find_joker("Pareidolia")) or false)
    elseif special == "midranked" then
        if not whole_hand_for_scoring then
            return true
        end
        -- Too lazy to make a loop
        -- What procedural programming does to a man
        local ranks_list = {
                whole_hand_for_scoring[1]._vhp_cache.get_id,
                whole_hand_for_scoring[2]._vhp_cache.get_id,
                whole_hand_for_scoring[3]._vhp_cache.get_id,
        }
        table.sort(ranks_list)
        return ranks_list[2] == card._vhp_cache.get_id
    else
        error("Unknown special effect: " .. tostring(special))
    end
end


-- How the patterns work
-- [1] = pattern_valid = function(pattern) -> boolean
-- [2] = card_valid = function(card, pattern) -> boolean
local pattern_funcs = {
    -- {stone}
    {
        function (p) return p.stone end,
        function (card, p) return card.config.center_key == 'm_stone' end,
    },
    -- {rank, suit, special}
    {
        function (p) return p.rank and p.suit and p.special end,
        function (card, p) return card._vhp_cache.get_id == p.rank and card._vhp_cache.is_suit[p.suit] and match_special(card, p.special) end,
    },
    -- {rank, "Wilds"}
    {
        function (p) return p.rank and p.suit == "Wilds" and (not p.special) end,
        function (card, p) return card._vhp_cache.get_id == p.rank and card.config.center_key == 'm_wild' end,
    },
    -- {rank, suit} with a standard suit
    {
        function (p) return p.rank and p.suit and (not p.special) end,
        function (card, p) return card._vhp_cache.get_id == p.rank and card._vhp_cache.is_suit[p.suit] and card.config.center_key ~= 'm_wild' end,
    },
    -- {rank, suit} with a wild suit
    {
        function (p) return p.rank and p.suit and (not p.special) end,
        function (card, p) return card._vhp_cache.get_id == p.rank and card._vhp_cache.is_suit[p.suit] end,
    },
    -- {"Wilds"}
    {
        function (p) return p.suit == "Wilds" and (not p.rank) and (not p.special) end,
        function (card, p) return card.config.center_key == 'm_wild' end,
    },
    -- {rank, special}
    {
        function (p) return p.rank and p.special and (not p.suit) end,
        function (card, p) return card._vhp_cache.get_id == p.rank and match_special(card, p.special) end,
    },
    -- {suit, special}
    {
        function (p) return p.suit and p.special and (not p.rank) end,
        function (card, p) return card._vhp_cache.is_suit[p.suit] and match_special(card, p.special) end,
    },
    -- {rank}/{suit} with a standard suit
    {
        function (p) return p.suit and (not p.rank) and (not p.special) end,
        function (card, p) return card._vhp_cache.is_suit[p.suit] and card.config.center_key ~= 'm_wild' end,
    },
    {
        function (p) return p.rank and (not p.suit) and (not p.special) end,
        function (card, p) return card._vhp_cache.get_id == p.rank and card.config.center_key ~= 'm_wild' end,
    },
    -- {rank}/{suit} with a wild card
    {
        function (p) return p.suit and (not p.rank) and (not p.special) end,
        function (card, p) return card._vhp_cache.is_suit[p.suit] end,
    },
    {
        function (p) return p.rank and (not p.suit) and (not p.special) end,
        function (card, p) return card._vhp_cache.get_id == p.rank end,
    },
    -- {special}
    {
        function (p) return p.special and (not p.rank) and (not p.suit) and (not p.stone) end,
        function (card, p) return match_special(card, p.special) end,
    },
    -- {} always true
    {
        function (p) return (not p.rank) and (not p.suit) and (not p.stone) and (not p.special) end,
        function (card, p) return true end,
    },
}
-- List of {rank = number?, suit = string?, stone = true|nil, unscoring = true|nil, times = number?, special = any?}
local function match_simple(hand, pattern, debug_this)
    -- How the patterns work
    -- [1] = pattern_valid = function(pattern) -> boolean
    -- [2] = card_valid = function(card, pattern) -> boolean

    -- Does the pattern match
    local card_indices_used_set = {}
    local pattern_indices_done_set = {}
    for _, func_tuple in pairs(pattern_funcs) do
        for p_key, p_value in pairs(pattern) do
            if (not pattern_indices_done_set[p_key]) and func_tuple[1](p_value) then
                for h_key, h_value in pairs(hand) do
                    if (not card_indices_used_set[h_key]) and func_tuple[2](h_value, p_value) then
                        pattern_indices_done_set[p_key] = true
                        card_indices_used_set[h_key] = true
                        break
                    end
                end
            end
        end
    end
    local count = 0
    for _, __ in pairs(pattern_indices_done_set) do
        count = count + 1
    end
    if count ~= #pattern then
        return
    end
    -- Match found, search scoring cards
    local scoring_cards = {}
    for h_key, h_value in pairs(hand) do
        local is_scoring = false
        local max_times = 1
        for p_key, p_value in pairs(pattern) do
            if not p_value.unscoring then
                local suit_okay = false
                if not p_value.suit then
                    suit_okay = true
                else
                    -- Works with wild cards
                    -- Since they are every suit (even if it doesn't exist)
                    suit_okay = h_value:is_suit(p_value.suit, nil, true)
                end
                local rank_okay = false
                if not p_value.rank then
                    rank_okay = true
                else
                    rank_okay = h_value:get_id() == p_value.rank
                end
                local special_ok = false
                if not p_value.special then
                    special_ok = true
                else
                    special_ok = match_special(h_value, p_value.special, hand)
                end
                if p_value.stone then
                    is_scoring = is_scoring or SMODS.has_enhancement(h_value, "m_stone")
                else
                    is_scoring = is_scoring or (suit_okay and rank_okay and special_ok)
                end
                if suit_okay and rank_okay and special_ok then
                    local p_times = p_value.times or 1
                    if p_times > max_times then
                        max_times = p_times
                    end
                end
            end
        end
        if is_scoring then
            for i = 1, max_times, 1 do
                table.insert(scoring_cards, h_value)
            end
        end
    end
    return scoring_cards
end


local function eval_pattern(hand, pattern, options, debug_this)
    local has_pareidolia = next(find_joker("Pareidolia")) or false

    local rank_vars_set = {}
    local suit_vars_set = {}
    for key, value in pairs(pattern) do
        if value.rank and type(value.rank) == "table" and value.rank[1] then
            rank_vars_set[value.rank[1]] = true
        end
        if value.suit and value.suit[2] == false then
            suit_vars_set[value.suit[1]] = true
        end
    end
    local rank_vars = {}
    local suit_vars = {}
    for key, value in pairs(rank_vars_set) do
        table.insert(rank_vars, key)
    end
    for key, value in pairs(suit_vars_set) do
        table.insert(suit_vars, key)
    end

    local possible_ranks_set = {}
    local possible_suits_set = {}
    for key, value in pairs(hand) do
        possible_ranks_set[value._vhp_cache.get_id] = true
        for _, suit in pairs({"Spades", "Hearts", "Clubs", "Diamonds"}) do
            --                                                     Makes sure it doesn't become false
            possible_suits_set[suit] = possible_suits_set[suit] or value._vhp_cache.is_suit[suit] or nil
        end
    end
    local possible_ranks = {}
    local possible_suits = {}
    for key, value in pairs(possible_ranks_set) do
        table.insert(possible_ranks, key)
    end
    for key, value in pairs(possible_suits_set) do
        table.insert(possible_suits, key)
    end

    local nonunique_var_set = {}
    local are_all_distinct = true
    for var, option_list in pairs(options) do
        for _, value in pairs(option_list) do
            if value == "_nonunique" then
                nonunique_var_set[var] = true
                are_all_distinct = false
                break
            end
        end
    end

    local rank_combinations
    local suit_combinations
    if are_all_distinct then
        rank_combinations = permutation_something(possible_ranks, #rank_vars)
        suit_combinations = permutation_something(possible_suits, #suit_vars)
    else
        rank_combinations = cartesian_product(possible_ranks, #rank_vars)
        suit_combinations = cartesian_product(possible_suits, #suit_vars)
    end

    for rank_key, rank_combination in pairs(rank_combinations) do
        for suit_key, suit_combination in pairs(suit_combinations) do
            local current_rank_map = {}
            for key, value in pairs(rank_combination) do
                current_rank_map[rank_vars[key]] = value
            end
            local current_suit_map = {}
            for key, value in pairs(suit_combination) do
                current_suit_map[suit_vars[key]] = value
            end

            local vars_ok = true

            if not are_all_distinct then
                local should_be_unique_set = {}
                for key, value in pairs(current_rank_map) do
                    if not nonunique_var_set[key] then
                        if should_be_unique_set[value] then
                            vars_ok = false
                            break
                        end
                        should_be_unique_set[value] = true
                    end
                end
                for key, value in pairs(current_suit_map) do
                    if not nonunique_var_set[key] then
                        if should_be_unique_set[value] then
                            vars_ok = false
                            break
                        end
                        should_be_unique_set[value] = true
                    end
                end
            end

            for key, value in pairs(current_rank_map) do
                if options[key] then
                    local this_var_ok = false
                    local is_face = value == 11 or value == 12 or value == 13 or has_pareidolia
                    for _, possible_value in pairs(options[key]) do
                        if value == possible_value then
                            this_var_ok = true
                        end
                        if possible_value == "_face" and is_face then
                            this_var_ok = true
                        end
                        if possible_value == "_nonface" and not is_face then
                            this_var_ok = true
                        end
                    end
                    if #options[key] == 1 and nonunique_var_set[key] then
                        -- Option list is only {"_nonunique"}
                        this_var_ok = true
                    end
                    for _, possible_value in pairs(options[key]) do
                        if type(possible_value) == "table" and possible_value["not"] then
                            local negation = possible_value["not"]
                            if value == negation then
                                this_var_ok = false
                            end
                        end
                    end
                    if not this_var_ok then
                        vars_ok = false
                        break
                    end
                end
            end

            for key, value in pairs(current_suit_map) do
                if options[key] then
                    local this_var_ok = false
                    for _, possible_value in pairs(options[key]) do
                        if value == possible_value then
                            this_var_ok = true
                        end
                    end
                    if #options[key] == 1 and nonunique_var_set[key] then
                        -- Option list is only {"_nonunique"}
                        this_var_ok = true
                    end
                    if not this_var_ok then
                        vars_ok = false
                        break
                    end
                end
            end

            if vars_ok then
                local simple_pattern = {}
                for key, value in pairs(pattern) do
                    local pattern_slot = {}
                    if value.stone then
                        pattern_slot.stone = true
                    end
                    if value.rank then
                        if type(value.rank) == "number" then
                            pattern_slot.rank = value.rank
                        else
                            local rank_value = current_rank_map[value.rank[1]]
                            if rank_value == 14 and value.rank[2] ~= 0 then
                                rank_value = 1 -- Ace as low of a straight
                            end
                            rank_value = rank_value + value.rank[2]
                            pattern_slot.rank = rank_value
                        end
                    end
                    if value.suit then
                        if value.suit[2] then
                            pattern_slot.suit = value.suit[1]
                        else
                            pattern_slot.suit = current_suit_map[value.suit[1]]
                        end
                    end
                    pattern_slot.unscoring = value.unscoring
                    pattern_slot.times = value.times
                    pattern_slot.special = value.special
                    table.insert(simple_pattern, pattern_slot)
                end
                local ret = match_simple(hand, simple_pattern, debug_this)
                if ret then
                    return ret
                end
            end
        end
    end
end


-- List of {rank = number?, suit = string?, stone = true|nil, unscoring = true|nil}
local function create_example_hand(pattern, full_stats)
    if not pattern then
        return {}
    end
    local ret_hand = {}
    for key, value in pairs(pattern) do
        local suit_key = SUIT_CARD_KEY_MAP[value.suit] or ""
        if value.stone then
            table.insert(ret_hand, {"S_A", not value.unscoring, "m_stone"})
        elseif value.suit == "Wilds" then
            table.insert(ret_hand, {"H_" .. (RANK_CARD_KEY_MAP[value.rank] or value.rank), not value.unscoring, "m_wild"})
        elseif full_stats.different_enhancement then
            table.insert(ret_hand, {
                    suit_key .. "_" .. (RANK_CARD_KEY_MAP[value.rank] or value.rank),
                    not value.unscoring,
                    ({"m_mult", "m_bonus", "m_lucky", "m_glass", "m_steel"})[key]
            })
        elseif full_stats.any_enhancement then
            table.insert(ret_hand, {
                    suit_key .. "_" .. (RANK_CARD_KEY_MAP[value.rank] or value.rank),
                    not value.unscoring,
                    ({"m_mult", "m_bonus", "m_bonus", "m_mult", "m_steel"})[key]
            })
        elseif full_stats.same_enhancement then
            table.insert(ret_hand, {
                    suit_key .. "_" .. (RANK_CARD_KEY_MAP[value.rank] or value.rank),
                    not value.unscoring,
                    "m_lucky"
            })
        else
            table.insert(ret_hand, {
                    suit_key .. "_" .. (RANK_CARD_KEY_MAP[value.rank] or value.rank),
                    not value.unscoring,
                    (full_stats.all_enhanced and ("m_" .. full_stats.all_enhanced)) or (value.special == "special" and "m_vhp_special" or (value.special == "mult" and "m_mult" or nil))
            })
        end
    end
    return ret_hand
end


local play_cards_ref = G.FUNCS.play_cards_from_highlighted
G.FUNCS.play_cards_from_highlighted = function(e)
    for _, card in pairs(G.hand.highlighted) do
        if card.facing == "back" then
            card._vhp_was_face_down = true
        end
    end

    local ret = play_cards_ref(e)

    return ret
end


local eval_play_ref = G.FUNCS.evaluate_play
G.FUNCS.evaluate_play = function (e)
    if G.GAME.vhp_consecutive_unique_set == nil then
        G.GAME.vhp_consecutive_unique_set = {}
    end

    if G.GAME.vhp_same_hand_combo == nil then
        G.GAME.vhp_same_hand_combo = {
            hand = "an_hand_that_does_not_exist",
            combo = 0,
        }
    end
    if G.GAME.vhp_hands_banned_for_spicy_set == nil then
        G.GAME.vhp_hands_banned_for_spicy_set = {}
    end

    local nostalgic_hand = nil
    if (not G.GAME.vhp_nostalgia_hand) and #G.play.cards == 5 then
        local nostalgic_example = {}
        local nostalgic_ranks_example = {}
        nostalgic_hand = {}
        for _, card in pairs(G.play.cards) do
            table.insert(nostalgic_hand, {
                rank = card.base.id,
                suit = {card.base.suit, true}
            })
            table.insert(nostalgic_example, {
                rank = card.base.id,
                suit = card.base.suit
            })
            table.insert(nostalgic_ranks_example, {
                rank = card.base.id,
                suit = pseudorandom_element({"Spades", "Hearts", "Clubs", "Diamonds"}, pseudoseed("vhp_nostalgia_ranks"))
            })
        end
        for _, id in pairs(nostalgic_hand_ids) do
            G.GAME.hands[id].example = create_example_hand(nostalgic_example, {})
        end
        for key, _ in pairs(nostalgic_ranks_hand_set) do
            G.GAME.hands[key].example = create_example_hand(nostalgic_ranks_example, {})
        end
    end
    local dejavu_hand = copy_table(G.GAME.vhp_dejavu_hand)
    if G.GAME.vhp_dejavu_hand and #G.play.cards > 0 then
        local first_card = G.play.cards[1]
        table.insert(dejavu_hand, 1, (first_card.config.center_key == "m_stone") and {stone = true} or {
            rank = first_card.base.id,
            suit = {first_card.base.suit, true}
        })
        dejavu_hand[6] = nil
        table.insert(G.GAME.vhp_dejavu_example, 1, (first_card.config.center_key == "m_stone") and {stone = true} or {
            rank = first_card.base.id,
            suit = first_card.base.suit
        })
        G.GAME.vhp_dejavu_example[6] = nil
        for _, id in pairs(dejavu_hand_ids) do
            G.GAME.hands[id].example = create_example_hand(G.GAME.vhp_dejavu_example, {})
        end
    end
    local ceasar_hand = nil
    if #G.play.cards == 5 then
        local ceasar_example = {}
        ceasar_hand = {}
        for _, card in pairs(G.play.cards) do
            table.insert(ceasar_hand, {
                rank = card.base.id,
                suit = {card.base.suit, true}
            })
            table.insert(ceasar_example, {
                rank = card.base.id,
                suit = card.base.suit
            })
        end
        for id, rotation in pairs(ceasar_ids_values) do
            local this_ceasar = copy_table(ceasar_example)
            for index, _ in pairs(this_ceasar) do
                this_ceasar[index].rank = ceasar_rotation(this_ceasar[index].rank, rotation)
            end
            G.GAME.hands[id].example = create_example_hand(this_ceasar, {})
        end
    end
    
    local ret = eval_play_ref(e)
    
    G.GAME.vhp_temp_wilds = nil
    if
        G.GAME.used_vouchers.v_vhp_discover_master and
        G.GAME.blind and G.GAME.blind.boss and
        G.GAME.current_round.hands_played == 0 and
        #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit
    then
        local played_hand = G.GAME.last_hand_played
        if G.GAME.hands[played_hand].played <= 1 then
            G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
            G.E_MANAGER:add_event(Event({
                func = (function()
                    local new_spectral = SMODS.create_card({
                        set = "Spectral",
                        area = G.consumeables,
                        skip_materialize = true,
                        key = "c_black_hole",
                    })
                    new_spectral:add_to_deck()
                    G.consumeables:emplace(new_spectral)
                    G.GAME.consumeable_buffer = math.max(0, G.GAME.consumeable_buffer - 1)
                    play_sound('timpani')
                    return true
                end)}))
        end
    end

    if not G.GAME.vhp_poker_hand_stack then
        G.GAME.vhp_poker_hand_stack = {}
    end
    table.insert(G.GAME.vhp_poker_hand_stack, G.GAME.last_hand_played)

    if G.GAME.vhp_consecutive_unique_set[G.GAME.last_hand_played] then
        G.GAME.vhp_consecutive_unique_set = {}
    end
    G.GAME.vhp_consecutive_unique_set[G.GAME.last_hand_played] = true

    if spicy_hands_set[G.GAME.last_hand_played] then
        G.GAME.vhp_hands_banned_for_spicy_set[G.GAME.vhp_same_hand_combo.hand] = true
    end

    if G.GAME.vhp_same_hand_combo.hand == G.GAME.last_hand_played and (not G.GAME.vhp_hands_banned_for_spicy_set[G.GAME.last_hand_played]) then
        G.GAME.vhp_same_hand_combo.combo = G.GAME.vhp_same_hand_combo.combo + 1
    else
        G.GAME.vhp_same_hand_combo = {
            hand = G.GAME.last_hand_played,
            combo = 1,
        }
    end

    if nostalgic_hand then
        G.GAME.vhp_nostalgia_hand = nostalgic_hand
    end
    if nostalgic_resetter_hand_ids_set[G.GAME.last_hand_played] then
        G.GAME.vhp_nostalgia_hand = nil
    end
    if dejavu_hand then
        G.GAME.vhp_dejavu_hand = dejavu_hand
    end
    if ceasar_hand then
        G.GAME.vhp_ceasar_hand = ceasar_hand
    end
    if probability_mod_hand_map[G.GAME.last_hand_played] then
        for k, v in pairs(G.GAME.probabilities) do
            G.GAME.probabilities[k] = v / probability_mod_hand_map[G.GAME.last_hand_played]
        end
    end

    for _, card in pairs(G.playing_cards) do
        card._vhp_was_face_down = nil
    end

    if open_url_hand_map[G.GAME.last_hand_played] then
        love.system.openURL(open_url_hand_map[G.GAME.last_hand_played])
    end

    if keyed_hand_set[G.GAME.last_hand_played] then
        reset_key_hand()
    end

    return ret
end


local Blind_get_loc_debuff_text_ref = Blind.get_loc_debuff_text
function Blind:get_loc_debuff_text(...)
    if loc_debuff_text_replacement then
        return loc_debuff_text_replacement
    end
    return Blind_get_loc_debuff_text_ref(self, ...)
end


local Card_get_id_ref = Card.get_id
function Card:get_id(...)
    if G.GAME.get_id_forced_value then
        return G.GAME.get_id_forced_value
    end
    return Card_get_id_ref(self, ...)
end


local function update_all_hands_chips_mult()
    for _, hand in pairs(G.GAME.hands) do
        hand.mult = math.max(hand.s_mult + hand.l_mult*(hand.level - 1), 1)
        hand.chips = math.max(hand.s_chips + hand.l_chips*(hand.level - 1), 0)
        if G.GAME.omni_mult then
            hand.mult = hand.mult + G.GAME.omni_mult
        end
        if G.GAME.omni_chips then
            hand.chips = hand.chips + G.GAME.omni_chips
        end
    end
end


local Blind_modify_hand_ref = Blind.modify_hand
function Blind:modify_hand(cards, ph, handname, mult, hand_chips, ...)
    if base_emult_hand_map[handname] then
        return mult ^ talis_num(base_emult_hand_map[handname]), hand_chips, true
    end
    return Blind_modify_hand_ref(self, cards, ph, handname, mult, hand_chips, ...)
end


local Blind_debuff_hand_ref = Blind.debuff_hand
function Blind:debuff_hand(cards, hand, handname, check, ...)
    if G.GAME.modifiers.vhp_no_repeat_hand_types then
        local hand_played_min = 1
        if check then
            hand_played_min = 0
        end
        if G.GAME.hands[handname].played > hand_played_min then
            loc_debuff_text_replacement = "No repeat hand types"
            return true
        end
    end
    if G.GAME.modifiers.vhp_only_discard_worthy and handname ~= "vhp_discard_worthy" then
        loc_debuff_text_replacement = "Play only Discard-Worthy"
        return true
    end
    loc_debuff_text_replacement = nil

    if not check then
        if money_ease_hand_map[handname] then
            ease_dollars(money_ease_hand_map[handname])
        end
        if probability_mod_hand_map[handname] then
            for k, v in pairs(G.GAME.probabilities) do
                G.GAME.probabilities[k] = v * probability_mod_hand_map[handname]
            end
        end
        if banana_scoring_hand_set[handname] then
            for _, card in pairs(G.play.cards) do
                if G.GAME.pool_flags.gros_michel_extinct then
                    local old_value = card.ability.perma_x_mult
                    card.ability.perma_x_mult = card.ability.perma_x_mult + 1.7
                    G.E_MANAGER:add_event(Event({func = (function() card.ability.perma_x_mult = old_value return true end)}))
                else
                    local old_value = card.ability.perma_mult
                    card.ability.perma_mult = card.ability.perma_mult or 0
                    card.ability.perma_mult = card.ability.perma_mult + 3
                    G.E_MANAGER:add_event(Event({func = (function() card.ability.perma_mult = old_value return true end)}))
                end
            end
        end
        if enhance_kicker_hand_set[handname] then
            local kickers = eval_pattern(cards, FIND_KICKER_PATTERN, {})
            if kickers then
                for _, card in pairs(kickers) do
                    card:set_ability(G.P_CENTERS.m_vhp_special, nil, true)
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            card:juice_up()
                            return true
                        end
                    }))
                end
            end
        end
        if create_joker_hand_map[handname] and #G.jokers.cards < G.jokers.config.card_limit then
            G.GAME.joker_buffer = G.GAME.joker_buffer + 1
            G.E_MANAGER:add_event(Event({func = function()
                local new_card = create_card('Joker', G.jokers, nil, nil, nil, nil, create_joker_hand_map[handname], "vhp_create_joker")
                new_card:add_to_deck()
                G.jokers:emplace(new_card)
                new_card:start_materialize()
                G.GAME.joker_buffer = 0
                return true end }))
        end
        if create_consumable_hand_map[handname] then
            for i = 1, create_consumable_hand_map[handname].count, 1 do
                if #G.consumeables.cards < G.consumeables.config.card_limit then
                    G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
                    G.E_MANAGER:add_event(Event({func = function()
                        local new_card = create_card('Tarot_Planet', G.consumeables, nil, nil, nil, nil, create_consumable_hand_map[handname].id, "vhp_create_consumable")
                        if create_consumable_hand_map[handname].negative then
                            new_card:set_edition({negative = true})
                        end
                        new_card:add_to_deck()
                        G.consumeables:emplace(new_card)
                        G.GAME.consumeable_buffer = 0
                        return true end }))
                end
            end
        end
        if hand_size_mod_hand_map[handname] then
            G.hand:change_size(hand_size_mod_hand_map[handname])
            G.GAME.round_resets.temp_handsize = (G.GAME.round_resets.temp_handsize or 0) + hand_size_mod_hand_map[handname]
        end
        if special_wild_hand_map[handname] then
            G.GAME.vhp_temp_wilds = true
        end
        if draw_extra_hand_map[handname] then
            G.GAME.vhp_draw_extra = G.GAME.vhp_draw_extra or 0
            G.GAME.vhp_draw_extra = G.GAME.vhp_draw_extra + draw_extra_hand_map[handname]
        end
        if ritual_hand_set[handname] then
            for _, card in pairs(G.play.cards) do
                if card.config.center_key ~= "m_vhp_special" then
                    card:set_ability(G.P_CENTERS.m_vhp_special, nil, true)
                    card:set_edition({negative = true})
                else
                    card:set_ability(G.P_CENTERS.c_base, nil, true)
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            card:juice_up()
                            return true
                        end
                    }))
                end
            end
        end
        if special_copy_hand_map[handname] then
            for _, card in pairs(G.play.cards) do
                if card.config.center_key == "m_vhp_special" then
                    G.playing_card = (G.playing_card and G.playing_card + 1) or 1
                    local _card = copy_card(card, nil, nil, G.playing_card)
                    _card:add_to_deck()
                    G.deck.config.card_limit = G.deck.config.card_limit + 1
                    table.insert(G.playing_cards, _card)
                    G.hand:emplace(_card)
                    _card.states.visible = nil
                    playing_card_joker_effects({ _card })
    
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            _card:start_materialize()
                            return true
                        end
                    }))
                end
            end
        end
        if ritual_type_hand_map[handname] then
            for _, card in pairs(G.play.cards) do
                if card.config.center_key == "c_base" then
                    if ritual_type_hand_map[handname][1] then
                        card:set_edition({[ritual_type_hand_map[handname][1]] = true})
                    end
                    if ritual_type_hand_map[handname][2] then
                        card:set_ability(G.P_CENTERS["m_" .. ritual_type_hand_map[handname][2]], nil, true)
                    end
                else
                    card:set_ability(G.P_CENTERS.c_base, nil, true)
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            card:juice_up()
                            return true
                        end
                    }))
                end
            end
        end
        if disable_boss_blind_hand_set[handname] and G.GAME.blind and ((not G.GAME.blind.disabled) and (G.GAME.blind:get_type() == 'Boss')) then
            --G.E_MANAGER:add_event(Event({func = function()
                G.E_MANAGER:add_event(Event({func = function()
                    G.GAME.blind:disable()
                return true end }))
            --return true end }))
        end
        if change_blind_req_hand_map[handname] then
            self.chips = self.chips * (1 + change_blind_req_hand_map[handname])
            self.chip_text = number_format(self.chips)
            self:wiggle()
        end
        if add_first_card_seal_hand_map[handname] then
            if G.play.cards[1] then
                G.play.cards[1]:set_seal(add_first_card_seal_hand_map[handname])
            end
        end
        if draw_before_scoring_hand_set[handname] then
            print("This doesn't work correctly!")
            G.FUNCS.draw_from_deck_to_hand()
        end
        if enhance_faces_held_in_hand_hand_set[handname] then
            local cen_pool = {}
            for k, v in pairs(G.P_CENTER_POOLS["Enhanced"]) do
                if v.key ~= 'm_stone' then
                    cen_pool[#cen_pool+1] = v
                end
            end
            for _, card in pairs(G.hand.cards) do
                if card:is_face() then
                    card:set_ability(pseudorandom_element(cen_pool, pseudoseed("vhp_collective")), nil, true)
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            card:juice_up()
                            return true
                        end
                    }))
                end
            end
        end
        if debuff_faces_held_in_hand_hand_set[handname] then
            for _, card in pairs(G.hand.cards) do
                if card:is_face() then
                    card:set_debuff(true)
                    card.ability.vhp_perma_debuff = true
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            card:juice_up()
                            return true
                        end
                    }))
                end
            end
        end
        if trolley_debuff_hand_set[handname] then
            local find_debuff_pattern = TROLLEY_FIND_THREE
            if pseudorandom('trolley') < G.GAME.probabilities.normal * 0.7 then
                find_debuff_pattern = TROLLEY_FIND_ONE
            end
            local cards_to_debuff = eval_pattern(G.play.cards, find_debuff_pattern, {})
            if cards_to_debuff then
                for _, card in pairs(cards_to_debuff) do
                    card:set_debuff(true)
                    card.ability.vhp_perma_debuff = true
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            card:juice_up()
                            return true
                        end
                    }))
                end
            end
        end
        if game_speed_hand_map[handname] then
            G.SETTINGS.GAMESPEED = game_speed_hand_map[handname]
        end
        if omni_mult_hand_map[handname] then
            G.GAME.omni_mult = G.GAME.omni_mult or 0
            G.GAME.omni_mult = talis_num(G.GAME.omni_mult) + talis_num(omni_mult_hand_map[handname])
            level_up_hand(G.jokers.cards[1], handname)
            update_all_hands_chips_mult()
        end
        if omni_chips_hand_map[handname] then
            G.GAME.omni_chips = G.GAME.omni_chips or 0
            G.GAME.omni_chips = talis_num(G.GAME.omni_chips) + talis_num(omni_chips_hand_map[handname])
            level_up_hand(G.jokers.cards[1], handname)
            update_all_hands_chips_mult()
        end
        if nonspecial_remove_mods_hand_set[handname] then
            for _, card in pairs(G.play.cards) do
                if card.config.center_key ~= "m_vhp_special" then
                    card:set_ability(G.P_CENTERS.c_base, nil, true)
                    card:set_seal()
                    card:set_edition()
                end
            end
        end
        if cigarette_chance_hand_map[handname] then
            if (pseudorandom("cigarette") < G.GAME.probabilities.normal/cigarette_chance_hand_map[handname]) then
                for _, card in pairs(G.play.cards) do
                    card:set_debuff(true)
                    card.ability.vhp_perma_debuff = true
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            card:juice_up()
                            return true
                        end
                    }))
                end
            else
                G.GAME.hands[handname].s_chips = G.GAME.hands[handname].s_chips - talis_num(100)
                G.GAME.hands[handname].s_mult = G.GAME.hands[handname].s_mult - talis_num(2.5)
                level_up_hand(G.play.cards[1], handname, false, 0)
            end
        end
        if super_ritual_type_hand_map[handname] then
            if not probability_mod_hand_map[handname] then
                for _, card in pairs(G.play.cards) do
                    if card.config.center_key ~= "m_vhp_special" then
                        card:set_ability(G.P_CENTERS.c_base, nil, true)
                        card:set_seal()
                        card:set_edition()
                    end
                end
            end
            if super_ritual_type_hand_map[handname] == "discard" then
                G.GAME.round_resets.discards = G.GAME.round_resets.discards + 1
                ease_discard(1)
            elseif super_ritual_type_hand_map[handname] == "hand" then
                G.GAME.round_resets.hands = G.GAME.round_resets.hands + 1
                ease_hands_played(1)
            elseif super_ritual_type_hand_map[handname] == "handsize" then
                G.hand:change_size(1)
            elseif super_ritual_type_hand_map[handname] == "jokerslot" then
                G.E_MANAGER:add_event(Event({func = function()
                    if G.jokers then
                        G.jokers.config.card_limit = G.jokers.config.card_limit + 1
                    end
                    return true end }))
            elseif super_ritual_type_hand_map[handname] == "consumableslot" then
                G.E_MANAGER:add_event(Event({func = function()
                    G.consumeables.config.card_limit = G.consumeables.config.card_limit + 1
                    return true end }))
            elseif super_ritual_type_hand_map[handname] == "interest" then
                G.GAME.interest_amount = G.GAME.interest_amount + 1
            elseif super_ritual_type_hand_map[handname] == "permamult" then
                for _, card in pairs(G.playing_cards) do
                    card.ability.perma_mult = card.ability.perma_mult or 0
                    card.ability.perma_mult = card.ability.perma_mult + 5
                end
            elseif super_ritual_type_hand_map[handname] == "permabonus" then
                for _, card in pairs(G.playing_cards) do
                    card.ability.perma_bonus = card.ability.perma_bonus or 0
                    card.ability.perma_bonus = card.ability.perma_bonus + 50
                end
            elseif super_ritual_type_hand_map[handname] == "packselection" then
                G.GAME.vhp_extra_pack_choice = (G.GAME.vhp_extra_pack_choice or 0) + 1
            elseif super_ritual_type_hand_map[handname] == "packcard" then
                G.GAME.vhp_extra_pack_card = (G.GAME.vhp_extra_pack_card or 0) + 1
            elseif super_ritual_type_hand_map[handname] == "blackhole" then
                for i = 1, #G.consumeables.cards do
                    if
                        G.consumeables.cards[i].ability.set == "Planet"
                        and not G.consumeables.cards[i].getting_sliced
                        and not G.consumeables.cards[i].ability.eternal
                    then
                        local target = G.consumeables.cards[i]
                        target.getting_sliced = true
                        G.E_MANAGER:add_event(Event({
                            func = function()
                                target:start_dissolve({ G.C.RED }, nil, 1.6)
                                local new_spectral = SMODS.create_card({
                                    set = "Spectral",
                                    area = G.consumeables,
                                    skip_materialize = true,
                                    key = "c_black_hole",
                                })
                                new_spectral:add_to_deck()
                                G.consumeables:emplace(new_spectral)
                                return true
                            end,
                        }))
                    end
                end
            elseif super_ritual_type_hand_map[handname] == "blindreq" then
                self.chips = self.chips * 0.75
                self.chip_text = number_format(self.chips)
                self:wiggle()
            elseif super_ritual_type_hand_map[handname] == "blindreward" then
                G.GAME.blind.dollars = G.GAME.blind.dollars + 2
                G.GAME.vhp_blind_reward_extra = (G.GAME.vhp_blind_reward_extra or 0) + 2
            else
                error("Unknown ritual: " .. tostring(super_ritual_type_hand_map[handname]))
            end
        end
        if hand_ease_hand_map[handname] then
            ease_hands_played(hand_ease_hand_map[handname][1])
            if hand_ease_hand_map[handname][2] then
                G.GAME.round_resets.hands = G.GAME.round_resets.hands + hand_ease_hand_map[handname][1]
            end
        end
        if no_wee_hand_set[handname] then
            for _, card in pairs(SMODS.find_card("j_wee")) do
                card.ability.extra.chips = 0
                card:juice_up(0.8, 0.8)
            end
        end
        if perma_all_cards_rank_count_as_hand_map[handname] then
            G.GAME.get_id_forced_value = perma_all_cards_rank_count_as_hand_map[handname]
        end
        if nonspecial_convert_hand_map[handname] then
            for _, card in pairs(G.play.cards) do
                if card.config.center_key ~= "m_vhp_special" then
                    card:set_ability(G.P_CENTERS["m_" .. nonspecial_convert_hand_map[handname]], nil, true)
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            card:juice_up()
                            return true
                        end
                    }))
                end
            end
        end
        if tsunami_dupe_hand_map[handname] then
            for _, area in pairs({G.hand, G.deck, G.discard}) do
                for _, card in pairs(area.cards) do
                    G.E_MANAGER:add_event(Event({
                        trigger = 'after',
                        func = function()
                            if card.ability.name == 'Glass Card' then 
                                card:shatter()
                            else
                                card:start_dissolve()
                            end
                        return true end }))
                end
            end
            for _ = 1, tsunami_dupe_hand_map[handname], 1 do
                for _, card in pairs(G.play.cards) do
                    G.playing_card = (G.playing_card and G.playing_card + 1) or 1
                    local _card = copy_card(card, nil, nil, G.playing_card)
                    _card:add_to_deck()
                    G.deck.config.card_limit = G.deck.config.card_limit + 1
                    table.insert(G.playing_cards, _card)
                    G.hand:emplace(_card)
                    _card.states.visible = nil
                    playing_card_joker_effects({ _card })
    
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            _card:start_materialize()
                            return true
                        end
                    }))
                end
            end
        end
        if level_up_multi_hand_map[handname] then
            for _, p_hand in pairs(level_up_multi_hand_map[handname]) do
                level_up_hand(nil, p_hand, true)
            end
            local used_card = G.play.cards[1]
            G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.2, func = function()
                play_sound('tarot1')
                used_card:juice_up(0.8, 0.5)
                return true end }))
            G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.9, func = function()
                play_sound('tarot1')
                used_card:juice_up(0.8, 0.5)
                return true end }))
            G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.9, func = function()
                play_sound('tarot1')
                used_card:juice_up(0.8, 0.5)
                return true end }))
        end
    end

    return Blind_debuff_hand_ref(self, cards, hand, handname, check, ...)
end


local Card_open_ref = Card.open
function Card:open(...)
    if self.ability.set == "Booster" and G.GAME.vhp_extra_pack_card then
        self.ability.extra = self.ability.extra + G.GAME.vhp_extra_pack_card
    end
    local ret = Card_open_ref(self, ...)
    if self.ability.set == "Booster" and G.GAME.vhp_extra_pack_choice then
        G.GAME.pack_choices = math.min(G.GAME.pack_choices + G.GAME.vhp_extra_pack_choice, self.ability.extra)
    end
    return ret
end


local smods_any_suit_ref = SMODS.has_any_suit
function SMODS.has_any_suit(...)
    if G.GAME.vhp_temp_wilds then
        return true
    end
    return smods_any_suit_ref(...)
end


local Card_set_debuff_ref = Card.set_debuff
function Card:set_debuff(should_debuff, ...)
    if self.ability.vhp_perma_debuff then
        return Card_set_debuff_ref(self, true, ...)
    end
    return Card_set_debuff_ref(self, should_debuff, ...)
end


SMODS.current_mod.reset_game_globals = function (run_start)
    if run_start then
        local rank_count = 0
        for _, __ in pairs(SMODS.Ranks) do
            rank_count = rank_count + 1
        end
        local suit_count = 0
        for _, __ in pairs(SMODS.Suits) do
            suit_count = suit_count + 1
        end
        if rank_count > 13 or suit_count > 4 then
            sendWarnMessage("Custom ranks or suits detected. Currently they are not supported by Highest Priestess and may cause issues.", "HighestPriestess")
        end
        G.GAME.vhp_rng_hand = {}
        G.GAME.vhp_rng_example = {}
        G.GAME.vhp_dejavu_hand = {{stone = true}, {stone = true}, {stone = true}, {stone = true}, {stone = true}}
        G.GAME.vhp_dejavu_example = {{stone = true}, {stone = true}, {stone = true}, {stone = true}, {stone = true}}
        for i = 1, 5, 1 do
            local chosen_rank = pseudorandom_element({2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14}, pseudoseed("vhp_rng"))
            local chosen_suit = pseudorandom_element({"Spades", "Hearts", "Clubs", "Diamonds"}, pseudoseed("vhp_rng"))
            table.insert(G.GAME.vhp_rng_hand, {rank = chosen_rank, suit = {chosen_suit, true}})
            table.insert(G.GAME.vhp_rng_example, {rank = chosen_rank, suit = chosen_suit})
        end
        reset_key_hand()
        for key, hand in pairs(G.GAME.hands) do
            if not hand.polyhedra_group then
                local vanilla_hands_map = {
                    ["Five of a Kind"] = 10,
                    Flush = 5,
                    ["Flush Five"] = 12,
                    ["Flush House"] = 11,
                    ["Four of a Kind"] = 4,
                    ["Full House"] = 3,
                    ["High Card"] = 9,
                    Pair = 1,
                    Straight = 6,
                    ["Straight Flush"] = 8,
                    ["Three of a Kind"] = 2,
                    ["Two Pair"] = 7,
                }
                if vanilla_hands_map[key] then
                    hand.polyhedra_group = vanilla_hands_map[key]
                else
                    math.randomseed(pseudohash(key))
                    hand.polyhedra_group = math.random(1, 12)
                end
            end
        end
    end
end


--[[local function eval_pattern(hand, pattern, options)
    local simple_pattern = {}
    for key, value in pairs(pattern) do
        if value.stone then
            table.insert(simple_pattern, {stone = true})
        elseif type(value.rank) == "number" and value.suit and value.suit[2] then
            table.insert(simple_pattern, {rank = value.rank, suit = value.suit[1]})
        elseif type(value.rank) == "number" then
            table.insert(simple_pattern, {rank = value.rank})
        elseif value.suit and value.suit[2] then
            table.insert(simple_pattern, {suit = value.suit[1]})
        else
            return
        end
        simple_pattern[#simple_pattern].unscoring = value.unscoring
    end
    local ret = match_simple(hand, simple_pattern)
    return ret
end]]


local function update_hand_cache(hand)
    -- One of the biggest bottleneck is unexpectedly calling these functions
    -- They all call internally stuff like SMODS.has_no_rank or SMODS.has_any_suit
    -- Which then call Card:calculate_joker a ton of times, very bad!
    -- So let's just cache these results
    for _, card in pairs(hand) do
        card._vhp_cache = {}
        card._vhp_cache.get_id = card:get_id()
        card._vhp_cache.is_suit = {
            Spades = card:is_suit("Spades", nil, true),
            Hearts = card:is_suit("Hearts", nil, true),
            Clubs = card:is_suit("Clubs", nil, true),
            Diamonds = card:is_suit("Diamonds", nil, true),
            Wilds = card:is_suit("Wilds", nil, true),
        }
    end
end


local evaluate_poker_hand_ref = evaluate_poker_hand
function evaluate_poker_hand(hand)
    update_hand_cache(hand)
    local ret = evaluate_poker_hand_ref(hand)
    return ret
end


local config = SMODS.current_mod.config
local new_hands_visible = not config.new_hands_secret

SMODS.Atlas { key = 'planets', path = 'planets.png', px = 71, py = 95 }
SMODS.Atlas { key = 'jokers', path = 'jokers.png', px = 71, py = 95 }

for _, hand_stats in pairs(poker_hands) do
    if hand_stats.nostalgic then
        table.insert(nostalgic_hand_ids, "vhp_" .. hand_stats.key)
    end
    if hand_stats.nostalgic_ranks then
        nostalgic_ranks_hand_set["vhp_" .. hand_stats.key] = true
    end
    if hand_stats.reset_nostalgia then
        nostalgic_resetter_hand_ids_set["vhp_" .. hand_stats.key] = true
    end
    if hand_stats.rng or hand_stats.rng_hint then
        table.insert(rng_hand_ids, "vhp_" .. hand_stats.key)
    end
    if hand_stats.deja_vu then
        table.insert(dejavu_hand_ids, "vhp_" .. hand_stats.key)
    end
    if hand_stats.ceasar then
        ceasar_ids_values["vhp_" .. hand_stats.key] = hand_stats.ceasar
    end
    if hand_stats.money_ease then
        money_ease_hand_map["vhp_" .. hand_stats.key] = hand_stats.money_ease
        money_ease_hand_map["vhp_" .. hand_stats.key .. "_flush"] = hand_stats.money_ease
    end
    if hand_stats.probability_mod then
        probability_mod_hand_map["vhp_" .. hand_stats.key] = hand_stats.probability_mod
    end
    if hand_stats.banana_scoring then
        banana_scoring_hand_set["vhp_" .. hand_stats.key] = true
    end
    if hand_stats.special_mult then
        special_mult_hand_map["vhp_" .. hand_stats.key] = hand_stats.special_mult
        special_mult_hand_map["vhp_" .. hand_stats.key .. "_flush"] = hand_stats.special_mult
    end
    if hand_stats.special_xmult then
        special_xmult_hand_map["vhp_" .. hand_stats.key] = hand_stats.special_xmult
    end
    if hand_stats.enhance_kicker then
        enhance_kicker_hand_set["vhp_" .. hand_stats.key] = true
    end
    if hand_stats.special_joker then
        special_joker_hand_set["vhp_" .. hand_stats.key] = true
    end
    if hand_stats.gene_dupes then
        gene_dupes_hand_set["vhp_" .. hand_stats.key] = hand_stats.gene_dupes
    end
    if hand_stats.create_joker_id then
        create_joker_hand_map["vhp_" .. hand_stats.key] = hand_stats.create_joker_id
    end
    if hand_stats.hand_size_mod then
        hand_size_mod_hand_map["vhp_" .. hand_stats.key] = hand_stats.hand_size_mod
    end
    if hand_stats.special_wild then
        special_wild_hand_map["vhp_" .. hand_stats.key] = true
    end
    if hand_stats.draw_extra then
        draw_extra_hand_map["vhp_" .. hand_stats.key] = hand_stats.draw_extra
    end
    if hand_stats.ritual then
        ritual_hand_set["vhp_" .. hand_stats.key] = true
    end
    if hand_stats.disable_boss_blind then
        disable_boss_blind_hand_set["vhp_" .. hand_stats.key] = true
    end
    if hand_stats.change_blind_req then
        change_blind_req_hand_map["vhp_" .. hand_stats.key] = hand_stats.change_blind_req
    end
    if hand_stats.ritual_type_edition or hand_stats.ritual_type_enhancement then
        ritual_type_hand_map["vhp_" .. hand_stats.key] = {hand_stats.ritual_type_edition, hand_stats.ritual_type_enhancement}
    end
    if hand_stats.special_perma_bonus then
        special_perma_bonus_hand_map["vhp_" .. hand_stats.key] = hand_stats.special_perma_bonus
    end
    if hand_stats.special_perma_mult then
        special_perma_mult_hand_map["vhp_" .. hand_stats.key] = hand_stats.special_perma_mult
    end
    if hand_stats.add_first_card_seal then
        add_first_card_seal_hand_map["vhp_" .. hand_stats.key] = hand_stats.add_first_card_seal
    end
    if hand_stats.draw_before_scoring then
        draw_before_scoring_hand_set["vhp_" .. hand_stats.key] = true
    end
    if hand_stats.special_horsemen_xmult then
        special_horsemen_xmult_hand_map["vhp_" .. hand_stats.key] = hand_stats.special_horsemen_xmult
    end
    if hand_stats.create_consumable_id then
        create_consumable_hand_map["vhp_" .. hand_stats.key] = {
            id = hand_stats.create_consumable_id,
            count = hand_stats.create_consumable_count or 1,
            negative = hand_stats.create_consumable_negative,
        }
    end
    if hand_stats.special_destroy then
        special_destroy_hand_set["vhp_" .. hand_stats.key] = true
    end
    if hand_stats.special_chips then
        special_chips_hand_map["vhp_" .. hand_stats.key] = hand_stats.special_chips
        special_chips_hand_map["vhp_" .. hand_stats.key .. "_flush"] = hand_stats.special_chips
    end
    if hand_stats.special_copy then
        special_copy_hand_map["vhp_" .. hand_stats.key] = hand_stats.special_copy
        special_copy_hand_map["vhp_" .. hand_stats.key .. "_flush"] = hand_stats.special_copy
    end
    if hand_stats.enhance_faces_held_in_hand then
        enhance_faces_held_in_hand_hand_set["vhp_" .. hand_stats.key] = true
    end
    if hand_stats.debuff_faces_held_in_hand then
        debuff_faces_held_in_hand_hand_set["vhp_" .. hand_stats.key] = true
    end
    if hand_stats.special_chance then
        special_chance_hand_map["vhp_" .. hand_stats.key] = hand_stats.special_chance
    end
    if hand_stats.trolley_debuff then
        trolley_debuff_hand_set["vhp_" .. hand_stats.key] = true
    end
    if hand_stats.game_speed then
        game_speed_hand_map["vhp_" .. hand_stats.key] = hand_stats.game_speed
    end
    if hand_stats.open_url then
        open_url_hand_map["vhp_" .. hand_stats.key] = hand_stats.open_url
    end
    if hand_stats.super_ritual_type then
        super_ritual_type_hand_map["vhp_" .. hand_stats.key] = hand_stats.super_ritual_type
    end
    if hand_stats.spicy_hands then
        spicy_hands_set["vhp_" .. hand_stats.key] = hand_stats.spicy_hands
    end
    if hand_stats.keyed then
        keyed_hand_set["vhp_" .. hand_stats.key] = true
    end
    if hand_stats.special_balance then
        special_balance_hand_set["vhp_" .. hand_stats.key] = true
    end
    if hand_stats.special_swap then
        special_swap_hand_set["vhp_" .. hand_stats.key] = true
    end
    if hand_stats.special_maximize then
        special_maximize_hand_set["vhp_" .. hand_stats.key] = true
    end
    if hand_stats.omni_mult then
        omni_mult_hand_map["vhp_" .. hand_stats.key] = hand_stats.omni_mult
    end
    if hand_stats.omni_chips then
        omni_chips_hand_map["vhp_" .. hand_stats.key] = hand_stats.omni_chips
    end
    if hand_stats.hand_ease then
        hand_ease_hand_map["vhp_" .. hand_stats.key] = {hand_stats.hand_ease, hand_stats.hand_ease_permanent}
    end
    if hand_stats.no_wee then
        no_wee_hand_set["vhp_" .. hand_stats.key] = true
    end
    if hand_stats.perma_all_cards_rank_count_as then
        perma_all_cards_rank_count_as_hand_map["vhp_" .. hand_stats.key] = hand_stats.perma_all_cards_rank_count_as
    end
    if hand_stats.nonspecial_convert then
        nonspecial_convert_hand_map["vhp_" .. hand_stats.key] = hand_stats.nonspecial_convert
    end
    if hand_stats.nonspecial_remove_mods then
        nonspecial_remove_mods_hand_set["vhp_" .. hand_stats.key] = true
    end
    if hand_stats.base_emult then
        base_emult_hand_map["vhp_" .. hand_stats.key] = hand_stats.base_emult
    end
    if hand_stats.tsunami_and_dupe then
        tsunami_dupe_hand_map["vhp_" .. hand_stats.key] = hand_stats.tsunami_and_dupe
    end
    if hand_stats.cigarette_chance then
        cigarette_chance_hand_map["vhp_" .. hand_stats.key] = hand_stats.cigarette_chance
    end
    if hand_stats.level_up_multi then
        level_up_multi_hand_map["vhp_" .. hand_stats.key] = hand_stats.level_up_multi
    end

    local function custom_hand_eval(hand)
        if G.hand == nil then
            if hand_stats.no_hand then
                return {{}}
            end
            return
        end
        if hand_stats.no_hand then
            return
        end
        --update_hand_cache(hand)

        if hand_stats.chance and not (pseudorandom("plain_luck") < G.GAME.probabilities.normal/hand_stats.chance) then
            return
        end
        if hand_stats.no_cigarette and (G.GAME.hands.vhp_cigarette.mult > talis_num(1) or G.GAME.hands.vhp_cigarette.chips > talis_num(0)) then
            return
        end
        if hand_stats.chance_or_lucky_high then
            local is_ok = false
            if #hand == 1 and hand[1].config.center_key == "m_lucky" then
                is_ok = true
            end
            if (not is_ok) and (not (pseudorandom("cig_lucky") < G.GAME.probabilities.normal/hand_stats.chance_or_lucky_high)) then
                return
            end
        end
        if hand_stats.possible_rank_sums or hand_stats.possible_rank_products then
            local accumulator = hand_stats.possible_rank_products and 1 or 0
            local aces_count = 0
            for _, card in pairs(hand) do
                if card.config.center_key ~= 'm_stone' then
                    if hand_stats.possible_rank_products then
                        accumulator = accumulator * ((card._vhp_cache.get_id == 14) and 1 or card._vhp_cache.get_id)
                    elseif hand_stats.leaf_rank_sum then
                        accumulator = accumulator + ((card._vhp_cache.get_id == 14) and 1 or card._vhp_cache.get_id)
                    else
                        if card.edition and card.edition.negative then
                            accumulator = accumulator - card.base.nominal
                        else
                            accumulator = accumulator + card.base.nominal
                        end
                        if card._vhp_cache.get_id == 14 then
                            aces_count = aces_count + 1
                            if card.edition and card.edition.negative then
                                -- -11 or -21 -> -1 or -11
                                accumulator = accumulator + 10
                            end
                        end
                    end
                end
            end
            local broke = false
            for _, rank_sum in pairs(hand_stats.possible_rank_sums or hand_stats.possible_rank_products) do
                local possible_sums_set = {[rank_sum] = true}
                for i = 1, aces_count, 1 do
                    -- The sum can be 10 more for each ace
                    -- Ace can be both 1 or 11
                    possible_sums_set[rank_sum + 10 * i] = true
                end
                if possible_sums_set[accumulator] then
                    broke = true
                    break
                end
            end
            if not broke then
                return
            end
        end
        if hand_stats.all_enhanced then
            local enhancement_to_check = "m_" .. (hand_stats.all_enhanced == "special" and "vhp_" or "") .. hand_stats.all_enhanced
            for _, card in pairs(hand) do
                if card.config.center_key ~= enhancement_to_check then
                    return
                end
            end
        end
        if hand_stats.any_enhancement then
            for _, card in pairs(hand) do
                if card.config.center_key == "c_base" then
                    return
                end
            end
        end
        if hand_stats.any_seal then
            for _, card in pairs(hand) do
                if not card.seal then
                    return
                end
            end
        end
        if hand_stats.same_enhancement and #hand > 0 then
            local enhancement_to_check = hand[1].config.center_key
            if enhancement_to_check == "c_base" then
                return
            end
            for _, card in pairs(hand) do
                if card.config.center_key ~= enhancement_to_check then
                    return
                end
            end
        end
        if hand_stats.same_seal and #hand > 0 then
            local seal_to_check = hand[1].seal
            if not seal_to_check then
                return
            end
            for _, card in pairs(hand) do
                if card.seal ~= seal_to_check then
                    return
                end
            end
        end
        if hand_stats.same_edition and #hand > 0 then
            if not hand[1].edition then
                return
            end
            local edition_to_check = hand[1].edition.type
            for _, card in pairs(hand) do
                if (not card.edition) or (card.edition.type ~= edition_to_check) then
                    return
                end
            end
        end
        if hand_stats.different_enhancement then
            -- All cards must be enhanced, if there's a base it's always skipped
            local enhancement_set = {["c_base"] = true}
            for _, card in pairs(hand) do
                if enhancement_set[card.config.center_key] then
                    return
                end
                enhancement_set[card.config.center_key] = true
            end
        end
        if hand_stats.card_count and #hand ~= hand_stats.card_count then
            return
        end
        if hand_stats.all_editioned then
            for _, card in pairs(hand) do
                if (not card.edition) or (card.edition[hand_stats.all_editioned] ~= true) then
                    return
                end
            end
        end
        if hand_stats.all_sealed then
            for _, card in pairs(hand) do
                if card.seal ~= hand_stats.all_sealed then
                    return
                end
            end
        end
        if hand_stats.exact_enhancements then
            local counters = {}
            for _, enhancement in pairs(hand_stats.exact_enhancements) do
                local enhance_key = "m_" .. (enhancement == "special" and "vhp_" or "") .. enhancement
                counters[enhance_key] = (counters[enhance_key] or 0) + 1
            end
            for _, card in pairs(hand) do
                local enhancement_to_check = card.config.center_key
                if enhancement_to_check == "c_base" then
                    enhancement_to_check = "m_none" -- "None" enhancement
                end
                if not counters[enhancement_to_check] then
                    return
                end
                counters[enhancement_to_check] = counters[enhancement_to_check] - 1
                if counters[enhancement_to_check] <= 0 then
                    counters[enhancement_to_check] = nil
                end
            end
        end
        if hand_stats.exact_seals then
            local counters = {}
            for _, seal in pairs(hand_stats.exact_seals) do
                local seal_key = seal
                counters[seal_key] = (counters[seal_key] or 0) + 1
            end
            for _, card in pairs(hand) do
                local seal_to_check = card.seal or "None"
                if not counters[seal_to_check] then
                    return
                end
                counters[seal_to_check] = counters[seal_to_check] - 1
                if counters[seal_to_check] <= 0 then
                    counters[seal_to_check] = nil
                end
            end
        end
        if hand_stats.exact_editions then
            local counters = {}
            for _, edition in pairs(hand_stats.exact_editions) do
                local edition_key = edition
                counters[edition_key] = (counters[edition_key] or 0) + 1
            end
            for _, card in pairs(hand) do
                local edition_to_check = "base"
                if card.edition then
                    edition_to_check = card.edition.type
                end
                if (not counters[edition_to_check]) and (not hand_stats.less_exact_editions) then
                    return
                end
                if counters[edition_to_check] then
                    counters[edition_to_check] = counters[edition_to_check] - 1
                    if counters[edition_to_check] <= 0 then
                        counters[edition_to_check] = nil
                    end
                end
            end
            if hand_stats.less_exact_editions then
                for _, __ in pairs(counters) do
                    return
                end
            end
        end
        if hand_stats.money_min and talis_num(G.GAME.dollars) < talis_num(hand_stats.money_min) then
            return
        end
        if hand_stats.money_max and talis_num(G.GAME.dollars) > talis_num(hand_stats.money_max) then
            return
        end
        if hand_stats.unmodified then
            for _, card in pairs(hand) do
                if card.config.center_key ~= "c_base" and (not hand_stats.different_enhancement) then
                    return
                end
                if card.seal then
                    return
                end
                if card.edition then
                    return
                end
            end
        end
        if hand_stats.class_dived then
            if #hand ~= 2 then
                return
            end
            local two = nil
            local king = nil
            for _, card in pairs(hand) do
                if card._vhp_cache.get_id == 2 then
                    two = card
                end
                if card._vhp_cache.get_id == 13 then
                    king = card
                end
            end
            if not (two and king) then
                return
            end
            if two.config.center_key ~= "c_base" or two.seal or two.edition then
                return
            end
            if king.config.center_key ~= "m_steel" or king.seal ~= "Red" or (not king.edition) or (not king.edition.polychrome) then
                return
            end
        end
        if hand_stats.nostalgic then
            if not G.GAME.vhp_nostalgia_hand then
                return
            end
            local is_nostalgic = eval_pattern(hand, G.GAME.vhp_nostalgia_hand, {})
            if not is_nostalgic then
                return
            end
        end
        if hand_stats.nostalgic_ranks then
            if not G.GAME.vhp_nostalgia_hand then
                return
            end
            local nostalgia_copy = copy_table(G.GAME.vhp_nostalgia_hand)
            for _, card_pattern in pairs(nostalgia_copy) do
                card_pattern.suit = nil
            end
            local is_nostalgic = eval_pattern(hand, nostalgia_copy, {})
            if not is_nostalgic then
                return
            end
        end
        if hand_stats.deja_vu then
            if not G.GAME.vhp_dejavu_hand then
                return
            end
            local is_nostalgic = eval_pattern(hand, G.GAME.vhp_dejavu_hand, {})
            if not is_nostalgic then
                return
            end
        end
        if hand_stats.ceasar then
            if not G.GAME.vhp_ceasar_hand then
                return
            end
            local ceasar_copy = copy_table(G.GAME.vhp_ceasar_hand)
            for index, _ in pairs(ceasar_copy) do
                ceasar_copy[index].rank = ceasar_rotation(ceasar_copy[index].rank, hand_stats.ceasar)
            end
            local is_ceasar = eval_pattern(hand, ceasar_copy, {})
            if not is_ceasar then
                return
            end
        end
        if hand_stats.card_count_min and #hand < hand_stats.card_count_min then
            return
        end
        if hand_stats.card_count_max and #hand > hand_stats.card_count_max then
            return
        end
        if hand_stats.rng then
            if not G.GAME.vhp_rng_hand then
                return
            end
            local is_rng = eval_pattern(hand, G.GAME.vhp_rng_hand, {})
            if not is_rng then
                return
            end
            if G.GAME.vhp_rng_example then
                G.GAME.hands["vhp_" .. hand_stats.key].example = create_example_hand(G.GAME.vhp_rng_example, {})
                --G.GAME.vhp_rng_example = nil
            end
        end
        if hand_stats.rng_hint then
            if (not G.GAME.vhp_rng_hand) or #hand ~= 5 then
                return
            end
            local wildcard_count = 0
            for _, card in pairs(hand) do
                if card.config.center_key == "m_vhp_special" then
                    wildcard_count = wildcard_count + 1
                end
            end
            if wildcard_count == 0 then
                return
            end
            -- Please don't look at this
            local wildcards_indices = {
                {
                    {1},
                    {2},
                    {3},
                    {4},
                    {5},
                },
                {
                    {1, 2},
                    {1, 3},
                    {1, 4},
                    {1, 5},
                    {2, 3},
                    {2, 4},
                    {2, 5},
                    {3, 4},
                    {3, 5},
                    {4, 5},
                },
                {
                    {3, 4, 5},
                    {2, 4, 5},
                    {3, 2, 5},
                    {3, 4, 2},
                    {1, 4, 5},
                    {3, 1, 5},
                    {3, 4, 1},
                    {1, 2, 5},
                    {1, 4, 2},
                    {1, 2, 3},
                },
                {
                    {1, 2, 3, 4},
                    {5, 2, 3, 4},
                    {1, 5, 3, 4},
                    {1, 2, 5, 4},
                    {1, 2, 3, 5},
                },
                {
                    {1, 2, 3, 4, 5},
                },
            }
            local broke = false
            for _, indices in pairs(wildcards_indices[wildcard_count]) do
                local rng_copy = copy_table(G.GAME.vhp_rng_hand)
                for _, index_value in pairs(indices) do
                    rng_copy[index_value] = {unscoring = true}
                end
                local is_rng_hint = eval_pattern(hand, rng_copy, {})
                if is_rng_hint then
                    local rng_example_copy = create_example_hand(G.GAME.vhp_rng_example, {})
                    for _, index_value in pairs(indices) do
                        rng_example_copy[index_value] = {}
                    end
                    for i = 1, 5, 1 do
                        if #(G.GAME.hands["vhp_" .. hand_stats.key].example[i]) == 3 and #(rng_example_copy[i]) == 2 then
                            G.GAME.hands["vhp_" .. hand_stats.key].example[i] = rng_example_copy[i]
                        end
                    end
                    broke = true
                    break
                end
            end
            if not broke then
                return
            end
        end
        if hand_stats.all_debuffed then
            for _, card in pairs(hand) do
                if not card.debuff then
                    return
                end
            end
        end
        if hand_stats.everything_is_stone then
            -- WARNING: When the hand is played, played cards are no longer in G.hand!!!
            for _, card in pairs(G.hand.cards) do
                if card.config.center_key ~= "m_stone" then
                    return
                end
            end
        end
        if hand_stats.everything_is_enhanced then
            -- WARNING: When the hand is played, played cards are no longer in G.hand!!!
            for _, card in pairs(G.hand.cards) do
                if card.config.center_key ~= ("m_" .. hand_stats.everything_is_enhanced) then
                    return
                end
            end
        end
        if hand_stats.all_in and #G.hand.highlighted < #G.hand.cards then
            return
        end
        if hand_stats.all_face then
            for _, card in pairs(hand) do
                if not card:is_face() then
                    return
                end
            end
        end
        if hand_stats.all_nonface then
            for _, card in pairs(hand) do
                if card:is_face() then
                    return
                end
            end
        end
        if hand_stats.two_pair_in_hand then
            local cards_held = {}
            for _, card in pairs(G.hand.cards) do
                if not card.highlighted then
                    table.insert(cards_held, card)
                end
            end
            local all_pairs = get_X_same(2, cards_held, true)
            if #all_pairs < 2 then
                return
            end
        end
        if hand_stats.kingmaxxing then
            local has_held_in_hand = false
            for _, card in pairs(G.hand.cards) do
                if not card.highlighted then
                    has_held_in_hand = true
                    if card:get_id() ~= 13 or card.config.center_key ~= "m_steel" or card.seal ~= "Red" then
                        return
                    end
                end
            end
            if not has_held_in_hand then
                return
            end
        end
        if hand_stats.rank_max then
            for _, card in pairs(hand) do
                if card._vhp_cache.get_id ~= 14 and card._vhp_cache.get_id > hand_stats.rank_max then
                    return
                end
            end
        end
        if hand_stats.rank_min then
            for _, card in pairs(hand) do
                if card._vhp_cache.get_id ~= 14 and card._vhp_cache.get_id < hand_stats.rank_min then
                    return
                end
            end
        end
        if hand_stats.possible_last_hand_ids then
            local broke = false
            for _, possible_id in pairs(hand_stats.possible_last_hand_ids) do
                if G.GAME.last_hand_played == possible_id then
                    broke = true
                    break
                end
            end
            if not broke then
                return
            end
        end
        if hand_stats.yin_yan then
            local light_sum = 0
            local dark_sum = 0
            for _, card in pairs(hand) do
                local current_rank = (card._vhp_cache.get_id == 14) and 1 or card._vhp_cache.get_id
                if card._vhp_cache.is_suit.Hearts or card._vhp_cache.is_suit.Diamonds then
                    light_sum = light_sum + current_rank
                end
                if card._vhp_cache.is_suit.Spades or card._vhp_cache.is_suit.Clubs then
                    dark_sum = dark_sum + current_rank
                end
            end
            if light_sum ~= dark_sum then
                return
            end
        end
        if hand_stats.statistic then
            if #hand ~= 5 then
                return
            end
            local rank_values = {}
            local special_rank = nil
            for _, card in pairs(hand) do
                local rank = (card._vhp_cache.get_id == 14) and 1 or card._vhp_cache.get_id
                table.insert(rank_values, rank)
                if card.config.center_key == "m_vhp_special" then
                    if special_rank then
                        return
                    end
                    special_rank = rank
                end
            end
            if not special_rank then
                return
            end
            if hand_stats.statistic == "mean" then
                local sum = 0
                for _, v in pairs(rank_values) do
                    sum = sum + v
                end
                if math.floor((sum / 5) + 0.5) ~= special_rank then
                    return
                end
            elseif hand_stats.statistic == "median" then
                table.sort(rank_values)
                if rank_values[3] ~= special_rank then
                    return
                end
            elseif hand_stats.statistic == "mode" then
                local modes = calculate_mode(rank_values)
                if #modes ~= 1 or modes[1] ~= special_rank then
                    return
                end
            end
        end
        if hand_stats.math_identity then
            local rank_values = {}
            for _, card in pairs(hand) do
                table.insert(rank_values, (card._vhp_cache.get_id == 14) and 1 or card._vhp_cache.get_id)
            end
            if
                hand_stats.math_identity == "product" or
                hand_stats.math_identity == "log" or
                hand_stats.math_identity == "hyper" or
                hand_stats.math_identity == "bitand" or
                hand_stats.math_identity == "bitnor"
            then
                if #hand ~= 3 then
                    return
                end
                local operation = ({
                    product = function (a, b)
                        return a * b
                    end,
                    log = function (a, b)
                        return a ^ b
                    end,
                    hyper = function (a, b)
                        return hyperoperator_small(b, a, a)
                    end,
                    bitand = bitwise_and,
                    bitnor = bitwise_nor,
                })[hand_stats.math_identity]
                local broke = false
                for _, permutation in pairs(permutation_something(rank_values, #rank_values)) do
                    if permutation[3] == operation(permutation[1], permutation[2]) then
                        broke = true
                        break
                    end
                end
                if not broke then
                    return
                end
            end
            if hand_stats.math_identity == "sum" or hand_stats.math_identity == "factorial" then
                local operation = ({
                    sum = function (a)
                        return a
                    end,
                    factorial = function (a)
                        local ret = 1
                        for i = 1, a, 1 do
                            ret = ret * i
                        end
                        return ret
                    end
                })[hand_stats.math_identity]
                local sum = 0
                for _, value in pairs(rank_values) do
                    sum = sum + value
                end
                local broke = false
                for _, target in pairs(rank_values) do
                    if operation(target) == sum - target then
                        broke = true
                        break
                    end
                end
                if not broke then
                    return
                end
            end
        end
        if hand_stats.triangular then
            if #hand ~= 3 then
                return
            end
            local rank_values = {}
            for _, card in pairs(hand) do
                table.insert(rank_values, (card._vhp_cache.get_id == 14) and 1 or card._vhp_cache.get_id)
            end
            if
                rank_values[1] + rank_values[2] <= rank_values[3] or
                rank_values[3] + rank_values[2] <= rank_values[1] or
                rank_values[1] + rank_values[3] <= rank_values[2]
            then
                return
            end
        end
        if hand_stats.chill_hands then
            if G.GAME.vhp_consecutive_unique_set == nil then
                return
            end
            local count = 0
            for _, __ in pairs(G.GAME.vhp_consecutive_unique_set) do
                count = count + 1
            end
            -- Happens every n-th -> Becomes n-th unique when played
            if count ~= hand_stats.chill_hands - 1 then
                return
            end
        end
        if hand_stats.spicy_hands then
            if G.GAME.vhp_same_hand_combo == nil then
                return
            end
            if G.GAME.vhp_same_hand_combo.combo < hand_stats.spicy_hands then
                return
            end
        end
        if hand_stats.all_facedown then
            for _, card in pairs(hand) do
                if not (card.facing == "back" or card._vhp_was_face_down) then
                    return
                end
            end
        end
        if hand_stats.slayer then
            if #hand ~= 4 then
                return
            end
            local monster = nil
            for _, card in pairs(hand) do
                if card:is_face() then
                    monster = card
                    break
                end
            end
            if not monster then
                return
            end
            local defeated = false
            for _, trigger in pairs(hand) do
                if trigger ~= monster and eval_pattern({trigger, monster}, SAME_SUIT_PATTERN, {}) then
                    local weapon_sum = 0
                    for _, weapon in pairs(hand) do
                        if weapon ~= trigger and weapon ~= monster then
                            weapon_sum = weapon_sum + ((weapon._vhp_cache.get_id == 14) and 1 or weapon._vhp_cache.get_id)
                        end
                    end
                    if weapon_sum >= monster._vhp_cache.get_id then
                        defeated = true
                        break
                    end
                end
            end
            if not defeated then
                return
            end
        end
        if hand_stats.no_cards_in_deck and #G.deck.cards > 0 then
            return
        end
        if hand_stats.required_hands_left then
            local hands_left = G.GAME.current_round.hands_left
            -- hands_left decrease when you play an hand
            -- If you're just selecting cards, we have to consider the hand you already have
            if #G.play.cards == 0 then
                hands_left = hands_left - 1
            end
            if hands_left ~= hand_stats.required_hands_left then
                return
            end
        end
        if hand_stats.neutral_hands and (G.GAME.hands_played + 1) % hand_stats.neutral_hands ~= 0 then
            return
        end
        if hand_stats.required_hands_played and G.GAME.current_round.hands_played ~= hand_stats.required_hands_played then
            return
        end
        if hand_stats.all_cards_in_hand_of_rank then
            -- WARNING: Also counts played cards
            for _, card in pairs(G.hand.cards) do
                if card:get_id() ~= hand_stats.all_cards_in_hand_of_rank then
                    return
                end
            end
        end
        if hand_stats.high_special then
            if #get_X_same(2, hand, true) > 0 or #hand == 0 then
                return
            end
            local highest_card = get_highest(hand)[1][1]
            if highest_card.config.center_key ~= "m_vhp_special" then
                return
            end
        end
        if hand_stats.low_special then
            if #get_X_same(2, hand, true) > 0 or #hand == 0 then
                return
            end
            local lowest_card = hand[1]
            for _, card in pairs(hand) do
                if lowest_card._vhp_cache.get_id > card._vhp_cache.get_id then
                    lowest_card = card
                end
            end
            if lowest_card.config.center_key ~= "m_vhp_special" then
                return
            end
        end
        if hand_stats.rank_constrain then
            for _, card in pairs(hand) do
                if not hand_stats.rank_constrain[tostring(card._vhp_cache.get_id)] then
                    return
                end
            end
        end
        if hand_stats.suit_constrain then
            for _, card in pairs(hand) do
                local broke = false
                for _, suit in pairs(hand_stats.suit_constrain) do
                    if card._vhp_cache.is_suit[suit] then
                        broke = true
                        break
                    end
                end
                if not broke then
                    return
                end
            end
        end
        if hand_stats.keyed then
            local counters = {}
            for _, enhancement in pairs(G.GAME.vhp_key_hand) do
                counters[enhancement] = (counters[enhancement] or 0) + 1
            end
            for _, card in pairs(hand) do
                local enhancement_to_check = card.config.center_key
                if not counters[enhancement_to_check] then
                    return
                end
                counters[enhancement_to_check] = counters[enhancement_to_check] - 1
                if counters[enhancement_to_check] <= 0 then
                    counters[enhancement_to_check] = nil
                end
            end
        end
        if hand_stats.joker_slots_filled then
            if (not G.jokers) or #G.jokers.cards + G.GAME.joker_buffer ~= G.jokers.config.card_limit then
                return
            end
        end
        if hand_stats.date_check and os.date(hand_stats.date_check[1], os.time()) ~= hand_stats.date_check[2] then
            return
        end
        if hand_stats.joker_stat_target then
            local broke = false
            for _, card in pairs(SMODS.find_card(hand_stats.joker_stat_target)) do
                if not hand_stats.joker_stat_property then
                    broke = true
                    break
                end
                local stat = card.ability.extra[hand_stats.joker_stat_property]
                if stat and stat >= hand_stats.joker_stat_min then
                    broke = true
                    break
                end
            end
            if not broke then
                return
            end
        end
        if hand_stats.play_atleast_hand and G.GAME.hands[hand_stats.play_atleast_hand].played < hand_stats.play_atleast_times then
            return
        end
        if hand_stats.idol_cards then
            for _, card in pairs(hand) do
                if
                    card._vhp_cache.get_id ~= G.GAME.current_round.idol_card.id or
                    (not card._vhp_cache.is_suit[G.GAME.current_round.idol_card.suit])
                then
                    return
                end
            end
        end
        if hand_stats.play_in_order then
            if not G.GAME.vhp_poker_hand_stack then
                return
            end
            for i = 0, #hand_stats.play_in_order - 1, 1 do
                if
                    G.GAME.vhp_poker_hand_stack[#G.GAME.vhp_poker_hand_stack - i] ~=
                    hand_stats.play_in_order[#hand_stats.play_in_order - i]
                then
                    return
                end
            end
        end
        
        local eval = hand_stats.eval
        for key, value in pairs(eval) do
            --local pattern_ret = time_and_return(eval_pattern, hand, value.pattern, value.options)
            local pattern_ret = eval_pattern(hand, value.pattern, value.options, hand_stats.key == "dropshot")
            if pattern_ret then
                if hand_stats.held_in_hand_scoring_rank then
                    for _, held_card in pairs(G.hand.cards) do
                        if held_card:get_id() == hand_stats.held_in_hand_scoring_rank then
                            table.insert(pattern_ret, held_card)
                        end
                    end
                end
                return {pattern_ret}
            end
        end
    end

    if hand_stats.measure_time then
        custom_hand_eval = to_timing(custom_hand_eval, hand_stats.key)
    end

    if not hand_stats.composite_only then
        local base_hand_desc = copy_table(hand_stats.desc)
        table.insert(base_hand_desc, "Author: " .. hand_stats.author)
        if not hand_stats.example then
            table.insert(base_hand_desc, "(No example hand given)")
        end
        SMODS.PokerHand {
            key = hand_stats.key,
            chips = hand_stats.base_chips,
            mult = hand_stats.base_mult,
            l_chips = hand_stats.level_chips,
            l_mult = hand_stats.level_mult,
            example = create_example_hand(hand_stats.example, hand_stats),
            loc_txt = {
                name = hand_stats.name,
                description = base_hand_desc,
            },
            visible = new_hands_visible,
            evaluate = function (parts, hand)
                return custom_hand_eval(hand)
            end,
            order_offset = hand_stats.order_offset,
            vhp_it_is = true,
            polyhedra_group = hand_stats.polyhedra_group,
        }
    end

    if hand_stats.flush_name then
        local flush_hand_desc = copy_table(hand_stats.desc)
        table.insert(flush_hand_desc, "all along with a Flush. Author: " .. hand_stats.author)
        if not hand_stats.flush_example then
            table.insert(flush_hand_desc, "(No example hand given)")
        end
        SMODS.PokerHand {
            key = hand_stats.key .. "_flush",
            chips = hand_stats.flush_base_chips,
            mult = hand_stats.flush_base_mult,
            l_chips = hand_stats.flush_level_chips,
            l_mult = hand_stats.flush_level_mult,
            example = create_example_hand(hand_stats.flush_example, hand_stats),
            loc_txt = {
                name = hand_stats.flush_name,
                description = flush_hand_desc,
            },
            visible = new_hands_visible,
            evaluate = function (parts, hand)
                if next(parts._flush) and custom_hand_eval(hand) then
                    return {SMODS.merge_lists(parts._flush)}
                end
            end,
            order_offset = hand_stats.order_offset,
            vhp_it_is = true,
            polyhedra_group = hand_stats.flush_polyhedra_group,
        }
    end

    if hand_stats.straight_name then
        local straight_hand_desc = copy_table(hand_stats.desc)
        table.insert(straight_hand_desc, "all along with a Straight. Author: " .. hand_stats.author)
        if not hand_stats.straight_example then
            table.insert(straight_hand_desc, "(No example hand given)")
        end
        SMODS.PokerHand {
            key = hand_stats.key .. "_straight",
            chips = hand_stats.straight_base_chips,
            mult = hand_stats.straight_base_mult,
            l_chips = hand_stats.straight_level_chips,
            l_mult = hand_stats.straight_level_mult,
            example = create_example_hand(hand_stats.straight_example, hand_stats),
            loc_txt = {
                name = hand_stats.straight_name,
                description = straight_hand_desc,
            },
            visible = new_hands_visible,
            evaluate = function (parts, hand)
                if next(parts._straight) and custom_hand_eval(hand) then
                    return {SMODS.merge_lists(parts._straight)}
                end
            end,
            order_offset = hand_stats.order_offset,
            vhp_it_is = true,
            polyhedra_group = hand_stats.straight_polyhedra_group,
        }
    end

    if hand_stats.house_name then
        local house_hand_desc = copy_table(hand_stats.desc)
        table.insert(house_hand_desc, "all along with a Full House. Author: " .. hand_stats.author)
        if not hand_stats.house_example then
            table.insert(house_hand_desc, "(No example hand given)")
        end
        SMODS.PokerHand {
            key = hand_stats.key .. "_house",
            chips = hand_stats.house_base_chips,
            mult = hand_stats.house_base_mult,
            l_chips = hand_stats.house_level_chips,
            l_mult = hand_stats.house_level_mult,
            example = create_example_hand(hand_stats.house_example, hand_stats),
            loc_txt = {
                name = hand_stats.house_name,
                description = house_hand_desc,
            },
            visible = new_hands_visible,
            evaluate = function (parts, hand)
                --update_hand_cache(hand)
                local full_house_cards = eval_pattern(hand, FULL_HOUSE_PATTERN, {})
                if full_house_cards and custom_hand_eval(hand) then
                    return {full_house_cards}
                end
            end,
            order_offset = hand_stats.order_offset,
            vhp_it_is = true,
            polyhedra_group = hand_stats.house_polyhedra_group,
        }
    end


    local function create_planet(stats)
        math.randomseed(pseudohash(stats.name))
        local planet_atlas = ("custom_planet" .. tostring(hand_stats.planet_texture_id))
        if (not hand_stats.planet_texture_id) or (stats.xpos == nil) then
            planet_atlas = "planets"
        end
        local planet_texture_pos = {x = stats.xpos, y = 0}
        if (not hand_stats.planet_texture_id) or (stats.xpos == nil) then
            planet_texture_pos = {x = math.random(0, 5), y = math.random(0, 1)}
        end
        SMODS.Consumable {
            set = "Planet",
            key = hand_stats.key .. stats.suffix .. "_planet",
            config = {hand_type = "vhp_" .. hand_stats.key .. stats.suffix, softlock = not new_hands_visible},
            atlas = planet_atlas,
            pos = planet_texture_pos,
            set_card_type_badge = function(self, card, badges)
                badges[1] = create_badge(hand_stats.planet_badge or localize('k_planet_q'), get_type_colour(self or card.config, card), nil, 1.2)
            end,
            process_loc_text = function(self)
                --use another planet's loc txt instead
                local target_text = G.localization.descriptions[self.set]['c_mercury'].text
                SMODS.Consumable.process_loc_text(self)
                G.localization.descriptions[self.set][self.key].text = target_text
            end,
            generate_ui = 0,
            loc_txt = {
                name = stats.planet_name or (stats.name .. " Planet"),
            },
            vhp_planet = true,
        }
    end

    if not hand_stats.composite_only then
        create_planet{name = hand_stats.name, planet_name = hand_stats.planet_name, suffix = "", xpos = 0}
    end
    if hand_stats.flush_name then
        create_planet{name = hand_stats.flush_name, planet_name = hand_stats.flush_planet_name, suffix = "_flush", xpos = 1}
    end
    if hand_stats.straight_name then
        create_planet{name = hand_stats.straight_name, planet_name = hand_stats.straight_planet_name, suffix = "_straight"}
    end
    if hand_stats.house_name then
        create_planet{name = hand_stats.house_name, planet_name = hand_stats.house_planet_name, suffix = "_house"}
    end


    math.randomseed(pseudohash(hand_stats.name .. "joker"))
    local joker_atlas = ("custom_jokers" .. tostring(hand_stats.joker_texture_id))
    if not hand_stats.joker_texture_id then
        joker_atlas = "jokers"
    end
    local joker_atlas_random_x = math.random(0, 4)
    local joker_texture_pos = {
        {x = joker_atlas_random_x, y = 0},
        {x = joker_atlas_random_x, y = 1},
        {x = joker_atlas_random_x, y = 2},
    }
    if hand_stats.joker_texture_id then
        joker_texture_pos = {
            {x = 0, y = 0},
            {x = 1, y = 0},
            {x = 2, y = 0},
        }
    end

    if hand_stats.joker_mult then
        SMODS.Joker {
            key = hand_stats.key .. "_mult_joker",
            config = {t_mult = hand_stats.joker_mult, type = "vhp_" .. hand_stats.key},
            atlas = joker_atlas,
            pos = joker_texture_pos[1],
            process_loc_text = function(self)
                --use another joker's loc txt instead
                local target_text = G.localization.descriptions[self.set]['j_jolly'].text
                SMODS.Joker.process_loc_text(self)
                G.localization.descriptions[self.set][self.key].text = target_text
            end,
            loc_vars = function(self, info_queue, card)
                return { vars = { card.ability.t_mult, localize(card.ability.type, "poker_hands") } }
            end,
            rarity = 1,
            cost = 4,
            blueprint_compat = true,
            in_pool = function (self)
                if not config.autogen_jokers then
                    return false
                end
                return new_hands_visible or G.GAME.hands["vhp_" .. hand_stats.key].played > 0
            end,
            loc_txt = {
                name = hand_stats.joker_mult_name or (hand_stats.name .. " Joker"),
            },
        }
    end

    if hand_stats.joker_chips then
        SMODS.Joker {
            key = hand_stats.key .. "_chips_joker",
            config = {t_chips = hand_stats.joker_chips, type = "vhp_" .. hand_stats.key},
            atlas = joker_atlas,
            pos = joker_texture_pos[2],
            process_loc_text = function(self)
                --use another joker's loc txt instead
                local target_text = G.localization.descriptions[self.set]['j_sly'].text
                SMODS.Joker.process_loc_text(self)
                G.localization.descriptions[self.set][self.key].text = target_text
            end,
            loc_vars = function(self, info_queue, card)
                return { vars = { card.ability.t_chips, localize(card.ability.type, "poker_hands") } }
            end,
            rarity = 1,
            cost = 4,
            blueprint_compat = true,
            in_pool = function (self)
                if not config.autogen_jokers then
                    return false
                end
                return new_hands_visible or G.GAME.hands["vhp_" .. hand_stats.key].played > 0
            end,
            loc_txt = {
                name = hand_stats.joker_chips_name or (hand_stats.name .. " Jester"),
            },
        }
    end

    if hand_stats.joker_xmult then
        SMODS.Joker {
            key = hand_stats.key .. "_xmult_joker",
            config = {Xmult = hand_stats.joker_xmult, type = "vhp_" .. hand_stats.key},
            atlas = joker_atlas,
            pos = joker_texture_pos[3],
            process_loc_text = function(self)
                --use another joker's loc txt instead
                local target_text = G.localization.descriptions[self.set]['j_duo'].text
                SMODS.Joker.process_loc_text(self)
                G.localization.descriptions[self.set][self.key].text = target_text
            end,
            loc_vars = function(self, info_queue, card)
                return { vars = { card.ability.Xmult, localize(card.ability.type, "poker_hands") } }
            end,
            rarity = 3,
            cost = 8,
            blueprint_compat = true,
            in_pool = function (self)
                if not config.autogen_jokers then
                    return false
                end
                return new_hands_visible or G.GAME.hands["vhp_" .. hand_stats.key].played > 0
            end,
            loc_txt = {
                name = hand_stats.joker_xmult_name or ("The " .. hand_stats.name),
            },
        }
    end
end


local function update_poker_hands_visibility()
    new_hands_visible = not config.new_hands_secret
    for key, value in pairs(SMODS.PokerHands) do
        if value.vhp_it_is then
            value.visible = new_hands_visible
        end
    end
    for key, value in pairs(G.P_CENTERS) do
        if value.vhp_planet then
            value.config.softlock = not new_hands_visible
        end
    end
end

SMODS.current_mod.config_tab = function()
    return {n=G.UIT.ROOT, config = {align = "cm", minh = G.ROOM.T.h*0.25, padding = 0.0, r = 0.1, colour = G.C.CLEAR}, nodes = {
        create_toggle({label = "Added poker hands are Secret", ref_table = config, ref_value = 'new_hands_secret', callback = update_poker_hands_visibility}),
        create_toggle({label = "Add auto-generated Jokers", ref_table = config, ref_value = 'autogen_jokers'}),
    }}
end

SMODS.current_mod.extra_tabs = function()
    return {
        {
            label = 'Credits',
            tab_definition_function = function()
                local CREDITS_NAMES_PER_ROW = 5
                local author_hands_map = {}
                for _, hand_stats in pairs(poker_hands) do
                    local author = hand_stats.author
                    local name = hand_stats.credits_name or hand_stats.name
                    if author_hands_map[author] then
                        table.insert(author_hands_map[author], name)
                    else
                        author_hands_map[author] = {name}
                    end
                end
                local credits_table = {}
                local i = 1
                for author, hands in pairs(author_hands_map) do
                    if (i - 1) % CREDITS_NAMES_PER_ROW == 0 then
                        table.insert(credits_table, {n=G.UIT.R, config={align = "cm", padding = 0.05}, nodes={}})
                    end
                    local last_row = credits_table[#credits_table]
                    local color = G.C.UI.TEXT_LIGHT
                    if #hands >= 5 then
                        color = G.C.FILTER
                    end
                    table.insert(last_row.nodes,
                            {n=G.UIT.T, config={text = " " .. author .. " ", scale = 0.4, colour = color, shadow = true}}
                    )
                    i = i + 1
                end
                return {n = G.UIT.ROOT, config = {
                    align = "cm", minh = G.ROOM.T.h*0.25, padding = 0.2, r = 0.1, colour = G.C.BLACK, emboss = 0.05, minw = 10
                }, nodes = {
                    {n=G.UIT.R, config={align = "cm", padding = 0}, nodes={
                        {n=G.UIT.T, config={text = "Inspired by ", scale = 0.5, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
                        {n=G.UIT.T, config={text = "Sixty Suits", scale = 0.5, colour = G.C.BLUE, shadow = true}},
                        {n=G.UIT.T, config={text = " (notmario)", scale = 0.5, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
                    }},
                    {n=G.UIT.R, config={align = "cm", padding = 0}, nodes={
                        {n=G.UIT.T, config={text = "and ", scale = 0.5, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
                        {n=G.UIT.T, config={text = '"High" Priestess', scale = 0.5, colour = G.C.BLUE, shadow = true}},
                        {n=G.UIT.T, config={text = " (Super S.F)", scale = 0.5, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
                    }},
                    {n=G.UIT.R, config={align = "cm", padding = 0.1,outline_colour = G.C.JOKER_GREY, r = 0.1, outline = 1}, nodes={
                        {n=G.UIT.R, config={align = "cm", padding = 0}, nodes={
                            {n=G.UIT.T, config={text = "Thanks to everyone <3", scale = 0.7, colour = G.C.RED, shadow = true}},
                        }},
                        {n=G.UIT.R, config={align = "tm", padding = 0}, nodes=credits_table}
                    }}
                }}
            end,
        },
    }
end


SMODS.Atlas {
    key = "vhp_tarot",
    path = "tarot.png",
    px = 71,
    py = 95,
}
SMODS.Atlas {
    key = "vhp_151",
    path = "strange_star.png",
    px = 71,
    py = 95,
}
SMODS.Atlas {
    key = "vhp_voucher1",
    path = "voucher1.png",
    px = 71,
    py = 95,
}
SMODS.Atlas {
    key = "vhp_voucher2",
    path = "voucher2.png",
    px = 71,
    py = 95,
}
SMODS.Atlas {
    key = "vhp_deck",
    path = "deck.png",
    px = 71,
    py = 95,
}
SMODS.Atlas {
    key = "vhp_enhancement",
    path = "enhancement.png",
    px = 71,
    py = 95,
}
SMODS.Atlas {
    key = "vhp_chaos",
    path = "chaos.png",
    px = 71,
    py = 95,
}


SMODS.Consumable {
    key = "highest_priestess",
    set = "Tarot",
    loc_txt = {
        name = "The Highest Priestess",
        text = {
            "{C:planet}Discover{} a new poker hand",
            "and level it up as many",
            "times as the current {C:attention}Ante",
        }
    },
    atlas = "vhp_tarot",
    pos = {x = 0, y = 0},
    can_use = function (self, card)
        for key, value in pairs(G.GAME.hands) do
            if not value.visible then
                return true
            end
        end
        return false
    end,
    use = function (self, card, area, copier)
        local secret_hands = {}
        for key, value in pairs(G.GAME.hands) do
            if not value.visible then
                table.insert(secret_hands, key)
            end
        end
        local chosen_hand = pseudorandom_element(secret_hands, pseudoseed("blunt"))

        G.GAME.hands[chosen_hand].visible = true
        update_hand_text(
                {sound = 'button', volume = 0.7, pitch = 0.8, delay = 0.3},
                {handname=localize(chosen_hand, 'poker_hands'),chips = G.GAME.hands[chosen_hand].chips,
                mult = G.GAME.hands[chosen_hand].mult, level=G.GAME.hands[chosen_hand].level}
        )
        level_up_hand(card, chosen_hand, nil, G.GAME.round_resets.ante)
        update_hand_text({sound = 'button', volume = 0.7, pitch = 1.1, delay = 0}, {mult = 0, chips = 0, handname = '', level = ''})
    end,
}


local function calculate151()
    local total_count = 0
    for key, value in pairs(SMODS.PokerHands) do
        if value.mod and G.GAME.hands[key].played > 0 then
            total_count = total_count + 1
        end
    end
    return total_count
end

SMODS.Joker {
    key = "hundredfiftyone",
    loc_txt = {
        -- Name idea by Post Prototype
        name = "Strange Star",
        text = {
            "{X:mult,C:white} X#1# {} Mult for each",
            "modded {C:attention}poker hand{} played",
            "at least once this run",
            "{C:inactive}(Currently {X:mult,C:white} X#2# {C:inactive} Mult)",
        }
    },
    atlas = "vhp_151",
    pos = {x = 0, y = 0},
    config = {extra = {xmult_bonus = 0.1}},
    rarity = 2,
    cost = 5,
    blueprint_compat = true,
    loc_vars = function (self, info_queue, card)
        local center = card and (card.ability) or self.config
        return {vars = {center.extra.xmult_bonus, 1 + calculate151() * center.extra.xmult_bonus}}
    end,
    calculate = function (self, card, context)
        if context.joker_main then
            card.ability.x_mult = 1 + calculate151() * card.ability.extra.xmult_bonus
        end
    end,
}


SMODS.Voucher {
    key = "discoverer",
    loc_txt = {
        name = "Discoverer",
        text = {
            "At end of round, {C:green}#1# in #2#{} chance",
            "to create {C:tarot}The Highest Priestess{}",
            "{C:inactive}(Must have room)",
            "{C:attention,s:0.8}Original idea and art by Sustato",
        }
    },
    config = {extra = 2},
    atlas = "vhp_voucher1",
    pos = {x = 0, y = 0},
    loc_vars = function (self, info_queue, card)
        local center = card and (card.ability) or self.config
        info_queue[#info_queue+1] = G.P_CENTERS.c_vhp_highest_priestess
        return {vars = {''..(G.GAME and G.GAME.probabilities.normal or 1), center.extra}}
    end,
    redeem = function (self, card)
        local center = card and (card.ability) or self.config
        G.GAME.vhp_discoverer_chance = center.extra
    end
}

local Back_trigger_effect_ref = Back.trigger_effect
function Back:trigger_effect(args, ...)
    if G.GAME.used_vouchers.v_vhp_discoverer then
        if
            args.context == "eval" and
            G.GAME.last_blind and
            pseudorandom('discover') < G.GAME.probabilities.normal/G.GAME.vhp_discoverer_chance and
            #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit
        then
            G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
            G.E_MANAGER:add_event(Event({
                func = (function()
                    local new_tarot = SMODS.create_card({
                        set = "Tarot",
                        area = G.consumeables,
                        skip_materialize = true,
                        key = "c_vhp_highest_priestess",
                    })
                    new_tarot:add_to_deck()
                    G.consumeables:emplace(new_tarot)
                    G.GAME.consumeable_buffer = math.max(0, G.GAME.consumeable_buffer - 1)
                    play_sound('timpani')
                    return true
                end)}))
        end
    end
    return Back_trigger_effect_ref(self, args, ...)
end


SMODS.Voucher {
    key = "discover_master",
    loc_txt = {
        name = "The Highest Discoverer",
        text = {
            "If first poker hand of {C:attention}Boss Blind{}",
            "was never played before,",
            "create a {C:spectral}Black Hole{}",
            "{C:inactive}(Must have room)",
            "{C:attention,s:0.8}Original idea and art by Sustato",
        }
    },
    requires = {"v_vhp_discoverer"},
    config = {},
    atlas = "vhp_voucher2",
    pos = {x = 0, y = 0},
    loc_vars = function (self, info_queue, card)
        info_queue[#info_queue+1] = G.P_CENTERS.c_black_hole
        return {vars = {}}
    end,
}


SMODS.Back {
    key = "toker",
    loc_txt = {
        name = "Toker's Deck",
        text = {
            "Start run with the",
            "{C:planet,T:v_vhp_discoverer}Discoverer{} voucher",
            "and an {C:attention}Eternal",
            "{C:planet,T:j_vhp_hundredfiftyone}Strange Star",
        }
    },
    atlas = "vhp_deck",
    pos = {x = 0, y = 0},
    config = {vouchers = {"v_vhp_discoverer"}},
    apply = function (self, back)
        G.E_MANAGER:add_event(Event({
            func = function()
                if G.jokers then
                    local new_joker = SMODS.create_card({
                        set = "Joker",
                        area = G.jokers,
                        key = "j_vhp_hundredfiftyone",
                    })
                    new_joker:add_to_deck()
                    new_joker:set_eternal(true)
                    new_joker:start_materialize()
                    G.jokers:emplace(new_joker)
                    return true
                end
            end,
        }))
    end
}


SMODS.Enhancement {
    key = "special",
    loc_txt = {
        name = "Special Card",
        text = {
            "Can be used to play",
            "new {C:planet}poker hands"
        },
    },
    atlas = "vhp_enhancement",
    pos = {x = 0, y = 0},
    calculate = function (self, card, context)
        if context.scoring_name and special_chance_hand_map[context.scoring_name] then
            if pseudorandom('special_nope') >= G.GAME.probabilities.normal/special_chance_hand_map[context.scoring_name] then
                return
            end
        end
        if context.cardarea == G.play and context.main_scoring then
            if special_mult_hand_map[context.scoring_name] or special_xmult_hand_map[context.scoring_name] or special_chips_hand_map[context.scoring_name] then
                return {
                    mult = special_mult_hand_map[context.scoring_name],
                    xmult = special_xmult_hand_map[context.scoring_name],
                    chips = special_chips_hand_map[context.scoring_name],
                }
            elseif special_balance_hand_set[context.scoring_name] then
                -- https://github.com/MathIsFun0/Cryptid/blob/ecc305c5b0c3423455df891fd646d12572641b46/items/epic.lua#L241
                local tot = hand_chips + mult
                if not to_big or not tot.array or #tot.array < 2 or tot.array[2] < 2 then --below eXeY notation or no Talisman
                    hand_chips = mod_chips(math.floor(tot / 2))
                    mult = mod_mult(math.floor(tot / 2))
                else
                    if hand_chips > mult then
                        tot = hand_chips
                    else
                        tot = mult
                    end
                    hand_chips = mod_chips(tot)
                    mult = mod_chips(tot)
                end
                update_hand_text({ delay = 0 }, { mult = mult, chips = hand_chips })
                return {
                    message = localize("k_balanced"),
                    colour = { 0.8, 0.45, 0.85, 1 },
                    func = function()
                        G.E_MANAGER:add_event(Event({
                            trigger = "after",
                            func = function()
                                play_sound("gong", 0.94, 0.3)
                                play_sound("gong", 0.94 * 1.5, 0.2)
                                play_sound("tarot1", 1.5)
                                return true
                            end,
                        }))
                    end,
                }
            elseif special_swap_hand_set[context.scoring_name] then
                return {
                    swap = true,
                    message = localize("k_swapped_ex"),
                    colour = { 0.8, 0.45, 0.85, 1 },
                    func = function()
                        G.E_MANAGER:add_event(Event({
                            trigger = "after",
                            func = function()
                                play_sound("gong", 0.94, 0.3)
                                play_sound("gong", 0.94 * 1.5, 0.2)
                                play_sound("tarot1", 1.5)
                                return true
                            end,
                        }))
                    end,
                }
            elseif special_maximize_hand_set[context.scoring_name] then
                local tot = nil
                if hand_chips > mult then
                    tot = hand_chips
                else
                    tot = mult
                end
                hand_chips = mod_chips(tot)
                mult = mod_chips(tot)
                update_hand_text({ delay = 0 }, { mult = mult, chips = hand_chips })
                return {
                    message = "Maximized!",
                    colour = { 0.8, 0.45, 0.85, 1 },
                    func = function()
                        G.E_MANAGER:add_event(Event({
                            trigger = "after",
                            func = function()
                                play_sound("gong", 0.94, 0.3)
                                play_sound("gong", 0.94 * 1.5, 0.2)
                                play_sound("tarot1", 1.5)
                                return true
                            end,
                        }))
                    end,
                }
            elseif special_joker_hand_set[context.scoring_name] and #G.jokers.cards + G.GAME.joker_buffer < G.jokers.config.card_limit then
                G.GAME.joker_buffer = G.GAME.joker_buffer + 1
                G.E_MANAGER:add_event(Event({func = function()
                    play_sound('timpani')
                    local new_card = create_card('Joker', G.jokers, nil, nil, nil, nil, nil, "vhp_spawn_bacon")
                    new_card:add_to_deck()
                    G.jokers:emplace(new_card)
                    G.GAME.joker_buffer = 0
                    return true end }))
                return {
                    message = localize('k_plus_joker')
                }
            elseif special_perma_bonus_hand_map[context.scoring_name] or special_perma_mult_hand_map[context.scoring_name] then
                if special_perma_bonus_hand_map[context.scoring_name] then
                    card.ability.perma_bonus = card.ability.perma_bonus or 0
                    card.ability.perma_bonus = card.ability.perma_bonus + special_perma_bonus_hand_map[context.scoring_name]
                end
                if special_perma_mult_hand_map[context.scoring_name] then
                    card.ability.perma_mult = card.ability.perma_mult or 0
                    card.ability.perma_mult = card.ability.perma_mult + special_perma_mult_hand_map[context.scoring_name]
                end
                return {
                    message = localize("k_upgrade_ex")
                }
            elseif special_horsemen_xmult_hand_map[context.scoring_name] then
                local specials_count = 0
                for _, card in pairs(G.hand.cards) do
                    if card.config.center_key == "m_vhp_special" then
                        specials_count = specials_count + 1
                    end
                end
                if specials_count > 0 then
                    return {
                        xmult = 1 + specials_count * special_horsemen_xmult_hand_map[context.scoring_name]
                    }
                end
            end
        end
        if context.destroy_card and context.cardarea == G.play then
            if gene_dupes_hand_set[context.scoring_name] then
                for _ = 1, 4, 1 do
                    G.playing_card = (G.playing_card and G.playing_card + 1) or 1
                    local _card = copy_card(card, nil, nil, G.playing_card)
                    _card:set_ability(G.P_CENTERS.c_base)
                    _card:add_to_deck()
                    G.deck.config.card_limit = G.deck.config.card_limit + 1
                    table.insert(G.playing_cards, _card)
                    G.hand:emplace(_card)
                    _card.states.visible = nil
                    playing_card_joker_effects({ _card })
    
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            _card:start_materialize()
                            return true
                        end
                    }))
                end
                return {
                    remove = true,
                }
            elseif special_destroy_hand_set[context.scoring_name] then
                return {
                    remove = true,
                }
            end
        end
    end
}


SMODS.Consumable {
    key = "chaos",
    set = "Tarot",
    atlas = "vhp_chaos",
    pos = {x = 0, y = 0},
    config = {mod_conv = 'm_vhp_special', max_highlighted = 1},
    loc_txt = {
        name = "Chaos",
        text={
            "Enhances {C:attention}#1#{} selected",
            "card into a",
            "{C:attention}#2#",
        },
    },
    loc_vars = function (self, info_queue, card)
        local center = card and (card.ability) or self.config
        info_queue[#info_queue+1] = G.P_CENTERS[center.mod_conv]
        return {vars = {center.max_highlighted, localize{type = 'name_text', set = 'Enhanced', key = center.mod_conv}}};
    end,
}


-- Support for modded planets (serious mode must allow other modded planets that don't level up just one hand)
-- Art (Pixelorama)
-- Planets should correspond to polyhedra
-- Faster level up
SMODS.Atlas {
    key = "polyhedra",
    path = "polyhedras.png",
    px = 71,
    py = 95,
}

SMODS.ObjectType {
    key = "Polyhedra",
    default = "c_vhp_polyhedra9", -- Tetrahedron
    cards = {},
}

local hand_group_stats = {
    {planet_name = "Mercury", poly_name = "Cube"},
    {planet_name = "Venus", poly_name = "Octahedron"},
    {planet_name = "Earth", poly_name = "Cuboctahedron"},
    {planet_name = "Mars", poly_name = "Dodecahedron"},
    {planet_name = "Jupiter", poly_name = "Prism"},
    {planet_name = "Saturn", poly_name = "Pyramid"},
    {planet_name = "Uranus", poly_name = "Snub Cube"},
    {planet_name = "Neptune", poly_name = "Frustum"},
    {planet_name = "Pluto", poly_name = "Tetrahedron"},
    {planet_name = "Planet X", poly_name = "Icosahedron"},
    {planet_name = "Ceres", poly_name = "Antiprism"},
    {planet_name = "Eris", poly_name = "Sphere"},
}
hand_group_stats = {}

for type_index, stats in pairs(hand_group_stats) do
    SMODS.Consumable {
        key = "polyhedra" .. type_index,
        set = "Planet",
        atlas = "polyhedra",
        pools = {Polyhedra = true},
        pos = {x = 0, y = 0},
        config = {polyhedra_type = type_index, group_name = stats.planet_name},
        loc_txt = {
            name = stats.poly_name,
            text = {
                "{S:0.8}(Average {S:0.8,V:1}lvl.#1#{S:0.8}){}",
                "Level up all",
                "{C:attention}poker hands",
                "of group {C:dark_edition}#2#",
            }
        },
        loc_vars = function (self, info_queue, card)
            local center = card and (card.ability) or self.config
            local level_sum = 0
            local hands_count = 0
            for _, hand in pairs(G.GAME.hands) do
                if hand.polyhedra_group == center.polyhedra_type then
                    level_sum = level_sum + (hand.level or 1)
                    hands_count = hands_count + 1
                end
            end
            local level_average = math.floor((level_sum / hands_count) + 0.5)
            local level_color = G.C.HAND_LEVELS[math.min(level_average, 7)]
            if level_average == 1 then
                level_color = G.C.UI.TEXT_DARK
            end
            return {vars = {level_average, center.group_name, colours = {level_color}}}
        end,
        set_card_type_badge = function(self, card, badges)
            badges[1] = create_badge(type_index == 12 and "Polyhedra?" or "Polyhedra", get_type_colour(self or card.config, card), nil, 1.2)
        end,
        can_use = function (self, card)
            return true
        end,
        use = function (self, card, area, copier)
            update_hand_text({sound = 'button', volume = 0.7, pitch = 0.8, delay = 0.3}, {handname=card.ability.group_name .. " Hands",chips = '...', mult = '...', level=''})
            G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.2, func = function()
                play_sound('tarot1')
                card:juice_up(0.8, 0.5)
                G.TAROT_INTERRUPT_PULSE = true
                return true end }))
            update_hand_text({delay = 0}, {mult = '+', StatusText = true})
            G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.9, func = function()
                play_sound('tarot1')
                card:juice_up(0.8, 0.5)
                return true end }))
            update_hand_text({delay = 0}, {chips = '+', StatusText = true})
            G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.9, func = function()
                play_sound('tarot1')
                card:juice_up(0.8, 0.5)
                G.TAROT_INTERRUPT_PULSE = nil
                return true end }))
            update_hand_text({sound = 'button', volume = 0.7, pitch = 0.9, delay = 0}, {level='+1'})
            delay(1.3)
            for k, hand in pairs(G.GAME.hands) do
                if hand.polyhedra_group == card.ability.polyhedra_type then
                    level_up_hand(card, k, true)
                end
            end
            update_hand_text({sound = 'button', volume = 0.7, pitch = 1.1, delay = 0}, {mult = 0, chips = 0, handname = '', level = ''})
        end,
    }
end

--[[local get_current_pool_ref = get_current_pool
function get_current_pool(_type, _rarity, _leg, _append, ...)
    if _type == "Planet" and pseudorandom("vhp_polyhedra") < 1 then
        return get_current_pool_ref("Polyhedra", _rarity, _leg, _append, ...)
    end
    return get_current_pool_ref(_type, _rarity, _leg, _append, ...)
end]]


--[[SMODS.PokerHand {
    key = "test",
    chips = 99,
    mult = 99,
    l_chips = 999,
    l_mult = 999,
    example = {},
    loc_txt = {
        name = "Full House?",
        description = {
            "Test"
        },
    },
    visible = true,
    evaluate = function (parts, hand)
        return {G.hand.cards}
    end,
}]]


-- YOU CAN PLAY 0-CARD HANDS
--[[G.FUNCS.can_play = function(e)
    if G.GAME.blind.block_play then 
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
        e.config.button = nil
    else
        e.config.colour = G.C.BLUE
        e.config.button = 'play_cards_from_highlighted'
    end
end]]


--[[function evaluate_poker_hand(hand)
    local results = {}
    local parts = {}
    for _, v in ipairs(SMODS.PokerHandPart.obj_buffer) do
        parts[v] = SMODS.PokerHandParts[v].func(hand) or {}
    end
    for k, _hand in pairs(SMODS.PokerHands) do
        results[k] = _hand.evaluate(parts, hand) or {}
    end
    for _, v in ipairs(G.handlist) do
        if not results.top and results[v] then
            results.top = results[v]
            break
        end
    end
    return results
end]]


SMODS.Challenge {
    key = "fat_blunt",
    loc_txt = {
        name = "Fat Blunt",
    },
    rules = {
        custom = {
            {id = "vhp_no_repeat_hand_types"},
        },
    },
}


SMODS.Challenge {
    key = "garbage_can",
    loc_txt = {
        name = "For The Worthy",
    },
    rules = {
        custom = {
            {id = "vhp_only_discard_worthy"},
        },
    },
    jokers = {
        {id = "j_burnt"},
    },
}