# SpendArc 💸

Personal finance tracker app — Flutter assessment submission.

## Architecture

Clean Architecture with 3 layers:

```
lib/
├── core/               # Shared utilities (Failure, UseCase base)
├── features/
│   └── expense/
│       ├── data/       # Models, DataSources, Repository impl
│       ├── domain/     # Entities, Repository interface, UseCases
│       └── presentation/ # BLoC, Pages, Widgets
└── injection_container.dart  # GetIt DI setup
```

## Setup

```bash
# Install dependencies
flutter pub get

# Generate Hive adapters
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app
flutter run

# Run tests
flutter test
```

## Modules Implemented

### ✅ Module 1 — Clean Architecture (20%)
- Data / Domain / Presentation layers
- `get_it` dependency injection
- UseCase abstraction with `Either<Failure, T>`
- Repository pattern

### ✅ Module 2 — Custom Animations (35%)
- **ArcMeter**: `CustomPainter` + `Canvas.drawArc()` with gradient
- **LineChart**: `Path()` + `canvas.drawPath()` — NO chart libraries
- **Spring Swipe Delete**: `Dismissible` with spring curve
- **Particle Burst**: `CustomPainter` with particle physics

### ✅ Module 3 — BLoC (20%)
- Optimistic updates with rollback on failure
- Inter-BLoC communication via stream subscription
- Proper stream disposal in `close()`

### ✅ Module 4 — Offline First (15%)
- Hive local database with instant load
- Write queue: `isSynced` flag on all records
- Background sync pattern
- `compute()` for heavy analytics (isolate)

### ✅ Module 5 — Testing (10%)
- 5 unit tests: repository (×2), usecase (×1), BLoC (×2)
- 2 widget tests: add expense form, ArcMeter
- Using `bloc_test` + `mocktail`

## Key Design Decisions

**Why Clean Architecture?** — Separation of concerns. Domain layer has zero Flutter imports, making it fully unit-testable without a device. Swapping Hive for SQLite only touches the data layer.

**Why optimistic updates?** — Perceived performance. Showing the result instantly (before DB write confirms) makes the app feel native-speed. Rollback on failure ensures correctness.

**Why shouldRepaint optimization?** — `return oldDelegate.progress != progress` prevents unnecessary canvas redraws. Without this, every parent rebuild triggers a repaint even if the progress value hasn't changed, degrading animation performance.

**Why cancel subscriptions in close()?** — Inter-BLoC subscriptions hold references. Without cancellation, a closed BLoC stays alive in memory as long as the subscription exists — a guaranteed memory leak.
