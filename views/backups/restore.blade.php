<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">Restore Backup</h2>
    </x-slot>
    <div class="py-12">
        <div class="max-w-4xl mx-auto sm:px-6 lg:px-8">
            @if (session('success'))
                <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4">{{ session('success') }}</div>
            @endif
            @if (session('error'))
                <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">{{ session('error') }}</div>
            @endif
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6">
                    <h3 class="text-lg font-semibold mb-4">Select Backup to Restore</h3>
                    <form method="POST" action="{{ route('backups.executeRestore') }}">
                        @csrf
                        <div class="mb-4">
                            <label class="block text-sm font-medium text-gray-700 mb-2">Backup Snapshot</label>
                            <select name="snapshot" required class="w-full rounded-md border-gray-300">
                                <option value="">Select a snapshot...</option>
                                @foreach($backups as $backup)
                                    <option value="{{ $backup['id'] }}" {{ request('snapshot') == $backup['id'] ? 'selected' : '' }}>
                                        {{ $backup['time'] }} - {{ $backup['type'] }} ({{ $backup['size'] }})
                                    </option>
                                @endforeach
                            </select>
                        </div>
                        <div class="mb-4">
                            <label class="block text-sm font-medium text-gray-700 mb-2">Restore Options</label>
                            <div class="space-y-2">
                                <label class="flex items-center"><input type="checkbox" name="restore_sites" checked class="mr-2"> Restore Sites</label>
                                <label class="flex items-center"><input type="checkbox" name="restore_databases" checked class="mr-2"> Restore Databases</label>
                                <label class="flex items-center"><input type="checkbox" name="restore_email" checked class="mr-2"> Restore Email</label>
                                <label class="flex items-center"><input type="checkbox" name="restore_configs" class="mr-2"> Restore Configs</label>
                            </div>
                        </div>
                        <div class="mb-4">
                            <label class="block text-sm font-medium text-gray-700 mb-2">Restore To</label>
                            <input type="text" name="restore_path" value="/opt/webserver" class="w-full rounded-md border-gray-300" placeholder="/opt/webserver">
                        </div>
                        <div class="bg-red-50 p-4 rounded mb-4">
                            <p class="text-sm text-red-800"><strong>Warning:</strong> This will overwrite existing files! Make sure you have a backup before proceeding.</p>
                        </div>
                        <button type="submit" class="bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded" onclick="return confirm('Are you sure? This will overwrite current data!')">
                            Start Restore
                        </button>
                    </form>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
