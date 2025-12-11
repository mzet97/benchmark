/**
 * Complex Query Result Model
 */

export interface ComplexOrderResult {
  user_id: number;
  user_email: string;
  total_orders: number;
  total_value: number;
  average_value: number;
  days_since_first_order: number;
}

export interface ComplexOrderResponse {
  period_days: number;
  total_users: number;
  data: ComplexOrderResult[];
  timestamp: string;
}
