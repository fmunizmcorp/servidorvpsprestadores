<x-app-layout>
    <x-slot name="header"><h2 class="font-semibold text-xl text-gray-800 leading-tight">Firewall Management (UFW)</h2></x-slot>
    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            @if (session('success'))<div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4">{{ session('success') }}</div>@endif
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg mb-6">
                <div class="p-6">
                    <h3 class="text-lg font-semibold mb-4">Current Rules</h3>
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50"><tr>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">#</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">To</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Action</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">From</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Delete</th>
                        </tr></thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            @foreach ($rules as $rule)
                            <tr><td class="px-6 py-4 whitespace-nowrap text-sm">{{ $rule['number'] }}</td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm font-mono">{{ $rule['to'] }}</td>
                                <td class="px-6 py-4 whitespace-nowrap"><span class="px-2 py-1 text-xs rounded {{ $rule['action'] == 'ALLOW' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800' }}">{{ $rule['action'] }}</span></td>
                                <td class="px-6 py-4 whitespace-nowrap text-sm font-mono">{{ $rule['from'] }}</td>
                                <td class="px-6 py-4 whitespace-nowrap"><form method="POST" action="{{ route('security.deleteRule') }}" class="inline">@csrf @method('DELETE')<input type="hidden" name="number" value="{{ $rule['number'] }}"><button type="submit" class="text-red-600 hover:text-red-900">Delete</button></form></td>
                            </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6">
                    <h3 class="text-lg font-semibold mb-4">Add New Rule</h3>
                    <form method="POST" action="{{ route('security.addRule') }}" class="flex gap-4">
                        @csrf
                        <select name="action" class="rounded-md border-gray-300"><option value="allow">Allow</option><option value="deny">Deny</option></select>
                        <input type="text" name="port" placeholder="Port (e.g., 80)" class="rounded-md border-gray-300">
                        <input type="text" name="from" placeholder="From IP (optional)" class="rounded-md border-gray-300">
                        <button type="submit" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">Add Rule</button>
                    </form>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
