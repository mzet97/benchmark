import { z } from 'zod';

// User model schema
export const UserSchema = z.object({
  id: z.number(),
  email: z.string().email(),
  first_name: z.string(),
  last_name: z.string(),
  age: z.number(),
  created_at: z.string()
});

// Create User from database row
export function createUser(row) {
  return {
    id: row.id,
    email: row.email,
    first_name: row.first_name,
    last_name: row.last_name,
    age: row.age,
    created_at: row.created_at
  };
}

// User response type
export const UserResponseSchema = z.object({
  user: UserSchema,
  timestamp: z.string()
});

export function validateUser(data) {
  return UserSchema.parse(data);
}
