<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('Email Logs') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <!-- Log Filter -->
            <div class="mb-6">
                <form method="GET" class="flex gap-4">
                    <select name="type" class="rounded-md border-gray-300" onchange="this.form.submit()">
                        <option value="all" {{ $logType == 'all' ? 'selected' : '' }}>All Logs</option>
                        <option value="sent" {{ $logType == 'sent' ? 'selected' : '' }}>Sent Mail</option>
                        <option value="received" {{ $logType == 'received' ? 'selected' : '' }}>Received Mail</option>
                        <option value="errors" {{ $logType == 'errors' ? 'selected' : '' }}>Errors Only</option>
                        <option value="bounces" {{ $logType == 'bounces' ? 'selected' : '' }}>Bounces</option>
                    </select>
                    <select name="lines" class="rounded-md border-gray-300" onchange="this.form.submit()">
                        <option value="50" {{ $lines == 50 ? 'selected' : '' }}>Last 50 lines</option>
                        <option value="100" {{ $lines == 100 ? 'selected' : '' }}>Last 100 lines</option>
                        <option value="200" {{ $lines == 200 ? 'selected' : '' }}>Last 200 lines</option>
                        <option value="500" {{ $lines == 500 ? 'selected' : '' }}>Last 500 lines</option>
                    </select>
                    <input type="text" name="search" placeholder="Search..." 
                           value="{{ request('search') }}"
                           class="rounded-md border-gray-300">
                    <button type="submit" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
                        Filter
                    </button>
                </form>
            </div>

            <!-- Logs Display -->
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg mb-6">
                <div class="p-6">
                    <h3 class="text-lg font-semibold mb-4">
                        {{ ucfirst($logType) }} Mail Logs
                        <span class="text-sm text-gray-500">(Last {{ $lines }} lines)</span>
                    </h3>
                    <div class="bg-gray-900 text-gray-100 p-4 rounded font-mono text-xs overflow-x-auto" 
                         style="max-height: 600px; overflow-y: scroll;">
                        @if (!empty($logs))
                            @foreach ($logs as $log)
                                <div class="hover:bg-gray-800 py-1">
                                    <span class="text-gray-500">{{ $log['timestamp'] ?? '' }}</span>
                                    <span class="text-blue-400">{{ $log['process'] ?? '' }}</span>
                                    <span class="{{ $log['level'] == 'error' ? 'text-red-400' : ($log['level'] == 'warning' ? 'text-yellow-400' : 'text-gray-300') }}">
                                        {{ $log['message'] }}
                                    </span>
                                </div>
                            @endforeach
                        @else
                            <div class="text-gray-500">No logs found matching the current filter.</div>
                        @endif
                    </div>
                </div>
            </div>

            <!-- Statistics -->
            @if (!empty($stats))
            <div class="grid grid-cols-1 md:grid-cols-5 gap-4">
                <div class="bg-white p-4 rounded-lg shadow">
                    <h3 class="text-sm text-gray-500">Total Messages</h3>
                    <p class="text-2xl font-bold">{{ $stats['total'] }}</p>
                </div>
                <div class="bg-white p-4 rounded-lg shadow">
                    <h3 class="text-sm text-gray-500">Sent</h3>
                    <p class="text-2xl font-bold text-green-600">{{ $stats['sent'] }}</p>
                </div>
                <div class="bg-white p-4 rounded-lg shadow">
                    <h3 class="text-sm text-gray-500">Received</h3>
                    <p class="text-2xl font-bold text-blue-600">{{ $stats['received'] }}</p>
                </div>
                <div class="bg-white p-4 rounded-lg shadow">
                    <h3 class="text-sm text-gray-500">Bounced</h3>
                    <p class="text-2xl font-bold text-yellow-600">{{ $stats['bounced'] }}</p>
                </div>
                <div class="bg-white p-4 rounded-lg shadow">
                    <h3 class="text-sm text-gray-500">Errors</h3>
                    <p class="text-2xl font-bold text-red-600">{{ $stats['errors'] }}</p>
                </div>
            </div>
            @endif

            <!-- Log Analysis Tips -->
            <div class="mt-6 bg-blue-50 border-l-4 border-blue-400 p-4">
                <div class="flex">
                    <div class="ml-3">
                        <h3 class="text-sm font-medium text-blue-800">Log Analysis Tips</h3>
                        <div class="mt-2 text-sm text-blue-700">
                            <ul class="list-disc list-inside">
                                <li><strong>status=sent:</strong> Message delivered successfully</li>
                                <li><strong>status=deferred:</strong> Temporary failure, will retry</li>
                                <li><strong>status=bounced:</strong> Permanent failure, recipient invalid</li>
                                <li><strong>NOQUEUE:</strong> Message rejected before queuing (usually spam)</li>
                                <li><strong>relay=none:</strong> No mail server found for destination</li>
                                <li><strong>Connection refused:</strong> Destination server not accepting mail</li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
