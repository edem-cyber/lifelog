# LifeLog - Daily Journal App - for Oppx Fullstack Flutter role

A Flutter app for daily journaling with mood tracking and analytics. Users can create one journal entry per day with title, body, and mood rating (1-5).

## Setup Instructions

### Prerequisites
- Flutter SDK 3.7+
- Supabase account

### 1. Supabase Setup
1. Create a new Supabase project at https://supabase.com
2. Go to **Table Editor** and create a table named `journal_entries` with these columns:
   - `id` (uuid, primary key, default: gen_random_uuid())
   - `user_id` (uuid, foreign key to auth.users)
   - `title` (text, required)
   - `body` (text, required) 
   - `mood` (int4, required)
   - `date` (date, required)
   - `created_at` (timestamptz, default: now())
   - `updated_at` (timestamptz, default: now())

3. Go to **Authentication > Settings** and disable "Enable email confirmations"
4. Go to **Database > Policies** and enable RLS for the `journal_entries` table
5. Create an Edge Function named `dynamic-endpoint` (TypeScript code provided separately)

### 2. App Configuration
Update `lib/config/supabase_config.dart` with your project credentials:

```dart
static const String supabaseUrl = 'YOUR_NEW_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_NEW_ANON_KEY';
```

---

## Security Note

For this demo app, the Supabase anon key and URL are hardcoded in the source code for simplicity and ease of review. **In production, we would never expose any keys directly in the code.**

Instead, use a package like [`flutter_dotenv`](https://pub.dev/packages/flutter_dotenv) to load environment variables securely and keep keys out of version control.

To use your own Supabase project, replace the values in `lib/config/supabase_config.dart` with your own project's URL and anon key.

### 3. Run the App
```bash
git clone <repository-url>
cd lifelog
flutter pub get
flutter run
```

## Schema Design Decisions

- **One entry per day**: Enforced via unique constraint on `(user_id, date)` and Edge Function validation
- **Mood as integer**: Simple 1-5 scale for easy analytics and storage efficiency
- **Date separation**: Separate `date` field from `created_at` for proper daily grouping
- **RLS policies**: Database-level security ensuring users only access their own data

## Assumptions & Tradeoffs

**Assumptions:**
- Users want simple mood tracking (1-5 scale vs complex emotions)
- One entry per day limit encourages focused reflection
- Text-based entries are sufficient (no image attachments)

**Tradeoffs:**
- **Edge Functions over client validation**: Ensures data integrity but requires internet
- **Material 3 over custom design**: Faster development, consistent UX
- **Real-time search over indexed search**: Simpler implementation for small datasets

## Known Limitations

- Requires internet connection for all operations
- Text-only entries (no images, voice notes, or attachments)
- Basic export format (plain text only)
- No offline functionality or data caching
- Limited analytics compared to dedicated mood tracking apps

## Future  Enhancements

The app's architecture is designed to integrate AI-powered features for enhanced user insights:

- **Google Gemini Integration**: Analyze journal content to provide personalized mood insights and writing patterns
- **Sentiment Analysis**: Automatically detect emotional themes beyond the 1-5 mood scale
- **Smart Suggestions**: AI-generated writing prompts based on mood trends and past entries
- **Predictive Analytics**: Identify mood patterns and suggest wellness activities


The current simple schema supports future AI features while maintaining data privacy and user control.

## Tech Stack

**Frontend:** Flutter, Riverpod, GoRouter, fl_chart  
**Backend:** Supabase (Auth, Database, Edge Functions, RLS)
