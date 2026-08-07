//
//  Generated code. Do not modify.
//  source: benchmark.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use healthRequestDescriptor instead')
const HealthRequest$json = {
  '1': 'HealthRequest',
};

/// Descriptor for `HealthRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List healthRequestDescriptor = $convert.base64Decode(
    'Cg1IZWFsdGhSZXF1ZXN0');

@$core.Deprecated('Use healthResponseDescriptor instead')
const HealthResponse$json = {
  '1': 'HealthResponse',
  '2': [
    {'1': 'status', '3': 1, '4': 1, '5': 9, '10': 'status'},
    {'1': 'version', '3': 2, '4': 1, '5': 9, '10': 'version'},
    {'1': 'timestamp', '3': 3, '4': 1, '5': 9, '10': 'timestamp'},
    {'1': 'database', '3': 4, '4': 1, '5': 9, '10': 'database'},
    {'1': 'cache', '3': 5, '4': 1, '5': 9, '10': 'cache'},
  ],
};

/// Descriptor for `HealthResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List healthResponseDescriptor = $convert.base64Decode(
    'Cg5IZWFsdGhSZXNwb25zZRIWCgZzdGF0dXMYASABKAlSBnN0YXR1cxIYCgd2ZXJzaW9uGAIgAS'
    'gJUgd2ZXJzaW9uEhwKCXRpbWVzdGFtcBgDIAEoCVIJdGltZXN0YW1wEhoKCGRhdGFiYXNlGAQg'
    'ASgJUghkYXRhYmFzZRIUCgVjYWNoZRgFIAEoCVIFY2FjaGU=');

@$core.Deprecated('Use jsonItemsRequestDescriptor instead')
const JsonItemsRequest$json = {
  '1': 'JsonItemsRequest',
  '2': [
    {'1': 'limit', '3': 1, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `JsonItemsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List jsonItemsRequestDescriptor = $convert.base64Decode(
    'ChBKc29uSXRlbXNSZXF1ZXN0EhQKBWxpbWl0GAEgASgFUgVsaW1pdA==');

@$core.Deprecated('Use jsonItemsResponseDescriptor instead')
const JsonItemsResponse$json = {
  '1': 'JsonItemsResponse',
  '2': [
    {'1': 'items', '3': 1, '4': 3, '5': 11, '6': '.benchmark.JsonItem', '10': 'items'},
    {'1': 'count', '3': 2, '4': 1, '5': 5, '10': 'count'},
    {'1': 'timestamp', '3': 3, '4': 1, '5': 9, '10': 'timestamp'},
  ],
};

/// Descriptor for `JsonItemsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List jsonItemsResponseDescriptor = $convert.base64Decode(
    'ChFKc29uSXRlbXNSZXNwb25zZRIpCgVpdGVtcxgBIAMoCzITLmJlbmNobWFyay5Kc29uSXRlbV'
    'IFaXRlbXMSFAoFY291bnQYAiABKAVSBWNvdW50EhwKCXRpbWVzdGFtcBgDIAEoCVIJdGltZXN0'
    'YW1w');

@$core.Deprecated('Use jsonItemDescriptor instead')
const JsonItem$json = {
  '1': 'JsonItem',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 5, '10': 'id'},
    {'1': 'uuid', '3': 2, '4': 1, '5': 9, '10': 'uuid'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'email', '3': 4, '4': 1, '5': 9, '10': 'email'},
    {'1': 'created_at', '3': 5, '4': 1, '5': 9, '10': 'createdAt'},
    {'1': 'is_active', '3': 6, '4': 1, '5': 8, '10': 'isActive'},
  ],
};

/// Descriptor for `JsonItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List jsonItemDescriptor = $convert.base64Decode(
    'CghKc29uSXRlbRIOCgJpZBgBIAEoBVICaWQSEgoEdXVpZBgCIAEoCVIEdXVpZBISCgRuYW1lGA'
    'MgASgJUgRuYW1lEhQKBWVtYWlsGAQgASgJUgVlbWFpbBIdCgpjcmVhdGVkX2F0GAUgASgJUglj'
    'cmVhdGVkQXQSGwoJaXNfYWN0aXZlGAYgASgIUghpc0FjdGl2ZQ==');

@$core.Deprecated('Use getUserRequestDescriptor instead')
const GetUserRequest$json = {
  '1': 'GetUserRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 5, '10': 'id'},
  ],
};

/// Descriptor for `GetUserRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getUserRequestDescriptor = $convert.base64Decode(
    'Cg5HZXRVc2VyUmVxdWVzdBIOCgJpZBgBIAEoBVICaWQ=');

@$core.Deprecated('Use userResponseDescriptor instead')
const UserResponse$json = {
  '1': 'UserResponse',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 5, '10': 'id'},
    {'1': 'email', '3': 2, '4': 1, '5': 9, '10': 'email'},
    {'1': 'first_name', '3': 3, '4': 1, '5': 9, '10': 'firstName'},
    {'1': 'last_name', '3': 4, '4': 1, '5': 9, '10': 'lastName'},
    {'1': 'age', '3': 5, '4': 1, '5': 5, '10': 'age'},
    {'1': 'created_at', '3': 6, '4': 1, '5': 9, '10': 'createdAt'},
  ],
};

