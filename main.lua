local VHP = SMODS.current_mod
local FULL_HOUSE_PATTERN = {
        {rank = {"a", 0}},
        {rank = {"a", 0}},
        {rank = {"a", 0}},
        {rank = {"b", 0}},
        {rank = {"b", 0}},
}
local RANK_CARD_KEY_MAP = {[10] = "T", [11] = "J", [12] = "Q", [13] = "K", [14] = "A"}
local SUIT_CARD_KEY_MAP = {Spades = "S", Hearts = "H", Clubs = "C", Diamonds = "D"}
local CUSTOM_JOKERS_ATLAS_MAP = {
    "custom_jokers_low_card.png",
    "custom_jokers_nothing.png",
    "custom_jokers_bumblebee_straight.png",
    "custom_jokers_parable.png",
    "custom_jokers_royal_sampler.png",
    "custom_jokers_aaaaa.png",
    "custom_jokers_last_ditch.png",
}
local CUSTOM_PLANETS_ATLAS_MAP = {
    "custom_planet_garn47.png",
    "custom_planet_sigma_n.png",
    "custom_planet_omicron.png",
    "custom_planet_lemon.png",
}

local json = assert(SMODS.load_file('json.lua'))()
local hands_json = assert(SMODS.load_file('parsed_hands.lua'))()
local poker_hands = json.decode(hands_json)
local nostalgic_hand_ids = {}
local rng_hand_ids = {}
local dejavu_hand_ids = {}
local ceasar_ids_values = {}


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


local function match_special(card, special)
    if special == "debuffed" then
        return card.debuff
    elseif special == "editioned" then
        return card.edition ~= nil
    elseif special == "nondebuffed" then
        return not card.debuff
    end
end


-- Maybe there's something to optimize here?
local pattern_funcs = {
    {
        function (p) return p.stone end,
        function (card, p) return card.config.center_key == 'm_stone' end,
    },
    {
        function (p) return p.rank and p.suit == "Wilds" end,
        function (card, p) return card._vhp_cache.get_id == p.rank and card.config.center_key == 'm_wild' end,
    },
    {
        function (p) return p.rank and p.suit end,
        function (card, p) return card._vhp_cache.get_id == p.rank and card._vhp_cache.is_suit[p.suit] and (not card.config.center_key == 'm_wild') end,
    },
    {
        function (p) return p.rank and p.suit end,
        function (card, p) return card._vhp_cache.get_id == p.rank and card._vhp_cache.is_suit[p.suit] end,
    },
    {
        function (p) return p.suit == "Wilds" and (not p.rank) end,
        function (card, p) return card.config.center_key == 'm_wild' end,
    },
    {
        function (p) return p.rank and p.special end,
        function (card, p) return card._vhp_cache.get_id == p.rank and match_special(card, p.special) end,
    },
    {
        function (p) return p.suit and (not p.rank) end,
        function (card, p) return card._vhp_cache.is_suit[p.suit] and (not card.config.center_key == 'm_wild') end,
    },
    {
        function (p) return p.rank and (not p.suit) and (not p.special) end,
        function (card, p) return card._vhp_cache.get_id == p.rank and (not card.config.center_key == 'm_wild') end,
    },
    {
        function (p) return p.suit and (not p.rank) end,
        function (card, p) return card._vhp_cache.is_suit[p.suit] end,
    },
    {
        function (p) return p.rank and (not p.suit) and (not p.special) end,
        function (card, p) return card._vhp_cache.get_id == p.rank end,
    },
    {
        function (p) return p.special and (not p.rank) and (not p.suit) and (not p.stone) end,
        function (card, p) return match_special(card, p.special) end,
    },
    {
        function (p) return (not p.rank) and (not p.suit) and (not p.stone) and (not p.special) end,
        function (card, p) return true end,
    },
}
-- List of {rank = number?, suit = string?, stone = true|nil, unscoring = true|nil, times = number?, special = any?}
local function match_simple(hand, pattern)
    --[[Match order:
        {stone}
        {rank, "Wilds"},
        {rank, suit} with a standard suit,
        {rank, suit} with a wild suit,
        {"Wilds"},
        {rank, special},
        {rank}/{suit} with a standard suit,
        {rank}/{suit} with a wild card,
        {special},
        {} always true,
    ]]
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
                if p_value.stone then
                    is_scoring = is_scoring or SMODS.has_enhancement(h_value, "m_stone")
                else
                    is_scoring = is_scoring or (suit_okay and rank_okay)
                end
                if suit_okay and rank_okay then
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


