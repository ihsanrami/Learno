"""
=============================================================================
Curriculum Structure for Learno Educational Backend
=============================================================================
Defines WHAT topics exist (static structure).
GPT-4 generates HOW to teach each topic (dynamic content).
=============================================================================
"""

from dataclasses import dataclass
from enum import Enum
from typing import Dict, List, Optional, Tuple


class GradeLevel(Enum):
    KINDERGARTEN = 0
    FIRST = 1
    SECOND = 2
    THIRD = 3
    FOURTH = 4


class SubjectType(Enum):
    MATH = "math"
    SCIENCE = "science"
    ENGLISH = "english"
    ARABIC = "arabic"


@dataclass
class TopicInfo:
    topic_id: str
    name_en: str
    name_ar: str
    grade: GradeLevel
    subject: SubjectType
    difficulty_level: int  # 1=KG, 2=G1-2, 3=G3, 4=G4
    order: int


# =============================================================================
# COMPLETE CURRICULUM: (GradeLevel, SubjectType) -> [TopicInfo, ...]
# =============================================================================

CURRICULUM: Dict[Tuple[GradeLevel, SubjectType], List[TopicInfo]] = {

    # ─────────────────────────── KINDERGARTEN ────────────────────────────────
    (GradeLevel.KINDERGARTEN, SubjectType.MATH): [
        TopicInfo("numbers_to_3",           "Numbers to 3",               "الأرقام حتى 3",                 GradeLevel.KINDERGARTEN, SubjectType.MATH,    1, 1),
        TopicInfo("counting_to_3",          "Counting to 3",              "العد حتى 3",                    GradeLevel.KINDERGARTEN, SubjectType.MATH,    1, 2),
        TopicInfo("numbers_to_5",           "Numbers to 5",               "الأرقام حتى 5",                 GradeLevel.KINDERGARTEN, SubjectType.MATH,    1, 3),
        TopicInfo("counting_to_5",          "Counting to 5",              "العد حتى 5",                    GradeLevel.KINDERGARTEN, SubjectType.MATH,    1, 4),
        TopicInfo("one_more_one_less_to_5", "One more and one less to 5", "واحد أكثر وواحد أقل حتى 5",     GradeLevel.KINDERGARTEN, SubjectType.MATH,    1, 5),
        TopicInfo("comparing_up_to_5",      "Comparing up to 5",          "المقارنة حتى 5",                GradeLevel.KINDERGARTEN, SubjectType.MATH,    1, 6),
    ],
    (GradeLevel.KINDERGARTEN, SubjectType.SCIENCE): [
        TopicInfo("shapes_and_colors_kg",   "Shapes and colors",          "الأشكال والألوان",              GradeLevel.KINDERGARTEN, SubjectType.SCIENCE, 1, 1),
        TopicInfo("materials_kg",           "Materials",                  "المواد",                        GradeLevel.KINDERGARTEN, SubjectType.SCIENCE, 1, 2),
        TopicInfo("comparing_kg",           "Comparing",                  "المقارنة",                      GradeLevel.KINDERGARTEN, SubjectType.SCIENCE, 1, 3),
        TopicInfo("states_of_matter_kg",    "States of matter",           "حالات المادة",                  GradeLevel.KINDERGARTEN, SubjectType.SCIENCE, 1, 4),
        TopicInfo("light_and_sound_kg",     "Light and sound",            "الضوء والصوت",                  GradeLevel.KINDERGARTEN, SubjectType.SCIENCE, 1, 5),
        TopicInfo("force_and_motion_kg",    "Force and motion",           "القوة والحركة",                 GradeLevel.KINDERGARTEN, SubjectType.SCIENCE, 1, 6),
    ],
    (GradeLevel.KINDERGARTEN, SubjectType.ENGLISH): [
        TopicInfo("letters_a_to_h",         "Learn letters A-H",          "تعلم الحروف A-H",              GradeLevel.KINDERGARTEN, SubjectType.ENGLISH, 1, 1),
        TopicInfo("letters_i_to_p",         "Learn letters I-P",          "تعلم الحروف I-P",              GradeLevel.KINDERGARTEN, SubjectType.ENGLISH, 1, 2),
        TopicInfo("letters_q_to_z_kg",      "Learn letters Q-Z",          "تعلم الحروف Q-Z",              GradeLevel.KINDERGARTEN, SubjectType.ENGLISH, 1, 3),
        TopicInfo("letter_identification",  "Letter identification",      "التعرف على الحروف",             GradeLevel.KINDERGARTEN, SubjectType.ENGLISH, 1, 4),
        TopicInfo("lowercase_uppercase",    "Lowercase and uppercase",    "الحروف الصغيرة والكبيرة",       GradeLevel.KINDERGARTEN, SubjectType.ENGLISH, 1, 5),
        TopicInfo("word_recognition_kg",    "Word recognition",           "التعرف على الكلمات",            GradeLevel.KINDERGARTEN, SubjectType.ENGLISH, 1, 6),
    ],
    (GradeLevel.KINDERGARTEN, SubjectType.ARABIC): [
        TopicInfo("arabic_letters_alef_ba_ta", "Arabic letters (ا ب ت)", "الحروف العربية (ا ب ت)",        GradeLevel.KINDERGARTEN, SubjectType.ARABIC,  1, 1),
        TopicInfo("colors_arabic_kg",          "Colors in Arabic",        "الألوان",                       GradeLevel.KINDERGARTEN, SubjectType.ARABIC,  1, 2),
        TopicInfo("numbers_1_to_5_arabic",     "Numbers 1 to 5",          "الأرقام من 1 إلى 5",           GradeLevel.KINDERGARTEN, SubjectType.ARABIC,  1, 3),
        TopicInfo("animal_names_arabic",       "Animal names",            "أسماء الحيوانات",               GradeLevel.KINDERGARTEN, SubjectType.ARABIC,  1, 4),
        TopicInfo("body_parts_arabic",         "Body parts",              "أجزاء الجسم",                   GradeLevel.KINDERGARTEN, SubjectType.ARABIC,  1, 5),
        TopicInfo("simple_two_letter_words",   "Simple two-letter words", "كلمات بسيطة من حرفين",          GradeLevel.KINDERGARTEN, SubjectType.ARABIC,  1, 6),
    ],

    # ─────────────────────────── FIRST GRADE ─────────────────────────────────
    (GradeLevel.FIRST, SubjectType.MATH): [
        TopicInfo("counting_to_100",         "Counting to 100",            "العد حتى 100",                  GradeLevel.FIRST, SubjectType.MATH,    2, 1),
        TopicInfo("skip_counting",           "Skip counting",              "العد بالتخطي",                  GradeLevel.FIRST, SubjectType.MATH,    2, 2),
        TopicInfo("comparing_up_to_100",     "Comparing up to 100",        "المقارنة حتى 100",              GradeLevel.FIRST, SubjectType.MATH,    2, 3),
        TopicInfo("understand_addition",     "Understand addition",        "فهم الجمع",                     GradeLevel.FIRST, SubjectType.MATH,    2, 4),
        TopicInfo("addition_strategies_10",  "Addition strategies up to 10","استراتيجيات الجمع حتى 10",    GradeLevel.FIRST, SubjectType.MATH,    2, 5),
        TopicInfo("understand_subtraction",  "Understand subtraction",     "فهم الطرح",                     GradeLevel.FIRST, SubjectType.MATH,    2, 6),
    ],
    (GradeLevel.FIRST, SubjectType.SCIENCE): [
        TopicInfo("shapes_and_colors_g1",    "Shapes and colors",          "الأشكال والألوان",              GradeLevel.FIRST, SubjectType.SCIENCE, 2, 1),
        TopicInfo("materials_g1",            "Materials",                  "المواد",                        GradeLevel.FIRST, SubjectType.SCIENCE, 2, 2),
        TopicInfo("states_of_matter_g1",     "States of matter",           "حالات المادة",                  GradeLevel.FIRST, SubjectType.SCIENCE, 2, 3),
        TopicInfo("heating_and_cooling",     "Heating and cooling",        "التسخين والتبريد",              GradeLevel.FIRST, SubjectType.SCIENCE, 2, 4),
        TopicInfo("light_and_sound_g1",      "Light and sound",            "الضوء والصوت",                  GradeLevel.FIRST, SubjectType.SCIENCE, 2, 5),
        TopicInfo("earths_resources",        "Earth's resources",          "موارد الأرض",                   GradeLevel.FIRST, SubjectType.SCIENCE, 2, 6),
    ],
    (GradeLevel.FIRST, SubjectType.ENGLISH): [
        TopicInfo("grammar_sentences",       "Grammar and mechanics",      "قواعد اللغة والجمل",            GradeLevel.FIRST, SubjectType.ENGLISH, 2, 1),
        TopicInfo("nouns_g1",                "Nouns",                      "الأسماء",                       GradeLevel.FIRST, SubjectType.ENGLISH, 2, 2),
        TopicInfo("pronouns_g1",             "Pronouns",                   "الضمائر",                       GradeLevel.FIRST, SubjectType.ENGLISH, 2, 3),
        TopicInfo("verbs_g1",                "Verbs",                      "الأفعال",                       GradeLevel.FIRST, SubjectType.ENGLISH, 2, 4),
        TopicInfo("subject_verb_agreement",  "Subject-verb agreement",     "تطابق الفعل مع الفاعل",         GradeLevel.FIRST, SubjectType.ENGLISH, 2, 5),
        TopicInfo("silent_e",                "Silent e",                   "حرف E الصامت",                  GradeLevel.FIRST, SubjectType.ENGLISH, 2, 6),
    ],
    (GradeLevel.FIRST, SubjectType.ARABIC): [
        TopicInfo("remaining_arabic_letters","Remaining Arabic letters",   "باقي الحروف العربية",           GradeLevel.FIRST, SubjectType.ARABIC,  2, 1),
        TopicInfo("three_letter_words",      "Forming 3-letter words",     "تكوين كلمات من 3 حروف",         GradeLevel.FIRST, SubjectType.ARABIC,  2, 2),
        TopicInfo("short_vowels",            "Short vowels",               "الحركات القصيرة",               GradeLevel.FIRST, SubjectType.ARABIC,  2, 3),
        TopicInfo("fruits_vegetables_arabic","Fruits and vegetables",      "أسماء الفواكه والخضراوات",      GradeLevel.FIRST, SubjectType.ARABIC,  2, 4),
        TopicInfo("simple_sentence_g1",      "Simple Arabic sentence",     "الجملة البسيطة",                GradeLevel.FIRST, SubjectType.ARABIC,  2, 5),
        TopicInfo("singular_plural_arabic",  "Singular and plural",        "التمييز بين المفرد والجمع",     GradeLevel.FIRST, SubjectType.ARABIC,  2, 6),
    ],

    # ─────────────────────────── SECOND GRADE ────────────────────────────────
    (GradeLevel.SECOND, SubjectType.MATH): [
        TopicInfo("counting_g2",             "Counting",                   "العد",                          GradeLevel.SECOND, SubjectType.MATH,    2, 1),
        TopicInfo("comparing_ordering_g2",   "Comparing and ordering",     "المقارنة والترتيب",             GradeLevel.SECOND, SubjectType.MATH,    2, 2),
        TopicInfo("skip_counting_patterns",  "Skip-counting and number patterns", "العد بالتخطي وأنماط الأرقام", GradeLevel.SECOND, SubjectType.MATH, 2, 3),
        TopicInfo("names_of_numbers",        "Names of numbers",           "أسماء الأرقام",                 GradeLevel.SECOND, SubjectType.MATH,    2, 4),
        TopicInfo("even_and_odd",            "Even and odd",               "الأعداد الزوجية والفردية",      GradeLevel.SECOND, SubjectType.MATH,    2, 5),
        TopicInfo("addition_one_digit",      "Addition strategies one digit","استراتيجيات جمع رقم واحد",   GradeLevel.SECOND, SubjectType.MATH,    2, 6),
    ],
    (GradeLevel.SECOND, SubjectType.SCIENCE): [
        TopicInfo("materials_g2",            "Materials",                  "المواد",                        GradeLevel.SECOND, SubjectType.SCIENCE, 2, 1),
        TopicInfo("states_of_matter_g2",     "States of matter",           "حالات المادة",                  GradeLevel.SECOND, SubjectType.SCIENCE, 2, 2),
        TopicInfo("changes_of_state",        "Changes of state",           "تغيرات الحالة",                 GradeLevel.SECOND, SubjectType.SCIENCE, 2, 3),
        TopicInfo("heat_g2",                 "Heat",                       "الحرارة",                       GradeLevel.SECOND, SubjectType.SCIENCE, 2, 4),
        TopicInfo("physical_chemical_g2",    "Physical and chemical change","التغير الفيزيائي والكيميائي",  GradeLevel.SECOND, SubjectType.SCIENCE, 2, 5),
        TopicInfo("mixtures_g2",             "Mixtures",                   "المخاليط",                      GradeLevel.SECOND, SubjectType.SCIENCE, 2, 6),
    ],
    (GradeLevel.SECOND, SubjectType.ENGLISH): [
        TopicInfo("rhyming_g2",              "Rhyming",                    "القافية",                       GradeLevel.SECOND, SubjectType.ENGLISH, 2, 1),
        TopicInfo("phoneme_manipulation",    "Phoneme manipulation",       "التعامل مع الصوتيات",           GradeLevel.SECOND, SubjectType.ENGLISH, 2, 2),
        TopicInfo("letters_q_to_z_g2",       "Learn letters Q-Z",          "تعلم الحروف Q-Z",              GradeLevel.SECOND, SubjectType.ENGLISH, 2, 3),
        TopicInfo("consonant_digraphs_tri",  "Consonant digraphs and trigraphs","الأزواج والثلاثيات الحرفية", GradeLevel.SECOND, SubjectType.ENGLISH, 2, 4),
        TopicInfo("consonant_digraphs_blend","Consonant digraphs and blends","الأزواج الحرفية والمزج",      GradeLevel.SECOND, SubjectType.ENGLISH, 2, 5),
        TopicInfo("digraphs_silent_letters", "Digraphs, blends and silent letters","الأزواج والمزج والصامتة", GradeLevel.SECOND, SubjectType.ENGLISH, 2, 6),
    ],
    (GradeLevel.SECOND, SubjectType.ARABIC): [
        TopicInfo("reading_simple_words_g2", "Reading simple words",       "قراءة كلمات وجمل بسيطة",       GradeLevel.SECOND, SubjectType.ARABIC,  2, 1),
        TopicInfo("long_vowels_arabic",      "Long vowels",                "الحركات الطويلة",               GradeLevel.SECOND, SubjectType.ARABIC,  2, 2),
        TopicInfo("writing_letters_correctly","Writing letters correctly",  "كتابة الحروف بشكل صحيح",       GradeLevel.SECOND, SubjectType.ARABIC,  2, 3),
        TopicInfo("madd_arabic",             "Madd (lengthening)",         "المدود",                        GradeLevel.SECOND, SubjectType.ARABIC,  2, 4),
        TopicInfo("listening_comprehension_g2","Listening comprehension",  "الاستماع والفهم البسيط",        GradeLevel.SECOND, SubjectType.ARABIC,  2, 5),
        TopicInfo("basic_pronouns_arabic",   "Basic pronouns",             "الضمائر الأساسية",              GradeLevel.SECOND, SubjectType.ARABIC,  2, 6),
    ],

    # ─────────────────────────── THIRD GRADE ─────────────────────────────────
    (GradeLevel.THIRD, SubjectType.MATH): [
        TopicInfo("place_value_g3",          "Place value",                "القيمة المكانية",               GradeLevel.THIRD, SubjectType.MATH,    3, 1),
        TopicInfo("comparing_ordering_g3",   "Comparing and ordering",     "المقارنة والترتيب",             GradeLevel.THIRD, SubjectType.MATH,    3, 2),
        TopicInfo("rounding_g3",             "Rounding",                   "التقريب",                       GradeLevel.THIRD, SubjectType.MATH,    3, 3),
        TopicInfo("addition_three_digits",   "Addition three digits",      "جمع ثلاثة أرقام",              GradeLevel.THIRD, SubjectType.MATH,    3, 4),
        TopicInfo("subtraction_three_digits","Subtraction three digits",   "طرح ثلاثة أرقام",              GradeLevel.THIRD, SubjectType.MATH,    3, 5),
        TopicInfo("estimate_sums",           "Estimate sums",              "تقدير المجاميع",                GradeLevel.THIRD, SubjectType.MATH,    3, 6),
    ],
    (GradeLevel.THIRD, SubjectType.SCIENCE): [
        TopicInfo("materials_g3",            "Materials",                  "المواد",                        GradeLevel.THIRD, SubjectType.SCIENCE, 3, 1),
        TopicInfo("states_of_matter_g3",     "States of matter",           "حالات المادة",                  GradeLevel.THIRD, SubjectType.SCIENCE, 3, 2),
        TopicInfo("phase_change_g3",         "Phase change",               "تغير الطور",                    GradeLevel.THIRD, SubjectType.SCIENCE, 3, 3),
        TopicInfo("heat_thermal_g3",         "Heat and thermal energy",    "الحرارة والطاقة الحرارية",      GradeLevel.THIRD, SubjectType.SCIENCE, 3, 4),
        TopicInfo("physical_chemical_g3",    "Physical and chemical change","التغير الفيزيائي والكيميائي",  GradeLevel.THIRD, SubjectType.SCIENCE, 3, 5),
        TopicInfo("mixtures_g3",             "Mixtures",                   "المخاليط",                      GradeLevel.THIRD, SubjectType.SCIENCE, 3, 6),
    ],
    (GradeLevel.THIRD, SubjectType.ENGLISH): [
        TopicInfo("short_long_vowels_g3",    "Short and long vowels",      "الحروف الصوتية",                GradeLevel.THIRD, SubjectType.ENGLISH, 3, 1),
        TopicInfo("blends_digraphs_tri_g3",  "Blends, digraphs and trigraphs","المزج والأزواج",             GradeLevel.THIRD, SubjectType.ENGLISH, 3, 2),
        TopicInfo("main_idea_g3",            "Main idea",                  "الفكرة الرئيسية",               GradeLevel.THIRD, SubjectType.ENGLISH, 3, 3),
        TopicInfo("inference_theme_g3",      "Inference and theme",        "الاستنتاج والموضوع",            GradeLevel.THIRD, SubjectType.ENGLISH, 3, 4),
        TopicInfo("character_g3",            "Character",                  "الشخصية",                       GradeLevel.THIRD, SubjectType.ENGLISH, 3, 5),
        TopicInfo("text_structure_g3",       "Text structure",             "بنية النص",                     GradeLevel.THIRD, SubjectType.ENGLISH, 3, 6),
    ],
    (GradeLevel.THIRD, SubjectType.ARABIC): [
        TopicInfo("nominal_verbal_sentences","Nominal and verbal sentences","الجملة الاسمية والفعلية",      GradeLevel.THIRD, SubjectType.ARABIC,  3, 1),
        TopicInfo("verb_noun_distinction",   "Verbs and nouns",            "التمييز بين الفعل والاسم",      GradeLevel.THIRD, SubjectType.ARABIC,  3, 2),
        TopicInfo("short_text_comprehension","Reading short text",         "قراءة نص قصير وفهمه",           GradeLevel.THIRD, SubjectType.ARABIC,  3, 3),
        TopicInfo("adjectives_arabic_g3",    "Adjectives",                 "الصفات",                        GradeLevel.THIRD, SubjectType.ARABIC,  3, 4),
        TopicInfo("question_words_arabic",   "Question words",             "استخدام أدوات الاستفهام",       GradeLevel.THIRD, SubjectType.ARABIC,  3, 5),
        TopicInfo("writing_short_sentence",  "Writing 3-5 word sentence",  "كتابة جملة من 3 إلى 5 كلمات", GradeLevel.THIRD, SubjectType.ARABIC,  3, 6),
    ],

    # ─────────────────────────── FOURTH GRADE ────────────────────────────────
    (GradeLevel.FOURTH, SubjectType.MATH): [
        TopicInfo("place_value_g4",          "Place value",                "القيمة المكانية",               GradeLevel.FOURTH, SubjectType.MATH,    4, 1),
        TopicInfo("comparing_ordering_g4",   "Comparing and ordering",     "المقارنة والترتيب",             GradeLevel.FOURTH, SubjectType.MATH,    4, 2),
        TopicInfo("rounding_g4",             "Rounding",                   "التقريب",                       GradeLevel.FOURTH, SubjectType.MATH,    4, 3),
        TopicInfo("addition_g4",             "Addition",                   "الجمع",                         GradeLevel.FOURTH, SubjectType.MATH,    4, 4),
        TopicInfo("subtraction_g4",          "Subtraction",                "الطرح",                         GradeLevel.FOURTH, SubjectType.MATH,    4, 5),
        TopicInfo("multiplication_g4",       "Multiplication",             "الضرب",                         GradeLevel.FOURTH, SubjectType.MATH,    4, 6),
    ],
    (GradeLevel.FOURTH, SubjectType.SCIENCE): [
        TopicInfo("materials_g4",            "Materials",                  "المواد",                        GradeLevel.FOURTH, SubjectType.SCIENCE, 4, 1),
        TopicInfo("matter_and_mass_g4",      "Matter and mass",            "المادة والكتلة",                GradeLevel.FOURTH, SubjectType.SCIENCE, 4, 2),
        TopicInfo("states_of_matter_g4",     "States of matter",           "حالات المادة",                  GradeLevel.FOURTH, SubjectType.SCIENCE, 4, 3),
        TopicInfo("heat_thermal_g4",         "Heat and thermal energy",    "الحرارة والطاقة الحرارية",      GradeLevel.FOURTH, SubjectType.SCIENCE, 4, 4),
        TopicInfo("physical_chemical_g4",    "Physical and chemical change","التغير الفيزيائي والكيميائي",  GradeLevel.FOURTH, SubjectType.SCIENCE, 4, 5),
        TopicInfo("mixtures_g4",             "Mixtures",                   "المخاليط",                      GradeLevel.FOURTH, SubjectType.SCIENCE, 4, 6),
    ],
    (GradeLevel.FOURTH, SubjectType.ENGLISH): [
        TopicInfo("main_idea_g4",            "Main idea",                  "الفكرة الرئيسية",               GradeLevel.FOURTH, SubjectType.ENGLISH, 4, 1),
        TopicInfo("inference_theme_g4",      "Inference and theme",        "الاستنتاج والموضوع",            GradeLevel.FOURTH, SubjectType.ENGLISH, 4, 2),
        TopicInfo("character_g4",            "Character",                  "الشخصية",                       GradeLevel.FOURTH, SubjectType.ENGLISH, 4, 3),
        TopicInfo("authors_purpose",         "Author's purpose",           "غرض المؤلف",                    GradeLevel.FOURTH, SubjectType.ENGLISH, 4, 4),
        TopicInfo("authors_perspective",     "Author's perspective",       "وجهة نظر المؤلف",               GradeLevel.FOURTH, SubjectType.ENGLISH, 4, 5),
        TopicInfo("text_structure_g4",       "Text structure",             "بنية النص",                     GradeLevel.FOURTH, SubjectType.ENGLISH, 4, 6),
    ],
    (GradeLevel.FOURTH, SubjectType.ARABIC): [
        TopicInfo("types_of_sentences_ar",   "Types of sentences",         "أنواع الجمل الاسمية والفعلية",  GradeLevel.FOURTH, SubjectType.ARABIC,  4, 1),
        TopicInfo("subject_and_verb_ar",     "Subject and verb",           "الفاعل والفعل",                 GradeLevel.FOURTH, SubjectType.ARABIC,  4, 2),
        TopicInfo("masculine_feminine_ar",   "Masculine and feminine",     "المذكر والمؤنث",                GradeLevel.FOURTH, SubjectType.ARABIC,  4, 3),
        TopicInfo("plural_ar_g4",            "Plural",                     "الجمع",                         GradeLevel.FOURTH, SubjectType.ARABIC,  4, 4),
        TopicInfo("medium_text_reading",     "Reading medium text",        "قراءة نص متوسط",                GradeLevel.FOURTH, SubjectType.ARABIC,  4, 5),
        TopicInfo("short_paragraph_writing", "Writing a short paragraph",  "كتابة فقرة قصيرة",              GradeLevel.FOURTH, SubjectType.ARABIC,  4, 6),
    ],
}


