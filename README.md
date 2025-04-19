# Auto Shape Detection Canvas 🎨

A Flutter-based drawing application with real-time geometric shape recognition. Users can draw freehand sketches, and the app automatically detects and renders perfect geometric shapes.

![Shape Detection Demo](https://via.placeholder.com/800x400.png?text=Shape+Detection+Demo) <!-- Add actual demo gif/image -->

## Features ✨

- **Multi-Shape Detection**: Recognizes 7+ geometric forms:
  - Lines 📏
  - Circles ⚪
  - Triangles ▲
  - Rectangles/Squares ▭
  - Pentagons ⬠
  - Hexagons ⬢

- **Smart Recognition Algorithms**:
  - Ramer-Douglas-Peucker path simplification
  - Vertex detection through angle analysis
  - Advanced geometric calculations:
    - Centroid detection for circles
    - Colinearity checks
    - Polygon angle validation

- **Real-Time Feedback**:
  - Live drawing preview
  - Automatic shape replacement
  - Multi-shape canvas preservation

## Technical Highlights 🛠️

### Core Components
- `ShapeDetector`: Neural-inspired detection engine
- `CustomPaint` canvas with gesture recognition
- State-managed shape history

### Detection Pipeline
1. Path simplification (ε=3.0 tolerance)
2. Vertex detection (150° angle threshold)
3. Shape classification hierarchy:
   - Polygons → Circles → Lines

### Precision Metrics
- 25° angle tolerance for rectangles
- 5px side length variance
- 500 radius variance limit for circles

## Setup & Usage 🚀

### Requirements
- Flutter 3.0+
- Dart 2.17+

### Installation
```bash
flutter pub get
flutter run
```

### Drawing Tips
- Draw shapes in single strokes
- Close polygon paths completely
- Pause briefly at vertices


### Contribution 🤝
Open to PRs for:

- Additional shape types
- Improved detection accuracy
- Performance optimizations
- UI/UX enhancements
