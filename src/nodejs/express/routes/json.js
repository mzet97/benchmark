export async function jsonHandler(req, res) {
  const items = [];
  for (let i = 0; i < 1000; i++) {
    items.push({
      id: i,
      name: `User ${i}`,
      email: `user${i}@example.com`,
      active: true,
      tags: ['benchmark', 'test', 'api']
    });
  }

  res.json({
    items,
    count: items.length,
    timestamp: new Date().toISOString()
  });
}
