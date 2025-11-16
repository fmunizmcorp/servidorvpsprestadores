<x-app-layout>
    <x-slot name="header">
        <div class="flex justify-between items-center">
            <h2 class="font-semibold text-xl text-gray-800 leading-tight">
                {{ __('Backup Details') }}
            </h2>
            <a href="{{ route('backups.list') }}" class="bg-gray-500 hover:bg-gray-700 text-white font-bold py-2 px-4 rounded">
                Back to List
            </a>
        </div>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            @if (session('success'))
                <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded relative mb-4">
                    {{ session('success') }}
                </div>
            @endif

            @if (session('error'))
                <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative mb-4">
                    {{ session('error') }}
                </div>
            @endif

            <!-- Snapshot Information -->
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg mb-6">
                <div class="p-6 bg-white border-b border-gray-200">
                    <h3 class="text-lg font-semibold mb-4">Snapshot Information</h3>
                    <dl class="grid grid-cols-1 gap-x-4 gap-y-4 sm:grid-cols-2">
                        <div class="sm:col-span-1">
                            <dt class="text-sm font-medium text-gray-500">Snapshot ID</dt>
                            <dd class="mt-1 text-sm text-gray-900 font-mono">{{ $snapshot['short_id'] ?? 'N/A' }}</dd>
                        </div>
                        <div class="sm:col-span-1">
                            <dt class="text-sm font-medium text-gray-500">Full ID</dt>
                            <dd class="mt-1 text-sm text-gray-900 font-mono break-all">{{ $snapshot['id'] ?? 'N/A' }}</dd>
                        </div>
                        <div class="sm:col-span-1">
                            <dt class="text-sm font-medium text-gray-500">Created At</dt>
                            <dd class="mt-1 text-sm text-gray-900">{{ $snapshot['time'] ?? 'N/A' }}</dd>
                        </div>
                        <div class="sm:col-span-1">
                            <dt class="text-sm font-medium text-gray-500">Hostname</dt>
                            <dd class="mt-1 text-sm text-gray-900">{{ $snapshot['hostname'] ?? 'N/A' }}</dd>
                        </div>
                        <div class="sm:col-span-2">
                            <dt class="text-sm font-medium text-gray-500">Backed Up Paths</dt>
                            <dd class="mt-1 text-sm text-gray-900">
                                <ul class="list-disc list-inside">
                                    @if (isset($snapshot['paths']) && is_array($snapshot['paths']))
                                        @foreach ($snapshot['paths'] as $path)
                                            <li>{{ $path }}</li>
                                        @endforeach
                                    @else
                                        <li>No paths information available</li>
                                    @endif
                                </ul>
                            </dd>
                        </div>
                        @if (isset($snapshot['tags']) && !empty($snapshot['tags']))
                        <div class="sm:col-span-2">
                            <dt class="text-sm font-medium text-gray-500">Tags</dt>
                            <dd class="mt-1 text-sm text-gray-900">
                                @foreach ($snapshot['tags'] as $tag)
                                    <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-blue-100 text-blue-800 mr-2">
                                        {{ $tag }}
                                    </span>
                                @endforeach
                            </dd>
                        </div>
                        @endif
                    </dl>
                </div>
            </div>

            <!-- Files in Snapshot -->
            @if (isset($snapshot['files']) && !empty($snapshot['files']))
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg mb-6">
                <div class="p-6 bg-white border-b border-gray-200">
                    <h3 class="text-lg font-semibold mb-4">Files in Snapshot (First 100)</h3>
                    <div class="bg-gray-50 p-4 rounded overflow-x-auto">
                        <pre class="text-xs text-gray-700 whitespace-pre-wrap">@foreach ($snapshot['files'] as $file){{ $file }}
@endforeach</pre>
                    </div>
                </div>
            </div>
            @endif

            <!-- Actions -->
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 bg-white border-b border-gray-200">
                    <h3 class="text-lg font-semibold mb-4">Actions</h3>
                    <div class="flex gap-4">
                        <a href="{{ route('backups.restore', ['snapshot' => $snapshot['id']]) }}" 
                           class="bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded">
                            Restore This Backup
                        </a>
                        <form method="POST" action="{{ route('backups.delete', $snapshot['id']) }}" class="inline" onsubmit="return confirm('Are you sure you want to delete this backup? This action cannot be undone!');">
                            @csrf
                            @method('DELETE')
                            <button type="submit" class="bg-red-500 hover:bg-red-700 text-white font-bold py-2 px-4 rounded">
                                Delete This Backup
                            </button>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
