# MeetSpace

MeetSpace is a platform for discovering, reserving and managing workspaces, meeting rooms and event spaces.

Developed as part of the Software Development 2 course (*Razvoj softvera II*).

## About

MeetSpace allows users to browse available spaces, view detailed information, select additional amenities and create reservations through secure in-app payments.

The mobile application is intended for regular users. It supports booking, Stripe and PayPal payments, favorites, reviews, notifications and personalized space recommendations.

The Windows desktop application is intended for administrators. It provides space and reference-data management, user administration, booking approval and rejection workflows, reminders and revenue reporting.

The backend is implemented as an ASP.NET Core REST API. RabbitMQ is used as a message broker for asynchronous communication with a separate Subscriber service. The complete backend system is containerized using Docker Compose.

## Features

### Mobile Application

- User registration and login
- Profile management and profile photo upload
- Space browsing and detailed space information
- Space images, facilities and amenities
- Space search and filtering
- Favorites
- Booking creation with selected date, time and amenities
- Stripe in-app payment
- PayPal sandbox payment
- Booking history and upcoming bookings
- User booking cancellation
- Reviews after completed bookings
- Personalized space recommendations
- Real-time notification refresh using SignalR
- Notification preferences with enable/disable setting
- Mobile logout
- Password reset through email verification code

### Desktop Administration Application

- Administrator login and logout
- Space management
- Space image upload
- Facility management
- Country and city management
- Space type management
- Amenity and amenity category management
- User management
- Booking status management
- Upcoming booking overview
- Booking history
- Booking approval and rejection
- Rejection reason entry
- Administrator booking cancellation
- Reminder sending
- Revenue overview 
- User review monitoring
- PDF report generation for users and revenue
- Payment method and payment status management

### Recommendation System

MeetSpace uses an **Item-based Collaborative Filtering** recommendation algorithm.

The system analyzes approved bookings, favorites and user ratings to recommend spaces based on previous user interactions and similarities between spaces.

Detailed documentation is available in:

[`recommender-dokumentacija.md`](./recommender-dokumentacija.md)

## Technology Stack

| Technology | Purpose |
| --- | --- |
| ASP.NET Core 8 | REST API |
| Entity Framework Core | Database access and migrations |
| SQL Server 2022 | Database |
| Flutter | Android and Windows applications |
| Docker Compose | Container orchestration |
| RabbitMQ | Message broker |
| ASP.NET Core Subscriber Worker | Asynchronous message processing |
| SignalR | Automatic notification refresh |
| Stripe | In-app card payments |
| PayPal Sandbox | PayPal payments |
| Azure Blob Storage | User and space image storage |

## Microservice Architecture

The backend consists of separate services:

| Service | Description |
| --- | --- |
| `api` | ASP.NET Core REST API used by mobile and desktop applications |
| `subscriber` | Background worker that consumes RabbitMQ messages and executes asynchronous tasks |
| `rabbitmq` | Message broker used for communication between API and Subscriber |
| `sqlserver` | SQL Server database |

The API publishes messages to RabbitMQ for:

- password-reset email requests;
- booking status changes;
- booking reminders.

The Subscriber service consumes these messages and performs real background work:

- sends password-reset emails through SMTP;
- forwards booking status notifications to the API;
- forwards reminder notifications to the API.

## Prerequisites

Before starting the application, install:

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- an archive extraction tool that supports password-protected ZIP files
- Android Emulator AVD for the mobile application
- Windows OS for the desktop application

## Backend Setup

### 1. Clone the Repository

```bash
git clone https://github.com/Emela-Rizvanovic/MeetSpace-RS2.git
cd MeetSpace-RS2
```

### 2. Extract Environment Configuration

Locate the protected archive in the repository root:

```text
.env-tajne.zip
```

Extract its content into the same root folder. The extracted file must be:

```text
.env
```

Archive password:

```text
fit
```

### 3. Start All Backend Services

From the repository root, run:

```bash
docker compose up --build
```

Wait until the SQL Server, RabbitMQ, API and Subscriber services are started.

Docker Compose starts the services in the required order and waits for SQL Server and RabbitMQ health checks.

After startup, the API automatically:
1. applies Entity Framework Core migrations;
2. creates the database schema;
3. inserts the initial seed data.

No manual database configuration is required.

### 4. Stop Backend Services

```bash
docker compose down
```

To remove containers and reset the Docker database volume:

```bash
docker compose down -v
```

## Docker Services and Ports

| Service | Address |
| --- | --- |
| Backend API | `http://localhost:5245` |
| SQL Server | `localhost,14330` |
| RabbitMQ | `localhost:5672` |
| RabbitMQ Management UI | `http://localhost:15672` |

RabbitMQ Management UI credentials are provided through the extracted `.env` configuration.

## Frontend Builds

The prepared Android and Windows builds are available as a ZIP archive in the corresponding GitHub Release.

Build archive name:

```text
fit-build-2026-05-31.zip
```

The archive contains:

