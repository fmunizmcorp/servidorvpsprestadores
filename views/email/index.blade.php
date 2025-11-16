<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">Email Management</h2>
    </x-slot>
    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-6">
                <div class="bg-white p-6 rounded-lg shadow"><h3 class="text-gray-500">Domains</h3><p class="text-3xl font-bold">{{ $stats['domains'] }}</p></div>
                <div class="bg-white p-6 rounded-lg shadow"><h3 class="text-gray-500">Accounts</h3><p class="text-3xl font-bold">{{ $stats['accounts'] }}</p></div>
                <div class="bg-white p-6 rounded-lg shadow"><h3 class="text-gray-500">Sent Today</h3><p class="text-3xl font-bold text-green-600">{{ $stats['sentToday'] }}</p></div>
                <div class="bg-white p-6 rounded-lg shadow"><h3 class="text-gray-500">Received Today</h3><p class="text-3xl font-bold text-blue-600">{{ $stats['receivedToday'] }}</p></div>
            </div>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                <a href="{{ route('email.domains') }}" class="bg-blue-500 hover:bg-blue-700 text-white p-6 rounded-lg text-center">Manage Domains</a>
                <a href="{{ route('email.accounts') }}" class="bg-green-500 hover:bg-green-700 text-white p-6 rounded-lg text-center">Manage Accounts</a>
                <a href="{{ route('email.queue') }}" class="bg-yellow-500 hover:bg-yellow-700 text-white p-6 rounded-lg text-center">Email Queue</a>
            </div>
        </div>
    </div>
</x-app-layout>
