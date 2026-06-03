---
name: ClassRent
colors:
  surface: '#f8f9fb'
  surface-dim: '#d9dadc'
  surface-bright: '#f8f9fb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f4f6'
  surface-container: '#edeef0'
  surface-container-high: '#e7e8ea'
  surface-container-highest: '#e1e2e4'
  on-surface: '#191c1e'
  on-surface-variant: '#434654'
  inverse-surface: '#2e3132'
  inverse-on-surface: '#f0f1f3'
  outline: '#737685'
  outline-variant: '#c3c6d6'
  surface-tint: '#0c56d0'
  primary: '#003d9b'
  on-primary: '#ffffff'
  primary-container: '#0052cc'
  on-primary-container: '#c4d2ff'
  inverse-primary: '#b2c5ff'
  secondary: '#00687b'
  on-secondary: '#ffffff'
  secondary-container: '#50dcff'
  on-secondary-container: '#005f71'
  tertiary: '#7b2600'
  on-tertiary: '#ffffff'
  tertiary-container: '#a33500'
  on-tertiary-container: '#ffc6b2'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dae2ff'
  primary-fixed-dim: '#b2c5ff'
  on-primary-fixed: '#001848'
  on-primary-fixed-variant: '#0040a2'
  secondary-fixed: '#afecff'
  secondary-fixed-dim: '#48d7f9'
  on-secondary-fixed: '#001f27'
  on-secondary-fixed-variant: '#004e5d'
  tertiary-fixed: '#ffdbcf'
  tertiary-fixed-dim: '#ffb59b'
  on-tertiary-fixed: '#380d00'
  on-tertiary-fixed-variant: '#812800'
  background: '#f8f9fb'
  on-background: '#191c1e'
  surface-variant: '#e1e2e4'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  title-lg:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.1px
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.5px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  2xl: 48px
  gutter: 16px
  margin-mobile: 16px
  margin-desktop: 32px
---

## Brand & Style
The design system for ClassRent is built on the pillars of **Trust, Efficiency, and Modernity**. It targets students, educators, and facility managers who require a friction-less utility for managing physical spaces.

The aesthetic follows a **Modern Startup Minimalism** approach. It prioritizes clarity and functional white space to reduce cognitive load during the booking process. The interface utilizes a high-clarity typographic hierarchy and subtle depth cues to guide the user through complex scheduling tasks. The emotional response should be one of "calm productivity"—where the tool disappears and the task of finding a room becomes effortless.

## Colors
The palette is anchored by **Educational Blue (#0052CC)**, a vibrant and authoritative primary color that denotes reliability and intelligence. 

- **Primary:** Used for main actions, active states, and brand-critical elements.
- **Secondary:** A bright cyan used sparingly for success states or highlighting secondary features like "available" indicators.
- **Neutral:** A range of cool grays used for backgrounds and subtle borders to keep the UI light and airy.
- **Surface:** Pure white is used for cards and modal containers to create a distinct separation from the light gray application background.

## Typography
This design system uses **Inter** for all typographic roles. Inter’s tall x-height and systematic design ensure maximum legibility for data-dense booking screens.

Headlines use a tighter letter-spacing and semi-bold weights to appear modern and grounded. Body text maintains a generous line height (1.5x) to ensure readability during long browsing sessions. Mobile headlines are scaled down to prevent excessive line wrapping on narrow devices.

## Layout & Spacing
The system utilizes a **4px baseline grid** to ensure mathematical harmony across all components. 

- **Grid:** A 12-column fluid grid is used for desktop, 8-column for tablet, and 4-column for mobile.
- **Margins:** 16px horizontal margins on mobile devices; 32px or greater on desktop.
- **Gutters:** Standardized at 16px to maintain a compact, professional feel without crowding information.
- **Logic:** Use `md` (16px) for internal card padding and `lg` (24px) for vertical section spacing.

## Elevation & Depth
The depth model is inspired by Material Design 3 but softened for a startup aesthetic. It uses **Tonal Layers** combined with **Ambient Shadows**.

- **Level 0 (Background):** Neutral Gray (#F4F5F7).
- **Level 1 (Cards/Surface):** White (#FFFFFF) with a very soft, diffused shadow (Blur: 15px, Y: 4px, Opacity: 4% Black).
- **Level 2 (Modals/Overlays):** White (#FFFFFF) with a more pronounced shadow (Blur: 30px, Y: 8px, Opacity: 8% Black).
- **Interactions:** Hover states on cards should slightly increase the shadow spread rather than changing the background color.

## Shapes
The shape language is friendly and approachable, utilizing a **Rounded** (8px to 24px) corner strategy.

- **Small Components (Buttons, Chips, Inputs):** 8px or 12px radius.
- **Large Components (Cards, Modals, Bottom Sheets):** 16px to 24px radius.
- **Full Rounding:** Used exclusively for search bars and specific "Pill" styled status indicators to differentiate them from actionable cards.

## Components
- **Buttons:** Primary buttons are fully rounded (Pill) with a solid Educational Blue fill and white text. Secondary buttons use a subtle blue outline or tonal background.
- **Cards:** White surfaces with a 16px corner radius and a Level 1 shadow. Content should be padded by 16px.
- **Input Fields:** Outlined style with a 12px corner radius. On focus, the border thickens to 2px in Primary Blue. Labels use `label-lg` typography.
- **Bottom Navigation:** A persistent white bar with a subtle top border or very light shadow. Icons use Primary Blue for the active state with a soft tonal circle behind the active icon.
- **Filter Chips:** 8px rounded corners. Unselected: Light gray background with dark text. Selected: Primary Blue background with white text and a leading checkmark icon.
- **Booking Progress Bar:** A thin, 4px rounded track at the top of multi-step forms to show completion status without being intrusive.