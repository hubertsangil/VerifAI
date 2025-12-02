# Verity.ai - Visual App Structure

## 📱 Screen Flow

```
App Launch
    ↓
[Firebase Initialization]
    ↓
[AuthWrapper - Check Auth State]
    ↓
    ├─→ Not Authenticated → [AuthScreen]
    │                           ↓
    │                       Sign In / Sign Up
    │                           ↓
    └─→ Authenticated → [HomeScreen] ←─────┘
                            ↓
                    [BottomNavigationBar]
                            ↓
            ┌───────────────┴───────────────┐
            ↓                               ↓
    [New Check Tab]                 [History Tab]
            ↓                               ↓
    • URL Input Field              • StreamBuilder
    • Analyze Button               • List of HistoryTiles
    • Mission Panel                • Tap for details
    • Results Display
```

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────┐
│                   UI Layer                      │
│  ┌───────────┐  ┌───────────┐  ┌──────────┐   │
│  │AuthScreen │  │HomeScreen │  │ History  │   │
│  └─────┬─────┘  └─────┬─────┘  └────┬─────┘   │
│        │              │             │          │
└────────┼──────────────┼─────────────┼──────────┘
         │              │             │
┌────────┼──────────────┼─────────────┼──────────┐
│        │      Service Layer         │          │
│        ↓              ↓             ↓          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │Firebase  │  │ Gemini   │  │ History  │     │
│  │   Auth   │  │ Service  │  │ Service  │     │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘     │
│       │             │             │            │
└───────┼─────────────┼─────────────┼────────────┘
        │             │             │
┌───────┼─────────────┼─────────────┼────────────┐
│       │      Data Layer            │            │
│       ↓             ↓             ↓            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │Firebase  │  │ Gemini   │  │Firestore │     │
│  │   Auth   │  │   API    │  │    DB    │     │
│  └──────────┘  └──────────┘  └──────────┘     │
└─────────────────────────────────────────────────┘
```

## 📂 File Organization

```
lib/
├── main.dart                   [App Entry & Firebase Init]
│   └── VerityApp              → Material App with Theme
│       └── AuthWrapper         → Auth State Manager
│           ├── AuthScreen      (Not logged in)
│           └── HomeScreen      (Logged in)
│
├── config/
│   └── app_config.dart        [Centralized Configuration]
│       ├── geminiApiKey
│       ├── firebaseAppId
│       └── isConfigured()
│
├── models/
│   └── fact_check_model.dart [Data Models]
│       ├── FactCheckVerdict   (enum)
│       ├── Source             (class)
│       └── FactCheckResult    (class)
│           ├── toFirestore()
│           └── fromFirestore()
│
├── services/
│   ├── gemini_service.dart    [AI Fact-Checking]
│   │   ├── analyzeUrl()
│   │   ├── _parseGeminiResponse()
│   │   └── _extractSourcesFromText()
│   │
│   └── history_service.dart   [Firestore Operations]
│       ├── saveFactCheck()
│       ├── getHistoryStream()
│       ├── deleteFactCheck()
│       └── clearHistory()
│
├── screens/
│   ├── auth_screen.dart       [Authentication UI]
│   │   ├── Email field
│   │   ├── Password field
│   │   └── Sign In/Up toggle
│   │
│   ├── home_screen.dart       [Main App Screen]
│   │   ├── New Check Tab
│   │   │   ├── URL input
│   │   │   ├── Analyze button
│   │   │   ├── Mission panel
│   │   │   └── Results display
│   │   │
│   │   └── History Tab
│   │       └── HistoryScreen
│   │
│   └── history_screen.dart    [History View]
│       ├── StreamBuilder
│       ├── HistoryTile (widget)
│       └── Detail dialog
│
└── widgets/
    └── common_widgets.dart    [Reusable Components]
        ├── LoadingIndicator
        ├── ErrorDisplay
        └── EmptyState
```

## 🎨 UI Component Hierarchy

### AuthScreen
```
Scaffold
└── SafeArea
    └── Center
        └── SingleChildScrollView
            └── Form
                ├── Icon (App Logo)
                ├── Text (Title)
                ├── TextFormField (Email)
                ├── TextFormField (Password)
                ├── FilledButton (Submit)
                └── TextButton (Toggle mode)
```

### HomeScreen - New Check Tab
```
SingleChildScrollView
├── TextField (URL Input)
├── FilledButton (Analyze)
├── Card (Mission Panel)
│   └── ExpansionTile
│       └── Mission & SDG content
└── Card (Results) [if available]
    ├── Container (Verdict header)
    └── Padding (Summary & Sources)
```

### HistoryScreen
```
StreamBuilder<List<FactCheckResult>>
└── ListView.builder
    └── HistoryTile (Card)
        ├── Container (Status bar)
        ├── Icon (Verdict icon)
        ├── Text (Verdict)
        ├── Text (URL)
        ├── Text (Summary)
        └── Text (Timestamp)
```

## 🔄 Data Flow

### Fact-Check Flow
```
1. User Input
   ↓
   URL entered or shared
   ↓
2. Service Layer
   ↓
   GeminiService.analyzeUrl()
   ↓
   HTTP POST to Gemini API
   ↓
   Parse response
   ↓
3. Save to Firestore
   ↓
   HistoryService.saveFactCheck()
   ↓
   Store in /artifacts/{appId}/users/{userId}/factChecks
   ↓
4. Display Results
   ↓
   Update UI with FactCheckResult
```

### History Stream Flow
```
1. User Opens History Tab
   ↓
2. HistoryService.getHistoryStream()
   ↓
3. Firestore Real-time Listener
   ↓
4. StreamBuilder in HistoryScreen
   ↓
5. Build List of HistoryTiles
   ↓
6. Auto-updates on new data
```

## 🎨 Design System

### Colors (by Verdict)
- 🟢 **Accurate**: Green
- 🟠 **Misleading**: Orange
- 🔴 **False**: Red
- ⚪ **Unknown**: Grey

### Material 3 Components Used
- FilledButton (Primary actions)
- OutlinedButton (Secondary actions)
- Card (Content containers)
- NavigationBar (Bottom navigation)
- ExpansionTile (Collapsible panels)
- CircularProgressIndicator (Loading states)
- SnackBar (Toast messages)

### Typography Hierarchy
- **headlineLarge**: App title
- **headlineSmall**: Dialog titles
- **titleLarge**: Section headers
- **titleMedium**: Subsection headers
- **bodyLarge**: Primary text
- **bodyMedium**: Secondary text
- **bodySmall**: Timestamps, hints

## 🔐 Firebase Structure

```
Firestore Database:
artifacts/
  └── {appId}/
      └── users/
          └── {userId}/
              └── factChecks/ (collection)
                  └── {autoId}/ (document)
                      ├── verdict: "ACCURATE" | "MISLEADING" | "FALSE" | "UNKNOWN"
                      ├── summary: string
                      ├── sources: array[
                      │   └── {title: string, uri: string}
                      │   ]
                      ├── timestamp: timestamp
                      └── originalUrl: string

Firebase Auth:
users/ (auto-managed)
  └── {userId}/
      ├── email: string
      ├── emailVerified: boolean
      └── metadata: {createdAt, lastSignInAt}
```

## 🔌 External APIs

### Gemini API
- **Endpoint**: `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent`
- **Method**: POST
- **Auth**: API Key in query parameter
- **Request**: JSON with text prompt
- **Response**: Generated text with fact-check analysis

### Receive Sharing Intent
- **Platform**: Android
- **Trigger**: Share action from other apps
- **Data**: Text/URLs shared to the app
- **Listeners**: Media stream, text stream
