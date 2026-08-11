# Constitution enforcement

Use this node only when at least two binding principles can be checked mechanically, such as banned terms, hardcoded values, forbidden imports, file-structure rules, accessibility invariants, or security constraints.

1. List each enforceable principle from `constitution.md` and the observable violation it forbids.
2. Choose the narrowest gate that can detect it:
   - user-facing language → banned-language lint;
   - imports, APIs, or code shapes → linter, AST rule, or Semgrep;
   - file and secret rules → repository scan;
   - runtime/security invariants → an integration or negative-control test.
3. Add a passing fixture and a deliberately violating fixture before trusting the gate. The violation must fail with a useful diagnostic.
4. Wire the gate into the project's normal local and CI path. A documented command that does not run is not enforcement.
5. In `constitution.md`, link each principle to its gate. Register the gate as proof in `evidence-contract.md`, and assign implementation to the relevant foundation story.
6. For principles that cannot be checked mechanically, record the reason and the human or adversarial review point that owns them.

The enforcement is complete only when valid work passes, a deliberate violation fails, the gate runs on the real change path, and an independent audit repeats at least one violation attempt.
