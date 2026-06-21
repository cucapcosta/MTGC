/// Layout metrics shared across multi-screen (Mate XT) features.
library;

/// Which Mate XT fold state the window width implies.
enum ScreenMode { single, dual, triple }

// Tune to real Mate XT logical widths once measured on-device.
const double kDualMinWidth = 700;
const double kTripleMinWidth = 1100;

// Standard MTG card aspect ratio (width / height).
const double kCardAspect = 488 / 680;

ScreenMode modeFor(double width) {
  if (width >= kTripleMinWidth) return ScreenMode.triple;
  if (width >= kDualMinWidth) return ScreenMode.dual;
  return ScreenMode.single;
}

/// Grid columns to show for a given screen mode.
int columnsFor(ScreenMode mode) => switch (mode) {
      ScreenMode.single => 2,
      ScreenMode.dual => 4,
      ScreenMode.triple => 6,
    };
