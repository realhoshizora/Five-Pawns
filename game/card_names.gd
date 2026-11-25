class_name CardNames
## Tên tiếng Anh hiển thị trong game (thuật ngữ: docs/GDD.md mục 0).

const RANK := ["Pawn", "Horse", "Cannon", "Chariot", "Elephant", "Advisor", "General"]
const RANK_PLURAL := ["Pawns", "Horses", "Cannons", "Chariots", "Elephants", "Advisors", "Generals"]
const TYPE := {
	Combo.Type.SINGLE: "Single", Combo.Type.PAIR: "Pair", Combo.Type.TRIPLE: "Triple",
	Combo.Type.FOUR_PAWNS: "Four Pawns", Combo.Type.FIVE_PAWNS: "Five Pawns",
}


static func suit_name(id: int) -> String:
	return "Red" if Card.suit(id) == Card.Suit.RED else "Black"


## "Pair of Red Chariots", "Red General", "Triple · General-Advisor-Elephant", "Five Red Pawns"; "" nếu không hợp lệ.
static func combo(cards: Array) -> String:
	var c := Combo.classify(cards)
	match c.type:
		Combo.Type.SINGLE:
			return "%s %s" % [suit_name(cards[0]), RANK[Card.rank(cards[0])]]
		Combo.Type.PAIR:
			return "Pair of %s %s" % [suit_name(cards[0]), RANK_PLURAL[Card.rank(cards[0])]]
		Combo.Type.TRIPLE:
			var top := false
			for id in cards:
				top = top or Card.rank(id) == Card.Rank.GENERAL
			return "%s %s" % [suit_name(cards[0]), "General · Advisor · Elephant" if top else "Chariot · Cannon · Horse"]
		Combo.Type.FOUR_PAWNS:
			return "Four %s Pawns" % suit_name(cards[0])
		Combo.Type.FIVE_PAWNS:
			return "Five %s Pawns" % suit_name(cards[0])
	return ""
