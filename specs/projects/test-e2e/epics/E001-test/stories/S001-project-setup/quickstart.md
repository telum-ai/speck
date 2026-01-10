# Quickstart: Project Setup Validation

**Story**: S001-project-setup  
**Purpose**: Manual validation steps to verify the project setup is complete and functional.

---

## Prerequisites
- Node.js 18+ installed
- npm installed
- Git repository cloned

---

## Test Scenarios

### Scenario 1: Project Initialization
**Objective**: Verify package.json exists with correct metadata

**Steps**:
1. Navigate to project root
2. Check if package.json exists:
   ```bash
   ls -la package.json
   ```
3. Verify package.json contains:
   - name field
   - version field
   - Express.js dependency

**Expected Result**: ✅ package.json exists with valid structure

---

### Scenario 2: Dependency Installation
**Objective**: Verify npm install works correctly

**Steps**:
1. From project root, run:
   ```bash
   npm install
   ```
2. Verify node_modules directory created
3. Check Express.js installed:
   ```bash
   ls -la node_modules/express
   ```

**Expected Result**: ✅ Dependencies install successfully, node_modules exists

---

### Scenario 3: Folder Structure
**Objective**: Verify standard folders exist

**Steps**:
1. Check for src/ directory:
   ```bash
   ls -la src/
   ```
2. Check for tests/ directory:
   ```bash
   ls -la tests/
   ```

**Expected Result**: ✅ Both src/ and tests/ directories exist

---

### Scenario 4: Test Execution
**Objective**: Verify test suite runs

**Steps**:
1. Run tests:
   ```bash
   npm test
   ```

**Expected Result**: ✅ Tests execute and pass

---

## Troubleshooting

### Issue: npm install fails
- **Check**: Node.js version (should be 18+)
- **Solution**: Upgrade Node.js or check package.json syntax

### Issue: Tests don't run
- **Check**: Jest is installed in devDependencies
- **Solution**: Run `npm install --save-dev jest`

---

## Success Criteria Checklist
- [ ] package.json exists and is valid
- [ ] npm install completes without errors
- [ ] src/ directory exists
- [ ] tests/ directory exists
- [ ] npm test runs successfully
- [ ] README.md provides clear instructions
