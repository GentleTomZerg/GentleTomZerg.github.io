---
title: Boundaries
authors:
  - GentleTomZerg
date:
  created: 2025-06-23
  updated: 2025-06-23
categories:
  - Software Engineering
tags:
  - clean code
---

## Boundaries

> We seldom control all the software in our systems. Sometimes we buy third-party packages or use open source. Other times we depend on teams in our own company to produce components or subsystems for us. Somehow we must cleanly integrate this foreign code with our own.

### Using Third-Party Code

- Natural tension between the provider of an interface and the user of an interface.

      * Providers of third-party packages and frameworks strive for broad applicability so they can work in many environments and appeal to a wide audience.

      * Users, on the other hand, want an interface that is focused on their particular needs. This tension can cause problems at the boundaries of our systems.