# =============================================================================
# CONSTANTS
# =============================================================================

GRADE_DISPLAY_NAMES = {
    0: "Kindergarten",
    1: "First Grade",
    2: "Second Grade",
    3: "Third Grade",
    4: "Fourth Grade",
}

GRADE_AGE_RANGES = {
    0: "4-5",
    1: "5-6",
    2: "6-7",
    3: "7-8",
    4: "8-9",
}


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

def grade_int_to_enum(grade: int) -> Optional[GradeLevel]:
    for g in GradeLevel:
        if g.value == grade:
            return g
    return None


def subject_str_to_enum(subject: str) -> Optional[SubjectType]:
    s = subject.lower().strip()
    for sub in SubjectType:
        if sub.value == s:
            return sub
    return None


def get_topics(grade: int, subject: str) -> List[TopicInfo]:
    """Return all topics for a grade/subject combo."""
    g = grade_int_to_enum(grade)
    s = subject_str_to_enum(subject)
    if g is None or s is None:
        return []
    return list(CURRICULUM.get((g, s), []))


def get_topic(grade: int, subject: str, topic_id: str) -> Optional[TopicInfo]:
    """Find a topic by its exact topic_id slug."""
    for t in get_topics(grade, subject):
        if t.topic_id == topic_id:
            return t
    return None


def find_topic_by_name(grade: int, subject: str, name: str) -> Optional[TopicInfo]:
    """Find topic by display name — exact match, then partial match."""
    topics = get_topics(grade, subject)
    name_lower = name.lower().strip()

    # 1. Exact match
    for t in topics:
        if t.name_en.lower() == name_lower:
            return t

    # 2. Partial match (either direction)
    for t in topics:
        if name_lower in t.name_en.lower() or t.name_en.lower() in name_lower:
            return t

    # 3. topic_id slug match
    slug = name_lower.replace(" ", "_").replace("-", "_")
    for t in topics:
        if t.topic_id == slug:
            return t

    return None


def is_valid_topic(grade: int, subject: str, topic_id_or_name: str) -> bool:
    """True if this topic exists in the curriculum (by ID or display name)."""
    return (
        get_topic(grade, subject, topic_id_or_name) is not None
        or find_topic_by_name(grade, subject, topic_id_or_name) is not None
    )


def get_grade_display_name(grade: int) -> str:
    return GRADE_DISPLAY_NAMES.get(grade, f"Grade {grade}")


def get_grade_age_range(grade: int) -> str:
    return GRADE_AGE_RANGES.get(grade, "6-10")
