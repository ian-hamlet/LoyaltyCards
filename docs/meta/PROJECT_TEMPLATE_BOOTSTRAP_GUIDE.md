# Project Template Bootstrap Guide

**Created:** April 22, 2026  
**Purpose:** Guide for using LoyaltyCards as a template for new projects  
**Template Version:** 1.0

---

## Overview

This document explains how to use the LoyaltyCards project structure as a template for starting new software projects. The documentation structure, AI agent guidelines, and organizational patterns have been battle-tested and provide an excellent foundation for new development.

---

## What Makes This a Good Template?

### ✅ Comprehensive Documentation Structure
- **Organized by purpose** - deployment, development, legal, technical, quality
- **AI-friendly** - includes agent response guidelines and prompting patterns
- **Process-oriented** - defect tracking, requirements, version management
- **Quality-focused** - testing strategy, code review templates, lessons learned

### ✅ Proven Workflows
- Git branching strategy (main → develop → feature branches)
- AI agent interaction patterns and preferences
- Code review processes
- TestFlight deployment procedures
- Defect tracking and resolution workflows

### ✅ Legal Foundations
- Privacy policy template
- Terms of service template
- Accessibility statement

### ✅ Development Standards
- AI prompting guidelines
- Code review templates
- Development standards documentation
- Response formatting guidelines

---

## Quick Start: 5-Minute Bootstrap

### Step 1: Clone and Rename
```bash
# Clone as template for your new project
git clone [LoyaltyCards-repo] MyNewProject
cd MyNewProject

# Remove git history and start fresh
rm -rf .git
git init
git branch -M main

# Create develop branch
git checkout -b develop
```

### Step 2: Update Root Files
1. **README.md** - Replace with your project description
2. **CHANGELOG.md** - Clear history, add v0.1.0 placeholder
3. **DOCUMENTATION_INDEX.md** - Keep structure, update project name

### Step 3: Clean Source Directory
```bash
# Remove all app-specific code
rm -rf source/customer_app source/supplier_app source/shared

# Keep documentation about source structure
# You'll recreate source/ when you start coding
```

### Step 4: Update Key Documentation Files
See detailed list below in "Files to Update Immediately"

### Step 5: First Commit
```bash
git add .
git commit -m "Initial project structure from LoyaltyCards template"
git push origin develop
```

---

## Detailed Bootstrap Process

### Phase 1: Project Setup (Day 1)

#### Files to Update Immediately

**Root Level:**
- [ ] `README.md` - Project name, description, purpose
- [ ] `CHANGELOG.md` - Clear all entries, start fresh
- [ ] `DOCUMENTATION_INDEX.md` - Update project name throughout

**docs/meta/:**
- [ ] `PROJECT_METADATA.md` - Update all fields (name, description, tech stack, team)
- [ ] Keep all other files as templates/examples

**docs/project-management/:**
- [ ] `NEXT_ACTIONS.md` - Clear all actions, add initial setup tasks
- [ ] `DEFECT_TRACKER.md` - Clear all defects, keep structure/format
- [ ] `PROJECT_DEVELOPMENT_PLAN.md` - Adapt timeline and milestones
- [ ] `Requirements/` - Clear all REQ-* files, keep README.md as template
- [ ] `UserStories/` - Clear all user stories, keep folder structure

**docs/development/:**
- [ ] Keep ALL files - these are generic and reusable
- [ ] `DEVELOPMENT_STANDARDS.md` - Review and adapt to your tech stack
- [ ] No changes needed to AI agent guidelines (universal)

**docs/legal/:**
- [ ] `PRIVACY_POLICY.md` - Update company name, data collection details
- [ ] `TERMS_OF_SERVICE.md` - Update company name, service description
- [ ] `ACCESSIBILITY_STATEMENT.md` - Update company name, commitment details

**docs/deployment/:**
- [ ] `APP_STORE_SUBMISSION_CHECKLIST.md` - Keep as template, adapt later
- [ ] `TESTFLIGHT_DEPLOYMENT_GUIDE.md` - Keep as template
- [ ] `TESTFLIGHT_TESTING_GUIDE.md` - Keep as template
- [ ] `RELEASES.md` - Clear all releases, keep structure
- [ ] Delete `APP_ICON_PROMPTS.txt` (project-specific)
- [ ] `ROLLBACK_PROCEDURES.md` - Keep as template
- [ ] `SUPPORT_PROCEDURES.md` - Keep as template

