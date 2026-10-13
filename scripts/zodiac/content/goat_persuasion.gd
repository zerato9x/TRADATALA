extends RefCounted
## Goat listens for distinct voices, neighboring notes, and honest silences.
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
				"goat.notes",
				"goat.run",
				"goat.card"
			]
		}
	],
	"memory_button": {
		"en": "Goat's notebook",
		"vi": "Sổ của Mùi"
	},
	"memory_title": {
		"en": "What Goat remembers",
		"vi": "Điều Mùi nhớ"
	},
	"memory_topics": {
		"goat.notes": {
			"en": "Different voices",
			"vi": "Các giọng khác nhau"
		},
		"goat.run": {
			"en": "A committed phrase",
			"vi": "Câu đã hạ"
		},
		"goat.card": {
			"en": "A note and its neighbor",
			"vi": "Nốt và bạn liền kề"
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
			"en": "Goat closes the notebook without filling the last line. She listens to the glasses settle, then leaves the chair beside her open.",
			"vi": "Mùi gấp sổ lại mà không viết hết dòng cuối. Cô nghe tiếng ly lắng xuống rồi để trống ghế bên cạnh."
		},
		{
			"en": "\"You let different notes belong, and you didn't dress the missing ones in new words. I can hear you here.\"",
			"vi": "\"Bạn để các nốt khác nhau có chỗ, và không khoác lời mới lên nốt thiếu. Tôi nghe bạn ở đây được.\""
		},
		{
			"en": "She leaves a small goat Emblem on the blank line. \"Bring it when our day comes. We can begin with the quiet.\"",
			"vi": "Cô để Huy hiệu con dê nhỏ lên dòng trống. \"Đến ngày của mình thì mang theo nhé. Ta có thể bắt đầu bằng khoảng yên.\""
		}
	],
	"last_chance": {
		"id": "goat.last_chance.listen",
		"prompt": [
			{
				"speaker": "goat",
				"en": "Leave a little quiet. What are you trying to tell me?",
				"vi": "Chừa chút yên nhé. Bạn đang muốn nói gì với tôi?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "I was answering before I listened.",
				"vi": "Tôi đã trả lời trước khi nghe.",
				"recovery_success": true,
				"reaction": [
					{
						"speaker": "goat",
						"en": "Then listen now. There is still a little room.",
						"vi": "Vậy giờ nghe nhé. Vẫn còn chút khoảng."
					}
				]
			},
			{
				"id": "B",
				"en": "I don't have another promise to give today.",
				"vi": "Hôm nay tôi không có lời hứa khác để cho.",
				"recovery_success": true,
				"reaction": [
					{
						"speaker": "goat",
						"en": "Then let that be the whole answer.",
						"vi": "Vậy cứ để đó là trọn câu trả lời."
					}
				]
			},
			{
				"id": "C",
				"en": "Whatever tune makes tonight easier for me.",
				"vi": "Giai điệu nào khiến tối nay dễ hơn cho tôi.",
				"recovery_success": false,
				"reaction": [
					{
						"speaker": "goat",
						"en": "Then the listening can end here.",
						"vi": "Vậy mình dừng lắng nghe ở đây."
					}
				]
			}
		]
	},
	"special": []
}
const NODES := [
	{
		"id": "goat.t1.listen",
		"zodiac": "goat",
		"content_tier": "1",
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "goat",
				"en": "A quiet note gets lost under the table noise. How do you hear it?",
				"vi": "Một nốt nhỏ bị tiếng bàn che mất. Bạn nghe nó bằng cách nào?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Leave a little quiet before answering.",
				"vi": "Chừa chút yên trước khi trả lời.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "goat",
						"en": "Then it has somewhere to land.",
						"vi": "Vậy nó có chỗ để đến."
					}
				]
			},
			{
				"id": "B",
				"en": "Ask to hear it once more.",
				"vi": "Xin nghe thêm một lần.",
				"delta": 0,
				"reaction": [
					{
						"speaker": "goat",
						"en": "Ask gently. It was there already.",
						"vi": "Hỏi nhẹ thôi. Nó vốn ở đó rồi."
					}
				]
			},
			{
				"id": "C",
				"en": "Make my own sound louder.",
				"vi": "Làm tiếng mình to hơn.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "goat",
						"en": "Then we lose it twice.",
						"vi": "Vậy mình làm mất nó hai lần."
					}
				]
			}
		]
	},
	{
		"id": "goat.t1.difference",
		"zodiac": "goat",
		"content_tier": "1",
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "goat",
				"en": "Two voices don't sound alike. Must one change?",
				"vi": "Hai giọng không giống nhau. Có nhất thiết một giọng phải đổi không?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "They can find room beside each other.",
				"vi": "Họ có thể tìm chỗ bên nhau.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "goat",
						"en": "A harmony needs more than one voice.",
						"vi": "Hòa âm cần nhiều hơn một giọng."
					}
				]
			},
			{
				"id": "B",
				"en": "It depends on what they're trying to sing.",
				"vi": "Tùy họ đang muốn hát gì.",
				"delta": 0,
				"reaction": [
					{
						"speaker": "goat",
						"en": "Then ask them first.",
						"vi": "Vậy hỏi họ trước nhé."
					}
				]
			},
			{
				"id": "C",
				"en": "The softer voice should copy the louder one.",
				"vi": "Giọng nhỏ nên bắt chước giọng lớn.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "goat",
						"en": "Loudness doesn't choose the tune.",
						"vi": "Âm lượng không chọn giai điệu."
					}
				]
			}
		]
	},
	{
		"id": "goat.t1.pause",
		"zodiac": "goat",
		"content_tier": "1",
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "goat",
				"en": "What belongs between two notes?",
				"vi": "Giữa hai nốt nên có gì?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Enough space to hear both.",
				"vi": "Đủ khoảng để nghe cả hai.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "goat",
						"en": "Even a small rest can belong.",
						"vi": "Một khoảng nghỉ nhỏ cũng có chỗ."
					}
				]
			},
			{
				"id": "B",
				"en": "Whatever makes the next one possible.",
				"vi": "Điều giúp nốt tiếp theo đến được.",
				"delta": 0,
				"reaction": [
					{
						"speaker": "goat",
						"en": "Keep an ear on the one before it.",
						"vi": "Nhớ lắng nghe nốt trước đó."
					}
				]
			},
			{
				"id": "C",
				"en": "Nothing. Gaps are mistakes.",
				"vi": "Không gì cả. Khoảng trống là lỗi.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "goat",
						"en": "Then breathing would be a mistake too.",
						"vi": "Vậy thở cũng thành lỗi rồi."
					}
				]
			}
		]
	},
	{
		"id": "goat.t1plus.notes",
		"zodiac": "goat",
		"content_tier": "1+",
		"relationship_required": 2,
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "goat",
				"en": "How do you know you've heard more than one voice?",
				"vi": "Làm sao bạn biết mình đã nghe nhiều hơn một giọng?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "I can name the differences I heard.",
				"vi": "Tôi nói rõ được những khác biệt đã nghe.",
				"delta": 1,
				"reaction": []
			},
			{
				"id": "B",
				"en": "I notice when the sound changes.",
				"vi": "Tôi để ý khi âm thanh đổi.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "I count the same sound again.",
				"vi": "Tôi đếm lại cùng một âm.",
				"delta": -1,
				"reaction": []
			}
		],
		"followup": [
			{
				"speaker": "goat",
				"en": "Next Deal, score with three different printed ranks. Repeating one note won't make three voices.",
				"vi": "Ván tới ghi điểm bằng ba hạng in khác nhau nhé. Lặp một nốt không thành ba giọng."
			}
		],
		"promise": {
			"id": "goat.notes",
			"polarity": "DO",
			"interaction": "deal_action",
			"target_kind": "ACTION",
			"window": "NEXT_DEAL",
			"deal_phase": 0,
			"condition": "distinct_ranks",
			"rank_count": 3,
			"en": "During the next Deal, score positive points with at least three different printed ranks across successful Melds or Extensions. Extensions count only newly added cards. Repeated ranks count once; discarded cards do not count.",
			"vi": "Trong Ván kế tiếp, ghi điểm dương bằng ít nhất ba hạng in khác nhau qua Phỏm hoặc Nối thành công. Nối chỉ tính lá mới thêm. Hạng lặp chỉ tính một lần; lá bỏ không được tính."
		},
		"responses": {
			"ACCEPT": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "goat",
						"en": "I'll count each new rank once, from the cards you actually commit.",
						"vi": "Tôi tính mỗi hạng mới một lần, từ lá bạn thực sự hạ."
					}
				]
			},
			"REFUSE": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "goat",
						"en": "Then keep your ear open without giving your word.",
						"vi": "Vậy cứ lắng nghe mà chưa cần hứa."
					}
				]
			},
			"HAGGLE": {
				"delta": 0,
				"strategy": "ALTERNATE_ACTION",
				"terms": {
					"id": "goat.notes",
					"polarity": "DO",
					"interaction": "deal_action",
					"target_kind": "ACTION",
					"window": "NEXT_DEAL",
					"deal_phase": 0,
					"condition": "distinct_ranks",
					"rank_count": 2,
					"en": "During the next Deal, score positive points with at least two different printed ranks across successful Melds or Extensions. Extensions count only newly added cards; repeated ranks count once.",
					"vi": "Trong Ván kế tiếp, ghi điểm dương bằng ít nhất hai hạng in khác nhau qua Phỏm hoặc Nối thành công. Nối chỉ tính lá mới thêm; hạng lặp chỉ tính một lần."
				},
				"dialogue": [
					{
						"speaker": "goat",
						"en": "Two different scoring ranks instead of three. The same rule for newly committed cards. Confirm if that's your range.",
						"vi": "Hai hạng ghi điểm khác nhau thay vì ba. Vẫn chỉ tính lá mới hạ. Nếu vừa sức thì xác nhận nhé."
					}
				]
			},
			"COUNTER_REFUSE": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "goat",
						"en": "Then leave the notes unwritten. A clear no is enough.",
						"vi": "Vậy cứ để các nốt chưa viết. Nói không rõ ràng là đủ."
					}
				]
			}
		},
		"outcomes": {
			"FULFILLED": {
				"delta": 1,
				"dialogue": [
					{
						"speaker": "goat",
						"en": "The different ranks we agreed found a scoring voice. You heard more than the echo.",
						"vi": "Các hạng khác nhau đã thống nhất đều ghi điểm. Bạn nghe được hơn tiếng vọng."
					}
				]
			},
			"BROKEN": {
				"delta": -1,
				"dialogue": [
					{
						"speaker": "goat",
						"en": "The promised number of different scoring ranks wasn't there. Repeating a rank couldn't fill the gap.",
						"vi": "Chưa có đủ hạng ghi điểm khác nhau đã hứa. Lặp một hạng không lấp được khoảng thiếu."
					}
				]
			}
		}
	},
	{
		"id": "goat.t1plus.run",
		"zodiac": "goat",
		"content_tier": "1+",
		"relationship_required": 2,
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "goat",
				"en": "What lets one note meet the next?",
				"vi": "Điều gì giúp một nốt gặp nốt kế tiếp?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "A relation I can hear between them.",
				"vi": "Mối liên hệ tôi nghe được giữa chúng.",
				"delta": 1,
				"reaction": []
			},
			{
				"id": "B",
				"en": "Trying them beside each other.",
				"vi": "Thử đặt chúng bên nhau.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "Saying they're a tune because I want them to be.",
				"vi": "Gọi chúng là giai điệu vì tôi muốn thế.",
				"delta": -1,
				"reaction": []
			}
		],
		"followup": [
			{
				"speaker": "goat",
				"en": "Commit three consecutive printed ranks together next Deal. For an Extension, let the new notes carry the phrase.",
				"vi": "Ván tới hạ cùng lúc ba hạng in liên tiếp nhé. Với Nối, để các nốt mới tạo thành câu."
			}
		],
		"promise": {
			"id": "goat.run",
			"polarity": "DO",
			"interaction": "deal_action",
			"target_kind": "ACTION",
			"window": "NEXT_DEAL",
			"deal_phase": 0,
			"condition": "rank_run",
			"rank_count": 3,
			"en": "In one successful Meld or Extension during the next Deal, commit at least three different printed ranks in consecutive order. For Extensions, only newly added cards count. K and A are not consecutive for this promise.",
			"vi": "Trong một nước Phỏm hoặc Nối thành công của Ván kế tiếp, hạ ít nhất ba hạng in khác nhau liên tiếp. Với Nối, chỉ tính lá mới thêm. K và A không liền nhau trong lời hứa này."
		},
		"responses": {
			"ACCEPT": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "goat",
						"en": "One committed phrase. I won't borrow notes already on the table.",
						"vi": "Một câu được hạ cùng nhau. Tôi không mượn nốt đã ở trên bàn."
					}
				]
			},
			"REFUSE": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "goat",
						"en": "Then leave room to find the phrase first.",
						"vi": "Vậy cứ chừa chỗ để tìm câu ấy trước."
					}
				]
			},
			"HAGGLE": {
				"delta": 0,
				"strategy": "ALTERNATE_ACTION",
				"terms": {
					"id": "goat.run",
					"polarity": "DO",
					"interaction": "deal_action",
					"target_kind": "ACTION",
					"window": "NEXT_DEAL",
					"deal_phase": 0,
					"condition": "rank_run",
					"rank_count": 2,
					"en": "In one successful Meld or Extension during the next Deal, commit at least two different printed ranks in consecutive order. For Extensions, only newly added cards count. K and A are not consecutive for this promise.",
					"vi": "Trong một nước Phỏm hoặc Nối thành công của Ván kế tiếp, hạ ít nhất hai hạng in khác nhau liên tiếp. Với Nối, chỉ tính lá mới thêm. K và A không liền nhau trong lời hứa này."
				},
				"dialogue": [
					{
						"speaker": "goat",
						"en": "Two consecutive printed ranks in one action will do. Existing Meld cards still don't count. Read that before agreeing.",
						"vi": "Hai hạng in liên tiếp trong một nước là đủ. Lá đã trong Phỏm vẫn không tính. Đọc điều đó rồi hãy nhận."
					}
				]
			},
			"COUNTER_REFUSE": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "goat",
						"en": "Then leave the notes unwritten. A clear no is enough.",
						"vi": "Vậy cứ để các nốt chưa viết. Nói không rõ ràng là đủ."
					}
				]
			}
		},
		"outcomes": {
			"FULFILLED": {
				"delta": 1,
				"dialogue": [
					{
						"speaker": "goat",
						"en": "You committed the consecutive ranks together. The phrase had its own beginning and end.",
						"vi": "Bạn đã hạ các hạng liên tiếp cùng nhau. Câu có khởi đầu và kết thúc riêng."
					}
				]
			},
			"BROKEN": {
				"delta": -1,
				"dialogue": [
					{
						"speaker": "goat",
						"en": "The consecutive ranks weren't newly committed together. Notes already on the table couldn't complete that promise.",
						"vi": "Các hạng liên tiếp chưa được hạ mới cùng nhau. Nốt đã trên bàn không hoàn thành lời hứa đó."
					}
				]
			}
		}
	},
	{
		"id": "goat.t1plus.card",
		"zodiac": "goat",
		"content_tier": "1+",
		"relationship_required": 2,
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "goat",
				"en": "If a note could choose its company, what would you offer?",
				"vi": "Nếu một nốt chọn được bạn đi cùng, bạn sẽ cho nó gì?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "A neighbor it can actually meet.",
				"vi": "Nốt liền kề mà nó thực sự gặp được.",
				"delta": 1,
				"reaction": []
			},
			{
				"id": "B",
				"en": "A place where I can hear it clearly.",
				"vi": "Chỗ để tôi nghe nó rõ.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "An old neighbor and call the meeting new.",
				"vi": "Bạn cũ rồi gọi lần gặp là mới.",
				"delta": -1,
				"reaction": []
			}
		],
		"followup": [
			{
				"speaker": "goat",
				"en": "Choose one of these three. Next Deal, commit it with an adjacent printed rank in the same action. Both must be new to that play.",
				"vi": "Chọn một trong ba lá này. Ván tới hạ nó cùng hạng in liền kề trong một nước. Cả hai phải mới trong nước ấy."
			}
		],
		"promise": {
			"id": "goat.card",
			"polarity": "DO",
			"interaction": "card_play",
			"target_kind": "CARD",
			"targeting": "ANY",
			"window": "NEXT_DEAL",
			"adjacent_rank": true,
			"en": "Choose a card and commit it together with a card of an adjacent printed rank in one successful Meld or Extension during the next Deal. Both cards must be newly committed in that action. K and A are not adjacent for this promise.",
			"vi": "Chọn một lá rồi hạ nó cùng lá có hạng in liền kề trong một nước Phỏm hoặc Nối thành công của Ván kế tiếp. Cả hai lá phải được hạ mới trong nước đó. K và A không liền kề trong lời hứa này."
		},
		"responses": {
			"ACCEPT": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "goat",
						"en": "I'll remember the card you chose, and the neighbor committed with it.",
						"vi": "Tôi sẽ nhớ lá bạn chọn và lá liền kề hạ cùng nó."
					}
				]
			},
			"REFUSE": {
				"delta": 0,
				"dialogue": [
					{
						"speaker": "goat",
						"en": "Then let it wait for company you haven't promised.",
						"vi": "Vậy để nó đợi bạn đi cùng mà bạn chưa hứa."
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
						"speaker": "goat",
						"en": "Your chosen card met an adjacent rank in the same committed play.",
						"vi": "Lá bạn chọn đã gặp hạng liền kề trong cùng nước hạ."
					}
				]
			},
			"BROKEN": {
				"delta": -1,
				"dialogue": [
					{
						"speaker": "goat",
						"en": "That card didn't meet a newly committed neighbor. A card already in the Meld wasn't new company.",
						"vi": "Lá đó chưa gặp lá liền kề mới hạ. Lá vốn trong Phỏm không phải bạn mới."
					}
				]
			}
		}
	},
	{
		"id": "goat.t2.notes_memory",
		"zodiac": "goat",
		"content_tier": "2",
		"relationship_required": 3,
		"kind": "QUESTION",
		"memory_key": "goat.notes",
		"promise_from": "goat.t1plus.notes",
		"prompts": {
			"FULFILLED": [
				{
					"speaker": "goat",
					"en": "I heard the different ranks you promised: {target} Which difference stayed with you?",
					"vi": "Tôi đã nghe những hạng khác nhau bạn hứa: {target} Khác biệt nào ở lại với bạn?"
				}
			],
			"BROKEN": [
				{
					"speaker": "goat",
					"en": "We didn't hear all the promised ranks: {target} What would you listen for next time?",
					"vi": "Mình chưa nghe đủ hạng đã hứa: {target} Lần tới bạn sẽ lắng nghe điều gì?"
				}
			],
			"REFUSED": [
				{
					"speaker": "goat",
					"en": "You left these notes unpromised: {target} What did you need to hear first?",
					"vi": "Bạn chưa hứa các nốt này: {target} Bạn cần nghe điều gì trước?"
				}
			]
		},
		"answers": [
			{
				"id": "A",
				"en": "The ranks actually played, without counting an echo twice.",
				"vi": "Những hạng thực sự hạ, không đếm tiếng vọng hai lần.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "goat",
						"en": "Then each voice keeps its own place.",
						"vi": "Vậy mỗi giọng giữ được chỗ riêng."
					}
				]
			},
			{
				"id": "B",
				"en": "The room my hand left for another rank.",
				"vi": "Chỗ bài tôi chừa cho hạng khác.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "The same rank should sound different every time.",
				"vi": "Cùng một hạng mỗi lần nên được xem là khác.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "goat",
						"en": "An echo can be lovely without becoming another voice.",
						"vi": "Tiếng vọng vẫn đẹp dù không thành giọng khác."
					}
				]
			}
		]
	},
	{
		"id": "goat.t2.run_memory",
		"zodiac": "goat",
		"content_tier": "2",
		"relationship_required": 3,
		"kind": "QUESTION",
		"memory_key": "goat.run",
		"promise_from": "goat.t1plus.run",
		"prompts": {
			"FULFILLED": [
				{
					"speaker": "goat",
					"en": "This phrase came together: {target} What joined its notes?",
					"vi": "Câu này đã thành hình: {target} Điều gì nối các nốt?"
				}
			],
			"BROKEN": [
				{
					"speaker": "goat",
					"en": "The phrase didn't meet these terms: {target} Where did the notes separate?",
					"vi": "Câu chưa đáp ứng điều kiện này: {target} Các nốt tách ở đâu?"
				}
			],
			"REFUSED": [
				{
					"speaker": "goat",
					"en": "You didn't promise this phrase: {target} What needed more room?",
					"vi": "Bạn không hứa câu này: {target} Điều gì cần thêm khoảng?"
				}
			]
		},
		"answers": [
			{
				"id": "A",
				"en": "The ranks newly committed in the same play.",
				"vi": "Các hạng mới hạ trong cùng nước.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "goat",
						"en": "Then the phrase has its own evidence.",
						"vi": "Vậy câu có dấu vết riêng."
					}
				]
			},
			{
				"id": "B",
				"en": "I needed to hear the possible order first.",
				"vi": "Tôi cần nghe thứ tự có thể có trước.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "The old cards should fill every missing note.",
				"vi": "Lá cũ nên lấp mọi nốt thiếu.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "goat",
						"en": "That would change the phrase we named.",
						"vi": "Điều đó đổi câu mình đã nói."
					}
				]
			}
		]
	},
	{
		"id": "goat.t2.card_memory",
		"zodiac": "goat",
		"content_tier": "2",
		"relationship_required": 3,
		"kind": "QUESTION",
		"memory_key": "goat.card",
		"promise_from": "goat.t1plus.card",
		"prompts": {
			"FULFILLED": [
				{
					"speaker": "goat",
					"en": "Your chosen note found a neighbor: {target} What did you hear beside it?",
					"vi": "Nốt bạn chọn đã có bạn liền kề: {target} Bạn nghe gì bên nó?"
				}
			],
			"BROKEN": [
				{
					"speaker": "goat",
					"en": "This note didn't meet its promised neighbor: {target} What company did it have?",
					"vi": "Nốt này chưa gặp bạn liền kề đã hứa: {target} Nó đã đi cùng ai?"
				}
			],
			"REFUSED": [
				{
					"speaker": "goat",
					"en": "You left this note free: {target} Did it find a place later?",
					"vi": "Bạn để nốt này tự do: {target} Sau đó nó tìm được chỗ chưa?"
				}
			]
		},
		"answers": [
			{
				"id": "A",
				"en": "The card's real place, even when it wasn't the promised one.",
				"vi": "Chỗ thực sự của lá bài, kể cả khi không phải chỗ đã hứa.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "goat",
						"en": "Then we can hear what happened.",
						"vi": "Vậy mình nghe được điều đã xảy ra."
					}
				]
			},
			{
				"id": "B",
				"en": "I'm still looking for a hand that fits it.",
				"vi": "Tôi vẫn tìm bài hợp với nó.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "Any card anywhere beside it should count.",
				"vi": "Lá nào ở đâu cạnh nó cũng nên được tính.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "goat",
						"en": "We named a newly committed neighbor.",
						"vi": "Mình đã nói lá liền kề mới hạ mà."
					}
				]
			}
		]
	},
	{
		"id": "goat.t2.quiet",
		"zodiac": "goat",
		"content_tier": "2",
		"relationship_required": 3,
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "goat",
				"en": "Would you still listen if I had nothing new to sing?",
				"vi": "Nếu tôi chẳng có gì mới để hát, bạn còn nghe không?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Yes. You don't need a new song to sit here.",
				"vi": "Có. Bạn không cần bài hát mới để ngồi đây.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "goat",
						"en": "Then the quiet can stay.",
						"vi": "Vậy khoảng yên có thể ở lại."
					}
				]
			},
			{
				"id": "B",
				"en": "For a while. I like this table.",
				"vi": "Một lúc. Tôi thích bàn này.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "Only if the next song helps me win.",
				"vi": "Chỉ khi bài sau giúp tôi thắng.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "goat",
						"en": "I was asking for a listener.",
						"vi": "Tôi đang xin người lắng nghe."
					}
				]
			}
		]
	},
	{
		"id": "goat.t2.wrong",
		"zodiac": "goat",
		"content_tier": "2",
		"relationship_required": 3,
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "goat",
				"en": "If I lose the note I meant to sing, what would you do?",
				"vi": "Nếu tôi lạc mất nốt định hát, bạn sẽ làm gì?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Leave room for you to find it again.",
				"vi": "Chừa khoảng để bạn tìm lại.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "goat",
						"en": "Then I don't have to hide the pause.",
						"vi": "Vậy tôi không phải giấu khoảng dừng."
					}
				]
			},
			{
				"id": "B",
				"en": "Ask whether you'd like another start.",
				"vi": "Hỏi bạn có muốn bắt đầu lại không.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "Choose the note for you before you notice.",
				"vi": "Chọn nốt thay bạn trước khi bạn nhận ra.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "goat",
						"en": "That wouldn't be my voice returning.",
						"vi": "Vậy đâu phải giọng tôi quay lại."
					}
				]
			}
		]
	},
	{
		"id": "goat.t2.together",
		"zodiac": "goat",
		"content_tier": "2",
		"relationship_required": 3,
		"kind": "QUESTION",
		"prompt": [
			{
				"speaker": "goat",
				"en": "What makes this table worth returning to?",
				"vi": "Điều gì khiến bàn này đáng quay lại?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "We can hear each other without having to perform.",
				"vi": "Mình nghe nhau mà không cần biểu diễn.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "goat",
						"en": "Then I'll keep a little quiet here for you.",
						"vi": "Vậy tôi giữ chút yên ở đây cho bạn."
					}
				]
			},
			{
				"id": "B",
				"en": "The familiar sound when we sit down.",
				"vi": "Âm quen thuộc lúc mình ngồi xuống.",
				"delta": 0,
				"reaction": []
			},
			{
				"id": "C",
				"en": "Knowing exactly what I can get from you.",
				"vi": "Biết chính xác tôi lấy được gì từ bạn.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "goat",
						"en": "Then there'd be little room left to listen.",
						"vi": "Vậy còn ít chỗ để lắng nghe lắm."
					}
				]
			}
		]
	}
]
