import re
from typing import Any, Optional
import json
from os import listdir
from os.path import isfile, join


REGEX_KEYVALUE = re.compile(r"^(.+?)\s*=\s*(?:{((?:.|\n)*?)}|(.+))", re.MULTILINE)
REGEX_PARENTHESIS_GROUP = re.compile(r"\((.*?)\)", re.MULTILINE | re.DOTALL)
REGEX_WHITESPACE = re.compile(r"\s+")
#REGEX_ANY_CARD = re.compile(r"((?:unscoring|nonscoring) ?)?([a-z0-9*+]+) ?of ?([a-z0-9*]+)|(stone)", re.IGNORECASE)
#REGEX_ANY_CARD = re.compile(r"(?:X(\d+)?)? ?(?:((?:unscoring|nonscoring) ?)?([a-z0-9*+]+) ?of ?([a-z0-9*]+)|(stone))", re.IGNORECASE)
REGEX_ANY_CARD = re.compile(r"(?:X(\d+)?)? ?(?:((?:unscoring|nonscoring) ?)?([a-z0-9*+]+) ?of ?([a-z0-9*]+)|(stone)) ?(debuffed)?", re.IGNORECASE)
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


def parse_hand_pattern(raw_text: str):
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
            card_list.append({"stone": True})
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
            card_dict["debuffed"] = True
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
    # We can fix this by adding a nonunique rank var like this (X of *) (_internal of Y)
    has_suit_only = False
    has_rank_only = False
    for x in card_list: # type: ignore
        if "rank" in x and "suit" not in x:
            has_rank_only = True
        if "suit" in x and "rank" not in x:
            has_suit_only = True
    needs_support = has_rank_only and has_suit_only
    if needs_support:
        i = 0
        for x in card_list: # type: ignore
            if "suit" in x and "rank" not in x:
                x["rank"] = [f"_support{i}", 0] # type: ignore
                options_dict[f"_support{i}"] = ["_nonunique"]
                i += 1
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
                patterns_list = [parse_hand_pattern(x.group(1)) for x in patterns_iter]
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
                result["rank_sum"] = int(value)
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
            file.write(f"- {author}: " + ", ".join(x.get("credits_name", x["name"]) for x in hands) + "\n")


main()