**docs/technical/:**
- [ ] `DATABASE_SCHEMA.md` - Replace with your schema (keep format)
- [ ] `DEPENDENCIES.md` - Clear all dependencies, keep structure
- [ ] `SECURITY_MODEL.md` - Adapt to your security requirements
- [ ] `PERFORMANCE_BASELINES.md` - Keep structure, clear baseline data
- [ ] `Architecture/` - Clear all DECISION_*.md files, keep folder

**docs/quality/:**
- [ ] Keep ALL files as templates and examples
- [ ] `TESTING_STRATEGY.md` - Adapt test categories to your project
- [ ] `LESSONS_LEARNED.md` - Clear entries, keep structure
- [ ] Review reports are examples to reference

**docs/user/:**
- [ ] `ABOUT_[PROJECTNAME].md` - Rewrite for your project
- [ ] `USER_GUIDE.md` - Rewrite for your project

#### Files to Delete
- `source/` - Entire directory (will recreate when coding starts)
- Any build artifacts or generated files
- Project-specific icon prompts, design assets
- Specific requirement/user story files (keep folder structure)

#### Files to Keep As-Is (No Changes Needed)
- `docs/development/AI_AGENT_RESPONSE_GUIDELINES.md` ✅
- `docs/development/AI_PROMPTING_GUIDE.md` ✅
- `docs/development/CODE_REVIEW_PROMPT_TEMPLATE.md` ✅
- `docs/development/QUICK_REVIEW_PROMPT.md` ✅
- `docs/quality/PROCESS_IMPROVEMENTS.md` ✅
- `docs/quality/REVIEW_PROCESS_EXPLANATION.md` ✅
- All defect workflow documentation (generic patterns)

---

### Phase 2: Requirements Discovery (Week 1)

Use the existing template structure:

1. **Start with requirements discovery**
   - Use `docs/project-management/Requirements/00-REQUIREMENTS_DISCOVERY.md` as template
   - Create new requirement files following REQ-XXX pattern

2. **Define user stories**
   - Use `docs/project-management/UserStories/` folder
   - Follow existing user story format

3. **Update project plan**
   - Adapt `PROJECT_DEVELOPMENT_PLAN.md` to your timeline
   - Set realistic milestones

4. **Define architecture**
   - Create architecture decision records in `docs/technical/Architecture/`
   - Follow DECISION_*.md naming pattern

---

### Phase 3: Technical Foundation (Week 2)

1. **Database schema design**
   - Update `DATABASE_SCHEMA.md` with your tables/collections
   - Keep the clear documentation format

2. **Security model**
   - Adapt `SECURITY_MODEL.md` to your authentication/authorization needs
   - Document threat model

3. **Define dependencies**
   - List all frameworks, libraries in `DEPENDENCIES.md`
   - Document why each was chosen

4. **Set up source directory**
   ```bash
   mkdir -p source/
   # Create your app structure here
   # Follow similar patterns (separate apps, shared code, etc.)
   ```

---

### Phase 4: Development Setup (Week 2-3)

1. **Configure development standards**
   - Review and adapt `DEVELOPMENT_STANDARDS.md`
   - Set up linting, formatting rules
   - Define coding conventions

2. **Set up AI memory preferences**
   - Copy AI agent guidelines to `~/.copilot/memories/` or equivalent
   - Ensure terminal command permission preferences are set

3. **Create initial codebase**
   - Use AI agents following the prompting guidelines
   - Document architectural decisions as you go

4. **Set up testing framework**
   - Implement testing strategy from `TESTING_STRATEGY.md`
   - Create first tests

---

### Phase 5: Ongoing Development

1. **Use defect tracking**
   - Log issues in `DEFECT_TRACKER.md`
   - Follow the CR-XXX/BUG-XXX pattern

2. **Maintain NEXT_ACTIONS.md**
   - Keep backlog updated
   - Track completed items

3. **Update CHANGELOG.md**
   - Document all significant changes
   - Use semantic versioning

4. **Request code reviews**
   - Use `CODE_REVIEW_PROMPT_TEMPLATE.md`
   - Document findings in `docs/quality/`

5. **Track lessons learned**
   - Add insights to `LESSONS_LEARNED.md`
   - Update process improvements

---

### Phase 6: Dependency & Tool Maintenance (Ongoing)

#### Keep Development Tools Current

**Before Starting Each Development Session:**
```bash
# Check your platform's tooling
flutter --version              # For Flutter projects
node --version && npm --version # For Node/React Native
python --version               # For Python projects
```

