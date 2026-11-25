# Changelog

## 1.0.0
First stable release.

- Search 78 supported corruption-compatible weapons, instruments, shields and talismans by name or item ID.
- Filter by item type and rarity; preview upgrade, tier and corruption rolls using native game tooltips.
- Choose attributes from categorized menus and restore maximum base rolls for the selected item.
- Save, load, rename-by-saving, delete and undo favorites across normal UI reloads and logins.
- Shift-click supported equipment or backpack items to import upgrade, tier, corruption, runes and added stats.
- Compare an imported item with an edited configuration or favorite.
- Localized interface for eleven client languages.
- Fixed tooltip backgrounds stretching outside the window when moving the editor or comparison.
- Improved name search for accented Latin and Cyrillic text and leading/trailing spaces.
- Clear an unavailable comparison instead of leaving a previous item tooltip visible.
- Reject malformed item-link fields and malformed optional favorite data before passing them to the native preview.

### Preview assumptions
Always uses overdurability and the current character's modifiers. Instrument corruption factor: 1.35; two-handed factor: 1.5. Catalogue and maximum base rolls are curated, not a guarantee for every server item or future patch. This is an item-value preview, not a total-DPS simulator.
