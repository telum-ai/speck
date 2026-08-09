# speck-learn / quick-examples

## Quick Examples

**Example 1: Pattern Discovery**
```
/speck-learn "PostgreSQL window functions are 10x faster than Python loops for time overlap detection"

→ Type: PATTERN
→ Summary: Use window functions for time overlaps
→ Applied: Updated plan.md with pattern note
→ Commit tag: PATTERN: Window functions for time overlaps - 10x faster
```

**Example 2: Gotcha Encountered**
```
/speck-learn "iOS certificate setup requires Apple Developer account and takes 45 minutes"

→ Type: GOTCHA  
→ Summary: iOS cert requires Apple Developer account - 45min setup
→ Applied: Updated Story S003 (also iOS) with time warning
→ Commit tag: GOTCHA: iOS cert requires Apple Developer account - 45min setup
```

**Example 3: Rule Update Needed**
```
/speck-learn "Always run VACUUM ANALYZE after bulk inserts in PostgreSQL"

→ Type: RULE
→ Summary: VACUUM ANALYZE after bulk inserts
→ Applied: Updated .cursor/rules/database.mdc
→ Commit: chore(rules): add VACUUM ANALYZE requirement after bulk inserts
```

---

**Position in Flow**: Anytime during development  
**Duration**: 2-5 minutes  
**Purpose**: Capture learnings immediately, apply where applicable  
**Relationship to Retros**: Pre-seeds retrospective data, enables validation
