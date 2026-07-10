# VOLTFORM ⚡

A premium SwiftUI fitness prototype focused on **AI-personalized training programs, body analysis, muscle recovery forecasting, and progress tracking**. No meal plans, no nutrition, no login, no backend — everything runs locally.

## Requirements

- Xcode 15.4+ (Xcode 16 recommended)
- iOS 17.0+ deployment target (SwiftData + Swift Charts + `@Observable`)
- No external packages — everything uses Apple frameworks only

## Setup (2 minutes)

1. In Xcode: **File → New → Project → iOS App**
   - Product name: `VOLTFORM`
   - Interface: SwiftUI · Language: Swift · Storage: **None** (the code creates its own ModelContainer)
2. Delete the generated `ContentView.swift` and the generated `VOLTFORMApp.swift`.
3. Drag the entire `VOLTFORM/` source folder from this package into the project navigator (check "Copy items if needed" + your app target).
4. In the target's **Info** tab, add:
   - `NSCameraUsageDescription` → "VOLTFORM uses the camera for body scans."
5. Build & run. ✅

The camera preview works on a real device; on the simulator the body scan falls back to a simulated scan animation, and everything else works identically.

## AI Program Engine

`AIProgramEngine` generates a complete, individualized program from the body scan and profile:

- **Body analysis** (`BodyAnalysisEngine`): classifies the physique (ectomorph, mesomorph, endomorph, skinny-fat, overweight, lean, athletic, muscular), estimates body fat, lean mass, and a per-muscle development distribution with imbalance detection.
- **Split selection**: Full Body, Upper/Lower, PPL, PPL+Upper, PPL×2, Arnold Split, or Bro Split — chosen from fitness level, training days, body type and goal physique (e.g. fat-dominant bodies get high-frequency splits; advanced lifters chasing size get Arnold/Bro splits).
- **Cardio prescription**: type (walking, cycling, running, HIIT), weekly frequency and duration driven by body composition and goal; fat-dominant physiques also get post-lift finishers.
- **Core prescription**: direct ab frequency based on body-fat level and goal.
- **Volume & intensity**: sets scale with level and per-muscle weakness from the scan; rep ranges and rest periods follow the goal (strength / hypertrophy / fat loss).
- **Progressive overload**: next-session weights suggested from the user's own history (+2.5 kg on compounds when all sets were hit).
- **Continuous adaptation**: chronically under-recovered muscles are automatically deloaded; every new body scan re-targets the weak points, so the plan evolves with the user.

## Architecture (MVVM + Services)

```
VOLTFORM/
├── VOLTFORMApp.swift          App entry, ModelContainer, root routing
├── Theme.swift                Design tokens (colors, card styles)
├── Models/
│   └── Models.swift           SwiftData models + domain enums
├── Services/
│   ├── RecoveryEngine.swift   ⭐ personalized recovery math
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

## The RecoveryEngine ⭐

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

## Swapping in real ML later

`BodyAnalysisEngine` conforms to `BodyAnalyzing`. Replace the mock with a Vision/CoreML implementation that returns the same `BodyScanResult` and nothing else changes — the plan generator and recovery engine already consume its output (body type, weak muscles, etc.).

## Sample data

On first launch `StorageService` seeds a realistic week of sessions (a heavy leg day yesterday, pull/push days before that) plus sleep check-ins, so the Recovery screen immediately shows differentiated per-muscle states. Real logged workouts replace the picture over time.
