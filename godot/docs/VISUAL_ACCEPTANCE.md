# Heat Firm — Visual Acceptance Gate

Completion gate for the visual build. Every item must pass.

## Checklist

- [ ] Fresh screenshots exist at 390x844, 768x1024, 844x390, and 1366x768 in `qa/shots/`
- [ ] Zero script errors in the console of any run
- [ ] Zero horizontal overflow
- [ ] No non-uniformly stretched room art or crop sprites (uniform scale, aspect preserved)
- [ ] All six beds and primary actions (HUD + dock) visible in BOTH orientations
- [ ] Plant → harvest → craft → sell loop works
- [ ] Theme switch changes room + art instantly
- [ ] Tests pass (`PASS n/n`)

## Per-size expectations

| Size | Target | Beds | Notes |
|---|---|---|---|
| 390x844 | Phone portrait | 2x3 | Dock within thumb reach |
| 768x1024 | Tablet portrait | 2x3 | |
| 844x390 | Phone landscape | 3x2 | |
| 1366x768 | Desktop | 3x2 | |

## Rules

- The greenhouse room is the primary visual surface; UI cards support it, never cover the beds.
- Portrait and landscape are distinct compositions; never stretch one room image between aspect ratios.
