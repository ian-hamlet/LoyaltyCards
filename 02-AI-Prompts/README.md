# AI Prompts Directory

This directory contains all AI prompts and chat logs used throughout the development process.

## Structure

### Requirements
Store prompts used to generate or refine requirements documents. Name files descriptively:
- `01_InitialRequirementsPrompt.md`
- `02_RefineUserAuthRequirements.md`

### Design
Store prompts used for design artifacts including architecture, database, and UI/UX:
- `01_SystemArchitecturePrompt.md`
- `02_DatabaseSchemaPrompt.md`
- `03_UIDesignPrompt.md`

### Code
Store prompts used for code generation:
- `01_BackendAPIPrompt.md`
- `02_FrontendComponentPrompt.md`

### ChatLogs
Store complete conversation logs with AI assistants:
- Use descriptive names with dates: `2026-03-30_RequirementsSession.md`
- Include the full conversation for reproducibility

## Best Practices

1. **Version Control**: Keep all prompts under version control
2. **Naming Convention**: Use descriptive names with sequence numbers
3. **Context Preservation**: Include enough context in prompts for reproducibility
4. **Cross-Reference**: Link prompts to their output artifacts
5. **Iterative Development**: Document prompt refinements
6. **Chat Log Format**: Save complete conversations including AI responses

## Prompt Template

```markdown
# Prompt: [Title]

## Date
[YYYY-MM-DD]

## Context
[Background information and context]

## Objective
[What you want the AI to generate or help with]

## Prompt
[The actual prompt text]

## Output Reference
[Link to the generated artifact]

## Follow-up Prompts
[Any refinement prompts used]

## Notes
[Observations, learnings, or improvements]
```

## Chat Log Template

```markdown
# Chat Log: [Title]

**Date**: [YYYY-MM-DD]  
**Session Duration**: [Time]  
**AI Model**: [Model name and version]

## Objective
[What you were trying to achieve]

## Conversation

### User
[User message]

### Assistant
[AI response]

[Continue alternating...]

## Outcomes
- [List of artifacts generated]
- [Key decisions made]
- [Follow-up actions]

## Learnings
[What worked well, what to improve]
```
