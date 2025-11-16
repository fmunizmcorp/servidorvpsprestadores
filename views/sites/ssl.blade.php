<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('SSL Management') }}: {{ $site['name'] }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-4xl mx-auto sm:px-6 lg:px-8">
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

            <!-- Current SSL Status -->
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg mb-6">
                <div class="p-6">
                    <h3 class="text-lg font-semibold mb-4">Current SSL Status</h3>
                    @if ($sslStatus['active'])
                        <div class="bg-green-50 p-4 rounded mb-4">
                            <p class="text-green-800 font-semibold">✓ SSL Certificate is Active</p>
                            @if (isset($sslStatus['issuer']))
                                <p class="text-sm text-green-700 mt-2">Issuer: {{ $sslStatus['issuer'] }}</p>
                            @endif
                            @if (isset($sslStatus['expires']))
                                <p class="text-sm text-green-700">Expires: {{ $sslStatus['expires'] }}</p>
                            @endif
                        </div>
                    @else
                        <div class="bg-red-50 p-4 rounded mb-4">
                            <p class="text-red-800 font-semibold">✗ No SSL Certificate</p>
                        </div>
                    @endif
                </div>
            </div>

            <!-- Generate SSL Certificate -->
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6">
                    <h3 class="text-lg font-semibold mb-4">Generate/Renew SSL Certificate</h3>
                    <form method="POST" action="{{ route('sites.generateSSL', $site['name']) }}">
                        @csrf
                        
                        <div class="mb-4">
                            <label for="email" class="block text-sm font-medium text-gray-700">Email Address</label>
                            <input type="email" name="email" id="email" required
                                   class="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
                                   placeholder="admin@{{ $site['domain'] }}">
                            <p class="mt-1 text-sm text-gray-500">Required for Let's Encrypt certificate registration</p>
                        </div>

                        <div class="mb-4">
                            <label class="flex items-center">
                                <input type="checkbox" name="agree_tos" required class="rounded border-gray-300">
                                <span class="ml-2 text-sm">I agree to Let's Encrypt Terms of Service</span>
                            </label>
                        </div>

                        <div class="bg-blue-50 p-4 rounded mb-4">
                            <p class="text-sm text-blue-800">
                                <strong>Requirements:</strong>
                            </p>
                            <ul class="list-disc list-inside text-sm text-blue-700 mt-2">
                                <li>Domain {{ $site['domain'] }} must point to this server ({{ $serverIP ?? '72.61.53.222' }})</li>
                                <li>Port 80 must be accessible (for HTTP validation)</li>
                                <li>Site must be active and responding</li>
                            </ul>
                        </div>

                        <button type="submit" class="bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded">
                            Generate SSL Certificate
                        </button>
                    </form>
                </div>
            </div>

            <div class="mt-6">
                <a href="{{ route('sites.show', $site['name']) }}" class="text-blue-600 hover:text-blue-900">← Back to Site</a>
            </div>
        </div>
    </div>
</x-app-layout>
