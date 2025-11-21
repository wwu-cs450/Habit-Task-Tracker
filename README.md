# Habit Task Tracker

[![Lint and Test](https://github.com/wwu-cs450/Habit-Task-Tracker/actions/workflows/lint_and_test.yaml/badge.svg)](https://github.com/wwu-cs450/Habit-Task-Tracker/actions/workflows/lint_and_test.yaml) [![codecov](https://codecov.io/gh/wwu-cs450/Habit-Task-Tracker/branch/main/graph/badge.svg)](https://codecov.io/gh/wwu-cs450/Habit-Task-Tracker/branch/main)

(Coverage reported is for main branch)

A Habit and Task tracking application built as the CS 450 course project for Walla Walla University.

## Features

## Getting started 

Prerequisites

- Git
- If doing work for Android, see [Android development setup](docs/android-development-setup.md)

```pwsh
git clone https://github.com/wwu-cs450/Habit-Task-Tracker.git
cd Habit-Task-Tracker
```

To check if notifications are working, run with `flutter run --dart-define=NOTIF_TEST=true`. You should see three notifications: the first appears immediately after the app loads, the second appears 10 seconds after loading, and the third appears 20 seconds after loading.

## Architecture & docs

See `docs/ADR/` for architecture decision records related to design choices.


## License