**Monthly Tool Updates:**
- [ ] IDE (VS Code, Android Studio, Xcode) - latest stable version
- [ ] Platform SDKs (Android SDK, iOS SDK via Xcode)
- [ ] Build tools (Gradle, CocoaPods, npm, etc.)
- [ ] Version control tools (git, git-lfs)
- [ ] Debugging tools (Chrome DevTools, Flutter DevTools)

**Why This Matters:**
- Security patches and bug fixes
- New features and performance improvements
- Compatibility with latest OS versions
- Better AI agent integration (newer IDEs)

#### Monitor and Update Dependencies

**Weekly Dependency Checks:**
```bash
# Flutter projects
flutter pub outdated           # Shows outdated packages
flutter pub upgrade           # Updates within version constraints

# Node/React Native projects
npm outdated                  # Shows outdated packages
npm update                    # Updates within semver constraints

# Python projects
pip list --outdated           # Shows outdated packages

# Check for security vulnerabilities
flutter pub audit             # Flutter (requires Flutter 3.19+)
npm audit                     # Node.js
pip-audit                     # Python (install: pip install pip-audit)
```

**Document in DEPENDENCIES.md:**
```markdown
## Current Versions (Updated: 2026-04-22)

### Core Framework
- Flutter: 3.19.0
- Dart: 3.3.0

### Key Dependencies
- shared_preferences: ^2.2.2 (chosen for: stability, wide adoption)
- sqlite3: ^2.4.0 (chosen for: performance, ACID compliance)
- pointycastle: ^3.7.4 (chosen for: comprehensive crypto support)

### Why These Versions
- Flutter 3.19+ required for security audit features
- Dart 3.3+ for improved null safety
- Dependencies on latest stable (not bleeding edge)

### Update Policy
- Check for updates: Every Monday
- Security patches: Apply immediately
- Major versions: Review changelog, test in branch first
- Breaking changes: Schedule dedicated update sprint
```

#### Automated Dependency Management

**Set Up Dependabot (GitHub):**
1. Create `.github/dependabot.yml`:
```yaml
version: 2
updates:
  - package-ecosystem: "pub"
    directory: "/source/customer_app"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
    
  - package-ecosystem: "pub"
    directory: "/source/supplier_app"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
```

**Benefits:**
- Automatic PR creation for dependency updates
- Security vulnerability alerts
- Changelog summaries in PR descriptions
- Configurable update frequency

**Alternative: Renovate Bot**
- More customizable than Dependabot
- Better monorepo support
- Dependency grouping options
- Free for open source

#### Security Vulnerability Monitoring

**Set Up GitHub Security Alerts:**
1. Repository Settings → Security → Dependabot alerts (enable)
2. Set notification preferences
3. Review alerts weekly

**Subscribe to Framework Security Advisories:**
- Flutter: https://groups.google.com/g/flutter-announce
- React Native: https://github.com/facebook/react-native/security
- Your backend framework's security mailing list

**Document Vulnerabilities:**
- Add critical CVEs to `docs/quality/VULNERABILITIES.md`
- Track remediation in `DEFECT_TRACKER.md`
- Update `CHANGELOG.md` when patching

#### Platform-Specific Update Strategies

**Flutter Projects:**
```bash
# Check Flutter channel
flutter channel               # Stable recommended for production

# Upgrade Flutter itself
flutter upgrade

# Upgrade project dependencies
cd source/customer_app && flutter pub upgrade
cd source/supplier_app && flutter pub upgrade
cd source/shared && flutter pub upgrade

# Clean and rebuild after updates
flutter clean && flutter pub get
```

**iOS/Xcode Updates:**
- Update Xcode via App Store (major) or Xcode Releases (beta)
- Update CocoaPods: `sudo gem install cocoapods`
- Re-run pod install after updates: `cd ios && pod install`
- Test on latest iOS simulator versions

**Android Studio/Gradle:**
- Update Android Studio via built-in updater
- Update Gradle wrapper: `./gradlew wrapper --gradle-version=X.X.X`
- Update Android SDK via SDK Manager
- Test on latest Android emulator images

#### Breaking Change Management

**When Dependencies Have Breaking Changes:**

1. **Create update branch**
   ```bash
   git checkout -b chore/update-flutter-3.20
   ```

2. **Read migration guides**
   - Framework changelog
   - Dependency changelogs
   - Breaking changes documentation

