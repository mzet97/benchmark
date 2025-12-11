/**
 * User Model - Database entity
 */

export interface User {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  age: number;
  created_at: Date;
}

export interface UserDto {
  id: number;
  name: string;
  email: string;
  created_at: string;
  isActive: boolean;
}

export function mapUserToDto(user: User): UserDto {
  return {
    id: user.id,
    name: `${user.first_name} ${user.last_name}`,
    email: user.email,
    created_at: user.created_at.toISOString(),
    isActive: user.created_at > new Date(Date.now() - 365 * 24 * 60 * 60 * 1000),
  };
}
