---
description: Apply when working with interactive image components that need to
  display beyond their container bounds
alwaysApply: false
---

When implementing image display with pan and zoom functionality in Flutter, use OverflowBox instead of ClipRect to allow images to extend beyond container boundaries. Set maxWidth and maxHeight to be 3-4 times the container size and use alignment: Alignment.center for proper positioning.