3. **Update incrementally**
   - One major dependency at a time
   - Run tests after each update
   - Document changes needed

4. **Update documentation**
   - `DEPENDENCIES.md` - New versions
   - `CHANGELOG.md` - Migration notes
   - `docs/technical/Architecture/` - Any architectural changes

5. **Request code review**
   - Use CODE_REVIEW_PROMPT_TEMPLATE
   - Focus on migration-related changes
   - Verify no regressions

#### Dependency Update Checklist

Before merging dependency updates:

- [ ] All tests pass
- [ ] App builds successfully for all platforms
- [ ] Manual testing of key features
- [ ] Performance benchmarks checked (no regressions)
- [ ] Security audit passes (`flutter pub audit` / `npm audit`)
- [ ] Documentation updated (`DEPENDENCIES.md`, `CHANGELOG.md`)
- [ ] Breaking changes documented in commit message

#### Long-Term Maintenance Schedule

**Weekly:**
- [ ] Check for security alerts
- [ ] Review Dependabot/Renovate PRs
- [ ] Quick dependency outdated check

**Monthly:**
- [ ] Update all patch versions (`flutter pub upgrade --major-versions`)
- [ ] Update IDE and build tools
- [ ] Review and update DEPENDENCIES.md
- [ ] Clean up unused dependencies

**Quarterly:**
- [ ] Evaluate major version upgrades
- [ ] Review framework roadmap for upcoming changes
- [ ] Audit all dependencies for continued maintenance
- [ ] Update Flutter/SDK to latest stable major version

**Annually:**
- [ ] Major dependency audit (remove unused, consolidate duplicates)
- [ ] Platform SDK major version updates (iOS, Android)
- [ ] Review and update entire tech stack strategy
- [ ] Document year's major technical decisions

---

## Key Patterns to Maintain

### 1. Documentation Organization
```
docs/
├── deployment/       ← App Store, TestFlight, releases
├── development/      ← AI guidelines, standards, prompts
├── legal/           ← Privacy, terms, accessibility
├── meta/            ← Project metadata, documentation about docs
├── project-management/  ← Requirements, stories, defects, planning
├── quality/         ← Testing, reviews, lessons learned
├── technical/       ← Architecture, database, security, performance
└── user/           ← User-facing documentation
```

### 2. File Naming Conventions
- **Requirements:** `REQ-001_Descriptive_Name.md`
- **User Stories:** `US-001_Descriptive_Name.md`
- **Architecture Decisions:** `DECISION_Topic_Name.md`
- **Defects:** `BUG-XXX` or `CR-XXX` (Change Request) in tracker

### 3. Version Management
- Use semantic versioning: `v0.1.0`, `v0.2.0`, etc.
- Document in `CHANGELOG.md`
- Tag releases in git: `git tag v0.1.0`

### 4. Git Branching
```
main          ← Production releases only
  ↑
develop       ← Integration branch for features
  ↑
feature/*     ← Individual features/fixes
```

### 5. AI Agent Interaction
- Always use prompting guidelines from `docs/development/`
- Request explicit code reviews before production
- Follow terminal command permission preferences
- Never auto-commit to git

---

## Template Advantages

### For Solo Developers
- ✅ Clear structure prevents "where should this go?" questions
- ✅ AI agent guidelines ensure consistent quality
- ✅ Process documentation you can actually follow
- ✅ Built-in reminders (checklists, workflows)

### For Teams
- ✅ Onboarding documentation built-in
- ✅ Shared understanding of workflows
- ✅ Clear responsibility boundaries
- ✅ Communication patterns established

### For AI-Assisted Development
- ✅ AI agents know where to find/create files
- ✅ Prompting patterns proven to work
- ✅ Code review processes established
- ✅ Quality gates enforced

---

## Customization Guidelines

### What to Keep Exactly As-Is
1. **AI Agent Response Guidelines** - Universal formatting rules
2. **AI Prompting Guide** - Code generation patterns work everywhere
3. **Code Review Templates** - Generic quality checkpoints
4. **Defect Workflow** - Process patterns are universal

### What to Adapt
1. **Database Schema** - Obviously project-specific
2. **Architecture Decisions** - Will vary by project
3. **Dependencies** - Different tech stack
4. **Testing Strategy** - Adapt test types to your needs
5. **Legal Documents** - Update company/service details

