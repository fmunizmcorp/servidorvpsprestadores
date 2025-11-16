<x-app-layout>
    <x-slot name="header"><h2 class="font-semibold text-xl text-gray-800 leading-tight">ClamAV Antivirus</h2></x-slot>
    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
                <div class="bg-white p-6 rounded-lg shadow"><h3 class="text-gray-500">Virus Definitions</h3><p class="text-3xl font-bold">{{ $status['signatures'] }}</p></div>
                <div class="bg-white p-6 rounded-lg shadow"><h3 class="text-gray-500">Last Update</h3><p class="text-2xl font-bold">{{ $status['lastUpdate'] }}</p></div>
                <div class="bg-white p-6 rounded-lg shadow"><h3 class="text-gray-500">Version</h3><p class="text-2xl font-bold">{{ $status['version'] }}</p></div>
            </div>
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6">
                    <h3 class="text-lg font-semibold mb-4">Manual Scan</h3>
                    <form method="POST" action="{{ route('security.scan') }}">@csrf
                        <div class="mb-4"><label class="block text-sm font-medium text-gray-700 mb-2">Scan Path</label><input type="text" name="path" value="/opt/webserver" class="w-full rounded-md border-gray-300"></div>
                        <button type="submit" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">Start Scan</button>
                    </form>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
