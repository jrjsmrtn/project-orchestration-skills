---
# SPDX-FileCopyrightText: 2025 Georges Martin <jrjsmrtn@gmail.com>
# SPDX-License-Identifier: MIT
name: setup-architecture-as-code
description: Establish architecture-as-code practice using C4 modeling and Structurizr DSL. Use after bootstrap-project, when establishing architecture documentation, or when migrating from diagram-based to code-based architecture.
---

# Setup Architecture-as-Code

Establish architecture-as-code practice using C4 modeling and Structurizr DSL.

## When to Use

- After running `bootstrap-project` skill
- When establishing architecture documentation for a project
- When migrating from diagram-based to code-based architecture documentation
- When you need version-controlled, validated architecture models

## What is Architecture-as-Code?

Architecture-as-Code treats architecture documentation like source code:

| Traditional Diagrams | Architecture-as-Code |
|---------------------|---------------------|
| Draw in GUI tools | Define in text/DSL |
| Manual updates | Automated validation |
| Binary files (PNG, VSDX) | Text files (version control friendly) |
| Diagrams diverge from reality | Single source of truth |
| Hard to review changes | PR-reviewable changes |
| No validation | Syntax + semantic validation |

**Implementation Stack**:
- **Modeling Approach**: C4 Model (Context, Container, Component, Code)
- **Definition Language**: Structurizr DSL
- **Validation**: structurizr/cli
- **Visualization**: Structurizr Lite (local) or Structurizr Cloud

## Required Inputs

1. **Project/System name**
2. **System description** (1-2 sentences)
3. **Key users/personas** (who interacts with the system)
4. **External systems** (what the system integrates with)
5. **Main containers** (applications, databases, services)
6. **Technology stack** (languages, frameworks, databases)

## C4 Model Overview

The C4 model provides four levels of abstraction (zoom levels):

| Level | Name | Purpose | Audience |
|-------|------|---------|----------|
| 1 | System Context | System in its environment | Everyone |
| 2 | Container | Deployable units | Technical staff |
| 3 | Component | Internal structure | Developers |
| 4 | Code | Class/module level | Developers (often generated) |

**Key Principle**: Start with Level 1-2, add Level 3 only when needed. Level 4 is usually generated from code.

## Workflow

### Step 1: Create Directory Structure

```bash
mkdir -p architecture/shared
mkdir -p docs/architecture    # Structurizr-specific docs (h2-first, numbered files)
# Symlink so !adrs and !docs directives can reach docs/ from architecture/
ln -s ../docs architecture/docs
```

The symlink is required because Structurizr restricts `!adrs` and `!docs` paths to the same directory or subdirectories of the DSL file — it cannot traverse parent directories.

**Why `docs/architecture/` and not `docs/explanation/`?** Structurizr silently strips h1 headings (it auto-generates h1 from the element name). Diátaxis docs use h1 as their title, so pointing `!docs` at a Diátaxis directory would lose those titles. Keep Structurizr docs in a dedicated directory with h2-first files.

### Step 2: Create Workspace File

Create `architecture/workspace.dsl`:

```dsl
workspace "[Project Name]" "[Brief description]" {

    !identifiers hierarchical
    !adrs docs/adr
    !docs docs/architecture

    model {
        # ===== USERS/ACTORS =====
        user = person "User" "Primary user of the system" "User"

        # Add other personas as needed:
        # admin = person "Administrator" "System administrator" "Admin"
        # developer = person "Developer" "API consumer" "Developer"

        # ===== EXTERNAL SYSTEMS =====
        # externalSystem = softwareSystem "External System" "Description" "External"

        # ===== THE SYSTEM =====
        system = softwareSystem "[System Name]" "[System description]" {

            # ----- CONTAINERS -----

            # Web Application (if applicable)
            webApp = container "Web Application" "Provides user interface" "[Framework]" "Web"

            # API Service (if applicable)
            api = container "API Service" "Provides REST/GraphQL API" "[Framework]" "API"

            # Database
            database = container "Database" "Stores application data" "[Database Technology]" "Database"

            # Background Workers (if applicable)
            # worker = container "Background Worker" "Processes async tasks" "[Technology]" "Worker"

            # ----- COMPONENTS (for main container) -----
            # Uncomment and customize for your architecture:

            # api {
            #     authComponent = component "Authentication" "Handles user auth" "[Module]"
            #     businessComponent = component "Business Logic" "Core domain logic" "[Module]"
            #     dataComponent = component "Data Access" "Database operations" "[Module]"
            # }
        }

        # ===== RELATIONSHIPS =====

        # User interactions
        user -> system "Uses"
        user -> system.webApp "Interacts with" "HTTPS"

        # Internal relationships
        system.webApp -> system.api "Makes API calls to" "HTTP/JSON"
        system.api -> system.database "Reads from and writes to" "SQL"

        # External system relationships (if any)
        # system.api -> externalSystem "Integrates with" "HTTPS"
    }

    views {
        # ===== SYSTEM CONTEXT VIEW =====
        systemContext system "SystemContext" {
            include *
            autoLayout
            description "System Context diagram showing [System Name] and its environment"
        }

        # ===== CONTAINER VIEW =====
        container system "Containers" {
            include *
            autoLayout
            description "Container diagram showing the main deployable units"
        }

        # ===== COMPONENT VIEW (optional) =====
        # Uncomment when you have components defined:
        # component system.api "Components" {
        #     include *
        #     autoLayout
        #     description "Component diagram for the API service"
        # }

        # ===== STYLES =====
        styles {
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Software System" {
                background #1168BD
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Component" {
                background #85BBF0
                color #000000
            }
            element "Database" {
                shape Cylinder
            }
            element "Web" {
                shape WebBrowser
            }
            element "API" {
                shape Hexagon
            }
            element "Worker" {
                shape Robot
            }
        }
    }
}
```

### Step 3: Create Technology-Specific Templates

#### Elixir/Phoenix Template

```dsl
workspace "[Project Name]" "Elixir/Phoenix application" {

    !identifiers hierarchical
    !adrs docs/adr
    !docs docs/architecture

    model {
        user = person "User" "Application user" "User"

        system = softwareSystem "[System Name]" "Phoenix web application" {

            phoenix = container "Phoenix Application" "Web application and API" "Elixir/Phoenix" "Web"

            liveview = container "LiveView UI" "Real-time user interface" "Phoenix LiveView" "Web"

            # If using Ash Framework:
            # ash = container "Ash Resources" "Domain logic and resources" "Ash Framework" "Component"

            postgres = container "PostgreSQL" "Primary data store" "PostgreSQL 16" "Database"

            # Optional: Background jobs
            # oban = container "Oban Workers" "Background job processing" "Oban" "Worker"
        }

        user -> system.liveview "Uses" "HTTPS"
        system.liveview -> system.phoenix "LiveView connections" "WebSocket"
        system.phoenix -> system.postgres "Queries" "Ecto"
    }

    views {
        systemContext system "SystemContext" {
            include *
            autoLayout
        }

        container system "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Software System" {
                background #6B4C9A
                color #ffffff
            }
            element "Container" {
                background #9B59B6
                color #ffffff
            }
            element "Database" {
                shape Cylinder
                background #336791
            }
            element "Web" {
                shape WebBrowser
            }
        }
    }
}
```

#### Python/FastAPI Template

```dsl
workspace "[Project Name]" "Python FastAPI application" {

    !identifiers hierarchical
    !adrs docs/adr
    !docs docs/architecture

    model {
        user = person "User" "API consumer" "User"

        system = softwareSystem "[System Name]" "FastAPI service" {

            api = container "FastAPI Service" "REST API" "Python/FastAPI" "API"

            postgres = container "PostgreSQL" "Primary data store" "PostgreSQL 16" "Database"

            # Optional: Redis for caching/sessions
            # redis = container "Redis" "Cache and session store" "Redis" "Database"

            # Optional: Celery workers
            # celery = container "Celery Workers" "Async task processing" "Celery" "Worker"
        }

        user -> system.api "Calls" "HTTPS/JSON"
        system.api -> system.postgres "Queries" "SQLAlchemy"
    }

    views {
        systemContext system "SystemContext" {
            include *
            autoLayout
        }

        container system "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Software System" {
                background #306998
                color #ffffff
            }
            element "Container" {
                background #FFD43B
                color #000000
            }
            element "Database" {
                shape Cylinder
                background #336791
            }
            element "API" {
                shape Hexagon
            }
        }
    }
}
```

### Step 4: Create Model Overview

Create `architecture/README.md`:

