# Influence — Minnesota-First Product Roadmap

A lobbying and public affairs platform focused first on the Minnesota Legislature, built on top of the existing auth, AI chat, user/role management, and analytics foundation.

---

## What Exists Today

| Capability | Details |
|---|---|
| Authentication | Register, login (JWT + refresh token), logout, password reset, email confirmation |
| AI Chat | Conversations + messages, CrewAI-powered responses via GPT-4o, auto-titled from first message |
| User Management | List, view, activate/deactivate users (soft delete), assign roles |
| Role Management | Full CRUD; protected `admin` role; role-scoped access control |
| AI Microservice | General assistant agent, research specialist agent, direct Copilot API passthrough |
| Analytics | Ahoy event + visit tracking; per-user activity queryable |

---

## Product Scope

The product should launch as a Minnesota-first operating system for a lobbying and public affairs firm.

- Primary jurisdiction: Minnesota House, Minnesota Senate, and selected Minnesota state agencies
- Primary users: lobbyists, public affairs staff, compliance staff, and firm leadership
- Primary workflow: manage clients and matters, track Minnesota bills, manage legislator relationships, log advocacy activity, and generate drafting/reporting output quickly
- Deferred scope: federal-first workflows, multi-state architecture, and advanced intelligence features that depend on large volumes of historical data

---

## Layer 1 — Foundation
> Delivers value immediately. Replaces spreadsheets and email threads on day one.

### 1.1 Client Management
The commercial core of the firm. Every engagement ties back to a client.

- `Client` model: name, description, status (active/inactive), assigned staff, contact info
- CRUD UI: list, create, view, edit, deactivate
- Scope all downstream records (matters, contacts, activities) to a client

### 1.2 Matter Management
A *matter* represents a specific engagement or issue a client has hired the firm to work on.

- `Matter` model: title, description, status (active/inactive/closed), client association, assigned lobbyists
- Add `LegislativeSession` context from day one so matters are tied to a Minnesota session
- Attach a matter to one or more clients
- Status workflow: draft → active → closed
- CRUD UI with client context

### 1.3 Contact Database
Legislators, committee staff, agency officials, and coalition partners. The firm's most valuable institutional knowledge.

- `Contact` model: name, title, office/agency, chamber (House/Senate/Agency), party, phone, email, notes, leadership role, committee assignment, preferred contact method
- Many-to-many association with matters
- Search and filter by chamber, party, office
- Tag contacts as relationships (supporter, neutral, opposed)

### 1.4 Minnesota Contact Import
Reduce manual setup by preloading the Minnesota policymaker ecosystem.

- Import Minnesota House members, Minnesota Senate members, leadership, and committee assignments
- Seed key agency contacts for selected departments tied to client work
- Support bulk import updates before and during session
- Create a one-click onboarding workflow so firms start with a usable contact base immediately

### 1.5 Domain-Aware AI Drafting
Extend the existing AI chat to accept client/matter context so drafts are pre-populated with the right names, positions, and targets.

- Pass client name, matter description, and relevant contacts as AI system context
- Draft types: one-pager, talking points, letter to Minnesota legislator, committee testimony, amendment language, state agency letter
- UI: "New Draft" button within a matter that opens a context-aware chat session
- Minimal new infrastructure — the AI microservice already supports this via the existing `/ai/prompt` endpoint

---

## Layer 2 — Intelligence
> Builds on the data foundation. Centralizes work staff are already doing manually.

### 2.1 Minnesota Legislative Tracking
Track the Minnesota bills, committees, and proceedings that matter to each client.

- `Bill` model: docket number, title, status, chamber, committee, companion bill, link, summary, issue area
- Attach bills to matters and clients
- Manual entry to start; later add ingestion from Minnesota legislative sources
- Status change history (introduced → committee → floor → enacted or died)
- Track committee deadlines and special risk states like "dies if not heard"

### 2.2 Session Calendar & Deadline Tracking
Minnesota session deadlines are operationally critical and should be visible early.

- `LegislativeSession` model: year, type, start date, end date, status
- Track major dates: session start, committee deadlines, floor deadlines, adjournment, special session
- Alert users when tracked bills approach committee or floor deadlines
- Add dashboard visibility for urgent matters at risk during the active session

### 2.3 Activity Log
The core workflow tool — log every meeting, call, email, and action taken on a matter.

- `Activity` model: type (meeting/call/email/testimony/event/agency meeting/coalition meeting), date, contacts involved, matter, notes, outcome
- Linked to clients, matters, and contacts
- Link activity to bills when relevant
- Filterable timeline view per matter and per client
- Feeds directly into compliance reporting (Layer 3)

### 2.4 Document Library
Store and retrieve advocacy documents attached to matters.

- `Document` model: title, file, type (testimony/letter/brief/one-pager), matter association, uploaded by, date
- Upload and download from the matter detail view
- AI agent can search and summarize stored documents via `BackendRequestTool`

---

## Layer 3 — Reporting & Compliance
> Only meaningful once Layer 1–2 data exists.

