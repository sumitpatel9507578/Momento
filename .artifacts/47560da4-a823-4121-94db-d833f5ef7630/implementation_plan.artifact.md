# Momento Home Feed Implementation Plan

This plan outlines the steps to fully implement the Momento Home Feed with fake data, stories, and interactive components following the Dark Liquid Glass design language.

## User Review Required

> [!IMPORTANT]
> The implementation uses GetX for state management. I will be refactoring some existing controllers and models to align with the new requirements.

## Proposed Changes

### Models

#### [MODIFY] [post_model.dart](file:///C:/Users/sumit/AndroidStudioProjects/momento/lib/models/post_model.dart)
Update `PostModel` to include:
- `postId`, `userId`, `username`, `profileImage`, `mediaUrl`, `mediaType`
- `caption`, `likesCount`, `commentsCount`, `isLiked`, `isSaved`
- `timestamp`, `location`
- `isFollowing` (local state for follow button)

#### [MODIFY] [story_model.dart](file:///C:/Users/sumit/AndroidStudioProjects/momento/lib/models/story_model.dart)
Update `StoryModel` to include:
- `storyId`, `userId`, `username`, `profileImage`, `mediaUrl`, `mediaType`
- `timestamp`, `viewed`

---

### Services

#### [MODIFY] [fake_post_service.dart](file:///C:/Users/sumit/AndroidStudioProjects/momento/lib/services/fake_post_service.dart)
Implement a service to return 20 stable mock posts with realistic image URLs and metadata.

#### [NEW] [fake_story_service.dart](file:///C:/Users/sumit/AndroidStudioProjects/momento/lib/services/fake_story_service.dart)
Create a service to return 10-15 mock stories using Random User API data for profiles.

---

### Controllers

#### [MODIFY] [home_controller.dart](file:///C:/Users/sumit/AndroidStudioProjects/momento/lib/controllers/home_controller.dart)
Enhance with:
- Pagination logic (fetch next page)
- `isLoadingMore` state
- Follow/Unfollow logic (local)
- Save/Unsave logic

#### [MODIFY] [story_controller.dart](file:///C:/Users/sumit/AndroidStudioProjects/momento/lib/controllers/story_controller.dart)
Enhance with:
- Story playback logic (index, progress)
- Pause/Resume methods
- Navigation (next/prev)

---

### Widgets

#### [NEW] [post_card.dart](file:///C:/Users/sumit/AndroidStudioProjects/momento/lib/widgets/post_card.dart)
A reusable premium post component with:
- Glassmorphic actions bar
- Heart animation on double tap
- Follow button
- Post menu (Mute, Block, etc.)

#### [NEW] [story_bar.dart](file:///C:/Users/sumit/AndroidStudioProjects/momento/lib/widgets/story_bar.dart)
Horizontal list of stories with gradient rings and "Your Story" item.

#### [NEW] [story_item.dart](file:///C:/Users/sumit/AndroidStudioProjects/momento/lib/widgets/story_item.dart)
Individual circular story component with viewed/unseen state.

---

### Views

#### [MODIFY] [home_screen.dart](file:///C:/Users/sumit/AndroidStudioProjects/momento/lib/views/home_screen.dart)
Rebuild the UI to include:
- Glass Top App Bar with "Momento" and notifications.
- `CustomScrollView` with `SliverAppBar`, `SliverToBoxAdapter` for stories, and `SliverList` for posts.
- Pull-to-refresh and infinite scroll detection.

#### [NEW] [story_view_screen.dart](file:///C:/Users/sumit/AndroidStudioProjects/momento/lib/views/story_view_screen.dart)
Full-screen story viewer with:
- Progress indicators
- Swipe-to-dismiss
- Tap to navigate

---

### Routes & Bindings

#### [MODIFY] [app_pages.dart](file:///C:/Users/sumit/AndroidStudioProjects/momento/lib/routes/app_pages.dart)
Add route for `AppRoutes.story`.

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure no linting errors.
- Run `flutter test` (if applicable) to verify model parsing.

### Manual Verification
- Verify Home Feed loads 10 initial posts.
- Verify scrolling to bottom loads more posts.
- Verify pull-to-refresh works.
- Verify tapping a story opens the full-screen viewer.
- Verify story progress bar moves and auto-advances.
- Verify Like/Save/Follow buttons update UI instantly.
