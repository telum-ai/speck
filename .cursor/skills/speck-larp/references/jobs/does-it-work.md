# speck-larp / Job A DOES-IT-WORK

1. Read persona script, evidence contract, product contract, active recipe, and target platform visual-testing node.
2. Require the contract's built artifact. Clear build caches for UX-RC+ and verify the running build SHA plus client-bundle environment; dev/HMR output is not launch proof.
3. Cold-start: clear storage/install, create the persona state, set locale/viewport/device, and confirm expected auth state.
4. Execute every persona step through the real UI. Capture screenshot, AX/semantics, timing, transcript/log, and mechanism evidence as applicable.
5. Continue after a failure so downstream defects remain visible. Record P0–P3 per failed step.
6. Run hesitation, backtracking, invalid input, network loss, server failure, and optional-skip paths named by the persona/evidence contract.
7. For each action claim, prove the mechanism fired: request accepted, row/state changed, and relevant read-back observed. No mechanism is automatic fail.
8. Confirm each relevant magic moment's trigger, beats, output, and state transition. Return a separate DOES-IT-WORK verdict.
