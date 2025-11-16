<x-app-layout>
    <x-slot name="header"><h2 class="font-semibold text-xl text-gray-800 leading-tight">Fail2Ban Management</h2></x-slot>
    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            @if (session('success'))<div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4">{{ session('success') }}</div>@endif
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg mb-6">
                <div class="p-6"><h3 class="text-lg font-semibold mb-4">Jail Status</h3>
                    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                        @foreach ($jails as $jail)
                        <div class="border rounded p-4"><h4 class="font-semibold">{{ $jail['name'] }}</h4>
                            <p class="text-sm text-gray-600">Currently Banned: <span class="font-bold text-red-600">{{ $jail['banned'] }}</span></p>
                            <p class="text-sm text-gray-600">Total Banned: <span class="font-bold">{{ $jail['total'] }}</span></p>
                        </div>
                        @endforeach
                    </div>
                </div>
            </div>
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6"><h3 class="text-lg font-semibold mb-4">Banned IPs</h3>
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50"><tr><th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">IP Address</th><th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Jail</th><th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th></tr></thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            @foreach ($bannedIps as $ban)
                            <tr><td class="px-6 py-4 whitespace-nowrap text-sm font-mono">{{ $ban['ip'] }}</td><td class="px-6 py-4 whitespace-nowrap text-sm">{{ $ban['jail'] }}</td>
                                <td class="px-6 py-4 whitespace-nowrap"><form method="POST" action="{{ route('security.unbanIP') }}" class="inline">@csrf<input type="hidden" name="ip" value="{{ $ban['ip'] }}"><input type="hidden" name="jail" value="{{ $ban['jail'] }}"><button type="submit" class="text-green-600 hover:text-green-900">Unban</button></form></td>
                            </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
