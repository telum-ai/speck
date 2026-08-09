# Target build check

| Platform | Artifact |
|----------|----------|
| iOS | .app / TestFlight |
| Android | .apk/.aab |
| Web | dist/out served production-like |
| Desktop | packaged installer |
| CLI | release binary |

Dev-server for platforms that ban it → STOP.
Clean build after clearing caches for UX-RC+. Verify client-bundle env (NEXT_PUBLIC_* inlined at build). HMR false-BLOCKED → reproduce on production build.
