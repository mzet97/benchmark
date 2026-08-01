import { z } from 'zod';

// Mirrors UserOrderStats in contracts/grpc/benchmark.proto. Wire names are
// camelCase. See contracts/rest/canonical-payloads.md.
export const ComplexOrderResultSchema = z.object({
  userId: z.number(),
  userName: z.string(),
  totalOrders: z.number(),
  totalValue: z.number(),
  averageOrderValue: z.number()
});

export function createComplexOrderResult(row) {
  return {
    userId: parseInt(row.userId),
    userName: row.userName,
    totalOrders: parseInt(row.totalOrders),
    totalValue: parseFloat(row.totalValue),
    averageOrderValue: parseFloat(row.averageOrderValue)
  };
}

export function validateComplexOrderResult(data) {
  return ComplexOrderResultSchema.parse(data);
}
