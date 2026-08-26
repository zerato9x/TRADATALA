class_name DeckManager
extends RefCounted

const RANKS: Array[String] = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
const SUITS: Array[String] = ["Spades", "Hearts", "Diamonds", "Clubs"]

var draw_pile: Array[CardData] = []
var discard_pile: Array[CardData] = []
var _rng := RandomNumberGenerator.new()


func reset(shuffle_seed: int = -1) -> void:
	draw_pile = build_standard_deck()
	discard_pile.clear()
	if shuffle_seed >= 0:
		_rng.seed = shuffle_seed
	else:
		_rng.randomize()
	_shuffle_draw_pile()


func build_standard_deck() -> Array[CardData]:
	var cards: Array[CardData] = []
	for suit in SUITS:
		for rank_offset in range(RANKS.size()):
			var rank := RANKS[rank_offset]
			var rank_index := rank_offset + 1
			var value := rank_index
			var card_id := "standard_%s_%s" % [rank.to_lower(), suit.to_lower()]
			cards.append(CardData.new(card_id, rank, rank_index, suit, value))
	return cards


func draw(count: int = 1) -> Array[CardData]:
	var drawn: Array[CardData] = []
	for _index in range(maxi(count, 0)):
		if draw_pile.is_empty():
			break
		drawn.append(draw_pile.pop_back())
	return drawn


func refill(hand: Array[CardData], target_size: int) -> Array[CardData]:
	var drawn := draw(maxi(target_size - hand.size(), 0))
	hand.append_array(drawn)
	return drawn


func discard(card: CardData) -> void:
	discard_pile.append(card)


func discard_many(cards: Array[CardData]) -> void:
	discard_pile.append_array(cards)


func _shuffle_draw_pile() -> void:
	for index in range(draw_pile.size() - 1, 0, -1):
		var swap_index := _rng.randi_range(0, index)
		var temporary := draw_pile[index]
		draw_pile[index] = draw_pile[swap_index]
		draw_pile[swap_index] = temporary
