import re
from typing import Any, Optional
import json
from os import listdir
from os.path import isfile, join
from random import randint, seed


REGEX_KEYVALUE = re.compile(r"^(.+?)\s*=\s*(?:{((?:.|\n)*?)}|(.+))", re.MULTILINE)
REGEX_PARENTHESIS_GROUP = re.compile(r"\((.*?)\)", re.MULTILINE | re.DOTALL)
REGEX_WHITESPACE = re.compile(r"\s+")
REGEX_ANY_CARD = re.compile(r"(?:X(\d+)?)? ?(?:((?:unscoring|nonscoring) ?)?([a-z0-9*+]+) ?of ?([a-z0-9*]+)|(stone)) ?(debuffed|editioned|nondebuffed|nonface|gold|midranked|dark|light|special|lucky|bonus|mult|nonspecial|steel|face|glass|negative)?", re.IGNORECASE)
REGEX_RANK = re.compile(r"(?:(\*)|([a-z]+)(?:\+(\d+))?)", re.IGNORECASE)
REGEX_OPTIONS = re.compile(r"(\w) ?= ?\[(.+?)\]", re.IGNORECASE)
REGEX_VALUES_GENERIC = re.compile(r"[a-z0-9]+", re.IGNORECASE)
REGEX_VALUES_OPTIONS = re.compile(r"[a-z0-9!]+", re.IGNORECASE)
REGEX_COMMENT_MATCH = re.compile(r"^\s*>.*$", re.MULTILINE)


def rank_to_id(rank_name: str) -> Optional[int]:
    if rank_name.isdigit():
        return int(rank_name)
    return {
        "jack": 11,
        "queen": 12,
        "king": 13,
        "ace": 14,
    }.get(rank_name.lower())


def get_rank_token(rank_text: str, is_option: bool = False) -> Optional[int | str | list | dict]:
    if is_option and len(rank_text) >= 1 and rank_text[0] == "!":
        return {"not": get_rank_token(rank_text[1:], is_option)}
    if is_option and rank_text.lower() in ["face", "nonface"]:
        return "_" + rank_text.lower()
    rank_id = rank_to_id(rank_text)
    if rank_id:
        return rank_id
    regex_result = re.match(REGEX_RANK, rank_text)
    assert regex_result is not None
    if regex_result.group(1):
        return None
    else:
        return [regex_result.group(2), int(regex_result.group(3) or 0)]


def get_suit_token(suit_text: str) -> Optional[list]:
    if suit_text.lower() in ["spades", "hearts", "clubs", "diamonds", "wilds"]:
        return [suit_text.capitalize(), True]
    if suit_text == "*":
        return None
    return [suit_text, False]


def parse_hand_pattern(raw_text: str, warn_for_missing_support: bool = True):
    text = re.sub(REGEX_WHITESPACE, " ", raw_text)
    if ";" in text:
        cards_text, options_text = text.split(";")
    else:
        cards_text = text
        options_text = ""
    cards_iter = re.finditer(REGEX_ANY_CARD, cards_text)
    card_list: list[dict] = []
    for card in cards_iter:
        if card.group(5):
            card_dict: dict = {"stone": True}
            if card.group(1):
                print("WARNING! Multiscoring for stone cards not supported")
            card_list.append(card_dict)
            continue
        rank = card.group(3)
        suit = card.group(4)
        card_dict: dict = {}
        rank_token = get_rank_token(rank)
        if rank_token:
            card_dict["rank"] = rank_token
        suit_token = get_suit_token(suit)
        if suit_token:
            card_dict["suit"] = suit_token
        if card.group(2):
            card_dict["unscoring"] = True
        if card.group(1):
            card_dict["times"] = int(card.group(1))
        if card.group(6):
            card_dict["special"] = card.group(6).lower()
        card_list.append(card_dict)
    options_iter = re.finditer(REGEX_OPTIONS, options_text)
    options_dict: dict = {}
    for option in options_iter:
        var_key = option.group(1)
        possible_values_iter = re.finditer(REGEX_VALUES_OPTIONS, option.group(2))
        possible_values_str = [x.group() for x in possible_values_iter]
        are_values_suit = False
        for x in possible_values_str:
            if x.lower() in ["spades", "hearts", "clubs", "diamonds", "wilds"]:
                are_values_suit = True
                break
        if are_values_suit:
            possible_values = ["_nonunique" if x.lower() == "nonunique" else (get_suit_token(x) or [None])[0] for x in possible_values_str]
        else:
            possible_values = ["_nonunique" if x.lower() == "nonunique" else get_rank_token(x, True) for x in possible_values_str]
        options_dict[var_key] = possible_values
    # If the pattern contains any (X of *) and (* of Y) it may not work with a greedy algorithm
    # We can fix this manually by adding a nonunique rank var like this (X of *) (j of Y)
    requirements_count_association = {}
    needs_support = False
    for x in card_list: # type: ignore
        requirements_count = ("rank" in x) + ("suit" in x) + ("special" in x)
        requirements_id = ("rank" in x) * 2**0 + ("suit" in x) * 2**1 + ("special" in x) * 2**2
        if (
            requirements_count in requirements_count_association and
            requirements_count_association[requirements_count] != requirements_id
        ):
            needs_support = True
            break
        requirements_count_association[requirements_count] = requirements_id
    if needs_support and warn_for_missing_support:
        print(f"WARNING! Pattern ({raw_text}) needs support (clashing requirements)")
    return dict(pattern=card_list, options=options_dict)


