# Design System Strategy: The Sovereign Ledger

## 1. Overview & Creative North Star
The design system for this fintech experience is guided by the Creative North Star: **"The Sovereign Ledger."** 

In a landscape crowded with "friendly" fintech, this system takes an editorial approach that prioritizes authority, architectural precision, and transparency. It bridges the gap between traditional institutional finance and the decentralized innovation of Stellar. We move away from the "template" look of standard banking apps by utilizing **intentional asymmetry**, high-contrast typographic scales, and a layout philosophy rooted in depth and layering rather than rigid, bordered grids. This system doesn't just display data; it curates it into a premium, secure narrative.

---

## 2. Colors & Tonal Depth
The palette is rooted in a deep, authoritative navy and black foundation, punctuated by the technological vibrance of Stellar’s signature blue and a professional success green.

### The "No-Line" Rule
To achieve a high-end, custom feel, **1px solid borders are strictly prohibited** for sectioning or containment. Structural boundaries must be defined solely through background color shifts. Use `surface_container_low` sections sitting on a `surface` background to define areas.

### Surface Hierarchy & Nesting
Treat the UI as a physical stack of premium materials. 
*   **Base Layer:** `background` (#f8f9fa)
*   **Lower Level:** `surface_container_low` (#f3f4f5) for large grouping areas.
*   **Active Level:** `surface_container_lowest` (#ffffff) for primary interactive cards.
*   **Elevated Level:** `surface_container_high` (#e7e8e9) for secondary data or inset components.

### The "Glass & Gradient" Rule
To reflect the innovative "Stellar" influence, main CTAs and hero headers should utilize subtle gradients transitioning from `primary` (#000000) to `primary_container` (#171641). For floating elements, use **Glassmorphism**: utilize a semi-transparent `surface` color with a `backdrop-filter: blur(20px)` to create a frosted-glass effect that feels integrated into the environment.

---

## 3. Typography: The Editorial Voice
We utilize a dual-typeface strategy to balance modern tech with professional trust.

*   **Display & Headlines (Manrope):** Chosen for its geometric precision. Use `display-lg` (3.5rem) with tight letter-spacing for high-impact screens (e.g., balance displays) to create an authoritative, editorial feel.
*   **Body & Labels (Inter):** The "workhorse." `body-md` (0.875rem) provides maximum legibility for transaction logs and form fields.
*   **Typographic Contrast:** Emphasize hierarchy by pairing a `headline-sm` title with a `label-sm` in `on_surface_variant` (#47464e) for metadata. This "Big-Small" rhythm is key to the premium aesthetic.

---

## 4. Elevation & Depth
Depth is communicated through **Tonal Layering** rather than traditional structural lines or heavy shadows.

*   **The Layering Principle:** Depth is achieved by stacking surface-container tiers. A `surface_container_lowest` card placed on a `surface_container_low` background creates a soft, natural lift.
*   **Ambient Shadows:** When an element must "float" (like a modal or action sheet), use a shadow with a 24px-32px blur at 4%-6% opacity. The shadow color must be tinted with the `on_surface` token (#191c1d) to mimic natural light.
*   **The "Ghost Border" Fallback:** If a border is required for accessibility, it must be a "Ghost Border" using `outline_variant` at 15% opacity. Never use 100% opaque borders.
*   **Atmospheric Glass:** Use the `surface_tint` token as an overlay at low opacity (e.g., 5%) on top of dark navy backgrounds to give a "crystalline" depth to headers.

---

## 5. Signature Components

### Credit Limit Progress Bars
Avoid the standard thick bar. Use a sleek, 4px height track in `surface_container_highest`. The active progress uses a gradient from `secondary` (#1a4fd6) to `secondary_fixed_dim`. Use a `title-sm` font for the numerical value, positioned asymmetrically above the bar.

### Currency Conversion Cards
These cards should use the "Nesting" principle. The main container is `surface_container_lowest`. Inside, the input fields for USD and Stellar (XLM) are nested within `surface_container_low` with a `xl` (0.75rem) corner radius. No borders; use the color shift to indicate the field area.

### Transaction Status Badges
Utilize a "Low-Volume, High-Context" approach.
*   **Success:** `tertiary_container` background with `on_tertiary_container` text.
*   **Pending:** `secondary_container` background with `on_secondary_container` text.
*   **Shape:** Full pill-shape (`rounded-full`) with `label-md` uppercase typography.

### Buttons
*   **Primary:** A deep gradient from `primary_container` to `primary`. `rounded-md` (0.375rem).
*   **Secondary:** No background. Use a "Ghost Border" and `secondary` colored text.
*   **Tertiary/Text:** `on_surface` text with an icon. No container.

---

## 6. Do’s and Don’ts

### Do
*   **Do** use extreme vertical whitespace to separate sections rather than lines.
*   **Do** use `secondary` (Stellar Blue) sparingly for "moments of delight" or blockchain-specific actions.
*   **Do** align numerical data to the right in transaction lists to emphasize the "ledger" precision.
*   **Do** use the `xl` (0.75rem) corner radius for main cards to soften the professional navy palette.

### Don't
*   **Don't** use standard #000000 black for text; always use `on_surface` (#191c1d) for a more sophisticated, intentional tone.
*   **Don't** use 1px dividers between list items. Use 12px-16px of vertical spacing instead.
*   **Don't** use high-saturation reds for error states. Use the specified `error` (#ba1a1a) which is more professional and less "alarming."
*   **Don't** mix the roundedness scales. Cards are `xl`, buttons are `md`, and badges are `full`. Consistency in these primitives drives the "high-end" feel.