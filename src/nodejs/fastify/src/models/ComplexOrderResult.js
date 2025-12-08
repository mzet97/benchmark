import { z } from 'zod';

// ComplexOrderResult model schema
export const ComplexOrderResultSchema = z.object({
  user_id: z.number(),
  email: z.string(),
  order_count: z.number(),
  total_amount: z.number(),
  avg_amount: z.number(),
  days_since_first_order: z.number()
});

// Create ComplexOrderResult from database row
export function createComplexOrderResult(row) {
  return {
    user_id: row.user_id,
    email: row.email,
    order_count: parseInt(row.order_count),
    total_amount: parseFloat(row.total_amount),
    avg_amount: parseFloat(row.avg_amount),
    days_since_first_order: parseInt(row.days_since_first_order)
  };
}

// Validation function
export function validateComplexOrderResult(data) {
  return ComplexOrderResultSchema.parse(data);
}