def parse_example_pattern(raw_text: str):
    text = re.sub(REGEX_WHITESPACE, " ", raw_text)
    cards_iter = re.finditer(REGEX_ANY_CARD, text)
    card_list: list[dict] = []
    for card in cards_iter:
        if card.group(5):
            card_list.append({"stone": True})
            continue
        rank = card.group(3)
        suit = card.group(4)
        card_dict: dict = {}
        rank_token = get_rank_token(rank)
        if rank_token:
            card_dict["rank"] = rank_token
        suit_token = (get_suit_token(suit) or [None])[0]
        if suit_token:
            card_dict["suit"] = suit_token
        if card.group(2):
            card_dict["unscoring"] = True
        if card.group(6):
            card_dict["special"] = card.group(6).lower()
        card_list.append(card_dict)
    return card_list


def parse_poker_hand(raw_text: str) -> dict:
    text = re.sub(REGEX_COMMENT_MATCH, "", raw_text)
    items_iter = re.finditer(REGEX_KEYVALUE, text)
    result: dict = {}
    for item in items_iter:
        key = item.group(1)
        value = item.group(3)
        value_multiline = item.group(2)
        match key.lower():
            case "name":
                result["name"] = value
                seed(value)
                result["polyhedra_group"] = randint(1, 12)
            case "credits name":
                result["credits_name"] = value
            case "base chips":
                result["base_chips"] = float(value)
            case "base mult":
                result["base_mult"] = float(value)
            case "level chips":
                result["level_chips"] = float(value)
            case "level mult":
                result["level_mult"] = float(value)
            case "desc" | "description":
                loc_table = [x.strip() for x in value_multiline.strip().split("\n")]
                result["desc"] = loc_table
            case "eval" | "evaluation":
                patterns_iter = re.finditer(REGEX_PARENTHESIS_GROUP, value_multiline)
                patterns_list = [parse_hand_pattern(x.group(1), not result.get("no_support_warning", False)) for x in patterns_iter]
                result["eval"] = patterns_list
            case "order offset":
                result["order_offset"] = float(value)
            case "author":
                result["author"] = value
            case "planet name":
                result["planet_name"] = value
            case "example":
                result["example"] = parse_example_pattern(value)
            
            case "flush name":
                result["flush_name"] = value
                seed(value)
                result["flush_polyhedra_group"] = randint(1, 12)
            case "flush base chips":
                result["flush_base_chips"] = float(value)
            case "flush base mult":
                result["flush_base_mult"] = float(value)
            case "flush level chips":
                result["flush_level_chips"] = float(value)
            case "flush level mult":
                result["flush_level_mult"] = float(value)
            case "flush planet name":
                result["flush_planet_name"] = value
            case "flush example":
                result["flush_example"] = parse_example_pattern(value)
            
            case "straight name":
                result["straight_name"] = value
                seed(value)
                result["straight_polyhedra_group"] = randint(1, 12)
            case "straight base chips":
                result["straight_base_chips"] = float(value)
            case "straight base mult":
                result["straight_base_mult"] = float(value)
            case "straight level chips":
                result["straight_level_chips"] = float(value)
            case "straight level mult":
                result["straight_level_mult"] = float(value)
            case "straight planet name":
                result["straight_planet_name"] = value
            case "straight example":
                result["straight_example"] = parse_example_pattern(value)
            
            case "house name":
                result["house_name"] = value
                seed(value)
                result["house_polyhedra_group"] = randint(1, 12)
            case "house base chips":
                result["house_base_chips"] = float(value)
            case "house base mult":
                result["house_base_mult"] = float(value)
            case "house level chips":
                result["house_level_chips"] = float(value)
            case "house level mult":
                result["house_level_mult"] = float(value)
            case "house planet name":
                result["house_planet_name"] = value
            case "house example":
                result["house_example"] = parse_example_pattern(value)
            
            case "joker mult":
                result["joker_mult"] = float(value)
            case "joker mult name":
                result["joker_mult_name"] = value
            case "joker chips":
                result["joker_chips"] = float(value)
            case "joker chips name":
                result["joker_chips_name"] = value
            case "joker xmult":
                result["joker_xmult"] = float(value)
            case "joker xmult name":
                result["joker_xmult_name"] = value
            
            case "chance":
                result["chance"] = float(value)
            case "rank sum":
                result["possible_rank_sums"] = [int(value)]
            case "composite only":
                result["composite_only"] = True
            case "all enhanced":
                result["all_enhanced"] = value.lower()
            case "same enhancement":
                result["same_enhancement"] = True
            case "different enhancement":
                result["different_enhancement"] = True
            case "joker texture id":
                result["joker_texture_id"] = int(value)
            case "planet texture id":
                result["planet_texture_id"] = int(value)
            case "card count":
                result["card_count"] = int(value)
            case "all editioned":
                result["all_editioned"] = value.lower()
            case "exact enhancements":
                enhancements_list = REGEX_VALUES_GENERIC.findall(value)
                result["exact_enhancements"] = [x.lower() for x in enhancements_list]
            case "money min":
                result["money_min"] = float(value)
            case "money max":
                result["money_max"] = float(value)
            case "all sealed":
                result["all_sealed"] = value.capitalize()
            case "same edition":
                result["same_edition"] = True
            case "same seal":
                result["same_seal"] = True
            case "unmodified":
                result["unmodified"] = True
            case "nostalgic":
                result["nostalgic"] = True
            case "card count min":
                result["card_count_min"] = int(value)
            case "card count max":
                result["card_count_max"] = int(value)
            case "rng":
                result["rng"] = True
            case "all debuffed":
                result["all_debuffed"] = True
            case "everything is stone":
                result["everything_is_stone"] = True
            case "all in":
                result["all_in"] = True
            case "all face":
                result["all_face"] = True
            case "all nonface":
                result["all_nonface"] = True
            case "measure time":
                print("MEASURE TIME")
                result["measure_time"] = True
            case "two pair in hand":
                result["two_pair_in_hand"] = True
            case "deja vu":
                result["deja_vu"] = True
            case "ceasar":
                result["ceasar"] = int(value)
            case "rank max":
                result["rank_max"] = int(value)
            case "rank min":
                result["rank_min"] = int(value)
            case "any enhancement":
                result["any_enhancement"] = True
            case "math identity":
                result["math_identity"] = value.lower()
            case "possible last hand ids":
                hand_list = [x.strip() for x in value_multiline.strip().split("\n")]
                result["possible_last_hand_ids"] = hand_list
            case "chill hands":
                result["chill_hands"] = int(value)
            case "all facedown":
                result["all_facedown"] = True
            case "slayer":
                result["slayer"] = True
            case "no cards in deck":
                result["no_cards_in_deck"] = True
            case "everything is enhanced":
                result["everything_is_enhanced"] = value.lower()
            case "required hands left":
                result["required_hands_left"] = int(value)
            case "no hand":
                result["no_hand"] = True
            case "no support warning":
                result["no_support_warning"] = True
            case "all steel red seal king in hand":
                result["kingmaxxing"] = True
            case "reset nostalgia":
                result["reset_nostalgia"] = True
            case "money ease":
                result["money_ease"] = float(value)
            case "banana scoring":
                result["banana_scoring"] = True
            case "todo":
                print("TODO")
            case "special mult":
                result["special_mult"] = float(value)
            case "enhance kicker":
                result["enhance_kicker"] = True
            case "special joker":
                result["special_joker"] = True
            case "special xmult":
                result["special_xmult"] = float(value)
            case "probability mod":
                result["probability_mod"] = float(value)
            case "gene dupes":
                result["gene_dupes"] = int(value)
            case "required hands played":
                result["required_hands_played"] = int(value)
            case "create joker id":
                result["create_joker_id"] = value
            case "hand size mod":
                result["hand_size_mod"] = int(value)
            case "all cards in hand of rank":
                result["all_cards_in_hand_of_rank"] = rank_to_id(value)
            case "special wild":
                result["special_wild"] = True
            case "high special":
                result["high_special"] = True
            case "draw extra":
                result["draw_extra"] = int(value)
            case "ritual":
                result["ritual"] = True
            # Here
            case "disable boss blind":
                result["disable_boss_blind"] = True
            case "change blind req":
                result["change_blind_req"] = float(value)
            case "ritual type edition":
                result["ritual_type_edition"] = value.lower()
            case "ritual type enhancement":
                result["ritual_type_enhancement"] = value.lower()
            case "special perma bonus":
                result["special_perma_bonus"] = float(value)
            case "special perma mult":
                result["special_perma_mult"] = float(value)
            case "add first card seal":
                result["add_first_card_seal"] = value.capitalize()
            case "low special":
                result["low_special"] = True
            case "draw before scoring":
                result["draw_before_scoring"] = True
            case "special horsemen xmult":
                result["special_horsemen_xmult"] = float(value)
            case "held in hand scoring rank":
                result["held_in_hand_scoring_rank"] = rank_to_id(value)
            case "create consumable id":
                result["create_consumable_id"] = value
            case "create consumable count":
                result["create_consumable_count"] = int(value)
            case "create consumable negative":
                result["create_consumable_negative"] = True
            case "special destroy":
                result["special_destroy"] = True
            case "special chips":
                result["special_chips"] = float(value)
            case "special copy":
                result["special_copy"] = int(value)
            case "rng hint":
                result["rng_hint"] = True
            case "enhance faces held in hand":
                result["enhance_faces_held_in_hand"] = True
            case "debuff faces held in hand":
                result["debuff_faces_held_in_hand"] = True
            case "rank sum multi":
                result["possible_rank_sums"] = [int(x) for x in value.split()]
            case "leaf rank sum":
                result["leaf_rank_sum"] = True
            case "triangular":
                result["triangular"] = True
            case "rank product multi":
                result["possible_rank_products"] = [int(x) for x in value.split()]
            case "yin yan":
                result["yin_yan"] = True
            case "special chance":
                result["special_chance"] = float(value)
            case "trolley debuff":
                result["trolley_debuff"] = True
            case "rank constrain":
                result["rank_constrain"] = {rank_to_id(x): True for x in value.split()}
            case "suit constrain":
                result["suit_constrain"] = [get_suit_token(x)[0] for x in value.split()]
            case "game speed":
                result["game_speed"] = float(value)
            case "open url":
                result["open_url"] = value
            case "class dived":
                result["class_dived"] = True
            case "exact editions":
                editions_list = REGEX_VALUES_GENERIC.findall(value)
                result["exact_editions"] = [x.lower() for x in editions_list]
            case "super ritual type":
                result["super_ritual_type"] = value.lower()
            case "spicy hands":
                result["spicy_hands"] = int(value)
            case "keyed":
                result["keyed"] = True
            case "less exact editions":
                result["less_exact_editions"] = True
            case "statistic":
                result["statistic"] = value.lower()
            case "special balance":
                result["special_balance"] = True
            case "special swap":
                result["special_swap"] = True
            case "special maximize":
                result["special_maximize"] = True
            case "exact seals":
                seals_list = REGEX_VALUES_GENERIC.findall(value)
                result["exact_seals"] = [x.capitalize() for x in seals_list]
            case "joker slots filled":
                result["joker_slots_filled"] = True
            case "omni mult":
                result["omni_mult"] = float(value)
            case "date check":
                result["date_check"] = value.split("=")
            case "neutral hands":
                result["neutral_hands"] = int(value)
            case "hand ease":
                result["hand_ease"] = int(value)
            case "hand ease permanent":
                result["hand_ease_permanent"] = True
            case "joker stat target":
                result["joker_stat_target"] = value
            case "joker stat property":
                result["joker_stat_property"] = value
            case "joker stat min":
                result["joker_stat_min"] = float(value)
            case "no wee":
                result["no_wee"] = True
            case "perma all cards rank count as":
                result["perma_all_cards_rank_count_as"] = rank_to_id(value)
            case "nonspecial convert":
                result["nonspecial_convert"] = value.lower()
            case "any seal":
                result["any_seal"] = True
            case "planet badge":
                result["planet_badge"] = value
            case "nonspecial remove mods":
                result["nonspecial_remove_mods"] = True
            case "base emult":
                result["base_emult"] = float(value)
            case "nostalgic ranks":
                result["nostalgic_ranks"] = True
            case "tsunami and dupe":
                result["tsunami_and_dupe"] = int(value)
            case "cigarette chance":
                result["cigarette_chance"] = float(value)
            case "no cigarette":
                result["no_cigarette"] = True
            case "chance or lucky high":
                result["chance_or_lucky_high"] = float(value)
            case "play atleast hand":
                result["play_atleast_hand"] = value
            case "play atleast times":
                result["play_atleast_times"] = int(value)
            case "idol cards":
                result["idol_cards"] = True
            case "omni chips":
                result["omni_chips"] = float(value)
            case "play in order":
                hand_list = [x.strip() for x in value_multiline.strip().split("\n")]
                result["play_in_order"] = hand_list
            case "level up multi":
                hand_list = [x.strip() for x in value_multiline.strip().split("\n")]
                result["level_up_multi"] = hand_list
            case "schrodinger":
                result["schrodinger"] = True
            case "trolled":
                result["trolled"] = True
            case "discard ease":
                result["discard_ease"] = int(value)
            case "no discards":
                result["no_discards"] = True
            case "max times per round":
                result["max_times_per_round"] = int(value)
            case "omni xmult":
                result["omni_xmult"] = float(value)
            case "special money":
                result["special_money"] = float(value)
            case "eval held in hand":
                patterns_iter = re.finditer(REGEX_PARENTHESIS_GROUP, value_multiline)
                patterns_list = [parse_hand_pattern(x.group(1), not result.get("no_support_warning", False)) for x in patterns_iter]
                result["eval_held_in_hand"] = patterns_list
            case "different suits count":
                result["different_suits_count"] = int(value)
            case "with flush three":
                result["with_flush_three"] = True
            case "contrast mode":
                suit, contrast = value.split()
                result["contrast_mode"] = [suit.capitalize(), contrast.lower()]
            case "game state":
                result["game_state"] = value.upper()
            case _:
                raise RuntimeError(f"Invalid key '{key}'")
    return result


