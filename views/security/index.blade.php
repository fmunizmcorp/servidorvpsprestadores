<x-app-layout>
    <x-slot name="header"><h2 class="font-semibold text-xl text-gray-800 leading-tight">Security Dashboard</h2></x-slot>
    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
                <div class="bg-white p-6 rounded-lg shadow"><h3 class="text-gray-500">Active Rules</h3><p class="text-3xl font-bold text-green-600">{{ $stats['activeRules'] }}</p></div>
                <div class="bg-white p-6 rounded-lg shadow"><h3 class="text-gray-500">Banned IPs</h3><p class="text-3xl font-bold text-red-600">{{ $stats['bannedIPs'] }}</p></div>
                <div class="bg-white p-6 rounded-lg shadow"><h3 class="text-gray-500">Last Scan</h3><p class="text-2xl font-bold">{{ $stats['lastScan'] }}</p></div>
            </div>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                <a href="{{ route('security.firewall') }}" class="bg-blue-500 hover:bg-blue-700 text-white p-6 rounded-lg text-center font-semibold">Firewall (UFW)</a>
                <a href="{{ route('security.fail2ban') }}" class="bg-red-500 hover:bg-red-700 text-white p-6 rounded-lg text-center font-semibold">Fail2Ban</a>
                <a href="{{ route('security.clamav') }}" class="bg-green-500 hover:bg-green-700 text-white p-6 rounded-lg text-center font-semibold">ClamAV</a>
            </div>
        </div>
    </div>
</x-app-layout>
