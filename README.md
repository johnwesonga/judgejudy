# Judgejudy

An intelligent email triage and auto-response system built with Elixir, Jido AI agents, and hybrid RAG (Retrieval-Augmented Generation). Judgejudy automatically processes inbound emails by classifying intent, retrieving relevant knowledge base articles, and generating context-aware responses with human-in-the-loop escalation for low-confidence cases.

## Features

- **Email Classification**: Automatically detects intent (billing, support, sales, general) and category using keyword-based ML scoring with confidence scores
- **Hybrid Knowledge Retrieval**: Combines full-text search, semantic vector search (pgvector), and RRF ranking for accurate KB article retrieval
- **Confidence-Based Routing**: Escalates low-confidence cases to human agents; auto-resolves high-confidence cases
- **Multi-Agent Architecture**: Specialized AI agents for email processing, calculation, weather queries, and drafting
- **Real-time Email Processing**: IMAP sensor monitors inbox and routes emails to appropriate agents
- **Knowledge Base Management**: Seed KB articles with domain-specific knowledge and embeddings

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Judgejudy App                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Email Sensor │  │ Jido Agents  │  │ Knowledge    │      │
│  │ (IMAP)       │──│ (email_react, │──│   Base       │      │
│  └──────────────┘  │  draft, calc, │  │ (hybrid RAG)  │      │
│                    │  weather)     │  └──────────────┘      │
│                    └──────────────┘                         │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐│
│  │              Confidence-Based Routing                   ││
│  │  High Confidence (>0.5) ──→ Auto Reply                  ││
│  │  Low Confidence (<0.5) ────→ Escalate to Human          ││
│  └─────────────────────────────────────────────────────────┘│
│                                                             │
│  ┌──────────────┐                                           │
│  │   Mailer     │ (Swoosh for sending emails)               │
│  └──────────────┘                                           │
│                                                             │
│  ┌──────────────┐                                           │
│  │   PostgreSQL │ (Ecto + pgvector + tsvector)              │
│  └──────────────┘                                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Tech Stack

- **Language**: Elixir
- **AI Framework**: Jido (AI agent runtime with ReAct, CoT, CoD agents)
- **LLMs**: Anthropic (Claude Sonnet/Haiku), OpenAI (Qwen local)
- **Database**: PostgreSQL with pgvector and full-text search
- **Email**: Swoosh (SMTP) + IMAP polling
- **Embeddings**: Custom embedding model (bge-m3-mlx) for semantic search
- **Hybrid Search**: RRF (Reciprocal Rank Fusion) combining FTS + Vector + Intent/Category boosts

## Installation

```bash
mix deps.get
mix deps.compile
mix compile
mix ecto.create
mix ecto.migrate
mix judgejudy.seed_kb
```

### Environment Setup

Create a `.env` file with the following variables:

```bash
# LLM Keys
ANTHROPIC_API_KEY=your_anthropic_key
OPENAI_API_KEY=your_openai_key

# IMAP (email reception)
IMAP_SERVER=imap.gmail.com
IMAP_USERNAME=you@gmail.com
IMAP_PASSWORD=your_app_password

# SMTP (email sending)
SMTP_USERNAME=your_email
SMTP_PASSWORD=your_password

# Database
DATABASE_URL="postgres://user:pass@localhost:5432/judgejudy"

# Embeddings
EMBEDDINGS_BASE_URL=http://localhost:8000/v1
EMBEDDINGS_API_KEY=omlx
EMBEDDINGS_MODEL=bge-m3-mlx-4bit

# Escalation
ESCALATION_EMAIL=support-team@myapp.com

# React token for agent communication
REACT_TOKEN_SECRET=your_secret
```

## Usage

### Running the Application

```bash
mix run --no-halt
```

The application starts with:
1. PostgreSQL repository
2. Jido Registry and Signal Bus
3. IMAP sensor monitoring email inbox
4. Email ReAct Agent (main processing agent)
5. Additional specialized agents (weather, calc, drafting)

### Email Processing Flow

1. **Email Sensor**: Polls IMAP inbox for new messages
2. **ClassifyEmailAction**: Analyzes subject/body to determine intent, category, urgency, and confidence
3. **FetchContextAction**: Retrieves relevant KB articles using hybrid search (FTS + vector + boosts)
4. **DraftReplyAction**: Generates a response based on classification and retrieved context
5. **RouteByConfidenceAction**: Routes based on confidence threshold (default: 0.5)
   - High confidence → Auto-send reply
   - Low confidence → Escalate to human agent with notification

### Seeding Knowledge Base

```bash
mix judgejudy.seed_kb
```

Creates 10 KB articles across categories:
- Billing: payment, invoice, refund, subscription
- Support: authentication, api, bug, data_export, performance
- Sales: trial, pricing, enterprise, demo
- General: compatibility, status

## Agents

| Agent | Type | Model | Purpose |
|-------|------|-------|---------|
| `EmailReActAgent` | ReAct Agent | Claude Sonnet | Main email triage with tools for classification, KB lookup, drafting, sending |
| `DraftAgent` | CoD Agent | Claude Sonnet | Chain-of-Draft reasoning for response generation |
| `ThoughtAgent` | CoT Agent | Claude Sonnet | Chain-of-Thought reasoning for complex queries |
| `CalcAgent` | Agent | Haiku | Calculator with add/multiply/subtract tools |
| `WeatherAgent` | ReAct Agent | Local Qwen | Weather queries with location-based tools |

## Knowledge Base Querying

The knowledge base uses a hybrid search approach:

1. **Full-Text Search (FTS)**: PostgreSQL tsvector matching with `ts_rank_cd`
2. **Semantic Search**: Vector cosine similarity using pgvector HNSW index
3. **RRF Ranking**: Reciprocal Rank Fusion combines FTS and semantic scores
4. **Intent/Category Boosts**: Adds weighted boosts when intent/category matches

See `lib/judgejudy/knowledge_base.ex` for the full `hybrid_query/4` implementation.

## Intent and Category Mapping

### Intents
- `billing`: Payment-related queries
- `support`: Technical support and troubleshooting
- `sales`: Pricing, demos, and enterprise inquiries
- `general`: Miscellaneous questions

### Categories per Intent

| Intent | Categories |
|--------|------------|
| billing | payment, invoice, refund, subscription |
| support | authentication, api, bug, data_export, performance |
| sales | trial, pricing, enterprise, demo |
| general | compatibility, status, feedback |

## Escalation Threshold

The system escalates to human agents when either confidence score falls below the threshold:

```elixir
confidence_threshold = 0.5  # configured in config/config.exs
```

If either:
- Classification confidence < 0.5, OR
- Retrieval confidence < 0.5

The email is escalated with:
1. Auto-acknowledgement sent to sender ("ticket received")
2. Detailed notification sent to human agents (team inbox)

## Development

### Running Tests

```bash
mix test
```

### Format Code

```bash
mix format
```

## Configuration

Key configuration options (in `config/config.exs`):

```elixir
config :judgejudy, :confidence_threshold, 0.5
```

Adjust the threshold based on your desired balance between:
- Automation volume (higher = more auto-responses)
- Escalation coverage (lower = more human review)

## License

MIT License
