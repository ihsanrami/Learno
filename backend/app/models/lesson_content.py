"""
=============================================================================
Lesson Content System for Learno Educational Backend
=============================================================================
COMPREHENSIVE VERSION - Full Chapter Coverage with Dynamic Teaching

Philosophy:
- Each chapter is divided into CONCEPTS (not just questions)
- Each concept has: Explanation → Examples → Practice → Verification
- AI teaches like a real teacher: explain first, then test
- Lesson doesn't end until ALL concepts are mastered
- Adaptive: more practice if struggling, faster if doing well

Structure:
Chapter
├── Concept 1
│   ├── Introduction (what we'll learn)
│   ├── Explanation (teach the concept)
│   ├── Visual Example (with image)
│   ├── Guided Practice (together)
│   ├── Independent Practice (child alone)
│   └── Concept Check (verify understanding)
├── Concept 2
│   └── ...
└── Chapter Summary & Celebration

=============================================================================
"""

from dataclasses import dataclass, field
from typing import List, Dict, Optional
from enum import Enum


class ConceptPhase(Enum):
    """Phases within teaching a concept"""
    INTRODUCTION = "introduction"      # What we'll learn
    EXPLANATION = "explanation"        # Teach the concept
    VISUAL_EXAMPLE = "visual_example"  # Show with image
    GUIDED_PRACTICE = "guided_practice"  # Do together
    INDEPENDENT_PRACTICE = "independent_practice"  # Child tries alone
    CONCEPT_CHECK = "concept_check"    # Verify understanding
    COMPLETED = "completed"            # Move to next concept


class LessonPhase(Enum):
    """Overall lesson phases"""
    WELCOME = "welcome"
    TEACHING = "teaching"
    CHAPTER_REVIEW = "chapter_review"
    CELEBRATION = "celebration"
    COMPLETED = "completed"


@dataclass
class PracticeQuestion:
    """A single practice question within a concept"""
    question_text: str
    expected_answer: str
    acceptable_answers: List[str]
    hint_text: str
    difficulty: int = 1  # 1=easy, 2=medium, 3=hard
    image_prompt: Optional[str] = None  # For generating visual


@dataclass
class ConceptContent:
    """
    A single concept within a chapter.
    This is the core teaching unit.
    """
    concept_id: str
    concept_name: str
    order: int  # Order within chapter
    
    # Teaching content
    learning_objective: str  # What child will learn
    introduction_script: str  # How to introduce
    explanation_script: str  # Detailed explanation
    key_points: List[str]  # Main takeaways
    
    # Visual teaching
    visual_description: str  # Image to generate
    visual_explanation: str  # How to explain the image
    
    # Examples (teacher demonstrates)
    examples: List[Dict[str, str]]  # [{"problem": "...", "solution": "...", "explanation": "..."}]
    
    # Practice questions (child practices)
    guided_questions: List[PracticeQuestion]  # Teacher helps
    independent_questions: List[PracticeQuestion]  # Child alone
    
    # Verification
    mastery_check_question: str  # Final check before moving on
    mastery_answer: str
    mastery_acceptable: List[str]
    
    # Teaching tips
    common_mistakes: List[str]
    encouragement_phrases: List[str]
    struggle_hints: List[str]


@dataclass
class ChapterContent:
    """
    A complete chapter/lesson with all concepts.
    """
    chapter_id: str
    chapter_title: str
    chapter_description: str
    grade_level: int
    subject: str
    
    # Welcome
    welcome_script: str
    chapter_overview: str  # What we'll learn today
    
    # Concepts (in order)
    concepts: List[ConceptContent]
    
    # Chapter review
    review_questions: List[PracticeQuestion]
    
    # Completion
    completion_script: str
    certificate_text: str
    
    @property
    def total_concepts(self) -> int:
        return len(self.concepts)
    
    def get_concept(self, concept_id: str) -> Optional[ConceptContent]:
        for concept in self.concepts:
            if concept.concept_id == concept_id:
                return concept
        return None
    
    def get_concept_by_order(self, order: int) -> Optional[ConceptContent]:
        for concept in self.concepts:
            if concept.order == order:
                return concept
        return None


# =============================================================================
# COUNTING CHAPTER - COMPREHENSIVE CONTENT
# =============================================================================

