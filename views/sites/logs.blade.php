<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('Site Logs') }}: {{ $siteName }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <!-- Log Type Selector -->
            <div class="mb-6">
                <form method="GET" class="flex gap-4">
                    <select name="type" class="rounded-md border-gray-300" onchange="this.form.submit()">
                        <option value="access" {{ $logType == 'access' ? 'selected' : '' }}>Access Log</option>
                        <option value="error" {{ $logType == 'error' ? 'selected' : '' }}>Error Log</option>
                        <option value="php-error" {{ $logType == 'php-error' ? 'selected' : '' }}>PHP Error Log</option>
                    </select>
                    <select name="lines" class="rounded-md border-gray-300" onchange="this.form.submit()">
                        <option value="50" {{ $lines == 50 ? 'selected' : '' }}>Last 50 lines</option>
                        <option value="100" {{ $lines == 100 ? 'selected' : '' }}>Last 100 lines</option>
                        <option value="200" {{ $lines == 200 ? 'selected' : '' }}>Last 200 lines</option>
                        <option value="500" {{ $lines == 500 ? 'selected' : '' }}>Last 500 lines</option>
                    </select>
                    <button type="submit" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
                        Refresh
                    </button>
                </form>
            </div>

            <!-- Logs Display -->
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6">
                    <h3 class="text-lg font-semibold mb-4">
                        {{ ucfirst(str_replace('-', ' ', $logType)) }} 
                        <span class="text-sm text-gray-500">(Last {{ $lines }} lines)</span>
                    </h3>
                    <div class="bg-gray-900 text-gray-100 p-4 rounded font-mono text-xs overflow-x-auto" style="max-height: 600px; overflow-y: scroll;">
                        @if (!empty($logs))
                            @foreach ($logs as $line)
                                <div class="hover:bg-gray-800">{{ $line }}</div>
                            @endforeach
                        @else
                            <div class="text-gray-500">No logs found or log file is empty.</div>
                        @endif
                    </div>
                </div>
            </div>

            <!-- Quick Stats (for access logs) -->
            @if ($logType == 'access' && !empty($logs))
                <div class="mt-6 grid grid-cols-1 md:grid-cols-4 gap-4">
                    <div class="bg-white p-4 rounded shadow">
                        <p class="text-sm text-gray-500">Total Requests</p>
                        <p class="text-2xl font-bold">{{ count($logs) }}</p>
                    </div>
                    <div class="bg-white p-4 rounded shadow">
                        <p class="text-sm text-gray-500">200 OK</p>
                        <p class="text-2xl font-bold text-green-600">
                            {{ count(array_filter($logs, fn($l) => str_contains($l, ' 200 '))) }}
                        </p>
                    </div>
                    <div class="bg-white p-4 rounded shadow">
                        <p class="text-sm text-gray-500">404 Not Found</p>
                        <p class="text-2xl font-bold text-yellow-600">
                            {{ count(array_filter($logs, fn($l) => str_contains($l, ' 404 '))) }}
                        </p>
                    </div>
                    <div class="bg-white p-4 rounded shadow">
                        <p class="text-sm text-gray-500">500 Errors</p>
                        <p class="text-2xl font-bold text-red-600">
                            {{ count(array_filter($logs, fn($l) => str_contains($l, ' 500 ') || str_contains($l, ' 502 ') || str_contains($l, ' 503 '))) }}
                        </p>
                    </div>
                </div>
            @endif

            <div class="mt-6">
                <a href="{{ route('sites.show', $siteName) }}" class="text-blue-600 hover:text-blue-900">← Back to Site</a>
            </div>
        </div>
    </div>
</x-app-layout>
