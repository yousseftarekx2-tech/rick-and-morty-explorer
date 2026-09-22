# Rick & Morty Explorer

A responsive Flutter application for exploring characters, locations, and episode information from the Rick and Morty API.

The project was built to practice and demonstrate real-world Flutter development concepts including **REST API integration, BLoC/Cubit state management, repository architecture, pagination, search and filtering, responsive UI, error handling, animations, and testing**.

---

## Overview

**Rick & Morty Explorer** provides a clean and interactive way to explore the Rick and Morty universe.

Instead of loading the entire dataset at startup, the application uses **incremental pagination** to load characters as the user explores the list. Users can search characters, apply multiple filters, open detailed character profiles, and load episode information when needed.

The project focuses not only on building the UI, but also on structuring the application around clear responsibilities between the API layer, repositories, business logic, and presentation layer.

---

## Features

### Home

* Show overview and synopsis
* Total character count
* Total location count
* Total episode count
* Show statistics
* Featured characters
* Random character selection
* Quick navigation to the character explorer
* Independent loading and error states for different sections

### Character Explorer

* Responsive character grid
* Incremental pagination
* Pull-to-refresh
* Character image and information
* Loading skeletons
* Empty states
* Network error states
* Pagination error handling
* Retry support

### Search

* Case-insensitive character search
* Search while browsing loaded characters
* Starts-with results ranked before contains results
* Search state preserved while loading additional pages

### Filters

Characters can be filtered by:

* Status

  * Alive
  * Dead
  * Unknown

* Species

  * Human
  * Alien
  * Other

* Location

  * Searchable location selector
  * Locations are collected from the characters currently loaded in the application

Search and filters can be combined together.

### Character Details

Each character has a dedicated details screen containing:

* Character image
* Name
* Status
* Species
* Type
* Gender
* Origin
* Current location
* Number of appearances
* Episode information

Episode information is requested **on demand** rather than loading episode data for every character upfront.

### Episodes

When episode information is requested from a character details screen, the application loads the corresponding episode data and displays:

* Episode code
* Episode name
* Air date
* Season number
* Episode number

### UI / UX

* Material 3
* Light and dark themes
* Responsive layouts
* Adaptive character grid
* Skeleton loading
* Subtle animations
* Hero image transitions
* Animated state transitions
* Pull-to-refresh
* Clear empty and error states
* Responsive layout for phones, tablets, and desktop-sized screens

---

## Architecture

The project follows a layered approach that separates API communication, data handling, business logic, and presentation.

```text
                 ┌──────────────────────┐
                 │     Flutter UI       │
                 │ Screens / Widgets    │
                 └──────────┬───────────┘
                            │
                            ▼
                 ┌──────────────────────┐
                 │     Cubit / State    │
                 │ Business Logic       │
                 └──────────┬───────────┘
                            │
                            ▼
                 ┌──────────────────────┐
                 │     Repository       │
                 │ Data Abstraction     │
                 └──────────┬───────────┘
                            │
                            ▼
                 ┌──────────────────────┐
                 │      API Layer       │
                 │ Dio / REST API       │
                 └──────────┬───────────┘
                            │
                            ▼
                 ┌──────────────────────┐
                 │ Rick & Morty API     │
                 └──────────────────────┘
```

### Presentation

Contains:

* Screens
* Reusable widgets
* UI states
* Responsive layouts
* Animations

### Business Logic

The application uses Cubits to manage independent parts of the application:

* Characters
* Home data
* Episodes

Each Cubit is responsible for managing its own state and coordinating with the appropriate repository.

### Repository Layer

Repositories provide an abstraction between the business logic and the API.

This keeps the Cubits independent from the underlying HTTP implementation and makes the application easier to test and maintain.

### API Layer

The API layer uses **Dio** to communicate with the Rick and Morty REST API.

It handles:

* HTTP requests
* Pagination URLs
* Response validation
* Network errors
* Debug logging during development

---

## Data Flow