### 3.1 Minnesota Compliance Calendar
Start with deadline visibility and audit prep rather than a broad multi-jurisdiction compliance engine.

- `ComplianceDeadline` model: type, due date, jurisdiction, client, status
- Track Minnesota lobbying registration and reporting deadlines first
- Dashboard view of upcoming deadlines across all clients
- Use logged activity records to support quarterly audit prep

### 3.2 Client Status Reports
Auto-generate weekly or monthly client-facing summaries using the AI agent.

- Pull recent activities, bill status changes, and upcoming actions for a client
- AI drafts the narrative; staff reviews and approves before sending
- Exportable as PDF or email-ready HTML
- High leverage: firms currently spend hours on this manually

---

## Layer 4 — Advanced Intelligence
> Requires data density from Layers 1–3 to be accurate and useful.

### 4.1 News & Media Monitoring
Surface articles relevant to client issues before clients see them.

- Feed articles in via RSS or manual entry
- AI tags relevance to client issue areas
- Surfaces items that may require a response or statement
- Weekly digest per client with AI-generated context

### 4.2 Minnesota Agency Monitoring
Automated monitoring of selected Minnesota agencies and administrative proceedings tied to client priorities.

- The `ResearchSpecialist` CrewAI agent can be adapted for this
- Poll on a schedule; surface agency notices or proceedings linked to tracked issue areas
- Alert assigned lobbyists when relevant agency action or comment opportunities appear

### 4.3 Relationship Mapping
Visual network of who knows whom across the firm's contact database.

- Graph view of contacts, clients, and matters
- Highlight which offices have existing relationships with each client
- Useful for strategy: "who do we know who can get a meeting with this office?"
- Requires contact + activity history depth to be meaningful

### 4.4 Multi-State Expansion
Generalize the data model and workflows only after the Minnesota product is validated.

- Add new jurisdictions after Minnesota workflows are proven in production
- Reuse the session, bill, contact, and compliance patterns developed for Minnesota
- Avoid early architecture complexity until a second state is commercially justified

---

## Build Order Rationale

| Layer | Why this order |
|---|---|
| Clients + Matters | The firm's work is still organized around clients and active matters, and session context should be attached immediately |
| Minnesota Contact Import | Preloading legislators, committees, and agency contacts creates immediate value and avoids manual CRM setup |
| Minnesota Bill Tracking | State firms need bill and committee visibility early because session timelines are compressed |
| AI Drafting | Existing AI infrastructure can deliver quick value once clients, matters, contacts, and bills exist |
| Activity Log | Fuels compliance, client reporting, and institutional memory at the same time |
| Session Calendar | Minnesota committee and floor deadlines are operationally critical and deserve dedicated visibility |
| Minnesota Compliance | Deadline tracking and audit prep matter early, but can stay focused and lightweight at first |
| Reporting, Monitoring, and Mapping | These become more valuable once real session data and historical activity have accumulated |

---

## Recommended Build Sequence

| Priority | Feature | Why it comes next |
|---|---|---|
| 1 | Clients, Matters, Contacts | Base operating model for the firm |
| 2 | Minnesota Contact Import | Makes the system usable immediately for a Minnesota shop |
| 3 | Minnesota Bill Tracking | Connects firm work to real legislative objects |
| 4 | AI Drafting | Turns stored context into immediate drafting value |
| 5 | Activity Log | Captures the work that drives reporting and compliance |
| 6 | Session Calendar & Deadline Alerts | Gives the firm urgency visibility during session |
| 7 | Minnesota Compliance Calendar | Helps avoid missed filing deadlines and supports audit prep |
| 8 | Document Library | Centralizes testimony, briefs, and letters |
| 9 | Client Reporting | Automates status updates once enough data exists |
| 10 | Agency Monitoring | Extends beyond the legislature after the core workflow is solid |
| 11 | Relationship Mapping and Multi-State Expansion | Best added after Minnesota workflows are proven |

---

## Immediate Leverage Point

Once **clients**, **matters**, **Minnesota contacts**, and **tracked bills** are in the database, the existing AI microservice can draft content and pre-populate:

> *"Chair [Name], on behalf of [Client Name], we support HF [Number] with the following amendment..."*

without the user doing anything but reviewing it. That's a meaningful workflow acceleration with the infrastructure that already exists.

---

## What Changes From the Original Roadmap

| Original assumption | Minnesota-first adjustment |
|---|---|
| Federal-first lobbying workflows | Minnesota Legislature and selected Minnesota agencies first |
| Generic legislative tracking later in the roadmap | Minnesota bill tracking moves into the early build |
| Compliance framed broadly from the start | Start with Minnesota-specific deadline tracking and audit prep |
| Drafts aimed at Congress and federal comments | Drafts aimed at Minnesota legislators, committees, and agencies |
| Advanced intelligence as the next big step | Focus first on session execution, deadlines, and relationship workflows |
| Multi-jurisdiction roadmap implied | Keep multi-state expansion explicitly deferred until Minnesota succeeds |
