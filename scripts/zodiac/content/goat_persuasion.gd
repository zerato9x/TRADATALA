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
			"en": "Goat opens her notebook to a melody crossed out six times. She taps it twice, then turns the page toward you instead of hiding it.",
			"vi": "Mùi mở sổ, một giai điệu bị gạch sáu lần. Cô gõ hai nhịp, rồi xoay trang về phía bạn thay vì giấu đi."
		},
		{
			"en": "\"The third version was better. I knew it when I crossed it out. Sometimes I keep correcting until there's nothing left that sounds like me.\"",
			"vi": "\"Bản thứ ba hay hơn. Lúc gạch đi tôi đã biết. Có khi tôi cứ sửa đến mức chẳng còn gì nghe giống mình.\""
		},
		{
			"en": "She weights the page with a goat Emblem. \"Bring it on our day. I want to try this one with someone listening. Mistakes included.\"",
			"vi": "Cô chặn trang bằng Huy hiệu con dê. \"Đến ngày của mình thì mang nhé. Tôi muốn thử bản này khi có người nghe. Cả những chỗ sai nữa.\""
		}
	],
	"last_chance": {
		"id": "goat.last_chance.listen",
		"prompt": [
			{
				"speaker": "goat",
				"en": "Wait. You're answering the rhythm of my voice. Did you hear the words?",
				"vi": "Khoan. Bạn đang đáp theo nhịp giọng tôi. Có nghe lời tôi nói không?"
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
						"en": "All right. From the top. Slower this time.",
						"vi": "Được. Làm lại từ đầu. Lần này chậm hơn."
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
						"en": "Then stop there. No need to decorate the silence.",
						"vi": "Vậy dừng ở đó. Không cần trang trí khoảng lặng."
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
						"en": "That's a jingle, not an answer. We're done.",
						"vi": "Đó là câu quảng cáo, không phải trả lời. Thôi nhé."
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
				"en": "I played the quiet part and someone dropped a spoon. What would you do?",
				"vi": "Tôi vừa chơi đoạn nhỏ thì ai đánh rơi thìa. Bạn làm gì?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Let the noise settle so I can hear you.",
				"vi": "Chờ tiếng động lắng xuống để nghe bạn.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "goat",
						"en": "Yes. Let the spoon have its solo, then listen.",
						"vi": "Ừ. Để cái thìa độc tấu xong rồi nghe."
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
						"en": "I would. Though I'd glare at the spoon first.",
						"vi": "Tôi sẽ chơi. Nhưng phải lườm cái thìa trước."
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
						"en": "Lovely. Now we've got two spoons.",
						"vi": "Hay quá. Giờ mình có hai cái thìa."
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
				"en": "Two singers, different keys. Who has to change?",
				"vi": "Hai người hát, hai giọng khác nhau. Ai phải đổi?"
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
						"en": "Yes. Harmony takes work. Unison just takes obedience.",
						"vi": "Ừ. Hòa âm cần công sức. Đồng thanh chỉ cần nghe theo."
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
						"en": "Exactly. A duet and an argument need different arrangements.",
						"vi": "Đúng. Song ca với cãi nhau cần cách phối khác nhau."
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
						"en": "Then the loud one should buy a mirror and sing at that.",
						"vi": "Vậy người to tiếng nên mua gương mà hát với mình."
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
				"en": "There's a rest between these notes. Would you leave it there?",
				"vi": "Giữa những nốt này có dấu lặng. Bạn để nguyên chứ?"
			}
		],
		"answers": [
			{
				"id": "A",
				"en": "Yes. Give both notes room to be heard.",
				"vi": "Có. Để cả hai nốt đều được nghe.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "goat",
						"en": "Thank you. Even a tune needs somewhere to breathe.",
						"vi": "Cảm ơn. Giai điệu cũng cần chỗ thở."
					}
				]
			},
			{
				"id": "B",
				"en": "If it helps the next note land.",
				"vi": "Nếu nó giúp nốt sau vào đúng chỗ.",
				"delta": 0,
				"reaction": [
					{
						"speaker": "goat",
						"en": "Yes. The next note shouldn't trample the last one.",
						"vi": "Ừ. Nốt sau không nên giẫm lên nốt trước."
					}
				]
			},
			{
				"id": "C",
				"en": "No. Gaps are mistakes.",
				"vi": "Không. Khoảng trống là lỗi.",
				"delta": -1,
				"reaction": [
					{
						"speaker": "goat",
						"en": "Try singing without breathing. Brief career.",
						"vi": "Thử hát không thở đi. Sự nghiệp ngắn lắm."
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
						"en": "Different ranks, counted once each. I like echoes; I can still count them.",
						"vi": "Các hạng khác nhau, mỗi hạng tính một lần. Tôi thích tiếng vọng; vẫn đếm được nhé."
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
						"en": "There. Different ranks, each earning its place. Much better than one note shouted three times.",
						"vi": "Đấy. Các hạng khác nhau, đều có điểm. Hay hơn hét một nốt ba lần nhiều."
					}
				]
			},
			"BROKEN": {
				"delta": -1,
				"dialogue": [
					{
						"speaker": "goat",
						"en": "Not enough different scoring ranks. Louder isn't more varied.",
						"vi": "Chưa đủ hạng ghi điểm khác nhau. To hơn không có nghĩa đa dạng hơn."
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
						"en": "All in one play. No borrowing yesterday's notes to finish today's phrase.",
						"vi": "Cùng một nước bài. Không mượn nốt hôm qua để hoàn tất câu nhạc hôm nay."
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
						"en": "Together, in order. I could hear where that phrase was going.",
						"vi": "Cùng lúc, liền nhau. Tôi nghe được câu nhạc ấy đi về đâu."
					}
				]
			},
			"BROKEN": {
				"delta": -1,
				"dialogue": [
					{
						"speaker": "goat",
						"en": "The new cards didn't make the consecutive phrase. The old notes can't sing it for them.",
						"vi": "Các lá mới chưa tạo được câu liền hạng. Nốt cũ không hát hộ được."
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
						"en": "Your card, and a new neighbor in the same play. I'll listen for both.",
						"vi": "Lá của bạn, cùng lá kề hạng mới trong một nước. Tôi chờ nghe cả hai."
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
						"en": "Your card and its neighbor arrived together. That's the little phrase I wanted to hear.",
						"vi": "Lá bạn cùng lá kề hạng vào một lúc. Đúng câu nhạc nhỏ tôi muốn nghe."
					}
				]
			},
			"BROKEN": {
				"delta": -1,
				"dialogue": [
					{
						"speaker": "goat",
						"en": "No new neighbor beside that card in the same play. Proximity isn't a duet.",
						"vi": "Không có lá kề hạng mới cùng vào nước đó. Đứng gần chưa thành song ca."
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
					"en": "Different ranks, as promised: {target} Which note made you hear the rest differently?",
					"vi": "Đủ hạng khác nhau như đã hứa: {target} Nốt nào khiến bạn nghe phần còn lại khác đi?"
				}
			],
			"BROKEN": [
				{
					"speaker": "goat",
					"en": "Not all the promised ranks: {target} Was your hand stuck on a refrain?",
					"vi": "Chưa đủ hạng đã hứa: {target} Tay bài cứ lặp một điệp khúc à?"
				}
			],
			"REFUSED": [
				{
					"speaker": "goat",
					"en": "You didn't promise these notes: {target} I can respect a musician who asks to see the score first.",
					"vi": "Bạn không hứa các nốt này: {target} Tôi tôn trọng người muốn xem bản nhạc trước."
				}
			]
		},
		"answers": [
			{
				"id": "A",
				"en": "I'd count what I played, not the same rank twice.",
				"vi": "Tôi đếm những gì đã chơi, không đếm một hạng hai lần.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "goat",
						"en": "Good. Three distinct notes, not one wearing three hats.",
						"vi": "Tốt. Ba nốt riêng, không phải một nốt đội ba cái mũ."
					}
				]
			},
			{
				"id": "B",
				"en": "Whether my hand could fit another rank.",
				"vi": "Tay bài có chỗ cho hạng khác không.",
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
						"en": "It can. Still the same rank. Expression doesn't change the count.",
						"vi": "Nghe khác được. Vẫn cùng hạng. Cách diễn tả không đổi số đếm."
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
					"en": "That phrase worked: {target} Did you hear it before you played it?",
					"vi": "Câu nhạc thành rồi: {target} Bạn nghe ra trước khi chơi chứ?"
				}
			],
			"BROKEN": [
				{
					"speaker": "goat",
					"en": "The phrase came apart: {target} Which gap were you hoping the old notes would fill?",
					"vi": "Câu nhạc rời rạc: {target} Bạn mong nốt cũ lấp khoảng nào?"
				}
			],
			"REFUSED": [
				{
					"speaker": "goat",
					"en": "You left this unwritten: {target} Some things sound better before you promise to perform them.",
					"vi": "Bạn để phần này chưa viết: {target} Có thứ nghe hay hơn khi chưa hứa sẽ biểu diễn."
				}
			]
		},
		"answers": [
			{
				"id": "A",
				"en": "The new cards all arrived in the same play.",
				"vi": "Những lá mới cùng vào một nước.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "goat",
						"en": "Yes. Listen to what you actually played.",
						"vi": "Ừ. Nghe đúng những gì bạn đã chơi."
					}
				]
			},
			{
				"id": "B",
				"en": "I needed to see the order before I tried it.",
				"vi": "Tôi cần thấy thứ tự trước khi thử.",
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
						"en": "Then we'd be praising a different tune.",
						"vi": "Vậy mình đang khen một giai điệu khác."
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
					"en": "{target} found its neighbor. Small phrase, clear shape. What did you like about it?",
					"vi": "{target} tìm được lá kề hạng. Câu nhỏ, nét rõ. Bạn thích gì ở nó?"
				}
			],
			"BROKEN": [
				{
					"speaker": "goat",
					"en": "{target} didn't meet its new neighbor in one play. Where did the duet fall apart?",
					"vi": "{target} chưa gặp lá kề hạng mới trong một nước. Đoạn song ca vỡ ở đâu?"
				}
			],
			"REFUSED": [
				{
					"speaker": "goat",
					"en": "You didn't promise {target} a partner. Did the hand suggest a different arrangement?",
					"vi": "Bạn không hứa bạn diễn cho {target}. Tay bài gợi cách phối khác à?"
				}
			]
		},
		"answers": [
			{
				"id": "A",
				"en": "I'd tell you where the card went, even if I got it wrong.",
				"vi": "Tôi sẽ nói lá ấy đi đâu, kể cả khi tôi làm sai.",
				"delta": 1,
				"reaction": [
					{
						"speaker": "goat",
						"en": "Good. Even a wrong note deserves its right name.",
						"vi": "Tốt. Nốt sai cũng đáng được gọi đúng tên."
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
						"en": "New neighbors, same play. I wrote it down; my handwriting isn't that bad.",
						"vi": "Lá kề hạng mới, cùng nước bài. Tôi có ghi; chữ tôi đâu khó đọc đến thế."
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
				"en": "I've been working on the same four bars all week. Would you listen once more?",
				"vi": "Cả tuần tôi loay hoay bốn ô nhịp này. Bạn nghe thêm lần nữa nhé?"
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
						"en": "Good. Because I'm not sure they're getting better. Just more familiar.",
						"vi": "May quá. Tôi không chắc chúng hay hơn. Chỉ thấy quen hơn."
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
						"en": "I was hoping for an audience, not a sponsor.",
						"vi": "Tôi mong có khán giả, không phải nhà tài trợ."
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
				"en": "If I stop in the middle, don't sing the missing note for me. Can you do that?",
				"vi": "Nếu tôi dừng giữa chừng, đừng hát hộ nốt còn thiếu. Bạn làm được không?"
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
						"en": "Thank you. I usually hear everyone's patience running out before I hear the note.",
						"vi": "Cảm ơn. Tôi thường nghe người ta hết kiên nhẫn trước khi tìm được nốt nhạc."
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
						"en": "You'd fix the song and lose the singer.",
						"vi": "Bạn sửa được bài hát, rồi đánh mất người hát."
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
				"en": "Why this table? The traffic's dreadful and someone always drops a spoon.",
				"vi": "Sao lại bàn này? Xe cộ ồn khủng khiếp, lúc nào cũng có người đánh rơi thìa."
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
						"en": "Yes. Nobody asks me to make the motorbikes sound beautiful.",
						"vi": "Ừ. Chẳng ai bắt tôi biến tiếng xe máy thành nhạc hay."
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
						"en": "Then please don't mistake my notebook for a menu.",
						"vi": "Vậy đừng nhầm sổ nhạc của tôi với thực đơn."
					}
				]
			}
		]
	}
]
