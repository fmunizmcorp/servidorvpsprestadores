<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('Spam Logs Viewer') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            
            <!-- Filter Section -->
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg mb-6">
                <div class="p-6">
                    <form method="GET" action="{{ route('email.spam-logs') }}" class="flex gap-4 items-end">
                        <div class="flex-1">
                            <label class="block text-sm font-medium text-gray-700 mb-2">
                                Filter Logs
                            </label>
                            <input type="text" 
                                   name="filter" 
                                   value="{{ $filter }}"
                                   placeholder="Search in logs..."
                                   class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                        </div>
                        
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-2">
                                Lines
                            </label>
                            <select name="lines" class="rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                                <option value="50" {{ $lines == 50 ? 'selected' : '' }}>50</option>
                                <option value="100" {{ $lines == 100 ? 'selected' : '' }}>100</option>
                                <option value="200" {{ $lines == 200 ? 'selected' : '' }}>200</option>
                                <option value="500" {{ $lines == 500 ? 'selected' : '' }}>500</option>
                            </select>
                        </div>
                        
                        <div class="flex gap-2">
                            <button type="submit" class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700">
                                Filter
                            </button>
                            <a href="{{ route('email.spam-logs') }}" class="px-4 py-2 bg-gray-300 text-gray-700 rounded-md hover:bg-gray-400">
                                Clear
                            </a>
                        </div>
                    </form>
                </div>
            </div>

            <!-- Stats Cards -->
            <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
                <div class="bg-white p-4 rounded-lg shadow-sm">
                    <div class="text-sm text-gray-600">Total Entries</div>
                    <div class="text-2xl font-bold text-gray-900">{{ count($logs) }}</div>
                </div>
                <div class="bg-white p-4 rounded-lg shadow-sm">
                    <div class="text-sm text-gray-600">High Severity</div>
                    <div class="text-2xl font-bold text-red-600">
                        {{ collect($logs)->where('severity', 'high')->count() }}
                    </div>
                </div>
                <div class="bg-white p-4 rounded-lg shadow-sm">
                    <div class="text-sm text-gray-600">Medium Severity</div>
                    <div class="text-2xl font-bold text-yellow-600">
                        {{ collect($logs)->where('severity', 'medium')->count() }}
                    </div>
                </div>
                <div class="bg-white p-4 rounded-lg shadow-sm">
                    <div class="text-sm text-gray-600">Low Severity</div>
                    <div class="text-2xl font-bold text-green-600">
                        {{ collect($logs)->where('severity', 'low')->count() }}
                    </div>
                </div>
            </div>

            <!-- Logs Table -->
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6">
                    <div class="flex justify-between items-center mb-4">
                        <h3 class="text-lg font-semibold text-gray-900">Spam & Rejected Emails</h3>
                        <form method="POST" action="{{ route('email.spam-logs.clear') }}" 
                              onsubmit="return confirm('Are you sure you want to clear all spam logs?')">
                            @csrf
                            <button type="submit" class="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700">
                                Clear Logs
                            </button>
                        </form>
                    </div>
                    
                    @if(count($logs) > 0)
                    <div class="overflow-x-auto">
                        <table class="min-w-full divide-y divide-gray-200">
                            <thead class="bg-gray-50">
                                <tr>
                                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Timestamp</th>
                                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Type</th>
                                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Severity</th>
                                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Message</th>
                                </tr>
                            </thead>
                            <tbody class="bg-white divide-y divide-gray-200">
                                @foreach($logs as $log)
                                <tr class="hover:bg-gray-50">
                                    <td class="px-4 py-3 text-sm text-gray-900 whitespace-nowrap">
                                        {{ $log['timestamp'] }}
                                    </td>
                                    <td class="px-4 py-3 text-sm whitespace-nowrap">
                                        <span class="px-2 py-1 text-xs rounded-full 
                                            {{ $log['type'] == 'SpamAssassin' ? 'bg-red-100 text-red-800' : '' }}
                                            {{ $log['type'] == 'Blacklist' ? 'bg-purple-100 text-purple-800' : '' }}
                                            {{ $log['type'] == 'Rejected' ? 'bg-orange-100 text-orange-800' : '' }}
                                            {{ $log['type'] == 'Blocked' ? 'bg-yellow-100 text-yellow-800' : '' }}
                                            {{ $log['type'] == 'Other' ? 'bg-gray-100 text-gray-800' : '' }}">
                                            {{ $log['type'] }}
                                        </span>
                                    </td>
                                    <td class="px-4 py-3 text-sm whitespace-nowrap">
                                        <span class="px-2 py-1 text-xs rounded-full
                                            {{ $log['severity'] == 'high' ? 'bg-red-100 text-red-800' : '' }}
                                            {{ $log['severity'] == 'medium' ? 'bg-yellow-100 text-yellow-800' : '' }}
                                            {{ $log['severity'] == 'low' ? 'bg-green-100 text-green-800' : '' }}">
                                            {{ ucfirst($log['severity']) }}
                                        </span>
                                    </td>
                                    <td class="px-4 py-3 text-sm text-gray-600">
                                        <div class="max-w-3xl overflow-hidden text-ellipsis">
                                            {{ $log['message'] }}
                                        </div>
                                    </td>
                                </tr>
                                @endforeach
                            </tbody>
                        </table>
                    </div>
                    @else
                    <div class="text-center py-8 text-gray-500">
                        <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
                        </svg>
                        <p class="mt-2">No spam logs found</p>
                    </div>
                    @endif
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