```text
fit-build-2026-05-31/
|-- meetspace_mobile/
|   `-- app-release.apk
|
`-- meetspace_desktop/
    `-- Release/
        |-- meetspace_desktop.exe
        |-- data/
        `-- required DLL files
```

### Windows Desktop Application

1. Extract the GitHub Release build archive.
2. Open the Windows `Release` folder.
3. Run:

```text
meetspace_desktop.exe
```

The desktop application connects to:

```text
http://localhost:5245
```

### Android Mobile Application

1. Start an Android Emulator AVD.
2. Remove any previously installed version of the application.
3. Extract the GitHub Release build archive.
4. Locate:

```text
app-release.apk
```

5. Drag the APK file into the Android emulator.
6. Launch the MeetSpace application.

The Android application connects to the host machine API through:

```text
http://10.0.2.2:5245
```

## Login Credentials

### Administrator Account

| Context | Username | Password |
| --- | --- | --- |
| Windows desktop application | `desktop` | `test` |

The administrator account is used for dashboard access, booking processing, reminders, user administration and reference-data management.

### Primary Mobile User Account

| Context | Username | Password |
| --- | --- | --- |
| Android mobile application | `mobile` | `test` |

The `mobile` account includes seeded booking history, upcoming bookings, favorites and recommendation data.

### Additional Mobile User Accounts

| Username | Password |
| --- | --- |
| `user2` | `test` |
| `user3` | `test` |

These seeded accounts support recommendation-system demonstration data.

## Stripe Test Payment

Stripe payments run in test mode.

Use the following Stripe test card:

| Field | Value |
| --- | --- |
| Cardholder name | `Test User` |
| Card number | `4242 4242 4242 4242` |
| Expiration date | Any future date, for example `12/34` |
| CVC | Any three digits, for example `123` |

These credentials do not process real payments.

## PayPal Sandbox Payment

PayPal payments run in sandbox mode.

Use the following sandbox buyer account:

| Field | Value |
| --- | --- |
| Email | `sb-kjnyt50686065@personal.example.com` |
| Password | `]M>my%44` |

These credentials are intended only for testing and do not process real payments.

## Important Workflows

### User Booking Workflow

1. Log in through the mobile application.
2. Browse available spaces.
3. Open space details.
4. Select date, time and optional amenities.
5. Confirm booking information.
6. Pay using Stripe or PayPal.
7. Review the booking in the upcoming bookings list.
8. Receive notifications after administrator actions.

### Administrator Booking Workflow

1. Log in through the Windows desktop application.
2. Open upcoming bookings.
3. Review pending reservations.
4. Approve or reject a reservation.
5. Enter a rejection reason when rejecting.
6. Send a reminder when needed.
7. Review booking history and revenue data.

### Password Reset Workflow

1. Request password reset from the mobile application.
2. The API publishes a RabbitMQ message.
3. The Subscriber service consumes the message.
4. The Subscriber sends a verification code by email.
5. Enter the received code and choose a new password.

### Notification Workflow

1. The administrator approves, rejects or cancels a booking, or sends a reminder.
2. The API publishes a RabbitMQ message.
3. The Subscriber consumes the message.
4. The Subscriber forwards the notification request to the API.
5. The mobile application automatically receives refreshed notifications.

## Project Structure

```text
MeetSpace-RS2/
|
|-- MeetSpaceBackend/
|   |-- MeetSpace.Models/              # Request, response and shared model classes
|   |-- MeetSpace.Services/            # Business logic, database access and migrations
|   |-- MeetSpace.Subscriber/          # RabbitMQ background worker
|   |-- MeetSpace.WebAPI/              # REST API, controllers and SignalR hub
|   |-- Dockerfile.api                 # API Docker image
|   |-- Dockerfile.subscriber          # Subscriber Docker image
|   `-- MeetSpace.sln
|
|-- MeetSpaceFrontend/
|   |-- meetspace_mobile/              # Flutter Android application
|   `-- meetspace_desktop/             # Flutter Windows application
|
|-- .dockerignore
|-- .gitignore
|-- docker-compose.yml
|-- .env-tajne.zip                  # Protected environment configuration archive
|-- recommender-dokumentacija.md
`-- README.md
```

## Troubleshooting

### View Docker Logs

```bash
docker compose logs -f
```

### Rebuild and Restart Services

```bash
docker compose down
docker compose up --build
```

### Reset Docker Database

```bash
docker compose down -v
docker compose up --build
```

Use database reset only when a clean seeded database is required.

### Check Running Containers

```bash
docker compose ps
```

## Academic Context

This project was developed as a semester assignment for the Software Development 2 course (*Razvoj softvera II*) at the Faculty of Information Technologies, University of Mostar.

The project demonstrates:
- full-stack application development;
- mobile and desktop Flutter applications;
- REST API development;
- authentication and role-based authorization;
- microservice architecture;
- message-driven communication through RabbitMQ;
- Docker containerization;
- Stripe and PayPal integrations;
- recommendation-system implementation.

## License

This project was created for educational purposes as part of the Software Development 2 course.