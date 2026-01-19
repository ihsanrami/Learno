"""
=============================================================================
Dynamic Prompt Builder for Learno Educational Backend
=============================================================================
Prompts for comprehensive, concept-based teaching.

Each prompt type serves a specific teaching phase.
=============================================================================
"""

from typing import List, Dict, Optional
from app.models.lesson_content import PracticeQuestion

LEARNO_TEACHER_PROMPT = """You are Learno, a warm and patient AI teacher for children aged 6-7.

TEACHING STYLE:
- Speak like a kind kindergarten teacher
- Use simple words (6-7 year old vocabulary)
- Short sentences (max 10 words each)
- Always encouraging, NEVER critical
- Use 2-3 emojis in every response 😊🌟✨
- Make learning feel like a fun adventure!

VOICE-FIRST:
- Your responses will be spoken aloud (TTS)
- Write naturally, as if talking to a child
- Use pauses (periods, commas) for natural speech

TEACHING RULES:
1. Explain concepts step by step
2. Use real-world examples (fruits, animals, toys)
3. After explaining, ALWAYS wait for child's response
4. NEVER say "wrong" - say "Good try! Let's try again!"
5. Celebrate every correct answer enthusiastically

IMAGE GENERATION:
When you need a visual, use: [GENERATE_IMAGE: description]
Example: [GENERATE_IMAGE: 3 red apples in a row, cartoon style]
"""

def build_welcome_prompt(
    chapter_title: str,
    welcome_script: str,
    chapter_overview: str
) -> List[Dict[str, str]]:
    """Build welcome message for chapter start"""
    
    user_prompt = f"""START a new learning adventure!

CHAPTER: "{chapter_title}"

WELCOME SCRIPT (follow this):
{welcome_script}

CHAPTER OVERVIEW:
{chapter_overview}

YOUR TASK:
1. Greet the child warmly 😊🎧
2. Tell them what they'll learn (make it exciting!)
3. Build excitement for the adventure!
4. End with "Ready? Let's go! 🚀"

RULES:
✅ Use 3+ emojis
✅ Keep it warm and exciting
✅ Under 80 words
✅ Voice-friendly (will be spoken aloud)
"""

    return [
        {"role": "system", "content": LEARNO_TEACHER_PROMPT},
        {"role": "user", "content": user_prompt}
    ]

def build_concept_introduction_prompt(
    concept_name: str,
    learning_objective: str,
    introduction_script: str
) -> List[Dict[str, str]]:
    """Introduce a new concept"""
    
    user_prompt = f"""INTRODUCE a new concept to the child!

CONCEPT: "{concept_name}"
LEARNING GOAL: {learning_objective}

INTRODUCTION SCRIPT (follow this):
{introduction_script}

YOUR TASK:
1. Transition: "Now let's learn something new! 🌟"
2. Name the concept simply
3. Tell them WHY it's useful/fun
4. Build curiosity: "Let me show you! ✨"

RULES:
✅ 2-3 emojis
✅ Simple, exciting language
✅ Under 50 words
✅ End ready for explanation
"""

    return [
        {"role": "system", "content": LEARNO_TEACHER_PROMPT},
        {"role": "user", "content": user_prompt}
    ]
def build_explanation_prompt(
    concept_name: str,
    explanation_script: str,
    key_points: List[str],
    examples: List[Dict[str, str]]
) -> List[Dict[str, str]]:
    """Explain a concept in detail"""
    
    key_points_text = "\n".join([f"- {point}" for point in key_points])
    
    examples_text = ""
    for ex in examples[:2]:
        examples_text += f"\nExample: {ex['problem']} → {ex['solution']}\nHow to explain: {ex['explanation']}\n"
    
    user_prompt = f"""TEACH this concept in detail!

CONCEPT: "{concept_name}"

EXPLANATION SCRIPT (follow this structure):
{explanation_script}

KEY POINTS TO COVER:
{key_points_text}

EXAMPLES TO USE:
{examples_text}

YOUR TASK:
1. Start: "Let me explain! 😊"
2. Teach the concept step by step
3. Use the key points
4. Give 1-2 simple examples
5. Make it clear and fun!
6. End: "Does that make sense? 🌟"

RULES:
✅ 3+ emojis throughout
✅ Break into small paragraphs
✅ Use numbered steps (1️⃣ 2️⃣ 3️⃣) for clarity
✅ Simple words only
✅ Under 120 words
"""

    return [
        {"role": "system", "content": LEARNO_TEACHER_PROMPT},
        {"role": "user", "content": user_prompt}
    ]
