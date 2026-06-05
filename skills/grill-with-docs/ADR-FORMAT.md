# ADR Format

Architecture Decision Records (ADRs) are stored in `docs/adr/` with sequential numbering like `0001-slug.md`. The format is intentionally minimal — a single paragraph suffices if it captures the decision and rationale.

**Core template:** Title, context, decision, and reasoning. That's the baseline.

**Optional enhancements** include Status (proposed/accepted/deprecated), Considered Options, and Consequences — but only when they genuinely clarify the decision.

**Three criteria determine if an ADR is warranted:**

1. The choice carries meaningful reversal costs
2. Future readers will naturally question the approach
3. Real alternatives existed and trade-offs were weighed

**Strong candidates for ADRs:**

- Architectural patterns and system structure
- Communication protocols between system components
- High-switching-cost technology selections
- Ownership and boundary definitions
- Intentional departures from conventional approaches
- External constraints influencing design
- Non-obvious rejections of alternative solutions

The philosophy emphasizes capturing *why* decisions exist rather than exhaustive documentation. A bare-minimum ADR that prevents duplicate debates and explains deliberate choices delivers more value than elaborate templates nobody maintains.
