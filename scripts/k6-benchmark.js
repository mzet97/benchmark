import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');

export const options = {
    stages: [
        { duration: __ENV.RAMP_UP || '10s', target: parseInt(__ENV.VUS) || 50 },
        { duration: __ENV.DURATION || '60s', target: parseInt(__ENV.VUS) || 50 },
        { duration: '5s', target: 0 },
    ],
    thresholds: {
        http_req_duration: ['p(95)<1000'],
        http_req_failed: ['rate<0.05'],
        errors: ['rate<0.05'],
    },
};

const BASE_URL = __ENV.BASE_URL || 'http://csharp-minimalapi.benchmark.svc.cluster.local';

// Test data
const endpoints = [
    { path: '/health', weight: 20 },
    { path: '/json', weight: 20 },
    { path: '/db/simple?id=1', weight: 20 },
    { path: '/db/complex?days=30', weight: 20 },
    { path: '/cache?key=test', weight: 20 },
];

function pickEndpoint() {
    const totalWeight = endpoints.reduce((sum, e) => sum + e.weight, 0);
    let random = Math.random() * totalWeight;

    for (const endpoint of endpoints) {
        random -= endpoint.weight;
        if (random <= 0) {
            return endpoint.path;
        }
    }
    return endpoints[0].path;
}

export default function() {
    const endpoint = pickEndpoint();
    const url = `${BASE_URL}${endpoint}`;

    const params = {
        tags: {
            endpoint: endpoint,
            name: 'benchmark-test',
        },
    };

    const response = http.get(url, params);

    const success = check(response, {
        'status is 200': (r) => r.status === 200,
        'response time < 500ms': (r) => r.timings.duration < 500,
        'response has body': (r) => r.body && r.body.length > 0,
    });

    errorRate.add(!success);

    // Sleep between requests
    sleep(1);
}

export function handleSummary(data) {
    return {
        'results/k6/summary.html': HTMLReport(data),
        'results/k6/summary.json': JSON.stringify(data),
    };
}

function HTMLReport(data) {
    return `
    <!DOCTYPE html>
    <html>
    <head>
        <title>K6 Benchmark Results</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; }
            table { border-collapse: collapse; width: 100%; margin: 20px 0; }
            th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
            th { background-color: #4CAF50; color: white; }
            .metric { background-color: #f2f2f2; padding: 10px; margin: 10px 0; }
        </style>
    </head>
    <body>
        <h1>K6 Benchmark Results</h1>

        <div class="metric">
            <h2>Summary</h2>
            <p><strong>Total Requests:</strong> ${data.root.group.duration}</p>
            <p><strong>Success Rate:</strong> ${(100 - data.root.metrics.http_req_failed.values.rate * 100).toFixed(2)}%</p>
            <p><strong>Avg Response Time:</strong> ${data.root.metrics.http_req_duration.values.avg.toFixed(2)}ms</p>
        </div>

        <h2>Metrics</h2>
        <table>
            <tr>
                <th>Metric</th>
                <th>Avg</th>
                <th>Min</th>
                <th>Max</th>
                <th>P(95)</th>
                <th>P(99)</th>
            </tr>
            <tr>
                <td>Response Time (ms)</td>
                <td>${data.root.metrics.http_req_duration.values.avg.toFixed(2)}</td>
                <td>${data.root.metrics.http_req_duration.values.min.toFixed(2)}</td>
                <td>${data.root.metrics.http_req_duration.values.max.toFixed(2)}</td>
                <td>${data.root.metrics.http_req_duration.values['p(95)'].toFixed(2)}</td>
                <td>${data.root.metrics.http_req_duration.values['p(99)'].toFixed(2)}</td>
            </tr>
            <tr>
                <td>Requests/sec</td>
                <td>${data.root.metrics.http_reqs.values.rate.toFixed(2)}</td>
                <td>-</td>
                <td>-</td>
                <td>-</td>
                <td>-</td>
            </tr>
        </table>
    </body>
    </html>
    `;
}
