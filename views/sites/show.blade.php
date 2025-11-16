<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('Site Details') }}: {{ $site['name'] }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <!-- Site Information -->
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg mb-6">
                <div class="p-6 bg-white border-b border-gray-200">
                    <h3 class="text-lg font-semibold mb-4">Site Information</h3>
                    <dl class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <dt class="text-sm font-medium text-gray-500">Site Name</dt>
                            <dd class="mt-1 text-sm text-gray-900">{{ $site['name'] }}</dd>
                        </div>
                        <div>
                            <dt class="text-sm font-medium text-gray-500">Domain</dt>
                            <dd class="mt-1 text-sm text-gray-900">
                                <a href="http://{{ $site['domain'] }}" target="_blank" class="text-blue-600 hover:text-blue-900">
                                    {{ $site['domain'] }}
                                </a>
                            </dd>
                        </div>
                        <div>
                            <dt class="text-sm font-medium text-gray-500">PHP Version</dt>
                            <dd class="mt-1 text-sm text-gray-900">{{ $site['phpVersion'] }}</dd>
                        </div>
                        <div>
                            <dt class="text-sm font-medium text-gray-500">Site Path</dt>
                            <dd class="mt-1 text-sm text-gray-900 font-mono text-xs">{{ $site['path'] }}</dd>
                        </div>
                        <div>
                            <dt class="text-sm font-medium text-gray-500">NGINX Config</dt>
                            <dd class="mt-1 text-sm text-gray-900 font-mono text-xs">{{ $site['nginxConfig'] }}</dd>
                        </div>
                        <div>
                            <dt class="text-sm font-medium text-gray-500">PHP-FPM Pool</dt>
                            <dd class="mt-1 text-sm text-gray-900 font-mono text-xs">{{ $site['phpFpmPool'] }}</dd>
                        </div>
                    </dl>
                </div>
            </div>

            <!-- SSL Status -->
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg mb-6">
                <div class="p-6 bg-white border-b border-gray-200">
                    <div class="flex justify-between items-center mb-4">
                        <h3 class="text-lg font-semibold">SSL Certificate</h3>
                        <a href="{{ route('sites.ssl', $site['name']) }}" class="bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded">
                            Manage SSL
                        </a>
                    </div>
                    @if ($site['ssl'])
                        <div class="bg-green-50 p-4 rounded">
                            <p class="text-green-800">✓ SSL is active for this site</p>
                        </div>
                    @else
                        <div class="bg-red-50 p-4 rounded">
                            <p class="text-red-800">✗ SSL is not configured for this site</p>
                        </div>
                    @endif
                </div>
            </div>

            <!-- FastCGI Cache -->
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg mb-6">
                <div class="p-6 bg-white border-b border-gray-200">
                    <h3 class="text-lg font-semibold mb-4">FastCGI Cache</h3>
                    @if ($site['cache'])
                        <div class="bg-green-50 p-4 rounded">
                            <p class="text-green-800">✓ FastCGI Cache is enabled</p>
                            <form method="POST" action="{{ route('sites.clearCache', $site['name']) }}" class="mt-4">
                                @csrf
                                <button type="submit" class="bg-yellow-500 hover:bg-yellow-700 text-white font-bold py-2 px-4 rounded">
                                    Clear Cache
                                </button>
                            </form>
                        </div>
                    @else
                        <div class="bg-gray-50 p-4 rounded">
                            <p class="text-gray-800">FastCGI Cache is disabled</p>
                        </div>
                    @endif
                </div>
            </div>

            <!-- Actions -->
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6 bg-white border-b border-gray-200">
                    <h3 class="text-lg font-semibold mb-4">Actions</h3>
                    <div class="flex flex-wrap gap-2">
                        <a href="{{ route('sites.logs', $site['name']) }}" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
                            View Logs
                        </a>
                        <a href="{{ route('sites.edit', $site['name']) }}" class="bg-yellow-500 hover:bg-yellow-700 text-white font-bold py-2 px-4 rounded">
                            Edit Configuration
                        </a>
                        <form method="POST" action="{{ route('sites.restart', $site['name']) }}" class="inline">
                            @csrf
                            <button type="submit" class="bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded">
                                Restart PHP-FPM
                            </button>
                        </form>
                        <form method="POST" action="{{ route('sites.destroy', $site['name']) }}" class="inline">
                            @csrf
                            @method('DELETE')
                            <button type="submit" class="bg-red-500 hover:bg-red-700 text-white font-bold py-2 px-4 rounded" onclick="return confirm('Are you sure? This will delete all files and database!')">
                                Delete Site
                            </button>
                        </form>
                    </div>
                </div>
            </div>

            <div class="mt-6">
                <a href="{{ route('sites.index') }}" class="text-blue-600 hover:text-blue-900">← Back to Sites</a>
            </div>
        </div>
    </div>
</x-app-layout>