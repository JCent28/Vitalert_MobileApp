# Design System: VITALERT Patient Monitoring System

## 1. Visual Theme & Atmosphere
The design system for this clinical monitoring application is rooted in **Modern Clinical Minimalism** with high-fidelity telemetry utility. The interface prioritizes cognitive clarity, split-second triaging, and medical-grade reliability. Drawing inspiration from precision instrumentation and clean iOS healthcare interfaces, the UI utilizes generous white space, thin 1px crisp dividers, and a flat tonal depth model to reduce cognitive fatigue during critical care.

- **Density:** Cockpit Dense (8/10) for vital telemetry metrics and multi-bed roster lists.
- **Variance:** Predictable Balanced (3/10) for instant spatial muscle memory.
- **Motion:** Micro-pulsing cardiac sparklines and state indicators.

## 2. Color Palette & Roles
- **Primary Teal** (`#007B7F`) — Interactive brand highlights, active navigation, focused states.
- **Deep Navy Ink** (`#0B1C30`) — Primary high-contrast text, patient names, critical headings.
- **Surface Canvas** (`#F8F9FF` / `#F8FAFC`) — Background canvas surface.
- **Pure Surface** (`#FFFFFF`) — High-contrast container fill for vital cards and telemetry widgets.
- **Muted Slate** (`#64748B`) — Metric labels, timestamps, secondary metadata.
- **Normal Green** (`#2E7D32` / `#1B6D24`) — Stable vitals, within-range indicators, normal telemetry.
- **Warning Amber** (`#F59E0B`) — Deteriorating vital signs, elevated thresholds, medium alerts.
- **Critical Red** (`#D32F2F` / `#BA1A1A`) — Life-critical arrhythmias, desaturation alarms, immediate code alerts.
- **Whisper Border** (`#E2E8F0`) — 1px crisp structural borders defining cards and lists.

## 3. Typography Rules
- **Display:** `Inter` (SemiBold/Bold, `-0.02em` tracking) — High-impact clean titles and patient headers.
- **Telemetry Display:** `Inter` / Monospaced Tabular Nums (`48px`, `600` weight) — Prevent horizontal number jitter during real-time updates.
- **Body:** `Inter` (`14px`–`16px`, relaxed line height `1.5`) — Clinical notes and diagnosis records.
- **Metric Mono:** `JetBrains Mono` (`12px`–`14px`, `500` weight) — Waveform frequencies, sensor battery levels, blood pressure systolic/diastolic ratios.
- **Label Caps:** `Inter` (`11px`–`12px`, uppercase, `0.05em` tracking) — Telemetry abbreviations (`HR`, `SPO2`, `NIBP`, `RESP`, `TEMP`).

## 4. Component Stylings
- **Vital Metric Cards:** Pure white background with 1px border. Top-right contains `label-caps` for the metric type; center features large tabular vital readout; bottom contains 1.5px stroke sparkline colored to current state (Green/Amber/Red).
- **Status Badges:** Pill-shaped with a 10% opacity tinted background matching condition status, dark crisp text.
- **Patient Roster Cards:** 4px vertical color-coded urgency strip on the extreme left edge indicating highest active alert.
- **Bottom Navigation:** Clean white docking bar with 24px linear icons and teal active indicators.

## 5. Layout Principles
- Mobile-first responsive fluid column (390px viewport baseline, scaling gracefully to desktop grid).
- Strict 8px baseline grid (`xs: 4px`, `sm: 8px`, `md: 16px`, `lg: 24px`, `xl: 32px`).
- 16px side margins on mobile screens.

## 6. Design System Notes for Stitch Generation
```markdown
**DESIGN SYSTEM (REQUIRED):**
- Platform: Mobile / Web Responsive, Clinical Telemetry Dashboard
- Theme: Clean Medical Light Mode
- Background: Surface Canvas (#F8F9FF)
- Surface Cards: Pure White (#FFFFFF) with 1px border (#E2E8F0)
- Primary Accent: Precision Teal (#007B7F) for active tabs, buttons, and links
- Text Primary: Deep Navy (#0B1C30)
- Text Secondary: Muted Slate (#64748B)
- Telemetry Metrics: Monospaced/Tabular numbers for vital values (HR, SpO2, BP, Temp)
- Status Semantics: Stable (#2E7D32), Warning (#F59E0B), Critical (#D32F2F)
- Typography: Inter for UI & Headings, JetBrains Mono for metrics and timestamps
- Corner Radius: 4px (small components), 8px–12px (cards and modal sheets)
```

## 7. Anti-Patterns (Banned)
- No purple/neon glow aesthetics.
- No generic serif fonts.
- No unformatted jittering numbers (always enforce tabular numerals).
- No uncontained horizontal overflow.
- No emojis or AI copywriting fluff.
