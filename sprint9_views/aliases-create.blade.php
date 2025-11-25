<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 leading-tight">
            {{ __('Create Email Alias') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-3xl mx-auto sm:px-6 lg:px-8">
            
            @if(session('error'))
            <div class="mb-6 bg-red-50 border-l-4 border-red-400 p-4">
                <p class="text-red-700">{{ session('error') }}</p>
            </div>
            @endif

            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6">
                    <h3 class="text-lg font-semibold text-gray-900 mb-6">New Email Alias</h3>
                    
                    <form method="POST" action="{{ route('email.aliases.store') }}">
                        @csrf
                        
                        <div class="mb-6">
                            <label for="alias" class="block text-sm font-medium text-gray-700 mb-2">
                                Alias Email Address *
                            </label>
                            <input type="email" 
                                   name="alias" 
                                   id="alias"
                                   value="{{ old('alias') }}"
                                   required
                                   placeholder="info@example.com"
                                   class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                            @error('alias')
                            <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                            @enderror
                            <p class="mt-1 text-sm text-gray-500">
                                The email address that will act as an alias (e.g., info@example.com, sales@example.com)
                            </p>
                        </div>

                        <div class="mb-6">
                            <label for="destination" class="block text-sm font-medium text-gray-700 mb-2">
                                Destination Email Address *
                            </label>
                            <input type="email" 
                                   name="destination" 
                                   id="destination"
                                   value="{{ old('destination') }}"
                                   required
                                   placeholder="admin@example.com"
                                   class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500">
                            @error('destination')
                            <p class="mt-1 text-sm text-red-600">{{ $message }}</p>
                            @enderror
                            <p class="mt-1 text-sm text-gray-500">
                                Where emails sent to the alias should be delivered
                            </p>
                        </div>

                        <!-- Info Box -->
                        <div class="mb-6 bg-blue-50 border-l-4 border-blue-400 p-4">
                            <div class="flex">
                                <div class="flex-shrink-0">
                                    <svg class="h-5 w-5 text-blue-400" fill="currentColor" viewBox="0 0 20 20">
                                        <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd"></path>
                                    </svg>
                                </div>
                                <div class="ml-3">
                                    <h3 class="text-sm font-medium text-blue-800">Email Alias Information</h3>
                                    <div class="mt-2 text-sm text-blue-700">
                                        <ul class="list-disc list-inside space-y-1">
                                            <li>Aliases forward emails from one address to another</li>
                                            <li>Multiple aliases can point to the same destination</li>
                                            <li>Changes take effect immediately after creation</li>
                                            <li>Both addresses must use domains configured on this server</li>
                                        </ul>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div class="flex items-center justify-between">
                            <a href="{{ route('email.aliases') }}" 
                               class="px-4 py-2 bg-gray-200 text-gray-700 rounded-md hover:bg-gray-300">
                                Cancel
                            </a>
                            
                            <button type="submit" 
                                    class="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 flex items-center gap-2">
                                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
                                </svg>
                                Create Alias
                            </button>
                        </div>
                    </form>
                </div>
            </div>

            <!-- Examples Section -->
            <div class="mt-6 bg-white overflow-hidden shadow-sm sm:rounded-lg">
                <div class="p-6">
                    <h3 class="text-lg font-semibold text-gray-900 mb-4">Common Use Cases</h3>
                    
                    <div class="space-y-4">
                        <div class="flex items-start">
                            <div class="flex-shrink-0 h-6 w-6 rounded-full bg-blue-100 flex items-center justify-center">
                                <span class="text-blue-600 text-sm font-bold">1</span>
                            </div>
                            <div class="ml-3">
                                <h4 class="text-sm font-medium text-gray-900">Department Emails</h4>
                                <p class="text-sm text-gray-600">
                                    sales@example.com → john@example.com<br>
                                    support@example.com → jane@example.com
                                </p>
                            </div>
                        </div>
                        
                        <div class="flex items-start">
                            <div class="flex-shrink-0 h-6 w-6 rounded-full bg-blue-100 flex items-center justify-center">
                                <span class="text-blue-600 text-sm font-bold">2</span>
                            </div>
                            <div class="ml-3">
                                <h4 class="text-sm font-medium text-gray-900">Catch-All</h4>
                                <p class="text-sm text-gray-600">
                                    Multiple aliases pointing to admin@example.com for centralized management
                                </p>
                            </div>
                        </div>
                        
                        <div class="flex items-start">
                            <div class="flex-shrink-0 h-6 w-6 rounded-full bg-blue-100 flex items-center justify-center">
                                <span class="text-blue-600 text-sm font-bold">3</span>
                            </div>
                            <div class="ml-3">
                                <h4 class="text-sm font-medium text-gray-900">Role-Based</h4>
                                <p class="text-sm text-gray-600">
                                    webmaster@example.com → tech-team@example.com<br>
                                    admin@example.com → ceo@example.com
                                </p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
