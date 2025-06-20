import google.generativeai as genai
import json

# Gemini APIキー設定
genai.configure(api_key="AIzaSyC_ib78_VED-M4IMqDRsryiE7oEvK5BgPk")
model = genai.GenerativeModel("gemini-2.0-flash")

# --- 入力: 類似ネタ（DBから取得済みと想定） ---
ref_memos = [
    "カフェの混雑状況をLINEで教えてくれるBot",
    "図書館の混雑度を予測して表示するアプリ"
]

# --- AIへのプロンプト作成 ---
generation_prompt = f"""
以下の技術ネタを参考に、新しい技術ネタを1つ考えてください。
・{ref_memos[0]}
・{ref_memos[1]}
"""

# --- AIに生成を依頼 ---
response = model.generate_content(generation_prompt)

# --- 出力: JSON形式で新ネタを表示 ---
result = {
    "参考ネタ": ref_memos,
    "生成された新ネタ": response.text.strip()
}

print(json.dumps(result, ensure_ascii=False, indent=2))