/// Descriptor for `UserResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userResponseDescriptor = $convert.base64Decode(
    'CgxVc2VyUmVzcG9uc2USDgoCaWQYASABKAVSAmlkEhQKBWVtYWlsGAIgASgJUgVlbWFpbBIdCg'
    'pmaXJzdF9uYW1lGAMgASgJUglmaXJzdE5hbWUSGwoJbGFzdF9uYW1lGAQgASgJUghsYXN0TmFt'
    'ZRIQCgNhZ2UYBSABKAVSA2FnZRIdCgpjcmVhdGVkX2F0GAYgASgJUgljcmVhdGVkQXQ=');

@$core.Deprecated('Use complexOrdersRequestDescriptor instead')
const ComplexOrdersRequest$json = {
  '1': 'ComplexOrdersRequest',
  '2': [
    {'1': 'days', '3': 1, '4': 1, '5': 5, '10': 'days'},
  ],
};

/// Descriptor for `ComplexOrdersRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List complexOrdersRequestDescriptor = $convert.base64Decode(
    'ChRDb21wbGV4T3JkZXJzUmVxdWVzdBISCgRkYXlzGAEgASgFUgRkYXlz');

@$core.Deprecated('Use complexOrdersResponseDescriptor instead')
const ComplexOrdersResponse$json = {
  '1': 'ComplexOrdersResponse',
  '2': [
    {'1': 'period_days', '3': 1, '4': 1, '5': 5, '10': 'periodDays'},
    {'1': 'total_users', '3': 2, '4': 1, '5': 5, '10': 'totalUsers'},
    {'1': 'data', '3': 3, '4': 3, '5': 11, '6': '.benchmark.UserOrderStats', '10': 'data'},
  ],
};

/// Descriptor for `ComplexOrdersResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List complexOrdersResponseDescriptor = $convert.base64Decode(
    'ChVDb21wbGV4T3JkZXJzUmVzcG9uc2USHwoLcGVyaW9kX2RheXMYASABKAVSCnBlcmlvZERheX'
    'MSHwoLdG90YWxfdXNlcnMYAiABKAVSCnRvdGFsVXNlcnMSLQoEZGF0YRgDIAMoCzIZLmJlbmNo'
    'bWFyay5Vc2VyT3JkZXJTdGF0c1IEZGF0YQ==');

@$core.Deprecated('Use userOrderStatsDescriptor instead')
const UserOrderStats$json = {
  '1': 'UserOrderStats',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 5, '10': 'userId'},
    {'1': 'user_name', '3': 2, '4': 1, '5': 9, '10': 'userName'},
    {'1': 'total_orders', '3': 3, '4': 1, '5': 5, '10': 'totalOrders'},
    {'1': 'total_value', '3': 4, '4': 1, '5': 1, '10': 'totalValue'},
    {'1': 'average_order_value', '3': 5, '4': 1, '5': 1, '10': 'averageOrderValue'},
  ],
};

/// Descriptor for `UserOrderStats`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userOrderStatsDescriptor = $convert.base64Decode(
    'Cg5Vc2VyT3JkZXJTdGF0cxIXCgd1c2VyX2lkGAEgASgFUgZ1c2VySWQSGwoJdXNlcl9uYW1lGA'
    'IgASgJUgh1c2VyTmFtZRIhCgx0b3RhbF9vcmRlcnMYAyABKAVSC3RvdGFsT3JkZXJzEh8KC3Rv'
    'dGFsX3ZhbHVlGAQgASgBUgp0b3RhbFZhbHVlEi4KE2F2ZXJhZ2Vfb3JkZXJfdmFsdWUYBSABKA'
    'FSEWF2ZXJhZ2VPcmRlclZhbHVl');

@$core.Deprecated('Use cacheRequestDescriptor instead')
const CacheRequest$json = {
  '1': 'CacheRequest',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
  ],
};

/// Descriptor for `CacheRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cacheRequestDescriptor = $convert.base64Decode(
    'CgxDYWNoZVJlcXVlc3QSEAoDa2V5GAEgASgJUgNrZXk=');

@$core.Deprecated('Use cacheResponseDescriptor instead')
const CacheResponse$json = {
  '1': 'CacheResponse',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
    {'1': 'cached', '3': 3, '4': 1, '5': 8, '10': 'cached'},
    {'1': 'ttl', '3': 4, '4': 1, '5': 5, '10': 'ttl'},
    {'1': 'timestamp', '3': 5, '4': 1, '5': 9, '10': 'timestamp'},
  ],
};

/// Descriptor for `CacheResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cacheResponseDescriptor = $convert.base64Decode(
    'Cg1DYWNoZVJlc3BvbnNlEhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZR'
    'IWCgZjYWNoZWQYAyABKAhSBmNhY2hlZBIQCgN0dGwYBCABKAVSA3R0bBIcCgl0aW1lc3RhbXAY'
    'BSABKAlSCXRpbWVzdGFtcA==');

