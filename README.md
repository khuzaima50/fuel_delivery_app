# Presence Service API

A lightweight API for tracking real-time user presence and activity status using Node.js, Express, and Redis.

## Table of Contents
- [Requirements](#requirements)
- [Setup & Installation](#setup--installation)
- [Endpoints](#endpoints)
  - [Set Activity Status](#set-activity-status)
  - [Get Activity Status](#get-activity-status)
- [Testing](#testing)

---

## Requirements

- **Node.js** (v14 or higher)
- **Redis** server running locally or on a reachable host.

---

## Setup & Installation

1.  **Clone/Download** the repository.
2.  Install dependencies:
    ```bash
    npm install
    ```
3.  Ensure Redis is running:
    ```bash
    redis-cli ping
    # Expected output: PONG
    ```
4.  Start the server:
    ```bash
    npm run start
    ```

---

## Endpoints

### Set Activity Status

Updates the current activity status and "last active" timestamp for a given user.

- **URL**: `/v1/user/set-activity-status`
- **Method**: `POST`
- **Content-Type**: `application/json`

**Body**:
```json
{
  "clientId": "your_app_id",
  "userId": "user_unique_id",
  "status": "online"
}
```

**Common Statuses**:
- `online`
- `offline`
- `away`
- `dnd` (Do Not Disturb)

**Success Response**:
- Status: `200 OK`
- Body: `{"status": "Status updated successfully", "timestamp": 1629845039000}`

---

### Get Activity Status

Retrieves the current activity status for a given user.

- **URL**: `/v1/user/get-activity-status`
- **Method**: `GET`
- **Query Parameters**:
  - `clientId`: Unique identifier for the client app.
  - `userId`: Unique identifier for the user.

**Example Request**:
```bash
curl "http://localhost:4111/v1/user/get-activity-status?clientId=your_app_id&userId=user_unique_id"
```

**Success Response**:
- Status: `200 OK`
- Body: `{"status": "online"}`

---

## Testing

You can use `curl` or any API testing tool (like Postman/Insomnia) to test the endpoints.

### Using Curl:

1. **Set Status**:
   ```bash
   curl -X POST http://localhost:4111/v1/user/set-activity-status \
   -H "Content-Type: application/json" \
   -d '{"clientId": "test_app", "userId": "123", "status": "online"}'
   ```

2. **Get Status**:
   ```bash
   curl "http://localhost:4111/v1/user/get-activity-status?clientId=test_app&userId=123"
   ```
