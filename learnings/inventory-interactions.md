# Inventory interactions

## What needed extra clarification

The inventory/equipment flow has several behavior details that were refined after initial changes. Future edits should preserve them.

## Weapon selection and equipped slots

- The active weapon must stay synced with equipped slot changes.
- Picking up or moving a weapon into an equipped slot should select the correct weapon when appropriate.
- Unequipping a weapon should not leave it active in the player's hands.
- `1`, `2`, and `3` should select the specific equipped slots in order: primary, secondary, melee.
- `Q` and `E` cycle through occupied equipped weapons.

## Quick move behavior

- Shift-click should quick-move items into or out of equipped slots when valid.
- Quick moves must respect slot fit and available backpack space.

## Swap behavior

- Dragging onto an occupied equipped slot can quick-swap if the dragged item is valid for that slot and the displaced item has a valid destination.
- Dragging an equipped item onto an occupied backpack item can quick-swap if the backpack item is valid for the equipped destination.
- Backpack-to-backpack swaps are allowed too.
- Swaps must be validated atomically so they never create overlap or leave one item without a valid destination.

## Rotation behavior

- Rotating a dragged item should not be limited to items that already started in the backpack.
- A player should be able to grab an equipped item, rotate it while dragging, and place it into the backpack without dropping and picking it up again.

## Future changes should preserve

- no overlap after move or swap
- no stale equipped weapon state after equip or unequip
- quick inventory interactions that feel convenient instead of fiddly
