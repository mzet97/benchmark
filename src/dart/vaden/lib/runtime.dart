import 'dart:io';

/// Runtime knobs every implementation in this benchmark reads from the same
/// ConfigMap. See docs/ACTION_PLAN.md, Fase 3.1 and 3.2.

/// How many isolates should serve requests.
///
/// Dart runs one isolate by default, so a bare `dart run` in a pod with 7 CPUs
/// uses one of them. Every compiled runtime here uses all the cores it is
/// given, so leaving Dart on a single isolate measures "is this runtime
/// multi-threaded", not the framework.
int benchWorkers() {
  final requested = int.tryParse(Platform.environment['BENCH_CPUS'] ?? '');
  if (requested != null && requested > 0) return requested;
  return Platform.numberOfProcessors;
}

/// Connections this isolate is allowed to open.
///
/// DB_POOL_MAX is the budget for the whole pod, not for one isolate. If every
/// isolate opened DB_POOL_MAX connections, a multi-isolate runtime would run
/// against N times the pool of a single-threaded one -- the same hidden
/// variable the contract exists to remove.
int dbPoolPerWorker() {
  final total = int.tryParse(Platform.environment['DB_POOL_MAX'] ?? '') ?? 32;
  final perWorker = total ~/ benchWorkers();
  return perWorker < 1 ? 1 : perWorker;
}

/// Column decoding for the /db/complex aggregates.
///
/// package:postgres v3 decodes `numeric` to a String, to keep the exact
/// arbitrary-precision value. `total_amount` is DECIMAL(10,2), so SUM and AVG
/// over it arrive as Strings -- every Dart implementation here cast them
/// straight to `num`, which throws at runtime. COUNT is int8 and does arrive
/// as an int.
int asInt(Object? value) {
  if (value is int) return value;
  if (value is BigInt) return value.toInt();
  if (value is num) return value.toInt();
  return int.parse(value.toString());
}

double asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.parse(value.toString());
}
