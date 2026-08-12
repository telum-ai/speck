# speck-larp / recording

1. Save step artifacts under `<dir>/larp-recordings/<build-sha>-<persona>-<step>.*`; filenames use the running build SHA.
2. Write one findings note with setup, clean-build/client-env proof, reachability attempts, step results, magic moments, mechanism evidence, defects, and separate Job A/B/C verdicts for jobs run.
3. Run banned-language lint on captured product copy when applicable.
4. Apply `.speck/scripts/stamp-truth.sh` to the findings note. Confirm every cited artifact exists and belongs to the recorded build.
5. Report all findings and open aesthetic forks; never collapse functional, FELT-GOOD, and TASTE verdicts.
