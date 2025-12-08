import { v4 as uuidv4 } from 'uuid';

// JSONItem model
export function createJsonItem(id) {
  return {
    id,
    name: `Item ${id}`,
    description: `This is item number ${id}`,
    timestamp: new Date().toISOString(),
    random: `data-${uuidv4()}`
  };
}

// Validation function
export function validateJsonItem(data) {
  return typeof data.id === 'number' &&
         typeof data.name === 'string' &&
         typeof data.description === 'string';
}
