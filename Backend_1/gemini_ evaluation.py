import google.generativeai as genai
import json

# 🔑 Gemini APIキー設定
genai.configure(api_key="AIzaSyC_ib78_VED-M4IMqDRsryiE7oEvK5BgPk")

# 📝 ユーザーからのネタ入力を受け取る
user_memo = input("ネタを入力してください：\n")

# 📋 Geminiへの評価指示プロンプト
prompt = f"""
あなたは技術的アイデアを10の軸で評価するAIです。
次のネタを、以下の評価項目に基づき「0.0〜1.0」の数値で評価し、JSON形式で返してください。
10項目目は未定義なので、"未定義" というキー名で null を返してください。

【評価項目】
1. 新規性・独創性
2. 課題解決力・インパクト
3. ネタの単純度
4. 技術的面白さ・チャレンジ度
5. 応用可能性・発展性
6. UX・使いやすさ
7. 市場性・ニーズ
8. データ活用・AI親和性
9. 倫理性・社会的受容性
10. 未定義の評価項目（nullのままで）

【ネタ】
{user_memo}

出力形式の例：
{{
  "新規性・独創性": 0.8,
  "課題解決力・インパクト": 0.7,
  ...
  "未定義の評価項目": null
}}
"""

# 🤖 Geminiで評価
model = genai.GenerativeModel("gemini-2.0-flash")
response = model.generate_content(prompt)

# 📦 JSONとして読み取る
try:
    scores = json.loads(response.text)
    print("\n✅ Geminiによる10次元評価（ベクトル）:")
    for key, value in scores.items():
        print(f"{key}: {value}")
except json.JSONDecodeError:
    print("\n⚠️ Geminiの応答がJSON形式ではありません。")
    print("------ 応答内容 ------")
    print(response.text)
