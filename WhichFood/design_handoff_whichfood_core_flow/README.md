# Handoff: WhichFood — iOS Cooking Assistant (Core Flow)

## Overview
WhichFood is an AI-powered iOS cooking assistant: users pick ingredients they already have (or snap a photo of a dish) and get a complete personalized recipe. This handoff covers the **core flow**: welcome → 5-step onboarding → home (recipe library) → preference chips → ingredient selection → AI generation → recipe detail (with cooking mode, serving scaling, remix, ingredient check-off), plus Favorites, Search/Discover, and Settings tabs.

## About the Design Files
`WhichFood Prototype.dc.html` is a **design reference created in HTML** — an interactive prototype showing intended look and behavior, not production code. The task is to **recreate this design natively in SwiftUI** (the app targets iOS and should follow Apple HIG) — or in the team's chosen stack — using its established patterns. The `ios-frame.jsx` file is only a device-frame shell for previewing; ignore it in implementation.

## Fidelity
**High-fidelity.** Colors, typography, spacing, radii, and copy are final intent. Recreate pixel-perfectly, substituting: gradient image placeholders → real food photography; inline SVG icons → SF Symbols equivalents.

## Design Tokens
Colors:
- Primary orange `#FF5722` (buttons, selection, active tab, step numbers); hover/pressed `#E64A19`
- Gradient CTA: `linear-gradient(135deg, #FF7043, #FF5722)`
- Accent amber `#FFC107` (Go Premium badge, sparkle/play icons, review link)
- Background warm off-white `#FFFBF5`; cards `#FFFFFF`
- Text primary `#1A1512`; secondary `#8A7F76`; tertiary/disabled `#C9BDB1`; inactive tab `#B0A599`
- Borders `#F0E6DC` (1–1.5px); hairline dividers `#F7F0E8`; dashed empty-state border `#EAD9C9`
- Tints: selected card / tag bg `#FFF3E0` with `#E65100` text; allergen banner `#FFF8E1` bg, `#FFECB3` border, `#7A5C00` text; chef's tip gradient `#FFF3E0 → #FFECB3`, text `#5D4037`
- Dark surface (bottom bar on ingredient screen, Start cooking button, active filter chip) `#1A1512`

Typography:
- Headings/buttons: **Montserrat** 600–800; screen titles 24–25px/700, section headers 17px/700, card titles 13.5px/600, buttons 16px/700
- Body: **Open Sans** 400–700; body 14–15px, secondary 12–13px, meta 11.5px/600
- Cooking-mode step text: Montserrat 24px/600, line-height 1.45

Spacing & shape:
- Screen padding 22–24px; card grid gap 14px (2 columns)
- Radii: buttons/cards 16–20px, chips 20–22px (pill), sheets 26px top corners, small icons 12px
- Shadows: primary button `0 8px 20px rgba(255,87,34,.3)`; card hover `0 8px 20px rgba(26,21,18,.1)`; sheet `0 -12px 40px rgba(26,21,18,.2)`
- Touch targets ≥ 44px

## Screens / Views

### 1. Welcome
Top ~55%: radial gradient hero (`#FFC107 → #FF7043 → #FF5722`, rounded bottom 36px) with white 88px rounded-square app icon (chef-hat glyph), "WhichFood" Montserrat 800 34px white, "Your personal AI chef" subtitle. Bottom: headline "Turn what's in your kitchen into tonight's dinner.", supporting copy, primary button "Let's get cooking", text link "I've been here before" (skips onboarding).

### 2. Onboarding (5 steps, one question per screen)
Header: back button (36px, white, border), progress bar (6px, track `#F0E6DC`, fill `#FF5722`, animated width = step/5), "Skip" link. Title + subtitle, then large tappable option cards (white, 2px border; selected: bg `#FFF3E0`, border `#FF5722`, filled radio/check circle). Continue button at bottom — 40% opacity until a selection exists; last step label "Let's cook".
Steps: 1 Skill (single: Just starting out / Home cook / Confident chef, each with a one-line description) · 2 Equipment (multi: Stovetop, Oven, Microwave, Blender, Air fryer, Slow cooker) · 3 Dietary (multi: No restrictions, Vegetarian, Vegan, Gluten-free, Dairy-free, Nut allergy) · 4 Servings (single: Just me / 2 people / 3–4 people / 5 or more) · 5 Notification time (single: Morning / Around noon / Evening / No thanks, with descriptions).

