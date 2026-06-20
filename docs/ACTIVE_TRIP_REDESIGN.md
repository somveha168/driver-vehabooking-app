# Active Trip Redesign — Plan

> Status: **DRAFT — awaiting approval.** No code until confirmed (standing rule).
> Date: 2026-06-20
> Goal: modernize how the driver *handles a live trip*, grounded in rideshare driver-app UX standards, adapted to our operation (vendor-assigned, scheduled Private/Airport transfers, external navigation).

## 1. Industry standards we're adopting (researched)

- **3-foot / 1-second rule** — glanceable: big legible text, high contrast, minimal clutter (Uber Design).
- **One primary action per stage** — a single dominant CTA per state; no action menus while driving.
- **Bottom-docked action** — the stage CTA lives at the bottom, in thumb reach.
- **State machine** — En route → Arrived → In Progress → Completed = our `start → arrived_location → meet_passenger → drop_passenger`.
- **Swipe reserved for the critical/irreversible step only** — tap for routine steps (faster, more accessible); swipe guards the final completion.

### What we deliberately DON'T copy
- No immersive in-app **map command center** — navigation is external (Google Maps, locked decision). An in-app map would be dead chrome. We keep **Navigate** as a one-tap external hand-off.
- No **Accept** race — vendor pre-assigns the driver. Driver starts straight into the staged flow.

## 2. Decision (locked by user)
- **Trip screen** → focused **Active-Trip screen** merging: vertical **timeline + timestamps** (glanceable progress) + **single bottom-docked stage CTA** + quick **Call/Navigate**.
- **Final step** → **swipe-to-confirm** for Drop Passenger only; **tap** for Start / Arrived / Meet.
- **Scope** → **Trip flow + list cards**. Dashboard hero left as-is.

## 3. What changes (file-by-file, additive — no logic rewrite)

### 3.1 booking_detail (the Active-Trip screen)
`lib/app/modules/booking_detail/booking_detail_view.dart`
- Replace horizontal `_TripStepper` with a **vertical timeline** widget:
  - 4 nodes: Start · Arrived · Pickup · Drop-off.
  - Each node shows its **timestamp** (`startedAt/arrivedAt/metPassengerAt/droppedAt`) when done; current node highlighted (pulse); future nodes muted.
  - Stage color from `AppColors.forStage()` (already maps the stages).
- **Hero header**: status chip + code + customer name big (3-foot rule) + Call.
- **Route block**: pickup → dropoff with the existing Navigate hand-off.
- **Action dock** (`_ActionBar` refined): one stage-aware CTA, full-width, 56px+, docked in SafeArea.
  - `start` → tap "Start Now"; `arrived` → tap "Arrived"; `meet_passenger` → tap "Meet Passenger"; `complete` → **SwipeToConfirm** "Swipe to drop passenger".
  - Keeps existing `isActing` optimistic loading + snackbar.
- Controller unchanged (start/arrived/meetPassenger/complete/runAction already correct).

### 3.2 bookings list cards
`lib/app/modules/bookings/widgets/booking_card.dart`
- Add a **stage progress dot** (small 4-node mini-indicator or colored stage dot) + a **"next action" hint** chip (e.g. "Tap to start", "Arrived?", "On board") derived from `allowedActions`.
- Tighten hierarchy: customer name primary, time/route secondary, stage chip aligned.

### 3.3 Shared widget
- New `lib/app/core/widgets/trip_timeline.dart` — the vertical timeline (reused by detail; optionally a compact variant for the card).
- Reuse existing `StatusChip`, `SwipeToConfirm`, `InfoRow`.

### 3.4 i18n
`lib/app/core/i18n/translations/{en,km}.dart`
- Add keys: timeline timestamps label (e.g. `at_time`), "next action" hints (`hint_tap_start`, `hint_tap_arrived`, `hint_on_board`), any new microcopy. Stage/button keys already exist.

## 4. Out of scope (this pass)
- Dashboard hero / next-pickup card (recently redesigned — untouched).
- FCM push to driver (polling stays; earlier decision).
- Backend (complete & verified separately).

## 5. Build order
1. `trip_timeline.dart` shared widget.
2. booking_detail_view: hero + timeline + action dock.
3. booking_card: stage dot + next-action hint.
4. i18n EN + KM.
5. `flutter analyze` + targeted widget test for the timeline + swipe path.

## 6. Acceptance
- Driver opens an assigned trip → sees timeline at "Start", one tap "Start Now".
- Each stage advances with a single glanceable action; timestamps fill in.
- Final drop requires a deliberate swipe; booking completes; screen reflects completed.
- List cards show stage + the next action at a glance.
- EN + KM both render; `flutter analyze` clean.
