# Instagram-like Full-screen Story Editor & Comment Management Implementation Plan

This plan details the implementation of a full-featured Instagram-style Story Editor and enhanced comment management (like, edit, delete) for the Flutter app "Momento".

## User Review Required

> [!IMPORTANT]
> - **Story Layers & Export**: Interactive layers (`List<EditorLayer>`) will support text, drawings, filters, and stickers. For videos, layer JSON data and transformations are persisted alongside the media upload rather than heavy local FFmpeg video re-encoding, ensuring high stability and performance.
> - **Music & GIFs**: Integrated music picker with preview and Giphy/Tenor placeholder API configuration for GIFs.
> - **Comments**: Adds Like, Edit, and Delete actions to existing comments in `CommentBottomSheet`.

## Proposed Changes

### Story Editor (`lib/features/story_editor/`)

#### [NEW] [editor_layer.dart](file:///C:/Users/sumit/AndroidStudioProjects/Momento/lib/features/story_editor/models/editor_layer.dart)
- Data model for editing layers (text, sticker, draw path, filter, mention).

#### [NEW] [story_draft.dart](file:///C:/Users/sumit/AndroidStudioProjects/Momento/lib/features/story_editor/models/story_draft.dart)
- Model holding selected media, layers, music, mentions, filters, AI label, and share options (Your Story, Close Friends).

#### [NEW] [story_editor_controller.dart](file:///C:/Users/sumit/AndroidStudioProjects/Momento/lib/features/story_editor/controllers/story_editor_controller.dart)
- Manages editing state, layers stack, undo/redo, text tool, draw paths, filters, music selection, mentions, and upload payload.

#### [NEW] [story_editor_screen.dart](file:///C:/Users/sumit/AndroidStudioProjects/Momento/lib/features/story_editor/story_editor_screen.dart)
- Full-screen 9:16 editor view with background media, right-side vertical toolbar, top-left back button, and bottom share bar.

#### [NEW] [editor_widgets](file:///C:/Users/sumit/AndroidStudioProjects/Momento/lib/features/story_editor/widgets/)
- `editor_toolbar.dart`: Vertical right-side toolbar.
- `text_layer.dart`: Movable, scalable, rotatable text overlay with color picker & font style.
- `sticker_layer.dart`: Emojis, time, date, location, poll, GIFs.
- `draw_canvas.dart`: Pen, marker, neon brush, eraser, color palette.
- `filter_strip.dart`: Restyle / preset color-filters (Vivid, Warm, Cool, B&W, Vintage, Fade, Drama, Noir).
- `music_picker_sheet.dart`: Music search, list, 30s preview.
- `mention_sheet.dart`: User mention search & tag.
- `more_options_sheet.dart`: Alt text, hide story from, allow replies/sharing.
- `share_bar.dart`: Your Story & Close Friends pills + next upload button.

### Comment Management

#### [MODIFY] [comment_controller.dart](file:///C:/Users/sumit/AndroidStudioProjects/Momento/lib/controllers/comment_controller.dart)
- Add methods for `toggleLikeComment`, `editComment`, and `deleteComment`.

#### [MODIFY] [comment_bottom_sheet.dart](file:///C:/Users/sumit/AndroidStudioProjects/Momento/lib/widgets/comment_bottom_sheet.dart)
- Add like button, edit dialog/input, and delete action for comments.

## Verification Plan

### Automated Tests
- Run `flutter analyze` to verify zero compilation errors and warnings.

### Manual Verification
- Select an image/video in the STORY tab -> opens full-screen `StoryEditorScreen`.
- Test right-side toolbar tools (Text, Restyle, Draw, Stickers, Music, Mention, AI label, More options).
- Test bottom share bar ("Your stories", "Close Friends") and upload flow.
- Test comment like, edit, and delete in `CommentBottomSheet`.