local function eval_pattern(hand, pattern, options)
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
                local ret = match_simple(hand, simple_pattern)
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
                    (full_stats.all_enhanced and ("m_" .. full_stats.all_enhanced)) or nil
            })
        end
    end
    return ret_hand
end


local eval_play_ref = G.FUNCS.evaluate_play
G.FUNCS.evaluate_play = function (e)
    local nostalgic_hand = nil
    if (not G.GAME.vhp_nostalgia_hand) and #G.play.cards == 5 then
        local nostalgic_example = {}
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
        end
        for _, id in pairs(nostalgic_hand_ids) do
            G.GAME.hands[id].example = create_example_hand(nostalgic_example, {})
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

    if nostalgic_hand then
        G.GAME.vhp_nostalgia_hand = nostalgic_hand
    end
    if dejavu_hand then
        G.GAME.vhp_dejavu_hand = dejavu_hand
    end
    if ceasar_hand then
        G.GAME.vhp_ceasar_hand = ceasar_hand
    end
    return ret
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
    if hand_stats.rng then
        table.insert(rng_hand_ids, "vhp_" .. hand_stats.key)
    end
    if hand_stats.deja_vu then
        table.insert(dejavu_hand_ids, "vhp_" .. hand_stats.key)
    end
    if hand_stats.ceasar then
        ceasar_ids_values["vhp_" .. hand_stats.key] = hand_stats.ceasar
    end

    local function custom_hand_eval(hand)
        --update_hand_cache(hand)

        if hand_stats.chance and not (pseudorandom("plain_luck") < G.GAME.probabilities.normal/hand_stats.chance) then
            return
        end
        if hand_stats.rank_sum then
            local sum = 0
            local aces_count = 0
            for _, card in pairs(hand) do
                if card.config.center_key ~= 'm_stone' then
                    sum = sum + card.base.nominal
                end
                if card._vhp_cache.get_id == 14 then
                    aces_count = aces_count + 1
                end
            end
            local possible_sums_set = {[hand_stats.rank_sum] = true}
            for i = 1, aces_count, 1 do
                -- The sum can be 10 more for each ace
                -- Ace can be both 1 or 11
                possible_sums_set[hand_stats.rank_sum + 10 * i] = true
            end
            if not possible_sums_set[sum] then
                return
            end
        end
        if hand_stats.all_enhanced then
            local enhancement_to_check = "m_" .. hand_stats.all_enhanced
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
                local enhance_key = "m_" .. enhancement
                counters[enhance_key] = (counters[enhance_key] or 0) + 1
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
        if hand_stats.money_min and G.GAME.dollars < talis_num(hand_stats.money_min) then
            return
        end
        if hand_stats.money_max and G.GAME.dollars > talis_num(hand_stats.money_max) then
            return
        end
        if hand_stats.unmodified then
            for _, card in pairs(hand) do
                if card.config.center_key ~= "c_base" then
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
        if hand_stats.nostalgic then
            if not G.GAME.vhp_nostalgia_hand then
                return
            end
            local is_nostalgic = eval_pattern(hand, G.GAME.vhp_nostalgia_hand, {})
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
                G.GAME.vhp_rng_example = nil
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
        
        local eval = hand_stats.eval
        for key, value in pairs(eval) do
            --local pattern_ret = time_and_return(eval_pattern, hand, value.pattern, value.options)
            local pattern_ret = eval_pattern(hand, value.pattern, value.options)
            if pattern_ret then
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
                badges[1] = create_badge(localize('k_planet_q'), get_type_colour(self or card.config, card), nil, 1.2)
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
        create_planet{name = hand_stats.flush_name, planet_name = hand_stats.flush_planet_name, suffix = "_flush"}
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
            -- TODO: Implement T: and center stuff correctly
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
        for _, card in pairs(G.hand.cards) do
            if not card.highlighted then
                if card.config.center_key ~= "m_stone" then
                    return
                end
            end
        end
        return {hand}
    end,
}]]