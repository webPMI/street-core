# Agent Contracts System

**Purpose**: Define clear roles, boundaries, and collaboration rules for all agents in StreetCore.

## How Contracts Work

1. **Before assigning work**: Master reads relevant agent contract
2. **Agent receives task**: Must operate within contract boundaries
3. **Agent produces output**: Must follow output format rules
4. **Master validates**: Checks compliance with contract
5. **Approval gates**: Agents request permission for deep work

## Core Principles

- **Agents PROPOSE, Master DECIDES**: No agent has unilateral authority
- **Token budgets are hard limits**: Agents must stay within budget or escalate
- **Initial summaries required**: No deep dives without approval
- **Specialization enforced**: Agents stay in their domain

## Contract Structure

Each agent contract defines:
- `role`: Core responsibility
- `responsibilities`: What the agent does
- `boundaries`: What the agent must/must not do
- `output_format`: Expected deliverable structure
- `token_budget`: Maximum tokens per task
- `approval_required_for`: Actions needing Master approval
- `collaboration`: How agent works with others

## Token Budgets

| Agent | Budget | Rationale |
|-------|--------|-----------|
| master-agent | 15000 | Coordination overhead |
| architect-agent | 12000 | Design documents |
| backend-agent | 10000 | Code analysis |
| flutter-agent | 10000 | UI analysis |
| database-agent | 8000 | Index analysis |
| security-agent | 8000 | Vulnerability scans |
| devops-agent | 8000 | CI/CD analysis |

## Enforcement

**Master responsibilities**:
- ✅ Validate token usage after each agent task
- ✅ Ensure initial summaries before deep work
- ✅ Stop agents using authority language
- ✅ Enforce approval gates

**What happens on violation**:
1. Master stops agent
2. Agent refines output within limits
3. If impossible, escalate to user

## Quick Reference

**New task checklist**:
- [ ] Master reads agent contract
- [ ] Task includes scope and format requirements
- [ ] Token budget communicated
- [ ] Approval gate defined if needed

**Agent output checklist**:
- [ ] Within token budget?
- [ ] Initial summary format followed?
- [ ] Proposal tone (not directive)?
- [ ] Approval requested for deep work?