A typical character request follows this flow:

```text
User opens Character Explorer
            ↓
CharactersCubit
            ↓
CharactersRepository
            ↓
CharacterApi
            ↓
Rick & Morty REST API
            ↓
JSON Response
            ↓
Model Parsing
            ↓
Repository
            ↓
CharactersCubit
            ↓
UI
```

This separation keeps networking, data transformation, business logic, and UI responsibilities independent.

---

## Pagination

The Rick and Morty API provides paginated responses with up to 20 characters per page.

Instead of downloading the complete character dataset when the application starts, the app:

1. Loads the first page.
2. Displays the available characters immediately.
3. Detects when the user reaches the end of the current list.
4. Requests the next page.
5. Appends the new characters to the existing collection.
6. Re-applies the active search and filters.
7. Continues until the API reports that there are no more pages.

The pagination implementation also protects against duplicate requests and prevents multiple simultaneous page loads.

This approach keeps the initial experience lighter and avoids unnecessary API traffic.

---

## Search & Filtering

Search and filtering are handled locally against the characters that have already been loaded.

The search algorithm gives higher priority to names that **start with the entered query**, followed by names that simply contain the query.

For example:

```text
Query: "rick"

Starts with:
Rick Sanchez
Rick's Friend

Then:
Toxic Rick
Simple Rick
```

Filtering can be combined with search:

```text
Search
+
Status
+
Species
+
Location
```

When another page is loaded, the existing search and filter criteria are applied again to the complete loaded collection.

This means pagination continues even when the currently visible filtered result is empty.

---

## Character Details

The details screen presents the complete character information available from the API.

The application displays:

```text
Character
├── Image
├── Name
├── Status
├── Species
├── Type
├── Gender
├── Origin
├── Current Location
└── Episode Appearances
```

The character's episode array is already provided by the API, so the application can determine how many episodes the character appears in without downloading the complete episode catalog.

Episode details themselves are loaded only when requested.

---

## Home Experience

The Home screen provides a high-level overview of the show and acts as the entry point to the main explorer.

It includes:

* Show statistics
* Featured characters
* Random character interaction
* Character exploration entry point

The Home screen uses independent loading states for its sections, so a failure in one request does not prevent the rest of the screen from rendering.

---

## Responsive Design

The character grid adapts according to the available screen width.

The layout supports:

```text
Mobile
   ↓
2 columns

Small Tablet
   ↓
3 columns

Tablet / Small Desktop
   ↓
4 columns

Large Desktop
   ↓
5 columns
```

The UI was designed to remain usable across different screen sizes rather than targeting a single device.

---

## Loading & Error Handling

The application includes dedicated UI states for common asynchronous scenarios.

### Loading

* Initial loading indicators
* Skeleton character cards
* Pagination loading indicator

### Empty

* Empty character results
* Empty filtered results

### Network Errors

* Connection failures
* Timeouts
* Server errors
* Rate limiting
* Invalid API responses

### Pagination Errors

If loading another page fails, the already loaded characters remain visible and the user can retry the pagination request.

---

## Animations

Animations are intentionally kept subtle and functional.

The project includes:

* Hero image transitions
* Animated state changes
* Skeleton loading animation
* Smooth UI transitions

The goal is to improve the experience without making the interface feel over-animated.

---

## Testing

The project includes tests covering important parts of the application.

Testing focuses on:

* Model parsing
* Character search
* Search ranking
* Character filters
* Pagination
* Pagination error handling
* Duplicate request protection
* Cubit state transitions
* Home state behavior
* Episode loading
* Widget rendering
* Theme behavior
* Loading and error states

The goal is to verify both the business logic and important UI behaviors.

---

## Tech Stack

| Technology       | Purpose                                |
| ---------------- | -------------------------------------- |
| **Flutter**      | Cross-platform application development |
| **Dart**         | Programming language                   |
| **flutter_bloc** | State management                       |
| **Cubit**        | Business logic and state handling      |
| **Dio**          | HTTP client and REST API communication |
| **Material 3**   | UI system                              |
| **REST API**     | Remote data source                     |
| **Flutter Test** | Automated testing                      |