### 3. Home (tab: Home)
- Greeting: time-based ("Good morning/afternoon/evening") small gray + "Let's cook something great." 24px title.
- Two CTA cards side by side: **From Ingredients** (orange gradient, white text, cart icon) and **From Photo** (white, border, camera icon, hover border amber).
- "Your recipes" header + "N saved" count.
- Filter chips: All / Meaty / Vegetarian / Dessert (active: dark `#1A1512` bg, white text).
- 2-column recipe card grid: 110px image area (gradient placeholder + radial highlight), heart button top-right (30px white circle; filled orange when favorited), name, "35 min · Easy" meta.
- **Empty state** (no recipes, or filter empty): dashed-border card, 64px circular amber-tint icon, "Your cookbook is empty" / "No {filter} recipes yet", supporting copy.

### 4. Preferences ("What are you in the mood for?")
Back button, title, subtitle "Pick as many as you like…". Wrapping multi-select pill chips: Easy, Medium, Difficult, Healthy, Vegan, Vegetarian, Breakfast, Lunch, Dinner, Dessert, Hearty (selected: orange bg, white text). Bottom primary button "Choose ingredients".

### 5. Ingredient selection
Header row (back + "What's in your kitchen?" 19px). Search field (white, border, magnifier). Horizontally scrolling category chips (scrollbar hidden): Vegetables, Meat, Dairy, Grains, Fruits, Seafood, Herbs, Nuts (active: dark bg). Wrapping ingredient pill chips for active category; searching filters across ALL categories. Selected chip: orange bg + white check. When ≥1 selected: floating dark bar bottom (slides up, 20px radius): "N ingredients selected" + amber "Review ›" → opens bottom sheet.

### 6. Selected-ingredients bottom sheet
Dim overlay + sheet (26px top radius, grab handle). Title "Your ingredients", hint "Tap any item to remove it." Wrapping chips with × (removing last closes sheet). Primary button with amber sparkle icon: "Generate my recipe".

### 7. AI generation / loading
Centered: 110px animation — pulsing radial amber glow + spinning arc (`#FFE0B2` ring, orange top) + chef-hat icon. Title/subtitle vary by mode:
- Ingredients: "Cooking up your recipe…" / "Balancing your ingredients, preferences and skill level."
- Photo: "Reading your dish…" / "Identifying ingredients, technique and cuisine from your photo."
- Remix: "Remixing your recipe…" / "Rebalancing ingredients, steps and timing around your twist."
Below: 3 shimmering skeleton bars (100%/80%/60% width). Auto-advances after ~2.5s (real: on API response).

### 8. Photo source sheet (from Home "From Photo")
Bottom sheet: "Recipe from a photo", rows "Take a photo" (camera icon) and "Choose from library" (image icon), Cancel. Both lead to photo-mode generation; the photo becomes the recipe hero image.

### 9. Recipe detail
- Hero 250px: food image (gradient placeholder in prototype) with radial highlight, bottom dark fade, back + heart buttons (38px white circles), placeholder badge bottom-left.
- Tags row (amber-tint pills, `#E65100` text) → title 24px → description.
- Meta strip card: Prep / Cook / Serves / Level (uppercase 10.5px labels, bold values; Serves reflects the current serving selection).
- Nutrition: 4 tinted cards — kcal `#FFF3E0`/`#E65100`, carbs `#FFF8E1`/`#F57F17`, protein `#FBE9E7`/`#D84315`, fat `#EFEBE9`/`#5D4037`.
- **Action row**: "▶ Start cooking" (dark, amber play icon, flex 1.4) + "↻ Remix" (white, orange border-on-hover, flex 1).
- **Ingredients** card with header row: "Ingredients" + serving stepper (− / "N serv." / + in bordered pill; range 1–12). Each row: 22px rounded checkbox (checked: orange fill + white check; row text strikethrough + `#C9BDB1`), name, scaled quantity. Quantities scale linearly with servings (parse leading number incl. ¼½¾ fractions; format halves/quarters back to fractions).
- **Instructions**: numbered steps — 28px orange circle number + 14.5px text.
- Allergen banner (only if allergens exist): warning icon + "Contains: Dairy, Gluten".
- **Chef's tip** card: amber gradient, "CHEF'S TIP" label `#E65100`, tip text.
- If recipe is freshly generated (not yet saved): primary button "Save to my recipes" → saves and returns Home.

