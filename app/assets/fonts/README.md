# Bundled font sources

- NotoSans-Regular.ttf: https://raw.githubusercontent.com/notofonts/noto-fonts/main/hinted/ttf/NotoSans/NotoSans-Regular.ttf ; license NotoSans-OFL.txt.
- NotoSansCJK-Regular.ttf: weight 400 static instance made with fonttools from https://raw.githubusercontent.com/notofonts/noto-cjk/main/Sans/Variable/TTF/NotoSansCJKkr-VF.ttf ; license NotoCJK-OFL.txt. Korean regional defaults, CJK glyph coverage, approximately 21 MB.
- Existing NanumGothic retained as Korean PDF fallback.

PDF primary font is Noto Sans, then NanumGothic and Noto CJK fallback; Latin Vietnamese/French accents must render with the Latin font. Re-run six-language PDF tests and visual inspection after changing font order.
