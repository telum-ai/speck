# speck-frontier-scan / 4-proposed-action-plan-reversible-change

## 4. Proposed Action Plan (Reversible Change-Cascade)
[Provide concrete instructions or story specifications to implement the changes. If any existing validated features are affected, run compute-cascade.sh to trace the blast radius.]

*[as of SHA <commit-hash> | verified against SOTA <YYYY-MM-DD>]*
```

### 5. Apply SHA Stamp & Recheck

Apply the SHA stamp to the research report:
```bash
.speck/scripts/stamp-truth.sh specs/projects/<PROJECT_ID>/project-frontier-research-report-<YYYYMMDD>.md
```

Trigger `/project-state` to record the new frontier research report under project assets and update the state.

---
