# Project Context: [Project Name]

## Technical Context

### Technology Stack
- **Frontend**: [Framework, version]
- **Backend**: [Framework, version]
- **Database**: [Type, version]
- **Infrastructure**: [Platform/tools]

### Architecture Patterns
- **Overall Pattern**: [Monolith/Microservices/etc]
- **API Style**: [REST/GraphQL/gRPC]
- **State Management**: [Approach]
- **Authentication**: [Method]

### Code Standards
- **Style Guide**: [Reference]
- **Testing Strategy**: [Unit/Integration/E2E percentages]
- **Documentation**: [Standards]
- **Git Workflow**: [Branching strategy]

### Design System
- **UI Framework**: [Name/custom]
- **Component Library**: [Reference]
- **Design Tokens**: [Location]
- **Accessibility Level**: [WCAG standard]

## Domain Context

### Business Domain
- **Industry**: [Type]
- **Regulations**: [Compliance needs]
- **Market Position**: [B2B/B2C/etc]

### User Context  
- **Primary Users**: [Types]
- **User Expertise**: [Technical level]
- **Usage Context**: [Desktop/Mobile/etc]

### Integration Context
- **External Systems**: [List]
- **APIs Consumed**: [Services]
- **APIs Provided**: [Services]

## Operational Context

### Deployment
- **Environments**: [Dev/Staging/Prod]
- **CI/CD Pipeline**: [Tools]
- **Monitoring**: [Tools]

### Performance Targets
- **Response Time**: [SLA]
- **Availability**: [Uptime %]
- **Scale**: [User numbers]

### Security Requirements
- **Authentication**: [Requirements]
- **Authorization**: [Model]
- **Data Protection**: [Standards]

## Project Constraints

### Timeline
- **Deadline**: [Date]
- **Milestones**: [Key dates]

### Resources
- **Team Size**: [Number]
- **Budget**: [If relevant]

### Technical Debt
- **Known Issues**: [List]
- **Planned Refactoring**: [Areas]

## Inheritance Rules

Epics inherit all project context by default and may:
- Override specific technical choices
- Add epic-specific integrations
- Define additional constraints

Stories inherit merged context (project + epic) and may:
- Specify implementation details
- Add story-specific requirements
- Never contradict inherited context