### What to Replace Completely
1. **Requirements** - Start fresh for new project
2. **User Stories** - Project-specific
3. **Source Code** - Complete replacement
4. **Performance Baselines** - Measure your own app
5. **Icon/Design Assets** - Project-specific

---

## Project Types This Template Suits

### ✅ Excellent Fit
- Mobile apps (iOS, Android)
- Multi-tenant applications
- Apps with 2+ user types
- Projects with significant documentation needs
- AI-assisted development projects
- Projects requiring App Store deployment
- Solo developer projects needing structure

### ⚠️ Needs Adaptation
- Web-only applications (adapt deployment docs)
- Backend services (reduce mobile-specific docs)
- Open source projects (add contribution guidelines)
- Enterprise projects (add compliance docs)

### ❌ Poor Fit
- Quick prototypes/MVPs (too much overhead)
- Internal tools with no deployment process
- Projects with existing documentation standards

---

## Success Metrics

You'll know this template is working when:

1. **You never ask "where should I document this?"**
   - There's an obvious place for everything

2. **AI agents work more efficiently**
   - They know project structure and guidelines

3. **Code reviews catch issues early**
   - Following the review process prevents bugs

4. **Onboarding is fast**
   - New team members find what they need

5. **You reference your own docs**
   - Documentation is actually useful, not just comprehensive

---

## Common Pitfalls to Avoid

### ❌ Don't: Copy everything blindly
**Problem:** End up with irrelevant LoyaltyCards-specific content  
**Solution:** Read each file, adapt or delete project-specific content

### ❌ Don't: Skip the legal documents
**Problem:** Launch without privacy policy/terms  
**Solution:** Adapt templates early, get legal review

### ❌ Don't: Ignore the AI agent guidelines
**Problem:** Inconsistent AI-generated code quality  
**Solution:** Set up memory files, follow prompting guide

### ❌ Don't: Let documentation diverge from code
**Problem:** Docs become outdated and useless  
**Solution:** Update docs as you code, not after

### ❌ Don't: Skip architecture decisions
**Problem:** Lose context on "why did we do it this way?"  
**Solution:** Document decisions in real-time

---

## Maintenance Philosophy

### Documentation is a First-Class Deliverable

In LoyaltyCards development, we learned:
- **Good documentation prevents repeated mistakes**
- **AI agents work better with clear context**
- **Future you will thank present you**
- **Structure prevents chaos**