### 10. Cooking mode (full-screen over recipe)
Header: × close, progress bar, "n / total" counter. Center: 56px orange circle step number + step text (Montserrat 24px). Footer: "Back" (40% opacity on step 1) + "Next step" (flex 2, orange); final step label "Done — looks delicious" → closes. Keep screen awake while active; haptic on step change.

### 11. Remix sheet
Bottom sheet: "Remix this recipe" / "The AI will rewrite it around your twist." Three option rows (36px amber-tint icon square, title + description, chevron): **Make it vegan** (swap plant-based), **Make it spicier** (layered chili heat), **20-minute version** (streamlined). Each triggers remix generation → a modified recipe (renamed, tags/ingredients/steps/tip adjusted) shown as a new unsaved recipe.

### 12. Favorites tab
Title + 2-column grid of favorited recipes. Empty state: large outline heart (`#EAD9C9`), "No favorites yet", "Tap the heart on any recipe to keep it close at hand."

### 13. Search / Discover tab
Title "Discover", search field, 2-column grid over the full catalog, live filtering by name. Empty result: "Nothing found" + suggestion to create from ingredients.

### 14. Settings tab
Orange gradient account card: avatar circle, name, "Free plan · N AI recipes left", amber "Go Premium" badge. Grouped list rows (label, right-aligned value, chevron): Account, Premium, Recipes created, Language, Appearance, Send feedback, Rate WhichFood, Share the app. Footer: "WhichFood 1.0 · Terms · Privacy".

### 15. Tab bar
4 items: Home, Favorites, Search, Settings. Icon 22px + 10.5px bold label; active `#FF5722`, inactive `#B0A599`. Top hairline border, translucent warm-white bg.

## Interactions & Behavior
- All chips/cards/buttons: 150ms ease transitions on color/border; subtle lift or shadow on hover/press; haptic feedback on selection (iOS).
- Bottom sheets animate up 280ms ease (translateY 40px → 0); dim overlay `rgba(26,21,18,.45)`; tap outside dismisses.
- Floating "selected ingredients" bar slides up 300ms when first ingredient picked.
- Loading screen: pulse 1.8s, spinner 1.1s linear, skeleton shimmer 1.4s staggered.
- Heart toggle must `stopPropagation` from card tap.
- Back from a generated (unsaved) recipe returns Home and clears the ingredient selection.
- Free-tier counter: 3 AI generations; each generation/remix decrements (paywall when exhausted — not in this prototype).

## State Management
- `screen` (welcome / onboarding step / main / prefs / ingredients / generating / recipe), `tab`
- Onboarding answers: skill, equipment[], dietary[], servings, notificationTime
- `selectedPreferences[]`, `selectedIngredients[]`, ingredient search query, active category
- `savedRecipes[]`, `favorites[]` (ids), home filter, search query
- Recipe view: current recipe, `servings` (reset to recipe default on open), `checkedIngredients[]` (reset on open), cookingMode + stepIndex, sheets (ingredients review / photo source / remix)
- `freeGenerationsLeft`
- Data fetching: recipe generation API (ingredients + preferences + onboarding profile → full recipe JSON: name, desc, cuisine, difficulty, prep/cook time, serves, tags, allergens, nutrition {kcal, carbs, protein, fat}, ingredients [name, qty], steps[], chef tip); photo analysis API (image → same schema).

## Assets
- No bundled images: food imagery is gradient placeholders — replace with real photography (recipe hero 250px, cards 110px).
- Icons are hand-drawn inline SVGs mimicking SF Symbols — use real SF Symbols: house, heart, magnifyingglass, gearshape, cart, camera, photo, play.fill, arrow.clockwise, checkmark, chevron.right/left, xmark, exclamationmark.triangle, flame, leaf, timer.
- Fonts: Montserrat + Open Sans (Google Fonts; on iOS consider SF Pro fallback if licensing is a concern).

## Files
- `WhichFood Prototype.dc.html` — full interactive prototype (all screens, states, sample data, quantity-scaling logic worth porting).
- `ios-frame.jsx` — preview-only device frame; do not implement.
