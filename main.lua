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

local json = assert(SMODS.load_file('json.lua'))()
local hands_json = assert(SMODS.load_file('parsed_hands.lua'))()
local poker_hands = json.decode(hands_json)


SMODS.Atlas{
	key = "modicon",
	path = "modicon.png",
	px = 34,
	py = 34,
}


local function time_and_return(func, ...)
    local start_time = love.timer.getTime()
    local ret = func(...)
    local end_time = love.timer.getTime()
    print("Function ", func, " took ", 1000*(end_time-start_time), " ms")
    return ret
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


-- List of {rank = number?, suit = string?, stone = true|nil, unscoring = true|nil}
local function match_simple(hand, pattern)
    --[[Match order:
        {stone}
        {rank, "Wilds"},
        {rank, suit} with a standard suit,
        {rank, suit} with a wild suit,
        {"Wilds"},
        {rank}/{suit} with a standard suit,
        {rank}/{suit} with a wild card,
    ]]
    -- How the patterns work
    -- [1] = pattern_valid = function(pattern) -> boolean
    -- [2] = card_valid = function(card, pattern) -> boolean
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
            function (p) return p.suit and (not p.rank) end,
            function (card, p) return card._vhp_cache.is_suit[p.suit] and (not card.config.center_key == 'm_wild') end,
        },
        {
            function (p) return p.rank and (not p.suit) end,
            function (card, p) return card._vhp_cache.get_id == p.rank and (not card.config.center_key == 'm_wild') end,
        },
        {
            function (p) return p.suit and (not p.rank) end,
            function (card, p) return card._vhp_cache.is_suit[p.suit] end,
        },
        {
            function (p) return p.rank and (not p.suit) end,
            function (card, p) return card._vhp_cache.get_id == p.rank end,
        },
    }
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
        for p_key, p_value in pairs(pattern) do
            if not p_value.unscoring then
                if p_value.stone and SMODS.has_enhancement(h_value, "m_stone") then
                    is_scoring = true
                end
                local suit_okay = false
                if not p_value.suit then
                    suit_okay = true
                else
                    -- Works with wild cards
                    -- Since they are every suit (even if it doesn't exist)
                    suit_okay = h_value:is_suit(p_value.suit)
                end
                local rank_okay = false
                if not p_value.rank then
                    rank_okay = true
                else
                    rank_okay = h_value:get_id() == p_value.rank
                end
                is_scoring = is_scoring or (suit_okay and rank_okay)
            end
        end
        if is_scoring then
            table.insert(scoring_cards, h_value)
        end
    end
    return scoring_cards
end


local function eval_pattern(hand, pattern, options)
    local has_pareidolia = next(find_joker("Pareidolia"))

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
    for var, option_list in pairs(options) do
        for _, value in pairs(option_list) do
            if value == "_nonunique" then
                nonunique_var_set[var] = true
                break
            end
        end
    end

    local rank_combinations = cartesian_product(possible_ranks, #rank_vars)
    local suit_combinations = cartesian_product(possible_suits, #suit_vars)
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
                        if possible_ranks == "_nonface" and not is_face then
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
local function create_example_hand(pattern)
    if not pattern then
        return {}
    end
    local ret_hand = {}
    for key, value in pairs(pattern) do
        if value.stone then
            table.insert(ret_hand, {"S_A", not value.unscoring, "m_stone"})
        elseif value.suit == "Wilds" then
            table.insert(ret_hand, {"H_" .. (RANK_CARD_KEY_MAP[value.rank] or value.rank), not value.unscoring, "m_wild"})
        else
            table.insert(ret_hand, {SUIT_CARD_KEY_MAP[value.suit] .. "_" .. (RANK_CARD_KEY_MAP[value.rank] or value.rank), not value.unscoring})
        end
    end
    return ret_hand
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
            Spades = card:is_suit("Spades"),
            Hearts = card:is_suit("Hearts"),
            Clubs = card:is_suit("Clubs"),
            Diamonds = card:is_suit("Diamonds"),
            Wilds = card:is_suit("Wilds"),
        }
    end
end


local config = SMODS.current_mod.config
local new_hands_visible = not config.new_hands_secret

SMODS.Atlas { key = 'planets', path = 'planets.png', px = 71, py = 95 }
SMODS.Atlas { key = 'jokers', path = 'jokers.png', px = 71, py = 95 }

for hand_id, hand_stats in pairs(poker_hands) do
    local function custom_hand_eval(hand)
        update_hand_cache(hand)

        local eval = hand_stats.eval
        for key, value in pairs(eval) do
            --local pattern_ret = time_and_return(eval_pattern, hand, value.pattern, value.options)
            local pattern_ret = eval_pattern(hand, value.pattern, value.options)
            if pattern_ret then
                return {pattern_ret}
            end
        end
    end

    local base_hand_desc = copy_table(hand_stats.desc)
    table.insert(base_hand_desc, "Author: " .. hand_stats.author)
    if not hand_stats.example then
        table.insert(base_hand_desc, "(No example hand given)")
    end
    SMODS.PokerHand {
        key = "custom" .. tostring(hand_id),
        chips = hand_stats.base_chips,
        mult = hand_stats.base_mult,
        l_chips = hand_stats.level_chips,
        l_mult = hand_stats.level_mult,
        example = create_example_hand(hand_stats.example),
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

    if hand_stats.flush_name then
        local flush_hand_desc = copy_table(hand_stats.desc)
        table.insert(flush_hand_desc, "all along with a Flush. Author: " .. hand_stats.author)
        if not hand_stats.flush_example then
            table.insert(flush_hand_desc, "(No example hand given)")
        end
        SMODS.PokerHand {
            key = "customflush" .. tostring(hand_id),
            chips = hand_stats.flush_base_chips,
            mult = hand_stats.flush_base_mult,
            l_chips = hand_stats.flush_level_chips,
            l_mult = hand_stats.flush_level_mult,
            example = create_example_hand(hand_stats.flush_example),
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
            key = "customstraight" .. tostring(hand_id),
            chips = hand_stats.straight_base_chips,
            mult = hand_stats.straight_base_mult,
            l_chips = hand_stats.straight_level_chips,
            l_mult = hand_stats.straight_level_mult,
            example = create_example_hand(hand_stats.straight_example),
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
            key = "customhouse" .. tostring(hand_id),
            chips = hand_stats.house_base_chips,
            mult = hand_stats.house_base_mult,
            l_chips = hand_stats.house_level_chips,
            l_mult = hand_stats.house_level_mult,
            example = create_example_hand(hand_stats.house_example),
            loc_txt = {
                name = hand_stats.house_name,
                description = house_hand_desc,
            },
            visible = new_hands_visible,
            evaluate = function (parts, hand)
                update_hand_cache(hand)
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
        SMODS.Consumable {
            set = "Planet",
            key = "custom" .. stats.prefix .. tostring(hand_id) .. "_planet",
            config = {hand_type = "vhp_custom" .. stats.prefix .. tostring(hand_id), softlock = not new_hands_visible},
            atlas = "planets",
            pos = {x = math.random(0, 5), y = math.random(0, 1)},
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

    create_planet{name = hand_stats.name, planet_name = hand_stats.planet_name, prefix = ""}
    if hand_stats.flush_name then
        create_planet{name = hand_stats.flush_name, planet_name = hand_stats.flush_planet_name, prefix = "flush"}
    end
    if hand_stats.straight_name then
        create_planet{name = hand_stats.straight_name, planet_name = hand_stats.straight_planet_name, prefix = "straight"}
    end
    if hand_stats.house_name then
        create_planet{name = hand_stats.house_name, planet_name = hand_stats.house_planet_name, prefix = "house"}
    end


    math.randomseed(pseudohash(hand_stats.name .. "joker"))
    local joker_atlas_x = math.random(0, 4)

    if hand_stats.joker_mult then
        SMODS.Joker {
            key = "custom" .. tostring(hand_id) .. "_mult_joker",
            config = {t_mult = hand_stats.joker_mult, type = "vhp_custom" .. tostring(hand_id)},
            atlas = 'jokers',
            pos = {x = joker_atlas_x, y = 0},
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
                return new_hands_visible or G.GAME.hands["vhp_custom" .. tostring(hand_id)].played > 0
            end,
            loc_txt = {
                name = hand_stats.joker_mult_name or (hand_stats.name .. " Joker"),
            },
        }
    end

    if hand_stats.joker_chips then
        SMODS.Joker {
            key = "custom" .. tostring(hand_id) .. "_chips_joker",
            config = {t_chips = hand_stats.joker_chips, type = "vhp_custom" .. tostring(hand_id)},
            atlas = 'jokers',
            pos = {x = joker_atlas_x, y = 1},
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
                return new_hands_visible or G.GAME.hands["vhp_custom" .. tostring(hand_id)].played > 0
            end,
            loc_txt = {
                name = hand_stats.joker_chips_name or (hand_stats.name .. " Jester"),
            },
        }
    end

    if hand_stats.joker_xmult then
        SMODS.Joker {
            key = "custom" .. tostring(hand_id) .. "_xmult_joker",
            config = {Xmult = hand_stats.joker_xmult, type = "vhp_custom" .. tostring(hand_id)},
            atlas = 'jokers',
            pos = {x = joker_atlas_x, y = 2},
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
                return new_hands_visible or G.GAME.hands["vhp_custom" .. tostring(hand_id)].played > 0
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
    }}
end

SMODS.current_mod.extra_tabs = function()
    return {
        {
            label = 'Credits',
            tab_definition_function = function()
                local left_side = {}
                local right_side = {}
                local author_hands_map = {}
                for _, hand_stats in pairs(poker_hands) do
                    local author = hand_stats.author
                    local name = hand_stats.name
                    if author_hands_map[author] then
                        table.insert(author_hands_map[author], name)
                    else
                        author_hands_map[author] = {name}
                    end
                end
                for author, hands in pairs(author_hands_map) do
                    local hand_list = ""
                    for _, hand_name in pairs(hands) do
                        if string.len(hand_list) == 0 then
                            hand_list = hand_name
                        else
                            hand_list = hand_list .. ", " .. hand_name
                        end
                    end
                    table.insert(left_side, {n=G.UIT.R, config={align = "cl", padding = 0}, nodes={
                        {n=G.UIT.T, config={text = author, scale = 0.35, colour = G.C.FILTER, shadow = true}},
                    }})
                    table.insert(right_side, {n=G.UIT.R, config={align = "cl", padding = 0}, nodes={
                        {n=G.UIT.T, config={text = hand_list, scale = 0.35, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
                    }})
                end
                return {n = G.UIT.ROOT, config = {
                    align = "cm", minh = G.ROOM.T.h*0.25, padding = 0.0, r = 0.1, colour = G.C.CLEAR
                }, nodes = {
                    {n=G.UIT.C, config={align = "cm", padding = 0.1,outline_colour = G.C.JOKER_GREY, r = 0.1, outline = 1}, nodes={
                        {n=G.UIT.R, config={align = "cm", padding = 0}, nodes={
                            {n=G.UIT.T, config={text = "Thanks to everyone <3", scale = 0.7, colour = G.C.RED, shadow = true}},
                        }},
                        {n=G.UIT.R, config={align = "tm", padding = 0}, nodes={
                            {n=G.UIT.C, config={align = "tl", padding = 0.05}, nodes=left_side},
                            {n=G.UIT.C, config={align = "tl", padding = 0.05}, nodes=right_side},
                        }},
                    }}
                }}
            end,
        },
    }
end

--[[SMODS.PokerHand {
    key = "test_hand",
    chips = 25,
    mult = 5,
    l_chips = 5,
    l_mult = 1,
    example = {
        { 'S_2', true },
        { 'D_5', true },
    },
    loc_txt = {
        name = "Test Hand",
        description = {
            "2 + 5",
        },
    },
    visible = false,
    evaluate = function (parts, hand)
        local twos = {}
        local fives = {}
        for key, value in pairs(hand) do
            local id = value:get_id()
            if id == 2 then
                table.insert(twos, value)
            elseif id == 5 then
                table.insert(fives, value)
            end
        end
        if #twos ~= 0 and #fives ~= 0 then
            local sum = {}
            for key, value in pairs(twos) do
                table.insert(sum, value)
            end
            for key, value in pairs(fives) do
                table.insert(sum, value)
            end
            return {sum}
        end
    end,
}]]