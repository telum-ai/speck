# Speck E2E Test Setup

This is a minimal E2E test to verify the Speck story workflow orchestrator.

## Purpose

Tests that the complete story workflow executes correctly:
- story-specify → Creates spec.md
- story-clarify → Resolves ambiguities
- story-plan → Creates plan.md
- story-tasks → Creates tasks.md
- story-analyze → Quality check
- story-implement → Writes code
- story-validate → Validates implementation

## Setup

```bash
npm install
```

## Run

Start the test server:
```bash
npm start
```

## Test

Run validation tests:
```bash
npm test
```

## Story

This setup is for story S001-project-setup in epic E001-test.
See `specs/projects/test-e2e/epics/E001-test/stories/S001-project-setup/` for full specification.