```markdown
# [Project Name] Architecture-as-Code

## What is Architecture-as-Code?

This project uses **Architecture-as-Code**: architecture models defined in text files (Structurizr DSL), version-controlled alongside source code, and validated automatically.

**Benefits**:
- **Version Control**: Architecture changes tracked in git history
- **Code Review**: Architecture changes reviewable in PRs
- **Validation**: Syntax and semantic errors caught automatically
- **Single Source of Truth**: Model generates diagrams, not vice versa
- **AI-Friendly**: Text-based format readable by AI assistants

## Model Structure

```
architecture/
├── workspace.dsl       # C4 model definition (THE source of truth)
├── shared/             # Shared DSL fragments (!include targets)
│   └── _styles.dsl     # Unified element/relationship styles
├── docs -> ../docs     # Symlink (enables !adrs and !docs directives)
├── README.md           # This file
└── diagrams/           # Generated exports (optional, gitignored)
```

The `docs` symlink allows workspace files to use `!adrs docs/adr` and `!docs docs/architecture` — Structurizr requires these paths to be within or below the DSL file's directory.

## Quick Start

### View the Architecture

```bash
# Start Structurizr Lite viewer
make view-architecture
# or:
podman run --rm -p 8080:8080 \
  -v "$(pwd):/usr/local/structurizr" \
  -e STRUCTURIZR_WORKSPACE_PATH=architecture \
  structurizr/lite
```

Then open http://localhost:8080

### Validate the Model

```bash
make validate-architecture
# or:
podman run --rm \
  -v "$(pwd):/usr/local/structurizr" \
  -w /usr/local/structurizr/architecture \
  structurizr/cli validate -workspace workspace.dsl
```

### Export Diagrams

```bash
make export-architecture
# or:
podman run --rm \
  -v "$(pwd)/architecture:/usr/local/structurizr" \
  structurizr/cli export -workspace workspace.dsl -format plantuml
```

## C4 Model Levels

| Level | View | What It Shows |
|-------|------|---------------|
| 1 | System Context | [System] in its environment with users and external systems |
| 2 | Container | Deployable units: [list your containers] |
| 3 | Component | Internal structure of [main container] (if defined) |

## Updating the Architecture

1. **Edit** `workspace.dsl` with your changes
2. **Validate**: `make validate-architecture`
3. **Review**: `make view-architecture` to see visual changes
4. **Document**: Create/update ADR if this is a significant decision
5. **Commit**: Include DSL changes in your PR

## Architecture Decision Records

See [../adr/](../adr/) for ADRs explaining the rationale behind architectural decisions.

Key ADRs:
- [ADR-0002](../adr/0002-adopt-development-best-practices.md): Establishes architecture-as-code practice
- [ADR-0003](../adr/0003-*.md): Technology stack decision

## References

- [C4 Model](https://c4model.com/) - The modeling approach
- [Structurizr DSL](https://docs.structurizr.com/dsl/language) - Language reference
- [Structurizr Examples](https://structurizr.com/dsl) - DSL examples
```

### Step 5: Add Makefile Targets

Add to project `Makefile`:

```makefile
# Architecture-as-Code targets
.PHONY: validate-architecture view-architecture export-architecture

validate-architecture:
	@echo "Validating architecture model..."
	podman run --rm \
		-v "$(PWD):/usr/local/structurizr" \
		-w /usr/local/structurizr/architecture \
		structurizr/cli validate -workspace workspace.dsl

view-architecture:
	@echo "Starting Structurizr Lite on http://localhost:8080..."
	@echo "Press Ctrl+C to stop"
	podman run --rm -p 8080:8080 \
		-v "$(PWD):/usr/local/structurizr" \
		-e STRUCTURIZR_WORKSPACE_PATH=architecture \
		structurizr/lite

export-architecture:
	@echo "Exporting architecture to PlantUML..."
	podman run --rm \
		-v "$(PWD):/usr/local/structurizr" \
		-w /usr/local/structurizr/architecture \
		structurizr/cli export -workspace workspace.dsl -format plantuml -output diagrams/

export-architecture-json:
	@echo "Exporting architecture to JSON..."
	podman run --rm \
		-v "$(PWD):/usr/local/structurizr" \
		-w /usr/local/structurizr/architecture \
		structurizr/cli export -workspace workspace.dsl -format json
```

### Step 6: Validate and Commit

