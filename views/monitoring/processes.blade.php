<x-app-layout>
    <x-slot name="header"><h2 class="font-semibold text-xl text-gray-800 leading-tight">Top Processes</h2></x-slot>
    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6">
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50"><tr><th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">PID</th><th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">User</th><th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">CPU%</th><th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">MEM%</th><th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Command</th><th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th></tr></thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            @foreach ($processes as $proc)
                            <tr><td class="px-6 py-4 whitespace-nowrap text-sm">{{ $proc['pid'] }}</td><td class="px-6 py-4 whitespace-nowrap text-sm">{{ $proc['user'] }}</td><td class="px-6 py-4 whitespace-nowrap text-sm">{{ $proc['cpu'] }}%</td><td class="px-6 py-4 whitespace-nowrap text-sm">{{ $proc['mem'] }}%</td><td class="px-6 py-4 text-sm font-mono truncate max-w-xs">{{ $proc['command'] }}</td>
                                <td class="px-6 py-4 whitespace-nowrap"><form method="POST" action="{{ route('monitoring.killProcess') }}" class="inline">@csrf<input type="hidden" name="pid" value="{{ $proc['pid'] }}"><button type="submit" class="text-red-600 hover:text-red-900" onclick="return confirm('Kill process {{ $proc['pid'] }}?')">Kill</button></form></td>
                            </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
