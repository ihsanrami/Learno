/// =============================================================================
/// Enums for Learno App
/// =============================================================================
/// 🔄 UPDATED: Added learning level and teaching style enums
/// =============================================================================

enum Grade {
  kindergarten,
  first,
  second,
  third,
  fourth,
}

enum Subject {
  english,
  arabic,
  science,
  math,
  stories,
}

enum ResponseType {
  intro,
  question,
  praise,
  encouragement,
  hint,
  redirect,
  welcome,           // 🆕
  resume,            // 🆕
  explanation,       // 🆕
  celebration,       // 🆕
}

enum SessionStatus {
  idle,
  active,
  complete,
  error,
}

enum ChatMode {
  voice,
  text,
}

/// 🆕 NEW: Student learning level
enum LearningLevel {
  struggling,    // يحتاج مساعدة
  developing,    // يتعلم
  proficient,    // جيد
  advanced,      // ممتاز
}

/// 🆕 NEW: Teaching style based on level
enum TeachingStyle {
  extraSupport,   // شرح أكثر، صور أكثر
  standard,       // عادي
  accelerated,    // أسرع
  challenge,      // تحدي
}
