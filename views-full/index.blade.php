<x-app-layout>
    <x-slot name="header">
        <div class="flex justify-between items-center">
            <h2 class="font-semibold text-xl text-gray-800 leading-tight">
                {{ __('Backup Management') }}
            </h2>
            <button onclick="document.getElementById('triggerBackupModal').classList.remove('hidden')" 
                    class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
                Trigger Backup
            </button>
        </div>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            @if (session('success'))
                <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded relative mb-4">
                    {{ session('success') }}
                </div>
            @endif

            <!-- Backup Statistics -->
            <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-6">
                <div class="bg-white p-6 rounded-lg shadow">
                    <h3 class="text-gray-500 text-sm">Total Backups</h3>
                    <p class="text-3xl font-bold">{{ $stats['totalBackups'] }}</p>
                </div>
                <div class="bg-white p-6 rounded-lg shadow">
                    <h3 class="text-gray-500 text-sm">Total Size</h3>
                    <p class="text-3xl font-bold text-blue-600">{{ $stats['totalSize'] }}</p>
                </div>
                <div class="bg-white p-6 rounded-lg shadow">
                    <h3 class="text-gray-500 text-sm">Last Backup</h3>
                    <p class="text-2xl font-bold text-green-600">{{ $stats['lastBackup'] }}</p>
                </div>
                <div class="bg-white p-6 rounded-lg shadow">
                    <h3 class="text-gray-500 text-sm">Next Scheduled</h3>
                    <p class="text-2xl font-bold text-yellow-600">{{ $stats['nextScheduled'] }}</p>
                </div>
            </div>

            <!-- Recent Backups -->
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 bg-white border-b border-gray-200">
                    <h3 class="text-lg font-semibold mb-4">Recent Backups</h3>
                    <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-gray-50">
                            <tr>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Snapshot ID</th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Time</th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Type</th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Size</th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Duration</th>
                                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
                            </tr>
                        </thead>
                        <tbody class="bg-white divide-y divide-gray-200">
                            @forelse ($recentBackups as $backup)
                                <tr>
                                    <td class="px-6 py-4 whitespace-nowrap text-sm font-mono text-gray-900">
                                        {{ substr($backup['id'], 0, 8) }}...
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                        {{ $backup['time'] }}
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        @if ($backup['type'] == 'full')
                                            <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-blue-100 text-blue-800">
                                                Full
                                            </span>
                                        @elseif ($backup['type'] == 'sites')
                                            <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">
                                                Sites
                                            </span>
                                        @else
                                            <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-yellow-100 text-yellow-800">
                                                Email
                                            </span>
                                        @endif
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                        {{ $backup['size'] }}
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                        {{ $backup['duration'] }}
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                        <a href="{{ route('backups.restore') }}?snapshot={{ $backup['id'] }}" 
                                           class="text-green-600 hover:text-green-900 mr-3">
                                            Restore
                                        </a>
                                        <button onclick="showBackupDetails('{{ $backup['id'] }}')" 
                                                class="text-indigo-600 hover:text-indigo-900 mr-3">
                                            Details
                                        </button>
                                        <form action="{{ route('backups.delete', $backup['id']) }}" method="POST" class="inline">
                                            @csrf
                                            @method('DELETE')
                                            <button type="submit" class="text-red-600 hover:text-red-900"
                                                    onclick="return confirm('Delete this backup?')">
                                                Delete
                                            </button>
                                        </form>
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="6" class="px-6 py-4 text-center text-sm text-gray-500">
                                        <div class="flex flex-col items-center justify-center py-8">
                                            <svg class="h-12 w-12 text-gray-400 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4"></path>
                                            </svg>
                                            <p class="text-lg font-medium">No backups yet</p>
                                            <p class="text-sm text-gray-400 mt-1">Create your first backup to protect your data!</p>
                                        </div>
                                    </td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- Backup Schedule -->
            <div class="mt-6 bg-blue-50 border-l-4 border-blue-400 p-4">
                <div class="flex">
                    <div class="ml-3">
                        <h3 class="text-sm font-medium text-blue-800">Automated Backup Schedule</h3>
                        <div class="mt-2 text-sm text-blue-700">
                            <ul class="list-disc list-inside">
                                <li><strong>Daily:</strong> Full backup at 2:00 AM</li>
                                <li><strong>Retention:</strong> Keep last 30 daily backups</li>
                                <li><strong>Location:</strong> /opt/webserver/backups/restic-repo</li>
                                <li><strong>What's backed up:</strong> Sites, databases, email, configs</li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Quick Actions -->
            <div class="mt-6 grid grid-cols-1 md:grid-cols-3 gap-4">
                <a href="{{ route('backups.list') }}?type=full" 
                   class="bg-blue-500 hover:bg-blue-700 text-white p-6 rounded-lg text-center">
                    <svg class="h-8 w-8 mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 19a2 2 0 01-2-2V7a2 2 0 012-2h4l2 2h4a2 2 0 012 2v1M5 19h14a2 2 0 002-2v-5a2 2 0 00-2-2H9a2 2 0 00-2 2v5a2 2 0 01-2 2z"></path>
                    </svg>
                    View All Full Backups
                </a>
                <a href="{{ route('backups.restore') }}" 
                   class="bg-green-500 hover:bg-green-700 text-white p-6 rounded-lg text-center">
                    <svg class="h-8 w-8 mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
                    </svg>
                    Restore Backup
                </a>
                <a href="{{ route('backups.logs') }}" 
                   class="bg-yellow-500 hover:bg-yellow-700 text-white p-6 rounded-lg text-center">
                    <svg class="h-8 w-8 mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
                    </svg>
                    View Backup Logs
                </a>
            </div>
        </div>
    </div>

    <!-- Trigger Backup Modal -->
    <div id="triggerBackupModal" class="hidden fixed z-10 inset-0 overflow-y-auto">
        <div class="flex items-center justify-center min-h-screen px-4">
            <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"></div>
            <div class="bg-white rounded-lg overflow-hidden shadow-xl transform transition-all sm:max-w-lg sm:w-full z-20">
                <form method="POST" action="{{ route('backups.trigger') }}">
                    @csrf
                    <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                        <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">Trigger Manual Backup</h3>
                        
                        <div class="mb-4">
                            <label class="block text-sm font-medium text-gray-700 mb-2">Backup Type</label>
                            <div class="space-y-2">
                                <label class="flex items-center">
                                    <input type="radio" name="type" value="full" checked class="mr-2">
                                    <div>
                                        <span class="font-medium">Full Backup</span>
                                        <p class="text-sm text-gray-500">All sites, databases, email, and configurations</p>
                                    </div>
                                </label>
                                <label class="flex items-center">
                                    <input type="radio" name="type" value="sites" class="mr-2">
                                    <div>
                                        <span class="font-medium">Sites Only</span>
                                        <p class="text-sm text-gray-500">Website files and databases only</p>
                                    </div>
                                </label>
                                <label class="flex items-center">
                                    <input type="radio" name="type" value="email" class="mr-2">
                                    <div>
                                        <span class="font-medium">Email Only</span>
                                        <p class="text-sm text-gray-500">Email accounts and mailboxes only</p>
                                    </div>
                                </label>
                            </div>
                        </div>

                        <div class="bg-yellow-50 p-3 rounded">
                            <p class="text-sm text-yellow-800">
                                <strong>Note:</strong> Backup process may take several minutes depending on data size. 
                                The backup will run in the background.
                            </p>
                        </div>
                    </div>
                    <div class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
                        <button type="submit" class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-blue-600 text-base font-medium text-white hover:bg-blue-700 sm:ml-3 sm:w-auto sm:text-sm">
                            Start Backup
                        </button>
                        <button type="button" onclick="document.getElementById('triggerBackupModal').classList.add('hidden')"
                                class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm">
                            Cancel
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Backup Details Modal -->
    <div id="detailsModal" class="hidden fixed z-10 inset-0 overflow-y-auto">
        <div class="flex items-center justify-center min-h-screen px-4">
            <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"></div>
            <div class="bg-white rounded-lg overflow-hidden shadow-xl transform transition-all sm:max-w-2xl sm:w-full z-20">
                <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                    <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">Backup Details</h3>
                    <div id="detailsContent" class="bg-gray-50 p-4 rounded font-mono text-sm overflow-auto max-h-96">
                        Loading...
                    </div>
                </div>
                <div class="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
                    <button type="button" onclick="document.getElementById('detailsModal').classList.add('hidden')"
                            class="w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 sm:w-auto sm:text-sm">
                        Close
                    </button>
                </div>
            </div>
        </div>
    </div>

    <script>
    function showBackupDetails(snapshotId) {
        document.getElementById('detailsModal').classList.remove('hidden');
        fetch(`{{ route('backups.details') }}?snapshot=${snapshotId}`)
            .then(response => response.json())
            .then(data => {
                document.getElementById('detailsContent').innerHTML = `
                    <p><strong>Snapshot ID:</strong> ${data.id}</p>
                    <p><strong>Time:</strong> ${data.time}</p>
                    <p><strong>Hostname:</strong> ${data.hostname}</p>
                    <p><strong>Paths:</strong></p>
                    <ul class="list-disc list-inside ml-4">
                        ${data.paths.map(p => `<li>${p}</li>`).join('')}
                    </ul>
                    <p class="mt-2"><strong>Tags:</strong> ${data.tags.join(', ')}</p>
                `;
            })
            .catch(error => {
                document.getElementById('detailsContent').innerHTML = 'Error loading backup details';
            });
    }
    </script>
</x-app-layout>
