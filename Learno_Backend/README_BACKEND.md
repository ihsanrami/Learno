# Learno Educational Backend

An AI-powered educational backend designed for children ages 6-7, providing interactive learning experiences through conversational AI and image generation.

## Overview

Learno Backend is a FastAPI-based service that delivers personalized educational content. It uses OpenAI GPT for natural language interactions and DALL-E for generating child-friendly educational images.

## Features

- Concept-based teaching system
- Adaptive difficulty based on student performance
- AI-generated educational images
- Session management with progress tracking
- Voice-first design for young learners

## Requirements

- Python 3.10 or higher
- OpenAI API key

## Installation

1. Extract the project files

2. Create a virtual environment
   ```
   python -m venv venv
   ```

3. Activate the virtual environment

   Windows:
   ```
   venv\Scripts\activate
   ```

   Mac/Linux:
   ```
   source venv/bin/activate
   ```

4. Install dependencies
   ```
   pip install -r requirements.txt
   ```

5. Create environment file

   Create a file named `.env` in the project root:
   ```
   OPENAI_API_KEY=your-api-key-here
   ```

## Running the Server

Start the development server:
```
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The server will be available at `http://localhost:8000`

## API Documentation

Once the server is running, access the interactive API documentation at:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## API Endpoints

### Session Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /api/v1/session/start | Start a new lesson session |
| POST | /api/v1/session/end | End the current session |

### Lesson Interaction

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /api/v1/lesson/continue | Continue to next teaching step |
| POST | /api/v1/lesson/respond | Submit student response |
| POST | /api/v1/lesson/silence | Handle student silence |

## Project Structure

```
backend/
├── requirements.txt
├── .env
└── app/
    ├── __init__.py
    ├── config.py
    ├── main.py
    ├── ai/
    │   ├── __init__.py
    │   ├── openai_client.py
    │   └── dynamic_prompt_builder.py
    ├── models/
    │   ├── __init__.py
    │   └── lesson_content.py
    ├── routes/
    │   ├── __init__.py
    │   └── dynamic_routes.py
    ├── services/
    │   ├── __init__.py
    │   ├── session_service.py
    │   ├── image_service.py
    │   └── dynamic_lesson_service.py
    └── utils/
        ├── __init__.py
        └── exceptions.py
```

## Configuration

Environment variables can be set in the `.env` file:

| Variable | Default | Description |
|----------|---------|-------------|
| OPENAI_API_KEY | (required) | OpenAI API key |
| OPENAI_MODEL | gpt-4o | Model for text generation |
| OPENAI_MAX_TOKENS | 500 | Maximum response tokens |
| OPENAI_TEMPERATURE | 0.7 | Response creativity |
| SESSION_TIMEOUT_SECONDS | 1800 | Session timeout (30 min) |
| SILENCE_THRESHOLD_SECONDS | 12 | Silence detection threshold |

## Teaching Flow

1. Session starts with welcome message
2. Each concept follows this sequence:
   - Introduction
   - Explanation
   - Visual Example (with AI image)
   - Guided Practice
   - Independent Practice
   - Mastery Check
3. Chapter review after all concepts
4. Celebration on completion

## License

Proprietary - All rights reserved