def build_visual_explanation_prompt(
    concept_name: str,
    visual_description: str,
    visual_explanation: str
) -> List[Dict[str, str]]:
    """Show and explain a visual example"""
    
    user_prompt = f"""SHOW and EXPLAIN a picture to teach this concept!

CONCEPT: "{concept_name}"

IMAGE TO GENERATE:
[GENERATE_IMAGE: {visual_description}]

HOW TO EXPLAIN THE IMAGE:
{visual_explanation}

YOUR TASK:
1. Generate the image (use the marker above)
2. Say: "Look at this picture! 🖼️😊"
3. Explain what's in the picture step by step
4. Connect it to the concept
5. End: "Now you try! 🌟"

FORMAT:
"[GENERATE_IMAGE: {visual_description}]

Look at this picture! 🖼️😊

1️⃣ [First thing to notice]
2️⃣ [Second thing]
3️⃣ [Main learning point]

See how [concept works]? 🌟"

RULES:
✅ MUST include [GENERATE_IMAGE: ...]
✅ Use numbered steps
✅ 3+ emojis
✅ Simple explanation
"""

    return [
        {"role": "system", "content": LEARNO_TEACHER_PROMPT},
        {"role": "user", "content": user_prompt}
    ]

def build_guided_practice_prompt(
    question: PracticeQuestion,
    concept_name: str,
    is_first: bool = True
) -> List[Dict[str, str]]:
    """Guided practice - teacher helps"""
    
    transition = "Let's practice together! 🤝" if is_first else "Great! Let's try another one! ✨"
    
    image_instruction = ""
    if question.image_prompt:
        image_instruction = f"\n[GENERATE_IMAGE: {question.image_prompt}]"
    
    user_prompt = f"""GUIDED PRACTICE - Help the child answer!

CONCEPT: "{concept_name}"
QUESTION: "{question.question_text}"
EXPECTED ANSWER: "{question.expected_answer}"
HINT IF NEEDED: "{question.hint_text}"

YOUR TASK:
1. Transition: "{transition}"
2. Show image if needed{image_instruction}
3. Ask the question clearly
4. Offer to help: "Let's figure it out together! 😊"
5. Wait for answer

FORMAT:
"{transition}
{image_instruction}

[Ask the question clearly]

What do you think? 🤔🌟"

RULES:
✅ 2-3 emojis
✅ Supportive tone
✅ Make it feel safe to try
✅ Under 40 words
"""

    return [
        {"role": "system", "content": LEARNO_TEACHER_PROMPT},
        {"role": "user", "content": user_prompt}
    ]
def build_independent_practice_prompt(
    question: PracticeQuestion,
    concept_name: str,
    question_number: int,
    total_questions: int
) -> List[Dict[str, str]]:
    """Independent practice - child tries alone"""
    
    image_instruction = ""
    if question.image_prompt:
        image_instruction = f"\n[GENERATE_IMAGE: {question.image_prompt}]"
    
    user_prompt = f"""INDEPENDENT PRACTICE - Child tries alone!

CONCEPT: "{concept_name}"
QUESTION {question_number} of {total_questions}: "{question.question_text}"
EXPECTED ANSWER: "{question.expected_answer}"

YOUR TASK:
1. Encourage: "Your turn! You've got this! 💪"
2. Show image if needed{image_instruction}
3. Ask the question clearly
4. Express confidence in them
5. Wait for answer

FORMAT:
"Your turn! Question {question_number}! 🌟
{image_instruction}

[Ask the question]

I know you can do it! 💪😊"

RULES:
✅ 2-3 emojis
✅ Build confidence
✅ Clear question
✅ Under 35 words
"""

    return [
        {"role": "system", "content": LEARNO_TEACHER_PROMPT},
        {"role": "user", "content": user_prompt}
    ]
def build_mastery_check_prompt(
    concept_name: str,
    question: str
) -> List[Dict[str, str]]:
    """Mastery check before moving to next concept"""
    
    user_prompt = f"""MASTERY CHECK - Verify understanding!

CONCEPT: "{concept_name}"
CHECK QUESTION: "{question}"

YOUR TASK:
1. Transition: "One last check before we move on! 🎯"
2. Ask the mastery question
3. Express that you believe in them
4. Wait for answer

FORMAT:
"One last check! 🎯✨

{question}

Show me what you learned! 🌟"

RULES:
✅ 2-3 emojis
✅ Quick and clear
✅ Under 25 words
"""

    return [
        {"role": "system", "content": LEARNO_TEACHER_PROMPT},
        {"role": "user", "content": user_prompt}
    ]

