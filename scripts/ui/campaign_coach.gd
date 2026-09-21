extends CanvasLayer
## Contextual hints; never blocks or substitutes gameplay.
var host: MatchUI
var box: PanelContainer
var copy: Label
var current_id := ""
var _last_text := ""

func configure(ui: MatchUI) -> void:
	host = ui
	layer = 246
	box = PanelContainer.new()
	box.position = Vector2(280, 62)
	box.size = Vector2(720, 64)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.theme = PresentationTheme.create_game_theme()
	box.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("182b3eee"), Color("bda16a"), 1, 4, 10))
	add_child(box)
	var row := HBoxContainer.new()
	box.add_child(row)
	copy = Label.new()
	copy.custom_minimum_size.x = 570
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_theme_font_size_override("font_size", 16)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(copy)
	var guide := Button.new()
	guide.text = "?"
	guide.pressed.connect(func(): GameGlossary.open(host, "core"))
	row.add_child(guide)
	var dismiss := Button.new()
	dismiss.text = "×"
	dismiss.pressed.connect(func():
		host.campaign.onboarding.dismissed[current_id] = true
		host._queue_run_save()
	)
	row.add_child(dismiss)
	host.deal.state_changed.connect(func(result): host.campaign.onboarding.observe(result, host.deal))
	host.deal.wallet.balance_changed.connect(func(_a, _b, _c, reason):
		if reason != "reset": host.campaign.onboarding.mark(reason)
		if String(reason).begins_with("relic_purchase:"): host.campaign.onboarding.mark("relic_purchase")
	)

func _process(_delta: float) -> void:
	if host == null or host.campaign == null:
		return
	box.visible = host.game_started and not host.menu_layer.visible and host.campaign.current_day_index == 0
	if not box.visible:
		return
	if not host.selected_card_ids.is_empty():
		host.campaign.onboarding.mark("selection")
	if host.campaign.current_phase == CampaignManager.CampaignPhase.NOON_DEAL and host.deal.action_counts.get("new_meld", 0) > 0:
		host.campaign.onboarding.mark("noon_consequence")
	if get_tree().root.get_node_or_null("LotteryReceipt") != null or get_tree().root.get_node_or_null("GameGlossary") != null:
		box.hide()
		return
	var hints := _hint()
	current_id = hints[0]
	box.visible = not current_id.is_empty() and not host.campaign.onboarding.dismissed.has(current_id) and not host.campaign.onboarding.learned.has(current_id)
	var text := GameGlossary.words(hints[1], hints[2])
	if text != _last_text:
		copy.text = text
		_last_text = text

func _hint() -> Array[String]:
	var learned := host.campaign.onboarding.learned
	var npc := host.event_table.focused_npc_id
	if host.resolve_mode == "collection":
		return ["daily_debt", "He is back. Check today's debt and your wallet, then pay to begin Tuesday.", "Anh ta trở lại. Xem nợ hôm nay và ví, rồi trả để sang thứ Ba."]
	if host.current_campaign_event != null:
		match npc:
			"doi_no": return ["debt_intro", "This is today's target. He collects after the Evening Deal; the ledger shows the week.", "Đây là nợ hôm nay. Anh ta thu sau ván tối; sổ nợ ghi cả tuần."]
			"danh_giay": return ["shoe_polish", "Polish adds a day-long bonus to two random cards. A tip builds favor for a lottery hint.", "Đánh bóng thêm thưởng trong ngày cho hai lá ngẫu nhiên. Boa tăng thiện cảm để hỏi vé số."]
			"tra_da_auntie":
				if host.current_campaign_event.slot == EventManager.EventSlot.NOON:
					return ["noon_drink", "Order the Drink for Afternoon and Evening. Inspect the available new glasses; each explains its own charges and effect.", "Gọi ly dùng cho ván chiều và tối. Xem những ly mới đang mở; mỗi ly ghi rõ lượt dùng và hiệu ứng."]
				return ["drink", "Point to a glass to inspect it, then Order. One Drink is active; read this glass's effect.", "Chọn ly để xem rồi GỌI MÓN. Một ly đang dùng; đọc hiệu ứng của ly này."]
			"thay_boi": return ["gieo_transform", "Pull → effect / target. Accept commits; Reroll costs the next cast; Refuse leaves cards unchanged. GUIDE has every mapping.", "Kéo cần → hiệu ứng / mục tiêu. Nhận là chốt; Gieo lại trả giá kế; Từ chối giữ bài. HƯỚNG DẪN có đủ bảng."]
			"hang_rong": return ["relic_purchase", "Inspect a relic on the table, then buy. It enters your collection and a free slot; four slots maximum.", "Xem món trên bàn rồi mua. Món vào bộ sưu tập và ô trống; tối đa bốn ô."]
			"lotto":
				if host.current_campaign_event.slot == EventManager.EventSlot.AFTERNOON:
					return ["lottery_result", "Compare your tickets with today's draw. Winnings are already paid; next is the Evening Deal.", "So vé với kết quả hôm nay. Thưởng đã vào ví; tiếp theo là ván tối."]
				return ["lottery_ticket", "Pick tickets or Buy All within your budget. Check categories and your hint; results arrive this afternoon.", "Chọn vé hoặc MUA TẤT CẢ trong khả năng ví. Xem giải và gợi ý; chiều nay dò số."]
		if host.current_campaign_event.slot == 0:
			return ["starter", "Meet Đòi Nợ, visit Đánh Giày if you like, then choose a Drink to start your real day.", "Gặp Đòi Nợ, ghé Đánh Giày nếu thích, rồi gọi nước để bắt đầu ngày thật."]
		return ["event_" + str(host.current_campaign_event.slot), "Choose a person at the table. Their services change the real cards and earnings in your next Deal.", "Chọn người quanh bàn. Dịch vụ của họ ảnh hưởng bài thật và tiền ở ván tiếp theo."]
	var deal := host.deal
	if deal.state == DealState.STATE_PHASE_CHOICE:
		return ["phase_choice", "Phase 1 is settled: loose cards counted as deadwood. DUMP redraws loose cards; KEEP is offered only when your Drink allows it. Melds stay.", "Đã chốt giai đoạn 1: bài rời bị trừ điểm. ĐỔI rút lại bài rời; GIỮ chỉ có khi đồ uống cho phép. Phỏm ở lại."]
	if deal.state == DealState.STATE_FINAL_COMMIT_WINDOW:
		return ["last_call", "LAST CALL: one final chance to Hạ or Extend, then CHỐT. No more mandatory discards this phase.", "CHỐT HẠ: cơ hội cuối để Hạ hoặc Ghép, rồi CHỐT. Không cần bỏ thêm trong giai đoạn."]
	if host.campaign.current_phase == CampaignManager.CampaignPhase.NOON_DEAL and not learned.has("noon_consequence"):
		return ["noon_consequence", "This is your real deck after the morning visits. Look for polished or transformed cards and your equipped relic's trigger.", "Đây là bộ bài thật sau những lần ghé buổi sáng. Tìm bài bóng/biến đổi và điều kiện kích hoạt di vật đang đeo."]
	if deal.current_phase == 2 or host.campaign.current_phase == CampaignManager.CampaignPhase.AFTERNOON_DEAL:
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
