class_name CampaignHints
extends RefCounted
## Request-driven copy from committed campaign facts; owns no overlay or authority.
static func instruction(campaign: CampaignManager, deal: DealState, event: EventInstance, npc: String, resolve_mode: String) -> Array[String]:
	var learned := campaign.onboarding.learned
	if resolve_mode == "collection":
		return ["daily_debt", "He is back. Check today's debt and your wallet, then pay to begin Tuesday.", "Anh ta trở lại. Xem nợ hôm nay và ví, rồi trả để sang thứ Ba."]
	if event != null:
		match npc:
			"doi_no": return ["debt_intro", "This is today's target. He collects after the Evening Deal; the ledger shows the week.", "Đây là nợ hôm nay. Anh ta thu sau ván tối; sổ nợ ghi cả tuần."]
			"danh_giay": return ["shoe_reroll_rank", "Commit one or two cards, then reroll Rank or Suit. Your picks stay locked; each service doubles in price. All card properties stay.", "Chốt một hoặc hai lá rồi đổi số/chất. Lá đã chọn không được thay; mỗi dịch vụ tăng gấp đôi riêng. Giữ mọi thuộc tính."]
			"tra_da_auntie":
				if event.slot == EventManager.EventSlot.NOON:
					return ["noon_drink", "Order the Drink for Afternoon and Evening. Inspect the available new glasses; each explains its own charges and effect.", "Gọi ly dùng cho ván chiều và tối. Xem những ly mới đang mở; mỗi ly ghi rõ lượt dùng và hiệu ứng."]
				return ["drink", "Point to a glass to inspect it, then Order. One Drink is active; read this glass's effect.", "Chọn ly để xem rồi GỌI MÓN. Một ly đang dùng; đọc hiệu ứng của ly này."]
			"thay_boi": return ["gieo_transform", "Pull → effect / target. Accept commits; Reroll costs the next cast; Refuse leaves cards unchanged. GUIDE has every mapping.", "Kéo cần → hiệu ứng / mục tiêu. Nhận là chốt; Gieo lại trả giá kế; Từ chối giữ bài. HƯỚNG DẪN có đủ bảng."]
			"hang_rong": return ["relic_purchase", "Choose an object, hear Auntie, then buy. Relics stay active; cards join your deck. Removal: pay, choose a card, confirm.", "Chọn món, nghe cô rồi mua. Bảo vật luôn có hiệu lực; bài thêm vào bộ bài. Bỏ bài: trả tiền, chọn lá, xác nhận."]
			"lotto":
				if event.slot == EventManager.EventSlot.AFTERNOON:
					return ["lottery_result", "Compare your tickets with today's draw. Winnings are already paid; next is the Evening Deal.", "So vé với kết quả hôm nay. Thưởng đã vào ví; tiếp theo là ván tối."]
				return ["lottery_ticket", "Pick tickets or Buy All within your budget. Check prize categories; results arrive this afternoon.", "Chọn vé hoặc MUA TẤT CẢ trong khả năng ví. Xem các giải; chiều nay dò số."]
		if event.slot == 0:
			return ["starter", "Meet Đòi Nợ, visit Đánh Giày if you like, then choose a Drink to start your real day.", "Gặp Đòi Nợ, ghé Đánh Giày nếu thích, rồi gọi nước để bắt đầu ngày thật."]
		return ["event_" + str(event.slot), "Choose a person at the table. Their services change the real cards and earnings in your next Deal.", "Chọn người quanh bàn. Dịch vụ của họ ảnh hưởng bài thật và tiền ở ván tiếp theo."]
	if deal.state == DealState.STATE_PHASE_CHOICE:
		return ["phase_choice", "Phase 1 is settled: all loose cards counted as deadwood. Only cards marked with Sâm dứa/Bạc xỉu carry over. Replace the rest and refill. Melds stay.", "Đã chốt hiệp 1: tất cả bài rời tính phạt. Chỉ giữ bài đã đánh dấu với Sâm dứa/Bạc xỉu. Thay phần còn lại rồi bù bài. Phỏm ở lại."]
	if deal.state == DealState.STATE_FINAL_COMMIT_WINDOW:
		return ["last_call", "LAST CALL: one final chance to Hạ or Extend, then CHỐT. No more mandatory discards this phase.", "CHỐT HẠ: cơ hội cuối để Hạ hoặc Ghép, rồi CHỐT. Không cần bỏ thêm trong giai đoạn."]
	if campaign.current_phase == CampaignManager.CampaignPhase.NOON_DEAL and not learned.has("noon_consequence"):
		return ["noon_consequence", "This is your real deck after the morning visits. Look for transformed cards and your relics' triggers.", "Đây là bộ bài thật sau những lần ghé buổi sáng. Tìm bài đã đổi và điều kiện kích hoạt bảo vật."]
	if deal.current_phase == 2 or campaign.current_phase == CampaignManager.CampaignPhase.AFTERNOON_DEAL:
		return ["", "", ""]
	if not learned.has("new_meld"):
		if deal.hand.filter(func(card): return card.rank_index == 9).size() >= 3:
			return ["new_meld", "The three 9s make a Set. Select them and HẠ. Green outlines show legal new melds; other legal plays are welcome.", "Ba lá 9 tạo Bộ. Chọn rồi HẠ. Viền xanh lá chỉ Phỏm mới hợp lệ; bạn vẫn chơi cách khác được."]
		return ["new_meld", "Look for three matching ranks or a same-suit sequence. Green outlines show ready melds; G suggests a legal play.", "Tìm ba lá cùng số hoặc dãy cùng chất. Viền xanh chỉ Phỏm sẵn; G gợi ý nước hợp lệ."]
	if not learned.has("discard"):
		return ["discard", "Your meld paid immediately. Discard one loose card to end the turn; refilling draws real cards from your deck.", "Phỏm trả điểm ngay. Bỏ một lá rời để kết thúc lượt; bù bài rút lá thật từ bộ bài."]
	if not learned.has("extension"):
		if deal.hand.any(func(card): return card.rank_index == 9) and deal.melds.any(func(meld): return meld.meld_type == MeldRules.TYPE_SET and meld.cards[0].rank_index == 9):
			return ["extension", "A fourth 9 can extend the Set. Select it, select the table Set, then GHÉP. Orange outlines show extensions.", "Lá 9 thứ tư ghép được vào Bộ. Chọn lá, chọn Bộ trên bàn rồi GHÉP. Viền cam chỉ bài ghép được."]
		return ["extension", "Orange outlines identify cards that extend a table meld. Select the card and that meld, then GHÉP when ready.", "Viền cam chỉ bài ghép được vào Phỏm trên bàn. Chọn bài và Phỏm đó, rồi GHÉP khi sẵn sàng."]
	return ["", "", ""]
