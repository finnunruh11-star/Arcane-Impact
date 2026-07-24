# Combat Feel Baseline

These values are an initial tuning target, not a balance contract.

| Tier | Startup | Active | Recovery | Hit-stop | Camera trauma |
| --- | ---: | ---: | ---: | ---: | ---: |
| Light | 0.08-0.14 s | 0.05-0.10 s | 0.16-0.28 s | 0.025-0.035 s | 0.10-0.20 |
| Heavy | 0.12-0.22 s | 0.06-0.12 s | 0.28-0.45 s | 0.050-0.070 s | 0.30-0.55 |
| Ultimate | 0.35-0.80 s | authored | 0.45-0.80 s | 0.080-0.100 s | 0.65-1.00 |

- Physics runs at 60 Hz.
- Legal actions may be buffered for 0.12 seconds.
- Charge previews and collision queries must share the same dimensions.
- Hit-stop pauses the combat world, not presentation, UI, or audio.
- Screen shake, flashes, rumble, and aim assistance remain independent settings.
- Control attacks damage Resolve. A Resolve break enables hard control; bosses
  recover Resolve and temporarily resist another break.