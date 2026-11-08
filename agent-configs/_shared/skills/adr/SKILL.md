---
name: adr
description: "Writing ADRs (MADR format) for architecture and technology decisions"
---

# ADR (MADR)

Location: `docs/adr/NNNN-kebab-title.md`, numbered sequentially; never edit an accepted ADR's decision — supersede it with a new one.

```markdown
# NNNN. <Decision title in imperative form>

- Status: proposed | accepted | superseded by [NNNN](NNNN-x.md)
- Date: YYYY-MM-DD
- Deciders: Murpheux

## Context and problem statement
<2–5 sentences: forces, constraints, why now>

## Decision drivers
- <NFRs: availability/SLO, latency, cost (C$), security, operability, team skills>

## Considered options
1. <Option A>
2. <Option B>
3. <Option C / do nothing>

## Decision outcome
Chosen: **<option>**, because <justification tied to drivers>.

### Consequences
- Good: …
- Bad / trade-offs: …
- Follow-ups: …

## Pros and cons of the options
### <Option A>
- ✅ … ❌ …

## Links
- <tickets, docs, related ADRs>
```
Keep it under ~1 page; put deep analysis in linked design docs.