```bash
# Validate the model
make validate-architecture
# or manually:
podman run --rm -v "$(pwd):/usr/local/structurizr" \
  -w /usr/local/structurizr/architecture \
  structurizr/cli validate -workspace workspace.dsl

# View to verify (optional)
make view-architecture

# Commit
git add architecture/
git add Makefile  # if updated
git commit -m "docs: add architecture-as-code model (C4/Structurizr)"
```

## Outputs

This skill creates:
- [ ] `architecture/workspace.dsl` (C4 model with `!adrs` and `!docs` integration)
- [ ] `architecture/docs` symlink to `../docs` (enables Structurizr documentation directives)
- [ ] `architecture/shared/` directory (for shared DSL fragments like `_styles.dsl`)
- [ ] `architecture/README.md` (architecture-as-code documentation)
- [ ] Makefile targets (validate-architecture, view-architecture, export-architecture)

## Validation

```bash
# Verify workspace.dsl exists and is valid
make validate-architecture

# Expected output:
# Validating architecture model...
# workspace.dsl: OK

# View the model
make view-architecture
# Open http://localhost:8080 and verify diagrams render correctly
```

## Architecture-as-Code Best Practices

1. **Model is source of truth**: Diagrams are outputs, DSL is the source
2. **Start simple**: Begin with System Context and Container views
3. **Add components later**: Only add Component level when needed
4. **Validate in CI**: Include `make validate-architecture` in CI pipeline
5. **Review in PRs**: Architecture changes should be code-reviewed
6. **Keep descriptions short**: 1-2 sentences per element
7. **Update with code**: Architecture should evolve with implementation
8. **Reference in ADRs**: Link architectural decisions to model elements
9. **Don't export diagrams to git**: Generate on demand, don't commit PNGs

## Common Patterns

### Microservices
```dsl
service1 = container "Service 1" "Description" "Technology"
service2 = container "Service 2" "Description" "Technology"
messageQueue = container "Message Queue" "Async communication" "RabbitMQ" "Queue"

service1 -> messageQueue "Publishes events"
service2 -> messageQueue "Consumes events"
```

### API Gateway
```dsl
gateway = container "API Gateway" "Routes requests" "Kong/Nginx" "API"
gateway -> service1 "Routes to"
gateway -> service2 "Routes to"
user -> gateway "All requests"
```

### Caching Layer
```dsl
cache = container "Cache" "Caches responses" "Redis" "Database"
api -> cache "Checks cache"
api -> database "Cache miss"
```

## AI Collaboration

Architecture-as-Code is particularly AI-friendly:

| Aspect | Benefit for AI |
|--------|----------------|
| Text-based | AI can read and understand DSL directly |
| Structured | Clear syntax enables accurate modifications |
| Validated | AI changes can be validated automatically |
| Version-controlled | AI can see architecture history |

**AI can help with**:
- Generating initial workspace.dsl from project description
- Adding new containers/components
- Suggesting relationships between elements
- Reviewing architecture changes for consistency

**Human should lead on**:
- Major architectural decisions
- Strategic technology choices
- Validation of business alignment

## Growing to Multiple Workspaces

When a single workspace.dsl grows too large, split into focused workspaces per subsystem:

```
architecture/
├── workspace.dsl                    # Master — all subsystems at container level
├── <name>-<subsystem>-workspace.dsl # Focused — one subsystem at component level
├── shared/
│   └── _styles.dsl                  # Unified styles shared via !include
├── docs -> ../docs
└── README.md
```

Each focused workspace:
- Promotes its subsystem to a top-level softwareSystem with full container/component detail
- Declares other subsystems as one-line "Sibling" stubs with context-specific descriptions
- Repeats `!adrs docs/adr` and `!docs docs/architecture` (these are per-workspace, not inherited)
- Uses `styles { !include shared/_styles.dsl }` for style consistency

**Why not share sibling stubs or people via `!include`?** Structurizr errors on duplicate identifiers (no merge, no override). Each focused workspace defines its primary system with the same identifier as the stub would use. Also, descriptions are intentionally context-specific — a sibling description explains how that subsystem relates to *this* workspace's focus.

**Podman note**: mount the project root (not just `architecture/`) so the `docs` symlink resolves inside the container.

## Related Skills

- `bootstrap-project` - Creates initial directory structure
- `setup-adrs` - ADR-0002 documents architecture-as-code practice
- `analyze-project` - SPARK analysis informs architecture
- `plan-sprint` - Architecture updates tracked in sprints
