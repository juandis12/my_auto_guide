---
description: Run Harvey autonomous sales agent workflow — prospecting, lead qualification, anti-AI cold emails, and objection handling
---

# /harvey

Execute the Harvey sales engineering workflow for B2B outreach, lead research, or email generation.

## Steps

1. **Clarify Objective:**
   - Are we prospecting new target accounts?
   - Writing a cold email or LinkedIn outreach sequence?
   - Handling a prospect's sales objection?
   - Qualifying leads using BANT / MEDDIC?

2. **Load Relevant Playbook:**
   - Outreach: `.agents/skills/harvey/playbooks/email_frameworks.md`
   - Objections: `.agents/skills/harvey/playbooks/objection_handling.md`
   - Prospecting: `.agents/skills/harvey/playbooks/prospecting_tactics.md`
   - Qualification: `.agents/skills/harvey/playbooks/lead_qualification.md`

3. **Execute with Harvey Constraints:**
   - Enforce hard word limits (< 90 words for Email 1).
   - Zero AI buzzwords ("hope this finds you well", "supercharge", "revolutionize").
   - Low-friction interest CTA.

4. **Deliver Sequence & Strategy:**
   - Present the deliverables with subject lines, email bodies, follow-ups, and sending cadence.