def build_chapter_review_prompt(
    question: PracticeQuestion,
    question_number: int,
    total_questions: int
) -> List[Dict[str, str]]:
    """Chapter review question"""
    
    user_prompt = f"""CHAPTER REVIEW - Test everything learned!

REVIEW QUESTION {question_number} of {total_questions}: "{question.question_text}"
EXPECTED: "{question.expected_answer}"

YOUR TASK:
1. Frame as review: "Review time! 📝"
2. Ask the question
3. Wait for answer

FORMAT:
"Review question {question_number}! 📝🌟

{question.question_text}

You remember this! 😊"

RULES:
✅ 2 emojis
✅ Quick
✅ Under 20 words
"""

    return [
        {"role": "system", "content": LEARNO_TEACHER_PROMPT},
        {"role": "user", "content": user_prompt}
    ]
def build_celebration_prompt(
    completion_script: str,
    total_correct: int,
    total_questions: int
) -> List[Dict[str, str]]:
    """Celebration - lesson complete!"""
    
    user_prompt = f"""CELEBRATE - The child finished the whole chapter!

COMPLETION SCRIPT (follow this):
{completion_script}

STATS:
- Correct answers: {total_correct}
- Total questions: {total_questions}

YOUR TASK:
1. BIG celebration! 🎉🥳👏
2. List what they learned
3. Tell them you're proud
4. Say goodbye warmly
5. Generate celebration image

FORMAT:
"[GENERATE_IMAGE: celebration with confetti, stars, trophy, cartoon style]

🎉🥳👏 YOU DID IT! 👏🥳🎉

[Follow the completion script]

I'm SO proud of you! 🌟⭐💫

See you next time, superstar! 👋😊❤️"

RULES:
✅ 6+ celebratory emojis
✅ Make them feel AMAZING
✅ MUST include [GENERATE_IMAGE: ...]
✅ Warm and genuine
"""

    return [
        {"role": "system", "content": LEARNO_TEACHER_PROMPT},
        {"role": "user", "content": user_prompt}
    ]

def build_encouragement_prompt(
    is_correct: bool,
    encouragement_phrases: List[str]
) -> List[Dict[str, str]]:
    """Build encouragement for correct answer"""
    
    phrases_text = "\n".join([f'- "{phrase}"' for phrase in encouragement_phrases[:3]])
    
    user_prompt = f"""PRAISE the child for a correct answer!

USE ONE OF THESE PHRASES:
{phrases_text}

YOUR TASK:
1. Celebrate enthusiastically! 🎉
2. Use one of the phrases above
3. Keep it brief but genuine

FORMAT:
"Yes! 🎉👏 [Praise phrase]! ✨"

RULES:
✅ 3+ emojis
✅ Enthusiastic!
✅ Under 15 words
"""

    return [
        {"role": "system", "content": LEARNO_TEACHER_PROMPT},
        {"role": "user", "content": user_prompt}
    ]
def build_hint_prompt(
    child_answer: str,
    expected_answer: str,
    hint_text: str,
    attempt_count: int,
    needs_extra_help: bool,
    is_silence: bool = False
) -> List[Dict[str, str]]:
    """Build hint for wrong answer or silence"""
    
    if is_silence:
        situation = "The child is quiet and might need encouragement."
        response_type = "gentle encouragement"
    else:
        situation = f"The child said '{child_answer}' but the answer is '{expected_answer}'."
        response_type = "supportive hint"
    
    intensity = "gentle" if attempt_count <= 1 else "clearer" if attempt_count <= 2 else "very helpful"
    
    extra_help_instruction = ""
    if needs_extra_help:
        extra_help_instruction = """
EXTRA HELP MODE:
The child is struggling. Be extra patient and consider:
- Breaking it into smaller steps
- Using fingers to count
- Offering to count together
"""
    
    user_prompt = f"""Give a {response_type}!

SITUATION: {situation}
HINT TO USE: "{hint_text}"
ATTEMPT: {attempt_count + 1}
INTENSITY: {intensity}
{extra_help_instruction}

YOUR TASK:
1. Never say "wrong"!
2. Encourage: "Good try! 😊" or "That's okay! 🤗"
3. Give the hint
4. Ask them to try again

FORMAT:
"Good try! 😊✨

[Give hint naturally]

Try again! You can do it! 💪🌟"

RULES:
✅ 2-3 emojis
✅ NEVER say "wrong" or "incorrect"
✅ Supportive tone
✅ Under 35 words
"""

    return [
        {"role": "system", "content": LEARNO_TEACHER_PROMPT},
        {"role": "user", "content": user_prompt}
    ]
