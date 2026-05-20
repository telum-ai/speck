# Data Model: Project Setup

## Project Configuration Entity

### Package Manifest
**Purpose**: Defines project metadata, dependencies, and scripts

**Attributes**:
- `name`: Project identifier (string)
- `version`: Semantic version (string)
- `description`: Project description (string)
- `main`: Entry point file path (string)
- `scripts`: Command mappings (object)
  - `test`: Run test suite
  - `start`: Start application
  - `build`: Build project (if needed)
- `devDependencies`: Development dependencies (object)
- `dependencies`: Runtime dependencies (object)

**Validation Rules**:
- Name must be lowercase, URL-safe
- Version must follow semver format
- Scripts must reference valid commands

### Test Configuration
**Purpose**: Defines test framework setup

**Attributes**:
- `testEnvironment`: Runtime environment (node/jsdom)
- `testMatch`: Test file patterns (array)
- `coverageDirectory`: Coverage output location (string)

**Validation Rules**:
- Test patterns must match existing file structure
- Environment must be supported by Jest

### Git Configuration
**Purpose**: Defines version control ignore patterns

**Attributes**:
- `patterns`: List of files/directories to ignore (array)

**Common Patterns**:
- `node_modules/`: Dependencies
- `coverage/`: Test coverage reports
- `.env*`: Environment variables
- `dist/`: Build output

## State Transitions

### Project Lifecycle
```
Uninitialized → Configured → Dependencies Installed → Verified
```

**Transitions**:
1. **Initialize**: Create package.json → State: Configured
2. **Install**: Run npm install → State: Dependencies Installed  
3. **Verify**: Run test command → State: Verified

## Relationships

- Package Manifest → Test Configuration (embedded in package.json or jest.config.js)
- Package Manifest → Git Configuration (.gitignore excludes artifacts defined by scripts)