---

## Project Structure

The project is organized around the main application responsibilities:

```text
lib/
│
├── business_logic/
│   └── cubit/
│       ├── characters
│       ├── home
│       └── episodes
│
├── data/
│   ├── models/
│   ├── repository/
│   └── web_services/
│
├── presentation/
│   ├── screens/
│   └── widgets/
│
├── constants/
│
└── app_routing.dart
```

The exact implementation is intentionally kept simple while maintaining separation between:

* Data
* Business Logic
* Presentation

---

## API

This project uses the **Rick and Morty API**, a public REST API providing character, location, and episode data.

Main resources used by the application:

```text
Characters
https://rickandmortyapi.com/api/character

Locations
https://rickandmortyapi.com/api/location

Episodes
https://rickandmortyapi.com/api/episode
```

The API supports pagination and provides character, location, and episode resources through its REST interface.

Official API documentation:

[Rick and Morty API Documentation](https://rickandmortyapi.com/documentation?utm_source=chatgpt.com)

---

## Getting Started

### Prerequisites

Make sure you have Flutter installed and configured.

Check your Flutter environment:

```bash
flutter doctor
```

### Clone the repository

```bash
git clone https://github.com/yousseftarekx2-tech/rick-and-morty-explorer.git
```

### Navigate to the project

```bash
cd rick-and-morty-explorer
```

### Install dependencies

```bash
flutter pub get
```

### Run the application

```bash
flutter run
```

### Run tests

```bash
flutter test
```

---

## Project Goals

This project was built as a practical Flutter project to move beyond basic UI development and work with real application concerns.

The main goals were to practice:

* REST API integration
* JSON model parsing
* Repository pattern
* BLoC/Cubit state management
* Asynchronous programming
* Pagination
* Search algorithms
* Local filtering
* Error handling
* Responsive UI
* Reusable widgets
* Testing
* Separation of responsibilities

Rather than focusing only on making the screens look good, the project focuses on understanding how a Flutter application behaves when connected to real external data.

---

## Future Improvements

Possible future iterations include:

* Dedicated Episodes Explorer
* Seasons and episode browsing
* More detailed episode pages
* Additional location exploration
* Localization
* More advanced settings
* Improved offline capabilities
* Additional API-driven features
* Legitimate episode media playback if an appropriate licensed source becomes available

These features are intentionally kept outside the current scope so the existing application remains focused and maintainable.

---

## What I Learned

Building this project helped me work through several practical Flutter challenges:

* Handling real API responses instead of static data
* Designing state transitions for asynchronous operations
* Managing paginated data without replacing previously loaded content
* Combining search and multiple filters
* Handling API failures without breaking the existing UI
* Loading related data only when it is actually needed
* Building responsive layouts for different screen sizes
* Structuring Flutter code around responsibilities instead of putting everything inside screens
* Writing tests for both business logic and UI behavior

The project started as a Flutter/BLoC learning exercise and evolved into a more complete example of building a data-driven Flutter application.

---

## Screenshots & Demo

### Demo Video

> Demo video will be added here.

### Screenshots

> Project screenshots will be added here.

---

## License & Attribution

This project is a personal portfolio/learning project.

Character, location, episode, and related data are provided by the **Rick and Morty API**.

For API documentation and usage information, visit:

[rickandmortyapi.com/documentation](https://rickandmortyapi.com/documentation?utm_source=chatgpt.com)

This project is not affiliated with or endorsed by the creators of Rick and Morty.

---

## Author

**Youssef Tarek**

Computer Science Student | Flutter Developer

* GitHub: https://github.com/yousseftarekx2-tech
* LinkedIn: https://www.linkedin.com/in/youssef-tarek-1bb895340
* Portfolio: https://yousseftarekx2-tech.github.io/portfolio/
