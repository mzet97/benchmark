import { z } from 'zod';

// Mirrors UserResponse in contracts/grpc/benchmark.proto. Wire names are
// camelCase. See contracts/rest/canonical-payloads.md.
export const UserSchema = z.object({
  id: z.number(),
  email: z.string().email(),
  firstName: z.string(),
  lastName: z.string(),
  age: z.number().nullable(),
  createdAt: z.string()
});

export function createUser(row) {
  return {
    id: row.id,
    email: row.email,
    firstName: row.firstName,
    lastName: row.lastName,
    age: row.age,
    createdAt: row.createdAt
  };
}

export function validateUser(data) {
  return UserSchema.parse(data);
}
