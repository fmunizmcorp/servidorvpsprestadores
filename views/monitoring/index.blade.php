<x-app-layout>
    <x-slot name="header"><h2 class="font-semibold text-xl text-gray-800 leading-tight">System Monitoring</h2></x-slot>
    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-6">
                <div class="bg-white p-6 rounded-lg shadow"><h3 class="text-gray-500">CPU Usage</h3><p class="text-3xl font-bold text-blue-600">{{ $metrics['cpu'] }}%</p></div>
                <div class="bg-white p-6 rounded-lg shadow"><h3 class="text-gray-500">Memory</h3><p class="text-3xl font-bold text-green-600">{{ $metrics['memory'] }}%</p></div>
                <div class="bg-white p-6 rounded-lg shadow"><h3 class="text-gray-500">Disk</h3><p class="text-3xl font-bold text-yellow-600">{{ $metrics['disk'] }}%</p></div>
                <div class="bg-white p-6 rounded-lg shadow"><h3 class="text-gray-500">Uptime</h3><p class="text-2xl font-bold">{{ $metrics['uptime'] }}</p></div>
            </div>
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg mb-6">
                <div class="p-6"><h3 class="text-lg font-semibold mb-4">Services Status</h3>
                    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                        @foreach ($services as $service)
                        <div class="flex justify-between items-center border rounded p-3">
                            <span class="font-medium">{{ $service['name'] }}</span>
                            <span class="px-2 py-1 text-xs rounded {{ $service['active'] ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800' }}">{{ $service['active'] ? 'Active' : 'Inactive' }}</span>
                        </div>
                        @endforeach
                    </div>
                </div>
            </div>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                <a href="{{ route('monitoring.services') }}" class="bg-blue-500 hover:bg-blue-700 text-white p-6 rounded-lg text-center font-semibold">Detailed Services</a>
                <a href="{{ route('monitoring.processes') }}" class="bg-green-500 hover:bg-green-700 text-white p-6 rounded-lg text-center font-semibold">Top Processes</a>
                <a href="{{ route('monitoring.logs') }}" class="bg-yellow-500 hover:bg-yellow-700 text-white p-6 rounded-lg text-center font-semibold">System Logs</a>
            </div>
        </div>
    </div>
    <script>setTimeout(() => window.location.reload(), 30000);</script>
</x-app-layout>
