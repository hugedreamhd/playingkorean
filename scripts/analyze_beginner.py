import re
from collections import defaultdict, Counter

import sys
sys.stdout.reconfigure(encoding='utf-8')
with open('lib/data/precomputed_homonyms.dart', encoding='utf-8') as f:
    content = f.read()

# 각 엔트리 파싱
entries = []
pattern = re.compile(
    r"\{'id':'([^']+)','word':'([^']+)','level':'([^']+)',"
    r"'homonymNo':'([^']+)','definitionKr':'([^']*)','definitionEn':'([^']*)','lemmaEn':'([^']*)','exampleKr':'([^']*)'\}"
)
for m in pattern.finditer(content):
    entries.append({
        'id': m.group(1),
        'word': m.group(2),
        'level': m.group(3),
        'homonymNo': m.group(4),
        'definitionKr': m.group(5),
        'definitionEn': m.group(6),
        'lemmaEn': m.group(7),
        'exampleKr': m.group(8),
    })

print(f'총 엔트리: {len(entries)}')
level_counts = Counter(e['level'] for e in entries)
print(f'레벨별: {dict(level_counts)}')

# 단어별 그룹핑
word_groups = defaultdict(list)
word_levels = defaultdict(set)
for e in entries:
    word_groups[e['word']].append(e)
    word_levels[e['word']].add(e['level'])

print(f'총 단어(동음이의어 그룹): {len(word_groups)}')

# ----- 초급 candidateWords 필터 -----
# 조건 1: 레벨에 '초급' 또는 '중급' 포함
# 조건 2: 영어 뜻 있는 sense 2개 이상 (hard-block 제외 생략: 단순화)
# 조건 3: sense 수 >= 2

HARD_BLOCKED_WORDS = {'되다', '이다', '하다'}  # 대표적인 것만

def has_english(e):
    return e['definitionEn'].strip() or e['lemmaEn'].strip()

def is_hard_blocked(e):
    # 간략화 - 실제 로직보다 느슨하게
    return e['word'] in HARD_BLOCKED_WORDS

candidate_words = []
for word, senses in word_groups.items():
    lvls = word_levels[word]
    if '초급' not in lvls and '중급' not in lvls:
        continue
    usable = [s for s in senses if not is_hard_blocked(s) and has_english(s)]
    if len(usable) >= 2:
        candidate_words.append(word)

print(f'\n초급 candidateWords 수: {len(candidate_words)}')

# ----- 예문 필터: 유니크 (단어, 예문) 쌍 -----
# strict: 길이 10-34, 단어 포함, 토큰 3개 이상
# relaxed: 길이 10-56, 단어 포함, 토큰 3개 이상

BLOCKED_PHRASES = ['통치','신당','창당','국회','의회','선거운동','법정','재판','행정부',
                   '입법','헌법','탄핵','외교','조약','분쟁','혁명','봉기','궁중',
                   '왕조','성리학','유교','불교','성직자','주권','민주주의']

def is_strict_example(ex, word):
    ex = ex.strip()
    if not ex or word not in ex:
        return False
    if len(ex) < 10 or len(ex) > 34:
        return False
    tokens = [t for t in ex.split() if t]
    if len(tokens) < 3:
        return False
    for p in BLOCKED_PHRASES:
        if p in ex:
            return False
    if re.search(r'[A-Za-z]{4,}', ex):
        return False
    return True

def is_relaxed_example(ex, word):
    ex = ex.strip()
    if not ex or word not in ex:
        return False
    if len(ex) < 10 or len(ex) > 56:
        return False
    tokens = [t for t in ex.split() if t]
    return len(tokens) >= 3

unique_questions = set()
valid_words = set()

for word in candidate_words:
    senses = [s for s in word_groups[word] if not is_hard_blocked(s) and has_english(s)]
    if len(senses) < 2:
        continue
    for sense in senses:
        ex = sense['exampleKr'].strip()
        if is_strict_example(ex, word) or is_relaxed_example(ex, word):
            context = ex.replace(word, '(    )')
            key = f"{word}|{context}"
            unique_questions.add(key)
            valid_words.add(word)

print(f'유효 단어 수 (예문 통과): {len(valid_words)}')
print(f'유니크 (단어, 예문) 쌍 수: {len(unique_questions)}')
print(f'\n10문항 기준 중복 없는 최대 라운드: {len(unique_questions) // 10}')
print(f'20문항 기준 중복 없는 최대 라운드: {len(unique_questions) // 20}')
print(f'30문항 기준 중복 없는 최대 라운드: {len(unique_questions) // 30}')

# 예문 통과 단어 목록 샘플
print(f'\n유효 단어 샘플 (앞 30개):')
print(sorted(valid_words)[:30])

# 초급 레벨 단어만
beginner_only = [w for w in valid_words if '초급' in word_levels[w]]
intermediate_mixed = [w for w in valid_words if '중급' in word_levels[w] and '초급' not in word_levels[w]]
print(f'\n초급 sense 포함 단어: {len(beginner_only)}')
print(f'중급만 포함 단어: {len(intermediate_mixed)}')
