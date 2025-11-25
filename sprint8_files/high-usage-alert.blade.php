<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            margin: 0;
            padding: 0;
            background-color: #f3f4f6;
        }
        .container {
            max-width: 600px;
            margin: 20px auto;
            background: white;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
        }
        .header {
            background: #dc2626;
            color: white;
            padding: 30px 20px;
            text-align: center;
        }
        .header h1 {
            margin: 0;
            font-size: 24px;
        }
        .content {
            padding: 30px 20px;
        }
        .info-row {
            margin: 15px 0;
            padding: 10px;
            background: #f9fafb;
            border-radius: 4px;
        }
        .metric {
            margin: 15px 0;
            padding: 15px;
            background: white;
            border-left: 4px solid #dc2626;
            border-radius: 4px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        }
        .metric strong {
            display: block;
            margin-bottom: 5px;
            color: #6b7280;
            font-size: 14px;
        }
        .high {
            color: #dc2626;
            font-weight: bold;
            font-size: 24px;
        }
        .btn {
            display: inline-block;
            padding: 12px 24px;
            background: #2563eb;
            color: white;
            text-decoration: none;
            border-radius: 6px;
            margin-top: 20px;
            font-weight: 600;
        }
        .btn:hover {
            background: #1d4ed8;
        }
        .footer {
            text-align: center;
            padding: 20px;
            background: #f9fafb;
            border-top: 1px solid #e5e7eb;
            font-size: 12px;
            color: #6b7280;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚨 High Resource Usage Alert</h1>
        </div>
        
        <div class="content">
            <div class="info-row">
                <strong>Server:</strong> {{ $alertData['server'] }}
            </div>
            <div class="info-row">
                <strong>Time:</strong> {{ $alertData['timestamp'] }}
            </div>
            
            <p style="margin-top: 20px; font-size: 16px;">
                The following resource usage metrics have <strong style="color: #dc2626;">exceeded the 90% threshold</strong>:
            </p>
            
            @if($alertData['cpu'] >= 90)
            <div class="metric">
                <strong>CPU Usage</strong>
                <span class="high">{{ number_format($alertData['cpu'], 2) }}%</span>
            </div>
            @endif
            
            @if($alertData['memory'] >= 90)
            <div class="metric">
                <strong>Memory Usage</strong>
                <span class="high">{{ number_format($alertData['memory'], 2) }}%</span>
            </div>
            @endif
            
            @if($alertData['disk'] >= 90)
            <div class="metric">
                <strong>Disk Usage</strong>
                <span class="high">{{ number_format($alertData['disk'], 2) }}%</span>
            </div>
            @endif
            
            <p style="margin-top: 30px; font-size: 14px; color: #6b7280;">
                Please log in to the admin panel to investigate and take necessary actions to prevent service disruption.
            </p>
            
            <div style="text-align: center;">
                <a href="https://72.61.53.222/admin" class="btn">
                    Access Admin Panel →
                </a>
            </div>
        </div>
        
        <div class="footer">
            <p>This is an automated alert from VPS Admin Panel</p>
            <p style="margin-top: 5px;">Server: 72.61.53.222</p>
        </div>
    </div>
</body>
</html>
