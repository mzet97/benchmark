import { z } from 'zod';

// Order model schema
export const OrderSchema = z.object({
  id: z.number(),
  user_id: z.number(),
  total_amount: z.number(),
  status: z.string(),
  created_at: z.string()
});

// OrderItem model schema
export const OrderItemSchema = z.object({
  id: z.number(),
  order_id: z.number(),
  product_name: z.string(),
  quantity: z.number(),
  price: z.number(),
  created_at: z.string()
});

// Create Order from database row
export function createOrder(row) {
  return {
    id: row.id,
    user_id: row.user_id,
    total_amount: row.total_amount,
    status: row.status,
    created_at: row.created_at
  };
}

// Create OrderItem from database row
export function createOrderItem(row) {
  return {
    id: row.id,
    order_id: row.order_id,
    product_name: row.product_name,
    quantity: row.quantity,
    price: row.price,
    created_at: row.created_at
  };
}
