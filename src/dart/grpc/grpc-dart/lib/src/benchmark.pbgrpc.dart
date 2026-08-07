//
//  Generated code. Do not modify.
//  source: benchmark.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'benchmark.pb.dart' as $0;

export 'benchmark.pb.dart';

@$pb.GrpcServiceName('benchmark.BenchmarkService')
class BenchmarkServiceClient extends $grpc.Client {
  static final _$health = $grpc.ClientMethod<$0.HealthRequest, $0.HealthResponse>(
      '/benchmark.BenchmarkService/Health',
      ($0.HealthRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.HealthResponse.fromBuffer(value));
  static final _$getJsonItems = $grpc.ClientMethod<$0.JsonItemsRequest, $0.JsonItemsResponse>(
      '/benchmark.BenchmarkService/GetJsonItems',
      ($0.JsonItemsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.JsonItemsResponse.fromBuffer(value));
  static final _$getUser = $grpc.ClientMethod<$0.GetUserRequest, $0.UserResponse>(
      '/benchmark.BenchmarkService/GetUser',
      ($0.GetUserRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.UserResponse.fromBuffer(value));
  static final _$getComplexOrders = $grpc.ClientMethod<$0.ComplexOrdersRequest, $0.ComplexOrdersResponse>(
      '/benchmark.BenchmarkService/GetComplexOrders',
      ($0.ComplexOrdersRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.ComplexOrdersResponse.fromBuffer(value));
  static final _$getCacheValue = $grpc.ClientMethod<$0.CacheRequest, $0.CacheResponse>(
      '/benchmark.BenchmarkService/GetCacheValue',
      ($0.CacheRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.CacheResponse.fromBuffer(value));

  BenchmarkServiceClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options,
        interceptors: interceptors);

  $grpc.ResponseFuture<$0.HealthResponse> health($0.HealthRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$health, request, options: options);
  }

  $grpc.ResponseFuture<$0.JsonItemsResponse> getJsonItems($0.JsonItemsRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getJsonItems, request, options: options);
  }

  $grpc.ResponseFuture<$0.UserResponse> getUser($0.GetUserRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getUser, request, options: options);
  }

  $grpc.ResponseFuture<$0.ComplexOrdersResponse> getComplexOrders($0.ComplexOrdersRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getComplexOrders, request, options: options);
  }

  $grpc.ResponseFuture<$0.CacheResponse> getCacheValue($0.CacheRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getCacheValue, request, options: options);
  }
}

@$pb.GrpcServiceName('benchmark.BenchmarkService')
abstract class BenchmarkServiceBase extends $grpc.Service {
  $core.String get $name => 'benchmark.BenchmarkService';

  BenchmarkServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.HealthRequest, $0.HealthResponse>(
        'Health',
        health_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.HealthRequest.fromBuffer(value),
        ($0.HealthResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.JsonItemsRequest, $0.JsonItemsResponse>(
        'GetJsonItems',
        getJsonItems_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.JsonItemsRequest.fromBuffer(value),
        ($0.JsonItemsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetUserRequest, $0.UserResponse>(
        'GetUser',
        getUser_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetUserRequest.fromBuffer(value),
        ($0.UserResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ComplexOrdersRequest, $0.ComplexOrdersResponse>(
        'GetComplexOrders',
        getComplexOrders_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ComplexOrdersRequest.fromBuffer(value),
        ($0.ComplexOrdersResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CacheRequest, $0.CacheResponse>(
        'GetCacheValue',
        getCacheValue_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.CacheRequest.fromBuffer(value),
        ($0.CacheResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.HealthResponse> health_Pre($grpc.ServiceCall call, $async.Future<$0.HealthRequest> request) async {
    return health(call, await request);
  }

  $async.Future<$0.JsonItemsResponse> getJsonItems_Pre($grpc.ServiceCall call, $async.Future<$0.JsonItemsRequest> request) async {
    return getJsonItems(call, await request);
  }

  $async.Future<$0.UserResponse> getUser_Pre($grpc.ServiceCall call, $async.Future<$0.GetUserRequest> request) async {
    return getUser(call, await request);
  }

  $async.Future<$0.ComplexOrdersResponse> getComplexOrders_Pre($grpc.ServiceCall call, $async.Future<$0.ComplexOrdersRequest> request) async {
    return getComplexOrders(call, await request);
  }

  $async.Future<$0.CacheResponse> getCacheValue_Pre($grpc.ServiceCall call, $async.Future<$0.CacheRequest> request) async {
    return getCacheValue(call, await request);
  }

  $async.Future<$0.HealthResponse> health($grpc.ServiceCall call, $0.HealthRequest request);
  $async.Future<$0.JsonItemsResponse> getJsonItems($grpc.ServiceCall call, $0.JsonItemsRequest request);
  $async.Future<$0.UserResponse> getUser($grpc.ServiceCall call, $0.GetUserRequest request);
  $async.Future<$0.ComplexOrdersResponse> getComplexOrders($grpc.ServiceCall call, $0.ComplexOrdersRequest request);
  $async.Future<$0.CacheResponse> getCacheValue($grpc.ServiceCall call, $0.CacheRequest request);
}
