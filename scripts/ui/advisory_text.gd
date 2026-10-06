class_name AdvisoryText
extends RefCounted
## Formats the facts returned by gameplay queries for the current locale.
static func describe(row: Dictionary, last_call: bool = false) -> String:
	var text := GameGlossary.words("Keep %d/100 · relative to this hand. Lower is a better discard.", "Giữ %d/100 · so trong tay này. Thấp hơn là nên bỏ hơn.") % row.get("keep_score", 100)
	if row.get("locked", false): text += "\n" + GameGlossary.words("Locked this turn; Strawy cannot discard it.", "Đang bị khóa; Strawy không thể bỏ lá này.")
	elif row.get("protected", false): text += "\n" + GameGlossary.words("Preserved for a legal Meld/Extend.", "Giữ cho nước Hạ/Ghép hợp lệ.")
	if last_call or row.get("draw_count", 0) == 0:
		text += "\n" + GameGlossary.words("No refill before settlement. Consider your available plays and deadwood.", "Không bù bài trước khi chốt. Xem nước hợp lệ và bài rời.")
	var target: Dictionary = row.get("target", {})
	if not target.is_empty():
		text += "\n" + GameGlossary.words("After this discard: %s · %.3f%% in %d refill cards.", "Sau khi bỏ: %s · %.3f%% trong %d lá bù.") % [localized_label(target), row["probability"] * 100.0, row["draw_count"]]
	if not row.get("second_id", "").is_empty():
		text += "\n" + GameGlossary.words("Assumes Trà Đá's extra discard; no refill between the two discards.", "Tính cả lần bỏ thêm của Trà Đá; không bù bài giữa hai lần bỏ.")
	return text

static func localized_label(candidate: Dictionary) -> String:
	var label_key := String(candidate.get("label_key", ""))
	if label_key.is_empty():
		return String(candidate.get("label", ""))
	return String(TranslationServer.translate(label_key)) % candidate.get("label_args", []).map(_label_argument)



static func _label_argument(value: Variant) -> Variant:
	match value:
		&"compatible_identity": return GameGlossary.words("compatible identity", "định danh hợp lệ")
		" red": return GameGlossary.words(" red", " đỏ")
		" black": return GameGlossary.words(" black", " đen")
		" any suit": return GameGlossary.words(" any suit", " mọi chất")
	return value

static func reasoning(advice: Dictionary, last_call: bool) -> String:
	var row: Dictionary = advice.get("reasoning", {})
	if row.is_empty(): return ""
	if row.get("skip", false):
		return GameGlossary.words("Skip the extra discard: retain this hand and refill %d cards. Best target completion: %.3f%%.", "Bỏ qua lần bỏ thêm: giữ tay này và bù %d lá. Tỷ lệ hoàn tất mục tiêu tốt nhất: %.3f%%.") % [row.draw_count, row.probability * 100.0]
	return describe(row, last_call)
