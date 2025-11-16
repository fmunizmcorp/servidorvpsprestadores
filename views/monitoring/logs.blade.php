<x-app-layout>
    <x-slot name="header"><h2 class="font-semibold text-xl text-gray-800 leading-tight">System Logs</h2></x-slot>
    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="mb-6">
                <form method="GET" class="flex gap-4">
                    <select name="type" class="rounded-md border-gray-300" onchange="this.form.submit()">
                        <option value="syslog" {{ $logType == 'syslog' ? 'selected' : '' }}>Syslog</option>
                        <option value="auth" {{ $logType == 'auth' ? 'selected' : '' }}>Auth</option>
                        <option value="nginx" {{ $logType == 'nginx' ? 'selected' : '' }}>NGINX</option>
                        <option value="php" {{ $logType == 'php' ? 'selected' : '' }}>PHP</option>
                        <option value="mail" {{ $logType == 'mail' ? 'selected' : '' }}>Mail</option>
                    </select>
                    <select name="lines" class="rounded-md border-gray-300" onchange="this.form.submit()">
                        <option value="50" {{ $lines == 50 ? 'selected' : '' }}>Last 50</option>
                        <option value="100" {{ $lines == 100 ? 'selected' : '' }}>Last 100</option>
                        <option value="200" {{ $lines == 200 ? 'selected' : '' }}>Last 200</option>
                    </select>
                    <button type="submit" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">Refresh</button>
                </form>
            </div>
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6"><h3 class="text-lg font-semibold mb-4">{{ ucfirst($logType) }} Logs</h3>
                    <div class="bg-gray-900 text-gray-100 p-4 rounded font-mono text-xs overflow-x-auto" style="max-height: 600px; overflow-y: scroll;">
                        @if (!empty($logs))@foreach ($logs as $line)<div class="hover:bg-gray-800">{{ $line }}</div>@endforeach @else<div class="text-gray-500">No logs found.</div>@endif
                    </div>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
