⚡ VOLTFORM ⚡

A premium SwiftUI fitness prototype focused on **AI-personalized training programs, body analysis, muscle recovery forecasting, and progress tracking**. No meal plans, no nutrition, no login, no backend  everything runs locally.

## Requirements

- iOS 17.0+ deployment target (SwiftData + Swift Charts + `@Observable`)
- No external packages — everything uses Apple frameworks only

The camera preview works on a real device; on the simulator the body scan falls back to a simulated scan animation, and everything else works identically.

AI Program Engine

`AIProgramEngine` generates a complete, individualized program from the body scan and profile:

Architecture (MVVM + Services)

```
VOLTFORM/
├── VOLTFORMApp.swift          App entry, ModelContainer, root routing
├── Theme.swift                Design tokens (colors, card styles)
├── Models/
│   └── Models.swift           SwiftData models + domain enums
├── Services/
│   ├── RecoveryEngine.swift   personalized recovery math
│   └── Services.swift         BodyAnalysisEngine, WorkoutPlanEngine,
│                              OnboardingStateManager, NotificationService,
│                              StorageService (sample-data seeding)
├── Components/
│   └── Components.swift       PrimaryButton, OptionCard, MetricCard,
│                              RecoveryRing, MuscleRecoveryCard, SparklineChart,
│                              BottomTabBar, BodyFigurePlaceholder,
│                              WorkoutExerciseRow, DarkWorkoutCard
└── Views/
    ├── Onboarding/            Splash + 10-step onboarding flow
    ├── MainTabView.swift      Custom tab bar (Home · Workout · ➕ · Recovery · Profile)
    ├── Workout/               Today/Plan/History, live session, completed,
    │                          summary, Add Workout sheet
    ├── RecoveryAndBodyViews   Recovery forecast, Body screen, Scan Result
    └── Body/                  AVFoundation body-scan camera placeholder
```
⭐ The RecoveryEngine ⭐

Recovery is **never the same for two users**. For every muscle:

```
neededHours = baseHours(muscle)
            × fitnessLevel      (beginner +15%, advanced −10%)
            × soreness          (high +20%)
            × sleep 3-day avg   (< 6.5h → +15%)
            × hydration         (good −3%, low +6%)
            × session volume    (+10% … +25% by completed sets)
            × session length    (> 70 min → +5%)
            × bodyType→goal     (e.g. Lean→Muscular adds legs/back headroom)

recovery% = min(100, hoursSinceWorkout / neededHours × 100)
readyBy   = workoutEnd + neededHours
```

Base windows: Chest/Shoulders/Arms 48h · Core 36h · Back/Legs 72h.

Each muscle card shows the percentage, status, **"Ready by" forecast**, a 7-day Swift Charts sparkline (recovery evaluated at 20:00 each day), and an insight chip — including the **"Hasn't hit 60%"** warning when a muscle stays under 60% for 5+ days.

Every completed set in a workout session persists (exercise, muscle group, sets, reps, weight, duration, timestamp) and feeds straight back into the engine.

Swapping in real ML later

`BodyAnalysisEngine` conforms to `BodyAnalyzing`. Replace the mock with a Vision/CoreML implementation that returns the same `BodyScanResult` and nothing else changes — the plan generator and recovery engine already consume its output (body type, weak muscles, etc.).

Sample data

On first launch `StorageService` seeds a realistic week of sessions (a heavy leg day yesterday, pull/push days before that) plus sleep check-ins, so the Recovery screen immediately shows differentiated per-muscle states. Real logged workouts replace the picture over time.
