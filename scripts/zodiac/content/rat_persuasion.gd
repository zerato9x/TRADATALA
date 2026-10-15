extends RefCounted
## Rat values useful returns, physical things, and an honest account of ownership.
const CONFIG := {
	"visit_limits": {
		"1": 3,
		"2": 1,
		"1+": 1
	},
	"progression": [
		{
			"from": 2,
			"to": 3,
			"kept": 3,
			"distinct": 2,
			"promises": [
				"rat.reuse",
				"rat.extend",
				"rat.card"
			]
		}
	],
	"memory_button": {
		"en": "Rat's finds",
		"vi": "Đồ nhặt của Tý"
	},
	"memory_title": {
		"en": "What Rat remembers",
		"vi": "Điều Tý nhớ"
	},
	"memory_topics": {
		"rat.reuse": {
			"en": "A useful return",
			"vi": "Lấy lại có ích"
		},
		"rat.extend": {
			"en": "New pieces",
			"vi": "Phần mới"
		},
		"rat.card": {
			"en": "The real thing",
			"vi": "Chính lá thật"
		}
	},
	"emblem_unlock": {
		"relationship_tier": 3,
		"promises_kept": 3,
		"promise_kinds": 2,
		"promises_refused": 1,
		"pleased_victories": 1
	},
	"private_scene": [
		{
			"en": "Rat empties a pocket: string, a bent key, a blue button. He nearly puts them all back, then sets the button where you can see it.",
			"vi": "Tý dốc túi: sợi dây, chìa khóa cong, chiếc cúc xanh. Anh suýt cất hết lại, rồi để chiếc cúc nơi bạn nhìn thấy."
		},
		{
			"en": "\"From my first good coat. Coat's gone. Kept telling myself the button would be useful. It won't. I just liked that coat.\"",
			"vi": "\"Của chiếc áo tử tế đầu tiên tôi có. Áo mất rồi. Tôi cứ bảo cúc còn dùng được. Không đâu. Tôi chỉ thích cái áo ấy.\""
		},
		{
			"en": "He adds a rat Emblem to the little pile. \"This one's for you. Bring it on our day. The button stays with me, if that's all right.\"",
			"vi": "Anh thêm Huy hiệu con chuột vào đống nhỏ. \"Cái này cho bạn. Đến ngày của mình thì mang. Còn chiếc cúc, cho tôi giữ nhé.\""
		}
	],
	"last_chance": {
		"id": "rat.last_chance.account",
		"prompt": [
			{
				"speaker": "rat",
				"en": "Empty your pockets of excuses a moment. What are you actually offering?",
				"vi": "Tạm trút hết lý do khỏi túi đi. Bạn thật sự định cho tôi câu trả lời nào?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "A clear answer, even if I can't promise another use.",
				"vi": "Câu trả lời rõ, dù tôi không hứa dùng lại gì được.",
				"recovery_success": true,
				"reaction": [
					{
						"speaker": "rat",
						"en": "Good. That won't fall apart when I pick it up.",
						"vi": "Được. Câu ấy cầm lên không rã ra."
					}
				]
			},
			{
				"id": "B",
				"en": "Nothing more today. I need to leave the possibility open.",
				"vi": "Hôm nay không thêm gì. Tôi cần để ngỏ khả năng.",
				"recovery_success": true,
				"reaction": [
					{
						"speaker": "rat",
						"en": "Keep it, then. I don't take things people haven't offered.",
						"vi": "Vậy cứ giữ. Người ta chưa đưa thì tôi không lấy."
					}
				]
			},
			{
				"id": "C",
				"en": "Anything you want to hear, as long as I gain from it.",
				"vi": "Điều bạn muốn nghe, miễn tôi có lợi.",
				"recovery_success": false,
				"reaction": [
					{
						"speaker": "rat",
						"en": "Counterfeit. We're done trading words today.",
						"vi": "Hàng giả. Hôm nay thôi trao đổi lời lẽ nhé."
					}
				]
			}
		]
	},
	"special": []
}
const NODES := [
	{
		"id": "rat.t1.leftover",
		"zodiac": "rat",
		"content_tier": "1",
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "rat",
				"en": "Everyone's gone. There's a bent spoon under the table. Rubbish, or a find?",
				"vi": "Mọi người về hết. Dưới bàn có cái thìa cong. Rác, hay món đáng nhặt?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Something worth checking before throwing away.",
				"vi": "Điều đáng xem trước khi vứt.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "rat",
						"en": "Exactly. Bent isn't broken. Usually.",
						"vi": "Đúng. Cong chưa phải hỏng. Thường là vậy."
					}
				]
			},
			{
				"id": "B",
				"en": "Maybe somebody still needs it.",
				"vi": "Có lẽ ai đó vẫn cần.",
				"delta": 0,
				"reaction": [
					{
						"speaker": "rat",
						"en": "Then ask. A lost thing isn't automatically a free thing.",
						"vi": "Vậy hỏi đi. Đồ thất lạc không tự nhiên thành đồ cho không."
					}
				]
			},
			{
				"id": "C",
				"en": "Mine, because nobody was looking.",
				"vi": "Của tôi, vì chẳng ai nhìn.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "rat",
						"en": "Funny. That's what people say about my pockets when I'm asleep.",
						"vi": "Lạ nhỉ. Người ta cũng nói thế về túi tôi lúc tôi ngủ."
					}
				]
			}
		]
	},
	{
		"id": "rat.t1.borrow",
		"zodiac": "rat",
		"content_tier": "1",
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "rat",
				"en": "I lend you my good screwdriver. What do I get back?",
				"vi": "Tôi cho bạn mượn cái tua vít tốt. Tôi nhận lại gì?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Your screwdriver. And I'd tell you what I used it for.",
				"vi": "Tua vít của bạn. Và tôi kể đã dùng nó làm gì.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "rat",
						"en": "And if you chip the handle, tell me. I'll find out anyway.",
						"vi": "Mẻ cán thì nhớ nói. Đằng nào tôi cũng biết."
					}
				]
			},
			{
				"id": "B",
				"en": "The screwdriver and a thank-you, when I'm done.",
				"vi": "Xong việc tôi trả tua vít, rồi cảm ơn.",
				"delta": 0,
				"reaction": [
					{
						"speaker": "rat",
						"en": "Before I need it, preferably. I own one good screwdriver.",
						"vi": "Tốt nhất trước lúc tôi cần. Tôi chỉ có một cái tốt thôi."
					}
				]
			},
			{
				"id": "C",
				"en": "A reason they should let me keep it.",
				"vi": "Lý do để họ cho tôi giữ luôn.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "rat",
						"en": "It's a loan. The clue is the part where it comes back.",
						"vi": "Là cho mượn. Dấu hiệu nhận biết là phải trả lại."
					}
				]
			}
		]
	},
	{
		"id": "rat.t1.clever",
		"zodiac": "rat",
		"content_tier": "1",
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "rat",
				"en": "You find a shortcut through someone's yard. What makes it worth taking?",
				"vi": "Bạn tìm lối tắt qua sân người ta. Điều gì khiến nó đáng đi?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Knowing whose fence I'd have to fix afterward.",
				"vi": "Biết mình phải sửa rào cho ai sau đó.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "rat",
						"en": "Good. Show me the whole bill, even the bit on the back.",
						"vi": "Tốt. Cho tôi xem đủ hóa đơn, cả phần ghi mặt sau."
					}
				]
			},
			{
				"id": "B",
				"en": "When I understand where it leads.",
				"vi": "Khi tôi hiểu nó dẫn đến đâu.",
				"delta": 0,
				"reaction": [
					{
						"speaker": "rat",
						"en": "And what you leave behind. Loose nails have a way of finding feet.",
						"vi": "Cả thứ bạn để lại nữa. Đinh rơi giỏi tìm chân người lắm."
					}
				]
			},
			{
				"id": "C",
				"en": "When someone else carries the cost.",
				"vi": "Khi người khác gánh cái giá.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "rat",
						"en": "You've saved yourself a walk and bought them a repair. Clever for whom?",
						"vi": "Bạn đỡ đi xa, họ tốn sửa rào. Khôn cho ai?"
					}
				]
			}
		]
	},
	{
		"id": "rat.t1plus.reuse",
		"zodiac": "rat",
		"content_tier": "1+",
		"relationship_required": 2,
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "rat",
				"en": "What makes a second chance useful?",
				"vi": "Điều gì khiến cơ hội thứ hai có ích?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Using what came back, instead of only collecting it.",
				"vi": "Dùng thứ đã trở về, không chỉ cất thêm.",
				"delta": 1,
				"reaction": []
			},
			{
				"id": "B",
				"en": "Finding where it belongs next.",
				"vi": "Tìm chỗ tiếp theo của nó.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "Calling the return itself a finished job.",
				"vi": "Gọi việc lấy lại là đã làm xong.",
				"delta": -1,
				"reaction": []
			}
		],
		"followup": [
			{
				"speaker": "rat",
				"en": "Next Deal, bring a card back from the discards with a Drink, then play that same card. Give the return a use.",
				"vi": "Ván tới dùng Đồ uống lấy lại một lá từ bài bỏ, rồi hạ chính nó. Cho việc trở về một công dụng nhé."
			}
		],
		"promise": {
			"id": "rat.reuse",
			"polarity": "DO",
			"interaction": "deal_action",
			"target_kind": "ACTION",
			"window": "NEXT_DEAL",
			"deal_phase": 0,
			"condition": "recover_then_play",
			"recovery_source": "discard",
			"en": "During the next Deal, use Nhân Trần or Đen Đá to recover a physical card from the discards, then commit that same card in a successful Meld or Extension. A draw, a swap-out card, or a play before recovery does not count.",
			"vi": "Trong Ván kế tiếp, dùng Nhân Trần hoặc Đen Đá lấy lại một lá từ bài bỏ, rồi hạ chính lá đó vào Phỏm hoặc Nối thành công. Rút bài, lá đưa ra khi đổi, hoặc hạ trước khi lấy lại không được tính."
		},
		"responses": {
			"ACCEPT": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "rat",
						"en": "The same card, recovered then played. I know my finds by their scratches.",
						"vi": "Đúng lá ấy, lấy lại rồi chơi. Tôi nhận đồ nhặt được qua từng vết xước."
					}
				]
			},
			"REFUSE": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "rat",
						"en": "Then leave the second chance unclaimed.",
						"vi": "Vậy cứ để cơ hội thứ hai chưa nhận."
					}
				]
			},
			"HAGGLE": {
				"delta": 0,
				"strategy": "ALTERNATE_ACTION",
				"terms": {
					"id": "rat.reuse",
					"polarity": "DO",
					"interaction": "deal_action",
					"target_kind": "ACTION",
					"window": "NEXT_DEAL",
					"deal_phase": 0,
					"condition": "recover_then_play",
					"recovery_source": "any",
					"en": "During the next Deal, recover a physical card with Nhân Trần, Đen Đá, Nước Vối, or Nâu Đá, then commit that same card in a successful Meld or Extension. The recovered card must be newly committed after its return.",
					"vi": "Trong Ván kế tiếp, lấy lại một lá bằng Nhân Trần, Đen Đá, Nước Vối hoặc Nâu Đá, rồi hạ chính lá đó vào Phỏm hoặc Nối thành công. Lá được lấy lại phải được hạ mới sau khi trở về."
				},
				"dialogue": [
					{
						"speaker": "rat",
						"en": "Let a Meld recovery count too: Nước Vối or Nâu Đá, as well as the discard swaps. Same physical card, played afterward. Confirm that version.",
						"vi": "Tính cả lấy lại từ Phỏm nhé: Nước Vối hoặc Nâu Đá, cùng các lần đổi bài bỏ. Vẫn chính lá đó, hạ sau khi lấy lại. Xác nhận điều kiện đó nhé."
					}
				]
			},
			"COUNTER_REFUSE": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "rat",
						"en": "Then keep the possibility open. I won't take a promise you don't have.",
						"vi": "Vậy cứ để ngỏ khả năng. Tôi không lấy lời hứa bạn chưa có đâu."
					}
				]
			}
		},
		"outcomes": {
			"FULFILLED": {
				"delta": 1,
				"dialogue": [
					{
						"speaker": "rat",
						"en": "Back from the pile and useful again. That's a good find.",
						"vi": "Từ chồng bài trở lại, rồi có ích lần nữa. Nhặt được món tốt đấy."
					}
				]
			},
			"BROKEN": {
				"delta": -1,
				"dialogue": [
					{
						"speaker": "rat",
						"en": "Recovered, perhaps. Used again, no. I've enough unfinished repairs of my own.",
						"vi": "Có thể đã lấy lại. Nhưng chưa dùng tiếp. Đồ sửa dở của tôi cũng đủ nhiều rồi."
					}
				]
			}
		}
	},
	{
		"id": "rat.t1plus.extend",
		"zodiac": "rat",
		"content_tier": "1+",
		"relationship_required": 2,
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "rat",
				"en": "How much can you make from something already on the table?",
				"vi": "Bạn làm thêm được bao nhiêu từ thứ đã trên bàn?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "More, if I actually add something to it.",
				"vi": "Thêm được, nếu tôi thực sự góp thêm.",
				"delta": 1,
				"reaction": []
			},
			{
				"id": "B",
				"en": "It depends on the room it leaves.",
				"vi": "Tùy nó chừa chỗ ra sao.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "Enough if I count the old parts again.",
				"vi": "Đủ nếu tôi đếm lại phần cũ.",
				"delta": -1,
				"reaction": []
			}
		],
		"followup": [
			{
				"speaker": "rat",
				"en": "Add two different cards through Extensions next Deal. New pieces, not the same piece counted twice.",
				"vi": "Ván tới thêm hai lá khác nhau bằng Nối nhé. Phần mới, không phải một phần đếm hai lần."
			}
		],
		"promise": {
			"id": "rat.extend",
			"polarity": "DO",
			"interaction": "deal_action",
			"target_kind": "ACTION",
			"window": "NEXT_DEAL",
			"deal_phase": 0,
			"condition": "extension_cards",
			"card_count": 2,
			"en": "In the next Deal, newly add at least two different physical cards through successful Extensions. They can enter different Melds or Phases. Adding the same recovered card again counts only once; old Meld cards do not count.",
			"vi": "Trong Ván kế tiếp, thêm mới ít nhất hai lá vật lý khác nhau bằng Nối thành công. Có thể vào Phỏm hoặc Hiệp khác nhau. Lấy lại rồi thêm cùng một lá chỉ tính một lần; lá đã trong Phỏm không tính."
		},
		"responses": {
			"ACCEPT": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "rat",
						"en": "Two different cards. Moving the same coin between pockets won't fool me.",
						"vi": "Hai lá khác nhau. Chuyển một đồng qua hai túi không lừa được tôi."
					}
				]
			},
			"REFUSE": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "rat",
						"en": "Then keep the table open without promising an addition.",
						"vi": "Vậy cứ để bàn mở mà chưa hứa thêm."
					}
				]
			},
			"HAGGLE": {
				"delta": 0,
				"strategy": "ALTERNATE_ACTION",
				"terms": {
					"id": "rat.extend",
					"polarity": "DO",
					"interaction": "deal_action",
					"target_kind": "ACTION",
					"window": "NEXT_DEAL",
					"deal_phase": 0,
					"condition": "extension_cards",
					"card_count": 1,
					"en": "In the next Deal, newly add at least one physical card through a successful Extension. Cards already in the Meld do not count.",
					"vi": "Trong Ván kế tiếp, thêm mới ít nhất một lá vật lý bằng Nối thành công. Lá đã trong Phỏm không được tính."
				},
				"dialogue": [
					{
						"speaker": "rat",
						"en": "One newly added card instead of two. Still an actual Extension. Read that smaller job before you agree.",
						"vi": "Một lá mới thêm thay vì hai. Vẫn là Nối thực sự. Đọc việc nhỏ hơn rồi hãy nhận."
					}
				]
			},
			"COUNTER_REFUSE": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "rat",
						"en": "Then keep the possibility open. I won't take a promise you don't have.",
						"vi": "Vậy cứ để ngỏ khả năng. Tôi không lấy lời hứa bạn chưa có đâu."
					}
				]
			}
		},
		"outcomes": {
			"FULFILLED": {
				"delta": 1,
				"dialogue": [
					{
						"speaker": "rat",
						"en": "New pieces on the old work. Better than throwing out a perfectly good beginning.",
						"vi": "Thêm phần mới vào việc cũ. Hơn là vứt một khởi đầu còn tốt."
					}
				]
			},
			"BROKEN": {
				"delta": -1,
				"dialogue": [
					{
						"speaker": "rat",
						"en": "Not enough different additions. I counted the cards, not the trips they made.",
						"vi": "Chưa đủ lá khác nhau được thêm. Tôi đếm lá, không đếm số chuyến chúng đi."
					}
				]
			}
		}
	},
	{
		"id": "rat.t1plus.card",
		"zodiac": "rat",
		"content_tier": "1+",
		"relationship_required": 2,
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "rat",
				"en": "If you choose one thing to give another use, what do you owe it?",
				"vi": "Nếu chọn một thứ để dùng lại, bạn cần làm gì với nó?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Follow that actual thing through the return.",
				"vi": "Theo chính thứ đó suốt lần trở về.",
				"delta": 1,
				"reaction": []
			},
			{
				"id": "B",
				"en": "A chance, if I can find one.",
				"vi": "Cơ hội, nếu tôi tìm được.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "A replacement that looks close enough.",
				"vi": "Vật thay thế trông đủ giống.",
				"delta": -1,
				"reaction": []
			}
		],
		"followup": [
			{
				"speaker": "rat",
				"en": "Choose one of these three. Recover it with a Drink next Deal, then play it again. Not a look-alike.",
				"vi": "Chọn một trong ba lá. Ván tới dùng Đồ uống lấy lại nó rồi hạ lại. Không phải lá trông giống."
			}
		],
		"promise": {
			"id": "rat.card",
			"polarity": "DO",
			"interaction": "card_play",
			"target_kind": "CARD",
			"targeting": "ANY",
			"window": "NEXT_DEAL",
			"recover_first": true,
			"recovery_source": "any",
			"en": "Choose a card. During the next Deal, recover that physical card with Nhân Trần, Đen Đá, Nước Vối, or Nâu Đá, then newly commit it in a successful Meld or Extension. Using another card, drawing it, or playing it only before recovery does not count.",
			"vi": "Chọn một lá. Trong Ván kế tiếp, lấy lại chính lá đó bằng Nhân Trần, Đen Đá, Nước Vối hoặc Nâu Đá, rồi hạ mới nó vào Phỏm hoặc Nối thành công. Dùng lá khác, rút nó, hoặc chỉ hạ trước khi lấy lại không được tính."
		},
		"responses": {
			"ACCEPT": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "rat",
						"en": "That one. I'd recognize it anywhere. Bring it back and use it.",
						"vi": "Lá đó. Ở đâu tôi cũng nhận ra. Lấy lại rồi dùng nó nhé."
					}
				]
			},
			"REFUSE": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "rat",
						"en": "Then keep the choice free. No price for saying no.",
						"vi": "Vậy cứ để lựa chọn tự do. Nói không chẳng mất phí."
					}
				]
			}
		},
		"initial_authority": "OFFER_THREE_PLAYER_CHOOSES",
		"outcomes": {
			"FULFILLED": {
				"delta": 1,
				"dialogue": [
					{
						"speaker": "rat",
						"en": "Same card, second use. See? A little history doesn't make something finished.",
						"vi": "Đúng lá ấy, dùng lần nữa. Thấy chưa? Đã qua tay không có nghĩa hết giá trị."
					}
				]
			},
			"BROKEN": {
				"delta": -1,
				"dialogue": [
					{
						"speaker": "rat",
						"en": "That particular card didn't make the round trip into a new play. Similar isn't the same.",
						"vi": "Chính lá đó chưa quay về rồi vào nước bài mới. Giống không phải là một."
					}
				]
			}
		}
	},
	{
		"id": "rat.t2.reuse_memory",
		"zodiac": "rat",
		"content_tier": "2",
		"relationship_required": 3,
		"kind": "QUESTION",
		"memory_key": "rat.reuse",
		"promise_from": "rat.t1plus.reuse",
		"prompts": {
			"FULFILLED": [
				{
					"speaker": "rat",
					"en": "Recovered and used: {target} Did you know its next job before you brought it back?",
					"vi": "Lấy lại rồi dùng: {target} Bạn biết việc tiếp theo của nó trước khi lấy về chứ?"
				}
			],
			"BROKEN": [
				{
					"speaker": "rat",
					"en": "The second use didn't happen: {target} Another thing saved for later. I know that drawer.",
					"vi": "Chưa dùng lần nữa: {target} Lại một món để dành sau. Tôi biết cái ngăn kéo ấy."
				}
			],
			"REFUSED": [
				{
					"speaker": "rat",
					"en": "You passed on this return: {target} No sense bringing something home without room for it, eh?",
					"vi": "Bạn không nhận lần lấy lại này: {target} Mang về mà không có chỗ dùng thì cũng vô ích nhỉ?"
				}
			]
		},
		"answers": [
			{
				"id": "A",
				"en": "What I could play with the card after getting it back.",
				"vi": "Tôi chơi được gì bằng lá ấy sau khi lấy lại.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "rat",
						"en": "Good. A return with somewhere to go. Otherwise it's just another thing in a drawer.",
						"vi": "Tốt. Lấy lại rồi có chỗ dùng. Không thì lại thêm một món trong ngăn kéo."
					}
				]
			},
			{
				"id": "B",
				"en": "Whether I had room for it in my hand.",
				"vi": "Tay tôi có chỗ cho nó không.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "Any draw should have counted as a return.",
				"vi": "Rút lá nào cũng nên tính là lấy lại.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "rat",
						"en": "Fresh from the stock isn't back from anywhere.",
						"vi": "Mới từ chồng bốc ra thì đâu phải quay lại."
					}
				]
			}
		]
	},
	{
		"id": "rat.t2.extend_memory",
		"zodiac": "rat",
		"content_tier": "2",
		"relationship_required": 3,
		"kind": "QUESTION",
		"memory_key": "rat.extend",
		"promise_from": "rat.t1plus.extend",
		"prompts": {
			"FULFILLED": [
				{
					"speaker": "rat",
					"en": "Fresh additions: {target} Amazing what you can do without throwing the old work away.",
					"vi": "Thêm phần mới: {target} Không vứt việc cũ mà vẫn làm được bao nhiêu thứ."
				}
			],
			"BROKEN": [
				{
					"speaker": "rat",
					"en": "Not enough new pieces: {target} Show me what you actually added. I can count slowly.",
					"vi": "Chưa đủ phần mới: {target} Chỉ tôi những lá bạn thật sự thêm. Tôi đếm chậm được."
				}
			],
			"REFUSED": [
				{
					"speaker": "rat",
					"en": "You didn't promise these additions: {target} Keeping a piece for another repair?",
					"vi": "Bạn không hứa thêm các lá này: {target} Để dành cho việc sửa khác à?"
				}
			]
		},
		"answers": [
			{
				"id": "A",
				"en": "I'd count the different cards I really added.",
				"vi": "Tôi đếm những lá khác nhau mình thật sự thêm.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "rat",
						"en": "Then we're counting the same pile. Always a relief.",
						"vi": "Vậy mình đang đếm cùng một đống. Đỡ lo thật."
					}
				]
			},
			{
				"id": "B",
				"en": "Finding another use for each card.",
				"vi": "Tìm thêm cách dùng cho từng lá.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "The same card could count twice if I took it back.",
				"vi": "Cùng một lá tính hai lần được nếu tôi lấy lại.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "rat",
						"en": "Same scratch, same card. I checked.",
						"vi": "Cùng vết xước, cùng lá bài. Tôi xem rồi."
					}
				]
			}
		]
	},
	{
		"id": "rat.t2.card_memory",
		"zodiac": "rat",
		"content_tier": "2",
		"relationship_required": 3,
		"kind": "QUESTION",
		"memory_key": "rat.card",
		"promise_from": "rat.t1plus.card",
		"prompts": {
			"FULFILLED": [
				{
					"speaker": "rat",
					"en": "{target}, back and useful. Recognize it by now? I always get attached around the second repair.",
					"vi": "{target}, trở lại rồi có ích. Giờ quen mặt chưa? Tôi thường quý đồ từ lần sửa thứ hai."
				}
			],
			"BROKEN": [
				{
					"speaker": "rat",
					"en": "{target} didn't finish the return and replay. Where did you leave it?",
					"vi": "{target} chưa lấy lại rồi chơi tiếp xong. Bạn để nó ở đâu?"
				}
			],
			"REFUSED": [
				{
					"speaker": "rat",
					"en": "You didn't promise to bring {target} back. Did you already have another use in mind?",
					"vi": "Bạn không hứa lấy {target} lại. Đã tính dùng kiểu khác rồi à?"
				}
			]
		},
		"answers": [
			{
				"id": "A",
				"en": "I wanted to follow that card, even if another was easier.",
				"vi": "Tôi muốn theo đúng lá ấy, dù lá khác dễ hơn.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "rat",
						"en": "Good. Replacements have their uses. Pretending isn't one of them.",
						"vi": "Tốt. Đồ thay thế có ích. Giả làm đồ gốc thì không."
					}
				]
			},
			{
				"id": "B",
				"en": "I needed to know how I'd get it back.",
				"vi": "Tôi cần biết sẽ lấy nó lại bằng cách nào.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "A card with the same rank should have replaced it.",
				"vi": "Lá cùng hạng nên được thay nó.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "rat",
						"en": "I've got two brass keys. Only one opens my door.",
						"vi": "Tôi có hai chìa đồng. Chỉ một cái mở được cửa nhà."
					}
				]
			}
		]
	},
	{
		"id": "rat.t2.keep",
		"zodiac": "rat",
		"content_tier": "2",
		"relationship_required": 3,
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "rat",
				"en": "I keep a key to a door that isn't there anymore. Anything like that in your pockets?",
				"vi": "Tôi giữ chìa của cánh cửa không còn nữa. Trong túi bạn có thứ nào như vậy không?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Something with a history I don't need to sell.",
				"vi": "Thứ có chuyện cũ mà tôi không cần bán.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "rat",
						"en": "Yes. No buyer needed. That's the bit I keep forgetting.",
						"vi": "Ừ. Không cần người mua. Tôi cứ quên đoạn ấy."
					}
				]
			},
			{
				"id": "B",
				"en": "A few things I haven't understood yet.",
				"vi": "Vài thứ tôi chưa hiểu hết.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "Only things someone will pay for later.",
				"vi": "Chỉ thứ sau này có người trả tiền.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "rat",
						"en": "Then you never get to unpack, do you?",
						"vi": "Vậy bạn chẳng bao giờ được dỡ đồ ra nhỉ?"
					}
				]
			}
		]
	},
	{
		"id": "rat.t2.room",
		"zodiac": "rat",
		"content_tier": "2",
		"relationship_required": 3,
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "rat",
				"en": "I left my bag here while I fetched tea. Haven't done that in years. Would you move it?",
				"vi": "Tôi để túi đây đi lấy trà. Bao năm chưa dám thế. Bạn có chuyển nó không?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "I ask before moving what belongs to you.",
				"vi": "Tôi hỏi trước khi dời thứ thuộc về bạn.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "rat",
						"en": "Thank you. There's nothing valuable. That's not why I ask.",
						"vi": "Cảm ơn. Chẳng có gì đắt tiền. Tôi hỏi không phải vì thế."
					}
				]
			},
			{
				"id": "B",
				"en": "I'll tell you if I need the space.",
				"vi": "Tôi sẽ nói nếu cần chỗ.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "What you don't notice won't matter.",
				"vi": "Thứ bạn không để ý thì chẳng quan trọng.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "rat",
						"en": "I notice. I just don't always say so.",
						"vi": "Tôi có nhận ra. Chỉ không phải lúc nào cũng nói."
					}
				]
			}
		]
	},
	{
		"id": "rat.t2.quiet",
		"zodiac": "rat",
		"content_tier": "2",
		"relationship_required": 3,
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "rat",
				"en": "I'm going to leave that bottle cap on the ground. Don't look so surprised. Can we just have tea?",
				"vi": "Tôi sẽ để nắp chai kia dưới đất. Đừng ngạc nhiên thế. Mình uống trà thôi được không?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Yes. Sitting here can be enough.",
				"vi": "Được. Ngồi đây có thể đã đủ.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "rat",
						"en": "Good. If I reach for it, kick my chair. Gently.",
						"vi": "Được. Tôi mà cúi nhặt thì đá ghế nhắc nhé. Nhẹ thôi."
					}
				]
			},
			{
				"id": "B",
				"en": "For a little while. I still have work later.",
				"vi": "Một lúc thôi. Sau đó tôi vẫn có việc.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "Only if there's something in it for me.",
				"vi": "Chỉ khi có lợi cho tôi.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "rat",
						"en": "There was. An evening. You keep looking past it for something to pocket.",
						"vi": "Có đấy. Một buổi tối. Bạn cứ nhìn qua nó để tìm thứ bỏ túi."
					}
				]
			}
		]
	}
]
