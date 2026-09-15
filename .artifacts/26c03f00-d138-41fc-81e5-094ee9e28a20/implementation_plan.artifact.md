# Momento Complete Implementation Plan

Complete the social-media app features including functional Home Screen, Stories, Reels, Create, and Bottom Navigation using existing architecture and design patterns.

## User Review Required

> [!IMPORTANT]
> The app currently uses a local backend (`10.0.2.2:5000`). I will enable `useMockData` in `ApiConstants` to ensure the app is fully functional with fake data from Pexels and Random User APIs as requested for this development phase.

## Proposed Changes

### Configuration & Services
Update core constants and services to support mock data fallback.

#### [MODIFY] [api_constants.dart](file:///C:/Users/sumit/AndroidStudioProjects/Momento/lib/utils/api_constants.dart)
- Enable `useMockData = true`.

#### [MODIFY] [post_service.dart](file:///C:/Users/sumit/AndroidStudioProjects/Momento/lib/services/post_service.dart)
- Integrate `FakePostService` for data fetching when `useMockData` is enabled.

#### [MODIFY] [story_service.dart](file:///C:/Users/sumit/AndroidStudioProjects/Momento/lib/services/story_service.dart)
- Integrate `FakeStoryService` for story data.

#### [MODIFY] [reel_service.dart](file:///C:/Users/sumit/AndroidStudioProjects/Momento/lib/services/reel_service.dart)
- Integrate `PexelsService` for video content.

---

### Home & Feed
Complete the Home screen and feed interactions.

#### [MODIFY] [home_controller.dart](file:///C:/Users/sumit/AndroidStudioProjects/Momento/lib/controllers/home_controller.dart)
- Implement pagination logic for infinite scroll.
- Add real reactive states for likes, saves, and following.

#### [MODIFY] [post_card.dart](file:///C:/Users/sumit/AndroidStudioProjects/Momento/lib/widgets/post_card.dart)
- Add double-tap heart animation.
- Ensure all action buttons are reactive using GetX.

---

### Stories System
Full implementation of the story lifecycle.

#### [MODIFY] [story_controller.dart](file:///C:/Users/sumit/AndroidStudioProjects/Momento/lib/controllers/story_controller.dart)
- Implement full playback logic (progress, auto-next, pause/resume).
- Add methods for creating and posting stories locally.

#### [MODIFY] [story_viewer_screen.dart](file:///C:/Users/sumit/AndroidStudioProjects/Momento/lib/views/story_viewer_screen.dart)
- Complete UI with progress bars at the top.
- Add gesture detection (tap left/right, long press, swipe down).

#### [NEW] [story_editor_screen.dart](file:///C:/Users/sumit/AndroidStudioProjects/Momento/lib/views/story_editor_screen.dart)
- Basic image editor with text and emoji overlay.

---

### Reels
Complete the fullscreen video experience.

#### [MODIFY] [reel_controller.dart](file:///C:/Users/sumit/AndroidStudioProjects/Momento/lib/controllers/reel_controller.dart)
- Fix video initialization and lifecycle management.
- Implement pagination with `PexelsService`.

---

### Create & Navigation
Improve navigation consistency and the creation flow.

#### [MODIFY] [main_screen.dart](file:///C:/Users/sumit/AndroidStudioProjects/Momento/lib/views/main_screen.dart)
- Update middle "Create" button to show a Glass-styled bottom menu (Post, Story, Reel).
- Ensure consistent Bottom Navigation across all main tabs.

#### [MODIFY] [search_screen.dart](file:///C:/Users/sumit/AndroidStudioProjects/Momento/lib/views/search_screen.dart)
- Enhance the Explore screen with suggested users and a functional search.

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure no syntax errors.
- Run `flutter build apk` (optional) to verify build stability.

### Manual Verification
- Verify Splash → Login → Home flow.
- Test infinite scroll on Home feed.
- Test Story viewer gestures and auto-progress.
- Test Create Post/Story/Reel flows with `image_picker`.
- Verify Reels autoplay and swipe behavior.
- Confirm offline state using the global banner.