def main():
    POKER_HANDS_DIR = "poker_hands"
    POKER_HANDS_JSON = "parsed_hands.lua"
    CREDITS_FILE = "CREDITS.txt"
    poker_hand_files = [x for x in listdir(POKER_HANDS_DIR) if isfile(join(POKER_HANDS_DIR, x))]
    result = []
    for x in poker_hand_files:
        with open(join(POKER_HANDS_DIR, x)) as file:
            result.append(parse_poker_hand(file.read()))
            assert x.endswith(".txt")
            result[-1]["key"] = x.removesuffix(".txt")
    # I don't even know if SMODS can support reading non-lua files
    with open(POKER_HANDS_JSON, "w") as file:
        file.write("-- Autogenerated file. Changes may be lost!\nreturn [[ ")
        json.dump(result, file, indent=4)
        file.write(" ]]")
    
    with open(CREDITS_FILE, "w") as file:
        author_hands_map = {x["author"]: [y for y in result if y["author"] == x["author"]] for x in result}
        file.write("> Autogenerated file. Changes may be lost!\n")
        file.write("Thanks to everyone <3\n")
        file.write(f"Total poker hand count: {len(result)}\n")
        for author, hands in author_hands_map.items():
            hand_count_text = f" ({len(hands)} hands)" if len(hands) >= 5 else ""
            file.write(f"- {author}{hand_count_text}: " + ", ".join(x.get("credits_name", x["name"]) for x in hands) + "\n")


main()