# 🧠 LLM Architecture in TourGuard

> A technical deep-dive into how Large Language Models power the TourGuard Tourist Safety Application.

---

## Table of Contents

- [Overview](#overview)
- [Architecture Diagram](#architecture-diagram)
- [Core Components](#core-components)
- [LLM Functions](#llm-functions)
- [Prompt Engineering](#prompt-engineering)
- [Integration with Behavioral Analysis](#integration-with-behavioral-analysis)
- [API Endpoints](#api-endpoints)
- [Configuration](#configuration)
- [Design Philosophy](#design-philosophy)

---

## Overview

TourGuard implements a **multi-tier LLM architecture** with three distinct integration points:

| Layer       | Location                                                  | LLM Provider    | Purpose                                 |
| ----------- | --------------------------------------------------------- | --------------- | --------------------------------------- |
| ML Engine   | `ml-engine/app/llm_service.py`                            | Ollama / Gemini | Core AI features, investigation reports |
| Flutter App | `lib/services/gemini_service.dart`                        | Gemini          | Voice command classification            |
| Backend     | `tourguard-backend Final/src/chat/gemini-chat.service.ts` | Gemini          | In-app chatbot (AI Guardian)            |

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         FLUTTER APP                              │
│  ┌─────────────────────┐     ┌─────────────────────────────┐    │
│  │  GeminiService      │     │   Voice Command Input       │    │
│  │  (Voice NLU)        │←────│   "Someone is following me" │    │
│  │  → CALL_POLICE      │     └─────────────────────────────┘    │
│  └─────────────────────┘                                         │
└───────────────────────────────────┬─────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                      BACKEND SERVICES                            │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────-┐ │
│  │                   NestJS Backend                            │ │
│  │  ┌─────────────────────┐                                    │ │
│  │  │ GeminiChatService   │  "AI Guardian" Chatbot             │ │
│  │  │ - Safety advice     │  System Prompt: Travel expert      │ │
│  │  │ - Emergency help    │  Max tokens: 300                   │ │
│  │  │ - Translations      │  Temperature: 0.7                  │ │
│  │  └─────────────────────┘                                    │ │
│  └────────────────────────────────────────────────────────────-┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────-┐ │
│  │                    ML Engine (FastAPI)                      │ │
│  │                                                             │ │
│  │  ┌─────────────────┐   ┌────────────────────────────────┐   │ │
│  │  │   LLMService    │   │   Provider Selection           │   │ │
│  │  │   (Core Brain)  │───│   ┌─────────┐  ┌─────────────┐ │   │ │
│  │  │                 │   │   │ OLLAMA  │  │   GEMINI    │ │   │ │
│  │  │  6 AI Functions │   │   │ (Local) │  │  (Cloud)    │ │   │ │
│  │  │  + Caching      │   │   │ phi3:mini│  │gemini-1.5- │ │   │ │
│  │  │                 │   │   │         │  │   flash     │ │   │ │
│  │  └─────────────────┘   │   └─────────┘  └─────────────┘ │   │ │
│  │          ↓             │         ↑            ↑         │   │ │
│  │          │             │         └────────────┘         │   │ │
│  │          │             │         Auto-Fallback          │   │ │
│  │          │             └────────────────────────────────┘   │ │
│  │          ▼                                                  │ │
│  │  ┌─────────────────────────────────────────────────────┐    │ │
│  │  │             BehavioralAnalyzer                       │   │ │
│  │  │  - detect_location_dropoff()                         │   │ │
│  │  │  - analyze_movement_pattern()                        │   │ │
│  │  │  - assess_distress_signals()                         │   │ │
│  │  └─────────────────────────────────────────────────────┘    │ │
│  └────────────────────────────────────────────────────────────-┘ │
└─────────────────────────────────────────────────────────────────-┘
```

---

## Core Components

### 1. LLMService (ML Engine)

**File:** `ml-engine/app/llm_service.py`

The central LLM orchestration class with dual-provider support.

```python
class LLMService:
    def __init__(self):
        # Provider: 'ollama' (local) or 'gemini' (cloud)
        self.provider = settings.llm_provider

        # Auto-fallback: Ollama unavailable → switch to Gemini
        if self.provider == 'ollama' and not OLLAMA_AVAILABLE:
            if self.api_key and GEMINI_AVAILABLE:
                self.provider = 'gemini'
```

**Key Features:**

- **Dual Provider Support:** Ollama (local) or Google Gemini (cloud)
- **Automatic Fallback:** If Ollama fails, switches to Gemini automatically
- **Response Caching:** Prevents redundant API calls for identical queries
- **Singleton Pattern:** Single instance shared across the application

### 2. Generation Pipeline

All LLM calls flow through the `_generate()` method:

```
User Request → System Prompt + User Prompt → Provider (Ollama/Gemini) → Cache → Response
```

```python
def _generate(self, prompt: str, system_prompt: Optional[str] = None) -> str:
    # Check cache first
    cache_key = f"{system_prompt}::{prompt}"
    if cache_key in self._cache:
        return self._cache[cache_key]

    if self.provider == 'gemini':
        # Google Gemini API
        response = self.gemini_model.generate_content(full_prompt, ...)
    else:
        # Ollama local model
        response = ollama.chat(model=self.model, messages=messages, ...)

    # Cache and return
    self._cache[cache_key] = result
    return result
```

### 3. GeminiService (Flutter)

**File:** `lib/services/gemini_service.dart`

Client-side LLM for voice command classification.

```dart
static Future<Map<String, dynamic>> classifyVoiceCommand(String input) async {
    final prompt = '''
    Classify the user's voice input into:
    - CALL_POLICE (e.g. 'call cops', 'someone is following me')
    - CALL_AMBULANCE (e.g. 'hurt', 'accident', 'medical')
    - TRIGGER_SOS (e.g. 'sos', 'save me', 'bachao', 'madad')
    ...
    Return JSON: { "action": "ACTION_NAME", "confidence": 0.0 to 1.0 }
    ''';

    return _parseJsonLike(response.text);
}
```

### 4. GeminiChatService (Backend)

**File:** `tourguard-backend Final/src/chat/gemini-chat.service.ts`

NestJS service powering the in-app AI Guardian chatbot.

```typescript
private readonly systemPrompt = `You are the **AI Guardian** for TourGuard...
1. Provide safety advice to tourists
2. Help with emergency procedures (SOS, E-FIR, incident reporting)
3. Translate basic phrases into local Indian languages
4. Guide users on scams to avoid and emergency contacts
...Keep responses under 150 words.`;
```

---

## LLM Functions

The ML Engine provides six core LLM-powered functions:

| Function                          | Purpose                      | Output                                       |
| --------------------------------- | ---------------------------- | -------------------------------------------- |
| `chat_travel_assistant()`         | Conversational travel Q&A    | Response + suggested actions + safety score  |
| `generate_safety_advisory()`      | Location-based safety advice | Advisory text + risk level + recommendations |
| `suggest_itinerary()`             | Safe trip planning           | Itinerary + daily plan + safety notes        |
| `enhance_alert_message()`         | Enrich alert messages        | Enhanced message with actionable steps       |
| `explain_anomaly()`               | Explain detected anomalies   | Human-readable explanation                   |
| `assess_distress_probability()`   | Emergency assessment         | Assessment + priority + actions              |
| `generate_investigation_report()` | Full investigation report    | Structured report sections                   |

### Function Deep-Dive: `assess_distress_probability()`

```python
def assess_distress_probability(
    self,
    signals: List[str],           # ["Low battery (15%)", "Night travel"]
    distress_score: float,        # 65.0
    observation: Dict,            # Current GPS/battery/speed data
    history_summary: Dict         # Recent behavioral patterns
) -> Tuple[str, List[str], str]:  # (assessment, actions, priority)
```

**System Prompt:**

```
You are an emergency response analyst assessing tourist distress situations.
Analyze the warning signals and provide:
1. Clear risk assessment
2. Prioritized action recommendations
3. Context-aware reasoning

Be direct and actionable. In emergencies, clarity saves lives.
```

**Output Example:**

```
assessment: "CRITICAL RISK - Multiple warning signals indicate possible distress..."
actions: ["Contact tourist via all channels", "Dispatch emergency services", ...]
priority: "CRITICAL"
```

---

## Prompt Engineering

### Persona-Based System Prompts

Each function has a specialized expert persona:

| Function            | Persona                                      |
| ------------------- | -------------------------------------------- |
| Travel Chat         | Knowledgeable travel assistant for Meghalaya |
| Safety Advisory     | Safety expert for tourist destinations       |
| Itinerary           | Expert travel planner                        |
| Anomaly Explanation | Safety analyst                               |
| Distress Assessment | Emergency response analyst                   |
| Investigation       | Senior Safety Analyst                        |

### Example: Safety Advisory Persona

```python
system_prompt = """You are a safety expert for tourist destinations in Meghalaya, India.
Generate concise, actionable safety advisories. Consider:
- Current risk level of the area
- Time of day (night travel is generally riskier)
- Traveler profile (solo vs group, local vs foreign)
- Specific local safety concerns

Format: Brief advisory followed by 2-4 specific recommendations.
Be reassuring but honest about risks."""
```

### Context Injection

Prompts are enriched with real-time data:

```python
if location:
    prompt_parts.append(f"User is at: {location['name']} ({location['lat']}, {location['lng']})")

if context.get('danger_zones_nearby'):
    prompt_parts.append(f"Nearby danger zones: {context['danger_zones_nearby']}")

if context.get('current_risk'):
    prompt_parts.append(f"Current area risk level: {context['current_risk']}")
```

### Multilingual Support

Voice commands support Hindi/local languages:

```dart
- TRIGGER_SOS (e.g. 'sos', 'save me', 'bachao', 'madad', 'khatra')
- CALL_POLICE (e.g. 'robbery', 'thief', 'chori', 'chor')
```

---

## Integration with Behavioral Analysis

LLM works in tandem with the `BehavioralAnalyzer`:

```
┌─────────────────────┐     ┌─────────────────┐     ┌─────────────┐
│  BehavioralAnalyzer │────▶│   LLMService    │────▶│   Alerts    │
│                     │     │                 │     │             │
│ • GPS signal loss   │     │ • explain_      │     │ • Email     │
│ • Location jumps    │     │   anomaly()     │     │ • SMS       │
│ • Erratic movement  │     │ • assess_       │     │ • Push      │
│ • Distress signals  │     │   distress()    │     │             │
└─────────────────────┘     └─────────────────┘     └─────────────┘
```

### Example Flow

1. **BehavioralAnalyzer** detects location jump (500m in 5 seconds)
2. Creates anomaly data: `{type: 'location_jump', distance_m: 500, time_sec: 5}`
3. **LLMService.explain_anomaly()** generates human-readable explanation
4. **Alert dispatcher** sends enriched alert to responders

---

## API Endpoints

The ML Engine exposes these LLM-powered REST endpoints:

| Endpoint                                        | Method | Purpose                         |
| ----------------------------------------------- | ------ | ------------------------------- |
| `/llm/health`                                   | GET    | Check LLM service availability  |
| `/llm/chat`                                     | POST   | Travel assistant conversation   |
| `/llm/safety-advisory`                          | POST   | Location-based safety advice    |
| `/llm/suggest-itinerary`                        | POST   | Safe trip planning              |
| `/anomaly/explain`                              | POST   | Explain detected anomalies      |
| `/anomaly/assess-distress`                      | POST   | Distress probability assessment |
| `/investigation/analyze`                        | POST   | Generate investigation report   |
| `/observations/{tourist_id}/{trip_id}/patterns` | GET    | Behavioral pattern analysis     |

### Example Request: Safety Advisory

```bash
POST /llm/safety-advisory
Content-Type: application/json

{
  "location": {
    "lat": 25.5788,
    "lng": 91.8933,
    "name": "Shillong Peak"
  },
  "current_risk_level": "medium",
  "time_of_day": "evening",
  "user_profile": {
    "solo_traveler": true,
    "foreign_traveler": false
  }
}
```

### Example Response

```json
{
  "advisory_text": "Shillong Peak is generally safe but exercise caution during evening hours...",
  "risk_assessment": "medium",
  "recommendations": [
    "Stay on marked trails",
    "Inform someone of your plans",
    "Keep emergency contacts handy"
  ],
  "danger_zones_nearby": []
}
```

---

## Configuration

**File:** `ml-engine/app/config.py`

```python
class Settings(BaseSettings):
    # LLM Configuration
    ollama_host: str = "http://localhost:11434"
    ollama_model: str = "phi3:mini"
    llm_enabled: bool = True
    llm_timeout: int = 10          # Seconds
    llm_max_tokens: int = 1200     # Token budget per request
    llm_temperature: float = 0.7   # Creativity vs determinism

    # Provider Selection
    llm_provider: str = "ollama"   # 'ollama' or 'gemini'
    google_api_key: str = None     # Required for Gemini
```

### Environment Variables

```bash
# .env file
ML_ENGINE_LLM_ENABLED=true
ML_ENGINE_LLM_PROVIDER=gemini
ML_ENGINE_GOOGLE_API_KEY=your-api-key
ML_ENGINE_LLM_MAX_TOKENS=1200
ML_ENGINE_LLM_TEMPERATURE=0.7
```

### Trade-off Considerations

| Setting       | Lower Value                 | Higher Value             |
| ------------- | --------------------------- | ------------------------ |
| `temperature` | More deterministic, slower  | More creative, faster    |
| `max_tokens`  | Shorter responses, cheaper  | Longer responses, costly |
| `timeout`     | May fail on complex queries | More reliable but slower |

---

## Design Philosophy

### 1. Hybrid Architecture

```
Local (Ollama) + Cloud (Gemini) with automatic failover
```

- Ollama for development and privacy-sensitive deployments
- Gemini for production reliability

### 2. Defensive Design

```python
if not self.enabled:
    return "LLM service is currently unavailable."  # Always graceful
```

Every function has fallback responses when LLM is unavailable.

### 3. Persona-Driven Prompts

Each function has a specialized expert persona for consistent, domain-appropriate responses.

### 4. Context-Rich Generation

Location, battery, speed, alerts, behavioral history - all fed to context windows for accurate responses.

### 5. Structured Output Parsing

```python
# Extract actions from LLM response
for line in response.split('\n'):
    if line.startswith('-') or line.startswith('•'):
        actions.append(line.lstrip('-•').strip())
```

LLM responses are parsed into actionable data structures.

### 6. Response Caching

```python
cache_key = f"{system_prompt}::{prompt}"
if cache_key in self._cache:
    return self._cache[cache_key]
```

Prevents redundant API calls for cost and latency optimization.

---

## Summary

TourGuard's LLM integration is a **production-grade, safety-first architecture** that:

- ✅ Provides intelligent travel assistance and safety advice
- ✅ Handles emergency situations with structured response generation
- ✅ Supports multilingual voice commands
- ✅ Integrates deeply with behavioral analysis for anomaly explanation
- ✅ Fails gracefully with comprehensive fallback mechanisms
- ✅ Optimizes for cost and latency through caching

This architecture prioritizes **reliability over flashiness** - exactly what's needed for a safety-critical application. 🛡️

---

_Last Updated: January 2026_
