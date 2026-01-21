/// Concurrency control utilities for OhMyG0sh scanner.
///
/// This module provides tools to manage concurrent operations and prevent
/// resource exhaustion (e.g., "too many open files" errors).
library;

import 'dart:async';

/// A semaphore for controlling concurrent access to resources.
///
/// Limits the number of concurrent operations to prevent resource exhaustion.
/// Useful for controlling file I/O operations, network requests, or any
/// resource-limited operations.
///
/// Example:
/// ```dart
/// final semaphore = Semaphore(maxConcurrent: 10);
///
/// Future<void> processFile(File file) async {
///   await semaphore.acquire();
///   try {
///     // Process file
///     await file.readAsString();
///   } finally {
///     semaphore.release();
///   }
/// }
///
/// // Process many files with limited concurrency
/// await Future.wait(files.map(processFile));
/// ```
class Semaphore {
  /// Maximum number of concurrent operations allowed.
  final int maxConcurrent;

  /// Current number of active operations.
  int _current = 0;

  /// Queue of operations waiting to acquire the semaphore.
  final List<Completer<void>> _waiting = [];

  /// Creates a semaphore with the specified concurrency limit.
  ///
  /// Parameters:
  /// - [maxConcurrent]: Maximum number of concurrent operations (must be > 0)
  ///
  /// Throws:
  /// - [ArgumentError] if maxConcurrent is less than 1
  Semaphore(this.maxConcurrent) {
    if (maxConcurrent < 1) {
      throw ArgumentError.value(
        maxConcurrent,
        'maxConcurrent',
        'Must be at least 1',
      );
    }
  }

  /// Acquire the semaphore, waiting if necessary.
  ///
  /// If the current number of active operations is below the limit, returns
  /// immediately. Otherwise, waits until another operation releases the
  /// semaphore.
  ///
  /// Always pair with [release] in a try-finally block to ensure proper cleanup.
  ///
  /// Example:
  /// ```dart
  /// await semaphore.acquire();
  /// try {
  ///   // Do work
  /// } finally {
  ///   semaphore.release();
  /// }
  /// ```
  Future<void> acquire() async {
    if (_current < maxConcurrent) {
      _current++;
      return;
    }

    final completer = Completer<void>();
    _waiting.add(completer);
    return completer.future;
  }

  /// Release the semaphore, allowing waiting operations to proceed.
  ///
  /// If there are operations waiting in the queue, the next one is allowed
  /// to proceed. Otherwise, decrements the current operation count.
  ///
  /// Always call this in a finally block after [acquire].
  void release() {
    if (_waiting.isNotEmpty) {
      final completer = _waiting.removeAt(0);
      completer.complete();
    } else {
      _current--;
    }
  }

  /// Execute a function with semaphore protection.
  ///
  /// Automatically acquires the semaphore before executing [fn] and releases
  /// it afterwards, even if [fn] throws an error.
  ///
  /// This is a convenience method that handles acquire/release automatically.
  ///
  /// Example:
  /// ```dart
  /// final result = await semaphore.execute(() async {
  ///   return await processFile(file);
  /// });
  /// ```
  Future<T> execute<T>(Future<T> Function() fn) async {
    await acquire();
    try {
      return await fn();
    } finally {
      release();
    }
  }

  /// Current number of active operations.
  int get currentCount => _current;

  /// Number of operations waiting in queue.
  int get waitingCount => _waiting.length;

  /// Whether the semaphore is at capacity.
  bool get isAtCapacity => _current >= maxConcurrent;
}

/// Execute a list of futures with bounded concurrency.
///
/// Similar to [Future.wait], but limits the number of concurrent operations.
/// This prevents resource exhaustion when processing large batches.
///
/// Parameters:
/// - [futures]: List of future-producing functions to execute
/// - [maxConcurrent]: Maximum number of concurrent operations
///
/// Returns:
/// - List of results in the same order as input
///
/// Example:
/// ```dart
/// final results = await executeConcurrently(
///   files.map((f) => () => processFile(f)).toList(),
///   maxConcurrent: 10,
/// );
/// ```
Future<List<T>> executeConcurrently<T>(
  List<Future<T> Function()> futures, {
  required int maxConcurrent,
}) async {
  final semaphore = Semaphore(maxConcurrent);
  return Future.wait(
    futures.map((fn) => semaphore.execute(fn)),
  );
}

/// Process items in batches with bounded concurrency.
///
/// Divides items into batches and processes each batch concurrently,
/// with a limit on concurrent operations within each batch.
///
/// This is useful when you want to process items in chunks while still
/// maintaining concurrency control.
///
/// Parameters:
/// - [items]: Items to process
/// - [processor]: Function to process each item
/// - [batchSize]: Number of items per batch
/// - [maxConcurrent]: Maximum concurrent operations per batch
///
/// Returns:
/// - List of results in the same order as input
///
/// Example:
/// ```dart
/// final results = await processBatched(
///   files,
///   processor: (file) => scanFile(file),
///   batchSize: 100,
///   maxConcurrent: 10,
/// );
/// ```
Future<List<T>> processBatched<S, T>(
  List<S> items, {
  required Future<T> Function(S) processor,
  required int batchSize,
  required int maxConcurrent,
}) async {
  final results = <T>[];

  for (int i = 0; i < items.length; i += batchSize) {
    final end = (i + batchSize < items.length) ? i + batchSize : items.length;
    final batch = items.sublist(i, end);

    final batchResults = await executeConcurrently(
      batch.map((item) => () => processor(item)).toList(),
      maxConcurrent: maxConcurrent,
    );

    results.addAll(batchResults);
  }

  return results;
}
