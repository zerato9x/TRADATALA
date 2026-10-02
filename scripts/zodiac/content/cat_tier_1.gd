extends RefCounted
## English is transcribed verbatim from docs/authoring/CAT_TIER_1_AUTHORITY.txt.
## Vietnamese is a localization of that text, never a separate content branch.
## Topics organize authoring only; no answer has runtime personality traits.
const CONFIG := {"visit_limits": {"1": 3, "1+": 1}, "last_chance": {}, "special": []}
const NODES := [
	{"id": "cat.t1.favorite_card", "zodiac": "cat", "content_tier": "1", "topic": "favorite_card", "kind": "QUESTION",
		"prompt": [{"speaker": "cat", "en": "You have a favorite card?", "vi": "Bạn có lá bài yêu thích không?"}],
		"answers": [
			{"id": "A", "en": "Obviously. The one that makes me the most money.", "vi": "Có chứ. Lá kiếm cho tôi nhiều tiền nhất.", "delta": 0, "reaction": [{"speaker": "cat", "en": "Mm. Practical.", "vi": "Ừm. Thực tế đấy."}]},
			{"id": "B", "en": "Maybe. I just don’t like losing certain ones.", "vi": "Có lẽ. Tôi chỉ không thích mất vài lá nhất định.", "delta": 1, "reaction": [{"speaker": "cat", "en": "Oh?", "vi": "Ồ?"}, {"speaker": "cat", "en": "So you do get attached.", "vi": "Vậy là bạn cũng gắn bó với chúng."}]},
			{"id": "C", "en": "They’re cards.", "vi": "Chúng chỉ là bài thôi.", "delta": -1, "reaction": [{"speaker": "cat", "en": "That wasn’t what I asked.", "vi": "Tôi đâu có hỏi vậy."}]}
		]},
	{"id": "cat.t1.keeping_things", "zodiac": "cat", "content_tier": "1", "topic": "keeping_things", "kind": "QUESTION",
		"prompt": [{"speaker": "cat", "en": "If something stops being useful, do you still keep it?", "vi": "Nếu một thứ không còn hữu ích, bạn có giữ lại không?"}],
		"answers": [
			{"id": "A", "en": "If I like it.", "vi": "Nếu tôi thích nó.", "delta": 1, "reaction": [{"speaker": "cat", "en": "Good.", "vi": "Tốt."}, {"speaker": "cat", "en": "Useful things are boring.", "vi": "Những thứ hữu ích chán lắm."}]},
			{"id": "B", "en": "Depends how much space it takes.", "vi": "Còn tùy nó chiếm bao nhiêu chỗ.", "delta": 0, "reaction": [{"speaker": "cat", "en": "Reasonable.", "vi": "Hợp lý."}]},
			{"id": "C", "en": "No point keeping junk.", "vi": "Giữ đồ bỏ đi làm gì.", "delta": -1, "reaction": [{"speaker": "cat", "en": "Junk.", "vi": "Đồ bỏ đi."}, {"speaker": "cat", "en": "Mean.", "vi": "Ác thật."}]}
		]},
	{"id": "cat.t1.curiosity", "zodiac": "cat", "content_tier": "1", "topic": "curiosity", "kind": "QUESTION",
		"prompt": [{"speaker": "cat", "en": "If someone tells you not to open something…", "vi": "Nếu ai đó bảo bạn đừng mở một thứ…"}, {"speaker": "cat", "en": "Do you?", "vi": "Bạn có mở không?"}],
		"answers": [
			{"id": "A", "en": "Yes.", "vi": "Có.", "delta": 1, "reaction": [{"speaker": "cat", "en": "Obviously.", "vi": "Dĩ nhiên rồi."}]},
			{"id": "B", "en": "Depends who told me not to.", "vi": "Còn tùy ai bảo tôi đừng mở.", "delta": 0, "reaction": [{"speaker": "cat", "en": "Hm.", "vi": "Hừm."}, {"speaker": "cat", "en": "That’s probably smarter.", "vi": "Có lẽ như vậy khôn hơn."}]},
			{"id": "C", "en": "No.", "vi": "Không.", "delta": -1, "reaction": [{"speaker": "cat", "en": "Really?", "vi": "Thật sao?"}, {"speaker": "cat", "en": "How do you live like that?", "vi": "Sao bạn sống như thế được?"}]}
		]},
	{"id": "cat.t1plus.leave_it_alone", "zodiac": "cat", "content_tier": "1+", "topic": "favorite_card", "kind": "QUESTION", "requirements": {"target": "CARD"},
		"prompt": [{"speaker": "cat", "en": "You still have a favorite card?", "vi": "Bạn vẫn có lá bài yêu thích chứ?"}],
		"answers": [
			{"id": "A", "en": "The one that makes me money.", "vi": "Lá kiếm tiền cho tôi.", "delta": 0, "reaction": []},
			{"id": "B", "en": "Maybe.", "vi": "Có lẽ.", "delta": 1, "reaction": []},
			{"id": "C", "en": "No.", "vi": "Không.", "delta": -1, "reaction": []}
		],
		"followup": [{"speaker": "direction", "en": "Cat looks over the player’s cards.", "vi": "Mão nhìn qua những lá bài của người chơi."}, {"speaker": "cat", "en": "Mm.", "vi": "Ừm."}, {"speaker": "cat", "en": "Then leave this one alone.", "vi": "Vậy để yên lá này."}],
		"promise": {"id": "cat.leave_card", "polarity": "DONT", "interaction": "card_use", "target_kind": "CARD", "targeting": "ANY", "window": "NEXT_DEAL", "en": "Do not interact with the selected card during the next Deal.", "vi": "Không tương tác với lá bài đã chọn trong Ván kế tiếp."},
		"responses": {
			"ACCEPT": {"delta": 0, "dialogue": [{"speaker": "player", "en": "Fine.", "vi": "Được thôi."}, {"speaker": "cat", "en": "Really?", "vi": "Thật sao?"}, {"speaker": "cat", "en": "Okay.", "vi": "Được."}, {"speaker": "cat", "en": "Don’t touch it.", "vi": "Đừng chạm vào nó."}]},
			"REFUSE": {"delta": 0, "dialogue": [{"speaker": "player", "en": "No.", "vi": "Không."}, {"speaker": "cat", "en": "Mm.", "vi": "Ừm."}, {"speaker": "direction", "en": "She looks at the card again.", "vi": "Cô lại nhìn lá bài."}, {"speaker": "cat", "en": "So that one matters.", "vi": "Vậy là lá đó quan trọng."}]},
			"HAGGLE": {"delta": 0, "strategy": "OFFER_THREE", "dialogue": [{"speaker": "player", "en": "Pick something else.", "vi": "Chọn cái khác đi."}, {"speaker": "cat", "en": "No.", "vi": "Không."}, {"speaker": "direction", "en": "Pause.", "vi": "Một khoảng lặng."}, {"speaker": "cat", "en": "…Actually.", "vi": "…Mà này."}, {"speaker": "direction", "en": "Cat offers three cards.", "vi": "Mão đưa ra ba lá bài."}, {"speaker": "cat", "en": "You pick.", "vi": "Bạn chọn đi."}]},
			"COUNTER_ACCEPT": {"delta": 0, "dialogue": [{"speaker": "cat", "en": "Interesting.", "vi": "Thú vị đấy."}]}
		},
		"outcomes": {
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "cat", "en": "You really didn’t.", "vi": "Bạn thật sự không chạm vào."}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "cat", "en": "There.", "vi": "Đấy."}, {"speaker": "player", "en": "What?", "vi": "Gì cơ?"}, {"speaker": "cat", "en": "You touched it.", "vi": "Bạn đã chạm vào nó."}]}
		}},
	{"id": "cat.t1plus.keep_it", "zodiac": "cat", "content_tier": "1+", "topic": "keeping_things", "kind": "QUESTION", "requirements": {"target": "RELIC"},
		"prompt": [{"speaker": "direction", "en": "Cat points toward one of the player’s Relics.", "vi": "Mão chỉ vào một Di vật của người chơi."}, {"speaker": "cat", "en": "You were going to sell that?", "vi": "Bạn định bán nó à?"}],
		"answers": [
			{"id": "A", "en": "If I don’t need it.", "vi": "Nếu tôi không cần nó.", "delta": -1, "reaction": []},
			{"id": "B", "en": "Maybe.", "vi": "Có lẽ.", "delta": 0, "reaction": []},
			{"id": "C", "en": "I like it.", "vi": "Tôi thích nó.", "delta": 1, "reaction": []}
		],
		"followup": [{"speaker": "direction", "en": "Cat keeps looking at it.", "vi": "Mão vẫn nhìn nó."}, {"speaker": "cat", "en": "Then keep it.", "vi": "Vậy giữ nó lại."}],
		"promise": {"id": "cat.keep_relic", "polarity": "DONT", "interaction": "relic_loss", "target_kind": "RELIC", "targeting": "OWNED", "window": "ZODIAC_RETURN", "en": "Do not sell, give away, or lose the selected Relic before Cat returns.", "vi": "Không bán, cho đi hay làm mất Di vật đã chọn trước khi Mão trở lại."},
		"responses": {
			"ACCEPT": {"delta": 0, "dialogue": [{"speaker": "player", "en": "Okay.", "vi": "Được."}, {"speaker": "cat", "en": "Good.", "vi": "Tốt."}]},
			"REFUSE": {"delta": 0, "dialogue": [{"speaker": "player", "en": "I might need the money.", "vi": "Có thể tôi sẽ cần tiền."}, {"speaker": "cat", "en": "Then sell it.", "vi": "Vậy bán nó đi."}, {"speaker": "cat", "en": "I just wanted to know.", "vi": "Tôi chỉ muốn biết thôi."}]},
			"HAGGLE": {"delta": 0, "strategy": "OTHER_RELIC", "dialogue": [{"speaker": "player", "en": "Can I keep something else instead?", "vi": "Tôi giữ thứ khác thay nó được không?"}, {"speaker": "cat", "en": "…Sure.", "vi": "…Được."}, {"speaker": "cat", "en": "But that one.", "vi": "Nhưng phải là cái đó."}]}
		},
		"outcomes": {
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "cat", "en": "Still there.", "vi": "Vẫn còn đó."}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "cat", "en": "Oh.", "vi": "Ồ."}, {"speaker": "cat", "en": "You didn’t like it that much.", "vi": "Bạn đâu có thích nó đến thế."}]}
		}},
	{"id": "cat.t1plus.dont_change_it", "zodiac": "cat", "content_tier": "1+", "topic": "transformed_card", "kind": "QUESTION", "requirements": {"target": "TRANSFORMED_CARD"},
		"prompt": [{"speaker": "direction", "en": "Cat notices a transformed card.", "vi": "Mão để ý một lá bài đã biến đổi."}, {"speaker": "cat", "en": "That wasn’t always like that.", "vi": "Trước đây nó đâu có như thế."}, {"speaker": "player", "en": "No.", "vi": "Không."}, {"speaker": "cat", "en": "Better now?", "vi": "Giờ tốt hơn chưa?"}],
		"answers": [
			{"id": "A", "en": "Much better.", "vi": "Tốt hơn nhiều.", "delta": 0, "reaction": []},
			{"id": "B", "en": "I just like what happened to it.", "vi": "Tôi chỉ thích sự thay đổi của nó.", "delta": 1, "reaction": []},
			{"id": "C", "en": "I’ll replace it when I find something stronger.", "vi": "Tôi sẽ thay nó khi tìm được thứ mạnh hơn.", "delta": -1, "reaction": []}
		],
		"followup": [{"speaker": "direction", "en": "Cat stares at the card.", "vi": "Mão nhìn chằm chằm vào lá bài."}, {"speaker": "cat", "en": "Don’t.", "vi": "Đừng."}],
		"promise": {"id": "cat.protect_card", "polarity": "DONT", "interaction": "card_alter", "target_kind": "CARD", "targeting": "PERMANENTLY_CHANGED", "window": "ZODIAC_RETURN", "en": "Do not Reset, Reduce, transform, or otherwise alter the selected card before Cat returns.", "vi": "Không Hoàn nguyên, Giảm, biến đổi hay thay đổi lá bài đã chọn trước khi Mão trở lại."},
		"responses": {
			"ACCEPT": {"delta": 0, "dialogue": [{"speaker": "player", "en": "Fine.", "vi": "Được thôi."}, {"speaker": "cat", "en": "Leave it.", "vi": "Để yên nó."}]},
			"REFUSE": {"delta": 0, "dialogue": [{"speaker": "player", "en": "It’s my card.", "vi": "Bài của tôi mà."}, {"speaker": "direction", "en": "Cat looks at the player.", "vi": "Mão nhìn người chơi."}, {"speaker": "cat", "en": "I know.", "vi": "Tôi biết."}]},
			"HAGGLE": {"delta": 0, "strategy": "OTHER_TRANSFORMED_CARD", "dialogue": [{"speaker": "player", "en": "What if I change a different one?", "vi": "Nếu tôi đổi lá khác thì sao?"}, {"speaker": "cat", "en": "…Why?", "vi": "…Tại sao?"}, {"speaker": "direction", "en": "Pause.", "vi": "Một khoảng lặng."}, {"speaker": "cat", "en": "Fine.", "vi": "Được thôi."}, {"speaker": "cat", "en": "Leave that one alone instead.", "vi": "Vậy để yên lá đó thay cho nó."}]}
		},
		"outcomes": {
			"FULFILLED": {"delta": 1, "dialogue": [{"speaker": "cat", "en": "See?", "vi": "Thấy chưa?"}, {"speaker": "cat", "en": "It survived.", "vi": "Nó vẫn còn nguyên."}]},
			"BROKEN": {"delta": -1, "dialogue": [{"speaker": "cat", "en": "You changed it.", "vi": "Bạn đã đổi nó."}]}
		}}
]
