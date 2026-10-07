"""Import the supplied drink pieces onto one canvas with one table contact point.

Usage: python tools/import_drink_sprites.py C:/Stuffs/Asset/drink/pieces
Requires Pillow. Original sheets and extracted pieces are never modified.
"""

import argparse
import hashlib
import json
from io import BytesIO
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "assets" / "drinks"
CANVAS = (700, 900)  # Same 7:9 aspect as the existing 112 x 144 table slot.
CONTACT = (280, 776)
# Source-space body centres / glass bases, inspected across all three states.
# A single scale per drink prevents independently cropped states changing size.
SOURCES = {
    "tra_da": ("basic_trada", 1.0, [(390, 624), (1074, 624), (1778, 624)]),
    "nhan_tran": ("basic_nhantran", 1.0, [(296, 615), (1047, 616), (1784, 619)]),
    "nuoc_voi": ("basic_nuocvoi", 1.0, [(332, 609), (1076, 612), (1817, 612)]),
    "sam_dua": ("basic_samdua", 1.0, [(378, 618), (1085, 619), (1794, 619)]),
    "den_da": ("caffeine_denda", 1.0, [(357, 623), (1068, 624), (1780, 625)]),
    "nau_da": ("caffeine_nauda", 1.0, [(358, 621), (1070, 621), (1781, 621)]),
    "bac_xiu": ("caffeine_bacxiu", 1.0, [(357, 623), (1070, 624), (1779, 624)]),
    "sting": ("energy_sting", 0.8, [(291, 857), (815, 857), (1338, 861)]),
    "bo_huc": ("energy_redbull", 0.8, [(541, 816), (1227, 816), (1227, 816)]),
    "c2_iced_tea": ("sugar_c2", 1.0, [(546, 669), (1084, 669), (1622, 669)]),
    "mia_tac": ("sugar_nuocmiaquat", 1.0, [(344, 627), (1064, 629), (1807, 630)]),
    "mia_sau_rieng": ("sugar_nuocmiasaurieng", 1.0, [(342, 631), (1064, 631), (1789, 631)]),
}
STATES = ("full", "half", "empty")


def place(image, anchor, scale):
    image = image.convert("RGBA")
    if scale != 1.0:
        image = image.resize(
            (round(image.width * scale), round(image.height * scale)),
            Image.Resampling.NEAREST,
        )
    position = tuple(CONTACT[i] - round(anchor[i] * scale) for i in (0, 1))
    canvas = Image.new("RGBA", CANVAS)
    # Paste without a mask: using the sprite as its own mask would square alpha.
    canvas.paste(image, position)
    return canvas


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pieces", type=Path)
    parser.add_argument("--only", nargs="+", choices=list(SOURCES), help="Rebuild only these drinks.")
    args = parser.parse_args()
    cut_manifest = json.loads((args.pieces / "manifest.json").read_text("utf-8"))
    cuts = {entry["file"]: entry for entry in cut_manifest["sprites"]}
    manifest_path = DEST / "sprite_layout.json"
    result = json.loads(manifest_path.read_text("utf-8")) if args.only else {"canvas": CANVAS, "contact_point": CONTACT, "sprites": {}}
    for drink_id, (stem, scale, anchors) in SOURCES.items():
        if args.only and drink_id not in args.only:
            continue
        for state, source_anchor in zip(STATES, anchors):
            # The supplied Bo Huc can has sealed/opened states. Use the opened
            # drawing for both used and finished; never invent an empty can.
            source_state = "open" if drink_id == "bo_huc" and state != "full" else state
            key = f"{stem}/{stem}_{source_state}.png"
            cut = cuts[key]
            source = args.pieces / key
            crop_x, crop_y = cut["crop_xyxy"][:2]
            anchor = (source_anchor[0] - crop_x, source_anchor[1] - crop_y)
            image = Image.open(source)
            canvas = place(image, anchor, scale)
            output = f"{drink_id}_{state}.png"
            encoded = BytesIO()
            canvas.save(encoded, format="PNG")
            data = encoded.getvalue()
            target = DEST / output
            if not target.exists() or target.read_bytes() != data:
                temporary = target.with_suffix(".png.tmp")
                temporary.write_bytes(data)
                temporary.replace(target)
            result["sprites"][output] = {
                "source_piece": key,
                "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
                "source_anchor": source_anchor,
                "scale": scale,
            }
            if drink_id == "bo_huc" and state == "empty":
                result["sprites"][output]["alias_of"] = "bo_huc_half.png"
    manifest_path.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(f"Imported {3 * len(args.only or SOURCES)} production sprites (Bo Huc uses sealed/opened art).")


if __name__ == "__main__":
    main()
