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
			"en": "Rat closes a pocket he has been checking all evening. He leaves a space beside his glass without finding anything to fill it.",
			"vi": "Tý đóng chiếc túi anh đã kiểm tra suốt tối. Anh chừa khoảng cạnh ly mà không tìm thứ gì lấp vào."
		},
		{
			"en": "\"You followed the things you used, and you said no without dressing it up. I don't have to count your company like another find.\"",
			"vi": "\"Bạn đã theo những thứ mình dùng, và nói không mà chẳng tô vẽ. Tôi không phải đếm việc bạn ngồi cùng như món nhặt được nữa.\""
		},
		{
			"en": "He puts a small rat Emblem in the empty space. \"Bring it on our day. This one is yours; I'm not calling it a loan.\"",
			"vi": "Anh đặt Huy hiệu con chuột nhỏ vào khoảng trống. \"Mang theo vào ngày của mình nhé. Cái này là của bạn; tôi không gọi là cho mượn đâu.\""
		}
	],
	"last_chance": {
		"id": "rat.last_chance.account",
		"prompt": [
			{
				"speaker": "rat",
				"en": "Give me a plain account. What can you actually bring back to this table?",
				"vi": "Nói thật cho tôi nghe nhé. Bạn thực sự mang lại gì cho bàn này được?"
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
						"en": "Then there's something honest to work with.",
						"vi": "Vậy còn điều thật để mình tính tiếp."
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
						"en": "Then leave it open. I won't collect a word you don't have.",
						"vi": "Vậy cứ để ngỏ. Tôi không thu lời bạn chưa có đâu."
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
						"en": "Then we'll stop counting your words here.",
						"vi": "Vậy mình dừng tính lời của bạn ở đây."
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
				"en": "A little piece is left after everyone clears the table. What do you see?",
				"vi": "Mọi người dọn bàn rồi còn một mẩu nhỏ. Bạn thấy gì?"
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
						"en": "Good. Small isn't the same as useless.",
						"vi": "Tốt. Nhỏ không có nghĩa là vô dụng."
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
						"en": "Ask before you pocket it.",
						"vi": "Hỏi trước khi bỏ vào túi nhé."
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
						"en": "Not looking isn't permission.",
						"vi": "Không nhìn không có nghĩa là cho phép."
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
				"en": "Someone lends you a tool. What comes back with it?",
				"vi": "Có người cho bạn mượn dụng cụ. Bạn trả lại cùng gì?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "The tool, and an honest account of how I used it.",
				"vi": "Dụng cụ và lời kể thật về cách tôi dùng.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "rat",
						"en": "Then they'll know what they're getting back.",
						"vi": "Vậy họ biết mình đang nhận lại gì."
					}
				]
			},
			{
				"id": "B",
				"en": "Thanks, when I'm done.",
				"vi": "Lời cảm ơn, khi tôi xong.",
				"delta": 0,
				"reaction": [
					{
						"speaker": "rat",
						"en": "Let them know when that will be.",
						"vi": "Cho họ biết khi nào xong nhé."
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
						"en": "Borrowing has an ending.",
						"vi": "Mượn thì có lúc phải trả."
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
				"en": "When is a clever shortcut worth taking?",
				"vi": "Khi nào lối tắt khéo léo đáng đi?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "When I can show who pays for it.",
				"vi": "Khi tôi nói rõ được ai chịu cái giá.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "rat",
						"en": "Then it's a choice we can inspect.",
						"vi": "Vậy đó là lựa chọn mình xem rõ được."
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
						"en": "Look behind you too.",
						"vi": "Nhớ nhìn cả phía sau."
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
						"en": "That isn't a saving for everyone.",
						"vi": "Vậy đâu phải ai cũng tiết kiệm."
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
						"en": "The recovered card itself has to enter a play. I'll follow that one.",
						"vi": "Chính lá được lấy lại phải vào nước hạ. Tôi sẽ theo lá đó."
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
						"en": "The card came back and found a new play. You made the second chance useful.",
						"vi": "Lá bài đã trở về rồi tìm được nước hạ mới. Bạn đã làm cơ hội thứ hai có ích."
					}
				]
			},
			"BROKEN": {
				"delta": -1,
				"dialogue": [
					{
						"speaker": "rat",
						"en": "A recovered card didn't reach the promised new play. Bringing something back wasn't the whole job.",
						"vi": "Chưa có lá được lấy lại vào nước hạ mới đã hứa. Lấy về chưa phải trọn việc."
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
						"en": "Different physical cards. I'll count what you add.",
						"vi": "Các lá vật lý khác nhau. Tôi tính phần bạn thêm."
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
						"en": "You added the different cards we agreed. The old table made room for something new.",
						"vi": "Bạn đã thêm những lá khác nhau đã thống nhất. Bàn cũ có chỗ cho phần mới."
					}
				]
			},
			"BROKEN": {
				"delta": -1,
				"dialogue": [
					{
						"speaker": "rat",
						"en": "The Extensions didn't add enough different cards. Reusing a card couldn't make it another one.",
						"vi": "Nối chưa thêm đủ lá khác nhau. Dùng lại một lá không biến nó thành lá khác."
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
						"en": "Your pick. The return and the later play have to belong to that card.",
						"vi": "Bạn chọn nhé. Lần lấy lại và nước hạ sau phải thuộc chính lá đó."
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
						"en": "Your chosen card returned and entered a new play. You kept track of the real thing.",
						"vi": "Lá bạn chọn đã trở về rồi vào nước hạ mới. Bạn đã theo đúng lá thật."
					}
				]
			},
			"BROKEN": {
				"delta": -1,
				"dialogue": [
					{
						"speaker": "rat",
						"en": "That card didn't complete the return and later play. Another card couldn't stand in for it.",
						"vi": "Lá đó chưa hoàn thành lần lấy lại rồi hạ sau. Lá khác không thay nó được."
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
					"en": "You made this second chance useful: {target} What changed when the card returned?",
					"vi": "Bạn đã làm cơ hội thứ hai này có ích: {target} Lá trở về rồi điều gì đổi?"
				}
			],
			"BROKEN": [
				{
					"speaker": "rat",
					"en": "This second chance stopped short: {target} What would you leave clearer next time?",
					"vi": "Cơ hội thứ hai này còn dở: {target} Lần tới bạn sẽ nói rõ thêm gì?"
				}
			],
			"REFUSED": [
				{
					"speaker": "rat",
					"en": "You didn't promise this return: {target} What needed to stay open?",
					"vi": "Bạn không hứa lần trở về này: {target} Điều gì cần để ngỏ?"
				}
			]
		},
		"answers": [
			{
				"id": "A",
				"en": "Whether the recovered card actually got a later play.",
				"vi": "Lá được lấy lại có thực sự được hạ sau đó không.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "rat",
						"en": "Then the second chance has a path we can see.",
						"vi": "Vậy cơ hội thứ hai có đường mình nhìn được."
					}
				]
			},
			{
				"id": "B",
				"en": "What my hand could make room for.",
				"vi": "Bài tôi chừa chỗ được cho gì.",
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
						"en": "A new draw wasn't the return we named.",
						"vi": "Lá rút mới không phải lần lấy lại mình đã nói."
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
					"en": "You added what we agreed: {target} What did the old table make possible?",
					"vi": "Bạn đã thêm phần đã thống nhất: {target} Bàn cũ đã mở ra điều gì?"
				}
			],
			"BROKEN": [
				{
					"speaker": "rat",
					"en": "We didn't add the promised pieces: {target} Which ones were really new?",
					"vi": "Mình chưa thêm đủ phần đã hứa: {target} Phần nào thực sự mới?"
				}
			],
			"REFUSED": [
				{
					"speaker": "rat",
					"en": "You left this addition unpromised: {target} What did you keep room for?",
					"vi": "Bạn chưa hứa phần thêm này: {target} Bạn chừa chỗ cho gì?"
				}
			]
		},
		"answers": [
			{
				"id": "A",
				"en": "The different cards actually added.",
				"vi": "Những lá khác nhau thực sự thêm vào.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "rat",
						"en": "Then the account fits the table.",
						"vi": "Vậy lời kể khớp với bàn."
					}
				]
			},
			{
				"id": "B",
				"en": "The next useful place for each card.",
				"vi": "Chỗ có ích tiếp theo của từng lá.",
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
						"en": "Returning it doesn't create another physical card.",
						"vi": "Lấy lại không tạo ra lá vật lý khác."
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
					"en": "This was the card you brought back to use: {target} What made you choose it?",
					"vi": "Đây là lá bạn lấy lại để dùng: {target} Điều gì khiến bạn chọn nó?"
				}
			],
			"BROKEN": [
				{
					"speaker": "rat",
					"en": "This card didn't complete its second use: {target} Where did its path end?",
					"vi": "Lá này chưa dùng lại được như hứa: {target} Đường của nó dừng ở đâu?"
				}
			],
			"REFUSED": [
				{
					"speaker": "rat",
					"en": "You didn't bind this card to a return: {target} Did it find another place?",
					"vi": "Bạn không buộc lá này phải trở về: {target} Nó có tìm được chỗ khác không?"
				}
			]
		},
		"answers": [
			{
				"id": "A",
				"en": "Its real path, even when another card was easier.",
				"vi": "Đường thật của nó, kể cả khi lá khác dễ hơn.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "rat",
						"en": "Then you weren't hiding it behind a substitute.",
						"vi": "Vậy bạn không giấu nó sau lá thay thế."
					}
				]
			},
			{
				"id": "B",
				"en": "I needed to see what could recover it.",
				"vi": "Tôi cần xem điều gì lấy lại nó được.",
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
						"en": "The rank wasn't the whole thing you chose.",
						"vi": "Hạng không phải toàn bộ thứ bạn đã chọn."
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
				"en": "Is there anything you keep that nobody else would bother with?",
				"vi": "Bạn có giữ thứ gì mà người khác chẳng buồn giữ không?"
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
						"en": "Then it doesn't need a price to stay.",
						"vi": "Vậy nó không cần giá để ở lại."
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
						"en": "Then you're keeping a market, not a memory.",
						"vi": "Vậy bạn đang giữ chợ, không giữ kỷ niệm."
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
				"en": "If I leave my things here, what makes this a place I can trust?",
				"vi": "Nếu để đồ ở đây, điều gì khiến tôi tin được chỗ này?"
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
						"en": "Small things have owners too.",
						"vi": "Thứ nhỏ cũng có chủ."
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
						"en": "That's where trust starts getting lost.",
						"vi": "Niềm tin bắt đầu mất từ chỗ đó."
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
				"en": "Can we leave this evening without trying to get one more thing from it?",
				"vi": "Mình để tối nay trôi mà không cố lấy thêm gì được không?"
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
						"en": "Then I'll put the pockets away for a while.",
						"vi": "Vậy tôi thôi nghĩ đến túi một lúc."
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
						"en": "I was asking you to stay, not to collect.",
						"vi": "Tôi đang xin bạn ở lại, không xin bạn thu thêm."
					}
				]
			}
		]
	}
]
