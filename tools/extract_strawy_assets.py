"""Lossless extraction of the supplied, unevenly spaced hat poses."""
from pathlib import Path
import json
import shutil
from PIL import Image

SOURCE = Path(r"G:\PHOM\Environment\STRAWY")
DEST = Path(__file__).resolve().parents[1] / "assets/ui/strawy"
# Search regions separate the unevenly spaced poses. Derive each actual bound
# from its silhouette, rather than slicing a uniform grid. The source has alpha-1
# speckles throughout otherwise empty space; threshold only locates the bounds.
# Pixels inside the bounds are copied unchanged, including their original alpha.
REGIONS = [(0,0,383,550), (383,0,742,550), (742,0,1100,550),
           (1100,0,1448,550), (0,550,370,1086), (370,550,751,1086),
           (751,550,1100,1086), (1100,550,1448,1086)]
EYE_ANCHORS = [(200,292), (200,290), (200,296), (209,294),
               (194,294), (200,297), (200,290), (200,296)]

def main():
    DEST.mkdir(parents=True, exist_ok=True)
    sheet = Image.open(SOURCE / "strawy.png").convert("RGBA")
    manifest = {"source_size": list(sheet.size), "canvas": [400, 336],
                "bounds_alpha_threshold": 8, "edge_padding": 6, "poses": []}
    for number, region in enumerate(REGIONS, 1):
        local = sheet.crop(region).getchannel('A').point(lambda alpha: 255 if alpha > 8 else 0).getbbox()
        assert local is not None
        bounds = (max(0, region[0]+local[0]-6), max(0, region[1]+local[1]-6),
                  min(sheet.width, region[0]+local[2]+6), min(sheet.height, region[1]+local[3]+6))
        crop = sheet.crop(bounds)
        assert crop.width <= 400 and crop.height <= 328
        offset = ((400 - crop.width) // 2, 328 - crop.height)
        canvas = Image.new("RGBA", (400, 336))
        canvas.paste(crop, offset)  # Preserve alpha, including semitransparent edges.
        canvas.save(DEST / f"hat_{number:02}.png")
        manifest["poses"].append({"bounds": bounds, "offset": offset,
                                  "pivot": [200, 328], "eyes": EYE_ANCHORS[number-1]})
    for name in ["strawy_normal.png", "strawy_halfblink.png", "strawy_blink.png"]:
        shutil.copyfile(SOURCE / name, DEST / name)
    (DEST / "poses.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

if __name__ == "__main__":
    main()
