import json
import os
import sys

# 2.2MB의 대용량 사전 JSON 파일 경로
input_path = 'assets/1537907_1201814.json'
output_path = 'assets/data/quizzes.json'

print(f"Checking input file: {input_path}")
if not os.path.exists(input_path):
    print(f"Error: {input_path} not found!")
    sys.exit(1)

# 출력 디렉토리 생성
os.makedirs(os.path.dirname(output_path), exist_ok=True)

# 이미지 매핑 테이블 (주요 단어에 대해 고화질 URL 할당)
IMAGE_MAP = {
    "배": [
        "https://images.unsplash.com/photo-1615484477778-93660394222a",
        "https://images.unsplash.com/photo-1544257750-572358f5da22",
        "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b",
    ],
    "말": [
        "https://images.unsplash.com/photo-1553284965-83fd3e82fa5a",
        "https://images.unsplash.com/photo-1557804506-669a67965ba0",
    ],
    "눈": [
        "https://images.unsplash.com/photo-1542601039-4632f051523a",
        "https://images.unsplash.com/photo-1558470598-a5dda9640f68",
    ],
    "다리": [
        "https://images.unsplash.com/photo-1449034446853-66c86144b0ad",
        "https://images.unsplash.com/photo-1525596662741-e94ff9f26de1",
    ],
    "밤": [
        "https://images.unsplash.com/photo-1472552947727-b59aa9df4427",
        "https://images.unsplash.com/photo-1509339022327-1e1e25360a41",
    ],
    "벌": [
        "https://images.unsplash.com/photo-1587334274328-64186a80aeee",
        "https://images.unsplash.com/photo-1591047139829-d91aec16adbb",
    ],
    "감": [
        "https://images.unsplash.com/photo-1635345750275-c7e63b6528d2",
        "https://images.unsplash.com/photo-1499209974431-9dac3adaf471",
    ],
}

DEFAULT_IMAGE = "https://images.unsplash.com/photo-1516321497487-e288fb19713f"

def get_difficulty(word):
    if word in ["배", "말", "눈", "차", "물", "소", "개"]:
        return "Beginner"
    if word in ["다리", "밤", "벌", "감", "김", "풀", "병"]:
        return "Intermediate"
    return "Advanced"

try:
    print("Loading JSON data...")
    with open(input_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    print("Grouping words...")
    items = data.get('channel', {}).get('item', [])
    word_groups = {}

    for item in items:
        word_raw = item.get('wordinfo', {}).get('word', '')
        word = word_raw.replace('-', '')
        
        # 옌말 및 특수 부호 포함 단어 제외 (PUA 범위 체크)
        if any(ord(c) >= 0xE000 and ord(c) <= 0xF8FF for c in word):
            continue
            
        sense_info = item.get('senseinfo', {})
        if sense_info.get('type') == '옛말':
            continue
            
        if word not in word_groups:
            word_groups[word] = []
        word_groups[word].append(item)

    final_quizzes = []
    print(f"Total unique words found: {len(word_groups)}")
    
    for word, senses in word_groups.items():
        if len(senses) < 2:
            continue
            
        valid_senses = senses[:4]
        options = [word] * len(valid_senses)
        
        if len(options) < 4:
            options.extend(["사과", "포도", "오렌지", "딸기"][:4-len(options)])
            
        images = IMAGE_MAP.get(word, [DEFAULT_IMAGE] * 4)
        
        for i, target_sense in enumerate(valid_senses):
            img_url = images[i] if i < len(images) else DEFAULT_IMAGE
            
            quiz = {
                "id": f"{word}_{i}",
                "imageUrl": img_url,
                "contextText": target_sense['senseinfo']['definition'],
                "options": options,
                "romaji": [""] * 4,
                "englishMeanings": [""] * 4,
                "optionImages": [
                    images[j] if j < len(images) else DEFAULT_IMAGE
                    for j in range(4)
                ],
                "explanations": [
                    s.get('senseinfo', {}).get('definition', "설명이 없습니다.")
                    for s in valid_senses
                ] + ["무관한 오답입니다."] * (4-len(valid_senses)),
                "exampleSentences": [
                    s.get('senseinfo', {}).get('example_info', [{}])[0].get('example', "예문이 없습니다.")
                    for s in valid_senses
                ] + ["예문이 없습니다."] * (4-len(valid_senses)),
                "difficulty": get_difficulty(word),
                "answerIndex": i
            }
            final_quizzes.append(quiz)

    print(f"Generated {len(final_quizzes)} quiz items.")
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(final_quizzes[:50], f, ensure_ascii=False, indent=2)

    print(f"Successfully saved to {output_path}")

except Exception as e:
    print(f"Error occurred: {e}")
    sys.exit(1)
