# Greeting API

A minimal REST API for generating personalized greetings. Used exclusively for Speck orchestrator integration testing.

## Overview

This is a **test fixture project** that exists solely to validate the Speck orchestrator's state detection logic. It is not intended to be implemented.

## Vision

Provide a simple API that returns personalized greeting messages.

## Goals

1. Validate orchestrator state detection across all story phases
2. Test dependency blocking/unblocking logic
3. Ensure proper command routing

## Non-Goals

- Production deployment
- Real user adoption
- Feature completeness

## Target Users

- Speck developers testing the orchestrator

## Success Criteria

- All 10 story states are correctly detected
- Blocked/unblocked logic works correctly
- Integration tests pass