### Keep Documentation Useful
- ✅ Update as you go, not in batch later
- ✅ Delete outdated content (don't just add)
- ✅ Link related documents together
- ✅ Use consistent formatting
- ✅ Make it searchable (good filenames, clear headings)

---

## Example: Starting a "TaskManager" App

### Day 1: Bootstrap
```bash
# Clone and setup
git clone [LoyaltyCards] TaskManager
cd TaskManager
rm -rf .git source/
git init

# Update root files
# - README: "TaskManager - Team task management app"
# - PROJECT_METADATA: Update name, description, tech stack

# Update legal
# - PRIVACY_POLICY: Replace "LoyaltyCards" → "TaskManager"
# - TERMS_OF_SERVICE: Update service description

# Clear project-specific content
# - DEFECT_TRACKER: Keep structure, clear all entries
# - NEXT_ACTIONS: Add initial setup tasks
# - Requirements/: Delete all REQ-* files
```

### Week 1: Requirements
```markdown
# Create requirements
REQ-001_User_Authentication.md
REQ-002_Task_Creation.md
REQ-003_Team_Management.md

# Create user stories
US-001_User_Signup.md
US-002_Create_Task.md
US-003_Invite_Team_Member.md

# Document architecture decisions
DECISION_React_Native_Framework.md
DECISION_Firebase_Backend.md
```

### Week 2: Technical Design
```markdown
# Update technical docs
DATABASE_SCHEMA.md - Firestore collections for tasks, users, teams
SECURITY_MODEL.md - Role-based access control
DEPENDENCIES.md - React Native, Firebase, Redux
```

### Week 3+: Development
- Use AI prompting guidelines to generate code
- Request code reviews using templates
- Track defects in DEFECT_TRACKER.md
- Update CHANGELOG.md with features

---

## Template Lifecycle

### Version 1.0 (Current)
- Based on LoyaltyCards v0.2.0
- Includes lessons learned from production development
- AI agent guidelines proven in real development
- Documentation structure battle-tested

### Future Improvements
Consider adding to template:
- CI/CD pipeline configurations
- Docker/containerization examples
- API documentation templates
- Localization/i18n guidelines
- Analytics/monitoring setup docs

---

## Getting Help

### If You're Stuck

1. **"Where does X go?"**
   - Check DOCUMENTATION_INDEX.md for examples
   - Look at existing file organization patterns

2. **"How do I write a requirement?"**
   - Look at deleted REQ-* files in git history as examples
   - Follow the format shown in Requirements/README.md

3. **"How do I work with AI agents?"**
   - Read docs/development/AI_PROMPTING_GUIDE.md thoroughly
   - Follow the examples and anti-patterns

4. **"What should I document?"**
   - If you're asking yourself a question, document the answer
   - If you made a decision, document why
   - If you discovered something non-obvious, write it down

---

## Checklist: "Am I Using This Template Well?"

### Project Structure
- [ ] Documentation folder structure matches template
- [ ] File naming follows conventions (REQ-*, DECISION-*, etc.)
- [ ] No orphaned documents (everything is linked/discoverable)
- [ ] DOCUMENTATION_INDEX.md is up to date

### Development Process
- [ ] Using AI prompting guidelines consistently
- [ ] Requesting code reviews before major releases
- [ ] Tracking defects in structured format
- [ ] Maintaining NEXT_ACTIONS.md backlog

### Documentation Quality
- [ ] README explains project clearly
- [ ] Architecture decisions are documented
- [ ] Database schema is current
- [ ] Dependencies are documented with rationale

### Legal/Compliance
- [ ] Privacy policy adapted for project
- [ ] Terms of service updated
- [ ] Accessibility statement customized

### Git Workflow
- [ ] Using main/develop/feature branch structure
- [ ] Not auto-committing changes
- [ ] Semantic versioning in use
- [ ] CHANGELOG.md maintained

---

## Conclusion

This template represents **3+ months of real-world development experience** distilled into reusable structure. The documentation patterns, AI agent guidelines, and process workflows have been proven effective in production development.

**Key Takeaway:** Don't just copy the structure—understand the *why* behind each piece. Every document exists because it solved a real problem during LoyaltyCards development.

**Philosophy:** Good structure enables creativity. When you're not wondering where to put things or how to organize, you can focus on building great software.

---

## Quick Reference: First Day Checklist

Copy this to your new project's README as a bootstrap checklist:

```markdown
## Project Bootstrap Status

### Day 1: Setup
- [ ] Clone template, remove git history, init fresh repo
- [ ] Update README.md with project name/description
- [ ] Update PROJECT_METADATA.md with project details
- [ ] Clear CHANGELOG.md, start fresh
- [ ] Remove source/ directory
- [ ] Update legal docs (PRIVACY_POLICY, TERMS_OF_SERVICE)
- [ ] Clear DEFECT_TRACKER.md entries
- [ ] Clear NEXT_ACTIONS.md, add setup tasks
- [ ] Delete all REQ-* and US-* files
- [ ] First commit: "Initial project structure from template"

### Week 1: Requirements
- [ ] Create requirements discovery document
- [ ] Write initial requirement files (REQ-001, REQ-002...)
- [ ] Create user stories
- [ ] Update PROJECT_DEVELOPMENT_PLAN.md
- [ ] Draft initial architecture decisions

### Week 2: Technical Design
- [ ] Design and document database schema
- [ ] Define security model
- [ ] List and justify dependencies
- [ ] Create source/ directory structure
- [ ] Set up development environment

### Week 3+: Development
- [ ] First code implementation
- [ ] Set up testing framework
- [ ] Request initial code review
- [ ] Begin regular CHANGELOG updates
- [ ] Start tracking defects/issues
```

---

**Template Version:** 1.0  
**Last Updated:** April 22, 2026  
**Based On:** LoyaltyCards v0.2.0 Production Release  
**Maintained By:** Project maintainers

---

## Related Documents

**Folder:** `docs/meta/`
- PROJECT_METADATA.md - Project information template
- DOCUMENTATION_INDEX.md - Complete file listing

**Folder:** `docs/development/`
- AI_PROMPTING_GUIDE.md - How to work with AI agents
- DEVELOPMENT_STANDARDS.md - Coding standards
- AI_AGENT_RESPONSE_GUIDELINES.md - Agent behavior preferences

**Folder:** `docs/project-management/`
- PROJECT_DEVELOPMENT_PLAN.md - Planning template
- Requirements/README.md - How to write requirements
- DEFECT_TRACKER.md - Issue tracking format
