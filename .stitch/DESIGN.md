---
name: VITALERT Clinical System
colors:
  primary: '#007D79'
  primary-dark: '#004D40'
  primary-light: '#E0F2F1'
  background: '#F8FAFC'
  surface: '#FFFFFF'
  border: '#E2E8F0'
  text-main: '#0F172A'
  text-muted: '#64748B'
  status-normal: '#10B981'
  status-warning: '#F59E0B'
  status-critical: '#EF4444'
  status-info: '#3B82F6'
typography:
  fontFamily: Inter, -apple-system, BlinkMacSystemFont, sans-serif
  h1:
    fontSize: '24px'
    fontWeight: '700'
    lineHeight: '32px'
  h2:
    fontSize: '20px'
    fontWeight: '700'
    lineHeight: '28px'
  h3:
    fontSize: '16px'
    fontWeight: '600'
    lineHeight: '24px'
  body:
    fontSize: '14px'
    fontWeight: '400'
    lineHeight: '20px'
  label:
    fontSize: '12px'
    fontWeight: '600'
    letterSpacing: '0.05em'
    textTransform: 'uppercase'
rounded:
  sm: '0.375rem'
  md: '0.5rem'
  lg: '0.75rem'
  xl: '1rem'
  full: '9999px'
---

# VITALERT Design System (NephroAsia Dialysis Center)

## 1. Visual Language & Identity
The visual identity is designed for rapid clinical decision making in dialysis centers. It balances clean clinical readability with high-contrast alert status indicators.

## 2. Color Palette
- **Primary Teal**: `#007D79` (Main brand color, active headers, primary actions)
- **Deep Teal / Dark**: `#004D40` (Primary button hover, emphasized clinical headers)
- **Clinical Critical**: `#EF4444` / `#F43F5E` (High pulse, low SpO2 alerts, critical badges)
- **Clinical Warning**: `#F59E0B` (Approaching threshold, monitoring needed)
- **Clinical Normal / Live**: `#10B981` (Vitals in range, pulse live indicator)
- **Neutral Canvas**: `#F8FAFC` (Page background)
- **Surface Cards**: `#FFFFFF` (Elevated card containers, tables)
- **Text Main**: `#0F172A` (Headings, vital numbers, patient names)
- **Text Muted**: `#64748B` (Subheadings, timestamps, field labels)

## 3. Typography
- **Typeface**: `Inter` from Google Fonts
- Clean sans-serif with tabular numeric figures for pulse rate (BPM) and oxygen saturation (SpO2).

## 4. UI Components & Patterns
- **Header**: Sticky top bar with VITALERT logo, center name ("NephroAsia Dialysis Center"), and animated LIVE pulse pill.
- **Summary Cards**: 2x2 grid displaying Active Patients, Normal, Warning, and Critical metric counters.
- **Patient Table**: Clean divided row layout displaying patient avatar badge, name, chair number, session, and vital readings.
- **Alert Cards**: Left-accent colored borders (`4px solid #EF4444` for Critical, `4px solid #F59E0B` for Warning) with quick "Acknowledge" and "View Patient Log" action buttons.
- **Modal**: Backdrop blur overlay with structured form inputs for patient intake and dialysis session initiation.

## 5. Stitch Generation Design Block
When prompting Stitch for new screens in this app, include the following design system requirement block:

```markdown
**DESIGN SYSTEM (REQUIRED):**
- **Theme**: Light Mode clinical monitoring dashboard
- **Primary Color**: #007D79 (Deep Teal), Accent: #10B981 (Live Emerald), Critical: #EF4444, Warning: #F59E0B
- **Background**: #F8FAFC, Card Surface: #FFFFFF with subtle border #E2E8F0 and soft shadow
- **Font**: Inter (sans-serif)
- **Header**: Top navigation bar with "VITALERT", subtext "NephroAsia Dialysis Center", and "LIVE" pulsing badge.
- **Layout**: Mobile-first responsive container (max-w-md or max-w-lg centered), clean rounded cards (rounded-xl), touch-friendly buttons.
```