def get_counting_chapter() -> ChapterContent:
    """
    Complete counting chapter for Grade 2.
    
    Concepts covered:
    1. Number Recognition (1-5)
    2. Number Recognition (6-10)
    3. Counting Objects
    4. Counting Forward
    5. Comparing Numbers (More/Less)
    6. Simple Addition (Visual)
    7. Simple Addition (Abstract)
    
    Each concept has full teaching cycle.
    """
    
    return ChapterContent(
        chapter_id="counting_chapter",
        chapter_title="Counting Fun Adventure",
        chapter_description="Learn to count, compare numbers, and do simple addition",
        grade_level=2,
        subject="Math",
        
        # =====================================================================
        # WELCOME
        # =====================================================================
        welcome_script="""
Hello, little friend! 😊🎧 I'm Learno, your learning buddy!

Today we're going on a NUMBER ADVENTURE! ✨🔢

We're going to learn SO many cool things:
🌟 How to recognize numbers
🌟 How to count things
🌟 How to compare - which is MORE?
🌟 How to ADD numbers together!

Are you excited? I am! 🎉

Let's start our adventure! 🚀
        """.strip(),
        
        chapter_overview="""
Here's what we'll learn today:

1️⃣ First, we'll meet the numbers 1, 2, 3, 4, and 5
2️⃣ Then, we'll learn 6, 7, 8, 9, and 10
3️⃣ We'll count fun things like apples and stars
4️⃣ We'll learn which group has MORE
5️⃣ Finally, we'll learn to ADD numbers!

Ready? Let's go! 🌟
        """.strip(),
        
        # =====================================================================
        # CONCEPTS
        # =====================================================================
        concepts=[
            # -----------------------------------------------------------------
            # CONCEPT 1: Number Recognition (1-5)
            # -----------------------------------------------------------------
            ConceptContent(
                concept_id="numbers_1_to_5",
                concept_name="Meeting Numbers 1-5",
                order=1,
                
                learning_objective="Recognize and name numbers 1, 2, 3, 4, and 5",
                
                introduction_script="""
Let's meet our first number friends! 😊🔢

Numbers are everywhere! They help us count things.

Today, we'll meet five special numbers: 1, 2, 3, 4, and 5! ✨

Each number has its own shape. Let's learn them! 🌟
                """.strip(),
                
                explanation_script="""
Let me show you each number:

1️⃣ This is ONE - it looks like a stick! Just one line going down.
   ONE means just a single thing. Like one nose on your face! 👃

2️⃣ This is TWO - it has a curvy top and a flat bottom.
   TWO means a pair! Like two eyes! 👀

3️⃣ This is THREE - it has two bumps on the side.
   THREE is like two and one more! Like a triangle has three sides! 🔺

4️⃣ This is FOUR - it looks like a chair!
   FOUR is like two pairs! Like four legs on a dog! 🐕

5️⃣ This is FIVE - it has a hat on top and a round belly!
   FIVE is like one whole hand! ✋

Let's see them together! 🌟
                """.strip(),
                
                key_points=[
                    "1 is just one line - like a stick",
                    "2 has a curve - like a swan",
                    "3 has two bumps on the right side",
                    "4 looks like a chair",
                    "5 has a flat top and round bottom"
                ],
                
                visual_description="Numbers 1, 2, 3, 4, 5 displayed large and colorful in a row, each with cute cartoon objects below showing the quantity (1 apple, 2 stars, 3 hearts, 4 balls, 5 flowers), child-friendly cartoon style, white background",
                
                visual_explanation="""
Look at this picture! 🖼️😊

1️⃣ See the number 1? It has ONE apple below it! 🍎
2️⃣ The number 2 has TWO stars! ⭐⭐
3️⃣ Number 3 has THREE hearts! ❤️❤️❤️
4️⃣ Number 4 has FOUR balls! 🔵🔵🔵🔵
5️⃣ And number 5 has FIVE flowers! 🌸🌸🌸🌸🌸

See how the number tells us how many things there are? 🌟
                """.strip(),
                
                examples=[
                    {
                        "problem": "What number is this: 3",
                        "solution": "THREE",
                        "explanation": "This is three! See the two bumps? It looks like a sideways heart! 💕"
                    },
                    {
                        "problem": "What number is this: 1",
                        "solution": "ONE",
                        "explanation": "This is one! Just a simple line going down. Easy peasy! ✨"
                    },
                    {
                        "problem": "What number is this: 5",
                        "solution": "FIVE",
                        "explanation": "This is five! It has a flat hat on top and a round tummy! 😊"
                    }
                ],
                
                guided_questions=[
                    PracticeQuestion(
                        question_text="I'll show you a number. Can you tell me what it is? Look: 2 - What number is this? 🤔",
                        expected_answer="2",
                        acceptable_answers=["2", "two", "to", "too"],
                        hint_text="This number has a curvy top, like a swan swimming! 🦢",
                        difficulty=1,
                        image_prompt="Large colorful number 2 with two cute ducks below it, cartoon style"
                    ),
                    PracticeQuestion(
                        question_text="Great! Now this one: 4 - What number do you see? 🔢",
                        expected_answer="4",
                        acceptable_answers=["4", "four", "for"],
                        hint_text="This number looks like a chair you can sit on! 🪑",
                        difficulty=1,
                        image_prompt="Large colorful number 4 with four teddy bears below it, cartoon style"
                    )
                ],
                
                independent_questions=[
                    PracticeQuestion(
                        question_text="Your turn! What number is this: 3 🌟",
                        expected_answer="3",
                        acceptable_answers=["3", "three", "tree", "free"],
                        hint_text="Count the bumps on the side... one bump, two bumps!",
                        difficulty=1,
                        image_prompt="Large number 3 with three ice cream cones, cartoon style"
                    ),
                    PracticeQuestion(
                        question_text="Excellent! And this one: 5 ✨",
                        expected_answer="5",
                        acceptable_answers=["5", "five", "fife"],
                        hint_text="This number has a flat top like a hat, and a round belly!",
                        difficulty=1,
                        image_prompt="Large number 5 with five colorful butterflies, cartoon style"
                    ),
                    PracticeQuestion(
                        question_text="Last one! What number: 1 😊",
                        expected_answer="1",
                        acceptable_answers=["1", "one", "won"],
                        hint_text="The simplest number! Just one straight line!",
                        difficulty=1,
                        image_prompt="Large number 1 with one big red apple, cartoon style"
                    )
                ],
                
                mastery_check_question="Before we move on - if I show you 4, what number is that? 🎯",
                mastery_answer="4",
                mastery_acceptable=["4", "four", "for"],
                
                common_mistakes=[
                    "Mixing up 6 and 9 (we'll learn these later!)",
                    "Confusing 2 and 5 (2 has curve at top, 5 at bottom)"
                ],
                
                encouragement_phrases=[
                    "You're learning so fast! 🌟",
                    "Numbers are becoming your friends! 😊",
                    "Great job recognizing that number! 👏"
                ],
                
                struggle_hints=[
                    "Let's look at the shape together",
                    "Try tracing the number in the air with your finger",
                    "Remember: 1 is a stick, 2 is a swan, 3 has bumps, 4 is a chair, 5 has a hat!"
                ]
            ),
            
            # -----------------------------------------------------------------
            # CONCEPT 2: Number Recognition (6-10)
            # -----------------------------------------------------------------
            ConceptContent(
                concept_id="numbers_6_to_10",
                concept_name="Meeting Numbers 6-10",
                order=2,
                
                learning_objective="Recognize and name numbers 6, 7, 8, 9, and 10",
                
                introduction_script="""
Wow! You learned 1, 2, 3, 4, and 5! 🎉

Now let's meet FIVE MORE number friends! 

These are the bigger numbers: 6, 7, 8, 9, and 10! 🔢✨

After 10, we can count even higher! But let's master these first! 🌟
                """.strip(),
                
                explanation_script="""
Let me introduce our new number friends:

6️⃣ This is SIX - it looks like a curly snail! 🐌
   SIX is five plus one more!

7️⃣ This is SEVEN - it has a line on top and goes down.
   Like a boomerang! 🪃

8️⃣ This is EIGHT - it looks like a snowman! ⛄
   Two circles stacked up!

9️⃣ This is NINE - it's like 6 but upside down!
   It has a circle on TOP and a tail going down.

🔟 This is TEN - it's special because it uses TWO digits!
    A 1 and a 0 together! This is where two-digit numbers start! 🎉

These numbers come after 5. So we count: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10! 🌟
                """.strip(),
                
                key_points=[
                    "6 is curly like a snail",
                    "7 has a flat top line",
                    "8 looks like a snowman (two circles)",
                    "9 is like an upside-down 6",
                    "10 is special - it has TWO digits!"
                ],
                
                visual_description="Numbers 6, 7, 8, 9, 10 displayed large and colorful, each with objects below (6 oranges, 7 stars, 8 balloons, 9 flowers, 10 dots arranged in two rows of 5), cartoon style",
                
                visual_explanation="""
Look at our new number friends! 🖼️😊

6️⃣ Number 6 has SIX yummy oranges! 🍊🍊🍊🍊🍊🍊
7️⃣ Number 7 has SEVEN twinkly stars! ⭐
8️⃣ Number 8 has EIGHT party balloons! 🎈
9️⃣ Number 9 has NINE pretty flowers! 🌸
🔟 Number 10 has TEN dots - see? Five on top, five on bottom! 

10 is a big number! It takes two digits to write it! 🌟
                """.strip(),
                
                examples=[
                    {
                        "problem": "What number is this: 8",
                        "solution": "EIGHT",
                        "explanation": "This is eight! See how it looks like a snowman? Two circles! ⛄"
                    },
                    {
                        "problem": "What number is this: 10",
                        "solution": "TEN",
                        "explanation": "This is ten! It's special - a 1 and a 0 together! Two digits! 🎉"
                    }
                ],
                
                guided_questions=[
                    PracticeQuestion(
                        question_text="Let's practice! What number is this: 6 🤔",
                        expected_answer="6",
                        acceptable_answers=["6", "six", "siz"],
                        hint_text="It's curly like a snail! 🐌",
                        difficulty=1,
                        image_prompt="Large number 6 with six cute snails, cartoon style"
                    ),
                    PracticeQuestion(
                        question_text="Wonderful! Now this one: 9 🔢",
                        expected_answer="9",
                        acceptable_answers=["9", "nine", "nein"],
                        hint_text="It's like 6 but upside down! Circle on top!",
                        difficulty=1,
                        image_prompt="Large number 9 with nine colorful balloons, cartoon style"
                    )
                ],
                
                independent_questions=[
                    PracticeQuestion(
                        question_text="Your turn! What number: 7 ✨",
                        expected_answer="7",
                        acceptable_answers=["7", "seven", "saven"],
                        hint_text="It has a flat line on top, like a shelf!",
                        difficulty=1,
                        image_prompt="Large number 7 with seven birds, cartoon style"
                    ),
                    PracticeQuestion(
                        question_text="Great! What about: 8 🌟",
                        expected_answer="8",
                        acceptable_answers=["8", "eight", "ate"],
                        hint_text="Two circles on top of each other - like a snowman! ⛄",
                        difficulty=1,
                        image_prompt="Large number 8 with eight fish, cartoon style"
                    ),
                    PracticeQuestion(
                        question_text="And this special one: 10 🎉",
                        expected_answer="10",
                        acceptable_answers=["10", "ten"],
                        hint_text="Two digits together! A 1 and a 0!",
                        difficulty=1,
                        image_prompt="Large number 10 with ten fingers (two hands), cartoon style"
                    )
                ],
                
                mastery_check_question="Quick check! What number is 8? 🎯",
                mastery_answer="8",
                mastery_acceptable=["8", "eight", "ate"],
                
                common_mistakes=[
                    "Mixing up 6 and 9 (6 has circle at bottom, 9 at top)",
                    "Forgetting 10 has two digits"
                ],
                
                encouragement_phrases=[
                    "You know all numbers 1-10 now! 🎉",
                    "That's amazing progress! 🌟",
                    "You're a number expert! 👏"
                ],
                
                struggle_hints=[
                    "6 curls at the bottom, 9 curls at the top",
                    "8 is like two donuts stacked up! 🍩🍩",
                    "10 is the first number with TWO digits!"
                ]
            ),
            
            # -----------------------------------------------------------------
            # CONCEPT 3: Counting Objects
            # -----------------------------------------------------------------
            ConceptContent(
                concept_id="counting_objects",
                concept_name="Counting Things Around Us",
                order=3,
                
                learning_objective="Count objects accurately from 1 to 10",
                
                introduction_script="""
Now that you know the numbers, let's USE them! 🎉

Counting means finding out HOW MANY things there are! 🔢

We count things every day:
🍎 How many apples?
⭐ How many stars?
👆 How many fingers?

Let me teach you the MAGIC of counting! ✨
                """.strip(),
                
                explanation_script="""
Here's the SECRET to counting correctly! 🤫✨

The Counting Rules:
1️⃣ Point to EACH thing ONE time
2️⃣ Say ONE number for EACH thing
3️⃣ The LAST number you say is HOW MANY!

Let me show you:

If I have apples: 🍎 🍎 🍎

I point and count:
👆🍎 "One!"
👆🍎 "Two!"
👆🍎 "Three!"

The last number was THREE! So there are 3 apples! 🎉

Important! Don't skip any, and don't count the same one twice! 😊
                """.strip(),
                
                key_points=[
                    "Touch or point to each object",
                    "Say one number for each object",
                    "Don't skip any objects",
                    "Don't count the same object twice",
                    "The last number is your answer!"
                ],
                
                visual_description="A row of 5 red apples with a cartoon hand pointing to each one, numbers 1-2-3-4-5 appearing above each apple as if counting, cartoon style, child-friendly",
                
                visual_explanation="""
Watch how I count! 🖼️👆

See the hand pointing to each apple?

👆 Point to first apple: "One!" 1️⃣
👆 Point to second apple: "Two!" 2️⃣
👆 Point to third apple: "Three!" 3️⃣
👆 Point to fourth apple: "Four!" 4️⃣
👆 Point to fifth apple: "Five!" 5️⃣

The last number was FIVE! So there are 5 apples! 🍎🍎🍎🍎🍎

Now you try! 🌟
                """.strip(),
                
                examples=[
                    {
                        "problem": "Count: ⭐⭐⭐",
                        "solution": "3",
                        "explanation": "One star, two stars, three stars! There are 3 stars! ⭐"
                    },
                    {
                        "problem": "Count: 🎈🎈🎈🎈",
                        "solution": "4",
                        "explanation": "One, two, three, four! There are 4 balloons! 🎈"
                    }
                ],
                
                guided_questions=[
                    PracticeQuestion(
                        question_text="Let's count together! How many apples? 🍎🍎🍎 Count with me: one... two... 🤔",
                        expected_answer="3",
                        acceptable_answers=["3", "three", "tree", "free"],
                        hint_text="Point to each apple: one, two, three! What's the last number?",
                        difficulty=1,
                        image_prompt="Three red apples in a row, cartoon style, numbered 1-2-3 faintly"
                    ),
                    PracticeQuestion(
                        question_text="Great! Now count these stars! ⭐⭐⭐⭐⭐ How many? 🌟",
                        expected_answer="5",
                        acceptable_answers=["5", "five", "fife"],
                        hint_text="One, two, three, four... one more! What number comes after 4?",
                        difficulty=1,
                        image_prompt="Five yellow stars in a row, cartoon style, child-friendly"
                    )
                ],
                
                independent_questions=[
                    PracticeQuestion(
                        question_text="Your turn! How many bananas? 🍌🍌🍌🍌 😊",
                        expected_answer="4",
                        acceptable_answers=["4", "four", "for"],
                        hint_text="Count each banana: one, two, three...",
                        difficulty=1,
                        image_prompt="Four yellow bananas arranged in a row, cartoon style"
                    ),
                    PracticeQuestion(
                        question_text="How many hearts? ❤️❤️❤️❤️❤️❤️ 🔢",
                        expected_answer="6",
                        acceptable_answers=["6", "six", "siz"],
                        hint_text="This is more than 5! Count carefully: one, two, three, four, five...",
                        difficulty=2,
                        image_prompt="Six red hearts arranged in a row, cartoon style"
                    ),
                    PracticeQuestion(
                        question_text="Count the flowers! 🌸🌸🌸🌸🌸🌸🌸 How many? 🌟",
                        expected_answer="7",
                        acceptable_answers=["7", "seven", "saven"],
                        hint_text="After 6 comes 7! Count slowly and carefully!",
                        difficulty=2,
                        image_prompt="Seven colorful flowers in a row, cartoon style"
                    )
                ],
                
                mastery_check_question="Quick count! How many dots: ● ● ● ● ● (5 dots)? 🎯",
                mastery_answer="5",
                mastery_acceptable=["5", "five", "fife"],
                
                common_mistakes=[
                    "Counting the same object twice",
                    "Skipping an object",
                    "Saying numbers too fast without pointing"
                ],
                
                encouragement_phrases=[
                    "You're counting like a pro! 🌟",
                    "Great counting! 👏",
                    "You didn't skip any! Perfect! ✨"
                ],
                
                struggle_hints=[
                    "Slow down and point to each one",
                    "Use your finger to touch each object",
                    "Say the number OUT LOUD as you point"
                ]
            ),
            
            # -----------------------------------------------------------------
            # CONCEPT 4: Comparing Numbers (More/Less)
            # -----------------------------------------------------------------
            ConceptContent(
                concept_id="comparing_numbers",
                concept_name="More or Less?",
                order=4,
                
                learning_objective="Compare two groups and identify which has more or less",
                
                introduction_script="""
You're so good at counting now! 🎉

Now let's learn something fun: COMPARING! 🔍

Comparing means looking at two groups and asking:
❓ Which has MORE?
❓ Which has LESS?

This helps us know which group is BIGGER! 🌟
                """.strip(),
                
                explanation_script="""
Here's how to compare two groups! 🔢

Step 1: Count the FIRST group
Step 2: Count the SECOND group  
Step 3: Which NUMBER is bigger?

The group with the BIGGER number has MORE! 📈
The group with the SMALLER number has LESS! 📉

Example:
🍎🍎🍎 (3 apples) vs 🍌🍌🍌🍌🍌 (5 bananas)

3 apples... 5 bananas...
5 is BIGGER than 3!

So bananas has MORE! ✅
And apples has LESS! ✅

Easy rule: More things = bigger number! 🌟
                """.strip(),
                
                key_points=[
                    "Count both groups first",
                    "Compare the numbers",
                    "Bigger number = MORE",
                    "Smaller number = LESS",
                    "Same number = EQUAL"
                ],
                
                visual_description="Split image: Left side shows 3 red apples with number 3, Right side shows 5 yellow bananas with number 5, an arrow pointing to bananas with text 'MORE!', cartoon style, child-friendly",
                
                visual_explanation="""
Look at this picture! 🖼️😊

On the LEFT: 3 apples 🍎🍎🍎
On the RIGHT: 5 bananas 🍌🍌🍌🍌🍌

Which number is bigger: 3 or 5? 🤔

5 is bigger! So BANANAS has MORE! 

That means APPLES has LESS! 

See? We compare by counting first! 🌟
                """.strip(),
                
                examples=[
                    {
                        "problem": "⭐⭐ vs ⭐⭐⭐⭐ - Which has more?",
                        "solution": "The second group (4 stars)",
                        "explanation": "2 stars vs 4 stars. 4 is bigger than 2, so the second group has MORE! ✨"
                    }
                ],
                
                guided_questions=[
                    PracticeQuestion(
                        question_text="Look! 🍎🍎 apples and 🍎🍎🍎🍎 apples. Which group has MORE? Say 'first' or 'second'! 🤔",
                        expected_answer="second",
                        acceptable_answers=["second", "2", "two", "the second", "right", "4", "four"],
                        hint_text="Count both! First group has 2. Second group has 4. Which number is bigger?",
                        difficulty=1,
                        image_prompt="Left side: 2 apples labeled 'First'. Right side: 4 apples labeled 'Second', cartoon style"
                    )
                ],
                
                independent_questions=[
                    PracticeQuestion(
                        question_text="Which has MORE: ⭐⭐⭐⭐⭐⭐ stars or ❤️❤️❤️ hearts? Say 'stars' or 'hearts'! 🔢",
                        expected_answer="stars",
                        acceptable_answers=["stars", "star", "6", "six", "the stars"],
                        hint_text="Count stars: 6. Count hearts: 3. Which number is bigger?",
                        difficulty=1,
                        image_prompt="6 stars on left, 3 hearts on right, cartoon style"
                    ),
                    PracticeQuestion(
                        question_text="Which has LESS: 🔵🔵🔵🔵🔵🔵🔵 balls or 🟢🟢🟢 balls? Say 'blue' or 'green'! 📉",
                        expected_answer="green",
                        acceptable_answers=["green", "3", "three", "the green"],
                        hint_text="Blue: 7. Green: 3. Which number is SMALLER?",
                        difficulty=2,
                        image_prompt="7 blue balls on left, 3 green balls on right, cartoon style"
                    ),
                    PracticeQuestion(
                        question_text="🍊🍊🍊🍊 oranges vs 🍋🍋🍋🍋 lemons. Which has more? Or are they EQUAL? 🤔",
                        expected_answer="equal",
                        acceptable_answers=["equal", "same", "both", "4", "neither", "they're the same"],
                        hint_text="Count both... oranges: 4, lemons: 4. What if they're the SAME number?",
                        difficulty=2,
                        image_prompt="4 oranges on left, 4 lemons on right, equals sign between them, cartoon style"
                    )
                ],
                
                mastery_check_question="Last check! 🎈🎈🎈🎈🎈 vs 🎈🎈 - Which has MORE? Say 'first' or 'second'! 🎯",
                mastery_answer="first",
                mastery_acceptable=["first", "1", "one", "5", "five", "left"],
                
                common_mistakes=[
                    "Forgetting to count both groups",
                    "Confusing MORE and LESS",
                    "Not recognizing when groups are EQUAL"
                ],
                
                encouragement_phrases=[
                    "Great comparing! 🌟",
                    "You know more AND less now! 👏",
                    "Your brain is getting so smart! 🧠✨"
                ],
                
                struggle_hints=[
                    "Always count BOTH groups first",
                    "Bigger number = more things",
                    "If the numbers are the same, they're EQUAL!"
                ]
            ),
            
            # -----------------------------------------------------------------
            # CONCEPT 5: Simple Addition (Introduction)
            # -----------------------------------------------------------------
            ConceptContent(
                concept_id="addition_intro",
                concept_name="Adding Numbers Together",
                order=5,
                
                learning_objective="Understand addition as putting groups together",
                
                introduction_script="""
You're doing AMAZING! 🎉🌟

Now for something really cool: ADDITION! ➕

Addition means putting things TOGETHER to find out how many TOTAL!

When you ADD, you get MORE than you started with! 

Let me show you the magic! ✨🔢
                """.strip(),
                
                explanation_script="""
Addition is like making groups into ONE BIG group! 🎉

Here's how it works:

Imagine you have 2 apples: 🍎🍎
Your friend gives you 1 more apple: 🍎

Now put them TOGETHER:
🍎🍎 + 🍎 = 🍎🍎🍎

Count all of them: 1, 2, 3!

So: 2 + 1 = 3! ✨

The + sign means "put together" or "add"!
The = sign means "equals" or "is the same as"!

Addition always makes a BIGGER number! 📈
                """.strip(),
                
                key_points=[
                    "Addition means putting together",
                    "+ means 'add' or 'plus'",
                    "= means 'equals'",
                    "Count ALL the objects together",
                    "The answer is always bigger than what you started with"
                ],
                
                visual_description="Visual addition: 2 red apples on left, plus sign, 1 red apple in middle, equals sign, 3 red apples on right. Below shows '2 + 1 = 3' in large colorful numbers, cartoon style",
                
                visual_explanation="""
Look at this picture! 🖼️➕

On the left: 2 apples 🍎🍎
In the middle: + (plus sign - this means ADD!)
Then: 1 more apple 🍎
Then: = (equals sign - this shows the answer!)
On the right: 3 apples 🍎🍎🍎

We PUT TOGETHER 2 apples and 1 apple!
Now we have 3 apples TOTAL!

2 + 1 = 3! 🎉
                """.strip(),
                
                examples=[
                    {
                        "problem": "1 + 1 = ?",
                        "solution": "2",
                        "explanation": "One apple plus one more apple! Count together: 1, 2! So 1 + 1 = 2! ✨"
                    },
                    {
                        "problem": "2 + 2 = ?",
                        "solution": "4",
                        "explanation": "Two fingers plus two more fingers! Count: 1, 2, 3, 4! So 2 + 2 = 4! 🎉"
                    }
                ],
                
                guided_questions=[
                    PracticeQuestion(
                        question_text="Let's add together! 🍎🍎 + 🍎 = ? Two apples plus one apple. Count them all! How many? 🤔",
                        expected_answer="3",
                        acceptable_answers=["3", "three", "tree", "free"],
                        hint_text="Put them together: 🍎🍎🍎 - now count: one, two, three!",
                        difficulty=1,
                        image_prompt="2 apples, plus sign, 1 apple, equals sign, question mark, cartoon style"
                    ),
                    PracticeQuestion(
                        question_text="Now try: 1 + 2 = ? One ball plus two balls! ⚽ + ⚽⚽ = ? 🔢",
                        expected_answer="3",
                        acceptable_answers=["3", "three", "tree", "free"],
                        hint_text="Together: ⚽⚽⚽ - count all the balls!",
                        difficulty=1,
                        image_prompt="1 ball, plus sign, 2 balls, equals sign, question mark, cartoon style"
                    )
                ],
                
                independent_questions=[
                    PracticeQuestion(
                        question_text="Your turn! 2 + 2 = ? ✨",
                        expected_answer="4",
                        acceptable_answers=["4", "four", "for"],
                        hint_text="Two plus two! Hold up 2 fingers, then 2 more. Count all fingers!",
                        difficulty=1,
                        image_prompt="2 stars plus 2 stars equals question mark, cartoon style"
                    ),
                    PracticeQuestion(
                        question_text="Try this: 3 + 1 = ? 🌟",
                        expected_answer="4",
                        acceptable_answers=["4", "four", "for"],
                        hint_text="Three apples, and one more! Count: 1, 2, 3... plus one more!",
                        difficulty=2,
                        image_prompt="3 apples plus 1 apple equals question mark, cartoon style"
                    ),
                    PracticeQuestion(
                        question_text="One more: 3 + 2 = ? 🔢",
                        expected_answer="5",
                        acceptable_answers=["5", "five", "fife"],
                        hint_text="Three plus two! You can use your fingers: hold up 3, then add 2 more!",
                        difficulty=2,
                        image_prompt="3 bananas plus 2 bananas equals question mark, cartoon style"
                    ),
                    PracticeQuestion(
                        question_text="Last one! 4 + 1 = ? 🎉",
                        expected_answer="5",
                        acceptable_answers=["5", "five", "fife"],
                        hint_text="Four things, add one more! What number comes after 4?",
                        difficulty=2,
                        image_prompt="4 hearts plus 1 heart equals question mark, cartoon style"
                    )
                ],
                
                mastery_check_question="Final addition check! 2 + 3 = ? 🎯",
                mastery_answer="5",
                mastery_acceptable=["5", "five", "fife"],
                
                common_mistakes=[
                    "Counting only one group, not both",
                    "Forgetting to add the second number",
                    "Counting the same object twice"
                ],
                
                encouragement_phrases=[
                    "You're ADDING like a mathematician! 🧮",
                    "Amazing addition! 🎉",
                    "Your brain is super strong! 💪🧠"
                ],
                
                struggle_hints=[
                    "Use your fingers to help count",
                    "Draw dots on paper if it helps",
                    "First count one group, then keep counting with the other group"
                ]
            ),
        ],
        
        # =====================================================================
        # CHAPTER REVIEW
        # =====================================================================
        review_questions=[
            PracticeQuestion(
                question_text="Review time! What number is this: 7 🔢",
                expected_answer="7",
                acceptable_answers=["7", "seven", "saven"],
                hint_text="It has a flat top and goes down!",
                difficulty=1
            ),
            PracticeQuestion(
                question_text="Count these: ⭐⭐⭐⭐⭐⭐ How many stars? 🌟",
                expected_answer="6",
                acceptable_answers=["6", "six", "siz"],
                hint_text="One more than 5!",
                difficulty=1
            ),
            PracticeQuestion(
                question_text="Which is more: 4 or 9? 🤔",
                expected_answer="9",
                acceptable_answers=["9", "nine", "nein"],
                hint_text="Which number is bigger?",
                difficulty=1
            ),
            PracticeQuestion(
                question_text="Final question: 3 + 3 = ? ➕",
                expected_answer="6",
                acceptable_answers=["6", "six", "siz"],
                hint_text="Three plus three! Count all together!",
                difficulty=2
            ),
        ],
        
        # =====================================================================
        # COMPLETION
        # =====================================================================
        completion_script="""
🎉🎊🥳 WOW WOW WOW! 🥳🎊🎉

YOU DID IT! You finished the WHOLE chapter!

Look at everything you learned today:
✅ Numbers 1, 2, 3, 4, 5
✅ Numbers 6, 7, 8, 9, 10
✅ How to COUNT objects
✅ How to compare - MORE and LESS
✅ How to ADD numbers!

You are a MATH SUPERSTAR! ⭐🌟💫

I am SO PROUD of you! 🏆

You worked so hard and learned SO much!

See you next time for more learning adventures! 

Bye bye, my little math genius! 👋😊❤️
        """.strip(),
        
        certificate_text="🏆 CERTIFICATE OF ACHIEVEMENT 🏆\nCompleted: Counting Fun Adventure\nYou are a Math Superstar! ⭐"
    )


# =============================================================================
# CHAPTER REGISTRY
# =============================================================================

AVAILABLE_CHAPTERS = {
    "counting": get_counting_chapter,
}


def get_chapter(chapter_id: str) -> Optional[ChapterContent]:
    """Get chapter content by ID."""
    chapter_id_lower = chapter_id.lower().strip()
    
    # Map various names to counting chapter for now
    counting_aliases = [
        "counting", "counting fun", "counting fun adventure",
        "numbers", "count", "math basics"
    ]
    
    if chapter_id_lower in counting_aliases:
        return get_counting_chapter()
    
    factory = AVAILABLE_CHAPTERS.get(chapter_id_lower)
    if factory:
        return factory()
    
    return None


def is_chapter_available(grade: int, subject: str, lesson: str) -> bool:
    """Check if chapter is available."""
    subject_lower = subject.lower().strip()
    lesson_lower = lesson.lower().strip()
    
    # For prototype, Grade 2 Math maps to counting chapter
    valid_topics = [
        "counting", "comparing and ordering", "skip counting and number patterns",
        "names of numbers", "even and odd", "mixed operations: one digit",
        "mixed operations one digit"
    ]
    
    return grade == 2 and subject_lower == "math" and lesson_lower in valid_topics
