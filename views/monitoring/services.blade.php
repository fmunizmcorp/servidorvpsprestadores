<x-app-layout>
    <x-slot name="header"><h2 class="font-semibold text-xl text-gray-800 leading-tight">Services Management</h2></x-slot>
    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            @if (session('success'))<div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4">{{ session('success') }}</div>@endif
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6">
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50"><tr><th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Service</th><th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th><th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Memory</th><th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th></tr></thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            @foreach ($services as $service)
                            <tr><td class="px-6 py-4 whitespace-nowrap text-sm font-medium">{{ $service['name'] }}</td>
                                <td class="px-6 py-4 whitespace-nowrap"><span class="px-2 py-1 text-xs rounded {{ $service['active'] ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800' }}">{{ $service['active'] ? 'Active' : 'Inactive' }}</span></td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm">{{ $service['memory'] }}</td>
                                <td class="px-6 py-4 whitespace-nowrap"><form method="POST" action="{{ route('monitoring.restartService') }}" class="inline">@csrf<input type="hidden" name="service" value="{{ $service['name'] }}"><button type="submit" class="text-blue-600 hover:text-blue-900">Restart</button></form></td>
                            </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
